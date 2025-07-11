# MH Custom Tags (ElvUI Plugin)

## <span style="color:white">[4.0.2] TOC/Patch Update 11.1.7 (June 18th, 2025)</span>.

- **MAINTENANCE**: Updated TOC for 11.1.7

## <span style="color:white">[4.0.1] Bug Fix (June 13th, 2025)</span>.

### Bug Fixes

- **FIXED**: `formatHealthPercent` function in core.lua not displaying max HP at full health due to incorrect ElvUI function reference
- **FIXED**: Health tags using `MHCT.formatHealthPercent` now properly show formatted max HP value when at full health instead of showing nothing

## <span style="color:cyan">[4.0.0] Major update and refactor (May 17th, 2025)</span>.

### Performance Optimizations

- Implemented proper Lua localization patterns throughout all modules
- Optimized string handling with direct concatenation and cached format patterns
- Reduced memory allocations by reusing variables and pre-allocating where possible
- Optimized color gradient table generation with more efficient interpolation
- Cached frequently used values to reduce redundant calculations

### Code Structure Improvements

- Created tag registration helpers to standardize tag creation
- Reorganized files and modules for better maintainability
- Implemented consistent naming conventions across modules
- Moved related functionality to appropriate modules (e.g., health color tags)

### New Features

- Implemented multiple update frequencies for performance-critical tags
- Added new tag variants with different formatting options
- Enhanced abbreviation functionality for name tags

### Developer Improvements

- Added memory leak testing capabilities
- Improved code documentation and comments
- Standardized module structure for easier maintenance

## <span style="color:white">[3.0.4] TOC/Patch Update 11.5.0 (April 23rd, 2025)</span>.

- MAINTENANCE: Updated CL and TOC for 11.5.0

## <span style="color:white">[3.0.3] TOC/Patch Update 11.1.0 (Feb 24th, 2025)</span>.

- MAINTENANCE: Updated CL and TOC for 11.1.0

## <span style="color:white">[3.0.2] TOC/Patch Update 11.0.7 (December 17th, 2024)</span>.

- MAINTENANCE: Updated CL and TOC for 11.0.7
- MISC: Rearranged and cleaned up folder structure to make root addon folder less crowded
- MISC: Code cleanup of level tag to denote rares, boss rares, elite rares, etc.

## <span style="color:white">[3.0.1] Minor code clean up (November 27th, 2024)</span>.

- MISC: Woopsie! I forgot to remove print statement in `init.lua`

## <span style="color:cyan">[3.0.0] Major Update (November 11th, 2024)</span>.

- Complete refactor of code, cleaned up local variables, and made things a bit more efficient
- Utilized WOW Addon private namespace object for cleaner variable usage
- Rechecked every tag to ensure proper events were being used (and not adding event checks we don't need)
- Separated each category to have it's own file for better modularity
- **ADDED**: many new health related tags in `[health-v2]` category that focus on efficiency and second interval updates instead of using blizzard health related events. This has helped with CPU usage in raids/parties

## <span style="color:white">[2.0.3] (October 21st, 2024)</span>.

- MISC: TOC updated for patch 11.0.5
- MISC: tag categorized by type so can be easily viewed in the ElvUI options: "Available Tags" section
- MISC: code clean up

## <span style="color:white">[2.0.2] (September 5th, 2024)</span>.

- MISC: maintenance and small fixes with wording
- MISC: added additional comments and structure

## <span style="color:white">[2.0.1] (August 27th, 2024)</span>.

- NEW Tag: `[mh-health:current:percent:left-hidefull]`
- NEW Tag: `[mh-smartlevel]`
- BUG: Woopsie, accidentally deleted addon icon

## <span style="color:cyan">[2.0.0] Major Update (August 18th, 2024)</span>.

- Overhauled for TWW
- Complete revamp of code structure
- Added separate utility file to handle non tag specific logic
- Greatly increased performance of `[mh-health-color]` tag and created a static lookup table
- Refactored lots of functions to return sooner or fail faster
- Created additional helper functions to follow DRY methodology
- Cleaned up almost all functions
- Ensured all global variables were properly localized to help with faster look up

## <span style="color:white">[1.0.9] (August 17th, 2024)</span>.

- NEW TAG: mh-status-noicon
- DEF: Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (NO icon, text only)

## [1.0.8] (August 13th, 2024)

- TOC update for TWW pre patch
- Fixed issue with API updated RE: isAddOnLoaded()

## [1.0.7] (July 24th, 2024)

- TOC update for TWW pre patch

## [1.0.6] (2024-5-5)

- TOC update for 10.2.7

## [1.0.5] (2024-3-19)

- TOC update for 10.2.6
- Added helper function that works like JavaScript Array.includes()
- Added helper function 'abbreviate' to abbreviate longer names in two ways (default/reverse)
- NEW Tag: mh-name:caps:abbrev (see examples of abbreviations below)
- Reverse abbreviate example: Cleave Training Dummy => Cleave T. D.
- Default abbreviate example: Cleave Training Dummy => C. T. Dummy
- Small edits for status formatter to have a reverse status (icon and text)
- Small changes for default icon sizes

## [1.0.4] (2024-1-17)

- TOC update for 10.2.5

## [1.0.3] (2023-12-29)

- Created static absorb text color variable
- NEW Tag: simple percent v2 which is hidden at max health
- NEW Tag: mh-absorb (just absorb text)
- Code clean-up to remove unnecessary event hooks
- Updated/cleaned some lua code comments
- Code clean up and made some local constants
- Reworked classification helper function to properly handle rare and rareelite classification
- Updated some static/constant default values to align with UI

## [1.0.2] (2023-12-19)

- Cleaned up code and reorganized
- Re-coded status check and classification helpers
- Updated Readme
- Boss icon change, spelling fixes, and created constant set default icon size
- Added new deficit tags (both number and percentage, with and without status)
- Added new health gradient variation from ElvUI (brighter and higher contrast)
- Added new simple percent tag but with no percent sign
- Made boss classification icon a bit smaller (red skull)
- Cleaned up iconTable for only relevant icons and used same naming scheme for all
- Proper camelCase!
- Added new simple percent v2 that has no % sign
- Added new simple status tag that only shows status' if relevant
- Updated TOC accordingly

## [1.0.1] (2023-12-14)

- Updated and cleaned up code across several tags
- Renamed 'mh-dynamic:name:caps-deadicon' to 'mh-dynamic:name:caps-statusicon to properly describe the tag
- Updated a few tag info entries

## [1.0] (2023-12-12)

- ElvUI plugin to create custom tags (creation of addon, initital commit)
