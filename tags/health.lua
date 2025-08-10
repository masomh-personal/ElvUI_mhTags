-- ===================================================================================
-- UNIFIED HEALTH TAGS - Optimized and Consolidated
-- ===================================================================================
-- This file contains all health-related tags for ElvUI_mhTags
-- Tags are organized by category and follow DRY principles
-- All tags are performance-optimized with minimal memory allocation
-- ===================================================================================

local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references
local E = unpack(ElvUI)

-- Localize Lua functions
local format = string.format
local floor = math.floor
local tonumber = tonumber

-- Localize WoW API functions
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs

-- ===================================================================================
-- CONSTANTS
-- ===================================================================================

local HEALTH_SUBCATEGORY = "health"
local DEFAULT_DECIMAL_PLACE = MHCT.DEFAULT_DECIMAL_PLACE
local ABSORB_TEXT_COLOR = MHCT.ABSORB_TEXT_COLOR
local HEALTH_GRADIENT_RGB_TABLE = MHCT.HEALTH_GRADIENT_RGB

-- Common color constants
local WHITE_COLOR = "|cffFFFFFF"
local DEAD_OR_DC_COLOR = "|cffD6BFA6"
local COLOR_END = "|r"
local VERTICAL_SEPARATOR = " | "

-- Pre-built common format strings to reduce concatenation
local PERCENT_FORMAT = "%.1f%%"
local DEFICIT_FORMAT = "-%s"
local ABSORB_FORMAT_START = "|cff" .. ABSORB_TEXT_COLOR .. "("
local ABSORB_FORMAT_END = ")|r "

-- ===================================================================================
-- SHARED HELPER FUNCTIONS
-- ===================================================================================

-- Format health percentage with configurable decimal places
local function formatPercent(value, decimals)
	if decimals == 0 then
		return format("%.0f", value)
	elseif decimals == 1 then
		return format("%.1f", value)
	elseif decimals == 2 then
		return format("%.2f", value)
	else
		return format("%%.%df", decimals):format(value)
	end
end

-- Get health values and calculate percentage
local function getHealthData(unit)
	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)

	if maxHp == 0 then
		return 0, 0, 0
	end

	local percent = (currentHp / maxHp) * 100
	return currentHp, maxHp, percent
end

-- Format absorb shield if present
-- Optimized to use pre-built format strings
local function getAbsorbText(unit)
	local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
	if absorbAmount > 0 then
		return ABSORB_FORMAT_START .. E:ShortValue(absorbAmount) .. ABSORB_FORMAT_END
	end
	return ""
end

-- Get gradient color based on health percentage
-- Optimized with fast paths for common cases
local function getGradientColor(percent)
	-- Fast path: full health (very common)
	if percent >= 100 then
		return WHITE_COLOR
	end

	-- Fast path: dead or zero health
	if percent <= 0 then
		return HEALTH_GRADIENT_RGB_TABLE[0] or DEAD_OR_DC_COLOR
	end

	-- Standard lookup for everything else
	local index = floor(percent)
	return HEALTH_GRADIENT_RGB_TABLE[index] or WHITE_COLOR
end

-- ===================================================================================
-- SECTION 1: BASIC HEALTH DISPLAY
-- ===================================================================================
-- These tags show current health value with various formatting options

