# ElvUI MH Tags

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
