if not C_AddOns.IsAddOnLoaded("ElvUI") then
	return
end
local MHCT = MHCT
local E, L = unpack(ElvUI)

--------------------------------------
-- LOCALS
--------------------------------------
local tonumber, print, format, strupper, floor = tonumber, print, format, strupper, math.floor
local UnitName = UnitName
local GetRaidRosterInfo = GetRaidRosterInfo
local GetNumGroupMembers = GetNumGroupMembers
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsConnected = UnitIsConnected
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitEffectiveLevel = UnitEffectiveLevel
local IsInRaid = IsInRaid
local UnitPowerType = UnitPowerType

--------------------------------------
-- TAGS
-- NOTE: (from ElvUI) third arg here is added from the user as like [name:health{ff00ff:00ff00}] or [name:health{class:00ff00}]
--------------------------------------

E:AddTagInfo(
	"mh-health:current:percent:left",
	MHCT.TAG_CATEGORY_NAME,
	"Shows current + percent health at all times similar to following example: 85% | 100k"
)
E:AddTag(
	"mh-health:current:percent:left",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		local currentPercent = (currentHp / maxHp) * 100
		return format("%.1f%% | %s", currentPercent, E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true))
	end
)

E:AddTagInfo(
	"mh-health:current:percent:right",
	MHCT.TAG_CATEGORY_NAME,
	"Shows current + percent health at all times similar to following example: 100k | 85%"
)
E:AddTag(
	"mh-health:current:percent:right",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		local currentPercent = (currentHp / maxHp) * 100
		return format("%s | %.1f%%", E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true), currentPercent)
	end
)

E:AddTagInfo(
	"mh-health:current:percent:right-hidefull",
	MHCT.TAG_CATEGORY_NAME,
	"Hides percent at full health else shows at all times similar to following example: 100k | 85%"
)
E:AddTag(
	"mh-health:current:percent:right-hidefull",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)

		if maxHp ~= currentHp then
			local currentPercent = (currentHp / maxHp) * 100
			return format("%s | %.1f%%", E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true), currentPercent)
		else
			return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		end
	end
)

E:AddTagInfo(
	"mh-health:current:percent:left-hidefull",
	MHCT.TAG_CATEGORY_NAME,
	"Hides percent at full health else shows at all times similar to following example: 85% |100k"
)
E:AddTag(
	"mh-health:current:percent:left-hidefull",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)

		if maxHp ~= currentHp then
			local currentPercent = (currentHp / maxHp) * 100
			return format("%.1f%% | %s", currentPercent, E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true))
		else
			return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		end
	end
)

E:AddTagInfo(
	"mh-health:absorb:current:percent:right",
	MHCT.TAG_CATEGORY_NAME,
	"Hides percent at full health else shows absorb, current, and percent to following example: (**absorb amount**) 100k | 85%"
)
E:AddTag(
	"mh-health:absorb:current:percent:right",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		local returnString = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		if maxHp ~= currentHp then
			local currentPercent = (currentHp / maxHp) * 100
			returnString = format("%s | %.1f%%", returnString, currentPercent)
		end

		local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount ~= 0 then
			return format("|cff%s(%s)|r %s", MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount), returnString)
		end

		return returnString
	end
)

E:AddTagInfo(
	"mh-health:simple:percent",
	MHCT.TAG_CATEGORY_NAME,
	"Shows max hp at full or percent with dynamic # of decimals (dynamic number within {} of tag) - Example: [mh-health:simple:percent{2}] will show percent to 2 decimal places"
)
E:AddTag("mh-health:simple:percent", "PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH", function(unit, _, args)
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	return MHCT.formatHealthPercent(unit, args, true)
end)

E:AddTagInfo(
	"mh-health:simple:percent-nosign",
	MHCT.TAG_CATEGORY_NAME,
	"Shows max hp at full or percent (with no % sign) with dynamic # of decimals (dynamic number within {} of tag) - [Example: mh-health:simple:percent{2}] will show percent to 2 decimal places"
)
E:AddTag("mh-health:simple:percent-nosign", "PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH", function(unit, _, args)
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	return MHCT.formatHealthPercent(unit, args, false)
end)

