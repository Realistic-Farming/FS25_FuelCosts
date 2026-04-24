-- =========================================================
-- FS25 Realistic Fuel Costs - Entry Point
-- =========================================================
-- Loads all modules in dependency order, hooks FS25 mission
-- lifecycle events, and drives the update/draw loops.
-- =========================================================
-- Author: TisonK
-- =========================================================

local modDirectory = g_currentModDirectory
local modName      = g_currentModName

-- -------------------------------------------------------
-- Phase 1 — Utilities & Config
-- -------------------------------------------------------
source(modDirectory .. "src/utils/Logger.lua")
source(modDirectory .. "src/config/Constants.lua")
source(modDirectory .. "src/config/SettingsSchema.lua")

-- -------------------------------------------------------
-- Phase 2 — Settings
-- -------------------------------------------------------
source(modDirectory .. "src/settings/Settings.lua")
source(modDirectory .. "src/settings/SettingsManager.lua")

-- -------------------------------------------------------
-- Phase 3 — Core Systems
-- -------------------------------------------------------
source(modDirectory .. "src/FuelPriceEngine.lua")
source(modDirectory .. "src/FuelHUD.lua")

-- -------------------------------------------------------
-- Phase 4 — Network
-- -------------------------------------------------------
source(modDirectory .. "src/network/NetworkEvents.lua")

-- -------------------------------------------------------
-- Phase 5 — Manager (depends on all of the above)
-- -------------------------------------------------------
source(modDirectory .. "src/FuelCostsManager.lua")

-- -------------------------------------------------------
-- Lifecycle state
-- -------------------------------------------------------
local fcm = nil

local function isEnabled()
    return fcm ~= nil
end

-- -------------------------------------------------------
-- Mission00.load  (create manager)
-- -------------------------------------------------------
local function load(mission)
    if mission.cancelLoading then return end
    if fcm == nil then
        fcm = FuelCostsManager.new()
        getfenv(0)["g_FuelCostsManager"] = fcm
        mission.fuelCostsManager = fcm
    end
end

-- -------------------------------------------------------
-- Mission00.loadMission00Finished  (init + MP sync)
-- -------------------------------------------------------
local function loadedMission(mission, node)
    if not isEnabled() or mission.cancelLoading then return end
    fcm:init()
    fcm:registerConsoleCommands()
    if g_client ~= nil and g_server == nil then
        g_currentMission:sendEvent(FuelRequestSyncEvent.new())
    end
end

-- -------------------------------------------------------
-- FSBaseMission.delete  (cleanup)
-- -------------------------------------------------------
local function unload()
    if fcm ~= nil then
        fcm:delete()
        fcm = nil
        getfenv(0)["g_FuelCostsManager"] = nil
        if g_currentMission then
            g_currentMission.fuelCostsManager = nil
        end
    end
end

-- -------------------------------------------------------
-- Wire lifecycle hooks (SoilFertilizer direct-assign pattern)
-- -------------------------------------------------------
Mission00.load                  = Utils.prependedFunction(Mission00.load,                  load)
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished,  loadedMission)
FSBaseMission.delete            = Utils.prependedFunction(FSBaseMission.delete,            unload)

FSBaseMission.update = Utils.appendedFunction(FSBaseMission.update, function(mission, dt)
    if fcm then fcm:update(dt) end
end)

-- renderOverlay/renderText are ONLY valid inside a draw callback (not update)
FSBaseMission.draw = Utils.appendedFunction(FSBaseMission.draw, function(mission)
    if not mission.isRunning then return end
    if fcm and fcm.hud then
        fcm.hud:draw()
    end
end)

-- -------------------------------------------------------
-- Save hook
-- -------------------------------------------------------
if FSCareerMissionInfo and FSCareerMissionInfo.saveToXMLFile then
    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(
        FSCareerMissionInfo.saveToXMLFile,
        function(missionInfo)
            if g_currentMission and g_currentMission.missionDynamicInfo
               and g_currentMission.missionDynamicInfo.isMultiplayer then
                if g_server == nil then return end
            end
            if fcm then fcm:save() end
        end
    )
end

print("========================================")
print("  FS25 Realistic Fuel Costs LOADED      ")
print("  Dynamic diesel price simulation       ")
print("  Type 'FuelCostsInfo' in console       ")
print("========================================")
