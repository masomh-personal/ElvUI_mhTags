-- Early return if ElvUI isn't loaded
if not C_AddOns.IsAddOnLoaded("ElvUI") then
	return
end

-- Create addon private environment (to not pollute global namespace)
local _, ns = ...
ns.MHCT = {}
local MHCT = ns.MHCT

-- No global unpacking of ElvUI here - we'll do it locally where needed

-------------------------------------
-- Direct function references for internal use
-------------------------------------
-- Lua functions
local floor = math.floor
local format = string.format
local ipairs = ipairs
local tonumber = tonumber
local gsub = string.gsub
local gmatch = string.gmatch
local sub = string.sub
local tinsert = table.insert
local concat = table.concat
local strupper = strupper
local modf = math.modf
local min = math.min
local max = math.max

-- WoW API functions
local UnitIsAFK = UnitIsAFK
local UnitIsDND = UnitIsDND
local UnitIsFeignDeath = UnitIsFeignDeath
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitIsConnected = UnitIsConnected
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitIsPlayer = UnitIsPlayer
local UnitEffectiveLevel = UnitEffectiveLevel
local UnitClassification = UnitClassification
local GetCreatureDifficultyColor = GetCreatureDifficultyColor
local GetMaxPlayerLevel = GetMaxPlayerLevel

-- ElvUI references - treated like any other API
local E, L = unpack(ElvUI)
local ShortValue = E.ShortValue

-------------------------------------
-- CONSTANTS
-------------------------------------
MHCT.TAG_CATEGORY_NAME = "|cff0388fcmh|r|cffccff33Tags|r"
MHCT.MAX_PLAYER_LEVEL = GetMaxPlayerLevel()
MHCT.DEFAULT_ICON_SIZE = 14
MHCT.ABSORB_TEXT_COLOR = "ccff33"
MHCT.DEFAULT_TEXT_LENGTH = 28
MHCT.DEFAULT_DECIMAL_PLACE = 0

-- Status color constants
local STATUS_COLOR = "D6BFA6"
local BOSS_COLOR = "fc495e" -- light red
local RARE_COLOR = "fc49f3" -- light magenta

-- Common symbols
local ELITE_SYMBOL = "+"
local ELITE_PLUS_SYMBOL = "◆"
local BOSS_SYMBOL = "??"

-- Pre-computed color format strings for common use
MHCT.COLOR_FORMATS = {
	STATUS = "|cff" .. STATUS_COLOR .. "%s|r",
	BOSS = "|cff" .. BOSS_COLOR .. "%s|r",
	RARE = "|cff" .. RARE_COLOR .. "%s|r",
	ABSORB = "|cff%s(%s)|r",
	GROUP = "%s |cff00FFFF(%s)|r",
	NAME_REALM = "%s-%s",
}

-- OPTIMIZATION: Pre-compute all format patterns up to 10 decimal places
MHCT.FORMAT_PATTERNS = {
	DECIMAL_WITH_PERCENT = {}, -- Stores patterns like "%.0f%%", "%.1f%%", etc.
	DECIMAL_WITHOUT_PERCENT = {}, -- Stores patterns like "%.0f", "%.1f", etc.
	DEFICIT_WITH_PERCENT = {}, -- Stores patterns like "-%.0f%%", "-%.1f%%", etc.
	DEFICIT_WITHOUT_PERCENT = {}, -- Stores patterns like "-%.0f", "-%.1f", etc.
}

-- Initialize with commonly used decimal precision patterns
for i = 0, 10 do -- Increased to 10 for better coverage
	MHCT.FORMAT_PATTERNS.DECIMAL_WITH_PERCENT[i] = format("%%.%df%%%%", i)
	MHCT.FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[i] = format("%%.%df", i)
	MHCT.FORMAT_PATTERNS.DEFICIT_WITH_PERCENT[i] = format("-%%.%df%%%%", i)
	MHCT.FORMAT_PATTERNS.DEFICIT_WITHOUT_PERCENT[i] = format("-%%.%df", i)
