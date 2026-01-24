# ElvUI_mhTags

[![Version](https://img.shields.io/badge/Version-9.0-brightgreen)](https://github.com/masomh-personal/ElvUI_mhTags)
[![ElvUI](https://img.shields.io/badge/Requires-ElvUI-blue)](https://www.tukui.org/download.php?ui=elvui)
[![WoW](https://img.shields.io/badge/WoW-12.0.0+-orange)](https://worldofwarcraft.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

**39 custom tags for ElvUI unit frames.** Lightweight, performant, and flexible.

## Installation

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin) or [GitHub](https://github.com/masomh-personal/ElvUI_mhTags/releases)
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/`
3. `/reload` in-game

## Getting Started

**Open ElvUI** → `/ec` → Any unit frame → **Custom Texts** → Browse **mhTags** categories

### Popular Tags

| Tag                                     | Example        | Use For                       |
| --------------------------------------- | -------------- | ----------------------------- |
| `[mh-health-current-percent]`           | `100k \| 85%`  | Standard health display       |
| `[mh-health-percent-colored-status{0}]` | `85%` / `DEAD` | Color-coded with status       |
| `[mh-health-deficit]`                   | `-15k`         | Missing health (healer focus) |
| `[mh-dynamic:name:caps{20}]`            | `PLAYERNAME`   | Uppercase name, max 20 chars  |
| `[mh-classification:icon]`              | 🛡️             | Elite/Rare/Boss icon          |
| `[mh-status]`                           | `AFK` + icon   | Status indicator              |

## All Tags

### Health (21 tags)

| Tag                                            | Output                 | Notes                  |
| ---------------------------------------------- | ---------------------- | ---------------------- |
| `[mh-health-current]`                          | `100k`                 | Current HP             |
| `[mh-health-current-absorb]`                   | `(25k) 100k`           | With absorb shield     |
| `[mh-health-percent{N}]`                       | `85.2%`                | `{N}` = decimal places |
| `[mh-health-percent-nosign{N}]`                | `85.2`                 | No % sign              |
| `[mh-health-percent-nosign-colored-status{N}]` | `85.2`                 | Gradient + status      |
| `[mh-health-current-percent]`                  | `100k \| 85%`          | Combined display       |
| `[mh-health-percent-current]`                  | `85% \| 100k`          | Reversed order         |
| `[mh-health-current-percent-hidefull]`         | `100k \| 85%`          | Hides % at full        |
| `[mh-health-percent-current-hidefull]`         | `85% \| 100k`          | Hides % at full        |
| `[mh-health-current-percent-absorb]`           | `(25k) 100k \| 85%`    | All metrics            |
| `[mh-health-deficit]`                          | `-15k` / `DEAD`        | Missing health         |
| `[mh-health-deficit-nostatus]`                 | `-15k`                 | No status text         |
| `[mh-health-deficit-percent{N}]`               | `-15%`                 | As percentage          |
| `[mh-health-current-percent-colored]`          | `100k \| 85%`          | Gradient colored       |
| `[mh-health-percent-current-colored]`          | `85% \| 100k`          | Gradient colored       |
| `[mh-health-current-percent-colored-status]`   | `100k \| 85%` / `AFK`  | Colored + status       |
| `[mh-health-percent-current-colored-status]`   | `85% \| 100k` / `DEAD` | Colored + status       |
| `[mh-health-current-colored]`                  | `100k`                 | Current only, colored  |
| `[mh-health-percent-colored]`                  | `85%`                  | Percent only, colored  |
| `[mh-health-percent-colored-status{N}]`        | `85%` / `GHOST`        | Colored + status       |
| `[mh-healthcolor]`                             | `\|cffRRGGBB`          | Color code only        |

### Name (7 tags)

| Tag                                          | Output              | Notes                     |
| -------------------------------------------- | ------------------- | ------------------------- |
| `[mh-dynamic:name:caps{N}]`                  | `PLAYERNAME`        | `{N}` = max chars         |
| `[mh-dynamic:name:caps-statusicon{N}]`       | `PLAYERNAME` + icon | With status icon          |
| `[mh-player:frame:name:caps-groupnumber{N}]` | `PLAYERNAME (5)`    | With raid group #         |
| `[mh-name:caps:abbrev]`                      | `C.T. Dummy`        | Abbreviated               |
| `[mh-name:caps:abbrev-reverse]`              | `Cleave T.D.`       | Abbreviated reverse       |
| `[mh-name-caps-abbrev-V2{N}]`                | `C.T. Dummy`        | Smart abbrev if > N chars |
| `[mh-name-caps-abbrev-reverse-V2{N}]`        | `Cleave T.D.`       | Smart abbrev reverse      |

### Classification (5 tags)

| Tag                                | Output    | Notes                 |
| ---------------------------------- | --------- | --------------------- |
| `[mh-classification:icon]`         | Icon      | Elite/Rare/Boss       |
| `[mh-classification:icon-V2]`      | Icon      | Fixed-size variant    |
| `[mh-classification:text]`         | `[Elite]` | Colored with brackets |
| `[mh-classification:text-compact]` | `E`       | Single letter         |
| `[mh-classification:text-full]`    | `Elite`   | Full text             |

### Power (1 tag)

| Tag                     | Output | Notes                |
| ----------------------- | ------ | -------------------- |
| `[mh-power-percent{N}]` | `85.3` | Mana/energy/rage/etc |

### Misc (7 tags)

| Tag                               | Output        | Notes               |
| --------------------------------- | ------------- | ------------------- |
| `[mh-smartlevel]`                 | `80`          | Hides at max level  |
| `[mh-absorb]`                     | `(25k)`       | Absorb shield value |
| `[mh-difficultycolor:level]`      | `85`          | Difficulty colored  |
| `[mh-difficultycolor:level-hide]` | `85`          | Hides when both max |
| `[mh-status]`                     | `AFK` + icon  | Status with icon    |
| `[mh-status-noicon]`              | `AFK`         | Text only           |
| `[mh-healer-drinking]`            | `DRINKING...` | Healers only        |

## Syntax Guide

### Decimal Places `{N}`

```
[mh-health-percent{0}]     → 85%
[mh-health-percent{1}]     → 85.3%
[mh-health-percent{2}]     → 85.34%
```

### Max Characters `{N}`

```
[mh-dynamic:name:caps{15}]  → Max 15 characters
[mh-dynamic:name:caps{25}]  → Max 25 characters
```

## Performance

- **300-500 KB** memory in 40-person raids
- Pre-computed color gradients and format strings
- O(1) raid roster lookups
- Zero memory leaks
- **WoW 12.0+**: Uses native `UnitHealthPercent()` and `UnitPowerPercent()` APIs for optimal performance

**Utility commands:**

| Command          | Description                              |
| ---------------- | ---------------------------------------- |
| `/mhtags`        | Display addon memory usage               |
| `/mhtags debug`  | Show version info and API availability   |
| `/mhtags help`   | List available commands                  |

## Compatibility

|           | Version                                     |
| --------- | ------------------------------------------- |
| **WoW**   | Retail 12.0.0+ (Midnight), also works on 11.x |
| **ElvUI** | 13.0+ required, 14.0+ recommended for 12.0  |

### WoW 12.0 (Midnight) Notes

This addon is fully compatible with WoW 12.0's new addon security system:

- **New APIs**: Automatically uses `UnitHealthPercent()`, `UnitHealthMissing()`, `UnitPowerPercent()`, and `UnitPowerMissing()` when available
- **Fallback**: Gracefully falls back to manual calculation on pre-12.0 clients
- **Secret Values**: Tags handle WoW 12.0's "secret value" system correctly through ElvUI's display layer
- **Version Check**: Warns at startup if ElvUI version is incompatible with WoW 12.0

## v4.x Migration

Old tags work via aliases (zero overhead):

| v4.x                                | v5.0+                         |
| ----------------------------------- | ----------------------------- |
| `[mh-health:current:percent:right]` | `[mh-health-current-percent]` |
| `[mh-health:current:percent:left]`  | `[mh-health-percent-current]` |

## Support

- [GitHub Issues](https://github.com/masomh-personal/ElvUI_mhTags/issues)
- [CurseForge](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin)

**Bug reports:** Include WoW version, ElvUI version, error message, and steps to reproduce.

**Created by mhDesigns** for the World of Warcraft community
