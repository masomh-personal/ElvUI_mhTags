## MH Custom Tags for ElvUI

A lightweight ElvUI plugin that provides a comprehensive set of high-quality custom tags for unit frames and nameplates. Designed for clarity, flexibility, and performance in all content types (solo, dungeons, raids, and PvP).

### Key features

- **Extensive tag library**: 30+ tags across health, power, name, classification, and status categories
- **Performance-focused**: Throttled variants for high-density scenarios and efficient string/format handling
- **Consistent UX**: Clear naming, predictable output, and sensible defaults
- **Status & classification icons**: Purpose-built icons for AFK/DND/Offline/Dead/Ghost and unit rarity/classification
- **Backwards compatible**: All existing tags are preserved so profiles continue to work

## Requirements

- **ElvUI** (latest retail version)
- World of Warcraft Retail (Interface 110200)

## Installation

### Via CurseForge

Install from the CurseForge page: [MH Custom Tags (ElvUI Plugin)](https://www.curseforge.com/wow/addons/mh-custom-tags-elvui-plugin)

### Manual installation

1. Download the release zip
2. Extract to your addons folder: `World of Warcraft/_retail_/Interface/AddOns/`
3. Ensure the folder name is `ElvUI_mhTags`
4. Restart the game client and enable the addon at the character select screen

## Usage

1. Open ElvUI configuration with `/ec`
2. Navigate to the unit frame or nameplate you want to customize (e.g., Player, Target, Nameplates)
3. In a text field that accepts tags (e.g., Health Text, Name Text), insert any of the provided tags
4. Many tags support arguments via `{}` for decimals or behavior

### Examples

- Health percent with a percent sign and one decimal: `[mh-health:simple:percent{1}]`
- Current | Percent (shows both): `[mh-health:current:percent:right]`
- Hide percent at full health: `[mh-health:current:percent:right-hidefull]`
- Health deficit with status (short value): `[mh-deficit:num-status]`
- Status text only (no icon): `[mh-status-noicon]`
- Classification icon: `[mh-classification:icon]`
- Power percent (no % sign, 0 decimals): `[mh-power-percent{0}]`
- Uppercase abbreviated name: `[mh-name:caps:abbrev]`

### Throttled tags

Most frequently used tags include throttled variants that update every 0.25s, 0.5s, 1.0s, or 2.0s. These use the same base names with a suffix (for example):

- `[mh-health:current:percent:right-0.5]`
- `[mh-health-percent:status-1.0]`

Use throttled tags on raid frames or in high-density scenarios for improved performance.

## Tag catalog

All tags appear inside ElvUI under the category `mhTags [subcategory]`.

- **health-v1**: Simple percent (with/without percent sign), current | percent, hide-at-full, deficit (number and percent)
- **health-v2**: Status-aware percent, deficit with status, low-health colored, gradient-colored variants, color-only
- **power**: Percent-only with configurable decimals
- **name**: Uppercase, length-limited, and abbreviation helpers (including reverse abbreviation)
- **classification**: Icons and text for rare, elite, boss, and related types
- **misc**: Smart level, absorb text, status (with or without icon), difficulty color + level

For concrete names and full coverage, see the `Available Tags` panel in ElvUI or the source files under `tags/`.

## Compatibility and performance

- Designed for Retail; ElvUI is a required dependency
- No saved variables; the addon is stateless and safe to add/remove
- Optimized string formatting and optional throttling minimize CPU use
- All previously published tag names are preserved for profile compatibility

## Images

![image](https://github.com/masomh-personal/ElvUI_mhTags/assets/94949987/d5b72d1c-6789-48b4-ae45-798b829c840d)

## Support and feedback

- Report issues or request features on GitHub via issues or pull requests
- Alternatively, use the comments section on the CurseForge page

Please include:

- What tag(s) you were using and the exact tag string
- Screenshots or steps to reproduce
- ElvUI version and WoW client build

## License

This project is licensed under the GNU General Public License v3.0. See `LICENSE` for details.

## Changelog

See `CHANGELOG.md` for release notes and version history.
