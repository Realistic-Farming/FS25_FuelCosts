-- =========================================================
-- FS25 Realistic Fuel Costs - Constants
-- =========================================================
-- All tunable values live here. Do not hardcode elsewhere.
-- =========================================================

FuelConstants = {

    -- Base pricing (per litre, in game currency)
    PRICE = {
        DEFAULT_BASE        = 1.20,   -- default price per litre
        MIN_MULTIPLIER      = 0.50,   -- floor: price never drops below 50% of base
        MAX_MULTIPLIER      = 2.50,   -- ceiling: price never exceeds 250% of base
        PRICE_PRECISION     = 4,      -- decimal places for price display
    },

    -- Daily fluctuation ranges by volatility setting
    -- Values are max ± percentage swing per game day
    VOLATILITY = {
        NONE    = 0.00,
        LOW     = 0.03,   -- ±3%  per day
        MEDIUM  = 0.07,   -- ±7%  per day
        HIGH    = 0.14,   -- ±14% per day
    },

    -- Seasonal price modifiers (multiplied on top of base)
    -- FS25 currentSeason is 0-indexed: 0=Spring, 1=Summer, 2=Autumn, 3=Winter
    SEASONAL = {
        [0] = 0.97,   -- Spring  — mild demand
        [1] = 1.00,   -- Summer  — baseline
        [2] = 1.05,   -- Autumn  — harvest season peak
        [3] = 1.10,   -- Winter  — cold weather premium
    },

    -- Market shock events (random spikes/dips)
    SHOCK = {
        CHANCE_PER_DAY  = 0.03,   -- 3% chance a shock begins each day
        MIN_MAGNITUDE   = 0.15,   -- minimum ±15% shock
        MAX_MAGNITUDE   = 0.35,   -- maximum ±35% shock
        MIN_DURATION    = 3,      -- shortest shock in game days
        MAX_DURATION    = 7,      -- longest shock in game days
    },

    -- Difficulty multipliers applied to the final price
    DIFFICULTY = {
        SIMPLE    = 0.60,
        REALISTIC = 1.00,
        HARDCORE  = 1.50,
    },

    -- Notification display
    NOTIFICATION = {
        SHOW_DURATION_MS    = 4000,
        COST_THRESHOLD      = 1.00,   -- only notify if fill cost exceeds this amount
    },

    -- HUD
    HUD = {
        WIDTH               = 0.10,
        HEIGHT              = 0.04,
        PADDING             = 0.008,
        FONT_SIZE           = 0.018,
        BG_ALPHA            = 0.75,
        -- Price status colour thresholds (fraction of base price)
        COLOR_CHEAP         = 0.80,   -- below 80% of base → green
        COLOR_EXPENSIVE     = 1.25,   -- above 125% of base → red
    },

    -- Network
    NETWORK = {
        SYNC_RETRY_ATTEMPTS = 3,
        SYNC_RETRY_DELAY_MS = 5000,
    },

    -- Save/load XML key
    SAVE = {
        XML_KEY             = "fuelCosts",
    },
}
