--!load: tools/test/lua/f201_model_binding.lua, tools/test/lua/f201_boot.lua, src/FuelContextInput.lua, src/main.lua
-- RSF-F201, FuelCosts input through the REAL src/main.lua driven by its own hooks.
-- Witnesses: the cab set is FC_OPEN_SETTINGS only; FC_TOGGLE_HUD / FC_HUD_EDIT
-- register standalone and the post-load catch-up removes them once MasterHUD is
-- published; a stacked activate with the same owner and mission is a no-op; a
-- non-owner player callback registers nothing. Model binding, not the native one.

local b = g_inputBinding
local wPlayer, wVehicle = PlayerInputComponent.registerActionEvents, InputBinding.endActionEventsModification
T.ok("F201 FC A1 PLAYER wrapper installed at module load", wPlayer ~= F201Boot.nativePlayer)
T.ok("F201 FC A2 VEHICLE wrapper installed at module load", wVehicle ~= F201Boot.nativeVehicle)
local record = FuelCostsManager._f201Input
T.ok("F201 FC A3 record on the FuelCostsManager class table", record ~= nil)

local mission = { getIsClient = function() return true end, getIsServer = function() return true end, cancelLoading = false }
g_currentMission = mission
g_masterHUD = nil

-- GROUP B: load creates the manager and binds it; standalone PLAYER set is three
Mission00.load(mission)
local fcm = g_FuelCostsManager
T.ok("F201 FC B1 manager created and published", fcm ~= nil and mission.fuelCostsManager == fcm)
T.eq("F201 FC B2 owner bound", record.owner, fcm)
local targetsBefore = record.targets
wPlayer({ player = { isOwner = false } })
T.eq("F201 FC B3 non-owner registers nothing", b.attempts, 0)
wPlayer({ player = { isOwner = true } })
T.eq("F201 FC B4 standalone PLAYER set is three", b:totalIn("PLAYER"), 3)
T.ok("F201 FC B5 settings handle", fcm.settingsPanelEventId ~= nil)
T.eq("F201 FC B6 settings row hidden", b.events[fcm.settingsPanelEventId].displayIsVisible, false)
T.eq("F201 FC B7 toggle row labelled", b:first("PLAYER", "FC_TOGGLE_HUD").text, "input_FC_TOGGLE_HUD")
T.eq("F201 FC B8 edit row labelled", b:first("PLAYER", "FC_HUD_EDIT").text, "input_FC_HUD_EDIT")

-- GROUP C: the cab set is FC_OPEN_SETTINGS only
b:beginActionEventsModification("VEHICLE"); b:endActionEventsModification()
T.eq("F201 FC C1 exactly one cab action", b:totalIn("VEHICLE"), 1)
T.eq("F201 FC C2 it is FC_OPEN_SETTINGS", b:count("VEHICLE", "FC_OPEN_SETTINGS"), 1)
T.eq("F201 FC C3 no cab HUD toggle", b:count("VEHICLE", "FC_TOGGLE_HUD"), 0)
T.eq("F201 FC C4 no cab HUD edit", b:count("VEHICLE", "FC_HUD_EDIT"), 0)
T.ok("F201 FC C5 cab identity differs from on-foot", fcm.vehicleSettingsPanelEventId ~= fcm.settingsPanelEventId)
local ev = b:first("VEHICLE", "FC_OPEN_SETTINGS")
ev.callback(ev.targetObject, ev.actionName, 1)
T.eq("F201 FC C6 cab key reaches the manager", F201Boot.opens, 1)
local begun = b.begun
b:beginActionEventsModification("VEHICLE"); b:endActionEventsModification()
T.eq("F201 FC C7 complete cab set: only the engine bracket", b.begun, begun + 1)

-- GROUP D: stacked activate with the same owner and mission is a no-op
Mission00.load(mission)
T.eq("F201 FC D1 no second manager", F201Boot.managersCreated, 1)
T.eq("F201 FC D2 same targets kept", record.targets, targetsBefore)
T.ok("F201 FC D3 existing PLAYER events still owned", b.events[fcm.settingsPanelEventId] ~= nil)

-- GROUP E: MasterHUD published before loadMission00Finished: catch-up retires the HUD rows
g_masterHUD = {}
mission.masterHUD = g_masterHUD
FSBaseMission.update(mission, 16)
Mission00.loadMission00Finished(mission)
T.eq("F201 FC E1 manager initialised", fcm.initialized, true)
T.eq("F201 FC E2 only FC_OPEN_SETTINGS remains on foot", b:totalIn("PLAYER"), 1)
T.eq("F201 FC E3 toggle row gone", b:count("PLAYER", "FC_TOGGLE_HUD"), 0)
T.eq("F201 FC E4 edit row gone", b:count("PLAYER", "FC_HUD_EDIT"), 0)
T.eq("F201 FC E5 toggle handle cleared", fcm.toggleHudEventId, nil)
T.ok("F201 FC E6 settings handle kept", fcm.settingsPanelEventId ~= nil)
local attempts = b.attempts
wPlayer({ player = { isOwner = true } })
T.eq("F201 FC E7 with MasterHUD the wrapper adds nothing", b.attempts, attempts)

-- GROUP F: unload retires without restoring
FSBaseMission.delete(mission)
T.eq("F201 FC F1 record inactive", record.active, false)
T.eq("F201 FC F2 PLAYER wrapper not restored", PlayerInputComponent.registerActionEvents, wPlayer)
T.eq("F201 FC F3 VEHICLE wrapper not restored", InputBinding.endActionEventsModification, wVehicle)
T.eq("F201 FC F4 manager handle dropped", g_FuelCostsManager, nil)
F201Boot.opens = 0
ev.callback(ev.targetObject, ev.actionName, 1)
T.eq("F201 FC F5 retired target forwards nothing", F201Boot.opens, 0)