E:AddTagInfo(
	"mh-health:simple:percent-nosign-v2",
	MHCT.TAG_CATEGORY_NAME,
	"Hidden at max hp at full or percent (with no % sign) with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places"
)
E:AddTag(
	"mh-health:simple:percent-nosign-v2",
	"PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		if currentHp ~= maxHp then
			local decimalPlaces = tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
			local formatDecimal = format("%%.%sf", decimalPlaces)
			return format(formatDecimal, (currentHp / maxHp) * 100)
		end

		return ""
	end
)

E:AddTagInfo(
	"mh-health:simple:percent-v2",
	MHCT.TAG_CATEGORY_NAME,
	"Hidden at max hp at full or percent + % sign with dynamic # of decimals (dynamic number within {} of tag) - Example: [mh-health:simple:percent{2}] will show percent to 2 decimal places"
)
E:AddTag(
	"mh-health:simple:percent-v2",
	"PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		if currentHp ~= maxHp then
			local decimalPlaces = tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
			local formatDecimal = format("%%.%sf%%%%", decimalPlaces)
			return format(formatDecimal, (currentHp / maxHp) * 100)
		end

		return ""
	end
)

E:AddTagInfo(
	"mh-dynamic:name:caps-statusicon",
	MHCT.TAG_CATEGORY_NAME,
	"Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag) - Example: [mh-dynamic:name:caps-statusicon{20}] will show name up to 20 characters"
)
E:AddTag(
	"mh-dynamic:name:caps-statusicon",
	"UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_HEALTH INSTANCE_ENCOUNTER_ENGAGE_UNIT",
	function(unit, _, args)
		local name = UnitName(unit) or ""
		if not name then
			return
		end

		local cname = strupper(name)
		local length = tonumber(args) or MHCT.DEFAULT_TEXT_LENGTH
		local formatted = ""

		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			formatted = statusFormatted
		else
			formatted = E:ShortenString(cname, length)
		end

		return formatted
	end
)

E:AddTagInfo(
	"mh-dynamic:name:caps",
	MHCT.TAG_CATEGORY_NAME,
	"Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag - see examples above)"
)
E:AddTag("mh-dynamic:name:caps", "UNIT_NAME_UPDATE", function(unit, _, args)
	local name = UnitName(unit) or ""
	local cname = strupper(name)
	local length = tonumber(args) or MHCT.DEFAULT_TEXT_LENGTH
	return E:ShortenString(cname, length)
end)

E:AddTagInfo(
	"mh-name:caps:abbrev",
	MHCT.TAG_CATEGORY_NAME,
	"Name abbreviation/shortener - Example: 'Cleave Training Dummy' => 'C.T. Dummy'"
)
E:AddTag("mh-name:caps:abbrev", "UNIT_NAME_UPDATE", function(unit, _, args)
	local name = UnitName(unit)
	if name then
		return MHCT.abbreviate(strupper(name), false, unit)
	end
end)

E:AddTagInfo(
	"mh-name:caps:abbrev-reverse",
	MHCT.TAG_CATEGORY_NAME,
	"Name abbreviation/shortener - Example: 'Cleave Training Dummy' => 'Cleave T.D.'"
)
E:AddTag("mh-name:caps:abbrev-reverse", "UNIT_NAME_UPDATE", function(unit, _, args)
	local name = UnitName(unit)
	if name then
		return MHCT.abbreviate(strupper(name), true, unit)
	end
end)

E:AddTagInfo(
	"mh-name-caps-abbrev-V2",
	MHCT.TAG_CATEGORY_NAME,
	"Name abbreviation/shortener if greater than 25 characters - Example: 'Cleave Training Dummy' => 'C.T. Dummy'"
)
E:AddTag("mh-name-caps-abbrev-V2", "UNIT_NAME_UPDATE", function(unit, _, nameLen)
	local name = UnitName(unit)

	-- If no argument is provided, default to 25
	local maxLength = tonumber(nameLen) or 25
	if #name <= maxLength then
		return strupper(name)
	else
		return MHCT.abbreviate(strupper(name), false, unit)
	end
end)

