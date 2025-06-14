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
local GetFormattedText = E.GetFormattedText

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

-- Initialize with commonly used decimal precision patterns
for i = 0, 5 do -- Cache patterns for 0-5 decimal places
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

-- Check if value exists in table (JS includes equivalent)
MHCT.includes = function(table, value)
	for i = 1, #table do
		if table[i] == value then
			return true
		end
	end
	return false
end

-- Replace both rgbToHexDecimal and rgbToHex with this single function
MHCT.rgbToHex = function(r, g, b)
	if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
		return "FFFFFF" -- Default to white if invalid input
	end
	return format("%02X%02X%02X", r * 255, g * 255, b * 255)
end

-- Convert hex color to RGB values
MHCT.hexToRgb = function(hex)
	if type(hex) ~= "string" or #hex ~= 6 then
		return { r = 1, g = 1, b = 1 } -- Default to white if invalid input
	end

	local r = tonumber(sub(hex, 1, 2), 16) / 255
	local g = tonumber(sub(hex, 3, 4), 16) / 255
	local b = tonumber(sub(hex, 5, 6), 16) / 255

	return { r = r, g = g, b = b }
end

-- Check unit status (AFK, DND, Dead, etc.)
-- Reorder conditions to check most common cases first
MHCT.statusCheck = function(unit)
	if not unit then
		return nil
	end

	if not UnitIsConnected(unit) then
		return L["Offline"]
	elseif UnitIsGhost(unit) then
		return L["Ghost"]
	elseif not UnitIsFeignDeath(unit) and UnitIsDead(unit) then
		return L["Dead"]
	elseif UnitIsAFK(unit) then
		return L["AFK"]
	elseif UnitIsDND(unit) then
		return L["DND"]
	end

	return nil
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

-- Format difficulty level with colors and symbols
MHCT.difficultyLevelFormatter = function(unit, unitLevel)
	if not unit or not unitLevel then
		return ""
	end

	local unitType = MHCT.classificationType(unit)
	local difficultyColor = GetCreatureDifficultyColor(unitLevel)
	local hexColor = (unitType == "rare" or unitType == "rareelite") and RARE_COLOR
		or MHCT.rgbToHex(difficultyColor.r, difficultyColor.g, difficultyColor.b)

	-- Use table lookup for formatting based on unit type
	local formatFunctions = {
		boss = function()
			return format("|cff%s%s|r", BOSS_COLOR, BOSS_SYMBOL)
		end,
		eliteplus = function()
			return format("|cff%s%s%s|r", hexColor, unitLevel, ELITE_PLUS_SYMBOL)
		end,
		elite = function()
			return format("|cff%s%s%s|r", hexColor, unitLevel, ELITE_SYMBOL)
		end,
		rareelite = function()
			local isRareBoss = unitLevel < 0
			if isRareBoss then
				return format("|cff%s%sR|r", hexColor, BOSS_SYMBOL)
			else
				return format("|cff%s%sR%s|r", hexColor, unitLevel, ELITE_SYMBOL)
			end
		end,
		rare = function()
			return format("|cff%s%sR|r", hexColor, unitLevel)
		end,
		default = function()
			return format("|cff%s%s|r", hexColor, unitLevel)
		end,
	}

	-- Return formatted text with fallback to default
	return (formatFunctions[unitType] or formatFunctions.default)()
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

-- More efficient implementation with fewer table operations
MHCT.abbreviate = function(str, reverse, unit)
	if not str or str == "" then
		return ""
	end

	-- Remove apostrophes once
	local formattedString = gsub(str, "'", "")

	-- Split into words
	local words = {}
	local firstLetters = {}
	local wordCount = 0

	for word in gmatch(formattedString, "%w+") do
		wordCount = wordCount + 1
		words[wordCount] = word
		firstLetters[wordCount] = sub(word, 1, 1)
	end

	-- If only one word, return the original string
	if wordCount == 1 then
		return str
	end

	-- If mob is special (boss, rare, etc) just use first name
	if unit and MHCT.classificationType(unit) == "boss" then
		return words[1]
	end

	-- Build abbreviated string
	local result
	if reverse then
		result = words[1]
		for i = 2, wordCount do
			result = result .. " " .. firstLetters[i] .. "."
		end
	else
		result = ""
		for i = 1, wordCount - 1 do
			result = result .. firstLetters[i] .. "."
		end
		result = result .. " " .. words[wordCount]
	end

	return result
