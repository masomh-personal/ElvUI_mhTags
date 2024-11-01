if not C_AddOns.IsAddOnLoaded("ElvUI") then
	return
end

-- Create addon private environment (to not pollute Global)
local _, ns = ...
ns.MHCT = {}
local MHCT = ns.MHCT

-- Initialize core functions in MHCT object
MHCT.E, MHCT.L = unpack(ElvUI)
MHCT.ElvUF = MHCT.E.oUF

-- Lua Language Helpers
MHCT.floor = math.floor
MHCT.ipairs = ipairs
MHCT.format = string.format
MHCT.strupper = strupper
MHCT.gsub = string.gsub
MHCT.gmatch = string.gmatch
MHCT.sub = string.sub
MHCT.tinsert = table.insert
MHCT.tonumber = tonumber
MHCT.print = print

-- WoW API functions
MHCT.UnitIsAFK = UnitIsAFK
MHCT.UnitIsDND = UnitIsDND
MHCT.UnitIsFeignDeath = UnitIsFeignDeath
MHCT.UnitIsDead = UnitIsDead
MHCT.UnitIsGhost = UnitIsGhost
MHCT.UnitIsConnected = UnitIsConnected
MHCT.UnitHealthMax = UnitHealthMax
MHCT.UnitHealth = UnitHealth
MHCT.UnitIsPlayer = UnitIsPlayer
MHCT.UnitEffectiveLevel = UnitEffectiveLevel
MHCT.UnitClassification = UnitClassification
MHCT.GetCreatureDifficultyColor = GetCreatureDifficultyColor
MHCT.GetMaxPlayerLevel = GetMaxPlayerLevel
MHCT.UnitName = UnitName
MHCT.GetRaidRosterInfo = GetRaidRosterInfo
MHCT.GetNumGroupMembers = GetNumGroupMembers
MHCT.UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
MHCT.IsInRaid = IsInRaid
MHCT.UnitPowerType = UnitPowerType
MHCT.UnitIsDeadOrGhost = UnitIsDeadOrGhost

-------------------------------------
-- CONSTANTS
-------------------------------------
MHCT.TAG_CATEGORY_NAME = "|cff0388fcmh|r|cffccff33Tags|r"
MHCT.MAX_PLAYER_LEVEL = GetMaxPlayerLevel()
MHCT.DEFAULT_ICON_SIZE = 14
MHCT.ABSORB_TEXT_COLOR = "ccff33"
MHCT.DEFAULT_TEXT_LENGTH = 28
MHCT.DEFAULT_DECIMAL_PLACE = 0

-------------------------------------
-- HELPERS
-------------------------------------
-- JS.includes() equivalent
MHCT.includes = function(table, value)
	for _, v in ipairs(table) do
		if v == value then
			return true
		end
	end
	return false
end

MHCT.rgbToHexDecimal = function(r, g, b)
	local rValue = MHCT.floor(r * 255)
	local gValue = MHCT.floor(g * 255)
	local bValue = MHCT.floor(b * 255)

	return MHCT.format("%02X%02X%02X", rValue, gValue, bValue)
end

MHCT.RGBToHex = function(r, g, b)
	return MHCT.format("%02X%02X%02X", r * 255, g * 255, b * 255)
end

MHCT.HexToRGB = function(hex)
	local r = tonumber(MHCT.sub(hex, 1, 2), 16) / 255
	local g = tonumber(MHCT.sub(hex, 3, 4), 16) / 255
	local b = tonumber(MHCT.sub(hex, 5, 6), 16) / 255
	return { r = r, g = g, b = b }
end

print(MHCT.HexToRGB("FFFFFF"))

MHCT.statusCheck = function(unit)
	if UnitIsAFK(unit) then
		return MHCT.L["AFK"]
	elseif UnitIsDND(unit) then
		return MHCT.L["DND"]
	elseif not UnitIsFeignDeath(unit) and UnitIsDead(unit) then
		return MHCT.L["Dead"]
	elseif UnitIsGhost(unit) then
		return MHCT.L["Ghost"]
	elseif not UnitIsConnected(unit) then
		return MHCT.L["Offline"]
	end

	return nil
end

MHCT.iconTable = {
	["default"] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\deadc:%s:%s:%s:%s|t",
	["deadIcon"] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\deadc:%s:%s:%s:%s|t",
	["bossIcon"] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\boss_skull:%s:%s:%s:%s|t",
	["yellowWarning"] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\yellow_warning1:%s:%s:%s:%s|t",
	["redWarning"] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\red_warning1:%s:%s:%s:%s|t",
	["ghostIcon"] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\ghost:%s:%s:%s:%s|t",
	["yellowStar"] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\yellow_star:%s:%s:%s:%s|t",
	["silverStar"] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\silver_star:%s:%s:%s:%s|t",
	["yellowBahai"] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\bahai_yellow:%s:%s:%s:%s|t",
	["silverBahai"] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\bahai_silver:%s:%s:%s:%s|t",
	["offlineIcon"] = "|TInterface\\AddOns\\ElvUI_mhTags\\icons\\offline2:%s:%s:%s:%s|t",
}

MHCT.getFormattedIcon = function(name, size, x, y)
	local iconName = name or "default"
	local iconSize = size or MHCT.DEFAULT_ICON_SIZE
	local xOffSet = x or 0
	local yOffSet = y or 0

	return MHCT.format(MHCT.iconTable[iconName], iconSize, iconSize, xOffSet, yOffSet)
