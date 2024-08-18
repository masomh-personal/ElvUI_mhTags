if not C_AddOns.IsAddOnLoaded('ElvUI') then return end
local MHCT = MHCT
local E, L = unpack(ElvUI)
local ElvUF = E.oUF

--------------------------------------
-- LOCALS
--------------------------------------
local tonumber, print, format, strupper = tonumber, print, format, strupper
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
-- HEALTH RELATED TAGS
--------------------------------------
E:AddTagInfo("mh-health:current:percent:left", MHCT.TAG_CATEGORY_NAME, "Shows current + percent health at all times similar to following example: 85% | 100k")
E:AddTag('mh-health:current:percent:left', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit)
	local status = MHCT.statusCheck(unit)
	
	if (status) then
		return MHCT.statusFormatter(status)
	else
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		local currentPercent = (currentHp/maxHp)*100
		return format("%.1f%% | %s", currentPercent, E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true))
	end
end)

--
E:AddTagInfo("mh-health:current:percent:right", MHCT.TAG_CATEGORY_NAME, "Shows current + percent health at all times similar to following example: 100k | 85%")
E:AddTag('mh-health:current:percent:right', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit)
	local status = MHCT.statusCheck(unit)
	
	if (status) then
		return MHCT.statusFormatter(status)
	else
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		local currentPercent = (currentHp/maxHp)*100
		return format("%s | %.1f%%", E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true), currentPercent)
	end
end)

-- HEALTH: show percent on right of | and current HP on left, but only if not at 100%
E:AddTagInfo("mh-health:current:percent:right-hidefull", MHCT.TAG_CATEGORY_NAME, "Hides percent at full health else shows at all times similar to following example: 100k | 85%")
E:AddTag('mh-health:current:percent:right-hidefull', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit)
	local status = MHCT.statusCheck(unit)
	
	if (status) then
		return MHCT.statusFormatter(status)
	else
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)

		if maxHp ~= currentHp then
			local currentPercent = (currentHp/maxHp)*100
			return format("%s | %.1f%%", E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true), currentPercent)		
		else
			return E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true)
		end
	end
end)

-- PLAYER frame: to show health in custom format + show absorb amount if applicable
E:AddTagInfo("mh-health:absorb:current:percent:right", MHCT.TAG_CATEGORY_NAME, "Hides percent at full health else shows absorb, current, and percent to following example: (**absorb amount**) 100k | 85%")
E:AddTag('mh-health:absorb:current:percent:right', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_ABSORB_AMOUNT_CHANGED', function(unit)
	local status = MHCT.statusCheck(unit)
	
	if (status) then
		return MHCT.statusFormatter(status)
	else
		local returnString = ''
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)		

		if maxHp ~= currentHp then
			local currentPercent = (currentHp/maxHp)*100
			returnString = format("%s | %.1f%%", E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true), currentPercent)		
		else
			returnString = E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true)
		end

		local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount ~= 0 then
			returnString = format("|cff%s(%s)|r %s", MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount), returnString)
		end

		return returnString
	end
end)

-- Use dynamic argument to add decimal places
E:AddTagInfo("mh-health:simple:percent", MHCT.TAG_CATEGORY_NAME, "Shows max hp at full or percent with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places")
E:AddTag('mh-health:simple:percent', 'PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH', function(unit, _, args)
	local status = MHCT.statusCheck(unit)
	if (status) then
		return MHCT.statusFormatter(status)
	end
	
  local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)	
	if currentHp == maxHp then
		return E:GetFormattedText('CURRENT', maxHp, currentHp, nil, true)
	else
    local decimalPlaces = tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
    local formatDecimal = format('%%.%sf%%%%', decimalPlaces) -- NOTE: lots of escapes for percentage sign
		return format(formatDecimal, (currentHp/maxHp)*100)
	end
end)

-- Use dynamic argument to add decimal places (no % sign, same as above)
E:AddTagInfo("mh-health:simple:percent-nosign", MHCT.TAG_CATEGORY_NAME, "Shows max hp at full or percent (with  no % sign) with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places")
E:AddTag('mh-health:simple:percent-nosign', 'PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH', function(unit, _, args)
	local status = MHCT.statusCheck(unit)
	if (status) then
		return MHCT.statusFormatter(status)
	end
	
  local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)	
	if currentHp == maxHp then
		return E:GetFormattedText('CURRENT', maxHp, currentHp, nil, true)
	else
    local decimalPlaces = tonumber(args) or 0
    local formatDecimal = format('%%.%sf', decimalPlaces)
		return format(formatDecimal, (currentHp/maxHp)*100)
	end
