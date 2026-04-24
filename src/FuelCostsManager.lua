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
    self.settingsPanel   = FuelSettingsPanel.new(self)

    self.initialized = false
    self.lastDay     = -1

    self._wasFueling       = false
    self._fuelSessionAdded = 0
    self._fuelStopTimer    = 0

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
    FuelNetworkEvents_Register()
    -- Apply initial price to DIESEL fill type immediately so it's
    -- correct from the first fill even before the first day tick
    self.priceEngine:applyToFillTypes()

    -- Hook FillTrigger.fillVehicle to detect refueling events.
    -- FillTrigger is a plain class (not a specialization), so this appended
    -- function fires for every client-visible fill trigger call.
    Utils.appendedFunction(FillTrigger, "fillVehicle", function(trigger, vehicle, delta, dt)
        if g_FuelCostsManager then
            g_FuelCostsManager:_onFillTriggerFill(vehicle, trigger.fillTypeIndex, delta)
        end
    end)

    self.initialized = true
    FuelLogger.info("Initialized — base price $%.2f/L, current $%.4f/L",
        self.settings.baseFuelPrice, self.priceEngine.currentPrice)
end

function FuelCostsManager:update(dt)
    if not self.initialized then return end

    if self.settingsPanel then self.settingsPanel:update() end
    if self.hud           then self.hud:update(dt)         end

    if not self.settings.enabled then return end

    -- Session-end timer: fires "X litres — $Y" after 1.5 s of no fill events
    if self.settings.showNotifications and self._wasFueling then
        self._fuelStopTimer = self._fuelStopTimer + dt / 1000
        if self._fuelStopTimer >= 1.5 then
            self._wasFueling = false
            FuelLogger.debug("Notif: refuel session ENDED — %.1fL added", self._fuelSessionAdded)
            if self._fuelSessionAdded > 0.1 then
                local cost   = self._fuelSessionAdded * self.priceEngine:getDisplayPrice()
                local modEnv = g_modEnvironments and g_modEnvironments[g_currentModName]
                local i18n   = (modEnv and modEnv.i18n) or g_i18n
                local fmt    = (i18n and i18n:getText("fc_notification_fill")) or "Fuelled %.0fL — $%.2f"
                self.hud:flash(string.format(fmt, self._fuelSessionAdded, cost))
            end
            self._fuelSessionAdded = 0
            self._fuelStopTimer    = 0
        end
    end

    -- Day-change tick (server or singleplayer only)
    if g_currentMission and g_currentMission.environment then
        local day = g_currentMission.environment.currentDay or -1
        if day ~= self.lastDay and g_server ~= nil then
            self.lastDay = day
            self.priceEngine:onDayChanged(day)
            self:_broadcastPrice()
        end
    end
end

function FuelCostsManager:delete()
    if self.settingsPanel then self.settingsPanel:delete() end
    -- Restore DIESEL pricePerLiter so other mods/saves aren't affected
    self.priceEngine:restoreOriginalPrices()
    if self.hud then self.hud:delete() end
    self.initialized = false
    FuelLogger.info("Deleted")
end

-- -------------------------------------------------------
-- Refuel notification (hook-driven)
-- -------------------------------------------------------

function FuelCostsManager:_onFillTriggerFill(vehicle, fillTypeIndex, delta)
    if not self.initialized or not self.settings.enabled or not self.settings.showNotifications then return end
    if not vehicle or not vehicle.getActiveFarm then return end
    if fillTypeIndex ~= FillType.DIESEL then return end
    if delta <= 0 then return end

    local localFarmId = g_localPlayer and g_localPlayer.farmId or 1
    if vehicle:getActiveFarm() ~= localFarmId then return end

    if not self._wasFueling then
        self._wasFueling       = true
        self._fuelSessionAdded = 0
        self._fuelStopTimer    = 0
        FuelLogger.debug("Notif: refuel session STARTED")
        local modEnv  = g_modEnvironments and g_modEnvironments[g_currentModName]
        local i18n    = (modEnv and modEnv.i18n) or g_i18n
        local startMsg = (i18n and i18n:getText("fc_notification_refueling")) or "Refueling..."
        self.hud:flash(startMsg, {0.55, 0.80, 0.95, 1.0}, 2.5)
    end

    self._fuelSessionAdded = self._fuelSessionAdded + delta
    self._fuelStopTimer    = 0
end

-- -------------------------------------------------------
-- Day-change price application
-- -------------------------------------------------------
-- No fill hook needed. Payment is handled entirely by
-- FillTrigger:fillVehicle() → economyManager:getPricePerLiter()
-- → fillType.pricePerLiter, which we update each game day.
-- See FuelPriceEngine:applyToFillTypes() for details.

-- -------------------------------------------------------
-- Multiplayer
-- -------------------------------------------------------

function FuelCostsManager:_broadcastPrice()
    if g_server == nil then return end
    local pe = self.priceEngine
    g_server:broadcastEvent(
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
-- Settings panel
-- -------------------------------------------------------

function FuelCostsManager:onOpenSettingsInput()
    if self.settingsPanel then
        self.settingsPanel:toggle()
    end
end

-- Admin-only: force a price tick for testing (server/SP only)
function FuelCostsManager:debugForceTick()
    if g_server == nil then return end
    self.lastDay = self.lastDay + 1
    self.priceEngine:onDayChanged(self.lastDay)
    self:_broadcastPrice()
    FuelLogger.info("Force tick — new price: $%.4f/L", self.priceEngine.currentPrice)
end

-- -------------------------------------------------------
-- Console commands
-- -------------------------------------------------------

function FuelCostsManager:registerConsoleCommands()
    addConsoleCommand("FuelCostsInfo",       "Show current fuel price",             "consoleInfo",      self)
    addConsoleCommand("FuelCostsSetPrice",   "Set base fuel price (e.g. 1.50)",    "consoleSetPrice",  self)
    addConsoleCommand("FuelCostsDebug",      "Toggle debug logging",                "consoleDebug",     self)
    addConsoleCommand("FuelCostsTestNotif",  "Fire a test flash notification",      "consoleTestNotif", self)
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

function FuelCostsManager:consoleTestNotif()
    self.hud:flash("⛽ Refueling...", {0.55, 0.80, 0.95, 1.0}, 2.5)
    self.hud:flash("Fuelled 50L — $60.00")
    FuelLogger.info("Test notifications fired — check screen for flash")
end
