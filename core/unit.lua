-- Shared unit, status, classification, name, icon, and level helpers.
local _, ns = ...
local MHCT = ns.MHCT

local format = string.format
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local gsub = string.gsub
local gmatch = string.gmatch
local sub = string.sub
local concat = table.concat
local strupper = strupper
local unpack = unpack

local UnitIsAFK = UnitIsAFK
local UnitIsDND = UnitIsDND
local UnitIsFeignDeath = UnitIsFeignDeath
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitIsConnected = UnitIsConnected
local UnitIsPlayer = UnitIsPlayer
local UnitEffectiveLevel = UnitEffectiveLevel
local UnitClassification = UnitClassification
local GetCreatureDifficultyColor = GetCreatureDifficultyColor
local UnitName = UnitName
local IsInRaid = IsInRaid
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local issecretvalue = issecretvalue

local E, L = unpack(ElvUI)

local MAX_PLAYER_LEVEL_VALUE = MHCT.MAX_PLAYER_LEVEL
local STATUS_COLOR = MHCT.COLORS.STATUS
local BOSS_COLOR = MHCT.COLORS.BOSS
local RARE_COLOR = MHCT.COLORS.RARE

local ELITE_SYMBOL = "+"
local ELITE_PLUS_SYMBOL = "◆"
local BOSS_SYMBOL = "??"

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

MHCT.ICON_MAP = {
	["boss"] = "bossIcon",
	["eliteplus"] = "yellowBahai",
	["elite"] = "yellowStar",
	["rareelite"] = "silverBahai",
	["rare"] = "silverStar",
}

local STATUS_ICON_MAP = {
	[L["AFK"]] = "redWarning",
	[L["DND"]] = "yellowWarning",
	[L["Dead"]] = "deadIcon",
	[L["Ghost"]] = "ghostIcon",
	[L["Offline"]] = "offlineIcon",
}

local FORMATTED_STATUS_CACHE = {}
for status in pairs(STATUS_ICON_MAP) do
	FORMATTED_STATUS_CACHE[status] = format("|cff%s%s|r", STATUS_COLOR, strupper(status))
end

local CACHED_ICONS = {}
for iconName, iconFormat in pairs(MHCT.iconTable) do
	CACHED_ICONS[iconName] = format(iconFormat, MHCT.DEFAULT_ICON_SIZE, MHCT.DEFAULT_ICON_SIZE, 0, 0)
end
MHCT.CACHED_ICONS = CACHED_ICONS

-- Return true, false, or "secret" for boolean unit APIs.
local function getSafeBooleanState(apiFunc, unit)
	if not apiFunc or not unit then
		return "secret"
	end

	local value = apiFunc(unit)
	if value == nil or issecretvalue(value) then
		return "secret"
	end

	return value == true
end

MHCT.parseDecimalArg = function(args, default)
	if not args then
		return default or 0
	end
	local parsed = tonumber(args)
	if parsed == nil then
		return default or 0
	end
	return parsed
end

MHCT.rgbToHex = function(r, g, b)
	return format("%02X%02X%02X", r * 255, g * 255, b * 255)
end

-- unitLevel may be supplied by callers that already queried UnitEffectiveLevel.
MHCT.isAtMaxLevelTogether = function(unit, unitLevel)
	if not unit then
		return false
	end
	if not unitLevel then
		unitLevel = UnitEffectiveLevel(unit)
	end
	if issecretvalue(unitLevel) or unitLevel == nil then
		return false
	end
	local playerLevel = UnitEffectiveLevel("player")
	if playerLevel == nil or issecretvalue(playerLevel) then
		return false
	end
	return playerLevel == MAX_PLAYER_LEVEL_VALUE and unitLevel == MAX_PLAYER_LEVEL_VALUE
end

-- Return name, isSecret.
MHCT.getUnitNameSafe = function(unit)
	if not unit then
		return nil, false
	end
	local name = UnitName(unit)
	if issecretvalue(name) then
		return name, true
	end
	if name == nil or name == "" then
		return nil, false
	end
	return name, false
end

MHCT.getFormattedUnitName = function(unit, length)
	local name, isSecret = MHCT.getUnitNameSafe(unit)
	if name == nil then
		return nil
	end
	if isSecret then
		return name
	end
	return E:ShortenString(strupper(name), length or MHCT.DEFAULT_TEXT_LENGTH)
end

MHCT.statusCheck = function(unit)
	if not unit then
		return nil
	end

	local connectedState = getSafeBooleanState(UnitIsConnected, unit)
	if connectedState == false then
		return L["Offline"]
	end

	local ghostState = getSafeBooleanState(UnitIsGhost, unit)
	if ghostState == true then
		return L["Ghost"]
	end

	local deadState = getSafeBooleanState(UnitIsDead, unit)
	if deadState == true then
		local feignState = getSafeBooleanState(UnitIsFeignDeath, unit)
		if feignState == false then
			return L["Dead"]
		end
	end

	local afkState = getSafeBooleanState(UnitIsAFK, unit)
	if afkState == true then
		return L["AFK"]
	end

	local dndState = getSafeBooleanState(UnitIsDND, unit)
	if dndState == true then
		return L["DND"]
	end

	return nil
end

