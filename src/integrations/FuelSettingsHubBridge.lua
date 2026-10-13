-- =========================================================
-- FS25 Realistic Fuel Costs - SettingsHub bridge
-- =========================================================
-- Author: TisonK
-- =========================================================
-- Optional bridge to FS25_SettingsHub. Safe if SettingsHub is not installed
-- (register() just no-ops). Purpose: let the FarmTablet System Settings app
-- list Fuel Costs' settings.
--
-- This mod has a single source of truth for its settings -- FuelSettingsSchema
-- (config/SettingsSchema.lua) -- so, like SoilFertilizer, this walks the schema
-- directly instead of hand-listing each field. def.localOnly maps 1:1 onto
-- SettingsHub's adminOnly = false (both mean "per-player, not server-shared").
--
-- Real editing still goes through the in-game FuelSettingsPanel; this bridge
-- mirrors current values into SettingsHub for display and applies edits made
-- through SettingsHub minimally (SettingsHub validates by the def before calling
-- onChange, so applyChange only sets the value and applies the obvious HUD side
-- effect). Our own FS25_FuelCosts.xml stays the source of truth (selfPersisted).
-- =========================================================

FuelSettingsHubBridge = FuelSettingsHubBridge or {}

-- FarmTablet renders the label string as-is (no l10n lookup on its end), so resolve
-- each setting's human-readable name here from its "<uiId>_short" key, falling back
-- to the uiId if it is not translated.
-- BUILD 17:48 (George CLOSED DESIGN 17:40 item 3): the human names, because the tablet renders
-- this string as-is and the mod shipped no _short key for any of them, so every row read as its
-- raw uiId: "fc_enabled", "fc_basePrice". Keyed by SCHEMA ID, which is stable, rather than by uiId.
local HUMAN_LABEL = {
    enabled           = "Fuel Costs Enabled",
    baseFuelPrice     = "Base Fuel Price",
    difficulty        = "Difficulty",
    priceVolatility   = "Price Volatility",
    seasonalEffects   = "Seasonal Effects",
    marketShocks      = "Market Shocks",
    showNotifications = "Show Notifications",
    hudEnabled        = "HUD Enabled",
    hudPosition       = "HUD Position",
    debugMode         = "Debug Mode",
}

--- A ladder, so a real translation always beats a hardcoded English one.
--- 1. "<uiId>_short", which is what this mod's l10n now carries.
--- 2. "fc_setting_<id>". The mod already had fc_setting_enabled translated into 26 languages, and
---    going straight to the table would have thrown that away for the one setting that has one.
--- 3. The table above, which is correct English for every setting in the schema.
--- 4. The raw uiId, which is what the player used to see and is now only a last resort.
local function resolveLabel(def)
    local base = def.uiId or def.id
    if g_i18n ~= nil and g_i18n.hasText ~= nil then
        for _, key in ipairs({ base .. "_short", "fc_setting_" .. tostring(def.id) }) do
            if g_i18n:hasText(key) then
                local text = g_i18n:getText(key)
                if type(text) == "string" and text ~= "" then
                    return text
                end
            end
        end
    end
    local human = HUMAN_LABEL[def.id]
    if type(human) == "string" and human ~= "" then
        return human
    end
    return base
end

local function applyChange(key, value)
    local mgr = g_FuelCostsManager
    if mgr == nil or mgr.settings == nil then return end
    mgr.settings[key] = value
    -- HUD-affecting keys need an immediate reposition; everything else is read live.
    if (key == "hudEnabled" or key == "hudPosition") and mgr.hud ~= nil and mgr.hud.updatePosition ~= nil then
        mgr.hud:updatePosition()
    end
end

function FuelSettingsHubBridge.register(mgr)
    -- The reliable cross-mod handle is g_currentMission.settingsHub (the same one
    -- FarmTablet reads). The bare g_settingsHub global is only visible inside
    -- SettingsHub's own mod environment, so it reads back nil from here.
    local hub = (g_currentMission ~= nil and g_currentMission.settingsHub) or g_settingsHub
    if hub == nil then
        FuelLogger.info("SettingsHub not detected; skipping tablet registration")
        return
    end
    if mgr == nil or mgr.settings == nil then return end

    local defs = {}
    for _, def in ipairs(FuelSettingsSchema.definitions) do
        local shType
        if def.type == "bool" then
            shType = "bool"
        elseif def.type == "int" then
            shType = "int"
        elseif def.type == "float" then
            shType = "float"
        end

        if shType ~= nil then
            defs[#defs + 1] = {
                id        = def.id,
                type      = shType,
                default   = mgr.settings[def.id],
                adminOnly = not def.localOnly,
                label     = resolveLabel(def),
            }
        end
    end

    local ok, err = pcall(function()
        hub:registerModule("FuelCosts", {
            adminSettings = defs,
            onChange      = function(key, value, playerId) applyChange(key, value) end,
            -- We own our persistence (FS25_FuelCosts.xml, loaded in FuelCostsManager:init
            -- before this registration runs), so the hub must mirror for display only:
            -- never restore its own stale copy and replay it back through onChange on load
            -- (the SoilFertilizer disable-on-load trap).
            selfPersisted = true,
        })
    end)

    if ok then
        FuelLogger.info("Registered with SettingsHub (%d setting(s))", #defs)
    else
        FuelLogger.warning("SettingsHub registration failed: %s", tostring(err))
    end
end
