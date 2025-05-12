-- ===================================================================================
-- NAME RELATED TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Localize Lua functions
local format = string.format
local tonumber = tonumber

-- Get ElvUI references directly
local E = unpack(ElvUI)

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

-- Name in CAPS with configurable length
MHCT.registerTag(
	"mh-dynamic:name:caps",
	NAME_SUBCATEGORY,
	"Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag",
	"UNIT_NAME_UPDATE",
	function(unit, _, args)
		local name = UnitName(unit) or ""
		local cname = strupper(name)
		local length = tonumber(args) or DEFAULT_TEXT_LENGTH
		return E:ShortenString(cname, length)
	end
)

-- Name abbreviation - C.T. Dummy format
MHCT.registerTag(
	"mh-name:caps:abbrev",
	NAME_SUBCATEGORY,
	"Name abbreviation/shortener - Example: 'Cleave Training Dummy' => 'C.T. Dummy'",
	"UNIT_NAME_UPDATE",
	function(unit)
		local name = UnitName(unit)
		if name then
			return MHCT.abbreviate(strupper(name), false, unit)
		end
		return ""
	end
)

-- Name abbreviation reversed - Cleave T.D. format
MHCT.registerTag(
	"mh-name:caps:abbrev-reverse",
	NAME_SUBCATEGORY,
	"Name abbreviation/shortener - Example: 'Cleave Training Dummy' => 'Cleave T.D.'",
	"UNIT_NAME_UPDATE",
	function(unit)
		local name = UnitName(unit)
		if name then
			return MHCT.abbreviate(strupper(name), true, unit)
		end
		return ""
	end
)

-- Name with status icon
MHCT.registerTag(
	"mh-dynamic:name:caps-statusicon",
	NAME_SUBCATEGORY,
	"Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag) - Example: [mh-dynamic:name:caps-statusicon{20}] will show name up to 20 characters",
	"UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_HEALTH INSTANCE_ENCOUNTER_ENGAGE_UNIT",
	function(unit, _, args)
		local name = UnitName(unit) or ""
		if not name then
			return ""
		end

		local cname = strupper(name)
		local length = tonumber(args) or DEFAULT_TEXT_LENGTH

		-- Check for status first
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return E:ShortenString(cname, length)
	end
)

-- V2 Name abbrev - only abbreviate if over length limit
MHCT.registerTag(
	"mh-name-caps-abbrev-V2",
	NAME_SUBCATEGORY,
	"Name abbreviation/shortener if greater than 25 characters - Example: 'Cleave Training Dummy' => 'C.T. Dummy'",
	"UNIT_NAME_UPDATE",
	function(unit, _, nameLen)
		local name = UnitName(unit)
		if not name then
			return ""
		end

		-- If no argument is provided, default to 25
		local maxLength = tonumber(nameLen) or 25
		if #name <= maxLength then
			return strupper(name)
		else
			return MHCT.abbreviate(strupper(name), false, unit)
		end
	end
)

-- V2 Name abbrev reversed
MHCT.registerTag(
	"mh-name-caps-abbrev-reverse-V2",
	NAME_SUBCATEGORY,
	"Name abbreviation/shortener if greater than 25 characters - Example: 'Cleave Training Dummy' => 'Cleave T.D.'",
	"UNIT_NAME_UPDATE",
	function(unit, _, nameLen)
		local name = UnitName(unit)
		if not name then
			return ""
		end

		-- If no argument is provided, default to 23
		local maxLength = tonumber(nameLen) or 22
		if #name <= maxLength then
			return strupper(name)
		else
			return MHCT.abbreviate(strupper(name), true, unit)
		end
	end
)

-- Player frame name with group number
MHCT.registerTag(
	"mh-player:frame:name:caps-groupnumber",
	NAME_SUBCATEGORY,
	"Shows unit name in all CAPS with a dynamic # of characters + unit group number if in raid (dynamic number within {} of tag)",
	"UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE",
	function(unit, _, args)
		local name = UnitName(unit) or ""
		local cname = strupper(name)
		local length = tonumber(args) or DEFAULT_TEXT_LENGTH
		local formatted = E:ShortenString(cname, length)

		if IsInRaid() then
			local name, realm = UnitName(unit)
			if name then
				local nameRealm = (realm and realm ~= "" and format("%s-%s", name, realm)) or name
				for i = 1, GetNumGroupMembers() do
					local raidName, _, group = GetRaidRosterInfo(i)
					if raidName == nameRealm then
						formatted = format("%s |cff00FFFF(%s)|r", formatted, group)
					end
				end
			end
		end

		return formatted
	end
)
