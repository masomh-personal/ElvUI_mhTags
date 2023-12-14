if not IsAddOnLoaded('ElvUI') then return end
local E, L = unpack(ElvUI)

-- Are you local?
local tonumber, print, format, strupper, math = tonumber, print, format, strupper, math
local UnitName = UnitName
local UnitIsPlayer = UnitIsPlayer
local GetRaidRosterInfo = GetRaidRosterInfo
local GetNumGroupMembers = GetNumGroupMembers
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsGhost = UnitIsGhost
local UnitIsDead = UnitIsDead
local UnitIsConnected = UnitIsConnected
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitClassification = UnitClassification
local UnitEffectiveLevel = UnitEffectiveLevel
local GetCreatureDifficultyColor = GetCreatureDifficultyColor

-------------------------------------
-- HELPERS
-------------------------------------
local TAG_CATEGORY_NAME = "|cff0388fcmh|r|cffccff33Tags|r"
local MAX_PLAYER_LEVEL = 70 -- XPAC: DF

local rgbToHexDecimal = function(r, g, b)
	local rValue = math.floor(r * 255)
	local gValue = math.floor(g * 255)
	local bValue = math.floor(b * 255)

	return format("%02X%02X%02X", rValue, gValue, bValue)
end

local statusCheck = function(unit)
	return UnitIsDead(unit) and L["Dead"] or UnitIsGhost(unit) and L["Ghost"] or not UnitIsConnected(unit) and L["Offline"]
end

