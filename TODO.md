# TODO: FS25_FuelCosts

> Ecosystem role: **Markets and Economy** · Part of the Realistic Farming connected suite
> Status: FILLED from the ecosystem audit/baseline, kept current.
> Convention: `[ ]` open · `[~]` in progress · `[x]` done · `[!]` blocked. Newest at the top of each section.

## From the ecosystem audit (Arissani)
- [x] Bedrock migration scope DECIDED: adopt all four engines (delegate-when-present), price stays a no-addMoney oracle. Built - see Cross-mod integration.
- [ ] Confirm the price-read API surface (getDisplayPrice/getTrend/getPriceStatus) is what consumers (DairyCore) need.

## Bugs
- [x] 2026-07-26 bug sweep: FuelCosts bugs fixed and merged to main. FC-001 (compounding multiplier on rolling price) and FC-006 (MP sync applying multiplier to rolling instead of base) fixed. Applied multiplier to `effectiveBase` in clamp range. All closed.

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

## 2026-10-14 (Fred (via Desk)): keyboard defaults (Wizard, #26)

- [x] `modDesc.xml`: FC_OPEN_SETTINGS on Right Shift + F, FC_HUD_EDIT on Right Shift + minus; `src/ui/FuelSettingsPanel.lua` reads the live key through `src/utils/FcLiveKeyLabel.lua` (new, sourced in `src/main.lua`).
- [ ] Open Fuel Settings works on foot but not in a cab (FC-23, TESTING row 18): not traced yet.
- [~] In game (owed): TESTING row 534.

## 2026-10-14 (Fred (via Desk)): build packaging (MAINTENANCE row 313)

- [x] `build.sh`: keeps the `.git` file out of the zip on both paths, and its Python fallback (taken when there is no `zip` command, as in Git Bash) names the zip `FS25_FuelCosts.zip` instead of after the folder, so `--deploy` copies the zip it just built rather than a missing or stale one.
- [x] Built from a worktree (Python fallback; this machine's Git Bash has no `zip`) before and after this change: development wrote `bf-FuelCosts.zip`, named after the folder, with 21 entries, one of them the worktree `.git` file; this branch writes `FS25_FuelCosts.zip` with 20, exactly that file removed, every other entry byte-identical (CRC), nothing added. The `zip` command path gets the same `.git` exclusion but was not run here.
- Build tooling only, no in-game check (TESTING row 575).
