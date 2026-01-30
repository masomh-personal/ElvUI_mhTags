-- ===================================================================================
-- NAME RELATED TAGS - Optimized for efficiency
-- ===================================================================================
--
-- WoW 12.0+ Compatibility:
-- UnitName() may return secret values in combat for non-player units in 12.0+.
-- We use issecretvalue() to detect this and handle gracefully.
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
local issecretvalue = issecretvalue

-- Local constants
local NAME_SUBCATEGORY = "name"
local DEFAULT_TEXT_LENGTH = MHCT.DEFAULT_TEXT_LENGTH

-- Helper: Get name safely, handling secret values
-- Returns: name, isSecret
-- For secret values, we return them as-is (can't transform but can display)
local function getValidName(unit)
	if not unit then
		return nil, false
	end
	local name = UnitName(unit)
	if not name then
		return nil, false
	end
	-- Secret values can still be displayed by FontString, but can't be transformed
	if issecretvalue(name) then
		return name, true
	end
	-- Non-secret: check if empty
	if name == "" then
		return nil, false
	end
	return name, false
end

-- Helper: Format name with uppercase and length limit (only works on non-secret)
local function formatName(name, isSecret, length)
	if isSecret then
		-- Can't transform secret names, return as-is
		return name
	end
	return E:ShortenString(strupper(name), length)
end

-- ===================================================================================
-- NAME RELATED TAGS
-- ===================================================================================

-- Removed - no need to cache empty string

MHCT.registerTag(
	"mh-name-caps",
	NAME_SUBCATEGORY,
	"Unit name in CAPS. Use {N} for max character length (default 28). Example: [mh-name-caps{20}]",
	"UNIT_NAME_UPDATE",
	function(unit, _, args)
		local name, isSecret = getValidName(unit)
		if not name then
			return ""
		end

		local length = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		return formatName(name, isSecret, length)
	end
)

MHCT.registerTag(
	"mh-name-caps-or-status",
	NAME_SUBCATEGORY,
	"Shows status with icon when AFK, Dead, Offline, etc.; otherwise unit name in CAPS. Use {N} for max name length (default 28). Example: [mh-name-caps-or-status{20}]",
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

		local name, isSecret = getValidName(unit)
		if not name then
			return ""
		end

		local length = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		return formatName(name, isSecret, length)
	end
)

MHCT.registerTag(
	"mh-name-caps-with-raid-group",
	NAME_SUBCATEGORY,
	"Unit name in CAPS. In raid, appends raid group number (e.g. Name (3)). Use {N} for max name length (default 28). Example: [mh-name-caps-with-raid-group{20}]",
	"UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE",
	function(unit, _, args)
		local name, isSecret = getValidName(unit)
		if not name then
			return ""
		end

		local length = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		local formatted = formatName(name, isSecret, length)

		-- Only do raid group lookup if actually in a raid (and name is not secret)
		if not IsInRaid() or isSecret then
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
	local name, isSecret = getValidName(unit)
	if not name then
		return ""
	end

	-- Secret names can't be transformed, return as-is
	if isSecret then
		return name
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

-- Abbreviation tags using the helper
MHCT.registerTag(
	"mh-name-abbrev",
	NAME_SUBCATEGORY,
	"Abbreviated name in CAPS (e.g. Cleave Training Dummy → C.T. Dummy).",
	"UNIT_NAME_UPDATE",
	function(unit)
		return formatAbbreviatedName(unit, false)
	end
)

MHCT.registerTag(
	"mh-name-abbrev-reverse",
	NAME_SUBCATEGORY,
	"Abbreviated name with last word full (e.g. Cleave Training Dummy → Cleave T.D.).",
	"UNIT_NAME_UPDATE",
	function(unit)
		return formatAbbreviatedName(unit, true)
	end
)

MHCT.registerTag(
	"mh-name-abbrev-if-long",
	NAME_SUBCATEGORY,
	"Name in CAPS; abbreviates only if longer than {N} characters (default 25). Use {N} for length threshold. Example: [mh-name-abbrev-if-long{30}]",
	"UNIT_NAME_UPDATE",
	function(unit, _, nameLen)
		return formatAbbreviatedName(unit, false, tonumber(nameLen) or 25)
	end
)

MHCT.registerTag(
	"mh-name-abbrev-if-long-reverse",
	NAME_SUBCATEGORY,
	"Same as mh-name-abbrev-if-long but last word full. Use {N} for length threshold (default 25). Example: [mh-name-abbrev-if-long-reverse{30}]",
	"UNIT_NAME_UPDATE",
	function(unit, _, nameLen)
		return formatAbbreviatedName(unit, true, tonumber(nameLen) or 25)
	end
)
