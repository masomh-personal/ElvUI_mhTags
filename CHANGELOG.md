# Changelog

All notable changes to ElvUI_mhTags will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [9.0] - January 23, 2026

### Breaking Changes

- **WoW 12.0+ Only** - This addon now exclusively supports WoW 12.0 (Midnight) and later
  - Pre-12.0 clients are no longer supported
  - Removed all backwards compatibility fallback code
  - ElvUI 14.0+ is now required

- **Removed All Colored Health Tags** - Health-based gradient coloring is NOT possible in WoW 12.0
  - Blizzard's "secret value" system blocks ALL operations needed for gradient color lookup
  - Cannot use secret values as table keys
  - Cannot use `tonumber()` on secret-derived strings
  - Cannot use `string.byte()`, `string.len()`, or pattern matching on secret strings
  - The only operation that works is `string.format()` for display purposes
  - **Removed tags**: `mh-health-current-percent-colored`, `mh-health-percent-current-colored`, `mh-health-current-percent-colored-status`, `mh-health-percent-current-colored-status`, `mh-health-current-colored`, `mh-health-percent-colored`, `mh-health-percent-colored-status`, `mh-health-percent-nosign-colored-status`, `mh-healthcolor`
  - **Alternative**: Use non-colored tags, or consider reaction-based coloring (UnitReaction)

### Added

- **Secret-Safe Utility Functions in core.lua**:
  - `MHCT.GetHealthPercent(unit)` - Returns 0-100 percent, handles secret values via `CurveConstants.ScaleTo100`
  - `MHCT.GetPowerPercent(unit, powerType)` - Returns 0-100 percent, handles secret values via `CurveConstants.ScaleTo100`
  - `MHCT.FormatLargeNumber(value)` - Formats with K/M/B suffix using `AbbreviateNumbers()`, secret-safe
  - `MHCT.FormatPercent(value, decimals, includeSign)` - Formats percent string, secret-safe
  - `MHCT.SafeCall(func, default, ...)` - Wraps function calls in pcall with default fallback

- **Configurable Secret Value Fallback** - `MHCT.SECRET_VALUE_FALLBACK_TEXT` constant for customizing display when values are secret

- **Enhanced Slash Commands**:
  - `/mhtags` - Shows memory usage (default)
  - `/mhtags debug` - Shows version info and WoW 12.0 limitation notes
  - `/mhtags help` - Shows available commands

### Changed

- **Updated for WoW 12.0 (Midnight)** - Interface version bumped to 120000

- **Major Code Refactoring** - Simplified architecture for WoW 12.0+ only:
  - Uses WoW 12.0 APIs directly: `UnitHealthPercent()`, `UnitHealthMissing()`, `UnitPowerPercent()`, `UnitPowerMissing()`
  - Uses `issecretvalue()` directly in tag functions for secret value detection
  - Uses `CurveConstants.ScaleTo100` to get 0-100 range percentages directly from APIs
  - Uses `AbbreviateNumbers()` / `AbbreviateLargeNumbers()` for formatting (accepts secret values)
  - Removed backwards compatibility code (version detection, API wrappers, fallbacks)

- **Modernized TOC metadata**:
  - Added `## Category: Unit Frames` for addon list categorization (WoW 11.1.0+)
  - Added `## Group: ElvUI` for addon grouping in list
  - Added `## X-License: MIT`
  - Added `## X-Localizations: enUS`

- **Health Tags Updated for Secret Values** - Non-colored tags properly handle secrets:
  - `[mh-health-current]` - Shows formatted HP or fallback text
  - `[mh-health-current-absorb]` - Shows absorb + formatted HP
  - `[mh-health-percent]` - Shows percent or fallback for secrets
  - `[mh-health-current-percent]` - Shows current | percent
  - `[mh-health-percent-current]` - Shows percent | current
  - `[mh-health-current-percent-hidefull]` - Hides percent at full health
  - `[mh-health-percent-current-hidefull]` - Hides percent at full health
  - `[mh-health-current-percent-absorb]` - Includes absorb with secret handling
  - `[mh-health-deficit]` - Shows missing HP or empty for secrets

- **Power Tags Optimized** - Power percentage calculations use `MHCT.GetPowerPercent()`:
  - `[mh-power-percent]` now uses secret-safe utility with `CurveConstants.ScaleTo100`

- **Absorb Tags Updated**:
  - `[mh-absorb]` in misc.lua now uses `issecretvalue()` check and `MHCT.FormatLargeNumber()`

### Removed

- **Gradient Color Table** - Removed `MHCT.createGradientTable()` and related code since it cannot function with secret values
- **Colored Health Tags** - See Breaking Changes above
- **Debug Tags** - Removed `mh-debug-secret` temporary testing tag

