# Roadmap: FS25_FuelCosts

> Ecosystem role: **Markets and Economy** · Part of the Realistic Farming connected suite
> Status: FILLED from the ecosystem audit/baseline.
> Forward-looking only. Shipped history lives in CHANGELOG.md and the releases.

## How to use this file
- Populate the milestones below from the audit baseline once it lands.
- Each item should be small enough to map to a `TODO.md` entry.
- Keep it honest: near-term is committed, mid-term is intended, long-term is aspirational.

## Current baseline
- Version at baseline: see modDesc.xml (price-oracle build)
- Audit reference: ecosystem-dev-tracking Point 1-3 (FS25_FuelCosts, 2026-06-29)
- Baseline date: 2026-06-29

## Near-term (next release cycle)
- [ ] Keep the price-read API stable for consumers: getDisplayPrice(), getTrend(), getPriceStatus() are the contract; do not rename.
- [x] 2026-07-26 bug sweep: FC-001 (compounding multiplier) and FC-006 (MP sync multiplier placement) fixed and merged to main.

## Mid-term (this season)
- [x] Bedrock migration scope DECIDED and built: adopted all four engines (StateLedger + NetworkSync + MasterHUD + SettingsHub, delegate-when-present; commits 3a9ef4b + 03d22e8). Price stays a no-addMoney oracle. Whole-wave two-machine MP test still owed.

## Long-term / aspirational
- [ ] Richer fuel market (regional prices, supply shocks, seasonal swings) without breaking the read API.

## Cross-mod / ecosystem dependencies
- [ ] Consumers reading the price (DairyCore and others) depend on the read API staying stable.

## Deferred / parked
- `logOperatingRun()` / an operating-cost registration API: explicitly not built. Companions compute cost from the price. Do not add it.

## 2026-10-14 (Fred (via Desk)): keyboard defaults (Wizard, #26)

- [x] Open Fuel Settings is bound to Right Shift + F (it was unbound). Toggle HUD stays on Right Shift + U; HUD edit moves from Right Shift + V (Soil's Variable Rate) to Right Shift + minus. The settings panel's close hint names the live key only when one is bound, and otherwise reads 'click X to close' (`src/utils/FcLiveKeyLabel.lua`). Open Fuel Settings not opening from a cab is a separate open report (TESTING row 18). (Wizard's #26, merged at 4d40b9a6 on 2026-10-11, one PR of his keyboard-defaults wave.)
- The in-game check is TESTING row 534. Docs by Fred's catch-up (R-51), on Tyson's word of 2026-10-14.

## 2026-10-14 (Fred (via Desk)): the build script packs only the mod (MAINTENANCE row 313)

- [x] `build.sh` keeps the `.git` file out of the zip on both paths, and its Python fallback (taken when there is no `zip` command, as in Git Bash) names the zip `FS25_FuelCosts.zip` instead of after the folder, so `--deploy` copies the zip it just built rather than a missing or stale one.
- Build tooling only, no in-game check (TESTING row 575). Found by a fleet sweep that built every mod once from development in a throwaway worktree, on Tyson's word of 2026-10-14.