MHCT.getFormattedIcon = function(name, size, x, y)
	local iconName = name or "default"
	local defaultSize = MHCT.DEFAULT_ICON_SIZE

	if (not size or size == defaultSize) and (not x or x == 0) and (not y or y == 0) then
		return CACHED_ICONS[iconName] or CACHED_ICONS["default"]
	end

	local iconFormat = MHCT.iconTable[iconName] or MHCT.iconTable["default"]
	return format(iconFormat, size or defaultSize, size or defaultSize, x or 0, y or 0)
end

-- unitLevel may be supplied by callers that already queried UnitEffectiveLevel.
MHCT.classificationType = function(unit, unitLevel)
	if not unit then
		return nil
	end
	local isPlayerState = getSafeBooleanState(UnitIsPlayer, unit)
	if isPlayerState == true or isPlayerState == "secret" then
		return nil
	end

	if not unitLevel then
		unitLevel = UnitEffectiveLevel(unit)
	end
	local classification = UnitClassification(unit)
	if issecretvalue(unitLevel) or issecretvalue(classification) or classification == nil then
		return nil
	end

	if classification == "rare" or classification == "rareelite" then
		return classification
	end
	if unitLevel == -1 or classification == "boss" or classification == "worldboss" then
		return "boss"
	end
	if unitLevel > MAX_PLAYER_LEVEL_VALUE then
		return "eliteplus"
	end
	return classification
end

MHCT.difficultyLevelFormatter = function(unit, unitLevel, unitType)
	if not unit then
		return ""
	end
	if issecretvalue(unitLevel) or unitLevel == nil then
		return ""
	end

	unitType = unitType or MHCT.classificationType(unit, unitLevel)
	local hexColor
	if unitType == "rare" or unitType == "rareelite" then
		hexColor = RARE_COLOR
	else
		local difficultyColor = GetCreatureDifficultyColor(unitLevel)
		hexColor = MHCT.rgbToHex(difficultyColor.r, difficultyColor.g, difficultyColor.b)
	end

	if unitType == "boss" then
		return format("|cff%s%s|r", BOSS_COLOR, BOSS_SYMBOL)
	elseif unitType == "eliteplus" then
		return format("|cff%s%s%s|r", hexColor, unitLevel, ELITE_PLUS_SYMBOL)
	elseif unitType == "elite" then
		return format("|cff%s%s%s|r", hexColor, unitLevel, ELITE_SYMBOL)
	elseif unitType == "rareelite" then
		if unitLevel < 0 then
			return format("|cff%s%sR|r", hexColor, BOSS_SYMBOL)
		end
		return format("|cff%s%sR%s|r", hexColor, unitLevel, ELITE_SYMBOL)
	elseif unitType == "rare" then
		return format("|cff%s%sR|r", hexColor, unitLevel)
	end
	return format("|cff%s%s|r", hexColor, unitLevel)
end

MHCT.statusFormatter = function(status, size, reverse)
	if not status then
		return nil
	end

	local iconSize = size or MHCT.DEFAULT_ICON_SIZE
	local iconName = STATUS_ICON_MAP[status]
	local formattedStatus = FORMATTED_STATUS_CACHE[status]
	if not formattedStatus then
		formattedStatus = format("|cff%s%s|r", STATUS_COLOR, strupper(tostring(status)))
	end
	if not iconName then
		return formattedStatus
	end

	local icon = MHCT.getFormattedIcon(iconName, iconSize)
	if reverse then
		return icon .. formattedStatus
	end
	return formattedStatus .. icon
end

MHCT.abbreviate = function(str, reverse, unit)
	if not str or str == "" then
		return ""
	end
	if not str:find(" ") then
		return str
	end

	local formattedString = gsub(str, "'", "")
	if unit and MHCT.classificationType(unit) == "boss" then
		return formattedString:match("%w+")
	end

	local result = {}
	local words = {}
	local wordCount = 0
	for word in gmatch(formattedString, "%w+") do
		wordCount = wordCount + 1
		words[wordCount] = word
	end
	if wordCount == 1 then
		return str
	end

	if reverse then
		result[1] = words[1]
		for i = 2, wordCount do
			result[#result + 1] = " "
			result[#result + 1] = sub(words[i], 1, 1)
			result[#result + 1] = "."
		end
	else
		for i = 1, wordCount - 1 do
			result[#result + 1] = sub(words[i], 1, 1)
			result[#result + 1] = "."
		end
		result[#result + 1] = " "
		result[#result + 1] = words[wordCount]
	end
	return concat(result)
end

MHCT.formatWithStatusCheck = function(unit)
	if not unit then
		return nil
	end
	local status = MHCT.statusCheck(unit)
	if status then
		return MHCT.statusFormatter(status)
	end
	return nil
end

MHCT.appendRaidGroupToName = function(unit, formattedName)
	if not unit then
		return ""
	end
	if issecretvalue(formattedName) then
		return formattedName
	end
	if formattedName == nil or formattedName == "" then
		return formattedName or ""
	end
	local name = UnitName(unit)
	if issecretvalue(name) then
		return formattedName
	end
	if name == nil or not IsInRaid() then
		return formattedName
	end
	for i = 1, GetNumGroupMembers() do
		local raidName, _, group = GetRaidRosterInfo(i)
		if raidName == name then
			return format("%s |cff00FFFF(%s)|r", formattedName, group)
		end
	end
	return formattedName
end
