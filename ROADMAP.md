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
