# FS25_FuelCosts — Realistic Fuel Costs

> **Diesel isn't free. Every litre counts.**

![Status](https://img.shields.io/badge/status-WIP-orange)
![Version](https://img.shields.io/badge/version-0.1.0-blue)
![Platform](https://img.shields.io/badge/FS25-Farming%20Simulator%2025-green)
![Multiplayer](https://img.shields.io/badge/multiplayer-supported-brightgreen)

---

## What is this?

In real farming, diesel is one of the biggest operating costs — up to 50% of variable expenses on a working farm. In Farming Simulator 25, fuel is completely free. **Realistic Fuel Costs** fixes that.

Fill up at any fuel station and pay the market rate. The price isn't fixed — it moves every game day based on seasonal demand, market forces, and occasional supply shocks. Plan your big harvest runs around cheap fuel days. Watch the price spike in autumn when everyone's combining.

One mechanic. Universal impact. No new systems to learn.

---

## Features

| Feature | Status |
|---------|--------|
| Dynamic daily fuel pricing | 🔧 WIP |
| Seasonal price modifiers (autumn peak, winter premium) | 🔧 WIP |
| Random market shock events (±15–35% for 3–7 days) | 🔧 WIP |
| Live price HUD (colour-coded: green / white / red) | 🔧 WIP |
| Fill cost notification on refuel | 🔧 WIP |
| Configurable base price, volatility, and difficulty | 🔧 WIP |
| Server-authoritative pricing in multiplayer | 🔧 WIP |
| Price state persists across save/load | 🔧 WIP |
| MarketDynamics integration (oil price world event) | 📋 Planned |
| Console commands for debugging and price override | 🔧 WIP |
| 26-language localization | 🔧 WIP |

---

## How It Works

### Daily Price Engine
Each game day, the engine runs a random walk on the current price — up or down by a configurable percentage. Seasonal modifiers layer on top: autumn harvest season pushes prices up, spring is mild. Occasionally, a market shock event hits — a multi-day spike or dip that simulates real-world supply disruptions.

### Difficulty Multipliers
| Difficulty | Multiplier | Feel |
|------------|-----------|------|
| Simple | ×0.60 | Noticeable but forgiving |
| Realistic | ×1.00 | Real-world ballpark |
| Hardcore | ×1.50 | Fuel costs dominate your margins |

### Volatility Modes
| Mode | Daily swing | Feel |
|------|------------|------|
| None | 0% | Stable seasonal curve only |
| Low | ±3% | Gentle drift |
| Medium | ±7% | Market realism (default) |
| High | ±14% | Volatile — plan carefully |

### HUD
A small persistent display shows the current diesel price per litre, colour-coded:
- 🟢 **Green** — below 80% of base price (buy now)
- ⚪ **White** — normal range
- 🔴 **Red** — above 125% of base price (expensive)

---

## Compatibility

| Mod | Status |
|-----|--------|
| FS25_MarketDynamics | Planned integration — oil price event will affect fuel price |
| FS25_WorkerCosts | Works alongside — workers burning your fuel costs more when prices spike |
| FS25_RandomWorldEvents | No conflict |
| All other mods | No known conflicts |

---

## Installation

1. Download the latest release zip
2. Drop into `Documents\My Games\FarmingSimulator2025\mods\`
3. Enable in the mod selection screen
4. Start a career save — fuel costs are active from first fill

---

## Console Commands

| Command | Description |
|---------|-------------|
| `FuelCostsInfo` | Show current price, status, and shock state |
| `FuelCostsSetPrice <value>` | Override base fuel price |
| `FuelCostsDebug` | Toggle debug logging |

---

## Settings

All settings are accessible in-game. In multiplayer, settings are server-authoritative — only admins can change them.

| Setting | Default | Description |
|---------|---------|-------------|
| Enable Fuel Costs | ON | Master toggle |
| Base Fuel Price | $1.20/L | Starting price |
| Difficulty | Realistic | Price multiplier |
| Price Volatility | Medium | Daily swing range |
| Seasonal Effects | ON | Autumn/winter premium |
| Market Shocks | ON | Random price spikes/dips |
| Show Notifications | ON | Fill cost popup |
| Show HUD | ON | Price display overlay |

---

## Development Status

This mod is **actively in development**. The architecture is scaffolded and the price engine is implemented. The fuel fill hook and FS25 finance API calls are pending API verification against the FS25 LUADOC. Expect rapid iteration.

**Next milestone:** Working fuel deduction on refuel with live HUD display.

---

## Contributing

Issues and PRs welcome. If you find a bug or want to suggest a feature, open an issue. Check `CLAUDE.md` before writing any FS25 API calls.

---

*By TisonK*
