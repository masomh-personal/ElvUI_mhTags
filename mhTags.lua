if not IsAddOnLoaded('ElvUI') then return end
local E, L = unpack(ElvUI)
local ElvUF = E.oUF

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
local UnitIsFeignDeath = UnitIsFeignDeath
local UnitIsConnected = UnitIsConnected
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitClassification = UnitClassification
local UnitEffectiveLevel = UnitEffectiveLevel
local GetCreatureDifficultyColor = GetCreatureDifficultyColor
local UnitIsAFK = UnitIsAFK

-------------------------------------
-- HELPERS
-------------------------------------
local TAG_CATEGORY_NAME = "|cff0388fcmh|r|cffccff33Tags|r"
local MAX_PLAYER_LEVEL = 70 -- XPAC: DF
local DEFAULT_ICON_SIZE = 14
local ABSORB_TEXT_COLOR = 'ccff33'
local DEFAULT_TEXT_LENGTH = 28
local DEFAULT_DECIMAL_PLACE = 0

-- JS.includes() equivalent
local includes = function(table, value)
	for _, v in ipairs(table) do
			if v == value then
					return true
			end
	end
	return false
end

local rgbToHexDecimal = function(r, g, b)
	local rValue = math.floor(r * 255)
	local gValue = math.floor(g * 255)
	local bValue = math.floor(b * 255)

	return format("%02X%02X%02X", rValue, gValue, bValue)
end

local statusCheck = function(unit)
	local status = nil

	if UnitIsAFK(unit) then
		status = L["AFK"]
	elseif UnitIsDND(unit) then
		status = L["DND"]
	elseif (not UnitIsFeignDeath(unit) and UnitIsDead(unit)) then
		status = L["Dead"]
	elseif UnitIsGhost(unit) then
		status = L["Ghost"]
	elseif (not UnitIsConnected(unit)) then
		status = L["Offline"]
	end

	return status
end

