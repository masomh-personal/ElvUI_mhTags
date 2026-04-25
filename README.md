# ElvUI_mhTags

[![Version](https://img.shields.io/badge/Version-10-brightgreen)](https://github.com/masomh-personal/ElvUI_mhTags)
[![ElvUI](https://img.shields.io/badge/Requires-ElvUI%2015.0+-blue)](https://www.tukui.org/download.php?ui=elvui)
[![WoW](https://img.shields.io/badge/WoW-12.0.5%20Midnight+-orange)](https://worldofwarcraft.com)
[![License](https://img.shields.io/badge/License-GPL--3.0-yellow)](LICENSE)

Custom ElvUI unit-frame tags for WoW Retail 12.0.5+ (Midnight).

ElvUI_mhTags adds 70 focused tags for health, power, names, classifications, levels, status text, combined nameplates, and reusable color prefixes. It is Retail-only and intentionally targets Midnight's addon API restrictions.

> Important: WoW 12 introduced secret values for combat-sensitive data. This addon uses `UnitHealthPercent()`, `UnitPowerPercent()`, `UnitHealthMissing()`, `issecretvalue()`, and `CurveConstants.ScaleTo100` directly. Health-gradient tags were removed because secret values cannot be compared, used for arithmetic, or used as table keys.

## Requirements

- World of Warcraft Retail 12.0.5+ (Midnight)
- ElvUI 15.0+
- Retail addon folder: `World of Warcraft/_retail_/Interface/AddOns/ElvUI_mhTags`

## Installation

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin) or [GitHub Releases](https://github.com/masomh-personal/ElvUI_mhTags/releases).
2. Extract the `ElvUI_mhTags` folder into `World of Warcraft/_retail_/Interface/AddOns/`.
3. Restart WoW or run `/reload`.
4. Open ElvUI with `/ec`, go to a unit frame, open Custom Texts, and browse the `mhTags` categories.

## Popular Tags

- `[mh-health-current-percent]`: current health and percent, for example `100k | 85%`
- `[mh-health-percent{0}]`: health percent with custom decimal places, for example `85%`
- `[mh-health-deficit]`: missing health or status, for example `-15k` or `DEAD`
- `[mh-name-caps{20}]`: uppercase name capped to 20 characters
- `[mh-classification-icon]`: boss, elite, rare, and elite-plus icon
- `[mh-classification-name-level{14}]`: classification icon, name, and colored level in one tag
- `[mh-color-custom{FF5733}][mh-health-current]|r`: custom color prefix around another tag
- `[mh-status]`: AFK, DND, Dead, Ghost, or Offline status with icon

## Tag Reference

### Health Tags

- `[mh-health-current]`: current health, formatted
- `[mh-health-current-absorb]`: absorb shield plus current health
- `[mh-health-percent{N}]`: health percent with status check, default 1 decimal
- `[mh-health-percent-nosign{N}]`: health percent without `%`, default 1 decimal
- `[mh-health-current-percent]`: current health then percent
- `[mh-health-percent-current]`: percent then current health
- `[mh-health-current-percent-absorb]`: absorb, current health, and percent
- `[mh-health-deficit]`: missing health with status check
- `[mh-health-deficit-nostatus]`: missing health only
- `[mh-health-deficit-percent{N}]`: missing health percent, default 1 decimal

### Name Tags

- `[mh-name-caps{N}]`: uppercase unit name, default 28 characters
- `[mh-name-caps-or-status{N}]`: status when present, otherwise uppercase name
- `[mh-name-caps-with-raid-group{N}]`: uppercase name plus raid group number
- `[mh-name-abbrev]`: abbreviated uppercase name
- `[mh-name-abbrev-reverse]`: reverse abbreviated uppercase name
- `[mh-name-abbrev-if-long{N}]`: abbreviates only when longer than the threshold, default 25
- `[mh-name-abbrev-if-long-reverse{N}]`: reverse abbreviation only when longer than the threshold

### Classification Tags

- `[mh-classification-icon{N}]`: classification icon with optional size
- `[mh-classification-icon-fixed]`: classification icon at default size
- `[mh-classification-text]`: colored bracketed classification text
- `[mh-classification-symbols]`: compact classification symbol
- `[mh-classification-plain]`: plain classification text

### Combined Tags

- `[mh-classification-name-level{N}]`: classification icon, uppercase name, and colored level
- `[mh-classification-name-level-smart{N}]`: same as above, but hides max-level player/unit matches
- `[mh-classification-name{N}]`: classification icon and uppercase name
- `[mh-classification-name-level-raid-group{N}]`: classification icon, uppercase name, raid group, and level

### Power Tags

- `[mh-power-percent{N}]`: current power percent, default 0 decimals

### Misc Tags

- `[mh-smartlevel]`: level, hidden when both player and unit are max level
- `[mh-absorb]`: absorb shield amount in parentheses
- `[mh-diff-level]`: level colored by difficulty
- `[mh-diff-level-hide]`: difficulty-colored level, hidden at max level
- `[mh-status]`: status with icon
- `[mh-status-noicon]`: status text only

### Color Prefix Tags

Color tags return an opening color code and are meant to wrap other tags. Always close them with `|r`.

- Basic colors: `red`, `green`, `blue`, `cyan`, `magenta`, `black`, `gray`, `grey`, `purple`, `lime`, `brown`
- Class colors: `deathknight`, `demonhunter`, `druid`, `evoker`, `hunter`, `mage`, `monk`, `paladin`, `priest`, `rogue`, `shaman`, `warlock`, `warrior`
- Emerald palette: `emerald-green`, `emerald-red`, `emerald-blue`, `emerald-yellow`, `emerald-cyan`, `emerald-orange`
- Pastel palette: `pastel-green`, `pastel-red`, `pastel-blue`, `pastel-yellow`, `pastel-cyan`, `pastel-orange`
- Custom hex: `[mh-color-custom{RRGGBB}]`

Example:

```text
[mh-color-pastel-green][mh-health-current-percent]|r
```

## Decimal and Length Arguments

Decimal arguments are clamped to `0-3` decimal places.

```text
[mh-health-percent{0}]  -> 85%
[mh-health-percent{1}]  -> 85.3%
[mh-health-percent{2}]  -> 85.34%
[mh-power-percent{0}]   -> 85
```

Name and combined tags use `{N}` as a maximum character length.

```text
[mh-name-caps{15}]
[mh-classification-name-level{18}]
```

## Midnight Limitations

Blizzard's secret value system can restrict health, power, unit state, and some nameplate information in competitive or protected contexts. Secret values can be displayed by approved formatting paths, but they cannot safely be transformed like normal Lua values.

Blocked or unsafe operations include:

- Comparing secret values, for example `percent >= 50`
- Arithmetic on secret values, for example `100 - percent`
- Using secret values as table keys
- Calling string manipulation methods on secret-derived strings
- Converting secret-derived strings back through `tonumber()`

Supported display paths used by this addon include:

- `UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)`
- `UnitPowerPercent(unit, powerType, false, CurveConstants.ScaleTo100)`
- `UnitHealthMissing(unit)`
- `AbbreviateNumbers(value)`
- `string.format(pattern, value)`
- `issecretvalue(value)` before unsafe operations

Known behavior:

- Health-gradient and hide-at-full tags are removed because they require comparisons or color lookups based on secret values.
- Absorb tags may show `(0)` when a zero absorb is secret. The addon cannot compare or inspect the value to hide it safely.
- Deficit percent is hidden when arithmetic is blocked by secret values.
- Secret names are displayed as-is and are not uppercased, shortened, or abbreviated.

## Slash Commands

- `/mhtags`: show addon memory usage
- `/mhtags debug`: show addon, ElvUI, and target WoW version info
- `/mhtags help`: list commands

## Release Process

CurseForge project ID: `949599`.

Before publishing:

- Update `ElvUI_mhTags.toc`, `core.lua`, `README.md`, and `CHANGELOG.md` to the release version.
- Create a GitHub release tag such as `v10`.
- Attach or publish the addon zip with the folder name `ElvUI_mhTags`.
- Let the linked CurseForge project import/sync the GitHub release through the existing CurseForge setup.

## Packaging Notes

- Package folder name: `ElvUI_mhTags`
- CurseForge project ID: `949599`
- Retail game flavor: `retail`
- TOC interface: `120005`
- Minimum ElvUI: `15.0`
- License: GPL-3.0
- Binary icon assets in `icons/` are required for status and classification texture tags.

## Support

- [GitHub Issues](https://github.com/masomh-personal/ElvUI_mhTags/issues)
- [CurseForge](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin)

Bug reports should include WoW version, ElvUI version, tag string, error message, and reproduction steps.

Created by mhDesigns for the World of Warcraft community.
