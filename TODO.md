# TODO: FS25_FuelCosts

> Ecosystem role: **Markets and Economy** · Part of the Realistic Farming connected suite
> Status: FILLED from the ecosystem audit/baseline, kept current.
> Convention: `[ ]` open · `[~]` in progress · `[x]` done · `[!]` blocked. Newest at the top of each section.

## From the ecosystem audit (Arissani)
- [ ] Decide the bedrock migration scope: stay a lightweight price oracle on `FS25_FuelCosts.xml`, or adopt the four bedrock engines like the economy mods.
- [ ] Confirm the price-read API surface (getDisplayPrice/getTrend/getPriceStatus) is what consumers (DairyCore) need.

## Bugs
- [ ] None from the audit. Charging rides the base-game fill path (no custom hook), so no MP double-charge.

## Features / enhancements
- [ ] None scheduled. The daily price update works as designed.

## Cross-mod integration
- [ ] StateLedger/NetworkSync/MasterHUD/SettingsHub: NOT yet specced for FuelCosts. Blocked on the scope decision above.
- [x] Price-read API for consumers: getDisplayPrice(), getTrend(), getPriceStatus() (read-only, pcall + handle gate).

## Docs / localization
- [ ] Keep all 26 languages in step for any new setting.
- [ ] Update README/version on each release.

## Blocked / waiting on
- [!] Bedrock migration (waits on: the scope decision, whether FuelCosts stays an oracle or joins the full migration).