-- Current health value only (uses ElvUI's smart formatting)
MHCT.registerTag(
	"mh-health-current",
	HEALTH_SUBCATEGORY,
	"Shows current health value with smart formatting",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		local currentHp, maxHp = getHealthData(unit)
		return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
	end
)

-- Current health with absorb shield
MHCT.registerTag(
	"mh-health-current-absorb",
	HEALTH_SUBCATEGORY,
	"Shows current health with absorb shield in parentheses",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		local currentHp, maxHp = getHealthData(unit)
		local absorbText = getAbsorbText(unit)
		return absorbText .. E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
	end
)

-- ===================================================================================
-- SECTION 2: HEALTH PERCENTAGE
-- ===================================================================================
-- Tags that display health as a percentage with various options

-- Simple percentage with configurable decimals and status check
MHCT.registerTag(
	"mh-health-percent",
	HEALTH_SUBCATEGORY,
	"Shows health percentage with status check. Use {N} for decimal places",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp, percent = getHealthData(unit)

		-- Show max health value at full
		if currentHp == maxHp then
			return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		end

		local decimals = tonumber(args) or 1
		return formatPercent(percent, decimals) .. "%"
	end
)

-- Percentage without % sign
MHCT.registerTag(
	"mh-health-percent-nosign",
	HEALTH_SUBCATEGORY,
	"Shows health percentage without % sign. Use {N} for decimal places",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp, percent = getHealthData(unit)

		-- Show max health value at full
		if currentHp == maxHp then
			return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		end

		local decimals = tonumber(args) or 1
		return formatPercent(percent, decimals)
	end
)

-- ===================================================================================
-- SECTION 3: COMBINED HEALTH AND PERCENTAGE
-- ===================================================================================
-- Tags that show both current health and percentage in various formats

-- Current | Percent (shows both always)
MHCT.registerTag(
	"mh-health-current-percent",
	HEALTH_SUBCATEGORY,
	"Shows health as: 100k | 85%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp, percent = getHealthData(unit)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		local percentText = format(PERCENT_FORMAT, percent)

		return currentText .. VERTICAL_SEPARATOR .. percentText
	end
)

-- Percent | Current (shows both always)
MHCT.registerTag(
	"mh-health-percent-current",
	HEALTH_SUBCATEGORY,
	"Shows health as: 85% | 100k",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp, percent = getHealthData(unit)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		local percentText = format(PERCENT_FORMAT, percent)

		return percentText .. VERTICAL_SEPARATOR .. currentText
	end
)

-- Current | Percent (hides percent at full health)
MHCT.registerTag(
	"mh-health-current-percent-hidefull",
	HEALTH_SUBCATEGORY,
	"Shows health as: 100k | 85% but only 100k at full health",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp, percent = getHealthData(unit)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		if currentHp == maxHp then
			return currentText
		end

		local percentText = format(PERCENT_FORMAT, percent)
		return currentText .. VERTICAL_SEPARATOR .. percentText
	end
)

-- Percent | Current (hides percent at full health)
MHCT.registerTag(
	"mh-health-percent-current-hidefull",
	HEALTH_SUBCATEGORY,
	"Shows health as: 85% | 100k but only 100k at full health",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp, percent = getHealthData(unit)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		if currentHp == maxHp then
			return currentText
		end

		local percentText = format(PERCENT_FORMAT, percent)
		return percentText .. VERTICAL_SEPARATOR .. currentText
	end
)

-- Current | Percent with absorb shield
MHCT.registerTag(
	"mh-health-current-percent-absorb",
	HEALTH_SUBCATEGORY,
	"Shows (absorb) 100k | 85% with absorb shield when present",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp, percent = getHealthData(unit)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		local absorbText = getAbsorbText(unit)

		if currentHp == maxHp then
			return absorbText .. currentText
		end

		local percentText = format(PERCENT_FORMAT, percent)
		return absorbText .. currentText .. VERTICAL_SEPARATOR .. percentText
	end
)

-- ===================================================================================
-- SECTION 4: HEALTH DEFICIT
-- ===================================================================================
-- Tags that show missing health in various formats

-- Numeric deficit with status
MHCT.registerTag(
	"mh-health-deficit",
	HEALTH_SUBCATEGORY,
	"Shows missing health as -15k or status when dead/offline",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp = getHealthData(unit)
		if currentHp == maxHp then
			return ""
		end

		return format(DEFICIT_FORMAT, E:ShortValue(maxHp - currentHp))
	end
)

-- Numeric deficit without status check
MHCT.registerTag(
	"mh-health-deficit-nostatus",
	HEALTH_SUBCATEGORY,
	"Shows missing health as -15k (no status check)",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		local currentHp, maxHp = getHealthData(unit)
		if currentHp == maxHp then
			return ""
		end

		return format(DEFICIT_FORMAT, E:ShortValue(maxHp - currentHp))
	end
)

-- Percentage deficit with status
MHCT.registerTag(
	"mh-health-deficit-percent",
	HEALTH_SUBCATEGORY,
	"Shows missing health as -15% with status check. Use {N} for decimal places",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp, percent = getHealthData(unit)
		if currentHp == maxHp then
			return ""
		end

		local decimals = tonumber(args) or 1
		local deficit = 100 - percent
		return "-" .. formatPercent(deficit, decimals) .. "%"
	end
)

-- ===================================================================================
-- SECTION 5: COLORED HEALTH DISPLAYS
-- ===================================================================================
-- Tags that apply color gradients based on health percentage

-- Current | Percent with gradient coloring
MHCT.registerTag(
	"mh-health-current-percent-colored",
	HEALTH_SUBCATEGORY,
	"Shows health with full gradient coloring (red to yellow to green)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		local currentHp, maxHp, percent = getHealthData(unit)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		local absorbText = getAbsorbText(unit)

		-- White at full health
		if currentHp == maxHp then
			return absorbText .. WHITE_COLOR .. currentText .. COLOR_END
		end

		local percentText = format(PERCENT_FORMAT, percent)
		local result = currentText .. VERTICAL_SEPARATOR .. percentText
		local colorCode = getGradientColor(percent)

		return absorbText .. colorCode .. result .. COLOR_END
	end
)

-- Percent | Current with gradient coloring
MHCT.registerTag(
	"mh-health-percent-current-colored",
	HEALTH_SUBCATEGORY,
	"Shows health with full gradient coloring (red to yellow to green)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		local currentHp, maxHp, percent = getHealthData(unit)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		local absorbText = getAbsorbText(unit)

		-- White at full health
		if currentHp == maxHp then
			return absorbText .. WHITE_COLOR .. currentText .. COLOR_END
		end

		local percentText = format(PERCENT_FORMAT, percent)
		local result = percentText .. VERTICAL_SEPARATOR .. currentText
		local colorCode = getGradientColor(percent)

		return absorbText .. colorCode .. result .. COLOR_END
	end
)

-- Current value only with gradient coloring
MHCT.registerTag(
	"mh-health-current-colored",
	HEALTH_SUBCATEGORY,
	"Shows only current health value with gradient coloring",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		local currentHp, maxHp, percent = getHealthData(unit)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		local absorbText = getAbsorbText(unit)

		-- White at full health
		if currentHp == maxHp then
			return absorbText .. WHITE_COLOR .. currentText .. COLOR_END
		end

		local colorCode = getGradientColor(percent)
		return absorbText .. colorCode .. currentText .. COLOR_END
	end
)

-- Percentage only with gradient coloring
MHCT.registerTag(
	"mh-health-percent-colored",
	HEALTH_SUBCATEGORY,
	"Shows only health percentage with gradient coloring",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		local currentHp, maxHp, percent = getHealthData(unit)

		-- White at full health
		if currentHp == maxHp then
			return WHITE_COLOR .. "100%" .. COLOR_END
		end

		local percentText = format(PERCENT_FORMAT, percent)
		local colorCode = getGradientColor(percent)
		return colorCode .. percentText .. COLOR_END
	end
)

-- ===================================================================================
-- SECTION 6: HEALTH COLOR TAG
-- ===================================================================================
-- Tag that returns just the color code based on health percentage

MHCT.registerTag(
	"mh-healthcolor",
	HEALTH_SUBCATEGORY,
	"Returns color code based on health percentage for use with other tags",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		local currentHp, maxHp, percent = getHealthData(unit)

		if maxHp == 0 then
			return DEAD_OR_DC_COLOR
		end

		return getGradientColor(percent)
	end
)

-- ===================================================================================
-- SECTION 7: THROTTLED VARIANTS
-- ===================================================================================
-- Performance-optimized versions with configurable update rates
-- These are essential for raid frames with many units

-- Helper function to create throttled variants
local function createThrottledVariants()
	local throttleConfigs = {
		{ suffix = "-0.25", value = 0.25, desc = "0.25" },
		{ suffix = "-0.5", value = 0.5, desc = "0.5" },
		{ suffix = "-1.0", value = 1.0, desc = "1.0" },
		{ suffix = "-2.0", value = 2.0, desc = "2.0" },
	}

	-- List of tags that should have throttled variants
	local tagsToThrottle = {
		{
			base = "mh-health-current-percent",
			func = function(unit)
				local statusFormatted = MHCT.formatWithStatusCheck(unit)
				if statusFormatted then
					return statusFormatted
				end

				local currentHp, maxHp, percent = getHealthData(unit)
				local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
				local percentText = format(PERCENT_FORMAT, percent)

				return currentText .. VERTICAL_SEPARATOR .. percentText
			end,
		},
		{
			base = "mh-health-current-percent-hidefull",
			func = function(unit)
				local statusFormatted = MHCT.formatWithStatusCheck(unit)
				if statusFormatted then
					return statusFormatted
				end

				local currentHp, maxHp, percent = getHealthData(unit)
				local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

				if currentHp == maxHp then
					return currentText
				end

				local percentText = format(PERCENT_FORMAT, percent)
				return currentText .. VERTICAL_SEPARATOR .. percentText
			end,
		},
		{
			base = "mh-health-deficit",
			func = function(unit)
				local statusFormatted = MHCT.formatWithStatusCheck(unit)
				if statusFormatted then
					return statusFormatted
				end

				local currentHp, maxHp = getHealthData(unit)
				if currentHp == maxHp then
					return ""
				end

				return format(DEFICIT_FORMAT, E:ShortValue(maxHp - currentHp))
			end,
		},
		{
			base = "mh-health-current-percent-colored",
			func = function(unit)
				local currentHp, maxHp, percent = getHealthData(unit)
				local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
				local absorbText = getAbsorbText(unit)

				if currentHp == maxHp then
					return absorbText .. WHITE_COLOR .. currentText .. COLOR_END
				end

				local percentText = format(PERCENT_FORMAT, percent)
				local result = currentText .. VERTICAL_SEPARATOR .. percentText
				local colorCode = getGradientColor(percent)

				return absorbText .. colorCode .. result .. COLOR_END
			end,
		},
		{
			base = "mh-healthcolor",
			func = function(unit)
				local currentHp, maxHp, percent = getHealthData(unit)

				if maxHp == 0 then
					return DEAD_OR_DC_COLOR
				end

				return getGradientColor(percent)
			end,
		},
	}

	-- Create throttled versions for each tag
	for _, tagInfo in ipairs(tagsToThrottle) do
		for _, throttle in ipairs(throttleConfigs) do
			MHCT.registerThrottledTag(
				tagInfo.base .. throttle.suffix,
				HEALTH_SUBCATEGORY,
				format("Throttled version updating every %s seconds", throttle.desc),
				throttle.value,
				tagInfo.func
			)
		end
	end
end

-- Create all throttled variants
createThrottledVariants()

-- ===================================================================================
-- SECTION 8: LEGACY/COMPATIBILITY TAGS
-- ===================================================================================
-- These maintain backwards compatibility with old tag names
-- Consider these deprecated - use the new simplified names instead

MHCT.registerTag(
	"mh-health:current:percent:right",
	HEALTH_SUBCATEGORY,
	"DEPRECATED - Use [mh-health-current-percent] instead",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp, percent = getHealthData(unit)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		local percentText = format(PERCENT_FORMAT, percent)

		return currentText .. VERTICAL_SEPARATOR .. percentText
	end
)

MHCT.registerTag(
	"mh-health:current:percent:left",
	HEALTH_SUBCATEGORY,
	"DEPRECATED - Use [mh-health-percent-current] instead",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp, percent = getHealthData(unit)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		local percentText = format(PERCENT_FORMAT, percent)

		return percentText .. VERTICAL_SEPARATOR .. currentText
	end
)

MHCT.registerTag(
	"mh-health:current:percent:right-hidefull",
	HEALTH_SUBCATEGORY,
	"DEPRECATED - Use [mh-health-current-percent-hidefull] instead",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp, percent = getHealthData(unit)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		if currentHp == maxHp then
			return currentText
		end

		local percentText = format(PERCENT_FORMAT, percent)
		return currentText .. VERTICAL_SEPARATOR .. percentText
	end
)

MHCT.registerTag(
	"mh-health:current:percent:left-hidefull",
	HEALTH_SUBCATEGORY,
	"DEPRECATED - Use [mh-health-percent-current-hidefull] instead",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp, percent = getHealthData(unit)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		if currentHp == maxHp then
			return currentText
		end

		local percentText = format(PERCENT_FORMAT, percent)
		return percentText .. VERTICAL_SEPARATOR .. currentText
	end
)
