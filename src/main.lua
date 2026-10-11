-- 2026-08-22 (Wizard): with MasterHUD installed this mod's own HUD hide/move keys must not
-- merely be inert, they must not REGISTER at all - that is what removes their rows from the
-- F1 legend and the Controls list. Probed on TaxMod first: skipping registration does remove
-- the row, so the pattern is used suite-wide. Only HUD hide/move actions are gated; every
-- other action this mod registers is untouched.
local function __rfMhOwnsHudKeys()
    return ((g_currentMission ~= nil and g_currentMission.masterHUD) or g_masterHUD) ~= nil
end

-- =========================================================
-- FS25 Realistic Fuel Costs - Entry Point
-- =========================================================
-- Loads all modules in dependency order, hooks FS25 mission
-- lifecycle events, and drives the update/draw loops.
-- =========================================================
-- Author: TisonK
-- =========================================================

-- Hot-reload safety (proven live 2026-08-21 20:41 and 20:44: re-source died at
-- the first source() concat): g_currentModDirectory/g_currentModName are only
-- set during the initial mod load pass and are nil on a live re-source. Latch
-- into module globals on first load, and fall back to g_modsDirectory plus the
-- known loose-folder name for a live session whose boot predates the latch
-- (g_modsDirectory is engine-provided and already used live by CsRfPdaGuest).
FcModDirectory = FcModDirectory
    or g_currentModDirectory
    or (g_modsDirectory ~= nil and (g_modsDirectory .. "FS25_FuelCosts/") or nil)
FcModName      = FcModName or g_currentModName or "FS25_FuelCosts"
local modDirectory = FcModDirectory
local modName      = FcModName

-- -------------------------------------------------------
-- Phase 1 - Utilities & Config
-- -------------------------------------------------------
source(modDirectory .. "src/utils/FcLiveKeyLabel.lua")
source(modDirectory .. "src/utils/Logger.lua")
source(modDirectory .. "src/config/Constants.lua")
source(modDirectory .. "src/config/SettingsSchema.lua")

-- -------------------------------------------------------
-- Phase 2 - Settings
-- -------------------------------------------------------
source(modDirectory .. "src/settings/Settings.lua")
source(modDirectory .. "src/settings/SettingsManager.lua")

-- -------------------------------------------------------
-- Phase 3 - Core Systems
-- -------------------------------------------------------
source(modDirectory .. "src/FuelPriceEngine.lua")
source(modDirectory .. "src/FuelHUD.lua")
source(modDirectory .. "src/ui/FuelSettingsPanel.lua")

-- -------------------------------------------------------
-- Phase 4 - Network
-- -------------------------------------------------------
source(modDirectory .. "src/network/NetworkEvents.lua")

-- -------------------------------------------------------
-- Phase 5 - Manager (depends on all of the above)
-- -------------------------------------------------------
source(modDirectory .. "src/FuelCostsManager.lua")
source(modDirectory .. "src/FuelContextInput.lua")

-- -------------------------------------------------------
-- Phase 6 - Bedrock bridges (optional, delegate-when-present)
-- -------------------------------------------------------
source(modDirectory .. "src/integrations/FuelStateLedgerBridge.lua")
source(modDirectory .. "src/integrations/FuelNetworkSyncBridge.lua")
source(modDirectory .. "src/integrations/FuelSettingsHubBridge.lua")
source(modDirectory .. "src/integrations/FuelMasterHUDBridge.lua")

-- -------------------------------------------------------
-- Lifecycle state
-- -------------------------------------------------------
local fcm = nil

local function isEnabled()
    return fcm ~= nil
end

