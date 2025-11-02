# ElvUI_mhTags

[![Version](https://img.shields.io/badge/Version-6.1.0-brightgreen)](https://github.com/masomh-personal/ElvUI_mhTags)
[![ElvUI](https://img.shields.io/badge/Requires-ElvUI-blue)](https://www.tukui.org/download.php?ui=elvui)
[![WoW](https://img.shields.io/badge/WoW-11.2.5-orange)](https://worldofwarcraft.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

A high-performance ElvUI plugin providing 39 custom tags for unit frames, nameplates, and other UI elements. Designed for minimal memory footprint and maximum flexibility.

## Installation

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin) or [GitHub Releases](https://github.com/masomh-personal/ElvUI_mhTags/releases)
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or type `/reload`

## Quick Start

### Accessing Tags

1. Open ElvUI configuration: `/ec`
2. Navigate to any unit frame (Player, Target, Party, Raid, etc.)
3. Find the "Custom Texts" section
4. Click "Create New Text" or edit existing text
5. Browse available tags under **mhTags** categories

### Common Examples

```
Health Display:
[mh-health-current-percent]                    100k | 85%
[mh-health-percent{1}]                         85.3% (with % sign)
[mh-health-percent-nosign{1}]                  85.3 (without % sign, basic)
[mh-health-percent-nosign-colored-status{1}]   85.3 (without % sign, colored + status)
[mh-health-percent-colored-status{0}]          85% (with % sign, colored + status)
[mh-health-deficit]                            -15k (shows missing health)

Name Display:
[mh-dynamic:name:caps{20}]                      PLAYERNAME
[mh-dynamic:name:caps-statusicon{20}]           PLAYERNAME + status icon
[mh-player:frame:name:caps-groupnumber{15}]     PLAYERNAME (5)

Classification:
[mh-classification:icon]                 Elite/Rare/Boss icon
[mh-difficultycolor:level]               80 (colored by difficulty)

Power:
[mh-power-percent{1}]                    85.3 (mana/energy percent)

Status & Misc:
[mh-status]                              AFK/Dead/Offline with icon
[mh-healer-drinking]                     Drinking... (healers only, 5-man party)
```

### Utility Command

```
/mhtags    Display memory usage
```

---

## Complete Tag Reference

### Health Tags (21)

| Tag                                            | Output Example          | Description                                           |
| ---------------------------------------------- | ----------------------- | ----------------------------------------------------- |
| `[mh-health-current]`                          | `100k`                  | Current health value                                  |
| `[mh-health-current-absorb]`                   | `(25k) 100k`            | Current health with absorb shield                     |
| `[mh-health-percent{N}]`                       | `85.2%` or `DEAD`       | Health percentage with status (configurable decimals) |
| `[mh-health-percent-nosign{N}]`                | `85.2`                  | Health percent without % sign (basic)                 |
| `[mh-health-percent-nosign-colored-status{N}]` | `85.2` or `DEAD`        | Health percent without % sign (gradient + status)     |
| `[mh-health-current-percent]`                  | `100k \| 85%`           | Current and percentage                                |
| `[mh-health-percent-current]`                  | `85% \| 100k`           | Percentage and current                                |
| `[mh-health-current-percent-hidefull]`         | `100k \| 85%`           | Hides percent at full health                          |
| `[mh-health-percent-current-hidefull]`         | `85% \| 100k`           | Hides percent at full health                          |
| `[mh-health-current-percent-absorb]`           | `(25k) 100k \| 85%`     | All metrics combined                                  |
| `[mh-health-deficit]`                          | `-15k` or `DEAD`        | Missing health or status                              |
| `[mh-health-deficit-nostatus]`                 | `-15k`                  | Missing health only                                   |
| `[mh-health-deficit-percent{N}]`               | `-15%` or `AFK`         | Missing health as percentage                          |
| `[mh-health-current-percent-colored]`          | `100k \| 85%`           | Gradient colored (red/yellow/green)                   |
| `[mh-health-percent-current-colored]`          | `85% \| 100k`           | Gradient colored (red/yellow/green)                   |
| `[mh-health-current-percent-colored-status]`   | `100k \| 85%` or `AFK`  | Colored with status check                             |
| `[mh-health-percent-current-colored-status]`   | `85% \| 100k` or `DEAD` | Colored with status check                             |
| `[mh-health-current-colored]`                  | `100k`                  | Current only, gradient colored                        |
| `[mh-health-percent-colored]`                  | `85%`                   | Percent only, gradient colored                        |
| `[mh-health-percent-colored-status{N}]`        | `85%` or `GHOST`        | Colored percent with status                           |
| `[mh-healthcolor]`                             | `\|cffRRGGBB`           | Color code for custom composition                     |

### Name Tags (7)

| Tag                                          | Output Example      | Description                                    |
| -------------------------------------------- | ------------------- | ---------------------------------------------- |
| `[mh-dynamic:name:caps{N}]`                  | `PLAYERNAME`        | Name in ALL CAPS (N = max characters)          |
| `[mh-dynamic:name:caps-statusicon{N}]`       | `PLAYERNAME` + icon | Name with status icon                          |
| `[mh-player:frame:name:caps-groupnumber{N}]` | `PLAYERNAME (5)`    | Name with raid group number                    |
| `[mh-name:caps:abbrev]`                      | `C.T. Dummy`        | Abbreviated name                               |
| `[mh-name:caps:abbrev-reverse]`              | `Cleave T.D.`       | Abbreviated name (reverse)                     |
| `[mh-name-caps-abbrev-V2{N}]`                | `C.T. Dummy`        | Smart abbreviation (if name > N chars)         |
| `[mh-name-caps-abbrev-reverse-V2{N}]`        | `Cleave T.D.`       | Smart abbreviation reverse (if name > N chars) |

### Classification Tags (5)

| Tag                                | Output Example | Description                    |
| ---------------------------------- | -------------- | ------------------------------ |
| `[mh-classification:icon]`         | Icon           | Elite/Rare/Boss custom icon    |
| `[mh-classification:icon-V2]`      | Icon           | Fixed-size classification icon |
| `[mh-classification:text]`         | `[Elite]`      | Colored text with brackets     |
| `[mh-classification:text-compact]` | `E`            | Single letter (E/R/B)          |
| `[mh-classification:text-full]`    | `Elite`        | Full text without brackets     |

### Power Tags (1)

| Tag                     | Output Example | Description                           |
| ----------------------- | -------------- | ------------------------------------- |
| `[mh-power-percent{N}]` | `85` or `85.3` | Power percentage (mana, energy, etc.) |

### Miscellaneous Tags (7)

| Tag                               | Output Example | Description                                    |
| --------------------------------- | -------------- | ---------------------------------------------- |
| `[mh-smartlevel]`                 | `80`           | Smart level (hides at max)                     |
| `[mh-absorb]`                     | `(25k)`        | Absorb shield value                            |
| `[mh-difficultycolor:level]`      | `85`           | Level with difficulty color                    |
| `[mh-difficultycolor:level-hide]` | `85`           | Hides when both at max level                   |
| `[mh-status]`                     | `AFK` + icon   | Status with icon                               |
| `[mh-status-noicon]`              | `AFK`          | Status text only                               |
| `[mh-healer-drinking]`            | `Drinking...`  | Shows only for healers drinking in 5-man party |

---

## Special Syntax

### Configurable Decimals: `{N}`

Use `{N}` to specify decimal places (0-5):

```
With % sign:
[mh-health-percent{0}]            85%
[mh-health-percent{1}]            85.3%
[mh-health-percent{2}]            85.34%

Without % sign (basic):
[mh-health-percent-nosign{0}]     85
[mh-health-percent-nosign{1}]     85.3

Without % sign (colored + status):
[mh-health-percent-nosign-colored-status{0}]     85 (gradient colored)
[mh-health-percent-nosign-colored-status{1}]     85.3 (gradient colored)
```

### Dynamic Length: `{N}`

Specify maximum characters for name tags:

```
[mh-dynamic:name:caps{15}]     Max 15 characters
[mh-dynamic:name:caps{25}]     Max 25 characters
```

---

## Performance

### Benchmarks

- **Memory Usage**: 300-500 KB stable (40-person raid)
- **CPU**: < 1ms per update cycle
- **Raid Performance**: 93% faster name tag lookups vs v6.0.1

### Optimizations

- Pre-computed gradient color tables (101 entries)
- Cached format patterns for decimals (0-5)
- O(1) raid roster lookups (vs O(n) iteration)
- Bounded memory with automatic cleanup
- Zero memory leaks (validated)

### Recommended Usage

**Raid Frames (25-40 units):**

```
[mh-health-current-percent-hidefull]
[mh-health-deficit]
[mh-power-percent]
```

**Party/Arena (5-10 units):**

```
[mh-health-current-percent]
[mh-health-deficit]
```

**Player/Target (1-3 units):**

```
[mh-health-current-percent-colored]
[mh-health-current-absorb]
```

---

## Compatibility

- **WoW**: Retail 11.2.5+
- **ElvUI**: 13.0+ (14.0+ recommended)
- **Performance**: Optimized for ElvUI 14.0+ native update system

---

## Migrating from v4.x

Version 5.0.0+ simplified tag naming. Old tags still work via aliases:

| Old Tag (v4.x)                               | New Tag (v5.0+)                        |
| -------------------------------------------- | -------------------------------------- |
| `[mh-health:current:percent:right]`          | `[mh-health-current-percent]`          |
| `[mh-health:current:percent:left]`           | `[mh-health-percent-current]`          |
| `[mh-health:current:percent:right-hidefull]` | `[mh-health-current-percent-hidefull]` |
| `[mh-health:current:percent:left-hidefull]`  | `[mh-health-percent-current-hidefull]` |

Aliases have zero performance overhead. Migration recommended but not required.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/masomh-personal/ElvUI_mhTags/issues)
- **Discussions**: [GitHub Discussions](https://github.com/masomh-personal/ElvUI_mhTags/discussions)
- **CurseForge**: [Addon Page](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin)

When reporting bugs, please include:

1. WoW and ElvUI versions
2. Full error message with stack trace
3. Steps to reproduce

---

## Contributing

Contributions welcome. Please ensure:

1. Performance-first approach (test in 40-person raids)
2. No global namespace pollution
3. Memory efficiency (no unbounded caching)
4. Clear, self-descriptive naming
5. Update CHANGELOG.md

---

## Technical Details

### Architecture

- **Core**: `core.lua` - Shared utilities, constants, helpers
- **Modules**: 5 tag modules (health, power, name, classification, misc)
- **Registry**: Internal tag registry for ElvUI 14.0+ compatibility
- **Events**: Optimized event handling with grouped constants

### Key Features

- Raid roster caching for O(1) lookups
- Pre-computed gradients and format strings
- Triple-layered error protection (nil checks, type validation, pcall)
- Automatic memory cleanup with bounded caches
- ElvUI 14.0+ native performance integration

For complete technical details, see [CHANGELOG.md](CHANGELOG.md).

---

## License

MIT License - See [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **ElvUI Team** - For the outstanding UI framework
- **WoW Community** - For feedback and testing
- **Contributors** - For improvements and bug reports

---

**Created by mhDesigns for the World of Warcraft community**
