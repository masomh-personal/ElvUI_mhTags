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

-- Localize WoW API functions
-- strupper is still needed directly in formatAbbreviatedName
local strupper = strupper

-- Local constants
local NAME_SUBCATEGORY = "name"
local DEFAULT_TEXT_LENGTH = MHCT.DEFAULT_TEXT_LENGTH

-- ===================================================================================
-- NAME RELATED TAGS
-- ===================================================================================

MHCT.registerTag(
	"mh-name-caps",
	NAME_SUBCATEGORY,
	"Unit name in CAPS. Use {N} for max character length (default 28). Example: [mh-name-caps{20}]",
	"UNIT_NAME_UPDATE",
	function(unit, _, args)
		local length = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		-- MHCT.getFormattedUnitName handles secret/nil/empty and CAPS+shorten in one call
		local name = MHCT.getFormattedUnitName(unit, length)
		if name == nil then
			return ""
		end
		return name
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
		-- Status check first; status wins over name display
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local length = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		local name = MHCT.getFormattedUnitName(unit, length)
		if name == nil then
			return ""
		end
		return name
	end
)

MHCT.registerTag(
	"mh-name-caps-with-raid-group",
	NAME_SUBCATEGORY,
	"Unit name in CAPS. In raid, appends raid group number (e.g. Name (3)). Use {N} for max name length (default 28). Example: [mh-name-caps-with-raid-group{20}]",
	"UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE",
	function(unit, _, args)
		local length = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		local name = MHCT.getFormattedUnitName(unit, length)
		if name == nil then
			return ""
		end
		return MHCT.appendRaidGroupToName(unit, name)
	end
)

-- ===================================================================================
-- Helper for abbreviation tags — uses MHCT.getUnitNameSafe so secret/nil handling
-- is centralized in core.lua rather than repeated here.
local function formatAbbreviatedName(unit, reverse, lengthThreshold)
	local name, isSecret = MHCT.getUnitNameSafe(unit)
	if name == nil then
		return ""
	end
	-- Secret names can't be transformed (strupper/#len would error on them)
	if isSecret then
		return name
	end

	local uppercaseName = strupper(name)

	-- Only abbreviate when name exceeds the threshold (if one is given)
	if lengthThreshold and #name <= lengthThreshold then
		return uppercaseName
	end

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
		-- Use parseDecimalArg for consistency with all other {N} tags
		return formatAbbreviatedName(unit, false, MHCT.parseDecimalArg(nameLen, 25))
	end
)

MHCT.registerTag(
	"mh-name-abbrev-if-long-reverse",
	NAME_SUBCATEGORY,
	"Same as mh-name-abbrev-if-long but last word full. Use {N} for length threshold (default 25). Example: [mh-name-abbrev-if-long-reverse{30}]",
	"UNIT_NAME_UPDATE",
	function(unit, _, nameLen)
		return formatAbbreviatedName(unit, true, MHCT.parseDecimalArg(nameLen, 25))
	end
)
