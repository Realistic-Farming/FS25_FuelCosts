# Changelog

All notable changes to FS25_FuelCosts will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Changelog tracking for this mod begins **2026-08-23** under the suite-wide ruling
(see the ecosystem ledger, entry for Arissani and Wizard). Prior history lives in
the repo's git history and README.

---

## [Unreleased]

## [1.1.0.0] - 2026-10-12

> **This is not a final release.** It gives everyone, testers and players, new or returning, everything we have built so far, so nobody has to wait on an old version any longer. The Realistic Farming suite is far from done: we are still building and expanding every mod, and completing it could take months, possibly a year. Expect changes and rough edges along the way, and please report anything that looks wrong.

### Added
- A Fuel HUD show/hide toggle in the Control Center, and Control Center actions for Fuel Costs.
- The Fuel HUD follows the base game's HUD theme and can be resized in width.

### Changed
- The economy dial uses the suite's shared option scaling.
- Keyboard defaults are bound and no longer collide with other suite mods; the settings screen shows the live key.
- Settings show their proper names in Settings Hub and the Farm Tablet instead of internal ids.

### Fixed
- Key presses are registered only where they belong (on foot or in a vehicle), and editing the HUD in the suite editor works again.
- Mod reloads during development no longer leave stale hooks behind.

### Added
- Changelog file established (suite ruling 2026-08-22).
- Playtest fixes: FC_TOGGLE_HUD (RShift+U) and FC_HUD_EDIT (RShift+V) chords, manager/HUD/settings, vehicle input hook.
- Control Center action: `FC_OPEN_SETTINGS` opens fuel cost settings from the suite Control Center (requires SettingsHub).

### Fixed
- RSF-F201: cab and on-foot controls stay valid across vehicle entry and exit. Each input context now registers through its own private target, so the PLAYER and VEHICLE registrations no longer share one engine identifier that a cab rebuild wiped. Membership is checked in the wrap's own context, a complete set costs no registration work, and the input wrappers install once per session instead of being restored on every mission teardown. Removed the input-wrapper probe that called a getter the engine does not have (getActionEventDisplayName), which failed on every player callback and cleared the stored id. The settings panel's own pcall of the same getter is untouched here and is a separate follow-up.

## [1.0.0.1] - 2026-08-23

- First entry under changelog tracking.
