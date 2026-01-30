# ElvUI_mhTags

[![Version](https://img.shields.io/badge/Version-10-brightgreen)](https://github.com/masomh-personal/ElvUI_mhTags)
[![ElvUI](https://img.shields.io/badge/Requires-ElvUI%2014.0+-blue)](https://www.tukui.org/download.php?ui=elvui)
[![WoW](https://img.shields.io/badge/WoW-12.0.0%20Midnight+-orange)](https://worldofwarcraft.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

**29 custom tags for ElvUI unit frames.** Lightweight, performant, and WoW 12.0 (Midnight) optimized.

> **⚠️ Important**: This addon requires **WoW 12.0+ (Midnight)** and **ElvUI 14.0+**. Health gradient coloring has been removed due to Blizzard's secret value restrictions - see [WoW 12.0 Limitations](#wow-120-midnight-limitations) for details.

## Installation

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin) or [GitHub](https://github.com/masomh-personal/ElvUI_mhTags/releases)
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/`
3. `/reload` in-game

## Getting Started

**Open ElvUI** → `/ec` → Any unit frame → **Custom Texts** → Browse **mhTags** categories

### Popular Tags

| Tag                             | Example        | Use For                       |
| ------------------------------- | -------------- | ----------------------------- |
| `[mh-health-current-percent]`   | `100k \| 85%`  | Standard health display       |
| `[mh-health-percent{0}]`        | `85%`          | Percent with status check     |
| `[mh-health-deficit]`           | `-15k`         | Missing health (healer focus) |
| `[mh-name-caps{20}]`            | `PLAYERNAME`   | Uppercase name, max 20 chars  |
| `[mh-classification-icon]`     | 🛡️             | Elite/Rare/Boss icon          |
| `[mh-status]`                   | `AFK` + icon   | Status indicator              |

## Complete Tag Reference (29 Tags)

### Health Tags (10)

| Tag | Example Output | Description |
|-----|----------------|-------------|
| `[mh-health-current]` | `100k` | Current health formatted |
| `[mh-health-current-absorb]` | `(25k) 100k` | Absorb shield + current health (may show `(0)` for secret zero absorbs) |
| `[mh-health-percent{N}]` | `85.2%` | Health percent, `{N}` = decimals (default 1) |
| `[mh-health-percent-nosign{N}]` | `85.2` | Health percent without % sign |
| `[mh-health-current-percent]` | `100k \| 85%` | Current health and percent combined |
| `[mh-health-percent-current]` | `85% \| 100k` | Percent and current (reversed order) |
| `[mh-health-current-percent-absorb]` | `(25k) 100k \| 85%` | Absorb + current + percent (may show `(0)` for secret zero absorbs) |
| `[mh-health-deficit]` | `-15k` or `DEAD` | Missing health with status check |
| `[mh-health-deficit-nostatus]` | `-15k` | Missing health only (no status) |
| `[mh-health-deficit-percent{N}]` | `-15%` | Missing health as percent |

> **⚠️ Removed in v10**: Colored/gradient health tags were removed due to WoW 12.0 secret value restrictions. See [WoW 12.0 Limitations](#wow-120-midnight-limitations).

### Name Tags (7)

| Tag | Example Output | Description |
|-----|----------------|-------------|
| `[mh-name-caps{N}]` | `PLAYERNAME` | Uppercase name, `{N}` = max chars (default 28) |
| `[mh-name-caps-or-status{N}]` | `PLAYERNAME` + 💀 | Status with icon when AFK/Dead/etc.; otherwise name in CAPS |
| `[mh-name-caps-with-raid-group{N}]` | `PLAYERNAME (5)` | Name in CAPS; in raid, appends group number |
| `[mh-name-abbrev]` | `C.T. Dummy` | Abbreviated name (first letters + last word) |
| `[mh-name-abbrev-reverse]` | `Cleave T.D.` | Abbreviated (first word + last letters) |
| `[mh-name-abbrev-if-long{N}]` | `C.T. Dummy` | Abbreviate only if name longer than N chars (default 25) |
| `[mh-name-abbrev-if-long-reverse{N}]` | `Cleave T.D.` | Same as above, last word full |

### Classification Tags (5)

| Tag | Example Output | Description |
|-----|----------------|-------------|
| `[mh-classification-icon{N}]` | ⭐ | Unit classification icon (Boss/Elite/Rare); `{N}` = icon size (default 14) |
| `[mh-classification-icon-fixed]` | ⭐ | Same icon at fixed size (no size argument) |
| `[mh-classification-text]` | `[Elite]` | Classification as text in brackets |
| `[mh-classification-symbols]` | `E` | Single symbol (B/E/R/R+/E+) |
| `[mh-classification-plain]` | `Elite` | Plain text without brackets |

### Power Tags (1)

| Tag | Example Output | Description |
|-----|----------------|-------------|
| `[mh-power-percent{N}]` | `85` | Power percent (0–100); `{N}` = decimal places (default 0) |

### Misc Tags (6)

| Tag | Example Output | Description |
|-----|----------------|-------------|
| `[mh-smartlevel]` | `80` or `` | Shows level; hides if both player and unit are max |
| `[mh-absorb]` | `(25k)` | Absorb shield amount in yellow |
| `[mh-diff-level]` | `85` | Level with difficulty color (always shows) |
| `[mh-diff-level-hide]` | `85` or `` | Level with color; hides when you and unit both max |
| `[mh-status]` | `AFK` + 🔴 | Status text with icon (AFK/DND/Dead/Ghost/Offline) |
| `[mh-status-noicon]` | `AFK` | Status text only, no icon |

## Syntax Guide

### Decimal Places `{N}`

```
[mh-health-percent{0}]     → 85%
[mh-health-percent{1}]     → 85.3%
[mh-health-percent{2}]     → 85.34%
```

### Max Characters `{N}`

```
[mh-name-caps{15}]  → Max 15 characters
[mh-name-caps{25}]  → Max 25 characters
```

## Performance

- **300-500 KB** memory in 40-person raids
- Pre-cached icon strings and format patterns
- O(1) raid roster lookups
- Zero memory leaks
- **WoW 12.0+**: Uses native `UnitHealthPercent()` and `UnitPowerPercent()` APIs directly
- Pre-built classification text tables (created once at load)
- Icon cache fast-path for default sizes

**Utility commands:**

| Command          | Description                              |
| ---------------- | ---------------------------------------- |
| `/mhtags`        | Display addon memory usage               |
| `/mhtags debug`  | Show version info and WoW 12.0 notes |
| `/mhtags help`   | List available commands                  |

## Compatibility

|           | Version                              |
| --------- | ------------------------------------ |
| **WoW**   | Retail 12.0.0+ (Midnight) **only**   |
| **ElvUI** | 14.0+ required                       |

### WoW 12.0 (Midnight) Limitations

This addon is optimized exclusively for WoW 12.0 (Midnight) and later.

#### What Changed in WoW 12.0

Blizzard introduced a **"secret value" system** to protect combat-sensitive data in competitive content. This affects:
- **Nameplates** (enemy units)
- **Rated PvP** (arena, RBGs)
- **Competitive content** (Mythic+ leaderboards, etc.)

#### What Are Secret Values?

When health/power values are "secret," they carry a C-level taint that **cannot be removed by any Lua operation**. The taint propagates to all derived values.

**Blocked Operations on Secret Values:**

| Operation | Example | Result |
|-----------|---------|--------|
| Comparison | `percent >= 50` | ❌ Lua error |
| Arithmetic | `percent * 100` | ❌ Lua error |
| Table key | `colors[percent]` | ❌ Lua error |
| `tonumber()` | `tonumber(format('%d', secret))` | ❌ Returns `nil` |
| `string.byte()` | `string.byte(secretStr, 1)` | ❌ Lua error |
| `string.len()` | `#secretStr` | ❌ Lua error |
| `string.gsub()` | `secretStr:gsub(...)` | ❌ Lua error |

**Allowed Operations:**

| Operation | Example | Result |
|-----------|---------|--------|
| `string.format()` | `format('%d', secret)` | ✅ Returns tainted string (display only) |
| `issecretvalue()` | `issecretvalue(percent)` | ✅ Returns `true`/`false` |
| `AbbreviateNumbers()` | `AbbreviateNumbers(health)` | ✅ Returns formatted string |
| `string.concat()` | `string.concat(a, b, c)` | ✅ WoW 12.0 secret-safe concatenation |

#### Impact on This Addon

**Removed Features (v10):**
- **All colored health tags** - Gradient coloring requires table lookups (`colors[floor(percent)]`) which are blocked
- **Health color tag** (`mh-healthcolor`) - Cannot return dynamic color codes for secret values

**Removed Tags (v10):**

*Colored/Gradient Tags (9):*
- `mh-health-current-percent-colored`
- `mh-health-percent-current-colored`
- `mh-health-current-percent-colored-status`
- `mh-health-percent-current-colored-status`
- `mh-health-current-colored`
- `mh-health-percent-colored`
- `mh-health-percent-colored-status`
- `mh-health-percent-nosign-colored-status`
- `mh-healthcolor`

*"Hide at Full" Tags (2):*
- `mh-health-current-percent-hidefull`
- `mh-health-percent-current-hidefull`

> These required comparing `percent >= 100` which is blocked for secret values.

**What Still Works:**
- All non-colored health tags display values correctly
- Decimal formatting works (e.g., `{2}` for 2 decimal places)
- `string.format()` displays percentages/numbers even for secret values
- `AbbreviateNumbers()` formats large values (e.g., `2.5M`)
- Status checks (AFK, Dead, Offline) work normally
- Absorb shields display correctly (when present)

**Known Limitations:**
- **Absorb zero detection**: Tags with absorbs (e.g., `[mh-health-current-percent-absorb]`) may show `(0)` when absorb is zero and secret. All comparison methods are blocked: numeric comparison (`absorbAmount <= 0`), string comparison (`result == "0"`), and string length (`#result == 1`). **Workaround**: Use `[mh-absorb]` as a separate text element, or use non-absorb tags like `[mh-health-current-percent]` on frames where this occurs.

**Fallback Behavior:**
When health/power values are secret, tags display `---` (configurable via `MHCT.SECRET_VALUE_FALLBACK_TEXT`).

#### Why Can't We Work Around This?

We extensively tested multiple approaches:

1. **String laundering** - Format to string, then `tonumber()` back → `tonumber()` blocked on tainted strings
2. **Character extraction** - `string.byte()` each character → `string.byte()` blocked
3. **Pattern matching** - `string:match()` → Pattern functions blocked
4. **String key lookup** - `colors["85"]` with secret-derived key → Table indexing blocked

The taint is applied at the **C/engine level before Lua**, making it impossible to circumvent through any Lua manipulation.

#### Alternatives for Colored Health

If you need health-based coloring, consider:
- **Reaction-based colors** - Use `UnitReaction()` (not affected by secrets) for hostile/friendly coloring
- **Class-based colors** - Use `UnitClass()` for class colors
- **ElvUI's built-in health bars** - The bar itself can still show colors based on health %

**Configurable fallback:** `MHCT.SECRET_VALUE_FALLBACK_TEXT` (default: `"---"`)

## Support

- [GitHub Issues](https://github.com/masomh-personal/ElvUI_mhTags/issues)
- [CurseForge](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin)

**Bug reports:** Include WoW version, ElvUI version, error message, and steps to reproduce.

**Created by mhDesigns** for the World of Warcraft community