local iconTable = {
	['default'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\deadc:%s:%s:%s:%s|t",
	['deadIcon'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\deadc:%s:%s:%s:%s|t",
	['bossIcon'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\boss_skull:%s:%s:%s:%s|t",
	['yellowWarning'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\yellow_warning:%s:%s:%s:%s|t",
	['redWarning'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\red_warning:%s:%s:%s:%s|t",
	['questionIcon'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\question_mark:%s:%s:%s:%s|t",
	['yellowStar'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\yellow_star:%s:%s:%s:%s|t",
	['silverStar'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\silver_star:%s:%s:%s:%s|t",
	['yellowBahai'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\bahai_yellow:%s:%s:%s:%s|t",
	['silverBahai'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\bahai_silver:%s:%s:%s:%s|t",
	['yellowPlus'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\yellow_plus:%s:%s:%s:%s|t",
	['offline'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\offline:%s:%s:%s:%s|t",
}

local getFormattedIcon = function(name, size, x, y)
	local iconName = name or 'default'
	local iconSize = size or 10
	local xOffSet = x or 0
	local yOffSet = y or 0

	return format(iconTable[iconName], iconSize, iconSize, xOffSet, yOffSet)
end

local classificationType = function(unit)	
	if UnitIsPlayer(unit) then return end

	local unitType = 'normal'
	local unitLevel = UnitEffectiveLevel(unit)
	local classification = UnitClassification(unit)
	
	if ((unitLevel == -1) or (classification == 'boss') or (classification == 'worldboss')) then
		unitType = 'boss'
	elseif (unitLevel > MAX_PLAYER_LEVEL) then
		unitType = 'eliteplus'
	elseif (classification == 'rareelite' or classification == 'rare' or classification == 'elite') then
		unitType = classification
	end

	return unitType
end

local difficultyLevelFormatter = function(unit, unitLevel)
	local unitType = classificationType(unit)	
	local bossColor = '00FFFF' -- cyan (not base gray)
	local bossSymbol = '' -- empty string for now
	local crossSymbol = '+'
	local difficultyColor = GetCreatureDifficultyColor(unitLevel)
	local hexColor = rgbToHexDecimal(difficultyColor.r, difficultyColor.g, difficultyColor.b)
	local formattedString = format('|cff%s%s|r', hexColor, unitLevel)

	if (unitType == 'boss') then
		formattedString = format('|cff%s%s|r', bossColor, bossSymbol)
	elseif (unitType == 'eliteplus') then
		formattedString = format('|cff%s%s%s%s|r', hexColor, unitLevel, crossSymbol, crossSymbol)
	elseif (unitType == 'elite') then
		formattedString = format('|cff%s%s%s|r', hexColor, unitLevel, crossSymbol)
	elseif (unitType == 'rareelite') then
		formattedString = format('|cff%s%sR%s|r', hexColor, unitLevel, crossSymbol)
	elseif (unitType == 'rare') then
		formattedString = format('|cff%s%sR|r', hexColor, unitLevel)
	end

	return formattedString
end

local statusFormatter = function(status)
	local statusInfo = (status == 'Offline') and 'offline' or 'deadIcon'
	return format('%s %s', status, getFormattedIcon(statusInfo, 14))
end

--------------------------------------
-- HEALTH RELATED TAGS
--------------------------------------
E:AddTagInfo("mh-health:current:percent:left", TAG_CATEGORY_NAME, "Shows current + percent health at all times similar to following example: 85% | 100k")
E:AddTag('mh-health:current:percent:left', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit)
	local status = statusCheck(unit)
	
	if (status) then
		return statusFormatter(status)
	else
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		local CurrentPercent = (currentHp/maxHp)*100
		return format("%.1f%% | %s", CurrentPercent, E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true))
	end
end)

--
E:AddTagInfo("mh-health:current:percent:right", TAG_CATEGORY_NAME, "Shows current + percent health at all times similar to following example: 100k | 85%")
E:AddTag('mh-health:current:percent:right', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit)
	local status = statusCheck(unit)
	
	if (status) then
		return statusFormatter(status)
	else
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		local CurrentPercent = (currentHp/maxHp)*100
		return format("%s | %.1f%%", E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true), CurrentPercent)
	end
end)

-- HEALTH: show percent on right of | and current HP on left, but only if not at 100%
E:AddTagInfo("mh-health:current:percent:right-hidefull", TAG_CATEGORY_NAME, "Hides percent at full health else shows at all times similar to following example: 100k | 85%")
E:AddTag('mh-health:current:percent:right-hidefull', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit)
	local status = statusCheck(unit)
	
	if (status) then
		return statusFormatter(status)
	else
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)

		if maxHp ~= currentHp then
			local CurrentPercent = (currentHp/maxHp)*100
			return format("%s | %.1f%%", E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true), CurrentPercent)		
		else
			return E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true)
		end
	end
end)

-- PLAYER frame: to show health in custom format + show absorb amount if applicable
E:AddTagInfo("mh-health:absorb:current:percent:right", TAG_CATEGORY_NAME, "Hides percent at full health else shows absorb, current, and percent to following example: (<absorb amount>) 100k | 85%")
E:AddTag('mh-health:absorb:current:percent:right', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_ABSORB_AMOUNT_CHANGED', function(unit)
	local status = statusCheck(unit)
	
	if (status) then
		return statusFormatter(status)
	else
		local returnString = ''
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)		

		if maxHp ~= currentHp then
			local CurrentPercent = (currentHp/maxHp)*100
			returnString = format("%s | %.1f%%", E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true), CurrentPercent)		
		else
			returnString = E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true)
		end

		local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount ~= 0 then
			returnString = format("|cffccff33(%s)|r %s", E:ShortValue(absorbAmount), returnString)
		end

		return returnString
	end
end)

-- Use dynamic argument to add decimal places
E:AddTagInfo("mh-health:simple:percent", TAG_CATEGORY_NAME, "Shows max hp at full or percent with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places")
E:AddTag('mh-health:simple:percent', 'UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_HEALTH PLAYER_FLAGS_CHANGED', function(unit, _, args)
	local status = statusCheck(unit)
	if (status) then
		return statusFormatter(status)
	end
	
  local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)	
	if currentHp == maxHp then
		return E:GetFormattedText('CURRENT', maxHp, currentHp, nil, true)
	else
    local decimalPlaces = tonumber(args) or 0
    local formatDecimal = format('%%.%sf%%%%', decimalPlaces) -- NOTE: lots of escapes for percentage sign
		return format(formatDecimal, (currentHp/maxHp)*100)
	end
end)

-- Use dynamic argument to cap number of characters in name (default: 12) + dead icon if dead/offline (raid)
E:AddTagInfo("mh-dynamic:name:caps-statusicon", TAG_CATEGORY_NAME, "Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag) - Example: mh-dynamic:name:caps-statusicon{20} will show name up to 20 characters")
E:AddTag('mh-dynamic:name:caps-statusicon', 'UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_HEALTH INSTANCE_ENCOUNTER_ENGAGE_UNIT', function(unit, _, args)
	local name = UnitName(unit) or ''
	if not name then return end

	local cname = strupper(name)
	local length = tonumber(args) or 12
	local formatted = ''

	-- Adding status icon
	local status = statusCheck(unit)

	if (status) then
		formatted = statusFormatter(status)
	else
		formatted = E:ShortenString(cname, length)
	end	

	return formatted
end)

