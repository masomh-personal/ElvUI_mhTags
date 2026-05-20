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
MHCT.ADDON_VERSION = "10"
MHCT.ADDON_NAME = "ElvUI_mhTags"

-------------------------------------
-- FUNCTION LOCALIZATION
-- Localizing all functions improves performance by avoiding global lookups
-------------------------------------
-- Lua functions
local format = string.format
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local gsub = string.gsub
local gmatch = string.gmatch
local sub = string.sub
local tinsert = table.insert
local concat = table.concat
local unpack = unpack
local strupper = strupper
local strtrim = strtrim

-- WoW API functions (only those used in core.lua)
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
local GetMaxPlayerLevel = GetMaxPlayerLevel
local UnitName = UnitName
local UnitPowerType = UnitPowerType
local IsInRaid = IsInRaid
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo

-------------------------------------
-- WOW 12.0+ API LOCALIZATION
-- This addon requires WoW 12.0 (Midnight) or later
-- These APIs are used directly without fallbacks
-------------------------------------
local UnitHealthPercent = UnitHealthPercent
local UnitPowerPercent = UnitPowerPercent
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local CreateColor = CreateColor
local CreateColorCurve = C_CurveUtil and C_CurveUtil.CreateColorCurve
local LuaCurveTypeLinear = Enum.LuaCurveType and Enum.LuaCurveType.Linear
-- AbbreviateNumbers is AllowedWhenTainted in 12.0+ and accepts secret values natively.
-- Guaranteed to exist since TOC floor is 120005.
local AbbreviateNumbers = AbbreviateNumbers
-- TruncateWhenZero (12.0.5+): returns nil when a value is zero, even for secret zeros.
-- Used to suppress absorb display when absorb is 0 but its value is restricted.
local TruncateWhenZero = C_StringUtil and C_StringUtil.TruncateWhenZero
local issecretvalue = issecretvalue

