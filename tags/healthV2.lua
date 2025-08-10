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

-- Localize gradient table
local HEALTH_GRADIENT_RGB_TABLE = MHCT.HEALTH_GRADIENT_RGB

-- Set the category name for all v2 health tags
local HEALTH_V2_SUBCATEGORY = "health-v2"

-- Common color constants - cached for performance
local WHITE_COLOR = "|cffFFFFFF"
local DEAD_OR_DC_COLOR = "|cffD6BFA6"
local COLOR_END = "|r"
local VERTICAL_SEPARATOR = " | "

-- Pre-computed format strings for frequent operations
local PERCENT_FORMAT = "%.1f%%"
local ABSORB_PREFIX_FORMAT = "|cff%s(%s)|r "
local COMBINED_FORMAT_LEFT = "%s" .. VERTICAL_SEPARATOR .. "%s" -- "percent | current"
local COMBINED_FORMAT_RIGHT = "%s" .. VERTICAL_SEPARATOR .. "%s" -- "current | percent"

-- Pre-allocate variables to reduce memory allocation
local currentHp, maxHp, healthPercent, roundedPercent, absorbAmount
local statusFormatted, currentText, percentText, result, colorCode, absorbText

-- ===================================================================================
-- HELPER FUNCTIONS - Efficient direct string formatting
-- ===================================================================================

-- Format health percent with status check - optimized for common case first
local function formatHealthPercentWithStatus(unit, decimalPlaces)
	maxHp = UnitHealthMax(unit)
	currentHp = UnitHealth(unit)

	-- Guard against zero max health and prioritize status display
	if maxHp == 0 then
		statusFormatted = MHCT.formatWithStatusCheck(unit)
		return statusFormatted or ""
	end

	-- Check for status first (offline/dead/ghost/afk/dnd)
	statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	-- Always return percentage for this tag (even at full health)
	local decimals = tonumber(decimalPlaces) or 1
	local formatPattern = MHCT.FORMAT_PATTERNS.DECIMAL_WITH_PERCENT[decimals] or format("%%.%sf%%%%", decimals)
	return format(formatPattern, (currentHp / maxHp) * 100)
end

-- Format health deficit with status check - OPTIMIZED
local function formatHealthDeficitWithStatus(unit)
	currentHp = UnitHealth(unit)
	maxHp = UnitHealthMax(unit)

	-- Only show deficit if not at full health (most common check first)
	if currentHp < maxHp then
		return "-" .. E:ShortValue(maxHp - currentHp)
	end

	-- Check for status
	statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	return ""
end

-- Format minimal health deficit (no minus sign)
local function formatMinimalHealthDeficit(unit)
	currentHp = UnitHealth(unit)
	maxHp = UnitHealthMax(unit)

	-- Only show deficit if not at full health (most common check first)
	if currentHp < maxHp then
		return E:ShortValue(maxHp - currentHp)
	end

	-- Check status (less common)
	statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	return ""
end

-- Format health for hide-percent-at-full-health mode
local function formatHealthHideFullPercent(unit, isPercentFirst)
	maxHp = UnitHealthMax(unit)
	currentHp = UnitHealth(unit)

	-- If health is full, just return current health value (common case)
	if currentHp == maxHp then
		return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
	end

	-- Check for status
	statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	-- Get formatted current health
	currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	-- Calculate percentage since health isn't full
	percentText = format(PERCENT_FORMAT, (currentHp / maxHp) * 100)

	-- Format in requested order using pre-computed format strings
	if isPercentFirst then
		return format(COMBINED_FORMAT_LEFT, percentText, currentText)
	else
		return format(COMBINED_FORMAT_RIGHT, currentText, percentText)
	end
end

