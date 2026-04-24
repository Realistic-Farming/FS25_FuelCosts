-- =========================================================
-- FS25 Realistic Fuel Costs - NetworkEvents
-- =========================================================
-- Events:
--   FuelPriceSyncEvent      Server → Clients   broadcast price on day change
--   FuelSettingSyncEvent    Server → Clients   broadcast setting changes
--   FuelSettingChangeEvent  Client → Server    request a setting change (admin validated)
--   FuelRequestSyncEvent    Client → Server    request full state on join
-- =========================================================

-- -------------------------------------------------------
-- FuelPriceSyncEvent
-- -------------------------------------------------------
FuelPriceSyncEvent = {}
FuelPriceSyncEvent.__index = FuelPriceSyncEvent
FuelPriceSyncEvent.TYPE = nil

function FuelPriceSyncEvent.new(currentPrice, shockActive, shockDaysLeft)
    local self = setmetatable({}, FuelPriceSyncEvent)
    self.currentPrice  = currentPrice  or 1.20
    self.shockActive   = shockActive   or false
    self.shockDaysLeft = shockDaysLeft or 0
    return self
end

function FuelPriceSyncEvent:writeStream(_, streamId)
    streamWriteFloat32(streamId, self.currentPrice)
    streamWriteBool(streamId, self.shockActive)
    streamWriteInt8(streamId, self.shockDaysLeft)
end

function FuelPriceSyncEvent:readStream(_, streamId)
    self.currentPrice  = streamReadFloat32(streamId)
    self.shockActive   = streamReadBool(streamId)
    self.shockDaysLeft = streamReadInt8(streamId)
end

function FuelPriceSyncEvent:run(_)
    if g_FuelCostsManager and g_FuelCostsManager.priceEngine then
        local pe = g_FuelCostsManager.priceEngine
        pe.currentPrice  = self.currentPrice
        pe.shockActive   = self.shockActive
        pe.shockDaysLeft = self.shockDaysLeft
        FuelLogger.debug("Price sync received: $%.4f/L", self.currentPrice)
    end
end

-- -------------------------------------------------------
-- FuelSettingChangeEvent  (Client → Server)
-- -------------------------------------------------------
FuelSettingChangeEvent = {}
FuelSettingChangeEvent.__index = FuelSettingChangeEvent
FuelSettingChangeEvent.TYPE = nil
FuelSettingChangeEvent.MAX_ID_LEN = 40

function FuelSettingChangeEvent.new(settingId, value)
    local self = setmetatable({}, FuelSettingChangeEvent)
    self.settingId = settingId or ""
    self.value     = value
    return self
end

function FuelSettingChangeEvent:writeStream(_, streamId)
    streamWriteString(streamId, self.settingId)
    streamWriteString(streamId, tostring(self.value))
end

function FuelSettingChangeEvent:readStream(_, streamId)
    self.settingId = streamReadString(streamId)
    self.valueStr  = streamReadString(streamId)
end

function FuelSettingChangeEvent:run(connection)
    -- TODO: validate admin, apply setting, broadcast FuelSettingSyncEvent
end

-- -------------------------------------------------------
-- FuelSettingSyncEvent  (Server → Clients)
-- -------------------------------------------------------
FuelSettingSyncEvent = {}
FuelSettingSyncEvent.__index = FuelSettingSyncEvent
FuelSettingSyncEvent.TYPE = nil

function FuelSettingSyncEvent.new(settingId, value)
    local self = setmetatable({}, FuelSettingSyncEvent)
    self.settingId = settingId or ""
    self.value     = value
    return self
end

function FuelSettingSyncEvent:writeStream(_, streamId)
    streamWriteString(streamId, self.settingId)
    streamWriteString(streamId, tostring(self.value))
end

function FuelSettingSyncEvent:readStream(_, streamId)
    self.settingId = streamReadString(streamId)
    self.valueStr  = streamReadString(streamId)
end

function FuelSettingSyncEvent:run(_)
    -- TODO: apply received setting to local FuelSettings instance
end

-- -------------------------------------------------------
-- FuelRequestSyncEvent  (Client → Server)
-- -------------------------------------------------------
FuelRequestSyncEvent = {}
FuelRequestSyncEvent.__index = FuelRequestSyncEvent
FuelRequestSyncEvent.TYPE = nil

function FuelRequestSyncEvent.new() return setmetatable({}, FuelRequestSyncEvent) end
function FuelRequestSyncEvent:writeStream(_, _) end
function FuelRequestSyncEvent:readStream(_, _) end

function FuelRequestSyncEvent:run(connection)
    -- Server responds with full price + settings snapshot
    -- TODO: implement full sync response
end

-- -------------------------------------------------------
-- Registration
-- -------------------------------------------------------
function FuelNetworkEvents_Register()
    FuelPriceSyncEvent.TYPE    = NetworkEvent.registerEvent(FuelPriceSyncEvent)
    FuelSettingChangeEvent.TYPE = NetworkEvent.registerEvent(FuelSettingChangeEvent)
    FuelSettingSyncEvent.TYPE  = NetworkEvent.registerEvent(FuelSettingSyncEvent)
    FuelRequestSyncEvent.TYPE  = NetworkEvent.registerEvent(FuelRequestSyncEvent)
    FuelLogger.info("Network events registered")
end