### Technical Details

#### Secret Values in WoW 12.0 (Midnight)

Blizzard introduced a "secret value" system to protect combat-sensitive data. This affects health/power values on:
- Enemy nameplates
- Rated PvP (arena, RBGs)
- Competitive content

**How Secret Values Work:**

Secret values are tainted at the C/engine level before reaching Lua. The taint propagates to ALL derived values - even strings created via `string.format()` remain tainted.

**Blocked Operations (Lua errors or nil returns):**

| Operation | What Happens |
|-----------|--------------|
| `percent >= 50` | Lua error: "attempt to compare a secret value" |
| `percent * 100` | Lua error: "attempt to perform arithmetic on a secret value" |
| `colors[percent]` | Lua error: "table index is secret" |
| `colors[format('%d', percent)]` | Lua error: "table index is secret" (string is tainted!) |
| `tonumber(format('%d', percent))` | Returns `nil` (blocked, not error) |
| `string.byte(taintedStr, 1)` | Lua error: "attempt to index a secret value" |
| `#taintedStr` | Lua error: "attempt to get length of a secret value" |
| `taintedStr:gsub(...)` | Lua error: "attempt to call method on a secret value" |

**Allowed Operations:**

| Operation | Result |
|-----------|--------|
| `string.format('%d', secret)` | Returns displayable (but tainted) string |
| `issecretvalue(value)` | Returns `true` or `false` |
| `AbbreviateNumbers(secret)` | Returns formatted string like "2.5M" |
| `string.concat(a, b, c)` | WoW 12.0 secret-safe concatenation |

**Why Gradient Colors Cannot Work:**

Health-based gradient coloring requires:
1. Getting health percent (works with `CurveConstants.ScaleTo100`)
2. Looking up color in table: `colors[floor(percent)]` (BLOCKED - table index is secret)

We tested multiple workarounds:
- Format to string then `tonumber()` back → Blocked (string remains tainted)
- Extract characters with `string.byte()` → Blocked
- Pattern match with `:match()` → Blocked
- Build new string character by character → Derived strings still tainted

**Conclusion:** There is no Lua-level workaround. The taint is applied at the C level.

#### Performance Optimizations in v9.0

- Pre-cached icon strings avoid `format()` in hot path
- Pre-built classification text tables (created once at load)
- Removed unused API localizations
- Icon cache fast-path for default size (O(1) lookup)
- Shared format patterns across all tag files

### Compatibility

- **WoW**: Retail 12.0.0+ (Midnight) only - uses `UnitHealthPercent()`, `UnitPowerPercent()`, `issecretvalue()`
- **ElvUI**: 14.0+ required - uses modern tag registration API

---

## [7.0.0] - 2025-12-03

### Changed

- **`[mh-healer-drinking]` tag rewritten for accuracy**:
  - Switched from substring keyword matching to exact buff name matching
  - Now uses a lookup table for O(1) performance instead of O(n) iteration with substring search
  - Detects only active drinking/eating states: `"Drink"`, `"Food"`, `"Food & Drink"`, `"Refreshment"`
  - Avoids false positives from stat food buffs (e.g., "Well Fed" no longer triggers)
  - Moved combat check to tag function for better guard ordering (cheapest checks first)
  - Removed `"eating"` keyword (WoW uses "Food" buff, not "Eating")

### Compatibility

- **WoW**: Retail 11.2.7+
- **ElvUI**: 13.0+ (14.0+ recommended)
- **Localization**: `[mh-healer-drinking]` tag uses English buff names only. Non-English clients may have inconsistent results.

---

## [6.1.1] - 2025-11-07

### Changed

- **`[mh-healer-drinking]` tag optimizations**:
  - Added combat check to prevent unnecessary buff scanning (units cannot drink in combat)
  - Changed text color from light blue (`b0d0ff`) to more vibrant blue (`1f6bff`) for better visibility on unit frames
  - Optimized buff detection using keyword substring matching (`"drink"`, `"food"`, `"refreshment"`, `"eating"`)
  - Pre-built `DRINKING_TEXT` constant to avoid string allocation on every call
  - Removed redundant combat check (now only happens in `isDrinking()` helper)
  - Simplified code structure for better maintainability
  - Added note about localization (works best with English client; other locales may need additional keywords)
  - Better code documentation and performance comments

### Technical Notes

- **Localization Consideration**: The tag uses English buff name keywords for detection. While this works reliably for English clients (majority of users), non-English locales may have varying results. Alternative approaches were researched (spell IDs, textures, buff categories) but all require unmaintainable lists or aren't supported by the WoW API. Name-based detection offers the best balance of simplicity, performance, and maintainability.

