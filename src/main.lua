-- =========================================================
-- FS25 Realistic Fuel Costs - main.lua
-- =========================================================
-- Entry point. Loads all modules in dependency order,
-- then hooks into the FS25 mission lifecycle.
-- =========================================================
-- Author: TisonK
-- =========================================================

-- -------------------------------------------------------
-- Phase 1 — Utilities & Config
-- -------------------------------------------------------
source(g_currentModDirectory .. "src/utils/Logger.lua")
source(g_currentModDirectory .. "src/config/Constants.lua")
source(g_currentModDirectory .. "src/config/SettingsSchema.lua")

-- -------------------------------------------------------
-- Phase 2 — Settings
-- -------------------------------------------------------
source(g_currentModDirectory .. "src/settings/Settings.lua")
source(g_currentModDirectory .. "src/settings/SettingsManager.lua")

-- -------------------------------------------------------
-- Phase 3 — Core Systems
-- -------------------------------------------------------
source(g_currentModDirectory .. "src/FuelPriceEngine.lua")
source(g_currentModDirectory .. "src/FuelHUD.lua")

-- -------------------------------------------------------
-- Phase 4 — Network
-- -------------------------------------------------------
source(g_currentModDirectory .. "src/network/NetworkEvents.lua")

-- -------------------------------------------------------
-- Phase 5 — Manager (depends on all of the above)
-- -------------------------------------------------------
source(g_currentModDirectory .. "src/FuelCostsManager.lua")

-- -------------------------------------------------------
-- Mission lifecycle hooks
-- -------------------------------------------------------

Utils.appendedFunction(Mission00, "load", function(mission)
    print("[FuelCosts] Mission00.load hook fired")
    local env = getfenv(0)
    env.g_FuelCostsManager = FuelCostsManager.new()
end)

Utils.appendedFunction(Mission00, "loadMission00Finished", function(mission, node)
    if g_FuelCostsManager then
        g_FuelCostsManager:init()
        g_FuelCostsManager:registerConsoleCommands()
        -- Request full sync if joining an MP session
        if g_currentMission and g_currentMission.isMultiplayer and not g_currentMission.isMasterUser then
            g_currentMission:sendEvent(FuelRequestSyncEvent.new())
        end
    end
end)

Utils.appendedFunction(FSBaseMission, "update", function(mission, dt)
    if g_FuelCostsManager then
        g_FuelCostsManager:update(dt)
    end
end)

Utils.appendedFunction(FSBaseMission, "delete", function(mission)
    if g_FuelCostsManager then
        g_FuelCostsManager:delete()
        local env = getfenv(0)
        env.g_FuelCostsManager = nil
    end
end)

Utils.appendedFunction(FSCareerMissionInfo, "saveToXMLFile", function(missionInfo, xmlFile, key)
    if g_FuelCostsManager and g_currentMission and g_currentMission.isMasterUser ~= false then
        g_FuelCostsManager:save()
    end
end)
