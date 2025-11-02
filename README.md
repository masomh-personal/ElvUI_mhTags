# ElvUI_mhTags - High-Performance Custom Tags for ElvUI

[![Version](https://img.shields.io/badge/Version-6.1.0-brightgreen)](https://github.com/masomh-personal/ElvUI_mhTags)
[![ElvUI](https://img.shields.io/badge/Requires-ElvUI-blue)](https://www.tukui.org/download.php?ui=elvui)
[![WoW](https://img.shields.io/badge/WoW-11.2.5-orange)](https://worldofwarcraft.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

A lightweight, performance-optimized ElvUI plugin providing an extensive collection of custom tags for unit frames, nameplates, and other UI elements.

## Quick Start

### Installation

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin) or [GitHub Releases](https://github.com/masomh-personal/ElvUI_mhTags/releases)
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or type `/reload`

### Using Tags

1. Open ElvUI configuration: `/ec`
2. Navigate to any unit frame (Player, Target, Raid, etc.)
3. Find the "Custom Texts" section
4. Browse tags under "mhTags" categories or use examples below

### Popular Tag Examples

#### Health Display

```
[mh-health-current-percent]              Shows: 100k | 85%
[mh-health-percent-colored-status{0}]    Shows: 85% (colored, with status icons)
[mh-health-deficit]                      Shows: -15k (missing health)
```

#### Name Display

```
[mh-dynamic:name:caps{20}]               Shows: PLAYERNAME (max 20 characters)
[mh-dynamic:name:caps-statusicon{20}]    Shows: PLAYERNAME + status icon
[mh-player:frame:name:caps-groupnumber{15}]  Shows: PLAYERNAME (5) in raids
```

#### Classification & Level

```
[mh-classification:icon]                 Shows: Elite/Rare/Boss icon
[mh-smartlevel]                          Shows: Level (hides max level at cap)
[mh-difficultycolor:level]               Shows: Colored level by difficulty
```

#### Power Display

```
[mh-power-percent]                       Shows: 85 (mana/energy percent)
[mh-power-percent{1}]                    Shows: 85.3 (with 1 decimal)
```

### Slash Commands

```
/mhtags debug    Toggle debug mode (shows tag errors in chat)
/mhtags memory   Display current memory usage
/mhtags help     Show available commands
```

## Features

### Performance-First Design

- **Memory efficient**: Stable usage under 500 KB in 40-person raids
- **CPU optimized**: Streamlined algorithms with minimal overhead
- **No memory leaks**: Bounded caches, automatic cleanup
- **Raid-optimized**: 93% performance improvement for name tags with group numbers
- **ElvUI-native**: Leverages ElvUI 14.0+ performance enhancements

### Comprehensive Tag Library

#### Health Tags (30+ variants)

- Basic display: Current health with smart formatting
- Percentages: Configurable decimals (0-5 places), with or without % sign
- Combined views: Current + percentage in various orders
- Deficit tracking: Missing health as numeric or percentage values
- Gradient coloring: Red-yellow-green spectrum based on health percentage
- Smart features: Hide-at-full options, absorb shields, status indicators

#### Name Tags

- Dynamic character limits with truncation
- Smart abbreviation (e.g., "Cleave Training Dummy" → "C.T. Dummy")
- ALL CAPS formatting
- Raid group number integration
- Status icon integration

#### Classification Tags

- Custom icons for elite, rare, boss units
- Colored text indicators
- Difficulty-based coloring
- Smart level display (hides at max level)

#### Power Tags

- Percentage displays with configurable decimals
- Smart zero-power handling

#### Status & Miscellaneous Tags

- AFK, DND, Dead, Ghost, Offline indicators with custom icons
- Absorb shield displays
- Smart level tags
- Difficulty-colored levels

## Performance Guidelines

### Raid Frames (25-40 units)

All tags are optimized for raid performance with ElvUI 14.0+ native update system:

```
[mh-health-current-percent-hidefull]        Clean health + percent display
[mh-health-deficit]                         Shows missing health
[mh-power-percent]                          Shows power percentage
```

### Party/Arena (5-10 units)

Same tags work efficiently for smaller groups:

```
[mh-health-current-percent]                 Full-time health tracking
[mh-health-deficit]                         Missing health display
```

### Player/Target (1-3 units)

Use real-time updates for immediate feedback:

```
[mh-health-current-percent-colored]         Real-time with gradient coloring
[mh-health-current-absorb]                  Real-time with absorb shields
```

## Tag Name Changes (v5.0.0+)

Version 5.0.0 introduced simplified naming using hyphens instead of colons. Old tag names still work but are deprecated.

### Common Migrations

| Old Tag Name (v4.x)                          | New Tag Name (v5.0+)                   |
| -------------------------------------------- | -------------------------------------- |
| `[mh-health:current:percent:right]`          | `[mh-health-current-percent]`          |
| `[mh-health:current:percent:left]`           | `[mh-health-percent-current]`          |
| `[mh-health:current:percent:right-hidefull]` | `[mh-health-current-percent-hidefull]` |
| `[mh-deficit:num-status]`                    | `[mh-health-deficit]`                  |
| `[mh-deficit:percent-status]`                | `[mh-health-deficit-percent]`          |
| `[mh-health:simple:percent]`                 | `[mh-health-percent]`                  |

Backward compatibility is maintained via tag aliases (zero performance overhead).

## Technical Details

### Recent Improvements (v6.1.0)

#### Stability Enhancements

- Fixed decimal argument parsing (correctly handles 0 decimals)
- Added nil checks to all 50+ tag functions
- Implemented error boundaries (pcall) on all tags
- Added ElvUI API validation at startup
- ElvUI version compatibility check

#### Performance Optimizations

- Raid roster caching: 93% improvement for name tags in 40-person raids
- Pre-cached status formatters (eliminated string operations in hot path)
- Expanded format pattern cache (0-5 decimals)
- Optimized string concatenation
- Memory bounded with hard limits

#### Code Quality

- Eliminated 172+ lines of code duplication
- Centralized argument parsing
- Event constant groups for maintainability
- Tag alias system for legacy compatibility
- Simplified architecture leveraging ElvUI 14.0+ performance

### Monitoring Performance

#### Check Memory Usage

```lua
/run UpdateAddOnMemoryUsage(); print(GetAddOnMemoryUsage("ElvUI_mhTags").." KB")
```

Or use the built-in command:

```
/mhtags memory
```

#### Expected Values

- Initial load: 150-200 KB
- Stable state: 300-500 KB
- No growth over extended sessions

#### Performance Benchmarks

- 40-person raid: ~400 KB memory, < 1ms CPU per update cycle
- Name tags with group numbers: 93% faster than v6.0.1
- Status checks: Optimized hot path with pre-cached formatters

## Tag Categories

### Health (health)

Complete health tag system with 8 organized sections:

- Basic health values (current, formatted)
- Percentage displays (configurable decimals)
- Combined current + percentage views
- Deficit tracking (numeric and percentage)
- Gradient colored displays
- Health color codes for custom styling
- Legacy compatibility tags

### Name (name)

Advanced name formatting:

- Dynamic length truncation
- Smart abbreviation algorithms
- ALL CAPS formatting
- Raid group number integration
- Status icon combinations

### Classification (classification)

Unit classification indicators:

- Custom BLP icons (elite, rare, boss)
- Colored text indicators
- Compact symbols (B, E, R, R+, E+)
- Full descriptive text

### Power (power)

Resource display:

- Percentage with configurable decimals
- Smart handling of zero power

### Miscellaneous (misc)

Utility tags:

- Smart level display
- Difficulty-colored levels
- Absorb shield indicators
- Status indicators (AFK, Dead, Offline, Ghost, DND)

## Requirements

- **ElvUI**: Version 13.0 or higher - [Download from TukUI](https://www.tukui.org/download.php?ui=elvui)
- **World of Warcraft**: Retail (11.2.5+)

## Support & Contributing

### Bug Reports & Feature Requests

- [GitHub Issues](https://github.com/masomh-personal/ElvUI_mhTags/issues)
- [GitHub Discussions](https://github.com/masomh-personal/ElvUI_mhTags/discussions)
- [CurseForge Comments](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin)

### Contributing

Contributions are welcome. Please follow these guidelines:

1. **Performance first**: Every tag must be optimized for raid scenarios
2. **No global pollution**: Use addon namespace exclusively
3. **Memory efficiency**: Avoid unbounded caching
4. **Clear naming**: Tags should be self-descriptive
5. **Documentation**: Update README and CHANGELOG

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **ElvUI Team**: For creating an exceptional UI framework
- **WoW Community**: For feedback and testing
- **Contributors**: For helping improve the addon

---

**Created for the World of Warcraft community by mhDesigns**

For detailed version history and technical changes, see [CHANGELOG.md](CHANGELOG.md)