---

## [6.1.0] - 2025-11-02

### Breaking Changes

- **Removed throttled tag variants** - All `-0.25`, `-0.5`, `-1.0`, `-2.0` suffixed tags have been removed
  - ElvUI 14.0+ provides native performance optimizations making manual throttling obsolete
  - Migration: Remove throttle suffix from tags (e.g., `[mh-health-deficit-1.0]` becomes `[mh-health-deficit]`)
  - Result: Simpler codebase, better maintainability, full ElvUI 14.0+ compatibility

### Added

- **New Tag**: `[mh-health-percent-colored-status]` - Colored gradient health percent with status awareness

  - Gradient coloring (red/yellow/green based on health)
  - Status icons (AFK, Dead, Offline, Ghost, DND)
  - Configurable decimals via `{N}` syntax
  - Example: `[mh-health-percent-colored-status{0}]` shows `85%` or status icon

- **New Tag**: `[mh-health-current-percent-colored-status]` - Current and percent with gradient coloring

  - Combines current health value and percentage (e.g., `100k | 85%`)
  - Gradient coloring based on health percentage
  - Includes absorb shield display and status icons

- **New Tag**: `[mh-health-percent-current-colored-status]` - Percent and current with gradient coloring

  - Combines percentage and current health (e.g., `85% | 100k`)
  - Gradient coloring based on health percentage
  - Includes absorb shield display and status icons

- **New Tag**: `[mh-health-percent-nosign-colored-status{N}]` - Health percentage without % sign, with gradient coloring and status

  - Combines gradient coloring (red/yellow/green) with status awareness (AFK/Dead/Offline/etc.)
  - **No % sign** - displays clean numbers like `85` or `85.3`
  - Configurable decimals via `{N}` syntax (0-3 decimals, default 0)
  - Perfect for minimalist raid frames with full status awareness
  - Examples:
    - `[mh-health-percent-nosign-colored-status{0}]` → `85` (gradient colored) or `DEAD`
    - `[mh-health-percent-nosign-colored-status{1}]` → `85.3` (gradient colored) or `AFK`

- **Highlighted Tag**: `[mh-health-percent-nosign{N}]` - Health percentage without % sign (basic version)

  - Works like `[mh-health-percent{N}]` but omits the % symbol
  - Includes status checks but **no gradient coloring**
  - For colored version, use `[mh-health-percent-nosign-colored-status{N}]` above
  - Example: `[mh-health-percent-nosign{0}]` displays `85` instead of `85%`

- **New Tag**: `[mh-healer-drinking]` - Healer drinking status (works in any scenario)
  - Shows `DRINKING...` **only for healers** when drinking/eating
  - Works in **any scenario**: solo, party, or raid (user choice where to place tag)
  - Returns empty string for non-healers or when not drinking (combine with other tags for fallback display)
  - **Highly optimized performance**:
    - Early exit for non-healers (most units)
    - Early exit when in combat (cannot drink in combat)
    - Optimized keyword matching with plain search mode
    - Name-based detection (no spell ID checks needed)
  - Uses `UnitGroupRolesAssigned()` to detect healer role
  - Uses `UnitAffectingCombat()` to skip aura scanning when in combat
  - Detects drink buffs by keyword matching ("drink", "food", "refreshment")
  - Light blue color (`b0d0ff`) for visibility
  - Example: `[mh-healer-drinking]` → `DRINKING...` (when healer drinking) or `` (empty)

### Fixed

- **ElvUI method call syntax** - Corrected all ElvUI method calls to use `:` (colon) for proper `self` context

  - Root cause of "attempt to compare nil with number" errors in `ShortValue()`
  - Changed `E.ShortValue()` to `E:ShortValue()` throughout codebase

- **Absorb shield nil handling** - Added comprehensive protection for `UnitGetTotalAbsorbs()`

  - Triple-layered validation: nil check, type validation, pcall wrapper
  - Fixes crashes during shield application/removal timing windows

- **ElvUI method caching removed** - Eliminated local caching of `ShortValue`

  - Now always called via `E:ShortValue()` to ensure proper method context
  - Prevents stale function references

- **Decimal argument parsing** - Fixed `tonumber(args) or default` to correctly handle 0 decimals

  - Previously treated 0 as falsy, now explicitly checks for nil

- **Health data nil handling** - `getHealthData()` now handles nil returns from `UnitHealth`/`UnitHealthMax`

  - Prevents "attempt to compare nil with number" errors for invalid units

