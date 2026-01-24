-- Early return if ElvUI isn't loaded
if not C_AddOns.IsAddOnLoaded("ElvUI") then
	return
end

-- Create addon private environment (to not pollute global namespace)
local _, ns = ...
ns.MHCT = {}
local MHCT = ns.MHCT

-------------------------------------
-- ADDON VERSION INFO
-------------------------------------
MHCT.ADDON_VERSION = "9.0"
MHCT.ADDON_NAME = "ElvUI_mhTags"

-------------------------------------
-- FUNCTION LOCALIZATION
-- Localizing all functions improves performance by avoiding global lookups
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
local select = select
local type = type

-- WoW API functions (standard)
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
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local IsInRaid = IsInRaid
local wipe = wipe
local GetBuildInfo = GetBuildInfo

-------------------------------------
-- WOW VERSION DETECTION
-- Detect WoW 12.0+ for new API availability
-------------------------------------
local WOW_INTERFACE_VERSION = select(4, GetBuildInfo())
local IS_WOW_12_0_OR_LATER = WOW_INTERFACE_VERSION >= 120000

-- Export version info for debugging
MHCT.WOW_INTERFACE_VERSION = WOW_INTERFACE_VERSION
MHCT.IS_WOW_12_0_OR_LATER = IS_WOW_12_0_OR_LATER

-------------------------------------
-- WOW 12.0 API DETECTION AND WRAPPERS
-- New APIs in 12.0: UnitHealthPercent, UnitHealthMissing, UnitPowerPercent, UnitPowerMissing
-- Also: issecretvalue() to check if a value is secret
-------------------------------------

-- Check for new 12.0 APIs availability (they may not exist in all 12.0 builds)
local HAS_UNIT_HEALTH_PERCENT = type(UnitHealthPercent) == "function"
local HAS_UNIT_HEALTH_MISSING = type(UnitHealthMissing) == "function"
local HAS_UNIT_POWER_PERCENT = type(UnitPowerPercent) == "function"
local HAS_UNIT_POWER_MISSING = type(UnitPowerMissing) == "function"

-- Check for issecretvalue() function (12.0+)
local HAS_ISSECRETVALUE = type(issecretvalue) == "function"
local _issecretvalue = HAS_ISSECRETVALUE and issecretvalue or function() return false end

-- Export API availability for tag files
MHCT.HAS_UNIT_HEALTH_PERCENT = HAS_UNIT_HEALTH_PERCENT
MHCT.HAS_UNIT_HEALTH_MISSING = HAS_UNIT_HEALTH_MISSING
MHCT.HAS_UNIT_POWER_PERCENT = HAS_UNIT_POWER_PERCENT
MHCT.HAS_UNIT_POWER_MISSING = HAS_UNIT_POWER_MISSING
MHCT.HAS_ISSECRETVALUE = HAS_ISSECRETVALUE

-- Localize new APIs if available
local _UnitHealthPercent = HAS_UNIT_HEALTH_PERCENT and UnitHealthPercent or nil
local _UnitHealthMissing = HAS_UNIT_HEALTH_MISSING and UnitHealthMissing or nil
local _UnitPowerPercent = HAS_UNIT_POWER_PERCENT and UnitPowerPercent or nil
local _UnitPowerMissing = HAS_UNIT_POWER_MISSING and UnitPowerMissing or nil

-------------------------------------
-- API WRAPPER FUNCTIONS
-- WoW 12.0 Secret Value Handling:
-- Even the new 12.0 APIs can return "secret values" in combat contexts.
-- Secret values CANNOT be compared or used in arithmetic by tainted addon code.
-- We use issecretvalue() to detect secrets and return a safe default (0) for comparisons.
-- The actual display will use the raw values passed to ElvUI which handles them correctly.
-------------------------------------

-- Get health percentage (0-100) - SAFE FOR COMPARISONS
-- Returns 0 if the value is secret (caller should not use for comparisons in that case)
-- For display purposes, use UnitHealthPercent directly and pass to UI functions
MHCT.GetUnitHealthPercent = function(unit)
	if not unit then
		return 0
	end

	if HAS_UNIT_HEALTH_PERCENT then
		local percent = _UnitHealthPercent(unit)
		-- If it's a secret value, we can't compare it - return 0 as a safe default
		-- The display layer will still work with the raw value
		if percent and _issecretvalue(percent) then
			return 0 -- Secret value - can't be compared
		end
		return percent or 0
	end

	-- Fallback for pre-12.0 (no secret values in older WoW)
	local maxHp = UnitHealthMax(unit)
	if not maxHp or maxHp == 0 then
		return 0
	end
	local currentHp = UnitHealth(unit)
	return (currentHp / maxHp) * 100