E:AddTagInfo(
	"mh-name-caps-abbrev-reverse-V2",
	MHCT.TAG_CATEGORY_NAME,
	"Name abbreviation/shortener if greater than 25 characters - Example: 'Cleave Training Dummy' => 'Cleave T.D.'"
)
E:AddTag("mh-name-caps-abbrev-reverse-V2", "UNIT_NAME_UPDATE", function(unit)
	local name = UnitName(unit)

	-- If no argument is provided, default to 25
	local maxLength = tonumber(nameLen) or 25
	if #name <= maxLength then
		return strupper(name)
	else
		return MHCT.abbreviate(strupper(name), true, unit)
	end
end)

E:AddTagInfo(
	"mh-player:frame:name:caps-groupnumber",
	MHCT.TAG_CATEGORY_NAME,
	"Shows unit name in all CAPS with a dynamic # of characters + unit group number if in raid (dynamic number within {} of tag - see examples above)"
)
E:AddTag("mh-player:frame:name:caps-groupnumber", "UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE", function(unit, _, args)
	local name = UnitName(unit) or ""
	local cname = strupper(name)
	local length = tonumber(args) or MHCT.DEFAULT_TEXT_LENGTH
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

E:AddTagInfo(
	"mh-target:frame:power-percent",
	MHCT.TAG_CATEGORY_NAME,
	"Simple power percent, no percentage sign with dynamic number of decimals (dynamic number within {} of tag - see examples above)"
)
E:AddTag("mh-target:frame:power-percent", "UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER", function(unit, _, args)
	local powerType = UnitPowerType(unit)
	local currentPower = UnitPower(unit, powerType)
	local maxPower = UnitPowerMax(unit)
	if currentPower ~= 0 then
		local decimalPlaces = tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
		local formatDecimal = format("%%.%sf", decimalPlaces)
		return format(formatDecimal, (currentPower / maxPower) * 100)
	end

	return ""
end)

E:AddTagInfo(
	"mh-classification:icon",
	MHCT.TAG_CATEGORY_NAME,
	"Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites)"
)
E:AddTag("mh-classification:icon", "UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP", function(unit, _, args)
	local unitType = MHCT.classificationType(unit)
	local baseIconSize = tonumber(args) or MHCT.DEFAULT_ICON_SIZE

	if unitType and MHCT.ICON_MAP[unitType] then
		return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], baseIconSize)
	end

	return ""
end)

E:AddTagInfo(
	"mh-classification:icon-V2",
	MHCT.TAG_CATEGORY_NAME,
	"Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites) - NON Dynamic sizing"
)
E:AddTag("mh-classification:icon-V2", "UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
	local unitType = MHCT.classificationType(unit)
	local baseIconSize = MHCT.DEFAULT_ICON_SIZE

	if unitType and MHCT.ICON_MAP[unitType] then
		return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], baseIconSize)
	end

	return ""
end)

E:AddTagInfo(
	"mh-difficultycolor:level",
	MHCT.TAG_CATEGORY_NAME,
	"Traditional ElvUI difficulty color + level with more modern updates (will always show level)"
)
E:AddTag("mh-difficultycolor:level", "UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
	return MHCT.difficultyLevelFormatter(unit, UnitEffectiveLevel(unit))
end)

E:AddTagInfo(
	"mh-difficultycolor:level-hide",
	MHCT.TAG_CATEGORY_NAME,
	"Traditional ElvUI difficulty color + level with more modern updates (will always show level and only hide level when you reach max level and unit level is equal to player level)"
)
E:AddTag("mh-difficultycolor:level-hide", "UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
	local unitLevel = UnitEffectiveLevel(unit)
	local playerLevel = UnitEffectiveLevel("player")

	if playerLevel == unitLevel and playerLevel == MHCT.MAX_PLAYER_LEVEL then
		return ""
	end

	return MHCT.difficultyLevelFormatter(unit, unitLevel)
end)

E:AddTagInfo(
	"mh-deficit:num-status",
	MHCT.TAG_CATEGORY_NAME,
	"Shows deficit shortvalue number when less than 100% health and status + icon if dead/offline/ghost"
)
E:AddTag("mh-deficit:num-status", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
	return (currentHp == maxHp) and "" or format("-%s", E:ShortValue(maxHp - currentHp))
end)

E:AddTagInfo(
	"mh-deficit:num-nostatus",
	MHCT.TAG_CATEGORY_NAME,
	"Shows deficit shortvalue number when less than 100% health (no status)"
)
E:AddTag("mh-deficit:num-nostatus", "UNIT_HEALTH UNIT_MAXHEALTH", function(unit)
	local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
	return (currentHp == maxHp) and "" or format("-%s", E:ShortValue(maxHp - currentHp))
end)