-- Cache max player level at load time (doesn't change during session)
local MAX_PLAYER_LEVEL_VALUE = GetMaxPlayerLevel()

-- ElvUI references - unpack once. Only E is shared with tag files (via MHCT.E);
-- L is kept local since it's only used here for status string keys.
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
-- Validates ElvUI version for WoW 12.0+
-------------------------------------
local function checkCompatibility()
	local minElvUIVersion = 15.0
	local currentElvUIVersion = tonumber(E.version) or 0

	-- ElvUI version check
	if currentElvUIVersion > 0 and currentElvUIVersion < minElvUIVersion then
		print(
			format(
				"|cffFF0000[ElvUI_mhTags Error]|r This addon requires ElvUI %.1f or higher for WoW 12.0.5 (Midnight). "
					.. "Current version: %.2f. Please update ElvUI.",
				minElvUIVersion,
				currentElvUIVersion
			)
		)
	end

	-- Debug info (shown with /mhtags debug)
	MHCT.debugInfo = {
		elvuiVersion = currentElvUIVersion,
	}
end

checkCompatibility()

-- Export E for tag modules (avoids re-unpacking ElvUI in each file)
MHCT.E = E

-------------------------------------
-- CONSTANTS
-------------------------------------
MHCT.TAG_CATEGORY_NAME = "|cff0388fcmh|r|cffccff33Tags|r"
MHCT.MAX_PLAYER_LEVEL = MAX_PLAYER_LEVEL_VALUE
MHCT.DEFAULT_ICON_SIZE = 14
MHCT.DEFAULT_TEXT_LENGTH = 28
MHCT.DEFAULT_DECIMAL_PLACE = 0

-- Fallback display for secret values (rated arena, RBGs, competitive content)
-- Displayed when health/power values are restricted by Blizzard's secret value system
MHCT.SECRET_VALUE_FALLBACK_TEXT = "---"

-- Shared color constants exported so tag files don't redefine them independently.
-- classification.lua, misc.lua, and core.lua all reference these.
MHCT.COLORS = {
	STATUS = "D6BFA6",
	BOSS   = "fc495e", -- light red
	RARE   = "fc49f3", -- light magenta
	ELITE  = "ffcc00", -- gold
}

-- Emerald palette (hex values match mh-color-emerald-* in tags/color.lua)
MHCT.EMERALD_HEX = {
	RED    = "C85050",
	YELLOW = "C8C850",
	GREEN  = "50C878",
}

-- Convert 6-char hex ("RRGGBB") to normalized RGB (0-1) for ColorCurve stop definitions.
local function gradientStopFromHex(hex)
	return tonumber(sub(hex, 1, 2), 16) / 255,
		tonumber(sub(hex, 3, 4), 16) / 255,
		tonumber(sub(hex, 5, 6), 16) / 255
end

-- Health gradient: emerald-red (0%) -> emerald-yellow (50%) -> emerald-green (100%)
do
	local lr, lg, lb = gradientStopFromHex(MHCT.EMERALD_HEX.RED)
	local mr, mg, mb = gradientStopFromHex(MHCT.EMERALD_HEX.YELLOW)
	local hr, hg, hb = gradientStopFromHex(MHCT.EMERALD_HEX.GREEN)
	MHCT.HEALTH_GRADIENT_STOPS = {
		LOW  = { lr, lg, lb },
		MID  = { mr, mg, mb },
		HIGH = { hr, hg, hb },
	}
end

-- Local aliases for use within core.lua
local STATUS_COLOR = MHCT.COLORS.STATUS
local BOSS_COLOR   = MHCT.COLORS.BOSS
local RARE_COLOR   = MHCT.COLORS.RARE

-- Common symbols
local ELITE_SYMBOL = "+"
local ELITE_PLUS_SYMBOL = "◆"
local BOSS_SYMBOL = "??"

-- Pre-cached format patterns for percent formatting (0-3 decimals covers all use cases)
-- Exported for use by tag files to avoid duplication
MHCT.PERCENT_FORMATS = {
	[0] = "%.0f",
	[1] = "%.1f",
	[2] = "%.2f",
	[3] = "%.3f",
}

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

-- Pre-cached icon strings at default size (most common use case)
-- Avoids format() call in hot path for common icons
local CACHED_ICONS = {}
for iconName, iconFormat in pairs(MHCT.iconTable) do
	CACHED_ICONS[iconName] = format(iconFormat, MHCT.DEFAULT_ICON_SIZE, MHCT.DEFAULT_ICON_SIZE, 0, 0)
end
MHCT.CACHED_ICONS = CACHED_ICONS

-------------------------------------
-- SECRET VALUE UTILITIES (WoW 12.0+ Midnight)
-- These functions handle "secret values" that cannot be compared or used
-- in arithmetic operations. Common on nameplates and in competitive PvP.
-------------------------------------

-- Localize pcall for performance
local pcall = pcall

-- Safe boolean API call for WoW 12.x secret booleans.
-- Returns: true, false, or "secret" (for secret/nil cases).
--
-- In Midnight (12.0+), boolean unit APIs (UnitIsAFK, UnitIsDead, etc.) return secret
-- values in restricted contexts rather than throwing. issecretvalue() is the correct
-- detection path — pcall() is unnecessary overhead here.
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

-- CurveConstants.ScaleTo100 (Midnight) returns percent values in 0-100 directly,
-- bypassing the legacy 0-1 multiplication. Resolved once at load (see GetHealthPercent).
local CURVE_SCALE_TO_100 = CurveConstants and CurveConstants.ScaleTo100 or nil

-- Get health percent in 0-100 range, secret-safe.
-- Returns: percent (0-100), isSecret (boolean)
--
-- CURVE_SCALE_TO_100 is checked once at load time so each call avoids a runtime branch.
-- CurveConstants.ScaleTo100 gives 0-100 output directly; the legacy path scales *100.
if CURVE_SCALE_TO_100 then
	MHCT.GetHealthPercent = function(unit)
		if not unit then return nil, false end
		local ok, pct = pcall(UnitHealthPercent, unit, false, CURVE_SCALE_TO_100)
		if not ok or pct == nil then return nil, false end
		if issecretvalue(pct) then return pct, true end
		return pct, false
	end
else
	-- Legacy: UnitHealthPercent returns 0-1 range; scale to 0-100
	MHCT.GetHealthPercent = function(unit)
		if not unit then return nil, false end
		local ok, pct = pcall(UnitHealthPercent, unit)
		if not ok or pct == nil then return nil, false end
		if issecretvalue(pct) then return pct, true end
		return pct * 100, false
	end
end

-- Get power percent in 0-100 range, secret-safe.
-- Returns: percent (0-100), isSecret (boolean)
-- powerType: optional, defaults to unit's primary power type
--
-- Same load-time curve-path split as GetHealthPercent — removes per-call branching.
if CURVE_SCALE_TO_100 then
	MHCT.GetPowerPercent = function(unit, powerType)
		if not unit then return nil, false end
		if not powerType then powerType = UnitPowerType(unit) end
		local ok, pct = pcall(UnitPowerPercent, unit, powerType, false, CURVE_SCALE_TO_100)
		if not ok or pct == nil then return nil, false end
		if issecretvalue(pct) then return pct, true end
		return pct, false
	end
else
	-- Legacy: UnitPowerPercent returns 0-1 range; scale to 0-100
	MHCT.GetPowerPercent = function(unit, powerType)
		if not unit then return nil, false end
		if not powerType then powerType = UnitPowerType(unit) end
		local ok, pct = pcall(UnitPowerPercent, unit, powerType)
		if not ok or pct == nil then return nil, false end
		if issecretvalue(pct) then return pct, true end
		return pct * 100, false
	end
end

-- Format a number with K/M/B suffix, secret-safe.
-- AbbreviateNumbers is AllowedWhenTainted in 12.0+ (warcraft.wiki.gg/wiki/API_AbbreviateNumbers)
-- and accepts secret values natively — no pcall, no legacy fallback needed.
MHCT.FormatLargeNumber = function(value)
	if value == nil then
		return MHCT.SECRET_VALUE_FALLBACK_TEXT
	end
	return AbbreviateNumbers(value)
end

-- Format percent value using cached patterns
-- percentValue: 0-100 range, decimals: 0-3, includeSign: append %
MHCT.FormatPercent = function(percentValue, decimals, includeSign)
	if percentValue == nil then
		return MHCT.SECRET_VALUE_FALLBACK_TEXT
	end
	decimals = decimals or 0
	-- Clamp to cached range
	if decimals < 0 then
		decimals = 0
	end
	if decimals > 3 then
		decimals = 3
	end

	local pattern = MHCT.PERCENT_FORMATS[decimals]
	local result = format(pattern, percentValue)

	if includeSign == nil or includeSign then
		return result .. "%"
	end
	return result
end

-- Shared absorb text helper, used by health.lua and misc.lua.
-- withTrailingSpace: true for inline use before a health value (e.g. "(25k) 100k").
--
-- Zero-detection strategy:
--   Non-secret: direct comparison (absorbAmount <= 0)
--   Secret:     C_StringUtil.TruncateWhenZero (12.0.5+) returns nil for secret zeros,
--               allowing us to suppress "(0)" that previously leaked through.
--               Without TruncateWhenZero (shouldn't happen given TOC 120005), we fall
--               through and show the value — worst case is a visible "(0)".
MHCT.getAbsorbText = function(unit, withTrailingSpace)
	if not unit then return "" end

	local absorbAmount = UnitGetTotalAbsorbs(unit)

	if not issecretvalue(absorbAmount) then
		-- Non-secret: nil or zero/negative means no absorb to display
		if absorbAmount == nil or absorbAmount <= 0 then return "" end
	else
		-- Secret value: can't compare directly, but TruncateWhenZero handles secret zeros
		if TruncateWhenZero and not TruncateWhenZero(absorbAmount) then return "" end
	end

	local result = MHCT.FormatLargeNumber(absorbAmount)
	if result == nil then return "" end

	local text = "(" .. result .. ")"
	return withTrailingSpace and (text .. " ") or text
end

-- Build a ColorCurveObject from HEALTH_GRADIENT_STOPS (0%, 50%, 100%).
-- Midnight secret values block numeric percent + table lookup for text coloring, but
-- UnitHealthPercent(unit, false, colorCurve) evaluates the gradient on the C side and
-- returns a ColorMixin safe for GenerateHexColor(). See ColorCurveObject on warcraft.wiki.
local HEALTH_COLOR_CURVE
if CreateColorCurve and CreateColor and LuaCurveTypeLinear then
	HEALTH_COLOR_CURVE = CreateColorCurve()
	HEALTH_COLOR_CURVE:SetType(LuaCurveTypeLinear)
	local lr, lg, lb = unpack(MHCT.HEALTH_GRADIENT_STOPS.LOW)
	local mr, mg, mb = unpack(MHCT.HEALTH_GRADIENT_STOPS.MID)
	local hr, hg, hb = unpack(MHCT.HEALTH_GRADIENT_STOPS.HIGH)
	HEALTH_COLOR_CURVE:AddPoint(0.0, CreateColor(lr, lg, lb))
	HEALTH_COLOR_CURVE:AddPoint(0.5, CreateColor(mr, mg, mb))
	HEALTH_COLOR_CURVE:AddPoint(1.0, CreateColor(hr, hg, hb))
end
MHCT.HEALTH_COLOR_CURVE = HEALTH_COLOR_CURVE

-- Returns opening color escape "|cffRRGGBB" for the unit's current health gradient color.
-- nil when the curve is unavailable or evaluation fails (caller should use fallback).
MHCT.getHealthGradientColorPrefix = function(unit)
	if not unit or not HEALTH_COLOR_CURVE then return nil end
	local ok, color = pcall(UnitHealthPercent, unit, false, HEALTH_COLOR_CURVE)
	if not ok or not color then return nil end
	return "|c" .. color:GenerateHexColor()
end

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

-- Returns true when both player and unit are confirmed (non-secret, non-nil) max level.
-- Centralizes the "hide at max level" comparison used by mh-smartlevel,
-- mh-diff-level-hide, and mh-classification-name-level-smart.
-- Returns false on any uncertainty (secret values, nil, mismatch) — the safe choice
-- since a false negative just shows the level rather than hiding it.
MHCT.isAtMaxLevelTogether = function(unit)
	if not unit then return false end
	local unitLevel = UnitEffectiveLevel(unit)
	if unitLevel == nil or issecretvalue(unitLevel) then return false end
	local playerLevel = UnitEffectiveLevel("player")
	if playerLevel == nil or issecretvalue(playerLevel) then return false end
	return playerLevel == MAX_PLAYER_LEVEL_VALUE and unitLevel == MAX_PLAYER_LEVEL_VALUE
end

-- Returns (name, isSecret).
-- Secret names can be passed to FontString for display but cannot be transformed
-- (strupper, sub, #len check, etc. all break on secret strings in 12.0+).
MHCT.getUnitNameSafe = function(unit)
	if not unit then return nil, false end
	local name = UnitName(unit)
	if issecretvalue(name) then return name, true end
	if name == nil or name == "" then return nil, false end
	return name, false
end

-- Returns an UPPERCASE + length-capped name ready for display, or the raw secret name,
-- or nil when the unit has no name. Centralizes the secret/nil guard that name.lua
-- and combined.lua previously duplicated independently.
MHCT.getFormattedUnitName = function(unit, length)
	local name, isSecret = MHCT.getUnitNameSafe(unit)
	if name == nil then return nil end
	if isSecret then return name end
	return E:ShortenString(strupper(name), length or MHCT.DEFAULT_TEXT_LENGTH)
end

-- Resolves the unit's display status (AFK, DND, Dead, Ghost, Offline) using
-- secret-safe boolean reads. Returns the localized string or nil when none apply.
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

	-- Only override tags with death when death is confirmed.
	-- Any secret/unknown state should fall through so health still shows.
	local deadState = getSafeBooleanState(UnitIsDead, unit)
	local feignState = getSafeBooleanState(UnitIsFeignDeath, unit)
	if deadState == true and feignState == false then
		return L["Dead"]
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

-- Get formatted icon with size and offset
-- Uses pre-cached strings when using default size and no offset (common case)
MHCT.getFormattedIcon = function(name, size, x, y)
	local iconName = name or "default"
	local defaultSize = MHCT.DEFAULT_ICON_SIZE

	-- Fast path: use cached icon for default size with no offset
	if (not size or size == defaultSize) and (not x or x == 0) and (not y or y == 0) then
		return CACHED_ICONS[iconName] or CACHED_ICONS["default"]
	end

	-- Slow path: custom size or offset requires format()
	local iconFormat = MHCT.iconTable[iconName] or MHCT.iconTable["default"]
	return format(iconFormat, size or defaultSize, size or defaultSize, x or 0, y or 0)
end

-- Returns the unit's classification key ("boss", "eliteplus", "elite", "rareelite",
-- "rare", or the raw classification string) or nil for players / unresolvable units.
-- All inputs are secret-checked since UnitClassification and UnitEffectiveLevel can
-- both return secrets in restricted contexts.
MHCT.classificationType = function(unit)
	if not unit then
		return nil
	end
	local isPlayerState = getSafeBooleanState(UnitIsPlayer, unit)
	if isPlayerState == true or isPlayerState == "secret" then
		return nil
	end

	local unitLevel = UnitEffectiveLevel(unit)
	local classification = UnitClassification(unit)
	if issecretvalue(unitLevel) or issecretvalue(classification) or classification == nil then
		return nil
	end

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
	if not unit then
		return ""
	end
	if issecretvalue(unitLevel) or unitLevel == nil then
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
	if not formattedStatus then
		formattedStatus = format("|cff%s%s|r", STATUS_COLOR, strupper(tostring(status)))
	end

	if not iconName then
		return formattedStatus
	end

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

-- Append raid group number to formatted name when in raid (e.g. "NAME" -> "NAME |cff00FFFF(3)|r")
-- Shared by mh-name-caps-with-raid-group and mh-classification-name-level-raid-group
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
	if name == nil then
		return formattedName
	end
	if not IsInRaid() then
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

-------------------------------------
-- TAG REGISTRATION
-------------------------------------

-- Simple tag registration for ElvUI 15.0+
MHCT.registerTag = function(name, subCategory, description, events, func)
	local fullCategory = MHCT.TAG_CATEGORY_NAME .. " [" .. subCategory .. "]"

	E:AddTagInfo(name, fullCategory, description)
	E:AddTag(name, events, func)

	return name
end

-------------------------------------
-- SLASH COMMANDS
-------------------------------------

SLASH_MHTAGS1 = "/mhtags"
SlashCmdList["MHTAGS"] = function(msg)
	local cmd = msg and strtrim(msg:lower()) or ""

	if cmd == "debug" or cmd == "info" then
		-- Show debug/compatibility info
		local info = MHCT.debugInfo or {}
		print("|cff0388fc[ElvUI_mhTags]|r Debug Information:")
		print(format("  Addon Version: |cffffcc00%s|r", MHCT.ADDON_VERSION))
		print(format("  ElvUI Version: |cffffcc00%.2f|r", info.elvuiVersion or 0))
		print("  Target WoW Version: |cffffcc0012.0.5+ (Midnight)|r")
	elseif cmd == "help" then
		print("|cff0388fc[ElvUI_mhTags]|r Commands:")
		print("  |cffffcc00/mhtags|r - Show memory usage")
		print("  |cffffcc00/mhtags debug|r - Show version info")
		print("  |cffffcc00/mhtags help|r - Show this help")
	else
		-- Default: show memory usage
		UpdateAddOnMemoryUsage()
		local memoryUsage = GetAddOnMemoryUsage("ElvUI_mhTags")
		print(format("|cff0388fc[ElvUI_mhTags v%s]|r Memory: |cffffcc00%.2f KB|r", MHCT.ADDON_VERSION, memoryUsage))
	end
end