-- -------------------------------------------------------
-- Input action registration (RSF-F201 context-qualified)
-- FC_OPEN_SETTINGS opens the settings panel from both contexts. FC_TOGGLE_HUD and
-- FC_HUD_EDIT stay PLAYER-only and register only while MasterHUD is absent (with
-- MasterHUD installed they must not register at all, see the file header).
--
-- Each context registers through its own private forwarding target. The engine
-- keys an event by action, target and trigger shape only, so the old shared
-- g_FuelCostsManager target made the PLAYER and VEHICLE FC_OPEN_SETTINGS
-- registrations one global slot that every cab rebuild wiped. Membership is
-- asked of the wrap's own context by walking the native lists; a complete set
-- costs no transaction. The hook record lives on the FuelCostsManager class
-- table (unload() clears only the instance) and is never restored per mission.
--
-- The old getActionEventDisplayName probe is gone: that getter does not exist
-- in the engine, so its pcall always failed and the stored id was nil'd on
-- every player callback.
-- -------------------------------------------------------
local inputRecord = FuelContextInput.record(FuelCostsManager, "_f201Input")

local function hasSettingsPanel(owner) return owner.settingsPanel ~= nil end
local function ownsHudKeys() return not __rfMhOwnsHudKeys() end
local function hideRow(binding, eventId) binding:setActionEventTextVisibility(eventId, false) end
local function labelToggle(binding, eventId)
    binding:setActionEventText(eventId,
        (g_i18n ~= nil and g_i18n:getText("input_FC_TOGGLE_HUD")) or "Toggle Fuel HUD")
end
local function labelEdit(binding, eventId)
    binding:setActionEventText(eventId,
        (g_i18n ~= nil and g_i18n:getText("input_FC_HUD_EDIT")) or "Move Fuel HUD")
end

local FC_PLAYER_SPECS = {
    { action = "FC_OPEN_SETTINGS", handler = "onOpenSettingsInput", idField = "settingsPanelEventId",
      present = hasSettingsPanel, after = hideRow, up = false, down = true, always = false, startActive = true },
    { action = "FC_TOGGLE_HUD", handler = "onToggleHUDInput", idField = "toggleHudEventId",
      present = ownsHudKeys, after = labelToggle, up = false, down = true, always = false, startActive = true },
    { action = "FC_HUD_EDIT", handler = "onHUDEditInput", idField = "hudEditEventId",
      present = ownsHudKeys, after = labelEdit, up = false, down = true, always = false, startActive = true },
}

-- Cab set is FC_OPEN_SETTINGS only. Do not add the HUD hide/move actions here.
local FC_VEHICLE_SPECS = {
    { action = "FC_OPEN_SETTINGS", handler = "onOpenSettingsInput", idField = "vehicleSettingsPanelEventId",
      present = hasSettingsPanel, after = hideRow, up = false, down = true, always = false, startActive = true },
}

-- Installed once per loaded script environment, at module load, so the PLAYER
-- wrapper is in place before the first registerActionEvents fires.
if FuelContextInput.installPlayerWrapper(inputRecord, FC_PLAYER_SPECS) then
    FuelLogger.info("PlayerInputComponent hook installed for FC_OPEN_SETTINGS")
end
if FuelContextInput.installVehicleWrapper(inputRecord, FC_VEHICLE_SPECS) then
    FuelLogger.info("InputBinding hook installed for VEHICLE context")
end

local function activateInput(mission)
    if fcm == nil or PlayerInputComponent == nil or Vehicle == nil then return end
    FuelContextInput.activate(inputRecord, fcm, mission, {
        [PlayerInputComponent.INPUT_CONTEXT_NAME] = FC_PLAYER_SPECS,
        [Vehicle.INPUT_CONTEXT_NAME]              = FC_VEHICLE_SPECS,
    })
end

-- -------------------------------------------------------
-- Mission00.load  (create manager)
-- -------------------------------------------------------
local function load(mission)
    if mission.cancelLoading then return end
    -- Reload safety: a re-sourced copy of this file stacks another prepended
    -- load hook whose local fcm is nil. Resolve the live manager first so a
    -- stacked copy adopts it instead of creating a second manager.
    fcm = g_FuelCostsManager or mission.fuelCostsManager or fcm
    if fcm == nil then
        fcm = FuelCostsManager.new()
        getfenv(0)["g_FuelCostsManager"] = fcm
        mission.fuelCostsManager = fcm
    end
    -- RSF-F201: bind this manager as input owner of the mission and mint fresh
    -- per-context forwarding targets. A stacked reload copy adopts the binding.
    activateInput(mission)
