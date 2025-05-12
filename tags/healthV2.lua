-- ===================================================================================
-- VERSION 2.0 of health related tags. Focusing on efficiency for high CPU Usage (raids, etc)
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references directly
local E = unpack(ElvUI)

-- Localize WoW API functions directly
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs

-- Localize Lua functions directly
local format = string.format
local floor = math.floor
local tonumber = tonumber

-- Set the category name for all v2 health tags
local HEALTH_V2_SUBCATEGORY = "health-v2"

-- ===================================================================================
-- HELPER FUNCTIONS - Efficient direct string formatting
-- ===================================================================================

-- Efficiently format health text with direct string concatenation
local function formatHealthText(unit, isPercentFirst)
	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)

	-- Early return for full health with no absorbs (most common case)
	local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
	if currentHp == maxHp and absorbAmount == 0 then
		return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
	end

	-- Get formatted current health
	local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	-- Format with absorb info if present
	local absorbText = ""
	if absorbAmount > 0 then
		absorbText = format("|cff%s(%s)|r ", MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
	end

	-- Add percent text if not at full health
	if currentHp < maxHp then
		local percentText = format("%.1f%%", (currentHp / maxHp) * 100)

		if isPercentFirst then
			return absorbText .. percentText .. " | " .. currentText
		else
			return absorbText .. currentText .. " | " .. percentText
		end
	end

	-- Just return current health for full health
	return absorbText .. currentText
end

-- Format health percent with status check
local function formatHealthPercentWithStatus(unit, decimalPlaces)
	-- First check for status
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)

	-- Handle full health
	if currentHp == maxHp then
		-- Full health, just return formatted current health
		return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
	end

	-- Calculate percentage with configured decimal places
	local decimals = tonumber(decimalPlaces) or 1
	local formatStr = format("%%.%sf%%%%", decimals)
	return format(formatStr, (currentHp / maxHp) * 100)
end

-- Format health deficit with status check
local function formatHealthDeficitWithStatus(unit)
	-- First check for status
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	local currentHp = UnitHealth(unit)
	local maxHp = UnitHealthMax(unit)

	-- Only show deficit if not at full health
	if currentHp < maxHp then
		return format("-%s", E:ShortValue(maxHp - currentHp))
	end

	return ""
end

-- Format minimal health deficit (no minus sign)
local function formatMinimalHealthDeficit(unit)
	-- Check status first
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	-- Minimal deficit (no minus sign)
	local currentHp = UnitHealth(unit)
	local maxHp = UnitHealthMax(unit)

	if currentHp < maxHp then
		return E:ShortValue(maxHp - currentHp)
	end

	return ""
end

-- Format health for hide-percent-at-full-health mode
local function formatHealthHideFullPercent(unit, isPercentFirst)
	-- Check for status first
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)

	-- Get formatted current health
	local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	-- If health is full, just return current health value
	if currentHp == maxHp then
		return currentText
	end

	-- Calculate percentage since health isn't full
	local percentText = format("%.1f%%", (currentHp / maxHp) * 100)

	-- Format in requested order
	if isPercentFirst then
		return percentText .. " | " .. currentText
	else
		return currentText .. " | " .. percentText
	end
end

