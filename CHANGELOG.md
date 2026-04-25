# Changelog

All notable changes to ElvUI_mhTags will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project uses simple integer versions: 1, 2, 3, and so on.

---

## [10] - April 25, 2026

### Breaking Changes

- **WoW 12.0.5+ Only** - This addon now exclusively supports WoW 12.0.5 (Midnight) and later
  - Pre-12.0.5 clients are no longer supported
  - Removed all backwards compatibility fallback code
  - ElvUI 15.0+ is now required

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

- **Configurable Secret Value Fallback** - `MHCT.SECRET_VALUE_FALLBACK_TEXT` constant for customizing display when values are secret

- **Enhanced Slash Commands**:
  - `/mhtags` - Shows memory usage (default)
  - `/mhtags debug` - Shows version info and WoW 12.0.5 target notes
  - `/mhtags help` - Shows available commands

### Changed

- **Updated for WoW 12.0.5 (Midnight)** - Interface version bumped to 120005

- **Major Code Refactoring** - Simplified architecture for WoW 12.0+ only:
  - Uses WoW 12.0 APIs directly: `UnitHealthPercent()`, `UnitHealthMissing()`, `UnitPowerPercent()`
  - Uses `issecretvalue()` directly in tag functions for secret value detection
  - Uses `CurveConstants.ScaleTo100` to get 0-100 range percentages directly from APIs
  - Uses `AbbreviateNumbers()` / `AbbreviateLargeNumbers()` for formatting (accepts secret values)
  - Removed backwards compatibility code (version detection, API wrappers, fallbacks)

- **Modernized TOC metadata**:
  - Added `## Category: Unit Frames` for addon list categorization (WoW 11.1.0+)
  - Added `## Group: ElvUI` for addon grouping in list
  - Added `## X-Curse-Project-ID: 949599`
  - Added `## X-License: GPL-3.0`
  - Added `## X-Localizations: enUS`
  - Added `## X-Flavor: Retail`
  - Updated `## X-Min-ElvUI` to 15.0
  - Updated `## X-WoW-Version` to 12.0.5

- **Release Documentation Updated**:
  - Reworked the README for CurseForge readiness, complete tag coverage, Midnight API limitations, and the existing manual GitHub release flow

- **Status Tags Fixed**:
  - Restored AFK, DND, Ghost, and Offline handling for status tags
  - Replaced slash-command `:trim()` usage with WoW's `strtrim()` helper

- **Argument Handling Hardened**:
  - Clamped health and power decimal tag arguments to the supported `0-3` range
  - Routed health percent tags through the shared `MHCT.GetHealthPercent()` helper for consistent secret-value handling
  - Localized `UnitPowerType`, `pairs`, and `pcall` usage in hot paths

- **Health Tags Updated for Secret Values** - Non-colored tags properly handle secrets:
  - `[mh-health-current]` - Shows formatted HP or fallback text
  - `[mh-health-current-absorb]` - Shows absorb + formatted HP
  - `[mh-health-percent]` - Shows percent or fallback for secrets
  - `[mh-health-current-percent]` - Shows current | percent
  - `[mh-health-percent-current]` - Shows percent | current
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
- **Healer Drinking Tag** - Removed `[mh-healer-drinking]` tag and all related code

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

#### Performance Optimizations in v10.0

- Pre-cached icon strings avoid `format()` in hot path
- Pre-built classification text tables (created once at load)
- Removed unused API localizations
- Icon cache fast-path for default size (O(1) lookup)
- Shared format patterns across all tag files

### Compatibility

- **WoW**: Retail 12.0.0+ (Midnight) only - uses `UnitHealthPercent()`, `UnitPowerPercent()`, `issecretvalue()`
- **ElvUI**: 15.0+ required - uses modern tag registration API

### Note

- **Changelog History**: All changelog entries prior to WoW 12.0 (Midnight) have been removed. This changelog now starts with v10.0, which marks the transition to WoW 12.0+ and ElvUI 15.0+ support.

