# TODO: FS25_FuelCosts

> Ecosystem role: **Markets and Economy** · Part of the Realistic Farming connected suite
> Status: FILLED from the ecosystem audit/baseline, kept current.
> Convention: `[ ]` open · `[~]` in progress · `[x]` done · `[!]` blocked. Newest at the top of each section.

## From the ecosystem audit (Arissani)
- [x] Bedrock migration scope DECIDED: adopt all four engines (delegate-when-present), price stays a no-addMoney oracle. Built - see Cross-mod integration.
- [ ] Confirm the price-read API surface (getDisplayPrice/getTrend/getPriceStatus) is what consumers (DairyCore) need.

## Bugs
- [ ] None from the audit. Charging rides the base-game fill path (no custom hook), so no MP double-charge.

## Features / enhancements
- [ ] None scheduled. The daily price update works as designed.

## Cross-mod integration
- [x] All four bedrock bridges LIVE (delegate-when-present; own FS25_FuelCosts.xml + sync events kept as the standalone fallback). Commits 3a9ef4b + 03d22e8:
  - StateLedger `FuelCosts_Price` (currentPrice / lastDay / shock state; force-parseFile, overrides the XML price when present).
  - NetworkSync full daily price SNAPSHOT (id `FS25_FuelCosts`, channel `FuelCosts_Sync`; mirrors FuelPriceSyncEvent, delegates _broadcastPrice + client join). No addMoney (price oracle).
  - MasterHUD `FuelCosts_HUD` (price HUD + settings panel; own draw stands down).
  - SettingsHub `FuelCosts` (bare name, selfPersisted, schema-walked). Owed: two-machine MP test.
- [x] Price-read API for consumers: getDisplayPrice(), getTrend(), getPriceStatus() (read-only, pcall + handle gate).

## Docs / localization
- [ ] Keep all 26 languages in step for any new setting.
- [ ] Update README/version on each release.

## Blocked / waiting on
- [x] Bedrock migration DONE - all four bridges built (commits 3a9ef4b + 03d22e8). Only the whole-wave two-machine MP test remains.