-- Format health with low health coloring
local function formatHealthWithLowHealthColor(unit, isPercentFirst, threshold)
	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)
	local healthPercent = (currentHp / maxHp) * 100

	-- Check if health is below threshold
	local lowHealthThreshold = threshold or 20 -- Default to 20%
	local isLowHealth = healthPercent <= lowHealthThreshold

	-- Get formatted current health
	local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	-- Handle absorb information if present
	local absorbText = ""
	local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
	if absorbAmount > 0 then
		absorbText = format("|cff%s(%s)|r ", MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
	end

	-- Calculate percentage if not at full health
	local percentText
	if currentHp < maxHp then
		percentText = format("%.1f%%", healthPercent)
	else
		return absorbText .. currentText -- Just return current health at full health
	end

	-- Format with color if health is low
	local result
	if isPercentFirst then
		result = percentText .. " | " .. currentText
	else
		result = currentText .. " | " .. percentText
	end

	-- Apply color for low health
	if isLowHealth then
		local colorCode = MHCT.HEALTH_GRADIENT_RGB[floor(healthPercent)] or "|cffFF0000"
		return absorbText .. colorCode .. result .. "|r"
	else
		return absorbText .. result
	end
end

-- ===================================================================================
-- HEALTH PERCENT WITH STATUS - Multiple update frequencies
-- ===================================================================================

-- Health percent with status tags (various update rates)
MHCT.registerThrottledTag(
	"mh-health-percent:status-0.25",
	HEALTH_V2_SUBCATEGORY,
	"Health percent with status @ 0.25s update interval",
	MHCT.THROTTLES.QUARTER,
	function(unit, _, args)
		return formatHealthPercentWithStatus(unit, args)
	end
)

MHCT.registerThrottledTag(
	"mh-health-percent:status-0.5",
	HEALTH_V2_SUBCATEGORY,
	"Health percent with status @ 0.5s update interval",
	MHCT.THROTTLES.HALF,
	function(unit, _, args)
		return formatHealthPercentWithStatus(unit, args)
	end
)

MHCT.registerThrottledTag(
	"mh-health-percent:status-1.0",
	HEALTH_V2_SUBCATEGORY,
	"Health percent with status @ 1.0s update interval",
	MHCT.THROTTLES.ONE,
	function(unit, _, args)
		return formatHealthPercentWithStatus(unit, args)
	end
)

MHCT.registerThrottledTag(
	"mh-health-percent:status-2.0",
	HEALTH_V2_SUBCATEGORY,
	"Health percent with status @ 2.0s update interval",
	MHCT.THROTTLES.TWO,
	function(unit, _, args)
		return formatHealthPercentWithStatus(unit, args)
	end
)

-- Configurable health percent (custom decimals with multi-throttle support)
MHCT.registerMultiThrottledTag(
	"mh-health-percent:status-configurable",
	HEALTH_V2_SUBCATEGORY,
	"Health percent with status and configurable decimal places, updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit, _, args)
		return formatHealthPercentWithStatus(unit, args)
	end
)

-- ===================================================================================
-- HEALTH DEFICIT WITH STATUS - Multiple update frequencies
-- ===================================================================================

-- Health deficit with status tags (various update rates)
MHCT.registerThrottledTag(
	"mh-health-deficit:status-0.25",
	HEALTH_V2_SUBCATEGORY,
	"Health deficit with status @ 0.25s update interval",
	MHCT.THROTTLES.QUARTER,
	function(unit)
		return formatHealthDeficitWithStatus(unit)
	end
)

MHCT.registerThrottledTag(
	"mh-health-deficit:status-0.5",
	HEALTH_V2_SUBCATEGORY,
	"Health deficit with status @ 0.5s update interval",
	MHCT.THROTTLES.HALF,
	function(unit)
		return formatHealthDeficitWithStatus(unit)
	end
)

MHCT.registerThrottledTag(
	"mh-health-deficit:status-1.0",
	HEALTH_V2_SUBCATEGORY,
	"Health deficit with status @ 1.0s update interval",
	MHCT.THROTTLES.ONE,
	function(unit)
		return formatHealthDeficitWithStatus(unit)
	end
)

MHCT.registerThrottledTag(
	"mh-health-deficit:status-2.0",
	HEALTH_V2_SUBCATEGORY,
	"Health deficit with status @ 2.0s update interval",
	MHCT.THROTTLES.TWO,
	function(unit)
		return formatHealthDeficitWithStatus(unit)
	end
)

-- Minimal health deficit tags (no minus sign, various update rates)
MHCT.registerThrottledTag(
	"mh-health-deficit:minimal-0.25",
	HEALTH_V2_SUBCATEGORY,
	"Minimal health deficit display @ 0.25s update interval - no minus sign",
	MHCT.THROTTLES.QUARTER,
	function(unit)
		return formatMinimalHealthDeficit(unit)
	end
)

MHCT.registerThrottledTag(
	"mh-health-deficit:minimal-0.5",
	HEALTH_V2_SUBCATEGORY,
	"Minimal health deficit display @ 0.5s update interval - no minus sign",
	MHCT.THROTTLES.HALF,
	function(unit)
		return formatMinimalHealthDeficit(unit)
	end
)

MHCT.registerThrottledTag(
	"mh-health-deficit:minimal-1.0",
	HEALTH_V2_SUBCATEGORY,
	"Minimal health deficit display @ 1.0s update interval - no minus sign",
	MHCT.THROTTLES.ONE,
	function(unit)
		return formatMinimalHealthDeficit(unit)
	end
)

MHCT.registerThrottledTag(
	"mh-health-deficit:minimal-2.0",
	HEALTH_V2_SUBCATEGORY,
	"Minimal health deficit display @ 2.0s update interval - no minus sign",
	MHCT.THROTTLES.TWO,
	function(unit)
		return formatMinimalHealthDeficit(unit)
	end
)

-- ===================================================================================
-- HIDE PERCENT AT FULL HEALTH TAGS - Shows percent only when health isn't full
-- ===================================================================================

-- Current | Percent (hides percent at full)
MHCT.registerTag(
	"mh-health-current-percent-hidefull",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 100k | 85% but hides percent at full health",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatHealthHideFullPercent(unit, false) -- false = current first
	end
)

-- Percent | Current (hides percent at full)
MHCT.registerTag(
	"mh-health-percent-current-hidefull",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 85% | 100k but hides percent at full health",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatHealthHideFullPercent(unit, true) -- true = percent first
	end
)

-- BACKWARDS compatibility aliases
MHCT.registerTag(
	"mh-health:current:percent:right-hidefull",
	HEALTH_V2_SUBCATEGORY,
	"Alias for mh-health-current-percent-hidefull (V3 version)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatHealthHideFullPercent(unit, false)
	end
)

MHCT.registerTag(
	"mh-health:current:percent:left-hidefull",
	HEALTH_V2_SUBCATEGORY,
	"Alias for mh-health-percent-current-hidefull (V3 version)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatHealthHideFullPercent(unit, true)
	end
)

-- Add throttled versions of hide-full tags
MHCT.registerMultiThrottledTag(
	"mh-health-current-percent-hidefull",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 100k | 85% (hides percent at full), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatHealthHideFullPercent(unit, false)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health-percent-current-hidefull",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 85% | 100k (hides percent at full), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatHealthHideFullPercent(unit, true)
	end
)

-- ===================================================================================
-- LOW HEALTH COLORED VERSION - Direct string concatenation
-- ===================================================================================

-- Current | Percent with low health coloring
MHCT.registerTag(
	"mh-health-current-percent:low-health-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 100k | 85% with color gradient for health below 20% (NO STATUS)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit, _, args)
		local threshold = tonumber(args) or 20 -- Default to 20%, override with tag args
		return formatHealthWithLowHealthColor(unit, false, threshold) -- false = current first
	end
)

-- Percent | Current with low health coloring
MHCT.registerTag(
	"mh-health-percent-current:low-health-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 85% | 100k with color gradient for health below 20% (NO STATUS)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit, _, args)
		local threshold = tonumber(args) or 20 -- Default to 20%, override with tag args
		return formatHealthWithLowHealthColor(unit, true, threshold) -- true = percent first
	end
)

-- Low health colored versions with throttling
MHCT.registerMultiThrottledTag(
	"mh-health-current-percent:low-health-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health with color at low health (current | percent), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit, _, args)
		local threshold = tonumber(args) or 20
		return formatHealthWithLowHealthColor(unit, false, threshold)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health-percent-current:low-health-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health with color at low health (percent | current), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit, _, args)
		local threshold = tonumber(args) or 20
		return formatHealthWithLowHealthColor(unit, true, threshold)
	end
)