-- Use dynamic argument to cap number of characters in name (default: 12)
E:AddTagInfo("mh-dynamic:name:caps", TAG_CATEGORY_NAME, "Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag - see examples above)")
E:AddTag('mh-dynamic:name:caps', 'UNIT_NAME_UPDATE', function(unit, _, args)
	local name = UnitName(unit) or ''
	local cname = strupper(name)
	local length = tonumber(args) or 12
	local formatted = E:ShortenString(cname, length)

	return formatted
end)

-- Use dynamic argument to cap number of characters in name (default: 12)
E:AddTagInfo("mh-player:frame:name:caps-groupnumber", TAG_CATEGORY_NAME, "Shows unit name in all CAPS with a dynamic # of characters + unit group number if in raid (dynamic number within {} of tag - see examples above)")
E:AddTag('mh-player:frame:name:caps-groupnumber', 'UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE', function(unit, _, args)	
	local name = UnitName(unit) or ''
	local cname = strupper(name)
	local length = tonumber(args) or 12
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
E:AddTagInfo("mh-target:frame:power-percent", TAG_CATEGORY_NAME, "Simple power percent, no percentage sign with dynamic number of decimals (dynamic number within {} of tag - see examples above)")
E:AddTag('mh-target:frame:power-percent', 'UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER', function(unit, _, args)	
	local formatted = ''
	local powerType = UnitPowerType(unit)
	local currentPower = UnitPower(unit, powerType)
	local maxPower = UnitPowerMax(unit)
	if currentPower ~= 0 then
		local decimalPlaces = tonumber(args) or 0
		local formatDecimal = format('%%.%sf', decimalPlaces)
		formatted = format(formatDecimal, (currentPower/maxPower)*100)
	end

	return formatted
end)

-- Classiciation
E:AddTagInfo("mh-classification:icon", TAG_CATEGORY_NAME, "Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites - dynamic number within {} of tag = icon size with default size: 15px)")
E:AddTag('mh-classification:icon', 'UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP', function(unit, _, args)
	local unitType = classificationType(unit)
	local formattedString = ''
	local baseIconSize = tonumber(args) or 15
	
	if (unitType == 'boss') then
		formattedString = getFormattedIcon('bossIcon', baseIconSize-1)
	elseif (unitType == 'eliteplus') then
		formattedString = getFormattedIcon('yellowBahai', baseIconSize)
	elseif (unitType == 'elite') then
		formattedString = getFormattedIcon('yellowStar', baseIconSize)
	elseif (unitType == 'rareelite') then
		formattedString = getFormattedIcon('silverBahai', baseIconSize, 0, 1)
	elseif (unitType == 'rare') then
		formattedString = getFormattedIcon('silverStar', baseIconSize)
	end

	return formattedString
end)

-- Difficulty color + level
E:AddTagInfo("mh-difficultycolor:level", TAG_CATEGORY_NAME, "Traditional ElvUI difficulty color + level with more modern updates (will always show level)")
E:AddTag('mh-difficultycolor:level', 'UNIT_LEVEL PLAYER_LEVEL_UP', function(unit)
	return difficultyLevelFormatter(unit, UnitEffectiveLevel(unit))
end)

E:AddTagInfo("mh-difficultycolor:level-hide", TAG_CATEGORY_NAME, "Traditional ElvUI difficulty color + level with more modern updates (will always show level and only hide level when you reach max level and unit level is equal to player level)")
E:AddTag('mh-difficultycolor:level-hide', 'UNIT_LEVEL PLAYER_LEVEL_UP', function(unit)
	local unitLevel = UnitEffectiveLevel(unit)
	local playerLevel = UnitEffectiveLevel('player')

	-- Hide same level units
	if (playerLevel == unitLevel and playerLevel == MAX_PLAYER_LEVEL) then return '' end
	
	return difficultyLevelFormatter(unit, unitLevel)
end)