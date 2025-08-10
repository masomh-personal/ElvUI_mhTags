-- ===================================================================================
-- COMPLETE UNIFIED HEALTH TAGS - All tags from V1 and V2
-- Ensures 100% backward compatibility with optimizations
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references directly
local E = unpack(ElvUI)

-- Localize Lua functions
local format = string.format
local floor = math.floor
local tonumber = tonumber
local min = math.min
local max = math.max

-- Localize WoW API functions
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local GetTime = GetTime

-- Localize gradient table
local HEALTH_GRADIENT_RGB_TABLE = MHCT.HEALTH_GRADIENT_RGB

-- Set the category names
local HEALTH_V1_SUBCATEGORY = "health-v1"
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
local DEFICIT_FORMAT = "-%s"

-- ===================================================================================
-- SHARED CACHE SYSTEM - Reduce redundant calculations
-- ===================================================================================
local healthCache = {}
local cacheExpiry = {}
local CACHE_DURATION = 0.05 -- 50ms cache duration

local function getCachedHealthData(unit)
	local now = GetTime()
	local cacheKey = unit

	-- Check if cache is still valid
	if healthCache[cacheKey] and cacheExpiry[cacheKey] and cacheExpiry[cacheKey] > now then
		return healthCache[cacheKey].current, healthCache[cacheKey].max, healthCache[cacheKey].percent
	end

	-- Calculate and cache
	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)
	local percent = maxHp > 0 and (currentHp / maxHp) * 100 or 0

	healthCache[cacheKey] = {
		current = currentHp,
		max = maxHp,
		percent = percent,
	}
	cacheExpiry[cacheKey] = now + CACHE_DURATION

	return currentHp, maxHp, percent
end

-- ===================================================================================
-- OPTIMIZED SHARED HELPER FUNCTIONS
-- ===================================================================================

-- Single function for all health percent needs
local function formatHealthPercent(unit, decimalPlaces, showSign, hideAtFull)
	local currentHp, maxHp, healthPercent = getCachedHealthData(unit)

	-- Guard against zero max health
	if maxHp == 0 then
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		return statusFormatted or ""
	end

	-- Check for status first
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	-- Handle full health case
	if currentHp == maxHp then
		if hideAtFull then
			return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		end
		-- For non-hide mode, still show 100%
	end

	-- Format percentage
	local decimals = tonumber(decimalPlaces) or 1
	decimals = min(decimals, 10) -- Cap at 10

	local formatPattern
	if showSign then
		formatPattern = MHCT.FORMAT_PATTERNS.DECIMAL_WITH_PERCENT[decimals]
	else
		formatPattern = MHCT.FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[decimals]
	end

	return format(formatPattern, healthPercent)
end

-- Single function for all deficit needs
local function formatHealthDeficit(unit, showMinus, asPercent, decimalPlaces)
	local currentHp, maxHp, healthPercent = getCachedHealthData(unit)

	-- Only show deficit if not at full health
	if currentHp >= maxHp then
		-- Check for status
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end
		return ""
	end

	if asPercent then
		local decimals = tonumber(decimalPlaces) or 1
		decimals = min(decimals, 10)

		local deficit = 100 - healthPercent
		local formatPattern
		if showMinus then
			formatPattern = MHCT.FORMAT_PATTERNS.DEFICIT_WITH_PERCENT[decimals]
		else
			formatPattern = MHCT.FORMAT_PATTERNS.DEFICIT_WITHOUT_PERCENT[decimals]
		end

		return format(formatPattern, deficit)
	else
		local deficitValue = E:ShortValue(maxHp - currentHp)
		return showMinus and format(DEFICIT_FORMAT, deficitValue) or deficitValue
	end
end

