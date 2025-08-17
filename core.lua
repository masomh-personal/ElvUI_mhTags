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
local GetMaxPlayerLevel = GetMaxPlayerLevel()

-- ElvUI references - treated like any other API
local E, L = unpack(ElvUI)
local ShortValue = E.ShortValue

-------------------------------------
-- CONSTANTS
-------------------------------------
MHCT.TAG_CATEGORY_NAME = "|cff0388fcmh|r|cffccff33Tags|r"
MHCT.MAX_PLAYER_LEVEL = GetMaxPlayerLevel
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

-- Format pattern caching
local FORMAT_PATTERNS = {
	DECIMAL_WITH_PERCENT = {}, -- Stores patterns like "%.0f%%", "%.1f%%", etc.
	DECIMAL_WITHOUT_PERCENT = {}, -- Stores patterns like "%.0f", "%.1f", etc.
}

-- Only cache the most commonly used patterns (0-2 decimals)
for i = 0, 2 do
	FORMAT_PATTERNS.DECIMAL_WITH_PERCENT[i] = format("%%.%df%%%%", i)
	FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[i] = format("%%.%df", i)
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

-- Static color sequence for gradient
local GRADIENT_COLORS = {
	0.996,
	0.32,
	0.32, -- Start color (red) at 0% health
	0.98,
	0.84,
	0.58, -- Mid color (yellow) at 50% health
	0.44,
	0.92,
	0.44, -- End color (green) at 100% health
}

-------------------------------------
-- HELPER FUNCTIONS
-------------------------------------

-- Removed - not used anywhere in the codebase

-- Optimized RGB to hex conversion
MHCT.rgbToHex = function(r, g, b)
	-- Skip type checking for performance - callers should ensure valid input
	return format("%02X%02X%02X", r * 255, g * 255, b * 255)
end

-- Removed - not used anywhere in the codebase

-- Check unit status (AFK, DND, Dead, etc.)
-- Optimized: Check most common cases first (connected & alive)
MHCT.statusCheck = function(unit)
	if not unit then
		return nil
	end

	-- Most common case: unit is connected
	if UnitIsConnected(unit) then
		-- Most units are alive, check death states first
		if UnitIsDead(unit) and not UnitIsFeignDeath(unit) then
			return L["Dead"]
		elseif UnitIsGhost(unit) then
			return L["Ghost"]
		-- Then check less common statuses
		elseif UnitIsAFK(unit) then
			return L["AFK"]
		elseif UnitIsDND(unit) then
			return L["DND"]
		end
		return nil
	else
		-- Offline is relatively rare
		return L["Offline"]
	end
end

-- Get formatted icon with size and offset
MHCT.getFormattedIcon = function(name, size, x, y)
	local iconName = name or "default"
	local iconSize = size or MHCT.DEFAULT_ICON_SIZE
	local xOffSet = x or 0
	local yOffSet = y or 0

	-- Validate icon exists
	local iconFormat = MHCT.iconTable[iconName] or MHCT.iconTable["default"]

	return format(iconFormat, iconSize, iconSize, xOffSet, yOffSet)
end

-- Determine unit classification (boss, elite, rare, etc.)
MHCT.classificationType = function(unit)
	if not unit or UnitIsPlayer(unit) then
		return nil
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

-- Format difficulty level with colors and symbols - optimized
MHCT.difficultyLevelFormatter = function(unit, unitLevel)
	if not unit or not unitLevel then
		return ""
	end

	local unitType = MHCT.classificationType(unit)
	local hexColor

	if unitType == "rare" or unitType == "rareelite" then
		hexColor = RARE_COLOR
	else
		local difficultyColor = GetCreatureDifficultyColor(unitLevel)
		hexColor = MHCT.rgbToHex(difficultyColor.r, difficultyColor.g, difficultyColor.b)
	end

	-- Direct formatting without function table
	if unitType == "boss" then
		return format("|cff%s%s|r", BOSS_COLOR, BOSS_SYMBOL)
	elseif unitType == "eliteplus" then
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