local iconTable = {
	['default'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\deadc:%s:%s:%s:%s|t",
	['deadIcon'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\deadc:%s:%s:%s:%s|t",
	['bossIcon'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\boss_skull:%s:%s:%s:%s|t",
	['yellowWarning'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\yellow_warning1:%s:%s:%s:%s|t",
	['redWarning'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\red_warning1:%s:%s:%s:%s|t",
	['ghostIcon'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\ghost:%s:%s:%s:%s|t",
	['yellowStar'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\yellow_star:%s:%s:%s:%s|t",
	['silverStar'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\silver_star:%s:%s:%s:%s|t",
	['yellowBahai'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\bahai_yellow:%s:%s:%s:%s|t",
	['silverBahai'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\bahai_silver:%s:%s:%s:%s|t",
	['offlineIcon'] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\offline2:%s:%s:%s:%s|t",
}

local getFormattedIcon = function(name, size, x, y)
	local iconName = name or 'default'
	local iconSize = size or DEFAULT_ICON_SIZE
	local xOffSet = x or 0
	local yOffSet = y or 0

	return format(iconTable[iconName], iconSize, iconSize, xOffSet, yOffSet)
end

local classificationType = function(unit)	
	if UnitIsPlayer(unit) then return end

	local unitType = ''
	local unitLevel = UnitEffectiveLevel(unit)
	local classification = UnitClassification(unit)
	
	if ((classification == 'rare') or (classification == 'rareelite')) then
		unitType = classification
	elseif ((unitLevel == -1) or (classification == 'boss') or (classification == 'worldboss')) then
		unitType = 'boss'
	elseif (unitLevel > MAX_PLAYER_LEVEL) then
		unitType = 'eliteplus'
	else
		unitType = classification
	end

	return unitType
end

local difficultyLevelFormatter = function(unit, unitLevel)
	local unitType = classificationType(unit)	
	local crossSymbol = '+'
	local difficultyColor = GetCreatureDifficultyColor(unitLevel)
	local hexColor = rgbToHexDecimal(difficultyColor.r, difficultyColor.g, difficultyColor.b)
	local formattedString = format('|cff%s%s|r', hexColor, unitLevel)

	if (unitType == 'boss') then
		local bossColor = '00FFFF' -- cyan (not base gray)
		local bossSymbol = '' -- empty string for now
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

local statusFormatter = function(status, size, reverse)
	if not status then return end

	local iconSize = size or DEFAULT_ICON_SIZE
	local statusIconMap = ''
	
	if (status == L['AFK']) then
		statusIconMap = 'redWarning'
	elseif (status == L['DND']) then
		statusIconMap = 'yellowWarning'
	elseif (status == L['Dead']) then
		statusIconMap = 'deadIcon'
	elseif (status == L['Ghost']) then
		statusIconMap = 'ghostIcon'
	elseif (status == L['Offline']) then
		statusIconMap = 'offlineIcon'
	end

	if (reverse) then
		return format('%s|cffD6BFA6%s|r', getFormattedIcon(statusIconMap, iconSize), strupper(status))
	else 
		return format('|cffD6BFA6%s|r%s', strupper(status), getFormattedIcon(statusIconMap, iconSize))
	end
end

local abbreviate = function(str, reverse, unit)
	local words = {}
	local firstLetters = {}
	local formattedString = str:gsub("'", "") -- remove apostrophes
	for word in formattedString:gmatch("%w+") do	
			table.insert(firstLetters, word:sub(1, 1))
			table.insert(words, word)
	end

	-- GUARD: if there is only one word in string, return the string
	if #words == 1 then 
		return str
	end

	-- GUARD: if mob is special (boss, rare, etc) just use first name
	-- TYPES: "worldboss", "rareelite", "elite", "rare", "normal", "trivial", or "minus"
	if classificationType(unit) == 'boss' then
		return words[1]
	end

	local abbreviatedString = ''
	-- Reverse abbreviation of single words
	if reverse then
		-- Example: Cleave Training Dummy => Cleave T. D.
		for index, value in ipairs(words) do
			if index == 1 then
				abbreviatedString = abbreviatedString..value
			elseif index == 2 then 
				abbreviatedString = abbreviatedString..' '..firstLetters[index]..'.'
			else
				abbreviatedString = abbreviatedString..''..firstLetters[index]..'.'
			end
		end
	else 
		-- Example: Cleave Training Dummy => C. T. Dummy
		for index, value in ipairs(words) do
			if index ~= #words then
				abbreviatedString = abbreviatedString..''..firstLetters[index]..'.'
			else 
				abbreviatedString = abbreviatedString..' '..value
			end
		end
	end

	return abbreviatedString
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
		local currentPercent = (currentHp/maxHp)*100
		return format("%.1f%% | %s", currentPercent, E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true))
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
		local currentPercent = (currentHp/maxHp)*100
		return format("%s | %.1f%%", E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true), currentPercent)
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
			local currentPercent = (currentHp/maxHp)*100
			return format("%s | %.1f%%", E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true), currentPercent)		
		else
			return E:GetFormattedText('CURRENT', currentHp, maxHp, nil, true)
		end
	end
end)

-- PLAYER frame: to show health in custom format + show absorb amount if applicable
E:AddTagInfo("mh-health:absorb:current:percent:right", TAG_CATEGORY_NAME, "Hides percent at full health else shows absorb, current, and percent to following example: (**absorb amount**) 100k | 85%")
E:AddTag('mh-health:absorb:current:percent:right', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_ABSORB_AMOUNT_CHANGED', function(unit)
	local status = statusCheck(unit)
	
	if (status) then
		return statusFormatter(status)
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
			returnString = format("|cff%s(%s)|r %s", ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount), returnString)
		end

		return returnString
	end
end)

-- Use dynamic argument to add decimal places
E:AddTagInfo("mh-health:simple:percent", TAG_CATEGORY_NAME, "Shows max hp at full or percent with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places")
E:AddTag('mh-health:simple:percent', 'PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH', function(unit, _, args)
	local status = statusCheck(unit)
	if (status) then
		return statusFormatter(status)
	end
	
  local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)	
	if currentHp == maxHp then
		return E:GetFormattedText('CURRENT', maxHp, currentHp, nil, true)
	else
    local decimalPlaces = tonumber(args) or DEFAULT_DECIMAL_PLACE
    local formatDecimal = format('%%.%sf%%%%', decimalPlaces) -- NOTE: lots of escapes for percentage sign
		return format(formatDecimal, (currentHp/maxHp)*100)
	end
end)

-- Use dynamic argument to add decimal places (no % sign, same as above)
E:AddTagInfo("mh-health:simple:percent-nosign", TAG_CATEGORY_NAME, "Shows max hp at full or percent (with  no % sign) with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places")
E:AddTag('mh-health:simple:percent-nosign', 'PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH', function(unit, _, args)
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
    local formatDecimal = format('%%.%sf', decimalPlaces)
		return format(formatDecimal, (currentHp/maxHp)*100)
	end
end)

-- Use dynamic argument to add decimal places (no % sign, same as above + Hidden at full health)
E:AddTagInfo("mh-health:simple:percent-nosign-v2", TAG_CATEGORY_NAME, "Hidden at max hp at full or percent (with  no % sign) with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places")
E:AddTag('mh-health:simple:percent-nosign-v2', 'PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH', function(unit, _, args)
	local status = statusCheck(unit)
	local formatted = ''

	if (status) then
		formatted = statusFormatter(status)
	else 
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)	
		if currentHp ~= maxHp then
			local decimalPlaces = tonumber(args) or DEFAULT_DECIMAL_PLACE
			local formatDecimal = format('%%.%sf', decimalPlaces)
			formatted = format(formatDecimal, (currentHp/maxHp)*100)
		end
	end

	return formatted
end)

E:AddTagInfo("mh-health:simple:percent-v2", TAG_CATEGORY_NAME, "Hidden at max hp at full or percent + % sign with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places")
E:AddTag('mh-health:simple:percent-v2', 'PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH', function(unit, _, args)
	local status = statusCheck(unit)
	local formatted = ''

	if (status) then
		formatted = statusFormatter(status)
	else 
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)	
		if currentHp ~= maxHp then
			local decimalPlaces = tonumber(args) or DEFAULT_DECIMAL_PLACE
			local formatDecimal = format('%%.%sf%%%%', decimalPlaces)
			formatted = format(formatDecimal, (currentHp/maxHp)*100)
		end
	end

	return formatted
end)

-- Use dynamic argument to cap number of characters in name (default: 12) + dead icon if dead/offline (raid)
E:AddTagInfo("mh-dynamic:name:caps-statusicon", TAG_CATEGORY_NAME, "Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag) - Example: mh-dynamic:name:caps-statusicon{20} will show name up to 20 characters")
E:AddTag('mh-dynamic:name:caps-statusicon', 'UNIT_NAME_UPDATE UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_HEALTH INSTANCE_ENCOUNTER_ENGAGE_UNIT', function(unit, _, args)
	local name = UnitName(unit) or ''
	if not name then return end

	local cname = strupper(name)
	local length = tonumber(args) or DEFAULT_TEXT_LENGTH
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

-- Use dynamic argument to cap number of characters in name with no status
E:AddTagInfo("mh-dynamic:name:caps", TAG_CATEGORY_NAME, "Shows unit name in all CAPS with a dynamic # of characters (dynamic number within {} of tag - see examples above)")
E:AddTag('mh-dynamic:name:caps', 'UNIT_NAME_UPDATE', function(unit, _, args)
	local name = UnitName(unit) or ''
	local cname = strupper(name)
	local length = tonumber(args) or DEFAULT_TEXT_LENGTH
	local formatted = E:ShortenString(cname, length)

	return formatted
end)

E:AddTagInfo("mh-name:caps:abbrev", TAG_CATEGORY_NAME, "Name abbreviation/shortner - Example: 'Cleave Training Dummy' => 'C.T. Dummy")
E:AddTag('mh-name:caps:abbrev', 'UNIT_NAME_UPDATE', function(unit, _, args)
	local name = UnitName(unit)
	if name then
		return abbreviate(strupper(name), false, unit)
	end		
end)

E:AddTagInfo("mh-name:caps:abbrev-reverse", TAG_CATEGORY_NAME, "Name abbreviation/shortner - Example: 'Cleave Training Dummy' => 'Cleave T.D.")
E:AddTag('mh-name:caps:abbrev-reverse', 'UNIT_NAME_UPDATE', function(unit, _, args)
	local name = UnitName(unit)
	if name then
		return abbreviate(strupper(name), true, unit)
	end		
end)

-- Use dynamic argument to cap number of characters in name (default: 12)
E:AddTagInfo("mh-player:frame:name:caps-groupnumber", TAG_CATEGORY_NAME, "Shows unit name in all CAPS with a dynamic # of characters + unit group number if in raid (dynamic number within {} of tag - see examples above)")
E:AddTag('mh-player:frame:name:caps-groupnumber', 'UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE', function(unit, _, args)	
	local name = UnitName(unit) or ''
	local cname = strupper(name)
	local length = tonumber(args) or DEFAULT_TEXT_LENGTH
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
		local decimalPlaces = tonumber(args) or DEFAULT_DECIMAL_PLACE
		local formatDecimal = format('%%.%sf', decimalPlaces)
		formatted = format(formatDecimal, (currentPower/maxPower)*100)
	end

	return formatted
end)

-- Classiciation
E:AddTagInfo("mh-classification:icon", TAG_CATEGORY_NAME, "Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites - dynamic number within {} of tag = icon size with default size: 14px)")
E:AddTag('mh-classification:icon', 'UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP', function(unit, _, args)
	local unitType = classificationType(unit)
	local formattedString = ''
	local baseIconSize = tonumber(args) or DEFAULT_ICON_SIZE
	
	if (unitType == 'boss') then
		formattedString = getFormattedIcon('bossIcon', baseIconSize - 1)
	elseif (unitType == 'eliteplus') then
		formattedString = getFormattedIcon('yellowBahai', baseIconSize)
	elseif (unitType == 'elite') then
		formattedString = getFormattedIcon('yellowStar', baseIconSize)
	elseif (unitType == 'rareelite') then
		formattedString = getFormattedIcon('silverBahai', baseIconSize)
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

-- Difficulty color + level (hidden functionality dependending on lvl)
E:AddTagInfo("mh-difficultycolor:level-hide", TAG_CATEGORY_NAME, "Traditional ElvUI difficulty color + level with more modern updates (will always show level and only hide level when you reach max level and unit level is equal to player level)")
E:AddTag('mh-difficultycolor:level-hide', 'UNIT_LEVEL PLAYER_LEVEL_UP', function(unit)
	local unitLevel = UnitEffectiveLevel(unit)
	local playerLevel = UnitEffectiveLevel('player')

	-- Hide same level units
	if (playerLevel == unitLevel and playerLevel == MAX_PLAYER_LEVEL) then return '' end
	
	return difficultyLevelFormatter(unit, unitLevel)
end)

-- Deficit (number) with status + icon (dead or offline)
E:AddTagInfo("mh-deficit:num-status", TAG_CATEGORY_NAME, "Shows deficit shortvalue number when less than 100% health and status + icon if dead/offline/ghost")
E:AddTag('mh-deficit:num-status', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit)
	local formatted = ''
	local status = statusCheck(unit)
	if (status) then
		formatted = statusFormatter(status)
	else
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		formatted = (currentHp == maxHp) and '' or format('-%s', E:ShortValue(maxHp - currentHp))
	end

	return formatted
end)

-- Deficit (number) with no status
E:AddTagInfo("mh-deficit:num-nostatus", TAG_CATEGORY_NAME, "Shows deficit shortvalue number when less than 100% health (no status)")
E:AddTag('mh-deficit:num-nostatus', 'UNIT_HEALTH UNIT_MAXHEALTH', function(unit)
	local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
	return (currentHp == maxHp) and '' or format('-%s', E:ShortValue(maxHp - currentHp))
end)


-- Deficit (percent) with (dynamic decimal places)
E:AddTagInfo("mh-deficit:percent-status", TAG_CATEGORY_NAME, "Shows deficit percent with dynamic decimal when less than 100% health + status icon")
E:AddTag('mh-deficit:percent-status', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit, _, args)
	local formatted = ''
	local status = statusCheck(unit)
	if (status) then
		formatted = statusFormatter(status)
	else
		local decimalPlaces = tonumber(args) or 1
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		local formatDecimal = format('-%%.%sf%%%%', decimalPlaces)
		formatted = (currentHp == maxHp) and '' or format(formatDecimal, 100 - (currentHp/maxHp)*100)
	end

	return formatted	
end)

-- Deficit (percent) with (dynamic decimal places)
E:AddTagInfo("mh-deficit:percent-status-nosign", TAG_CATEGORY_NAME, "Shows deficit percent with dynamic decimal when less than 100% health + status icon (does not include %)")
E:AddTag('mh-deficit:percent-status-nosign', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit, _, args)
	local formatted = ''
	local status = statusCheck(unit)
	if (status) then
		formatted = statusFormatter(status)
	else
		local decimalPlaces = tonumber(args) or 1
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		local formatDecimal = format('-%%.%sf', decimalPlaces)
		formatted = (currentHp == maxHp) and '' or format(formatDecimal, 100 - (currentHp/maxHp)*100)
	end

	return formatted	
end)

-- Deficit (percent) with no status (dynamic decimal places)
E:AddTagInfo("mh-deficit:percent-nostatus", TAG_CATEGORY_NAME, "Shows deficit percent with dynamic decimal when less than 100% health (no status)")
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
E:AddTagInfo("mh-healthcolor", TAG_CATEGORY_NAME, "Similar color tag to base ElvUI, but with brighter and high contrast gradient")
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

-- Deficit (percent) with no status (dynamic decimal places)
E:AddTagInfo("mh-status", TAG_CATEGORY_NAME, "Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (with their own icons)")
E:AddTag('mh-status', 'UNIT_CONNECTION PLAYER_FLAGS_CHANGED', function(unit, _, args)
	local status = statusCheck(unit)
	if (status) then
		return statusFormatter(status)
	end
end)

-- Simple Absorb tag in paranthesis
E:AddTagInfo("mh-absorb", TAG_CATEGORY_NAME, "Simple absorb tag in paranthesis (with yellow text color)")
E:AddTag('mh-absorb', 'UNIT_ABSORB_AMOUNT_CHANGED', function(unit)
	local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
	if absorbAmount ~= 0 then
		return format("|cff%s(%s)|r", ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
	end
end)