end

-- -------------------------------------------------------
-- Mission00.loadMission00Finished  (init + MP sync)
-- -------------------------------------------------------
local function loadedMission(mission, node)
    if not isEnabled() or mission.cancelLoading then return end
    -- Reload safety: stacked copies of this hook must not init/register twice
    -- for the same mission. The flag lives on the manager, which is discarded
    -- on mission delete, so the next real mission load initializes normally.
    if fcm.__missionInitDone then return end
    fcm.__missionInitDone = true
    fcm:init()

    -- Bedrock bridges (delegate-when-present; each no-ops if its bedrock mod is
    -- absent). Handles are published by the bedrock mods at Mission00.load. When
    -- StateLedger carries a price block it overrides the price just loaded from
    -- FS25_FuelCosts.xml; the own XML stays the safety copy.
    FuelStateLedgerBridge.register(fcm)
    if FuelStateLedgerBridge.hasLedgerState() then
        FuelStateLedgerBridge.applyState(fcm)
    end
    FuelSettingsHubBridge.register(fcm)
    FuelMasterHUDBridge.register(fcm)
    FuelNetworkSyncBridge.register(fcm)

    fcm:registerConsoleCommands()
    -- Client join sync: when NetworkSync is active it delivers the full price state
    -- to joining clients, so the own request event is only the fallback path.
    if g_client ~= nil and g_server == nil and not FuelNetworkSyncBridge.active then
        g_client:getServerConnection():sendEvent(FuelRequestSyncEvent.new())
    end

    -- RSF-F201 post-load catch-up: one PLAYER reconciliation if the local owning
    -- player and the native PLAYER context already exist. Also retires this
    -- mod's own HUD hide/move rows now that MasterHUD (if present) is published.
    FuelContextInput.catchUpPlayer(inputRecord, FC_PLAYER_SPECS)
end

-- -------------------------------------------------------
-- FSBaseMission.delete  (cleanup)
-- -------------------------------------------------------
local function unload()
    -- RSF-F201: retire the input owner first. Old targets go inert; the captured
    -- predecessors stay installed so no neighbour's wrapper is unhooked.
    FuelContextInput.retire(inputRecord)
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

-- ---------------------------------------------------------
-- Realistic Farming Control Center: publish a runnable delegate.
--
-- FC_HUD_EDIT stays button-less (moving the panel needs the in-world drag).
-- FC_TOGGLE_HUD now grows a hide/show button below: the physical key stays gated
-- to MasterHUD, but a per-mod hide is reachable from the Control Center. Both keep
-- their directory row and live key readout here.
-- ---------------------------------------------------------
local function registerControlCenterActions()
    local registry = g_currentMission ~= nil and g_currentMission.rfActionRegistry or nil
    if registry == nil then return end

    registry.registerAction({
        action     = "FC_OPEN_SETTINGS",
        button     = "Open",
        -- The settings panel draws on the HUD, so the dialog steps aside.
        closeFirst = true,
        run = function()
            local mgr = g_FuelCostsManager
            if mgr ~= nil and mgr.onOpenSettingsInput ~= nil then
                mgr:onOpenSettingsInput()
            end
        end,
    })

    -- Per-mod HUD hide/show. Flips settings.hudEnabled (the mod's own visibility
    -- truth, honoured by the draw path under MasterHUD), mirroring the FC_TOGGLE_HUD
    -- key minus the MasterHUD gate. Live "Hide"/"Show" caption.
    registry.registerAction({
        action = "FC_TOGGLE_HUD",
        button = function()
            local s = g_FuelCostsManager ~= nil and g_FuelCostsManager.settings or nil
            return (s ~= nil and s.hudEnabled) and "Hide" or "Show"
        end,
        run = function()
            local mgr = g_FuelCostsManager
            if mgr == nil or mgr.settings == nil then return end
            mgr.settings.hudEnabled = not mgr.settings.hudEnabled
            if mgr.hud ~= nil and mgr.hud.flash ~= nil then
                mgr.hud:flash(mgr.settings.hudEnabled and "Fuel HUD shown" or "Fuel HUD hidden",
                    {0.55, 0.80, 0.95, 1.0}, 2.0)
            end
            return mgr.settings.hudEnabled and "Fuel HUD shown" or "Fuel HUD hidden"
        end,
    })
