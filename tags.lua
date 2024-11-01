if not C_AddOns.IsAddOnLoaded("ElvUI") then
	return
end

-- Get addon private environment (to not pollute Global)
local _, ns = ...
local MHCT = ns.MHCT

--------------------------------------
-- TAGS
--------------------------------------
MHCT.E:AddTagInfo(
	"mh-health:current:percent:left",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Shows current + percent health at all times similar to following example: 85% | 100k"
)
MHCT.E:AddTag(
	"mh-health:current:percent:left",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = MHCT.UnitHealthMax(unit)
		local currentHp = MHCT.UnitHealth(unit)
		local currentPercent = (currentHp / maxHp) * 100
		return MHCT.format(
			"%.1f%% | %s",
			currentPercent,
			MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		)
	end
)

MHCT.E:AddTagInfo(
	"mh-health:current:percent:right",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Shows current + percent health at all times similar to following example: 100k | 85%"
)
MHCT.E:AddTag(
	"mh-health:current:percent:right",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = MHCT.UnitHealthMax(unit)
		local currentHp = MHCT.UnitHealth(unit)
		local currentPercent = (currentHp / maxHp) * 100
		return MHCT.format(
			"%s | %.1f%%",
			MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true),
			currentPercent
		)
	end
)

MHCT.E:AddTagInfo(
	"mh-health:current:percent:right-hidefull",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Hides percent at full health else shows at all times similar to following example: 100k | 85%"
)
MHCT.E:AddTag(
	"mh-health:current:percent:right-hidefull",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = MHCT.UnitHealthMax(unit)
		local currentHp = MHCT.UnitHealth(unit)

		if maxHp ~= currentHp then
			local currentPercent = (currentHp / maxHp) * 100
			return MHCT.format(
				"%s | %.1f%%",
				MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true),
				currentPercent
			)
		else
			return MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		end
	end
)

MHCT.E:AddTagInfo(
	"mh-health:current:percent:left-hidefull",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Hides percent at full health else shows at all times similar to following example: 85% |100k"
)
MHCT.E:AddTag(
	"mh-health:current:percent:left-hidefull",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = MHCT.UnitHealthMax(unit)
		local currentHp = MHCT.UnitHealth(unit)

		if maxHp ~= currentHp then
			local currentPercent = (currentHp / maxHp) * 100
			return MHCT.format(
				"%.1f%% | %s",
				currentPercent,
				MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
			)
		else
			return MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		end
	end
)

MHCT.E:AddTagInfo(
	"mh-health:absorb:current:percent:right",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Hides percent at full health else shows absorb, current, and percent to following example: (**absorb amount**) 100k | 85%"
)
MHCT.E:AddTag(
	"mh-health:absorb:current:percent:right",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = MHCT.UnitHealthMax(unit)
		local currentHp = MHCT.UnitHealth(unit)
		local returnString = MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		if maxHp ~= currentHp then
			local currentPercent = (currentHp / maxHp) * 100
			returnString = MHCT.format("%s | %.1f%%", returnString, currentPercent)
		end

		local absorbAmount = MHCT.UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount ~= 0 then
			return MHCT.format("|cff%s(%s)|r %s", MHCT.ABSORB_TEXT_COLOR, MHCT.E:ShortValue(absorbAmount), returnString)
		end

		return returnString
	end
)

MHCT.E:AddTagInfo(
	"mh-health:simple:percent",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Shows max hp at full or percent with dynamic # of decimals (dynamic number within {} of tag) - Example: [mh-health:simple:percent{2}] will show percent to 2 decimal places"
)
MHCT.E:AddTag("mh-health:simple:percent", "PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH", function(unit, _, args)
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	return MHCT.formatHealthPercent(unit, args, true)
end)

MHCT.E:AddTagInfo(
	"mh-health:simple:percent-nosign",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Shows max hp at full or percent (with no % sign) with dynamic # of decimals (dynamic number within {} of tag) - [Example: mh-health:simple:percent{2}] will show percent to 2 decimal places"
)
MHCT.E:AddTag(
	"mh-health:simple:percent-nosign",
	"PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthPercent(unit, args, false)
	end
)

