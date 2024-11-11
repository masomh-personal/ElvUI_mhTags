local _, ns = ...
local MHCT = ns.MHCT

local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [name]"

-- ===================================================================================
-- LEVEL
-- ===================================================================================
do
	MHCT.E:AddTagInfo(
		"mh-dynamic:name:caps",
		thisCategory,
		"Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag"
	)
	MHCT.E:AddTag("mh-dynamic:name:caps", "UNIT_NAME_UPDATE", function(unit, _, args)
		local name = MHCT.UnitName(unit) or ""
		local cname = MHCT.strupper(name)
		local length = MHCT.tonumber(args) or MHCT.DEFAULT_TEXT_LENGTH
		return MHCT.E:ShortenString(cname, length)
	end)

	MHCT.E:AddTagInfo(
		"mh-name:caps:abbrev",
		thisCategory,
		"Name abbreviation/shortener - Example: 'Cleave Training Dummy' => 'C.T. Dummy'"
	)
	MHCT.E:AddTag("mh-name:caps:abbrev", "UNIT_NAME_UPDATE", function(unit, _, args)
		local name = MHCT.UnitName(unit)
		if name then
			return MHCT.abbreviate(MHCT.strupper(name), false, unit)
		end
	end)

	MHCT.E:AddTagInfo(
		"mh-name:caps:abbrev-reverse",
		thisCategory,
		"Name abbreviation/shortener - Example: 'Cleave Training Dummy' => 'Cleave T.D.'"
	)
	MHCT.E:AddTag("mh-name:caps:abbrev-reverse", "UNIT_NAME_UPDATE", function(unit, _, args)
		local name = MHCT.UnitName(unit)
		if name then
			return MHCT.abbreviate(MHCT.strupper(name), true, unit)
		end
	end)

	MHCT.E:AddTagInfo(
		"mh-dynamic:name:caps-statusicon",
		thisCategory,
		"Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag) - Example: [mh-dynamic:name:caps-statusicon{20}] will show name up to 20 characters"
	)
	MHCT.E:AddTag(
		"mh-dynamic:name:caps-statusicon",
		"UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_HEALTH INSTANCE_ENCOUNTER_ENGAGE_UNIT",
		function(unit, _, args)
			local name = MHCT.UnitName(unit) or ""
			if not name then
				return
			end

			local cname = MHCT.strupper(name)
			local length = MHCT.tonumber(args) or MHCT.DEFAULT_TEXT_LENGTH
			local formatted = ""

			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				formatted = statusFormatted
			else
				formatted = MHCT.E:ShortenString(cname, length)
			end

			return formatted
		end
	)

	MHCT.E:AddTagInfo(
		"mh-name-caps-abbrev-V2",
		thisCategory,
		"Name abbreviation/shortener if greater than 25 characters - Example: 'Cleave Training Dummy' => 'C.T. Dummy'"
	)
	MHCT.E:AddTag("mh-name-caps-abbrev-V2", "UNIT_NAME_UPDATE", function(unit, _, nameLen)
		local name = MHCT.UnitName(unit)

		-- If no argument is provided, default to 25
		local maxLength = MHCT.tonumber(nameLen) or 25
		if #name <= maxLength then
			return MHCT.strupper(name)
		else
			return MHCT.abbreviate(MHCT.strupper(name), false, unit)
		end
	end)

	MHCT.E:AddTagInfo(
		"mh-name-caps-abbrev-reverse-V2",
		thisCategory,
		"Name abbreviation/shortener if greater than 25 characters - Example: 'Cleave Training Dummy' => 'Cleave T.D.'"
	)
	MHCT.E:AddTag("mh-name-caps-abbrev-reverse-V2", "UNIT_NAME_UPDATE", function(unit, _, nameLen)
		local name = MHCT.UnitName(unit)

		-- If no argument is provided, default to 25
		local maxLength = MHCT.tonumber(nameLen) or 25
		if #name <= maxLength then
			return MHCT.strupper(name)
		else
			return MHCT.abbreviate(MHCT.strupper(name), true, unit)
		end
	end)

	MHCT.E:AddTagInfo(
		"mh-player:frame:name:caps-groupnumber",
		thisCategory,
		"Shows unit name in all CAPS with a dynamic # of characters + unit group number if in raid (dynamic number within {} of tag)"
	)
	MHCT.E:AddTag(
		"mh-player:frame:name:caps-groupnumber",
		"UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE",
		function(unit, _, args)
			local name = MHCT.UnitName(unit) or ""
			local cname = MHCT.strupper(name)
			local length = MHCT.tonumber(args) or MHCT.DEFAULT_TEXT_LENGTH
			local formatted = MHCT.E:ShortenString(cname, length)

			if MHCT.IsInRaid() then
				local name, realm = MHCT.UnitName(unit)
				if name then
					local nameRealm = (realm and realm ~= "" and MHCT.format("%s-%s", name, realm)) or name
					for i = 1, MHCT.GetNumGroupMembers() do
						local raidName, _, group = MHCT.GetRaidRosterInfo(i)
						if raidName == nameRealm then
							formatted = MHCT.format("%s |cff00FFFF(%s)|r", formatted, group)
						end
					end
				end
			end

			return formatted
		end
	)
end