-- Unified function for current + percent combinations
local function formatCurrentPercent(unit, isPercentFirst, hidePercent, withAbsorb, withColor, lowHealthThreshold)
	local currentHp, maxHp, healthPercent = getCachedHealthData(unit)

	-- Check for status
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	-- Get formatted current health
	local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	-- Handle absorb if requested
	local absorbText = ""
	if withAbsorb then
		local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount > 0 then
			absorbText = format(ABSORB_PREFIX_FORMAT, MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
		end
	end

	-- Handle full health case
	if currentHp == maxHp then
		if hidePercent then
			return absorbText .. currentText
		end
		-- Continue to show percent even at full
	end

	-- Calculate percentage text
	local percentText = format(PERCENT_FORMAT, healthPercent)

	-- Format in requested order
	local result
	if isPercentFirst then
		result = format(COMBINED_FORMAT_LEFT, percentText, currentText)
	else
		result = format(COMBINED_FORMAT_RIGHT, currentText, percentText)
	end

	-- Apply color if requested
	if withColor then
		-- Distinguish between full-gradient mode and low-health-only mode
		if lowHealthThreshold then
			-- Color only when at or below the threshold; otherwise leave uncolored
			if healthPercent <= lowHealthThreshold then
				local roundedPercent = floor(healthPercent)
				local colorCode = HEALTH_GRADIENT_RGB_TABLE[roundedPercent] or WHITE_COLOR
				return absorbText .. colorCode .. result .. COLOR_END
			else
				return absorbText .. result
			end
		else
			-- Full gradient mode: always apply gradient, including at 100%
			local roundedPercent = floor(healthPercent)
			local colorCode = HEALTH_GRADIENT_RGB_TABLE[roundedPercent] or WHITE_COLOR
			return absorbText .. colorCode .. result .. COLOR_END
		end
	end

	return absorbText .. result
end

-- ===================================================================================
-- REGISTER ALL V1 HEALTH TAGS
-- ===================================================================================

-- Basic health percent tags
MHCT.registerTag(
	"mh-health:simple:percent",
	HEALTH_V1_SUBCATEGORY,
	"Shows max hp at full or percent with dynamic # of decimals",
	"PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit, _, args)
		return formatHealthPercent(unit, args, true, false)
	end
)

MHCT.registerTag(
	"mh-health:simple:percent-nosign",
	HEALTH_V1_SUBCATEGORY,
	"Shows max hp at full or percent (no % sign) with dynamic # of decimals",
	"PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH",
	function(unit, _, args)
		return formatHealthPercent(unit, args, false, false)
	end
)

MHCT.registerTag(
	"mh-health:simple:percent-nosign-v2",
	HEALTH_V1_SUBCATEGORY,
	"Hidden at max hp at full or percent (with no % sign) with dynamic # of decimals",
	"PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp = getCachedHealthData(unit)
		if currentHp ~= maxHp then
			local decimalPlaces = tonumber(args) or 0
			local formatPattern = MHCT.FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[decimalPlaces]
				or format("%%.%sf", decimalPlaces)
			return format(formatPattern, (currentHp / maxHp) * 100)
		end

		return ""
	end
)

MHCT.registerTag(
	"mh-health:simple:percent-v2",
	HEALTH_V1_SUBCATEGORY,
	"Hidden at max hp at full or percent + % sign with dynamic # of decimals",
	"PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp = getCachedHealthData(unit)
		if currentHp ~= maxHp then
			local decimalPlaces = tonumber(args) or 0
			local formatPattern = MHCT.FORMAT_PATTERNS.DECIMAL_WITH_PERCENT[decimalPlaces]
				or format("%%.%sf%%%%", decimalPlaces)
			return format(formatPattern, (currentHp / maxHp) * 100)
		end

		return ""
	end
)

-- Current + Percent combinations
MHCT.registerTag(
	"mh-health:current:percent:left",
	HEALTH_V1_SUBCATEGORY,
	"Shows current + percent health: 85% | 100k",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatCurrentPercent(unit, true, false, false, false)
	end
)

MHCT.registerTag(
	"mh-health:current:percent:right",
	HEALTH_V1_SUBCATEGORY,
	"Shows current + percent health: 100k | 85%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatCurrentPercent(unit, false, false, false, false)
	end
)

-- Hide percent at full versions
MHCT.registerTag(
	"mh-health:current:percent:right-hidefull",
	HEALTH_V1_SUBCATEGORY,
	"Hides percent at full health: 100k | 85%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatCurrentPercent(unit, false, true, false, false)
	end
)

MHCT.registerTag(
	"mh-health:current:percent:left-hidefull",
	HEALTH_V1_SUBCATEGORY,
	"Hides percent at full health: 85% | 100k",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatCurrentPercent(unit, true, true, false, false)
	end
)

-- With absorb shield
MHCT.registerTag(
	"mh-health:absorb:current:percent:right",
	HEALTH_V1_SUBCATEGORY,
	"Shows absorb, current, and percent: (shield) 100k | 85%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		return formatCurrentPercent(unit, false, false, true, false)
	end
)

-- Deficit tags
MHCT.registerTag(
	"mh-deficit:num-status",
	HEALTH_V1_SUBCATEGORY,
	"Shows deficit shortvalue when less than 100% health",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatHealthDeficit(unit, true, false)
	end
)

MHCT.registerTag(
	"mh-deficit:num-nostatus",
	HEALTH_V1_SUBCATEGORY,
	"Shows deficit shortvalue (no status)",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		return formatHealthDeficit(unit, true, false)
	end
)

MHCT.registerTag(
	"mh-deficit:percent-status",
	HEALTH_V1_SUBCATEGORY,
	"Shows deficit percent with dynamic decimal",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit, _, args)
		return formatHealthDeficit(unit, true, true, args)
	end
)