MHCT.E:AddTagInfo(
	"mh-health:simple:percent-nosign-v2",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Hidden at max hp at full or percent (with no % sign) with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places"
)
MHCT.E:AddTag(
	"mh-health:simple:percent-nosign-v2",
	"PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = MHCT.UnitHealthMax(unit)
		local currentHp = MHCT.UnitHealth(unit)
		if currentHp ~= maxHp then
			local decimalPlaces = MHCT.tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
			local formatDecimal = MHCT.format("%%.%sf", decimalPlaces)
			return MHCT.format(formatDecimal, (currentHp / maxHp) * 100)
		end

		return ""
	end
)

MHCT.E:AddTagInfo(
	"mh-health:simple:percent-v2",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Hidden at max hp at full or percent + % sign with dynamic # of decimals (dynamic number within {} of tag) - Example: [mh-health:simple:percent{2}] will show percent to 2 decimal places"
)
MHCT.E:AddTag(
	"mh-health:simple:percent-v2",
	"PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = MHCT.UnitHealthMax(unit)
		local currentHp = MHCT.UnitHealth(unit)
		if currentHp ~= maxHp then
			local decimalPlaces = MHCT.tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
			local formatDecimal = MHCT.format("%%.%sf%%%%", decimalPlaces)
			return MHCT.format(formatDecimal, (currentHp / maxHp) * 100)
		end

		return ""
	end
)

MHCT.E:AddTagInfo(
	"mh-dynamic:name:caps-statusicon",
	MHCT.TAG_CATEGORY_NAME .. " [name]",
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
	"mh-dynamic:name:caps",
	MHCT.TAG_CATEGORY_NAME .. " [name]",
	"Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag - see examples above)"
)
MHCT.E:AddTag("mh-dynamic:name:caps", "UNIT_NAME_UPDATE", function(unit, _, args)
	local name = MHCT.UnitName(unit) or ""
	local cname = MHCT.strupper(name)
	local length = MHCT.tonumber(args) or MHCT.DEFAULT_TEXT_LENGTH
	return MHCT.E:ShortenString(cname, length)
end)

MHCT.E:AddTagInfo(
	"mh-name:caps:abbrev",
	MHCT.TAG_CATEGORY_NAME .. " [name]",
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
	MHCT.TAG_CATEGORY_NAME .. " [name]",
	"Name abbreviation/shortener - Example: 'Cleave Training Dummy' => 'Cleave T.D.'"
)
MHCT.E:AddTag("mh-name:caps:abbrev-reverse", "UNIT_NAME_UPDATE", function(unit, _, args)
	local name = MHCT.UnitName(unit)
	if name then
		return MHCT.abbreviate(MHCT.strupper(name), true, unit)
	end
end)

MHCT.E:AddTagInfo(
	"mh-name-caps-abbrev-V2",
	MHCT.TAG_CATEGORY_NAME .. " [name]",
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
	MHCT.TAG_CATEGORY_NAME .. " [name]",
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
	MHCT.TAG_CATEGORY_NAME .. " [name]",
	"Shows unit name in all CAPS with a dynamic # of characters + unit group number if in raid (dynamic number within {} of tag - see examples above)"
)
MHCT.E:AddTag("mh-player:frame:name:caps-groupnumber", "UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE", function(unit, _, args)
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
end)

MHCT.E:AddTagInfo(
	"mh-target:frame:power-percent",
	MHCT.TAG_CATEGORY_NAME .. " [power]",
	"Simple power percent, no percentage sign with dynamic number of decimals (dynamic number within {} of tag - see examples above)"
)
MHCT.E:AddTag(
	"mh-target:frame:power-percent",
	"UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER",
	function(unit, _, args)
		local powerType = MHCT.UnitPowerType(unit)
		local currentPower = UnitPower(unit, powerType)
		local maxPower = UnitPowerMax(unit)
		if currentPower ~= 0 then
			local decimalPlaces = MHCT.tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
			local formatDecimal = MHCT.format("%%.%sf", decimalPlaces)
			return MHCT.format(formatDecimal, (currentPower / maxPower) * 100)
		end

		return ""
	end
)