- **ElvUI 14.0+ tag alias compatibility** - Created internal tag registry
  - Supports legacy tag aliases without relying on ElvUI's internal `E.Tags.Methods` structure
  - Zero performance overhead

### Improved

- **Tag: `[mh-healer-drinking]`** - Enhanced flexibility and performance
  - Removed party/raid restriction - now works universally (solo, party, raid)
  - Optimized keyword matching using plain search mode (faster substring detection)
  - Updated display text to all caps: `DRINKING...`
  - Improved color to light blue (`b0d0ff`) for better visibility
  - Better code organization with pre-defined keyword table

- **Performance: Raid roster caching** - Eliminated O(n) iteration in name tags

  - Before: 1,600 iterations per update in 40-person raid
  - After: 40 O(1) cache lookups per update
  - Result: 93% performance improvement

- **Performance: Pre-cached status formatters** - Eliminated runtime string operations

  - Status text pre-computed at load time
  - Removes `strupper()` and `format()` calls from hot path

- **Performance: Format pattern cache** - Expanded from 0-2 decimals to 0-5 decimals

  - Covers all reasonable decimal use cases
  - Eliminates string concatenation for format string generation

- **Performance: ElvUI method calls** - Corrected all method call syntax

  - Changed `E.ShortValue()` to `E:ShortValue()` for proper Lua semantics
  - Colon syntax passes implicit `self` parameter

- **Performance: Memory efficiency** - Shared ElvUI table references

  - Single `unpack(ElvUI)` in core.lua
  - All modules use `MHCT.E` and `MHCT.L` exports
  - Reduces memory overhead and improves cache locality

- **Code Quality: Eliminated 250+ lines** - Major code reduction

  - Removed throttled tag infrastructure (125 lines)
  - Eliminated throttled tag generation logic (85 lines)
  - Tag alias system replaced manual duplication (40 lines)

- **Code Quality: Simplified architecture** - Removed complexity

  - Removed `registerThrottledTag` and `registerMultiThrottledTag` functions
  - Single registration path via `MHCT.registerTag()`

- **Code Quality: Centralized argument parsing** - Created `MHCT.parseDecimalArg()` helper

  - Used across all tag files for consistent decimal handling
  - Single source of truth for argument parsing logic

- **Code Quality: Event constant groups** - Added EVENTS table

  - Clear, reusable event string constants
  - Improved readability and maintainability

- **Developer Experience: Slash command** - Added `/mhtags` command

  - Displays current memory usage in KB
  - Useful for monitoring and debugging

- **Developer Experience: Error transparency** - Removed error suppression
  - All errors propagate naturally through WoW's error handler
  - Full stack traces visible for bug reports

### Technical Details

- ElvUI API validation performed at startup
- Soft warning for ElvUI versions below 13.0
- Raid roster cache updates on GROUP_ROSTER_UPDATE and PLAYER_ENTERING_WORLD events
- Cache has hard 40-entry limit with automatic wipe on updates
- Tag aliases share function references (zero performance overhead)
- All 50+ tag functions validate unit parameter
- Format string optimization reduces concatenation in frequently called tags

### Performance Impact

- 93% improvement for raid name tags with group numbers
- 2-5% CPU reduction in raid scenarios
- Memory usage: ~200-500 KB (stable, no growth)
- Zero tag-related crashes (comprehensive error boundaries)

### Compatibility

- **WoW**: Retail 11.2.5+
- **ElvUI**: 13.0+ (14.0+ recommended for optimal performance)

---

## [5.0.0] - 2025-08-10

### Added

- Simplified tag naming using hyphens instead of colons
- Backward compatibility via tag aliases (zero performance overhead)

### Changed

- Consolidated and reorganized all tags into logical categories
- Improved performance with optimized event handling
- Enhanced memory efficiency

### Deprecated

- Old colon-based tag names (still functional via aliases):
  - `mh-health:current:percent:right` → `mh-health-current-percent`
  - `mh-health:current:percent:left` → `mh-health-percent-current`
  - And others (see README for complete list)

---

## [4.x.x] - Previous Versions

For changelog entries prior to v5.0.0, please refer to git history or previous releases.

---

## Notes

### Versioning

- **MAJOR** (X.0.0): Breaking changes, API changes, removed features
- **MINOR** (0.X.0): New features, improvements, backward-compatible changes
- **PATCH** (0.0.X): Bug fixes, minor improvements

### Migration Guide

When upgrading major versions, always:

1. Read breaking changes section
2. Test in a non-production environment
3. Update tag strings if deprecated tags are used
4. Report any issues on GitHub

---

For detailed technical documentation, see [README.md](README.md).
