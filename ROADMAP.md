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

## Mid-term (this season)
- [ ] Decide the bedrock migration scope (see the open question): stay a lightweight oracle, or adopt StateLedger/SettingsHub/NetworkSync/MasterHUD like the economy mods.

## Long-term / aspirational
- [ ] Richer fuel market (regional prices, supply shocks, seasonal swings) without breaking the read API.

## Cross-mod / ecosystem dependencies
- [ ] Consumers reading the price (DairyCore and others) depend on the read API staying stable.

## Deferred / parked
- `logOperatingRun()` / an operating-cost registration API: explicitly not built. Companions compute cost from the price. Do not add it.