end)

-- Use dynamic argument to add decimal places (no % sign, same as above + Hidden at full health)
E:AddTagInfo("mh-health:simple:percent-nosign-v2", MHCT.TAG_CATEGORY_NAME, "Hidden at max hp at full or percent (with  no % sign) with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places")
E:AddTag('mh-health:simple:percent-nosign-v2', 'PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH', function(unit, _, args)
	local status = MHCT.statusCheck(unit)
	local formatted = ''

	if (status) then
		formatted = MHCT.statusFormatter(status)
	else 
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)	
		if currentHp ~= maxHp then
			local decimalPlaces = tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
			local formatDecimal = format('%%.%sf', decimalPlaces)
			formatted = format(formatDecimal, (currentHp/maxHp)*100)
		end
	end

	return formatted
end)

E:AddTagInfo("mh-health:simple:percent-v2", MHCT.TAG_CATEGORY_NAME, "Hidden at max hp at full or percent + % sign with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places")
E:AddTag('mh-health:simple:percent-v2', 'PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH', function(unit, _, args)
	local status = MHCT.statusCheck(unit)
	local formatted = ''

	if (status) then
		formatted = MHCT.statusFormatter(status)
	else 
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)	
		if currentHp ~= maxHp then
			local decimalPlaces = tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
			local formatDecimal = format('%%.%sf%%%%', decimalPlaces)
			formatted = format(formatDecimal, (currentHp/maxHp)*100)
		end
	end

	return formatted
end)

-- Use dynamic argument to cap number of characters in name (default: 12) + dead icon if dead/offline (raid)
E:AddTagInfo("mh-dynamic:name:caps-statusicon", MHCT.TAG_CATEGORY_NAME, "Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag) - Example: mh-dynamic:name:caps-statusicon{20} will show name up to 20 characters")
E:AddTag('mh-dynamic:name:caps-statusicon', 'UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_HEALTH INSTANCE_ENCOUNTER_ENGAGE_UNIT', function(unit, _, args)
	local name = UnitName(unit) or ''
	if not name then return end

	local cname = strupper(name)
	local length = tonumber(args) or MHCT.DEFAULT_TEXT_LENGTH
	local formatted = ''

	-- Adding status icon
	local status = MHCT.statusCheck(unit)

	if (status) then
		formatted = MHCT.statusFormatter(status)
	else
		formatted = E:ShortenString(cname, length)
	end	

	return formatted
end)

-- Use dynamic argument to cap number of characters in name with no status
E:AddTagInfo("mh-dynamic:name:caps", MHCT.TAG_CATEGORY_NAME, "Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag - see examples above)")
E:AddTag('mh-dynamic:name:caps', 'UNIT_NAME_UPDATE', function(unit, _, args)
	local name = UnitName(unit) or ''
	local cname = strupper(name)
	local length = tonumber(args) or MHCT.DEFAULT_TEXT_LENGTH
	local formatted = E:ShortenString(cname, length)

	return formatted
end)

E:AddTagInfo("mh-name:caps:abbrev", MHCT.TAG_CATEGORY_NAME, "Name abbreviation/shortner - Example: 'Cleave Training Dummy' => 'C.T. Dummy")
E:AddTag('mh-name:caps:abbrev', 'UNIT_NAME_UPDATE', function(unit, _, args)
	local name = UnitName(unit)
	if name then
		return MHCT.abbreviate(strupper(name), false, unit)
	end		
end)

E:AddTagInfo("mh-name:caps:abbrev-reverse", MHCT.TAG_CATEGORY_NAME, "Name abbreviation/shortner - Example: 'Cleave Training Dummy' => 'Cleave T.D.")
E:AddTag('mh-name:caps:abbrev-reverse', 'UNIT_NAME_UPDATE', function(unit, _, args)
	local name = UnitName(unit)
	if name then
		return MHCT.abbreviate(strupper(name), true, unit)
	end		
end)