end

Mission00.loadMission00Finished = Utils.appendedFunction(
    Mission00.loadMission00Finished, registerControlCenterActions)
FSBaseMission.delete            = Utils.prependedFunction(FSBaseMission.delete,            unload)

FSBaseMission.update = Utils.appendedFunction(FSBaseMission.update, function(mission, dt)
    -- RSF-F201: admission reset is the first input act of every update interval.
    FuelContextInput.resetAdmission(inputRecord)
    if fcm then fcm:update(dt) end
end)

-- renderOverlay/renderText are ONLY valid inside a draw callback (not update)
FSBaseMission.draw = Utils.appendedFunction(FSBaseMission.draw, function(mission)
    -- When MasterHUD is present it owns the single draw loop (our draw was registered
    -- as a self-draw via the bridge); stand down so the HUD never draws twice.
    if FuelMasterHUDBridge ~= nil and FuelMasterHUDBridge.active then return end
    if FuelMasterHUDBridge ~= nil then
        FuelMasterHUDBridge.drawStack()
        return
    end
    if not mission.isRunning then return end
    if fcm and fcm.hud then
        fcm.hud:draw()
    end
    if fcm and fcm.settingsPanel then
        fcm.settingsPanel:draw()
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

-- -------------------------------------------------------
-- Mouse event handler - settings panel eats input when open
-- -------------------------------------------------------
-- Reload-safe (hot-reload law): the handler table is a module global so a
-- re-source rebinds mouseEvent on the SAME registered table, and the manager is
-- resolved live on every event instead of captured. The old shape captured the
-- local fcm as an upvalue - a re-sourced copy holds fcm = nil forever, which is
-- why the 19:38 suite-edit drag never reached FuelHUD (orange chrome, no move).
-- Registration runs once per game session, guarded by a module-global flag.
FcMouseHandler = FcMouseHandler or {}
function FcMouseHandler:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    local mgr = g_FuelCostsManager
        or (g_currentMission ~= nil and g_currentMission.fuelCostsManager or nil)
    if mgr == nil then return eventUsed end
    if mgr.settingsPanel and mgr.settingsPanel:isOpen() then
        local consumed = mgr.settingsPanel:onMouseEvent(posX, posY, isDown, isUp, button, eventUsed)
        return consumed or eventUsed
    end
    -- BUILD 19:38: route mouse to the HUD while suite layout edit is on (drag to
    -- move). The settings-panel path above keeps priority when it is open.
    if mgr.hud and mgr.hud.editMode and mgr.hud.onMouseEvent then
        local consumed = mgr.hud:onMouseEvent(posX, posY, isDown, isUp, button)
        return consumed or eventUsed
    end
    return eventUsed
end
if not FcMouseHandlerRegistered then
    FcMouseHandlerRegistered = true
    addModEventListener(FcMouseHandler)
end
FuelLogger.info("Mouse routing bound (reload-safe, live-resolved manager)")


print("========================================")
print("  FS25 Realistic Fuel Costs LOADED      ")
print("  Dynamic diesel price simulation       ")
print("  Type 'FuelCostsInfo' in console       ")
print("========================================")