-- Format status text with icon
MHCT.statusFormatter = function(status, size, reverse)
	if not status then
		return nil
	end

	local iconSize = size or MHCT.DEFAULT_ICON_SIZE
	local iconName = STATUS_ICON_MAP[status]
	local formattedStatus = format("|cff%s%s|r", STATUS_COLOR, strupper(status))
	local icon = MHCT.getFormattedIcon(iconName, iconSize)

	if reverse then
		return format("%s%s", icon, formattedStatus)
	else
		return format("%s%s", formattedStatus, icon)
	end
end

-- Simplified abbreviation function
MHCT.abbreviate = function(str, reverse, unit)
	if not str or str == "" then
		return ""
	end

	-- Quick check for single word
	if not str:find(" ") then
		return str
	end

	-- Remove apostrophes
	local formattedString = gsub(str, "'", "")

	-- If boss unit, just return first word
	if unit and MHCT.classificationType(unit) == "boss" then
		return formattedString:match("%w+")
	end

	-- Build abbreviation directly without intermediate tables
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

-- Removed - not used directly, replaced with pre-computed gradient table

-- Simplified gradient table - only create key health percentages
MHCT.createGradientTable = function()
	local gradientTable = {}

	-- Use simpler interpolation for key percentages only
	-- Red (0-30%), Yellow (30-70%), Green (70-100%)
	for i = 0, 100 do
		local r, g, b
		if i <= 30 then
			-- Red to yellow gradient (0-30%)
			local factor = i / 30
			r = 0.996
			g = 0.32 + (0.84 - 0.32) * factor
			b = 0.32 + (0.58 - 0.32) * factor
		elseif i <= 70 then
			-- Yellow to green gradient (30-70%)
			local factor = (i - 30) / 40
			r = 0.98 - (0.98 - 0.44) * factor
			g = 0.84 + (0.92 - 0.84) * factor
			b = 0.58 - (0.58 - 0.44) * factor
		else
			-- Green (70-100%)
			r = 0.44
			g = 0.92
			b = 0.44
		end

		gradientTable[i] = format("|cff%02X%02X%02X", r * 255, g * 255, b * 255)
	end

	return gradientTable
end

-- Create the gradient table once at load time
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

-- Format health percent with configurable decimal places - simplified
MHCT.formatHealthPercent = function(unit, decimalPlaces, showSign)
	if not unit then
		return ""
	end

	local maxHp = UnitHealthMax(unit)
	if maxHp == 0 then
		return ""
	end

	local currentHp = UnitHealth(unit)
	if currentHp == maxHp then
		return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
	end

	local numDecimals = tonumber(decimalPlaces) or MHCT.DEFAULT_DECIMAL_PLACE
	local percent = (currentHp / maxHp) * 100

	-- Direct formatting based on common cases
	if showSign then
		if numDecimals == 0 then
			return format("%.0f%%", percent)
		elseif numDecimals == 1 then
			return format("%.1f%%", percent)
		else
			return format("%%.%df%%%%", numDecimals):format(percent)
		end
	else
		if numDecimals == 0 then
			return format("%.0f", percent)
		elseif numDecimals == 1 then
			return format("%.1f", percent)
		else
			return format("%%.%df", numDecimals):format(percent)
		end
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
-- Optional customCategory overrides the formatted mhTags category string
MHCT.registerThrottledTag = function(name, subCategory, description, throttle, func, customCategory)
	local fullCategory = customCategory or (MHCT.TAG_CATEGORY_NAME .. " [" .. subCategory .. "]")
	E:AddTagInfo(name, fullCategory, description)
	E:AddTag(name, throttle, func)
	return name
end

-- Enhanced multi-throttled tag registration
-- Optional customCategory places all generated throttled tags into that category
MHCT.registerMultiThrottledTag = function(namePattern, subCategory, descPattern, throttles, func, customCategory)
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
		MHCT.registerThrottledTag(tagName, subCategory, desc, throttleValue, func, customCategory)

		-- Store the result
		table.insert(results, tagName)
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
