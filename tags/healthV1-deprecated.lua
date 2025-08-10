-- ===================================================================================
-- VERSION 1.0 of health related tags - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references directly
local E = unpack(ElvUI)

-- Localize Lua functions
local format = string.format
local tonumber = tonumber

-- Localize WoW API functions
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs

-- Local constants
local HEALTH_SUBCATEGORY = "health-v1"
local DEFAULT_DECIMAL_PLACE = MHCT.DEFAULT_DECIMAL_PLACE
local ABSORB_TEXT_COLOR = MHCT.ABSORB_TEXT_COLOR

-- Pre-allocate variables to reduce memory allocation during frequent updates
local currentHp, maxHp, currentPercent, decimalPlaces, formatPattern
local statusFormatted, returnString, absorbAmount

-- Pre-computed format strings for common cases (avoid runtime string construction)
local COMMON_FORMATS = {
	PERCENT_LEFT = "%.1f%% | %s", -- "85.0% | 100k"
	PERCENT_RIGHT = "%s | %.1f%%", -- "100k | 85.0%"
	DEFICIT = "-%s", -- "-15k"
}

-- ===================================================================================
-- OPTIMIZED HELPER FUNCTIONS - Reduce code duplication and function call overhead
-- ===================================================================================

-- Fast health data retrieval with status check
local function getHealthDataWithStatus(unit)
	statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return nil, nil, statusFormatted
	end

	maxHp = UnitHealthMax(unit)
	currentHp = UnitHealth(unit)
	return currentHp, maxHp, nil
end

-- Fast current + percent formatter (optimized for most common case)
local function formatCurrentPercent(unit, leftFormat)
	currentHp, maxHp, statusFormatted = getHealthDataWithStatus(unit)
	if statusFormatted then
		return statusFormatted
	end

	currentPercent = (currentHp / maxHp) * 100
	local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	if leftFormat then
		return format(COMMON_FORMATS.PERCENT_LEFT, currentPercent, currentText)
	else
		return format(COMMON_FORMATS.PERCENT_RIGHT, currentText, currentPercent)
	end
end

-- Fast current + percent with hide-full logic
local function formatCurrentPercentHideFull(unit, leftFormat)
	currentHp, maxHp, statusFormatted = getHealthDataWithStatus(unit)
	if statusFormatted then
		return statusFormatted
	end

	local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	if maxHp ~= currentHp then
		currentPercent = (currentHp / maxHp) * 100
		if leftFormat then
			return format(COMMON_FORMATS.PERCENT_LEFT, currentPercent, currentText)
		else
			return format(COMMON_FORMATS.PERCENT_RIGHT, currentText, currentPercent)
		end
	else
		return currentText
	end
end

-- Fast deficit formatter
local function formatDeficit(unit, withStatus)
	if withStatus then
		currentHp, maxHp, statusFormatted = getHealthDataWithStatus(unit)
		if statusFormatted then
			return statusFormatted
		end
	else
		currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
	end

	return (currentHp == maxHp) and "" or format(COMMON_FORMATS.DEFICIT, E:ShortValue(maxHp - currentHp))
end

-- ===================================================================================
-- HEALTH RELATED TAGS
-- ===================================================================================

-- Current + Percent (Percent first) - OPTIMIZED
MHCT.registerTag(
	"mh-health:current:percent:left",
	HEALTH_SUBCATEGORY,
	"Shows current + percent health at all times similar to following example: 85% | 100k",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatCurrentPercent(unit, true)
	end
)

-- Current + Percent (Current first) - OPTIMIZED
MHCT.registerTag(
	"mh-health:current:percent:right",
	HEALTH_SUBCATEGORY,
	"Shows current + percent health at all times similar to following example: 100k | 85%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatCurrentPercent(unit, false)
	end
)

-- Current + Percent (Current first, hide percent at full) - OPTIMIZED
MHCT.registerTag(
	"mh-health:current:percent:right-hidefull",
	HEALTH_SUBCATEGORY,
	"Hides percent at full health else shows at all times similar to following example: 100k | 85%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatCurrentPercentHideFull(unit, false)
	end
)

-- Current + Percent (Percent first, hide percent at full) - OPTIMIZED
MHCT.registerTag(
	"mh-health:current:percent:left-hidefull",
	HEALTH_SUBCATEGORY,
	"Hides percent at full health else shows at all times similar to following example: 85% |100k",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatCurrentPercentHideFull(unit, true)
	end
)