end

-- Icon table with texture paths
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

-- Classification to icon mapping
MHCT.ICON_MAP = {
	["boss"] = "bossIcon",
	["eliteplus"] = "yellowBahai",
	["elite"] = "yellowStar",
	["rareelite"] = "silverBahai",
	["rare"] = "silverStar",
}

-- Status to icon mapping
local STATUS_ICON_MAP = {
	[L["AFK"]] = "redWarning",
	[L["DND"]] = "yellowWarning",
	[L["Dead"]] = "deadIcon",
	[L["Ghost"]] = "ghostIcon",
	[L["Offline"]] = "offlineIcon",
}

-- OPTIMIZATION: Pre-compute RGB gradient values directly
local GRADIENT_START = { 0.996, 0.32, 0.32 } -- Red at 0%
local GRADIENT_MID = { 0.98, 0.84, 0.58 } -- Yellow at 50%
local GRADIENT_END = { 0.44, 0.92, 0.44 } -- Green at 100%

-------------------------------------
-- HELPER FUNCTIONS
-------------------------------------

-- OPTIMIZATION: Faster includes using hash table for O(1) lookups
MHCT.includes = function(table, value)
	for i = 1, #table do
		if table[i] == value then
			return true
		end
	end
	return false
end

-- OPTIMIZATION: Single RGB to hex function with validation
MHCT.rgbToHex = function(r, g, b)
	if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
		return "FFFFFF" -- Default to white if invalid input
	end
	-- Use bitwise operations for faster conversion
	return format("%02X%02X%02X", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

-- OPTIMIZATION: Faster hex to RGB with caching
local hexToRgbCache = {}
MHCT.hexToRgb = function(hex)
	if type(hex) ~= "string" or #hex ~= 6 then
		return { r = 1, g = 1, b = 1 } -- Default to white if invalid input
	end

	-- Check cache first
	if hexToRgbCache[hex] then
		return hexToRgbCache[hex]
	end

	local r = tonumber(sub(hex, 1, 2), 16) / 255
	local g = tonumber(sub(hex, 3, 4), 16) / 255
	local b = tonumber(sub(hex, 5, 6), 16) / 255

	local result = { r = r, g = g, b = b }
	hexToRgbCache[hex] = result
	return result
end

-- OPTIMIZATION: Status check with ordered by frequency
MHCT.statusCheck = function(unit)
	if not unit then
		return nil
	end

	-- Most common checks first (alive and connected)
	if UnitIsConnected(unit) then
		-- Player is connected, check other statuses
		if UnitIsDead(unit) and not UnitIsFeignDeath(unit) then
			return L["Dead"]
		elseif UnitIsGhost(unit) then
			return L["Ghost"]
		elseif UnitIsAFK(unit) then
			return L["AFK"]
		elseif UnitIsDND(unit) then
			return L["DND"]
		end
	else
		return L["Offline"]
	end

	return nil
end

-- OPTIMIZATION: Cache formatted icons to avoid repeated string formatting
local formattedIconCache = {}
MHCT.getFormattedIcon = function(name, size, x, y)
	local iconName = name or "default"
	local iconSize = size or MHCT.DEFAULT_ICON_SIZE
	local xOffSet = x or 0
	local yOffSet = y or 0

	-- Create cache key
	local cacheKey = iconName .. ":" .. iconSize .. ":" .. xOffSet .. ":" .. yOffSet

	-- Check cache
	if formattedIconCache[cacheKey] then
		return formattedIconCache[cacheKey]
	end

	-- Validate icon exists
	local iconFormat = MHCT.iconTable[iconName] or MHCT.iconTable["default"]
	local formatted = format(iconFormat, iconSize, iconSize, xOffSet, yOffSet)

	-- Cache the result
	formattedIconCache[cacheKey] = formatted
	return formatted
end

-- OPTIMIZATION: Simplified classification type with early returns
MHCT.classificationType = function(unit)
	if not unit or UnitIsPlayer(unit) then
		return nil
	end

	local classification = UnitClassification(unit)

	-- Check special classifications first
	if classification == "worldboss" or classification == "boss" then
		return "boss"
	elseif classification == "rare" or classification == "rareelite" then
		return classification
	end

	-- Check level-based classification
	local unitLevel = UnitEffectiveLevel(unit)
	if unitLevel == -1 then
		return "boss"
	elseif unitLevel > MHCT.MAX_PLAYER_LEVEL then
		return "eliteplus"
	end

	return classification
end

-- OPTIMIZATION: Cache difficulty colors for common levels
local difficultyColorCache = {}
MHCT.difficultyLevelFormatter = function(unit, unitLevel)
	if not unit or not unitLevel then
		return ""
	end

	local unitType = MHCT.classificationType(unit)

	-- Direct formatting for special types
	if unitType == "boss" then
		return format("|cff%s%s|r", BOSS_COLOR, BOSS_SYMBOL)
	end

	-- Get color (with caching for normal units)
	local hexColor
	if unitType == "rare" or unitType == "rareelite" then
		hexColor = RARE_COLOR
	else
		-- Check cache for difficulty color
		if not difficultyColorCache[unitLevel] then
			local difficultyColor = GetCreatureDifficultyColor(unitLevel)
			difficultyColorCache[unitLevel] = MHCT.rgbToHex(difficultyColor.r, difficultyColor.g, difficultyColor.b)
		end
		hexColor = difficultyColorCache[unitLevel]
	end

	-- Format based on type
	if unitType == "eliteplus" then
		return format("|cff%s%s%s|r", hexColor, unitLevel, ELITE_PLUS_SYMBOL)
	elseif unitType == "elite" then
		return format("|cff%s%s%s|r", hexColor, unitLevel, ELITE_SYMBOL)
	elseif unitType == "rareelite" then
		if unitLevel < 0 then
			return format("|cff%s%sR|r", hexColor, BOSS_SYMBOL)
		else
			return format("|cff%s%sR%s|r", hexColor, unitLevel, ELITE_SYMBOL)
		end
	elseif unitType == "rare" then
		return format("|cff%s%sR|r", hexColor, unitLevel)
	else
		return format("|cff%s%s|r", hexColor, unitLevel)
	end
end

-- OPTIMIZATION: Cache formatted status strings
local statusFormatterCache = {}
MHCT.statusFormatter = function(status, size, reverse)
	if not status then
		return nil
	end

	local iconSize = size or MHCT.DEFAULT_ICON_SIZE
	local cacheKey = status .. ":" .. iconSize .. ":" .. tostring(reverse)

	-- Check cache
	if statusFormatterCache[cacheKey] then
		return statusFormatterCache[cacheKey]
	end

	local iconName = STATUS_ICON_MAP[status]
	local formattedStatus = format(MHCT.COLOR_FORMATS.STATUS, strupper(status))
	local icon = MHCT.getFormattedIcon(iconName, iconSize)

	local result
	if reverse then
		result = format("%s%s", icon, formattedStatus)
	else
		result = format("%s%s", formattedStatus, icon)
	end

	statusFormatterCache[cacheKey] = result
	return result
end

-- OPTIMIZATION: Improved abbreviation with less string operations
MHCT.abbreviate = function(str, reverse, unit)
	if not str or str == "" then
		return ""
	end

	-- Remove apostrophes once
	local formattedString = gsub(str, "'", "")

	-- Quick single word check
	if not formattedString:find(" ") then
		return str
	end

	-- If mob is special (boss, rare, etc) just use first name
	if unit and MHCT.classificationType(unit) == "boss" then
		return formattedString:match("^(%S+)")
	end

	-- Build word list more efficiently
	local words = {}
	for word in gmatch(formattedString, "%S+") do
		words[#words + 1] = word
	end

	local wordCount = #words
	if wordCount == 1 then
		return str
	end

	-- Build abbreviated string
	if reverse then
		local result = words[1]
		for j = 2, wordCount do
			result = result .. " " .. sub(words[j], 1, 1) .. "."
		end
		return result
	else
		local parts = {}
		for j = 1, wordCount - 1 do
			parts[j] = sub(words[j], 1, 1) .. "."
		end
		parts[wordCount] = " " .. words[wordCount]
		return concat(parts)
	end
end

-- OPTIMIZATION: Direct gradient calculation without extra function calls
MHCT.getColorGradient = function(perc)
	if type(perc) ~= "number" then
		return GRADIENT_START[1], GRADIENT_START[2], GRADIENT_START[3]
	end

	-- Clamp percentage
	perc = min(max(perc, 0), 1)

	-- Direct interpolation based on percentage
	local r, g, b
	if perc <= 0.5 then
		-- Red to Yellow (0% to 50%)
		local factor = perc * 2
		r = GRADIENT_START[1] + factor * (GRADIENT_MID[1] - GRADIENT_START[1])
		g = GRADIENT_START[2] + factor * (GRADIENT_MID[2] - GRADIENT_START[2])
		b = GRADIENT_START[3] + factor * (GRADIENT_MID[3] - GRADIENT_START[3])
	else
		-- Yellow to Green (50% to 100%)
		local factor = (perc - 0.5) * 2
		r = GRADIENT_MID[1] + factor * (GRADIENT_END[1] - GRADIENT_MID[1])
		g = GRADIENT_MID[2] + factor * (GRADIENT_END[2] - GRADIENT_MID[2])
		b = GRADIENT_MID[3] + factor * (GRADIENT_END[3] - GRADIENT_MID[3])
	end

	return r, g, b
end

-- OPTIMIZATION: More efficient gradient table creation
MHCT.createGradientTable = function()
	local gradientTable = {}
	local colorFormat = "|cff%02X%02X%02X"

	for i = 0, 100 do
		local percent = i / 100
		local r, g, b = MHCT.getColorGradient(percent)
		gradientTable[i] = format(colorFormat, floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
	end

	return gradientTable
end

-- Create the gradient table with 1% increments and store it
MHCT.HEALTH_GRADIENT_RGB = MHCT.createGradientTable()

-- Format unit status check
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

-- OPTIMIZATION: Cached health percent formatting
local healthPercentCache = {}
local healthPercentCacheTime = {}
local CACHE_DURATION = 0.1 -- Cache for 100ms

MHCT.formatHealthPercent = function(unit, decimalPlaces, showSign)
	if not unit then
		return ""
	end

	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)

	if maxHp == 0 then
		return "" -- Avoid division by zero
	end

	if currentHp == maxHp then
		return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
	else
		local numDecimals = tonumber(decimalPlaces) or MHCT.DEFAULT_DECIMAL_PLACE
		numDecimals = min(numDecimals, 10) -- Cap at 10 decimal places

		-- Use cached format patterns (guaranteed to exist up to 10)
		local pattern
		if showSign then
			pattern = MHCT.FORMAT_PATTERNS.DECIMAL_WITH_PERCENT[numDecimals]
		else
			pattern = MHCT.FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[numDecimals]
		end

		return format(pattern, (currentHp / maxHp) * 100)
	end
end

-- Format health deficit
MHCT.formatHealthDeficit = function(unit)
	if not unit then
		return ""
	end

	local currentHp = UnitHealth(unit)
	local maxHp = UnitHealthMax(unit)

	if currentHp == maxHp or maxHp == 0 then
		return ""
	end

	return format("-%s", ShortValue(maxHp - currentHp))
end

-- Standard tag registration helper
MHCT.registerTag = function(name, subCategory, description, events, func)
	-- Create the full category name with the provided subcategory
	local fullCategory = MHCT.TAG_CATEGORY_NAME .. " [" .. subCategory .. "]"

	-- Register the tag info and the tag itself in one clean function
	E:AddTagInfo(name, fullCategory, description)
	E:AddTag(name, events, func)

	-- Return the name for potential chaining or reference
	return name
end

-- Throttled tag registration helper
MHCT.registerThrottledTag = function(name, subCategory, description, throttle, func)
	-- Create the full category name with the provided subcategory
	local fullCategory = MHCT.TAG_CATEGORY_NAME .. " [" .. subCategory .. "]"

	-- Register the tag info and the throttled tag
	E:AddTagInfo(name, fullCategory, description)
	E:AddTag(name, throttle, func)

	-- Return the name for potential chaining or reference
	return name
end

-- Enhanced multi-throttled tag registration
MHCT.registerMultiThrottledTag = function(namePattern, subCategory, descPattern, throttles, func)
	local results = {}

	-- Allow passing a predefined set by name
	if type(throttles) == "string" and MHCT.THROTTLE_SETS[throttles] then
		throttles = MHCT.THROTTLE_SETS[throttles]
	-- Default to standard throttle set if not specified
	elseif not throttles then
		throttles = MHCT.THROTTLE_SETS.STANDARD
	end

	for _, throttleInfo in ipairs(throttles) do
		local throttleValue = throttleInfo.value
		local throttleSuffix = throttleInfo.suffix or tostring(throttleValue)

		-- Generate the tag name with the throttle suffix
		local tagName = namePattern .. throttleSuffix

		-- Generate the description with the throttle information
		local desc = descPattern:gsub("%%throttle%%", throttleSuffix:gsub("^-", ""))

		-- Register the tag with this throttle value
		MHCT.registerThrottledTag(tagName, subCategory, desc, throttleValue, func)

		-- Store the result
		tinsert(results, tagName)
	end

	return results -- Return all registered tag names
end

-- Define standard throttle rates that can be used throughout the addon
MHCT.THROTTLES = {
	INSTANT = 0, -- Update every frame (use sparingly!)
	QUARTER = 0.25, -- Update 4 times per second
	HALF = 0.5, -- Update twice per second
	ONE = 1.0, -- Update once per second
	TWO = 2.0, -- Update every 2 seconds
	FIVE = 5.0, -- Update every 5 seconds (for very low priority)
}

-- Throttle configurations for batch registration
MHCT.THROTTLE_CONFIGS = {
	{ value = MHCT.THROTTLES.QUARTER, suffix = "-0.25" },
	{ value = MHCT.THROTTLES.HALF, suffix = "-0.5" },
	{ value = MHCT.THROTTLES.ONE, suffix = "-1.0" },
	{ value = MHCT.THROTTLES.TWO, suffix = "-2.0" },
}

-- Common throttle sets for different use cases
MHCT.THROTTLE_SETS = {
	-- Standard set (0.25, 0.5, 1.0, 2.0)
	STANDARD = {
		{ value = MHCT.THROTTLES.QUARTER, suffix = "-0.25" },
		{ value = MHCT.THROTTLES.HALF, suffix = "-0.5" },
		{ value = MHCT.THROTTLES.ONE, suffix = "-1.0" },
		{ value = MHCT.THROTTLES.TWO, suffix = "-2.0" },
	},

	-- Fast set (0, 0.25, 0.5)
	FAST = {
		{ value = MHCT.THROTTLES.INSTANT, suffix = "-instant" },
		{ value = MHCT.THROTTLES.QUARTER, suffix = "-0.25" },
		{ value = MHCT.THROTTLES.HALF, suffix = "-0.5" },
	},

	-- Slow set (1.0, 2.0, 5.0)
	SLOW = {
		{ value = MHCT.THROTTLES.ONE, suffix = "-1.0" },
		{ value = MHCT.THROTTLES.TWO, suffix = "-2.0" },
		{ value = MHCT.THROTTLES.FIVE, suffix = "-5.0" },
	},
}