MHCT.registerTag(
	"mh-deficit:percent-status-nosign",
	HEALTH_V1_SUBCATEGORY,
	"Shows deficit percent with dynamic decimal (no % sign)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp = getCachedHealthData(unit)
		if currentHp == maxHp then
			return ""
		end

		local decimalPlaces = tonumber(args) or 1
		local formatPattern = MHCT.FORMAT_PATTERNS.DEFICIT_WITHOUT_PERCENT[decimalPlaces]
			or format("-%%.%sf", decimalPlaces)

		return format(formatPattern, 100 - (currentHp / maxHp) * 100)
	end
)

MHCT.registerTag(
	"mh-deficit:percent-nostatus",
	HEALTH_V1_SUBCATEGORY,
	"Shows deficit percent with dynamic decimal (no status)",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit, _, args)
		local currentHp, maxHp = getCachedHealthData(unit)
		if currentHp == maxHp then
			return ""
		end

		local decimalPlaces = tonumber(args) or 1
		local formatPattern = MHCT.FORMAT_PATTERNS.DEFICIT_WITH_PERCENT[decimalPlaces]
			or format("-%%.%sf%%%%", decimalPlaces)

		return format(formatPattern, 100 - (currentHp / maxHp) * 100)
	end
)

-- ===================================================================================
-- REGISTER ALL V2 HEALTH TAGS
-- ===================================================================================

-- Individual throttled health percent tags
MHCT.registerThrottledTag(
	"mh-health-percent:status-0.25",
	HEALTH_V2_SUBCATEGORY,
	"Health percent with status @ 0.25s update interval",
	MHCT.THROTTLES.QUARTER,
	function(unit, _, args)
		return formatHealthPercent(unit, args, true, false)
	end
)

MHCT.registerThrottledTag(
	"mh-health-percent:status-0.5",
	HEALTH_V2_SUBCATEGORY,
	"Health percent with status @ 0.5s update interval",
	MHCT.THROTTLES.HALF,
	function(unit, _, args)
		return formatHealthPercent(unit, args, true, false)
	end
)

MHCT.registerThrottledTag(
	"mh-health-percent:status-1.0",
	HEALTH_V2_SUBCATEGORY,
	"Health percent with status @ 1.0s update interval",
	MHCT.THROTTLES.ONE,
	function(unit, _, args)
		return formatHealthPercent(unit, args, true, false)
	end
)

MHCT.registerThrottledTag(
	"mh-health-percent:status-2.0",
	HEALTH_V2_SUBCATEGORY,
	"Health percent with status @ 2.0s update interval",
	MHCT.THROTTLES.TWO,
	function(unit, _, args)
		return formatHealthPercent(unit, args, true, false)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health-percent:status-configurable",
	HEALTH_V2_SUBCATEGORY,
	"Health percent with status and configurable decimal places, updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit, _, args)
		return formatHealthPercent(unit, args, true, false)
	end
)

-- Individual throttled deficit tags
MHCT.registerThrottledTag(
	"mh-health-deficit:status-0.25",
	HEALTH_V2_SUBCATEGORY,
	"Health deficit with status @ 0.25s update interval",
	MHCT.THROTTLES.QUARTER,
	function(unit)
		return formatHealthDeficit(unit, true, false)
	end
)

