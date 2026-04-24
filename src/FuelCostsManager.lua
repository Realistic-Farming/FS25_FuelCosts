-- =========================================================
-- FS25 Realistic Fuel Costs - FuelCostsManager
-- =========================================================
-- Central coordinator. Owns all subsystems.
-- Installs game hooks and drives the update loop.
--
-- Global reference: g_FuelCostsManager
-- =========================================================

---@class FuelCostsManager
FuelCostsManager = {}
FuelCostsManager.__index = FuelCostsManager

function FuelCostsManager.new()
    local self = setmetatable({}, FuelCostsManager)

    self.settings        = FuelSettings.new()
    self.settingsManager = FuelSettingsManager.new(self.settings)
    self.priceEngine     = FuelPriceEngine.new(self.settings)
    self.hud             = FuelHUD.new(self.settings, self.priceEngine)

    self.initialized = false
    self.lastDay     = -1

    FuelLogger.info("FuelCostsManager created")
    return self
end

-- -------------------------------------------------------
-- Lifecycle
-- -------------------------------------------------------

function FuelCostsManager:init()
    self:_loadSettings()
    self.hud:init()
    self.hud:updatePosition()
    self:_installHooks()
    FuelNetworkEvents_Register()
    self.initialized = true
    FuelLogger.info("Initialized — base price $%.2f/L", self.settings.baseFuelPrice)
end

function FuelCostsManager:update(dt)
    if not self.initialized or not self.settings.enabled then return end

    -- Day-change tick (server or singleplayer only)
    if g_currentMission and g_currentMission.environment then
        local day = g_currentMission.environment.currentDay or -1
        if day ~= self.lastDay and (g_currentMission.isMasterUser or not g_currentMission.isMultiplayer) then
            self.lastDay = day
            self.priceEngine:onDayChanged(day)
            self:_broadcastPrice()
        end
    end

    self.hud:draw()
end

function FuelCostsManager:delete()
    self:_uninstallHooks()
    if self.hud then self.hud:delete() end
    self.initialized = false
    FuelLogger.info("Deleted")
end

-- -------------------------------------------------------
-- Hooks
-- -------------------------------------------------------

function FuelCostsManager:_installHooks()
    -- TODO: hook the vehicle fuel fill event to charge the player.
    -- Candidate: FuelStation.buyFuel / Vehicle.setFuelFillLevel / FillUnit.addFillUnitFillLevel
    -- Verify exact method + signature in FS25-Community-LUADOC before implementing.
    -- Pattern to use: Utils.appendedFunction(TargetClass, "methodName", hookFn)
    FuelLogger.info("Hooks installed (stub)")
end

function FuelCostsManager:_uninstallHooks()
    -- TODO: remove all appended functions installed above
    FuelLogger.info("Hooks removed (stub)")
end

-- Called by the fuel fill hook when a vehicle is refuelled
function FuelCostsManager:onVehicleFuelled(litresFilled, vehicle)
    if not self.settings.enabled then return end
    if litresFilled <= 0 then return end

    local cost = self.priceEngine:chargeFill(litresFilled)

    if self.settings.showNotifications and cost >= FuelConstants.NOTIFICATION.COST_THRESHOLD then
        local msg = string.format(
            g_i18n:getText("fc_notification_fill") or "Fuelled %.0fL — $%.2f",
            litresFilled, cost
        )
        -- TODO: verify notification API in LUADOC
        -- g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, msg)
        FuelLogger.debug(msg)
    end
end

-- -------------------------------------------------------
-- Multiplayer
-- -------------------------------------------------------

function FuelCostsManager:_broadcastPrice()
    if not g_currentMission or not g_currentMission.isMultiplayer then return end
    local pe = self.priceEngine
    g_currentMission:broadcastEvent(
        FuelPriceSyncEvent.new(pe.currentPrice, pe.shockActive, pe.shockDaysLeft)
    )
end

-- -------------------------------------------------------
-- Save / Load
-- -------------------------------------------------------

function FuelCostsManager:_loadSettings()
    local path = g_currentMission and g_currentMission.missionInfo
        and g_currentMission.missionInfo.savegameDirectory
    if not path then return end

    local xmlPath = path .. "/FS25_FuelCosts.xml"
    local xmlFile = XMLFile.loadIfExists("FuelCostsSettings", xmlPath)
    if not xmlFile then return end

    self.settingsManager:loadFromXML(xmlFile, FuelConstants.SAVE.XML_KEY .. ".settings")
    self.priceEngine:loadFromXML(xmlFile, FuelConstants.SAVE.XML_KEY .. ".price")
    xmlFile:delete()
    FuelLogger.info("Settings loaded from %s", xmlPath)
end

function FuelCostsManager:save()
    local path = g_currentMission and g_currentMission.missionInfo
        and g_currentMission.missionInfo.savegameDirectory
    if not path then return end

    local xmlPath = path .. "/FS25_FuelCosts.xml"
    local xmlFile = XMLFile.create("FuelCostsSettings", xmlPath, FuelConstants.SAVE.XML_KEY)
    if not xmlFile then return end

    self.settingsManager:saveToXML(xmlFile, FuelConstants.SAVE.XML_KEY .. ".settings")
    self.priceEngine:saveToXML(xmlFile, FuelConstants.SAVE.XML_KEY .. ".price")
    xmlFile:save()
    xmlFile:delete()
    FuelLogger.info("Saved to %s", xmlPath)
end

-- -------------------------------------------------------
-- Console commands
-- -------------------------------------------------------

function FuelCostsManager:registerConsoleCommands()
    addConsoleCommand("FuelCostsInfo",       "Show current fuel price",          "consoleInfo",    self)
    addConsoleCommand("FuelCostsSetPrice",   "Set base fuel price (e.g. 1.50)", "consoleSetPrice", self)
    addConsoleCommand("FuelCostsDebug",      "Toggle debug logging",             "consoleDebug",   self)
end

function FuelCostsManager:consoleInfo()
    FuelLogger.info("Current price: $%.4f/L | Status: %s | Shock: %s",
        self.priceEngine:getDisplayPrice(),
        self.priceEngine:getPriceStatus(),
        tostring(self.priceEngine.shockActive))
end

function FuelCostsManager:consoleSetPrice(val)
    local p = tonumber(val)
    if not p then FuelLogger.warning("Usage: FuelCostsSetPrice <number>") ; return end
    self.settings.baseFuelPrice = math.max(0.10, math.min(10.0, p))
    self.priceEngine.currentPrice = self.settings.baseFuelPrice
    FuelLogger.info("Base price set to $%.4f/L", self.settings.baseFuelPrice)
end

function FuelCostsManager:consoleDebug()
    self.settings.debugMode = not self.settings.debugMode
    FuelLogger.info("Debug mode: %s", tostring(self.settings.debugMode))
end