end

-- Get health deficit (positive number representing missing health)
MHCT.GetUnitHealthMissing = function(unit)
	if not unit then
		return 0
	end

	if HAS_UNIT_HEALTH_MISSING then
		local missing = _UnitHealthMissing(unit)
		if missing and _issecretvalue(missing) then
			return 0 -- Secret value - can't be compared
		end
		return missing or 0
	end

	-- Fallback for pre-12.0
	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)
	if not maxHp or not currentHp then
		return 0
	end
	return maxHp - currentHp
end

-- Get power percentage (0-100)
MHCT.GetUnitPowerPercent = function(unit, powerType)
	if not unit then
		return 0
	end

	if HAS_UNIT_POWER_PERCENT then
		local percent = _UnitPowerPercent(unit, powerType)
		if percent and _issecretvalue(percent) then
			return 0 -- Secret value - can't be compared
		end
		return percent or 0
	end

	-- Fallback for pre-12.0
	local UnitPower = UnitPower
	local UnitPowerMax = UnitPowerMax
	local maxPower = UnitPowerMax(unit, powerType)
	if not maxPower or maxPower == 0 then
		return 0
	end
	local currentPower = UnitPower(unit, powerType)
	return (currentPower / maxPower) * 100
end

-- Get power deficit (positive number representing missing power)
MHCT.GetUnitPowerMissing = function(unit, powerType)
	if not unit then
		return 0
	end

	if HAS_UNIT_POWER_MISSING then
		local missing = _UnitPowerMissing(unit, powerType)
		if missing and _issecretvalue(missing) then
			return 0 -- Secret value - can't be compared
		end
		return missing or 0
	end

	-- Fallback for pre-12.0
	local UnitPower = UnitPower
	local UnitPowerMax = UnitPowerMax
	local maxPower = UnitPowerMax(unit, powerType)
	local currentPower = UnitPower(unit, powerType)
	if not maxPower or not currentPower then
		return 0
	end
	return maxPower - currentPower
end