-- ===================================================================================
-- GRADIENT COLORED HEALTH - Full range coloring (0-100%)
-- ===================================================================================

-- Create an optimized health formatter with full gradient coloring (only when below 100%)
local WHITE_COLOR = "|cffFFFFFF"
local function formatHealthWithFullGradient(unit, isPercentFirst)
	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)

	-- Early return for division by zero
	if maxHp == 0 then
		return ""
	end

	-- Handle absorb information if present
	local absorbText = ""
	local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
	if absorbAmount > 0 then
		absorbText = format("|cff%s(%s)|r ", MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
	end

	-- Special case: At full health, just show current value (which is max)
	if currentHp == maxHp then
		local fullHealthText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		return absorbText .. WHITE_COLOR .. fullHealthText .. "|r"
	end

	-- For non-full health, calculate percentage and format display
	local healthPercent = (currentHp / maxHp) * 100
	local percentText = format("%.1f%%", healthPercent)
	local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	-- Format in requested order
	local contentText
	if isPercentFirst then
		contentText = percentText .. " | " .. currentText
	else
		contentText = currentText .. " | " .. percentText
	end

	-- Apply gradient color for non-full health
	local roundedPercent = floor(healthPercent)
	local colorCode = MHCT.HEALTH_GRADIENT_RGB[roundedPercent] or WHITE_COLOR
	return absorbText .. colorCode .. contentText .. "|r"
end

-- Current | Percent with full gradient coloring
MHCT.registerTag(
	"mh-health-current-percent:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 100k | 85% with full color gradient from 0-100% (red to yellow to green)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		return formatHealthWithFullGradient(unit, false) -- false = current first
	end
)

-- Percent | Current with full gradient coloring
MHCT.registerTag(
	"mh-health-percent-current:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 85% | 100k with full color gradient from 0-100% (red to yellow to green)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		return formatHealthWithFullGradient(unit, true) -- true = percent first
	end
)

-- Add throttled versions for better performance in raids
MHCT.registerMultiThrottledTag(
	"mh-health-current-percent:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health with full gradient coloring (current | percent), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatHealthWithFullGradient(unit, false)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health-percent-current:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health with full gradient coloring (percent | current), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatHealthWithFullGradient(unit, true)
	end
)

-- Add simple versions that only show health value (no percent)
MHCT.registerTag(
	"mh-health-current:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows only current health value with full color gradient from 0-100%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)

		if maxHp == 0 then
			return ""
		end

		local healthPercent = (currentHp / maxHp) * 100
		local roundedPercent = floor(healthPercent)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		-- Apply gradient color
		local colorCode = MHCT.HEALTH_GRADIENT_RGB[roundedPercent] or "|cffFFFFFF"
		return colorCode .. currentText .. "|r"
	end
)

-- Add percent-only version with gradient coloring
MHCT.registerTag(
	"mh-health-percent:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows only health percentage with full color gradient from 0-100%",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)

		if maxHp == 0 then
			return ""
		end

		local healthPercent = (currentHp / maxHp) * 100
		local roundedPercent = floor(healthPercent)
		local percentText = format("%.1f%%", healthPercent)

		-- Apply gradient color
		local colorCode = MHCT.HEALTH_GRADIENT_RGB[roundedPercent] or "|cffFFFFFF"
		return colorCode .. percentText .. "|r"
	end
)

-- ===================================================================================
-- HEALTH COLOR TAGS
-- ===================================================================================

-- Health color gradient tag - optimized version
local DEAD_OR_DC_COLOR = "|cffD6BFA6"
MHCT.registerTag(
	"mh-healthcolor",
	HEALTH_V2_SUBCATEGORY,
	"Similar color tag to base ElvUI, but with brighter and high contrast gradient",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		-- Direct health calculation without status checks
		local currentHp = UnitHealth(unit)
		local maxHp = UnitHealthMax(unit)

		-- Early return for zero max health (prevents division by zero)
		if maxHp == 0 then
			return DEAD_OR_DC_COLOR -- Default
		end

		-- Calculate percentage and get the color directly
		local healthPercent = (currentHp / maxHp) * 100
		local index = floor(healthPercent)

		-- Direct lookup without conditional checks
		return MHCT.HEALTH_GRADIENT_RGB[index] or DEAD_OR_DC_COLOR
	end
)
