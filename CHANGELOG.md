# Changelog

All notable changes to FS25_FuelCosts will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Changelog tracking for this mod begins **2026-08-23** under the suite-wide ruling
(see the ecosystem ledger, entry for Arissani and Wizard). Prior history lives in
the repo's git history and README.

---

## [Unreleased]

### Added
- Changelog file established (suite ruling 2026-08-22).
- Playtest fixes: FC_TOGGLE_HUD (RShift+U) and FC_HUD_EDIT (RShift+V) chords, manager/HUD/settings, vehicle input hook.
- Control Center action: `FC_OPEN_SETTINGS` opens fuel cost settings from the suite Control Center (requires SettingsHub).

### Fixed
- RSF-F201: cab and on-foot controls stay valid across vehicle entry and exit. Each input context now registers through its own private target, so the PLAYER and VEHICLE registrations no longer share one engine identifier that a cab rebuild wiped. Membership is checked in the wrap's own context, a complete set costs no registration work, and the input wrappers install once per session instead of being restored on every mission teardown. Removed the input-wrapper probe that called a getter the engine does not have (getActionEventDisplayName), which failed on every player callback and cleared the stored id. The settings panel's own pcall of the same getter is untouched here and is a separate follow-up.

## [1.0.0.1] - 2026-08-23

- First entry under changelog tracking.
