-- ===================================================================================
-- NAME RELATED TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references from core (shared to avoid duplicate unpacking)
local E = MHCT.E

-- Localize Lua functions
local format = string.format
local tonumber = tonumber

-- Localize WoW API functions
local UnitName = UnitName
local strupper = strupper
local IsInRaid = IsInRaid
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo

-- Local constants
local NAME_SUBCATEGORY = "name"
local DEFAULT_TEXT_LENGTH = MHCT.DEFAULT_TEXT_LENGTH

-- ===================================================================================
-- NAME RELATED TAGS
-- ===================================================================================

-- Removed - no need to cache empty string

MHCT.registerTag(
	"mh-dynamic:name:caps",
	NAME_SUBCATEGORY,
	"Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag",
	"UNIT_NAME_UPDATE",
	function(unit, _, args)
		if not unit then
			return ""
		end
		local name = UnitName(unit)
		-- Early return for common case
		if not name or name == "" then
			return ""
		end

		local length = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		return E:ShortenString(strupper(name), length)
	end
)

MHCT.registerTag(
	"mh-dynamic:name:caps-statusicon",
	NAME_SUBCATEGORY,
	"Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag) - Example: [mh-dynamic:name:caps-statusicon{20}] will show name up to 20 characters",
	"UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_HEALTH INSTANCE_ENCOUNTER_ENGAGE_UNIT",
	function(unit, _, args)
		if not unit then
			return ""
		end
		-- Check for status first (less common case)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local name = UnitName(unit)
		if not name or name == "" then
			return ""
		end

		local length = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		return E:ShortenString(strupper(name), length)
	end
)

-- Removed - direct formatting is simpler
MHCT.registerTag(
	"mh-player:frame:name:caps-groupnumber",
	NAME_SUBCATEGORY,
	"Shows unit name in all CAPS with a dynamic # of characters + unit group number if in raid (dynamic number within {} of tag)",
	"UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE",
	function(unit, _, args)
		if not unit then
			return ""
		end
		local name = UnitName(unit)
		if not name or name == "" then
			return ""
		end

		local length = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		local formatted = E:ShortenString(strupper(name), length)

		-- Only do raid group lookup if actually in a raid
		if not IsInRaid() then
			return formatted
		end

		-- Find raid group number (simple iteration, only fires on roster/name changes)
		local numMembers = GetNumGroupMembers()
		for i = 1, numMembers do
			local raidName, _, group = GetRaidRosterInfo(i)
			if raidName == name then
				return format("%s |cff00FFFF(%s)|r", formatted, group)
			end
		end

		return formatted
	end
)

-- ===================================================================================
-- Helper function for name abbreviation with configurable parameters
local function formatAbbreviatedName(unit, reverse, lengthThreshold)
	if not unit then
		return ""
	end
	local name = UnitName(unit)
	if not name then
		return ""
	end

	-- Convert to uppercase once
	local uppercaseName = strupper(name)

	-- If length threshold is provided, only abbreviate if name is longer
	if lengthThreshold and #name <= lengthThreshold then
		return uppercaseName
	end

	-- Use the abbreviate function with the uppercase name
	return MHCT.abbreviate(uppercaseName, reverse, unit)
end

-- Then use this helper in all abbreviation tags
MHCT.registerTag(
	"mh-name:caps:abbrev",
	NAME_SUBCATEGORY,
	"Name abbreviation/shortener - Example: 'Cleave Training Dummy' => 'C.T. Dummy'",
	"UNIT_NAME_UPDATE",
	function(unit)
		if not unit then
			return ""
		end
		return formatAbbreviatedName(unit, false)
	end
)

MHCT.registerTag(
	"mh-name:caps:abbrev-reverse",
	NAME_SUBCATEGORY,
	"Name abbreviation/shortener - Example: 'Cleave Training Dummy' => 'Cleave T.D.'",
	"UNIT_NAME_UPDATE",
	function(unit)
		if not unit then
			return ""
		end
		return formatAbbreviatedName(unit, true)
	end
)

MHCT.registerTag(
	"mh-name-caps-abbrev-V2",
	NAME_SUBCATEGORY,
	"Name abbreviation/shortener if greater than 25 characters - Example: 'Cleave Training Dummy' => 'C.T. Dummy'",
	"UNIT_NAME_UPDATE",
	function(unit, _, nameLen)
		if not unit then
			return ""
		end
		return formatAbbreviatedName(unit, false, tonumber(nameLen) or 25)
	end
)

MHCT.registerTag(
	"mh-name-caps-abbrev-reverse-V2",
	NAME_SUBCATEGORY,
	"Name abbreviation/shortener if greater than 25 characters - Example: 'Cleave Training Dummy' => 'Cleave T.D.'",
	"UNIT_NAME_UPDATE",
	function(unit, _, nameLen)
		if not unit then
			return ""
		end
		return formatAbbreviatedName(unit, true, tonumber(nameLen) or 25)
	end
)