MHCT.registerThrottledTag(
	"mh-health-deficit:status-0.5",
	HEALTH_V2_SUBCATEGORY,
	"Health deficit with status @ 0.5s update interval",
	MHCT.THROTTLES.HALF,
	function(unit)
		return formatHealthDeficit(unit, true, false)
	end
)

MHCT.registerThrottledTag(
	"mh-health-deficit:status-1.0",
	HEALTH_V2_SUBCATEGORY,
	"Health deficit with status @ 1.0s update interval",
	MHCT.THROTTLES.ONE,
	function(unit)
		return formatHealthDeficit(unit, true, false)
	end
)

MHCT.registerThrottledTag(
	"mh-health-deficit:status-2.0",
	HEALTH_V2_SUBCATEGORY,
	"Health deficit with status @ 2.0s update interval",
	MHCT.THROTTLES.TWO,
	function(unit)
		return formatHealthDeficit(unit, true, false)
	end
)

-- Minimal deficit tags (no minus sign)
MHCT.registerThrottledTag(
	"mh-health-deficit:minimal-0.25",
	HEALTH_V2_SUBCATEGORY,
	"Minimal health deficit display @ 0.25s update interval - no minus sign",
	MHCT.THROTTLES.QUARTER,
	function(unit)
		return formatHealthDeficit(unit, false, false)
	end
)

MHCT.registerThrottledTag(
	"mh-health-deficit:minimal-0.5",
	HEALTH_V2_SUBCATEGORY,
	"Minimal health deficit display @ 0.5s update interval - no minus sign",
	MHCT.THROTTLES.HALF,
	function(unit)
		return formatHealthDeficit(unit, false, false)
	end
)

MHCT.registerThrottledTag(
	"mh-health-deficit:minimal-1.0",
	HEALTH_V2_SUBCATEGORY,
	"Minimal health deficit display @ 1.0s update interval - no minus sign",
	MHCT.THROTTLES.ONE,
	function(unit)
		return formatHealthDeficit(unit, false, false)
	end
)

MHCT.registerThrottledTag(
	"mh-health-deficit:minimal-2.0",
	HEALTH_V2_SUBCATEGORY,
	"Minimal health deficit display @ 2.0s update interval - no minus sign",
	MHCT.THROTTLES.TWO,
	function(unit)
		return formatHealthDeficit(unit, false, false)
	end
)

-- Hide percent at full tags (V2 naming)
MHCT.registerTag(
	"mh-health-current-percent-hidefull",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 100k | 85% but hides percent at full health",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatCurrentPercent(unit, false, true, false, false)
	end
)

MHCT.registerTag(
	"mh-health-percent-current-hidefull",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 85% | 100k but hides percent at full health",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatCurrentPercent(unit, true, true, false, false)
	end
)

-- Low health colored versions
MHCT.registerTag(
	"mh-health-current-percent:low-health-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 100k | 85% with color gradient for health below 20%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit, _, args)
		local threshold = tonumber(args) or 20
		return formatCurrentPercent(unit, false, false, true, true, threshold)
	end
)

MHCT.registerTag(
	"mh-health-percent-current:low-health-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 85% | 100k with color gradient for health below 20%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit, _, args)
		local threshold = tonumber(args) or 20
		return formatCurrentPercent(unit, true, false, true, true, threshold)
	end
)

-- Gradient colored versions
MHCT.registerTag(
	"mh-health-current-percent:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health with gradient coloring: 100k | 85%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		return formatCurrentPercent(unit, false, false, true, true)
	end
)

MHCT.registerTag(
	"mh-health-percent-current:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health with gradient coloring: 85% | 100k",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		return formatCurrentPercent(unit, true, false, true, true)
	end
)