end

--[[ 
    Interpolates between colors in a sequence based on a percentage.
    @param perc: Percentage (0 to 1) representing the position in the gradient.
    @return: Interpolated RGB color values.
]]
-- More efficient implementation with fewer calculations
MHCT.getColorGradient = function(perc)
	if type(perc) ~= "number" then
		return GRADIENT_COLORS[1], GRADIENT_COLORS[2], GRADIENT_COLORS[3]
	end

	-- Clamp percentage
	perc = perc > 1 and 1 or (perc < 0 and 0 or perc)

	local num = #GRADIENT_COLORS / 3
	local segment, relperc = math.modf(perc * (num - 1))

	local idx = segment * 3 + 1
	local r1, g1, b1 = GRADIENT_COLORS[idx], GRADIENT_COLORS[idx + 1], GRADIENT_COLORS[idx + 2]

	-- If at the end of the gradient, return the last color
	if segment >= num - 1 then
		return r1, g1, b1
	end

	-- Calculate interpolation
	local r2, g2, b2 = GRADIENT_COLORS[idx + 3], GRADIENT_COLORS[idx + 4], GRADIENT_COLORS[idx + 5]
	return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc
end

--[[ 
    Creates a gradient table with hex color values interpolated at 1.0% intervals.
    @return: Gradient table with hex color codes mapped from 0 to 100 percent.
]]
-- Optimized gradient table creation (one-time cost at login)
MHCT.createGradientTable = function()
	local gradientTable = {}

	-- Pre-define color stops for efficiency
	local colorStops = {
		{ percent = 0, r = 0.996, g = 0.32, b = 0.32 }, -- Red at 0%
		{ percent = 0.5, r = 0.98, g = 0.84, b = 0.58 }, -- Yellow at 50%
		{ percent = 1, r = 0.44, g = 0.92, b = 0.44 }, -- Green at 100%
	}

	-- Pre-compute format string for efficiency
	local colorFormat = "|cff%02X%02X%02X"

	-- Generate all gradient entries in one pass
	for i = 0, 100 do
		local percent = i / 100

		-- Find the color stops to interpolate between
		local lower, upper
		for j = 1, #colorStops - 1 do
			if percent >= colorStops[j].percent and percent <= colorStops[j + 1].percent then
				lower, upper = j, j + 1
				break
			end
		end

		-- Calculate interpolation factor
		local range = colorStops[upper].percent - colorStops[lower].percent
		local factor = range ~= 0 and (percent - colorStops[lower].percent) / range or 0

		-- Interpolate RGB values directly
		local r = colorStops[lower].r + factor * (colorStops[upper].r - colorStops[lower].r)
		local g = colorStops[lower].g + factor * (colorStops[upper].g - colorStops[lower].g)
		local b = colorStops[lower].b + factor * (colorStops[upper].b - colorStops[lower].b)

		-- Convert to hex and store directly with format string
		gradientTable[i] = format(colorFormat, r * 255, g * 255, b * 255)
	end

	return gradientTable
end

-- Create the gradient table with 1% increments and store it
MHCT.HEALTH_GRADIENT_RGB = MHCT.createGradientTable()
-- GLOBAL_MHCT_GRADIENT_TABLE = MHCT.HEALTH_GRADIENT_RGB

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

-- Format health percent with configurable decimal places
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

		-- Use cached format patterns if available
		local pattern
		if showSign then
			pattern = FORMAT_PATTERNS.DECIMAL_WITH_PERCENT[numDecimals] or format("%%.%df%%%%", numDecimals)
		else
			pattern = FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[numDecimals] or format("%%.%df", numDecimals)
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