-- Format health with low health coloring
local function formatHealthWithLowHealthColor(unit, isPercentFirst, threshold)
	maxHp = UnitHealthMax(unit)
	currentHp = UnitHealth(unit)

	-- Get formatted current health (used in all cases)
	currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	-- Early return for full health
	if currentHp == maxHp then
		-- Handle absorb information if present
		absorbAmount = UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount > 0 then
			return format(ABSORB_PREFIX_FORMAT, MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount)) .. currentText
		end
		return currentText
	end

	-- Calculate health percentage once and reuse
	healthPercent = (currentHp / maxHp) * 100

	-- Handle absorb information if present
	absorbText = ""
	absorbAmount = UnitGetTotalAbsorbs(unit) or 0
	if absorbAmount > 0 then
		absorbText = format(ABSORB_PREFIX_FORMAT, MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
	end

	-- Calculate percentage text
	percentText = format(PERCENT_FORMAT, healthPercent)

	-- Format text in requested order using pre-computed format strings
	if isPercentFirst then
		result = format(COMBINED_FORMAT_LEFT, percentText, currentText)
	else
		result = format(COMBINED_FORMAT_RIGHT, currentText, percentText)
	end

	-- Check if health is below threshold
	local lowHealthThreshold = threshold or 20 -- Default to 20%
	if healthPercent <= lowHealthThreshold then
		-- Apply color for low health
		colorCode = HEALTH_GRADIENT_RGB_TABLE[floor(healthPercent)] or "|cffFF0000"
		return absorbText .. colorCode .. result .. COLOR_END
	else
		return absorbText .. result
	end
end

-- Create an optimized health formatter with full gradient coloring (only when below 100%)
local function formatHealthWithFullGradient(unit, isPercentFirst)
	maxHp = UnitHealthMax(unit)
	currentHp = UnitHealth(unit)

	-- Early return for division by zero
	if maxHp == 0 then
		return ""
	end

	-- Handle absorb information if present
	absorbText = ""
	absorbAmount = UnitGetTotalAbsorbs(unit) or 0
	if absorbAmount > 0 then
		absorbText = format(ABSORB_PREFIX_FORMAT, MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
	end

	-- Special case: At full health, just show current value (which is max)
	if currentHp == maxHp then
		local fullHealthText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		return absorbText .. WHITE_COLOR .. fullHealthText .. COLOR_END
	end

	-- Calculate health percentage once and reuse
	healthPercent = (currentHp / maxHp) * 100
	roundedPercent = floor(healthPercent)

	-- Get text components
	percentText = format(PERCENT_FORMAT, healthPercent)
	currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	-- Format in requested order using pre-computed format strings
	if isPercentFirst then
		result = format(COMBINED_FORMAT_LEFT, percentText, currentText)
	else
		result = format(COMBINED_FORMAT_RIGHT, currentText, percentText)
	end

	-- Apply gradient color for non-full health
	colorCode = HEALTH_GRADIENT_RGB_TABLE[roundedPercent] or WHITE_COLOR
	return absorbText .. colorCode .. result .. COLOR_END
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
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED", -- ABSORB event needed for shield display
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
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED", -- ABSORB event needed for shield display
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

-- Current | Percent with full gradient coloring
MHCT.registerTag(
	"mh-health-current-percent:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 100k | 85% with color gradient (red to yellow to green) when below 100%, white at full health",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED", -- ABSORB event needed for shield display
	function(unit)
		return formatHealthWithFullGradient(unit, false) -- false = current first
	end
)

-- Percent | Current with full gradient coloring
MHCT.registerTag(
	"mh-health-percent-current:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 85% | 100k with color gradient (red to yellow to green) when below 100%, white at full health",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED", -- ABSORB event needed for shield display
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
	"Shows only current health value with color gradient when below 100%, white at full health",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED", -- ABSORB event needed for shield display
	function(unit)
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)

		if maxHp == 0 then
			return ""
		end

		-- Handle absorb information if present
		local absorbText = ""
		local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount > 0 then
			absorbText = format(ABSORB_PREFIX_FORMAT, MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
		end

		-- Handle full health case separately with white color
		if currentHp == maxHp then
			return absorbText .. WHITE_COLOR .. E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true) .. COLOR_END
		end

		local healthPercent = (currentHp / maxHp) * 100
		local roundedPercent = floor(healthPercent)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		-- Apply gradient color
		local colorCode = HEALTH_GRADIENT_RGB_TABLE[roundedPercent] or WHITE_COLOR
		return absorbText .. colorCode .. currentText .. COLOR_END
	end
)

-- Add percent-only version with gradient coloring
MHCT.registerTag(
	"mh-health-percent:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows only health percentage with color gradient when below 100%, white at full health",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)

		if maxHp == 0 then
			return ""
		end

		-- Handle full health case with white color
		if currentHp == maxHp then
			return WHITE_COLOR .. "100%" .. COLOR_END
		end

		local healthPercent = (currentHp / maxHp) * 100
		local roundedPercent = floor(healthPercent)
		local percentText = format(PERCENT_FORMAT, healthPercent)

		-- Apply gradient color
		local colorCode = HEALTH_GRADIENT_RGB_TABLE[roundedPercent] or WHITE_COLOR
		return colorCode .. percentText .. COLOR_END
	end
)

-- ===================================================================================
-- HEALTH COLOR TAGS
-- ===================================================================================

-- Health color gradient tag - optimized version
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
		return HEALTH_GRADIENT_RGB_TABLE[index] or DEAD_OR_DC_COLOR
	end
)

-- Add throttled versions of the health color tag for better performance
MHCT.registerMultiThrottledTag(
	"mh-healthcolor",
	HEALTH_V2_SUBCATEGORY,
	"Health color gradient, updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
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
		return HEALTH_GRADIENT_RGB_TABLE[index] or DEAD_OR_DC_COLOR
	end
)