MHCT.E:AddTagInfo(
	"mh-classification:icon",
	MHCT.TAG_CATEGORY_NAME .. " [classification]",
	"Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites)"
)
MHCT.E:AddTag("mh-classification:icon", "UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP", function(unit, _, args)
	local unitType = MHCT.classificationType(unit)
	local baseIconSize = MHCT.tonumber(args) or MHCT.DEFAULT_ICON_SIZE

	if unitType and MHCT.ICON_MAP[unitType] then
		return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], baseIconSize)
	end

	return ""
end)

MHCT.E:AddTagInfo(
	"mh-classification:icon-V2",
	MHCT.TAG_CATEGORY_NAME .. " [classification]",
	"Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites) - NON Dynamic sizing"
)
MHCT.E:AddTag("mh-classification:icon-V2", "UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
	local unitType = MHCT.classificationType(unit)
	local baseIconSize = MHCT.DEFAULT_ICON_SIZE

	if unitType and MHCT.ICON_MAP[unitType] then
		return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], baseIconSize)
	end

	return ""
end)

MHCT.E:AddTagInfo(
	"mh-difficultycolor:level",
	MHCT.TAG_CATEGORY_NAME .. " [misc]",
	"Traditional ElvUI difficulty color + level with more modern updates (will always show level)"
)
MHCT.E:AddTag("mh-difficultycolor:level", "UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
	return MHCT.difficultyLevelFormatter(unit, MHCT.UnitEffectiveLevel(unit))
end)

MHCT.E:AddTagInfo(
	"mh-difficultycolor:level-hide",
	MHCT.TAG_CATEGORY_NAME .. " [misc]",
	"Traditional ElvUI difficulty color + level with more modern updates (will always show level and only hide level when you reach max level and unit level is equal to player level)"
)
MHCT.E:AddTag("mh-difficultycolor:level-hide", "UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
	local unitLevel = MHCT.UnitEffectiveLevel(unit)
	local playerLevel = MHCT.UnitEffectiveLevel("player")

	if playerLevel == unitLevel and playerLevel == MHCT.MAX_PLAYER_LEVEL then
		return ""
	end

	return MHCT.difficultyLevelFormatter(unit, unitLevel)
end)

MHCT.E:AddTagInfo(
	"mh-deficit:num-status",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Shows deficit shortvalue number when less than 100% health and status + icon if dead/offline/ghost"
)
MHCT.E:AddTag("mh-deficit:num-status", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	local currentHp, maxHp = MHCT.UnitHealth(unit), MHCT.UnitHealthMax(unit)
	return (currentHp == maxHp) and "" or MHCT.format("-%s", MHCT.E:ShortValue(maxHp - currentHp))
end)

MHCT.E:AddTagInfo(
	"mh-deficit:num-nostatus",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Shows deficit shortvalue number when less than 100% health (no status)"
)
MHCT.E:AddTag("mh-deficit:num-nostatus", "UNIT_HEALTH UNIT_MAXHEALTH", function(unit)
	local currentHp, maxHp = MHCT.UnitHealth(unit), MHCT.UnitHealthMax(unit)
	return (currentHp == maxHp) and "" or MHCT.format("-%s", MHCT.E:ShortValue(maxHp - currentHp))
end)

MHCT.E:AddTagInfo(
	"mh-deficit:percent-status",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Shows deficit percent with dynamic decimal when less than 100% health + status icon"
)
MHCT.E:AddTag(
	"mh-deficit:percent-status",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local decimalPlaces = MHCT.tonumber(args) or 1
		local currentHp, maxHp = MHCT.UnitHealth(unit), MHCT.UnitHealthMax(unit)
		local formatDecimal = MHCT.format("-%%.%sf%%%%", decimalPlaces)
		return (currentHp == maxHp) and "" or MHCT.format(formatDecimal, 100 - (currentHp / maxHp) * 100)
	end
)

MHCT.E:AddTagInfo(
	"mh-deficit:percent-status-nosign",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Shows deficit percent with dynamic decimal when less than 100% health + status icon (does not include %)"
)
MHCT.E:AddTag(
	"mh-deficit:percent-status-nosign",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local decimalPlaces = MHCT.tonumber(args) or 1
		local currentHp, maxHp = MHCT.UnitHealth(unit), MHCT.UnitHealthMax(unit)
		local formatDecimal = MHCT.format("-%%.%sf", decimalPlaces)
		return (currentHp == maxHp) and "" or MHCT.format(formatDecimal, 100 - (currentHp / maxHp) * 100)
	end
)