-- Use dynamic argument to cap number of characters in name (default: 12)
E:AddTagInfo("mh-player:frame:name:caps-groupnumber", MHCT.TAG_CATEGORY_NAME, "Shows unit name in all CAPS with a dynamic # of characters + unit group number if in raid (dynamic number within {} of tag - see examples above)")
E:AddTag('mh-player:frame:name:caps-groupnumber', 'UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE', function(unit, _, args)	
	local name = UnitName(unit) or ''
	local cname = strupper(name)
	local length = tonumber(args) or MHCT.DEFAULT_TEXT_LENGTH
	local formatted = E:ShortenString(cname, length)

	-- Added additional checker to add group # you are in only when in raid
	if IsInRaid() then
		local name, realm = UnitName(unit)
		if name then
			local nameRealm = (realm and realm ~= '' and format('%s-%s', name, realm)) or name
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

-- Power: shows simple percent of power (dynamic for decimal points)
E:AddTagInfo("mh-target:frame:power-percent", MHCT.TAG_CATEGORY_NAME, "Simple power percent, no percentage sign with dynamic number of decimals (dynamic number within {} of tag - see examples above)")
E:AddTag('mh-target:frame:power-percent', 'UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER', function(unit, _, args)	
	local formatted = ''
	local powerType = UnitPowerType(unit)
	local currentPower = UnitPower(unit, powerType)
	local maxPower = UnitPowerMax(unit)
	if currentPower ~= 0 then
		local decimalPlaces = tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
		local formatDecimal = format('%%.%sf', decimalPlaces)
		formatted = format(formatDecimal, (currentPower/maxPower)*100)
	end

	return formatted
end)

-- Classiciation
E:AddTagInfo("mh-classification:icon", MHCT.TAG_CATEGORY_NAME, "Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites - dynamic number within {} of tag = icon size with default size: 14px)")
E:AddTag('mh-classification:icon', 'UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP', function(unit, _, args)
	local unitType = MHCT.classificationType(unit)
	local formattedString = ''
	local baseIconSize = tonumber(args) or MHCT.DEFAULT_ICON_SIZE
	
	if (unitType == 'boss') then
		formattedString = MHCT.getFormattedIcon('bossIcon', baseIconSize - 1)
	elseif (unitType == 'eliteplus') then
		formattedString = MHCT.getFormattedIcon('yellowBahai', baseIconSize)
	elseif (unitType == 'elite') then
		formattedString = MHCT.getFormattedIcon('yellowStar', baseIconSize)
	elseif (unitType == 'rareelite') then
		formattedString = MHCT.getFormattedIcon('silverBahai', baseIconSize)
	elseif (unitType == 'rare') then
		formattedString = MHCT.getFormattedIcon('silverStar', baseIconSize)
	end

	return formattedString
end)

-- Difficulty color + level
E:AddTagInfo("mh-difficultycolor:level", MHCT.TAG_CATEGORY_NAME, "Traditional ElvUI difficulty color + level with more modern updates (will always show level)")
E:AddTag('mh-difficultycolor:level', 'UNIT_LEVEL PLAYER_LEVEL_UP', function(unit)
	return MHCT.difficultyLevelFormatter(unit, UnitEffectiveLevel(unit))
end)

-- Difficulty color + level (hidden functionality dependending on lvl)
E:AddTagInfo("mh-difficultycolor:level-hide", MHCT.TAG_CATEGORY_NAME, "Traditional ElvUI difficulty color + level with more modern updates (will always show level and only hide level when you reach max level and unit level is equal to player level)")
E:AddTag('mh-difficultycolor:level-hide', 'UNIT_LEVEL PLAYER_LEVEL_UP', function(unit)
	local unitLevel = UnitEffectiveLevel(unit)
	local playerLevel = UnitEffectiveLevel('player')

	-- Hide same level units
	if (playerLevel == unitLevel and playerLevel == MHCT.MAX_PLAYER_LEVEL) then return '' end
	
	return MHCT.difficultyLevelFormatter(unit, unitLevel)
end)

-- Deficit (number) with status + icon (dead or offline)
E:AddTagInfo("mh-deficit:num-status", MHCT.TAG_CATEGORY_NAME, "Shows deficit shortvalue number when less than 100% health and status + icon if dead/offline/ghost")
E:AddTag('mh-deficit:num-status', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit)
	local formatted = ''
	local status = MHCT.statusCheck(unit)
	if (status) then
		formatted = MHCT.statusFormatter(status)
	else
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		formatted = (currentHp == maxHp) and '' or format('-%s', E:ShortValue(maxHp - currentHp))
	end

	return formatted
end)

-- Deficit (number) with no status
E:AddTagInfo("mh-deficit:num-nostatus", MHCT.TAG_CATEGORY_NAME, "Shows deficit shortvalue number when less than 100% health (no status)")
E:AddTag('mh-deficit:num-nostatus', 'UNIT_HEALTH UNIT_MAXHEALTH', function(unit)
	local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
	return (currentHp == maxHp) and '' or format('-%s', E:ShortValue(maxHp - currentHp))
end)