end

MHCT.classificationType = function(unit)
	if UnitIsPlayer(unit) then
		return
	end

	local unitLevel = UnitEffectiveLevel(unit)
	local classification = UnitClassification(unit)

	if classification == "rare" or classification == "rareelite" then
		return classification
	end

	if unitLevel == -1 or classification == "boss" or classification == "worldboss" then
		return "boss"
	end

	if unitLevel > MHCT.MAX_PLAYER_LEVEL then
		return "eliteplus"
	end

	return classification
end

MHCT.difficultyLevelFormatter = function(unit, unitLevel)
	local unitType = MHCT.classificationType(unit)
	local crossSymbol = "+"
	local difficultyColor = GetCreatureDifficultyColor(unitLevel)
	local hexColor = MHCT.rgbToHexDecimal(difficultyColor.r, difficultyColor.g, difficultyColor.b)

	local formatMap = {
		boss = function()
			return MHCT.format("|cff%s%s|r", "00FFFF", "")
		end,
		eliteplus = function()
			return MHCT.format("|cff%s%s%s%s|r", hexColor, unitLevel, crossSymbol, crossSymbol)
		end,
		elite = function()
			return MHCT.format("|cff%s%s%s|r", hexColor, unitLevel, crossSymbol)
		end,
		rareelite = function()
			return MHCT.format("|cff%s%sR%s|r", hexColor, unitLevel, crossSymbol)
		end,
		rare = function()
			return MHCT.format("|cff%s%sR|r", hexColor, unitLevel)
		end,
		default = function()
			return MHCT.format("|cff%s%s|r", hexColor, unitLevel)
		end,
	}

	return (formatMap[unitType] or formatMap["default"])()
end

MHCT.statusFormatter = function(status, size, reverse)
	if not status then
		return
	end

	local iconSize = size or MHCT.DEFAULT_ICON_SIZE
	local statusIconMap = {
		[MHCT.L["AFK"]] = "redWarning",
		[MHCT.L["DND"]] = "yellowWarning",
		[MHCT.L["Dead"]] = "deadIcon",
		[MHCT.L["Ghost"]] = "ghostIcon",
		[MHCT.L["Offline"]] = "offlineIcon",
	}
	local iconName = statusIconMap[status]
	local formattedStatus = MHCT.format("|cffD6BFA6%s|r", MHCT.strupper(status))

	if reverse then
		return MHCT.format("%s%s", MHCT.getFormattedIcon(iconName, iconSize), formattedStatus)
	else
		return MHCT.format("%s%s", formattedStatus, MHCT.getFormattedIcon(iconName, iconSize))
	end
end

MHCT.abbreviate = function(str, reverse, unit)
	local words = {}
	local firstLetters = {}
	local formattedString = gsub(str, "'", "") -- remove apostrophes
	for word in gmatch(formattedString, "%w+") do
		tinsert(firstLetters, MHCT.sub(word, 1, 1))
		tinsert(words, word)
	end

	-- GUARD: if there is only one word in string, return the string
	if #words == 1 then
		return str
	end

	-- GUARD: if mob is special (boss, rare, etc) just use first name
	if MHCT.classificationType(unit) == "boss" then
		return words[1]
	end

	local abbreviatedString = ""
	if reverse then
		for index, value in ipairs(words) do
			if index == 1 then
				abbreviatedString = value
			else
				abbreviatedString = abbreviatedString .. " " .. firstLetters[index] .. "."
			end
		end
	else
		for index, value in ipairs(words) do
			if index ~= #words then
				abbreviatedString = abbreviatedString .. "" .. firstLetters[index] .. "."
			else
				abbreviatedString = abbreviatedString .. " " .. value
			end
		end
	end

	return abbreviatedString
end

-- Precomputed health colors in 0.5% increments so this is not done on the fly during tag updates
MHCT.HEALTH_GRADIENT_RGB = {}
-- Colors for health percentages from 0% to 100% in 0.5% increments
for i = 0, 200 do
	local healthPercent = i / 200
	local r, g, b = MHCT.ElvUF:ColorGradient(
		healthPercent,
		1,
		0.93,
		0.57,
		0.57, -- Start color (red)
		0.93,
		0.72,
		0.57, -- Mid color (yellow)
		0.57,
		0.93,
		0.57 -- End color (green)
	)
	MHCT.HEALTH_GRADIENT_RGB[i * 0.5] = MHCT.format("|cff%s", MHCT.RGBToHex(r, g, b))
end

MHCT.ICON_MAP = {
	["boss"] = "bossIcon",
	["eliteplus"] = "yellowBahai",
	["elite"] = "yellowStar",
	["rareelite"] = "silverBahai",
	["rare"] = "silverStar",
}

MHCT.formatWithStatusCheck = function(unit)
	local status = MHCT.statusCheck(unit)
	if status then
		return MHCT.statusFormatter(status)
	end

	return nil
end

MHCT.formatHealthPercent = function(unit, args, showSign)
	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)
	if currentHp == maxHp then
		return MHCT.E:GetFormattedText("CURRENT", maxHp, currentHp, nil, true)
	else
		local decimalPlaces = tonumber(args) or 0
		local formatPattern = showSign and "%%.%sf%%%%" or "%%.%sf"
		return MHCT.format(MHCT.format(formatPattern, decimalPlaces), (currentHp / maxHp) * 100)
	end
end
