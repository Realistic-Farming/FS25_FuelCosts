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
    FuelNetworkEvents_Register()
    -- Apply initial price to DIESEL fill type immediately so it's
    -- correct from the first fill even before the first day tick
    self.priceEngine:applyToFillTypes()
    self.initialized = true
    FuelLogger.info("Initialized — base price $%.2f/L, current $%.4f/L",
        self.settings.baseFuelPrice, self.priceEngine.currentPrice)
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
    -- Restore DIESEL pricePerLiter so other mods/saves aren't affected
    self.priceEngine:restoreOriginalPrices()
    if self.hud then self.hud:delete() end
    self.initialized = false
    FuelLogger.info("Deleted")
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