-- Simple gradient colored tags
MHCT.registerTag(
	"mh-health-current:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows only current health value with color gradient when below 100%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		local currentHp, maxHp, healthPercent = getCachedHealthData(unit)

		if maxHp == 0 then
			return ""
		end

		-- Handle absorb
		local absorbText = ""
		local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount > 0 then
			absorbText = format(ABSORB_PREFIX_FORMAT, MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
		end

		local roundedPercent = floor(healthPercent)
		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		-- Apply gradient color even at 100%
		local colorCode = HEALTH_GRADIENT_RGB_TABLE[roundedPercent] or WHITE_COLOR
		return absorbText .. colorCode .. currentText .. COLOR_END
	end
)

MHCT.registerTag(
	"mh-health-percent:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows only health percentage with color gradient when below 100%",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		local currentHp, maxHp, healthPercent = getCachedHealthData(unit)

		if maxHp == 0 then
			return ""
		end

		local roundedPercent = floor(healthPercent)
		local percentText = format(PERCENT_FORMAT, healthPercent)

		-- Apply gradient color even at 100%
		local colorCode = HEALTH_GRADIENT_RGB_TABLE[roundedPercent] or WHITE_COLOR
		return colorCode .. percentText .. COLOR_END
	end
)

-- Health color tag
MHCT.registerTag(
	"mh-healthcolor",
	HEALTH_V2_SUBCATEGORY,
	"Color tag with bright gradient",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		local currentHp, maxHp, healthPercent = getCachedHealthData(unit)

		if maxHp == 0 then
			return DEAD_OR_DC_COLOR
		end

		local index = floor(healthPercent)
		return HEALTH_GRADIENT_RGB_TABLE[index] or DEAD_OR_DC_COLOR
	end
)

-- ===================================================================================
-- THROTTLED VERSIONS FROM V1
-- ===================================================================================

MHCT.registerMultiThrottledTag(
	"mh-health:current:percent:right",
	HEALTH_V1_SUBCATEGORY,
	"Shows current + percent (100k | 85%), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatCurrentPercent(unit, false, false, false, false)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health:simple:percent",
	HEALTH_V1_SUBCATEGORY,
	"Shows health percent, updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatHealthPercent(unit, 1, true, false)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-deficit:num-status",
	HEALTH_V1_SUBCATEGORY,
	"Shows health deficit, updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatHealthDeficit(unit, true, false)
	end
)

-- ===================================================================================
-- THROTTLED VERSIONS FROM V2
-- ===================================================================================

MHCT.registerMultiThrottledTag(
	"mh-health-percent:status",
	HEALTH_V2_SUBCATEGORY,
	"Health percent with status, updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit, _, args)
		return formatHealthPercent(unit, args, true, false)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health-deficit:status",
	HEALTH_V2_SUBCATEGORY,
	"Health deficit with status, updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatHealthDeficit(unit, true, false)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-healthcolor",
	HEALTH_V2_SUBCATEGORY,
	"Health color gradient, updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		local currentHp, maxHp, healthPercent = getCachedHealthData(unit)

		if maxHp == 0 then
			return DEAD_OR_DC_COLOR
		end

		local index = floor(healthPercent)
		return HEALTH_GRADIENT_RGB_TABLE[index] or DEAD_OR_DC_COLOR
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health-current-percent-hidefull",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 100k | 85% (hides percent at full), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatCurrentPercent(unit, false, true, false, false)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health-percent-current-hidefull",
	HEALTH_V2_SUBCATEGORY,
	"Shows health as: 85% | 100k (hides percent at full), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatCurrentPercent(unit, true, true, false, false)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health-current-percent:low-health-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health with color at low health (current | percent), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit, _, args)
		local threshold = tonumber(args) or 20
		return formatCurrentPercent(unit, false, false, true, true, threshold)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health-percent-current:low-health-colored",
	HEALTH_V2_SUBCATEGORY,
	"Shows health with color at low health (percent | current), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit, _, args)
		local threshold = tonumber(args) or 20
		return formatCurrentPercent(unit, true, false, true, true, threshold)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health-current-percent:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Gradient colored health, updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatCurrentPercent(unit, false, false, true, true)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health-percent-current:gradient-colored",
	HEALTH_V2_SUBCATEGORY,
	"Gradient colored health (percent | current), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatCurrentPercent(unit, true, false, true, true)
	end
)

-- ===================================================================================
-- CLEANUP - Periodically clean expired cache entries
-- ===================================================================================
local cleanupFrame = CreateFrame("Frame")
local timeSinceLastCleanup = 0
cleanupFrame:SetScript("OnUpdate", function(self, elapsed)
	timeSinceLastCleanup = timeSinceLastCleanup + elapsed
	if timeSinceLastCleanup > 1 then -- Clean every second
		local now = GetTime()
		for key, expiry in pairs(cacheExpiry) do
			if expiry < now then
				healthCache[key] = nil
				cacheExpiry[key] = nil
			end
		end
		timeSinceLastCleanup = 0
	end
end)