-- Absorb + Current + Percent - OPTIMIZED
MHCT.registerTag(
	"mh-health:absorb:current:percent:right",
	HEALTH_SUBCATEGORY,
	"Hides percent at full health else shows absorb, current, and percent to following example: (**absorb amount**) 100k | 85%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		currentHp, maxHp, statusFormatted = getHealthDataWithStatus(unit)
		if statusFormatted then
			return statusFormatted
		end

		returnString = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		if maxHp ~= currentHp then
			currentPercent = (currentHp / maxHp) * 100
			returnString = format(COMMON_FORMATS.PERCENT_RIGHT, returnString, currentPercent)
		end

		absorbAmount = UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount ~= 0 then
			return format(MHCT.COLOR_FORMATS.ABSORB, ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
				.. " "
				.. returnString
		end

		return returnString
	end
)

-- Simple Percent with status
MHCT.registerTag(
	"mh-health:simple:percent",
	HEALTH_SUBCATEGORY,
	"Shows max hp at full or percent with dynamic # of decimals (dynamic number within {} of tag) - Example: [mh-health:simple:percent{2}] will show percent to 2 decimal places",
	"PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthPercent(unit, args, true)
	end
)

-- Simple Percent with status (no % sign)
MHCT.registerTag(
	"mh-health:simple:percent-nosign",
	HEALTH_SUBCATEGORY,
	"Shows max hp at full or percent (with no % sign) with dynamic # of decimals (dynamic number within {} of tag) - [Example: mh-health:simple:percent{2}] will show percent to 2 decimal places",
	"PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthPercent(unit, args, false)
	end
)

-- Simple Percent v2 (hidden at full, no % sign)
MHCT.registerTag(
	"mh-health:simple:percent-nosign-v2",
	HEALTH_SUBCATEGORY,
	"Hidden at max hp at full or percent (with no % sign) with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places",
	"PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		if currentHp ~= maxHp then
			local decimalPlaces = tonumber(args) or DEFAULT_DECIMAL_PLACE

			-- Use cached format pattern if available
			local formatPattern = MHCT.FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[decimalPlaces]
				or format("%%.%sf", decimalPlaces)

			return format(formatPattern, (currentHp / maxHp) * 100)
		end

		return ""
	end
)

-- Simple Percent v2 (hidden at full, with % sign)
MHCT.registerTag(
	"mh-health:simple:percent-v2",
	HEALTH_SUBCATEGORY,
	"Hidden at max hp at full or percent + % sign with dynamic # of decimals (dynamic number within {} of tag) - Example: [mh-health:simple:percent{2}] will show percent to 2 decimal places",
	"PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		if currentHp ~= maxHp then
			local decimalPlaces = tonumber(args) or DEFAULT_DECIMAL_PLACE

			-- Use cached format pattern if available
			local formatPattern = MHCT.FORMAT_PATTERNS.DECIMAL_WITH_PERCENT[decimalPlaces]
				or format("%%.%sf%%%%", decimalPlaces)

			return format(formatPattern, (currentHp / maxHp) * 100)
		end

		return ""
	end
)

-- Deficit with status - OPTIMIZED
MHCT.registerTag(
	"mh-deficit:num-status",
	HEALTH_SUBCATEGORY,
	"Shows deficit shortvalue number when less than 100% health and status + icon if dead/offline/ghost",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		return formatDeficit(unit, true)
	end
)

-- Deficit without status - OPTIMIZED
MHCT.registerTag(
	"mh-deficit:num-nostatus",
	HEALTH_SUBCATEGORY,
	"Shows deficit shortvalue number when less than 100% health (no status)",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		return formatDeficit(unit, false)
	end
)

-- Deficit percent with status
MHCT.registerTag(
	"mh-deficit:percent-status",
	HEALTH_SUBCATEGORY,
	"Shows deficit percent with dynamic decimal when less than 100% health + status icon",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local decimalPlaces = tonumber(args) or 1
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)

		if currentHp == maxHp then
			return ""
		end

		-- Use cached format pattern if available
		local formatPattern = MHCT.FORMAT_PATTERNS.DEFICIT_WITH_PERCENT[decimalPlaces]
			or format("-%%.%sf%%%%", decimalPlaces)

		return format(formatPattern, 100 - (currentHp / maxHp) * 100)
	end
)

-- Deficit percent with status (no % sign)
MHCT.registerTag(
	"mh-deficit:percent-status-nosign",
	HEALTH_SUBCATEGORY,
	"Shows deficit percent with dynamic decimal when less than 100% health + status icon (does not include %)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local decimalPlaces = tonumber(args) or 1
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)

		if currentHp == maxHp then
			return ""
		end

		-- Use cached format pattern if available
		local formatPattern = MHCT.FORMAT_PATTERNS.DEFICIT_WITHOUT_PERCENT[decimalPlaces]
			or format("-%%.%sf", decimalPlaces)

		return format(formatPattern, 100 - (currentHp / maxHp) * 100)
	end
)

-- Deficit percent without status
MHCT.registerTag(
	"mh-deficit:percent-nostatus",
	HEALTH_SUBCATEGORY,
	"Shows deficit percent with dynamic decimal when less than 100% health (no status)",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit, _, args)
		local decimalPlaces = tonumber(args) or 1
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)

		if currentHp == maxHp then
			return ""
		end

		-- Use cached format pattern if available
		local formatPattern = MHCT.FORMAT_PATTERNS.DEFICIT_WITH_PERCENT[decimalPlaces]
			or format("-%%.%sf%%%%", decimalPlaces)

		return format(formatPattern, 100 - (currentHp / maxHp) * 100)
	end
)

-- Add throttled versions of the most commonly used health tags - OPTIMIZED
MHCT.registerMultiThrottledTag(
	"mh-health:current:percent:right",
	HEALTH_SUBCATEGORY,
	"Shows current + percent health (100k | 85%), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatCurrentPercent(unit, false)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health:simple:percent",
	HEALTH_SUBCATEGORY,
	"Shows health percent with % sign, updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthPercent(unit, 1, true) -- Default to 1 decimal place for throttled version
	end
)

MHCT.registerMultiThrottledTag(
	"mh-deficit:num-status",
	HEALTH_SUBCATEGORY,
	"Shows health deficit or status, updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatDeficit(unit, true)
	end
)