-- Deficit (percent) with (dynamic decimal places)
E:AddTagInfo("mh-deficit:percent-status", MHCT.TAG_CATEGORY_NAME, "Shows deficit percent with dynamic decimal when less than 100% health + status icon")
E:AddTag('mh-deficit:percent-status', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit, _, args)
	local formatted = ''
	local status = MHCT.statusCheck(unit)
	if (status) then
		formatted = MHCT.statusFormatter(status)
	else
		local decimalPlaces = tonumber(args) or 1
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		local formatDecimal = format('-%%.%sf%%%%', decimalPlaces)
		formatted = (currentHp == maxHp) and '' or format(formatDecimal, 100 - (currentHp/maxHp)*100)
	end

	return formatted	
end)

-- Deficit (percent) with (dynamic decimal places)
E:AddTagInfo("mh-deficit:percent-status-nosign", MHCT.TAG_CATEGORY_NAME, "Shows deficit percent with dynamic decimal when less than 100% health + status icon (does not include %)")
E:AddTag('mh-deficit:percent-status-nosign', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit, _, args)
	local formatted = ''
	local status = MHCT.statusCheck(unit)
	if (status) then
		formatted = MHCT.statusFormatter(status)
	else
		local decimalPlaces = tonumber(args) or 1
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		local formatDecimal = format('-%%.%sf', decimalPlaces)
		formatted = (currentHp == maxHp) and '' or format(formatDecimal, 100 - (currentHp/maxHp)*100)
	end

	return formatted	
end)

-- Deficit (percent) with no status (dynamic decimal places)
E:AddTagInfo("mh-deficit:percent-nostatus", MHCT.TAG_CATEGORY_NAME, "Shows deficit percent with dynamic decimal when less than 100% health (no status)")
E:AddTag('mh-deficit:percent-nostatus', 'UNIT_HEALTH UNIT_MAXHEALTH', function(unit, _, args)
	local decimalPlaces = tonumber(args) or 1
	local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
	local formatDecimal = format('-%%.%sf%%%%', decimalPlaces)
	return (currentHp == maxHp) and '' or format(formatDecimal, 100 - (currentHp/maxHp)*100)
end)

-- Updating healthcolor codes (brigher and better contrast)
local HEALTH_GRADIENT = {
	['r'] = {[1] = 0.93, [2] = 0.57, [3] = 0.57}, -- #ee9090 (RED gradient)
	['g'] = {[1] = 0.93, [2] = 0.72, [3] = 0.57}, -- #eec890 (YELLOW GRADIENT)
	['b'] = {[1] = 0.57, [2] = 0.93, [3] = 0.57}, -- #90ee90 (GREEN GRADIENT)
}
E:AddTagInfo("mh-healthcolor", MHCT.TAG_CATEGORY_NAME, "Similar color tag to base ElvUI, but with brighter and high contrast gradient")
E:AddTag('mh-healthcolor', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit)
	local healthColor = {}
	if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
		healthColor = Hex(0.84, 0.75, 0.65) -- #D6BFA6
	else
		local r, g, b = ElvUF:ColorGradient(UnitHealth(unit), UnitHealthMax(unit), HEALTH_GRADIENT.r[1], HEALTH_GRADIENT.r[2], HEALTH_GRADIENT.r[3], HEALTH_GRADIENT.g[1], HEALTH_GRADIENT.g[2], HEALTH_GRADIENT.g[3], HEALTH_GRADIENT.b[1], HEALTH_GRADIENT.b[2], HEALTH_GRADIENT.b[3])
		healthColor = Hex(r, g, b)
	end

	return healthColor;
end)

-- Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (with their own icons)
E:AddTagInfo("mh-status", MHCT.TAG_CATEGORY_NAME, "Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (with their own icons)")
E:AddTag('mh-status', 'UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit, _, args)
	local status = MHCT.statusCheck(unit)
	if (status) then
		return MHCT.statusFormatter(status)
	end
end)

E:AddTagInfo("mh-status-noicon", MHCT.TAG_CATEGORY_NAME, "Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (NO icon, text only)")
E:AddTag('mh-status-noicon', 'UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit, _, args)
	local status = MHCT.statusCheck(unit)
	if (status) then
		return format('|cffD6BFA6%s|r', strupper(status))
	end
end)

-- Simple Absorb tag in paranthesis
E:AddTagInfo("mh-absorb", MHCT.TAG_CATEGORY_NAME, "Simple absorb tag in paranthesis (with yellow text color)")
E:AddTag('mh-absorb', 'UNIT_ABSORB_AMOUNT_CHANGED', function(unit)
	local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
	if absorbAmount ~= 0 then
		return format("|cff%s(%s)|r", MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
	end
end)