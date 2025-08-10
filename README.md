# ElvUI_mhTags - High-Performance Custom Tags for ElvUI

[![Version](https://img.shields.io/badge/Version-5.0.0-brightgreen)](https://github.com/masomh-personal/ElvUI_mhTags)
[![ElvUI](https://img.shields.io/badge/Requires-ElvUI-blue)](https://www.tukui.org/download.php?ui=elvui)
[![WoW](https://img.shields.io/badge/WoW-11.0.2-orange)](https://worldofwarcraft.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

A lightweight, performance-optimized ElvUI plugin that provides an extensive collection of custom tags for unit frames, nameplates, and other UI elements.

## Purpose & Philosophy

As a long-time ElvUI user, I found myself constantly wanting more flexibility and options for displaying unit information. While ElvUI provides a solid foundation, I needed tags that could:

- **Display information exactly how I wanted** - with precise formatting control
- **Perform efficiently in high-stress scenarios** - 40-person raids, large battlegrounds
- **Provide visual clarity** - through color gradients, icons, and smart formatting
- **Adapt to different contexts** - raid frames vs target frames vs nameplates

This addon fills those gaps while maintaining a **zero-tolerance policy on performance degradation**. Every tag is optimized to run efficiently, even when called hundreds of times per second across multiple frames.

## Key Features

### Performance-First Design

- **Memory-efficient**: Stable usage under 1MB even in 40-person raids
- **CPU-optimized**: Streamlined algorithms with minimal overhead
- **Throttle options**: Multiple update frequencies (0.25s, 0.5s, 1.0s, 2.0s) for different use cases
- **No memory leaks**: v5.0+ completely eliminated all caching-related memory issues
- **DRY principles**: v5.1 consolidated all health tags with shared helper functions

### Rich Tag Collection

#### Health Tags (Unified System)

- **Basic Display**: Current health values with smart formatting
- **Percentages**: Configurable decimal places, with or without % sign
- **Combined Views**: Current + percentage in various orders
- **Deficit Tracking**: Missing health as numeric or percentage
- **Gradient Coloring**: Full red-yellow-green spectrum based on health
- **Smart Features**: Hide-at-full options, absorb shields, status indicators
- **Throttled Variants**: Pre-configured update rates for performance

#### Name Tags

- Dynamic character limits
- Smart abbreviation (e.g., "Cleave Training Dummy" becomes "C.T. Dummy")
- ALL CAPS formatting options
- Raid group number integration
- Boss/rare unit special handling

#### Classification Tags

- Custom icons for elite, rare, boss units
- Colored text indicators
- Difficulty-based coloring
- Smart level display

#### Power Tags

- Percentage displays with configurable decimals
- Multiple throttle options for performance
- Smart zero-power handling

## Installation

### Requirements

- **ElvUI** (Required) - [Download from TukUI](https://www.tukui.org/download.php?ui=elvui)
- **World of Warcraft** - Retail (11.0.2+)

### Install Methods

#### CurseForge (Recommended)

Download from: [MH Custom Tags on CurseForge](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin)

#### Manual Installation

1. Download the latest release from [GitHub Releases](https://github.com/masomh-personal/ElvUI_mhTags/releases)
2. Extract to: `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or `/reload`

## Important: Tag Name Changes in v5.1

### Simplified Naming Convention

Version 5.1 introduced a simplified, consistent naming convention for all tags. If you're upgrading from v5.0 or earlier, you'll need to update your tag names:

#### Old Format (v5.0 and earlier)

- Used colons (`:`) as separators
- Inconsistent naming patterns
- Examples: `[mh-health:current:percent:right]`, `[mh-deficit:num-status]`

#### New Format (v5.1+)

- Uses hyphens (`-`) consistently
- Clearer, more intuitive names
- Examples: `[mh-health-current-percent]`, `[mh-health-deficit]`

#### Common Tag Migrations

| Old Tag Name                                   | New Tag Name                           |
| ---------------------------------------------- | -------------------------------------- |
| `[mh-health:current:percent:right]`            | `[mh-health-current-percent]`          |
| `[mh-health:current:percent:left]`             | `[mh-health-percent-current]`          |
| `[mh-health:current:percent:right-hidefull]`   | `[mh-health-current-percent-hidefull]` |
| `[mh-health:current:percent:gradient-colored]` | `[mh-health-current-percent-colored]`  |
| `[mh-deficit:num-status]`                      | `[mh-health-deficit]`                  |
| `[mh-deficit:percent-status]`                  | `[mh-health-deficit-percent]`          |
| `[mh-health:simple:percent]`                   | `[mh-health-percent]`                  |

**Note**: Old tag names still work for backwards compatibility but are marked as deprecated. We recommend updating to the new names.

## Usage Guide

### Basic Usage

1. Open ElvUI config: `/ec`
2. Navigate to any unit frame (Player, Target, Raid, etc.)
3. Find the "Custom Texts" section
4. Create a new text or edit existing
5. Browse available tags under "mhTags" categories

### Performance Guidelines

#### For Raid Frames (25-40 units)

Use throttled variants for better performance:

```lua
[mh-health-current-percent-hidefull-1.0]  -- Updates every 1 second
[mh-health-deficit-2.0]                    -- Updates every 2 seconds
```

#### For Party/Arena (5-10 units)

Can use faster updates:

```lua
[mh-health-current-percent-hidefull-0.5]  -- Updates every 0.5 seconds
[mh-health-deficit-0.5]                    -- Updates every 0.5 seconds
```

#### For Player/Target (1-3 units)

Can use real-time or fast updates:

```lua
[mh-health-current-percent-colored]  -- Real-time updates with gradient
[mh-health-deficit-0.25]             -- Updates every 0.25 seconds
```

### Popular Tag Combinations

#### Minimalist Health Display

```lua
[mh-health-current-percent-hidefull-1.0]
```

Shows "100k | 85%" but only "100k" at full health

#### Raid Frame Deficit Tracker

```lua
[mh-health-deficit-1.0]
```

Shows "-15k" when damaged, or status icons when dead/offline

#### Colored Health with Absorbs

```lua
[mh-health-current-percent-colored]
```

Full gradient coloring with absorb shield display

#### Smart Name Abbreviation

```lua
[mh-name-caps-abbrev-V2{20}]
```

Abbreviates names longer than 20 characters

## Technical Details

### Recent Optimizations

#### Version 5.1.1 - CPU Performance Optimizations

- **Optimized status checks** - Reordered to check most common cases first
- **Fast path gradient colors** - Skip lookups for 100% and 0% health
- **Reduced string operations** - Pre-built format strings in hot paths
- **5-10% CPU reduction** - Measurable improvement in raid scenarios

#### Version 5.1.0 - Health Tag Consolidation

- **Unified health system** - All health tags now in single organized file
- **DRY principles applied** - Shared helper functions eliminate code duplication
- **Simplified naming** - Intuitive tag names (e.g., `mh-health-current-percent`)
- **Smart throttling** - Automated creation of performance variants
- **60% code reduction** - Consolidated from 2 files to 1 with better organization

#### Version 5.0.0 - Memory Optimization

- **Removed all caching mechanisms** - Direct formatting prevents memory accumulation
- **Local variable scoping** - All variables scoped within functions
- **Simplified algorithms** - Gradient calculation reduced from complex interpolation to 3-step
- **Eliminated string concatenation overhead** - Using table.concat where appropriate

### Monitoring Performance

Check memory usage:

```lua
/run print(GetAddOnMemoryUsage("ElvUI_mhTags").." KB")
```

Check CPU usage:

```lua
/run print(GetAddOnCPUUsage("ElvUI_mhTags").." ms")
```

Expected values:

- Initial load: 100-200 KB
- After 1 minute: < 500 KB
- Stable state: < 1 MB

## Tag Categories

The addon organizes tags into logical categories within ElvUI's tag system:

### Health Tags (Unified)

Complete health tag system with 8 organized sections:

- Basic health display values
- Percentage displays with configurable decimals
- Combined current + percentage views
- Deficit tracking for missing health
- Gradient colored displays
- Health color codes for custom styling
- Throttled variants for performance
- Legacy tags for backwards compatibility

### Classification Tags

Tags for displaying unit classification (elite, rare, boss) with custom icons or text.

### Name Tags

Advanced name formatting with abbreviation, capitalization, and group number support.

### Power Tags

Mana/Energy/Rage percentage displays with configurable update rates.

### Miscellaneous Tags

Additional utility tags including absorb shields, status indicators, and smart level display.

## Future Development

### Planned Features

- Additional gradient color schemes
- More abbreviation patterns for names
- Custom icon sets for different UI styles
- Further performance optimizations for massive raid scenarios

### Performance Goals

- Maintain sub-1MB memory usage
- Further optimize for 40+ unit scenarios
- Reduce CPU usage by additional 10-15%

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for:

- Bug reports
- Feature requests
- Performance improvements
- New tag ideas

### Development Guidelines

1. **Performance first** - Every tag must be optimized
2. **No global namespace pollution** - Use addon namespace
3. **Memory efficiency** - Avoid persistent caching
4. **Clear naming** - Tags should be self-descriptive

## Support

- **Bug Reports**: [GitHub Issues](https://github.com/masomh-personal/ElvUI_mhTags/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/masomh-personal/ElvUI_mhTags/discussions)
- **CurseForge Comments**: [Addon Page](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin)

## Screenshots

![Tag Examples](https://github.com/masomh-personal/ElvUI_mhTags/assets/94949987/d5b72d1c-6789-48b4-ae45-798b829c840d)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **ElvUI Team** - For creating an amazing UI framework
- **WoW Community** - For feedback and testing
- **Contributors** - For helping improve the addon

---

**Created for the WoW community by mhDesigns**

_If you find this addon useful, consider leaving a review on CurseForge!_