E:AddTagInfo(
	"mh-deficit:percent-status",
	MHCT.TAG_CATEGORY_NAME,
	"Shows deficit percent with dynamic decimal when less than 100% health + status icon"
)
E:AddTag(
	"mh-deficit:percent-status",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local decimalPlaces = tonumber(args) or 1
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		local formatDecimal = format("-%%.%sf%%%%", decimalPlaces)
		return (currentHp == maxHp) and "" or format(formatDecimal, 100 - (currentHp / maxHp) * 100)
	end
)

E:AddTagInfo(
	"mh-deficit:percent-status-nosign",
	MHCT.TAG_CATEGORY_NAME,
	"Shows deficit percent with dynamic decimal when less than 100% health + status icon (does not include %)"
)
E:AddTag(
	"mh-deficit:percent-status-nosign",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local decimalPlaces = tonumber(args) or 1
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		local formatDecimal = format("-%%.%sf", decimalPlaces)
		return (currentHp == maxHp) and "" or format(formatDecimal, 100 - (currentHp / maxHp) * 100)
	end
)

E:AddTagInfo(
	"mh-deficit:percent-nostatus",
	MHCT.TAG_CATEGORY_NAME,
	"Shows deficit percent with dynamic decimal when less than 100% health (no status)"
)
E:AddTag("mh-deficit:percent-nostatus", "UNIT_HEALTH UNIT_MAXHEALTH", function(unit, _, args)
	local decimalPlaces = tonumber(args) or 1
	local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
	local formatDecimal = format("-%%.%sf%%%%", decimalPlaces)
	return (currentHp == maxHp) and "" or format(formatDecimal, 100 - (currentHp / maxHp) * 100)
end)

E:AddTagInfo(
	"mh-healthcolor",
	MHCT.TAG_CATEGORY_NAME,
	"Similar color tag to base ElvUI, but with brighter and high contrast gradient"
)
E:AddTag("mh-healthcolor", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
	if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
		return "|cffD6BFA6" -- Precomputed Hex for dead or disconnected units
	else
		-- Calculate health percentage and round to the nearest 0.5%
		local healthPercent = (UnitHealth(unit) / UnitHealthMax(unit)) * 100
		local roundedPercent = math.floor(healthPercent * 2 + 0.5) / 2

		-- Lookup the color in the precomputed table
		return MHCT.HEALTH_GRADIENT_RGB[roundedPercent] or "|cffFFFFFF" -- Fallback to white if not found
	end
end)

E:AddTagInfo(
	"mh-status",
	MHCT.TAG_CATEGORY_NAME,
	"Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (with their own icons)"
)
E:AddTag("mh-status", "UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
	return MHCT.formatWithStatusCheck(unit)
end)

E:AddTagInfo(
	"mh-status-noicon",
	MHCT.TAG_CATEGORY_NAME,
	"Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (NO icon, text only)"
)
E:AddTag("mh-status-noicon", "UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
	local status = MHCT.statusCheck(unit)
	if status then
		return format("|cffD6BFA6%s|r", strupper(status))
	end
end)

E:AddTagInfo("mh-absorb", MHCT.TAG_CATEGORY_NAME, "Simple absorb tag in parentheses (with yellow text color)")
E:AddTag("mh-absorb", "UNIT_ABSORB_AMOUNT_CHANGED", function(unit)
	local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
	if absorbAmount ~= 0 then
		return format("|cff%s(%s)|r", MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
	end
end)

E:AddTagInfo(
	"mh-smartlevel",
	MHCT.TAG_CATEGORY_NAME,
	"Simple tag to show all unit levels if player is not max level. If max level, will show level of all non max level units"
)
E:AddTag("mh-smartlevel", "UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
	local unitLevel = UnitEffectiveLevel(unit)
	local playerLevel = UnitEffectiveLevel("player")

	-- if player is NOT max level, show level
	if playerLevel ~= MHCT.MAX_PLAYER_LEVEL then
		return unitLevel
	else
		-- else only show unit level if unit is NOT max level
		return MHCT.MAX_PLAYER_LEVEL == unitLevel and "" or unitLevel
	end
end)
