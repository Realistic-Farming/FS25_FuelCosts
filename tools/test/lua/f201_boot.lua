-- RSF-F201 boot fixture: engine-side input globals and the manager/bridge stubs
-- must exist BEFORE src/main.lua loads, because FuelCosts installs its wrappers
-- at module load and reads the FuelCostsManager class table for its record.
-- Loaded through --!load: after f201_model_binding.lua and before main.lua.
F201Model.installEngine({ "FC_OPEN_SETTINGS", "FC_TOGGLE_HUD", "FC_HUD_EDIT" })
F201Boot = { nativeCalls = 0, managersCreated = 0, opens = 0, toggles = 0, edits = 0 }
PlayerInputComponent.registerActionEvents = function() F201Boot.nativeCalls = F201Boot.nativeCalls + 1 end
F201Boot.nativePlayer = PlayerInputComponent.registerActionEvents
F201Boot.nativeVehicle = InputBinding.endActionEventsModification

local noop = function() end
FuelLogger = { info = noop, warning = noop, error = noop, debug = noop }
FuelCostsManager = FuelCostsManager or {}
FuelCostsManager.__index = FuelCostsManager
function FuelCostsManager.new()
    F201Boot.managersCreated = F201Boot.managersCreated + 1
    return setmetatable({ settingsPanel = { toggle = noop, update = noop, delete = noop }, settings = { enabled = true } }, FuelCostsManager)
end
function FuelCostsManager:init() self.initialized = true end
function FuelCostsManager:update(_dt) end
function FuelCostsManager:delete() self.initialized = false end
function FuelCostsManager:registerConsoleCommands() end
function FuelCostsManager:onOpenSettingsInput() F201Boot.opens = F201Boot.opens + 1 end
function FuelCostsManager:onToggleHUDInput() F201Boot.toggles = F201Boot.toggles + 1 end
function FuelCostsManager:onHUDEditInput() F201Boot.edits = F201Boot.edits + 1 end
FuelStateLedgerBridge = { register = noop, hasLedgerState = function() return false end, applyState = noop }
FuelSettingsHubBridge = { register = noop }
FuelMasterHUDBridge = { register = noop, active = false }
FuelNetworkSyncBridge = { register = noop, active = false }
