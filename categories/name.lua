-- ===================================================================================
-- NAME RELATED TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references directly
local E, L = unpack(ElvUI)

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
local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [name]"
local DEFAULT_TEXT_LENGTH = MHCT.DEFAULT_TEXT_LENGTH

-- ===================================================================================
-- NAME RELATED TAGS
-- ===================================================================================
do
	-- Name in CAPS with configurable length
	E:AddTagInfo(
		"mh-dynamic:name:caps",
		thisCategory,
		"Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag"
	)
	E:AddTag("mh-dynamic:name:caps", "UNIT_NAME_UPDATE", function(unit, _, args)
		local name = UnitName(unit) or ""
		local cname = strupper(name)
		local length = tonumber(args) or DEFAULT_TEXT_LENGTH
		return E:ShortenString(cname, length)
	end)

	-- Name abbreviation - C.T. Dummy format
	E:AddTagInfo(
		"mh-name:caps:abbrev",
		thisCategory,
		"Name abbreviation/shortener - Example: 'Cleave Training Dummy' => 'C.T. Dummy'"
	)
	E:AddTag("mh-name:caps:abbrev", "UNIT_NAME_UPDATE", function(unit)
		local name = UnitName(unit)
		if name then
			return MHCT.abbreviate(strupper(name), false, unit)
		end
	end)

	-- Name abbreviation reversed - Cleave T.D. format
	E:AddTagInfo(
		"mh-name:caps:abbrev-reverse",
		thisCategory,
		"Name abbreviation/shortener - Example: 'Cleave Training Dummy' => 'Cleave T.D.'"
	)
	E:AddTag("mh-name:caps:abbrev-reverse", "UNIT_NAME_UPDATE", function(unit)
		local name = UnitName(unit)
		if name then
			return MHCT.abbreviate(strupper(name), true, unit)
		end
	end)

	-- Name with status icon
	E:AddTagInfo(
		"mh-dynamic:name:caps-statusicon",
		thisCategory,
		"Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag) - Example: [mh-dynamic:name:caps-statusicon{20}] will show name up to 20 characters"
	)
	E:AddTag(
		"mh-dynamic:name:caps-statusicon",
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
	E:AddTagInfo(
		"mh-name-caps-abbrev-V2",
		thisCategory,
		"Name abbreviation/shortener if greater than 25 characters - Example: 'Cleave Training Dummy' => 'C.T. Dummy'"
	)
	E:AddTag("mh-name-caps-abbrev-V2", "UNIT_NAME_UPDATE", function(unit, _, nameLen)
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
	end)

	-- V2 Name abbrev reversed
	E:AddTagInfo(
		"mh-name-caps-abbrev-reverse-V2",
		thisCategory,
		"Name abbreviation/shortener if greater than 25 characters - Example: 'Cleave Training Dummy' => 'Cleave T.D.'"
	)
	E:AddTag("mh-name-caps-abbrev-reverse-V2", "UNIT_NAME_UPDATE", function(unit, _, nameLen)
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
	end)

	-- Player frame name with group number
	E:AddTagInfo(
		"mh-player:frame:name:caps-groupnumber",
		thisCategory,
		"Shows unit name in all CAPS with a dynamic # of characters + unit group number if in raid (dynamic number within {} of tag)"
	)
	E:AddTag("mh-player:frame:name:caps-groupnumber", "UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE", function(unit, _, args)
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
	end)
end
