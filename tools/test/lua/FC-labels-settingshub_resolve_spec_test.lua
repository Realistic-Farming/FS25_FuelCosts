-- FC-labels-settingshub_resolve_spec_test.lua - the names the tablet shows for Fuel Costs settings.
--
-- WHY THIS EXISTS. FarmTablet renders the label string as-is, with no l10n lookup of its own, so
-- the human name has to be resolved on this side. resolveLabel is a ladder: the "<uiId>_short"
-- key, then "fc_setting_<id>", then a hardcoded English table, then the raw uiId. The ladder's
-- whole point is that a real translation always beats a hardcoded English one.
--
-- It was possible to defeat that from the other end. A "<uiId>_short" key carrying English in all
-- 26 languages sits on rung 1 and always hits, so "fc_setting_enabled" on rung 2 - which holds
-- real translations ("Kraftstoffkosten aktivieren", "Activer les couts de carburant") - was never
-- reached. The ladder was keeping a translation the l10n was throwing away.
--
-- The bar starts where production starts: FuelSettingsHubBridge.register, which is what builds
-- label = resolveLabel(def) for every schema entry and hands them to the hub. g_i18n is stubbed
-- to carry exactly the keys the modDesc carries, so the l10n content is under test too, not just
-- the ladder's code.
--
--!load: src/config/SettingsSchema.lua, src/integrations/FuelSettingsHubBridge.lua

FuelLogger = FuelLogger or { info = function() end, warning = function() end, error = function() end }

local GERMAN_ENABLED = "Kraftstoffkosten aktivieren"

--- g_i18n as the engine presents it, carrying exactly the given keys.
local function i18nWith(keys)
    g_i18n = {
        hasText = function(_, k) return keys[k] ~= nil end,
        getText = function(_, k) return keys[k] end,
    }
end

--- Run production's registration and hand back the defs the hub was given, keyed by id.
local function registeredLabels()
    local captured = nil
    g_currentMission = g_currentMission or {}
    g_currentMission.settingsHub = {
        registerModule = function(_, _, payload) captured = payload end,
    }
    local mgr = { settings = {} }
    for _, def in ipairs(FuelSettingsSchema.definitions) do mgr.settings[def.id] = def.default end
    FuelSettingsHubBridge.register(mgr)
    if captured == nil or captured.adminSettings == nil then return nil end
    local byId = {}
    for _, d in ipairs(captured.adminSettings) do byId[d.id] = d.label end
    return byId, captured
end

-- ---- 1. the modDesc as it now stands: rung 2 serves the translation ----------------------
do
    -- exactly what the l10n carries after fc_enabled_short was dropped
    i18nWith({ fc_setting_enabled = GERMAN_ENABLED })
    local labels, payload = registeredLabels()
    T.ok("the bridge registered with the hub", labels ~= nil)
    if labels ~= nil then
        T.eq("the enabled setting shows its real translation, not an English stub",
            labels.enabled, GERMAN_ENABLED)
        T.ok("and it is not the hardcoded English", labels.enabled ~= "Fuel Costs Enabled")
        T.eq("a setting with no l10n at all falls to the English table, never the raw uiId",
            labels.baseFuelPrice, "Base Fuel Price")
        T.eq("and the last one too", labels.debugMode, "Debug Mode")
        T.eq("every schema entry reached the hub", #payload.adminSettings,
            #FuelSettingsSchema.definitions)
    end
end

-- ---- 2. the defect this PR removed, kept explicit so a re-add is a conscious act ----------
do
    -- rung 1 present and English, which is what the dropped fc_enabled_short did
    i18nWith({ fc_enabled_short = "Fuel Costs Enabled", fc_setting_enabled = GERMAN_ENABLED })
    local labels = registeredLabels()
    T.ok("with a _short key present it wins the ladder", labels ~= nil)
    if labels ~= nil then
        T.eq("which is exactly how the translation was being thrown away",
            labels.enabled, "Fuel Costs Enabled")
    end
    -- so: a _short key must never carry English for a setting that has a translated
    -- fc_setting_<id>. Rung 1 is for names the fc_setting_ keys do not cover.
end

-- ---- 3. a real translation on rung 1 is still honoured ------------------------------------
do
    i18nWith({ fc_enabled_short = GERMAN_ENABLED, fc_setting_enabled = "Enable Fuel Costs" })
    local labels = registeredLabels()
    if labels ~= nil then
        T.eq("rung 1 is not the problem when it carries the translation",
            labels.enabled, GERMAN_ENABLED)
    end
end

-- ---- 4. no l10n at all: the English table, and never a raw uiId --------------------------
do
    i18nWith({})
    local labels = registeredLabels()
    T.ok("registration still succeeds with no l10n", labels ~= nil)
    if labels ~= nil then
        local raw = 0
        for _, def in ipairs(FuelSettingsSchema.definitions) do
            if labels[def.id] == def.uiId then raw = raw + 1 end
        end
        T.eq("no setting falls through to its raw uiId", raw, 0)
        T.eq("the hardcoded English serves instead", labels.enabled, "Fuel Costs Enabled")
        T.eq("including the hud position", labels.hudPosition, "HUD Position")
    end
end

-- ---- 5. an empty string is not a name ------------------------------------------------------
do
    i18nWith({ fc_setting_enabled = "" })
    local labels = registeredLabels()
    if labels ~= nil then
        T.eq("an empty translation is skipped, not shown as a blank row",
            labels.enabled, "Fuel Costs Enabled")
    end
end