MHCT.E:AddTagInfo(
	"mh-deficit:percent-nostatus",
	MHCT.TAG_CATEGORY_NAME .. " [health]",
	"Shows deficit percent with dynamic decimal when less than 100% health (no status)"
)
MHCT.E:AddTag("mh-deficit:percent-nostatus", "UNIT_HEALTH UNIT_MAXHEALTH", function(unit, _, args)
	local decimalPlaces = MHCT.tonumber(args) or 1
	local currentHp, maxHp = MHCT.UnitHealth(unit), MHCT.UnitHealthMax(unit)
	local formatDecimal = MHCT.format("-%%.%sf%%%%", decimalPlaces)
	return (currentHp == maxHp) and "" or MHCT.format(formatDecimal, 100 - (currentHp / maxHp) * 100)
end)

MHCT.E:AddTagInfo(
	"mh-healthcolor",
	MHCT.TAG_CATEGORY_NAME .. " [misc]",
	"Similar color tag to base ElvUI, but with brighter and high contrast gradient"
)
MHCT.E:AddTag("mh-healthcolor", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
	if UnitIsDeadOrGhost(unit) or not MHCT.UnitIsConnected(unit) then
		return "|cffD6BFA6" -- Precomputed Hex for dead or disconnected units
	else
		-- Calculate health percentage and round to the nearest 0.5%
		local healthPercent = (MHCT.UnitHealth(unit) / MHCT.UnitHealthMax(unit)) * 100
		local roundedPercent = MHCT.floor(healthPercent * 2 + 0.5) / 2

		-- Lookup the color in the precomputed table
		return MHCT.HEALTH_GRADIENT_RGB[roundedPercent] or "|cffFFFFFF" -- Fallback to white if not found
	end
end)

MHCT.E:AddTagInfo(
	"mh-status",
	MHCT.TAG_CATEGORY_NAME .. " [misc]",
	"Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (with their own icons)"
)
MHCT.E:AddTag("mh-status", "UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
	return MHCT.formatWithStatusCheck(unit)
end)

MHCT.E:AddTagInfo(
	"mh-status-noicon",
	MHCT.TAG_CATEGORY_NAME .. " [misc]",
	"Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (NO icon, text only)"
)
MHCT.E:AddTag("mh-status-noicon", "UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
	local status = MHCT.statusCheck(unit)
	if status then
		return MHCT.format("|cffD6BFA6%s|r", MHCT.strupper(status))
	end
end)

MHCT.E:AddTagInfo(
	"mh-absorb",
	MHCT.TAG_CATEGORY_NAME .. " [misc]",
	"Simple absorb tag in parentheses (with yellow text color)"
)
MHCT.E:AddTag("mh-absorb", "UNIT_ABSORB_AMOUNT_CHANGED", function(unit)
	local absorbAmount = MHCT.UnitGetTotalAbsorbs(unit) or 0
	if absorbAmount ~= 0 then
		return MHCT.format("|cff%s(%s)|r", MHCT.ABSORB_TEXT_COLOR, MHCT.E:ShortValue(absorbAmount))
	end
end)

MHCT.E:AddTagInfo(
	"mh-smartlevel",
	MHCT.TAG_CATEGORY_NAME .. " [misc]",
	"Simple tag to show all unit levels if player is not max level. If max level, will show level of all non max level units"
)
MHCT.E:AddTag("mh-smartlevel", "UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
	local unitLevel = MHCT.UnitEffectiveLevel(unit)
	local playerLevel = MHCT.UnitEffectiveLevel("player")

	-- if player is NOT max level, show level
	if playerLevel ~= MHCT.MAX_PLAYER_LEVEL then
		return unitLevel
	else
		-- else only show unit level if unit is NOT max level
		return MHCT.MAX_PLAYER_LEVEL == unitLevel and "" or unitLevel
	end
end)