-- Cache max player level at load time (doesn't change during session)
local MAX_PLAYER_LEVEL_VALUE = GetMaxPlayerLevel()

-- ElvUI references - unpack once and share references
local E, L = unpack(ElvUI)

-------------------------------------
-- ELVUI API VALIDATION
-- Validates required ElvUI functions exist to prevent runtime errors
-------------------------------------
local function validateElvUIAPI()
	local requiredFunctions = {
		"AddTag",
		"AddTagInfo",
		"GetFormattedText",
		"ShortValue",
		"ShortenString",
	}

	local missing = {}
	for _, funcName in ipairs(requiredFunctions) do
		if not E[funcName] then
			tinsert(missing, funcName)
		end
	end

	if #missing > 0 then
		local missingList = concat(missing, ", ")
		error(
			format(
				"ElvUI_mhTags: Required ElvUI functions not found: %s\n"
					.. "This may indicate an incompatible ElvUI version. Please update both addons.",
				missingList
			)
		)
	end
end

-- Validate ElvUI API before proceeding
validateElvUIAPI()

-------------------------------------
-- VERSION COMPATIBILITY CHECKS
-- Validates ElvUI version and provides WoW 12.0 guidance
-------------------------------------
local function checkCompatibility()
	local minElvUIVersion = 13.0
	local recommendedElvUIVersion = 14.0
	local currentElvUIVersion = tonumber(E.version) or 0

	-- ElvUI version check
	if currentElvUIVersion > 0 then
		if currentElvUIVersion < minElvUIVersion then
			print(
				format(
					"|cffFF0000[ElvUI_mhTags Error]|r This addon requires ElvUI %.1f or higher. "
						.. "Current version: %.1f. Please update ElvUI.",
					minElvUIVersion,
					currentElvUIVersion
				)
			)
		elseif IS_WOW_12_0_OR_LATER and currentElvUIVersion < recommendedElvUIVersion then
			print(
				format(
					"|cffFFFF00[ElvUI_mhTags Warning]|r WoW 12.0 (Midnight) detected. "
						.. "ElvUI %.1f+ is recommended for best compatibility. "
						.. "Current version: %.1f",
					recommendedElvUIVersion,
					currentElvUIVersion
				)
			)
		end
	end

	-- WoW 12.0 API availability info (debug, only shown with /mhtags debug)
	MHCT.debugInfo = {
		wowVersion = WOW_INTERFACE_VERSION,
		elvuiVersion = currentElvUIVersion,
		isWoW12 = IS_WOW_12_0_OR_LATER,
		hasHealthPercent = HAS_UNIT_HEALTH_PERCENT,
		hasHealthMissing = HAS_UNIT_HEALTH_MISSING,
		hasPowerPercent = HAS_UNIT_POWER_PERCENT,
		hasPowerMissing = HAS_UNIT_POWER_MISSING,
	}
end

checkCompatibility()

-- Export ElvUI references for tag modules to avoid duplicate unpacking
MHCT.E = E
MHCT.L = L

-------------------------------------
-- CONSTANTS
-------------------------------------
MHCT.TAG_CATEGORY_NAME = "|cff0388fcmh|r|cffccff33Tags|r"
MHCT.MAX_PLAYER_LEVEL = MAX_PLAYER_LEVEL_VALUE
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

-- Cache all reasonable decimal patterns (0-5 decimals)
for i = 0, 5 do
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

-- Pre-cached formatted status text (avoids strupper() and format() in hot path)
local FORMATTED_STATUS_CACHE = {}
for status, _ in pairs(STATUS_ICON_MAP) do
	FORMATTED_STATUS_CACHE[status] = format("|cff%s%s|r", STATUS_COLOR, strupper(status))
end

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

-- Centralized argument parsing for decimal places
-- Handles nil, 0, and invalid values correctly
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

-- Optimized RGB to hex conversion
MHCT.rgbToHex = function(r, g, b)
	-- Skip type checking for performance - callers should ensure valid input
	return format("%02X%02X%02X", r * 255, g * 255, b * 255)
end

-- Removed - not used anywhere in the codebase

-- Optimized unit status check for ElvUI V14.0
MHCT.statusCheck = function(unit)
	if not unit then
		return nil
	end

	-- Fast path: check connection first (most common case)
	if not UnitIsConnected(unit) then
		return L["Offline"]
	end

	-- Check death states (common in combat)
	if UnitIsDead(unit) and not UnitIsFeignDeath(unit) then
		return L["Dead"]
	elseif UnitIsGhost(unit) then
		return L["Ghost"]
	end

	-- Check status flags (less common)
	if UnitIsAFK(unit) then
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
	local xOffset = x or 0
	local yOffset = y or 0

	-- Validate icon exists
	local iconFormat = MHCT.iconTable[iconName] or MHCT.iconTable["default"]

	return format(iconFormat, iconSize, iconSize, xOffset, yOffset)
end

-- Optimized unit classification for ElvUI V14.0
MHCT.classificationType = function(unit)
	if not unit or UnitIsPlayer(unit) then
		return nil
	end

	local unitLevel = UnitEffectiveLevel(unit)
	local classification = UnitClassification(unit)

	-- Fast path for rare types
	if classification == "rare" or classification == "rareelite" then
		return classification
	end

	-- Boss detection
	if unitLevel == -1 or classification == "boss" or classification == "worldboss" then
		return "boss"
	end

	-- Elite+ detection (unit level exceeds max player level)
	if unitLevel > MAX_PLAYER_LEVEL_VALUE then
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

-- Format status text with icon (uses pre-cached formatted text for performance)
MHCT.statusFormatter = function(status, size, reverse)
	if not status then
		return nil
	end

	local iconSize = size or MHCT.DEFAULT_ICON_SIZE
	local iconName = STATUS_ICON_MAP[status]
	local formattedStatus = FORMATTED_STATUS_CACHE[status] -- O(1) lookup, no strupper() or format()
	local icon = MHCT.getFormattedIcon(iconName, iconSize)

	if reverse then
		return icon .. formattedStatus
	else
		return formattedStatus .. icon
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

-- Optimized health percent formatter for ElvUI V14.0
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

	local decimals = tonumber(decimalPlaces) or MHCT.DEFAULT_DECIMAL_PLACE
	local percent = (currentHp / maxHp) * 100

	-- Use cached format patterns for better performance
	local fmt = FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[decimals] or format("%%.%df", decimals)

	if showSign then
		return format(fmt .. "%%", percent)
	else
		return format(fmt, percent)
	end
end

-- Optimized health deficit formatter for ElvUI V14.0
MHCT.formatHealthDeficit = function(unit)
	if not unit then
		return ""
	end

	local currentHp = UnitHealth(unit)
	local maxHp = UnitHealthMax(unit)

	if currentHp == maxHp or maxHp == 0 then
		return ""
	end

	return format("-%s", E:ShortValue(maxHp - currentHp))
end

-------------------------------------
-- TAG REGISTRATION
-------------------------------------

-- Internal registry to track tag functions and events (needed for aliases in ElvUI 14.0+)
local tagRegistry = {}

-- Simple tag registration for ElvUI V14.0+
MHCT.registerTag = function(name, subCategory, description, events, func)
	local fullCategory = MHCT.TAG_CATEGORY_NAME .. " [" .. subCategory .. "]"

	E:AddTagInfo(name, fullCategory, description)
	E:AddTag(name, events, func)

	-- Store for alias creation (ElvUI 14.0+ doesn't expose tag methods)
	tagRegistry[name] = {
		func = func,
		events = events,
		category = fullCategory,
		description = description,
	}

	return name
end

-- Create tag alias for backwards compatibility (shares function reference, no duplication)
MHCT.registerTagAlias = function(oldName, newName)
	-- Get the existing tag from our internal registry
	local tagData = tagRegistry[newName]
	local tagInfo = E.TagInfo[newName]

	if tagData and tagInfo then
		-- Register alias with deprecation notice, using the same wrapped function
		E:AddTagInfo(
			oldName,
			tagInfo.category,
			tagInfo.description .. " (DEPRECATED - Use [" .. newName .. "] instead)"
		)
		-- Use the same wrapped function reference (no duplication)
		E:AddTag(oldName, tagData.events, tagData.func)

		-- Store alias in registry too (in case someone aliases an alias)
		tagRegistry[oldName] = tagData
		return oldName
	end

	-- If new tag doesn't exist, silently fail (developer error, should be caught during development)
	return nil
end

-------------------------------------
-- SLASH COMMANDS
-------------------------------------

SLASH_MHTAGS1 = "/mhtags"
SlashCmdList["MHTAGS"] = function(msg)
	local cmd = msg and msg:lower():trim() or ""

	if cmd == "debug" or cmd == "info" then
		-- Show debug/compatibility info
		local info = MHCT.debugInfo or {}
		print("|cff0388fc[ElvUI_mhTags]|r Debug Information:")
		print(format("  Addon Version: |cffffcc00%s|r", MHCT.ADDON_VERSION))
		print(format("  WoW Interface: |cffffcc00%d|r", info.wowVersion or 0))
		print(format("  ElvUI Version: |cffffcc00%.1f|r", info.elvuiVersion or 0))
		print(format("  WoW 12.0+: |cffffcc00%s|r", info.isWoW12 and "Yes" or "No"))
		print("|cff0388fc[12.0 API Availability]|r")
		print(format("  UnitHealthPercent: |cff%s%s|r", info.hasHealthPercent and "00ff00" or "ff0000", info.hasHealthPercent and "Available" or "Unavailable"))
		print(format("  UnitHealthMissing: |cff%s%s|r", info.hasHealthMissing and "00ff00" or "ff0000", info.hasHealthMissing and "Available" or "Unavailable"))
		print(format("  UnitPowerPercent: |cff%s%s|r", info.hasPowerPercent and "00ff00" or "ff0000", info.hasPowerPercent and "Available" or "Unavailable"))
		print(format("  UnitPowerMissing: |cff%s%s|r", info.hasPowerMissing and "00ff00" or "ff0000", info.hasPowerMissing and "Available" or "Unavailable"))
	elseif cmd == "help" then
		print("|cff0388fc[ElvUI_mhTags]|r Commands:")
		print("  |cffffcc00/mhtags|r - Show memory usage")
		print("  |cffffcc00/mhtags debug|r - Show version and API info")
		print("  |cffffcc00/mhtags help|r - Show this help")
	else
		-- Default: show memory usage
		UpdateAddOnMemoryUsage()
		local memoryUsage = GetAddOnMemoryUsage("ElvUI_mhTags")
		print(format("|cff0388fc[ElvUI_mhTags v%s]|r Memory: |cffffcc00%.2f KB|r", MHCT.ADDON_VERSION, memoryUsage))
	end
end
