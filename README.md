# ElvUI_mhTags

[![Version](https://img.shields.io/badge/Version-9.0-brightgreen)](https://github.com/masomh-personal/ElvUI_mhTags)
[![ElvUI](https://img.shields.io/badge/Requires-ElvUI%2014.0+-blue)](https://www.tukui.org/download.php?ui=elvui)
[![WoW](https://img.shields.io/badge/WoW-12.0.0%20Midnight+-orange)](https://worldofwarcraft.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

**32 custom tags for ElvUI unit frames.** Lightweight, performant, and WoW 12.0 (Midnight) optimized.

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
| `[mh-dynamic:name:caps{20}]`    | `PLAYERNAME`   | Uppercase name, max 20 chars  |
| `[mh-classification:icon]`      | 🛡️             | Elite/Rare/Boss icon          |
| `[mh-status]`                   | `AFK` + icon   | Status indicator              |

## Complete Tag Reference (32 Tags)

### Health Tags (12)

| Tag | Example Output | Description |
|-----|----------------|-------------|
| `[mh-health-current]` | `100k` | Current health with ElvUI formatting |
| `[mh-health-current-absorb]` | `(25k) 100k` | Absorb shield + current health |
| `[mh-health-percent{N}]` | `85.2%` | Health percent, `{N}` = decimals (default 1) |
| `[mh-health-percent-nosign{N}]` | `85.2` | Health percent without % sign |
| `[mh-health-current-percent]` | `100k \| 85%` | Current health and percent combined |
| `[mh-health-percent-current]` | `85% \| 100k` | Percent and current (reversed order) |
| `[mh-health-current-percent-hidefull]` | `100k \| 85%` | Hides percent when at full health |
| `[mh-health-percent-current-hidefull]` | `85% \| 100k` | Hides percent when at full (reversed) |
| `[mh-health-current-percent-absorb]` | `(25k) 100k \| 85%` | Absorb + current + percent |
| `[mh-health-deficit]` | `-15k` or `DEAD` | Missing health with status check |
| `[mh-health-deficit-nostatus]` | `-15k` | Missing health only (no status) |
| `[mh-health-deficit-percent{N}]` | `-15%` | Missing health as percent |

> **⚠️ Removed in v9.0**: All colored/gradient health tags were removed due to WoW 12.0 secret value restrictions. See [WoW 12.0 Limitations](#wow-120-midnight-limitations).

### Name Tags (7)

| Tag | Example Output | Description |
|-----|----------------|-------------|
| `[mh-dynamic:name:caps{N}]` | `PLAYERNAME` | Uppercase name, `{N}` = max chars (default 28) |
| `[mh-dynamic:name:caps-statusicon{N}]` | `PLAYERNAME` + 💀 | Uppercase name with status icon |
| `[mh-player:frame:name:caps-groupnumber{N}]` | `PLAYERNAME (5)` | Name with raid group number |
| `[mh-name:caps:abbrev]` | `C.T. Dummy` | Abbreviated name (first letters + last word) |
| `[mh-name:caps:abbrev-reverse]` | `Cleave T.D.` | Abbreviated (first word + last letters) |
| `[mh-name-caps-abbrev-V2{N}]` | `C.T. Dummy` | Abbreviate only if name > N chars |
| `[mh-name-caps-abbrev-reverse-V2{N}]` | `Cleave T.D.` | Abbreviate reverse if > N chars |

### Classification Tags (5)

| Tag | Example Output | Description |
|-----|----------------|-------------|
| `[mh-classification:icon]` | ⭐ | Custom icon for Elite/Rare/Boss (dynamic size) |
| `[mh-classification:icon-V2]` | ⭐ | Same as above but fixed 14px size |
| `[mh-classification:text]` | `[Elite]` | Colored text with brackets |
| `[mh-classification:text-compact]` | `E` | Single letter (B/E/R/R+/E+) |
| `[mh-classification:text-full]` | `Elite` | Full text without brackets |

### Power Tags (1)

| Tag | Example Output | Description |
|-----|----------------|-------------|
| `[mh-power-percent{N}]` | `85` | Power percent (mana/energy/rage), `{N}` = decimals |

### Misc Tags (7)

| Tag | Example Output | Description |
|-----|----------------|-------------|
| `[mh-smartlevel]` | `80` or `` | Shows level; hides if both player and unit are max |
| `[mh-absorb]` | `(25k)` | Absorb shield amount in yellow |
| `[mh-difficultycolor:level]` | `85` | Level with difficulty color (always shows) |
| `[mh-difficultycolor:level-hide]` | `85` or `` | Level with color; hides at max level |
| `[mh-status]` | `AFK` + 🔴 | Status text with icon (AFK/DND/Dead/Ghost/Offline) |
| `[mh-status-noicon]` | `AFK` | Status text only, no icon |
| `[mh-healer-drinking]` | `DRINKING...` | Shows only for healers when drinking/eating |

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

**Removed Features (v9.0):**
- **All colored health tags** - Gradient coloring requires table lookups (`colors[floor(percent)]`) which are blocked
- **Health color tag** (`mh-healthcolor`) - Cannot return dynamic color codes for secret values

**Removed Tags:**
- `mh-health-current-percent-colored`
- `mh-health-percent-current-colored`
- `mh-health-current-percent-colored-status`
- `mh-health-percent-current-colored-status`
- `mh-health-current-colored`
- `mh-health-percent-colored`
- `mh-health-percent-colored-status`
- `mh-health-percent-nosign-colored-status`
- `mh-healthcolor`

**What Still Works:**
- All non-colored health tags display values correctly
- Formatting with `string.format()` shows percentages/numbers
- `AbbreviateNumbers()` formats large values (e.g., `2.5M`)
- Status checks (AFK, Dead, Offline) work normally
- Absorb shields display correctly (when not secret)

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
