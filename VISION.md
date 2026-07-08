# Vision: FS25_FuelCosts

> Ecosystem role: **Markets and Economy** · Part of the Realistic Farming connected suite
> Status: FILLED from the ecosystem audit (Point 1-3, ecosystem-map, notes).
> Last updated: 2026-07-08

## 1. One-line purpose
A dynamic fuel economy: diesel and DEF prices move day to day with a trend and a status, so refueling is a real, fluctuating operating cost instead of a fixed line item.

## 2. Problem it solves
FS25 fuel prices are static. Fuel never becomes a decision. FuelCosts turns fuel into a live cost by moving `pricePerLiter` for diesel and DEF on a daily cycle, with a readable price trend and status, so fuel planning matters.

## 3. Design pillars
- **Price oracle, not a charger.** FuelCosts sets the fill type's `pricePerLiter` once per game day; the base game's own fill trigger does the charging. No fill hook, no double-charge.
- **Read-only for companions.** Peer mods read the current price and calculate their own operating costs. FuelCosts deliberately exposes no "log a run" registration API.
- **Lightweight.** One save file, one daily update, minimal surface.
- **Multiplayer-safe.** Charging rides the base-game fill path, which is already networked.

## 4. Role in the ecosystem
- Public handle on `g_currentMission.fuelCostsManager` (getfenv alias `g_FuelCostsManager`), set in `Mission00.load`.
- Reads from (consumes): nothing cross-mod. It sets base-game fill-type prices.
- Read by (consumers): DairyCore and any companion needing a fuel price, via `getDisplayPrice()`, `getTrend()`, `getPriceStatus()` (read the price, compute cost internally, store in your own data model).
- Core-API registration status: NOT yet specced. The audit covered detection/handle, the price-read API, and confirmed there is no registration API. The four-bedrock migration (StateLedger/NetworkSync/MasterHUD/SettingsHub) has not been designed for FuelCosts; it currently uses its own `FS25_FuelCosts.xml` (root `fuelCosts`, settings + state in one file).

## 5. Explicit non-goals
- No operating-cost ledger. `logOperatingRun()` does not exist and is not planned; companions calculate their own costs from the price.
- No fill-event hook. The base game charges automatically; adding a hook would double-charge.

## 6. Success criteria
- Diesel/DEF prices move believably day to day and are cheap to read.
- Companion mods can read the current price safely (pcall + handle gate) and derive their own costs.
- Charging stays base-game-correct and MP-safe (no custom fill hook).

## 7. Open questions for the audit
- Should FuelCosts take the full four-bedrock migration like the economy mods, or stay a lightweight price oracle on its own save file? Decide the scope.
- If it migrates: does price state belong in StateLedger, and does a price change need a NetworkSync broadcast, or is the daily deterministic update enough for clients to compute locally?
