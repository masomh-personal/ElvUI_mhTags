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

-- FORMAT_PATTERNS table for cached decimal formats
local FORMAT_PATTERNS = {
	DECIMAL_WITH_PERCENT = {}, -- Stores patterns like "%.0f%%", "%.1f%%", etc.
	DECIMAL_WITHOUT_PERCENT = {}, -- Stores patterns like "%.0f", "%.1f", etc.
	DEFICIT_WITH_PERCENT = {}, -- Stores patterns like "-%.0f%%", "-%.1f%%", etc.
	DEFICIT_WITHOUT_PERCENT = {}, -- Stores patterns like "-%.0f", "-%.1f", etc.
}

-- Initialize patterns for common decimal place counts
for i = 0, 3 do
	FORMAT_PATTERNS.DECIMAL_WITH_PERCENT[i] = format("%%.%sf%%%%", i)
	FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[i] = format("%%.%sf", i)
	FORMAT_PATTERNS.DEFICIT_WITH_PERCENT[i] = format("-%%.%sf%%%%", i)
	FORMAT_PATTERNS.DEFICIT_WITHOUT_PERCENT[i] = format("-%%.%sf", i)
end

-- ===================================================================================
-- HEALTH RELATED TAGS
-- ===================================================================================

-- Current + Percent (Percent first)
MHCT.registerTag(
	"mh-health:current:percent:left",
	HEALTH_SUBCATEGORY,
	"Shows current + percent health at all times similar to following example: 85% | 100k",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		local currentPercent = (currentHp / maxHp) * 100
		return format("%.1f%% | %s", currentPercent, E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true))
	end
)

-- Current + Percent (Current first)
MHCT.registerTag(
	"mh-health:current:percent:right",
	HEALTH_SUBCATEGORY,
	"Shows current + percent health at all times similar to following example: 100k | 85%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		local currentPercent = (currentHp / maxHp) * 100
		return format("%s | %.1f%%", E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true), currentPercent)
	end
)

-- Current + Percent (Current first, hide percent at full)
MHCT.registerTag(
	"mh-health:current:percent:right-hidefull",
	HEALTH_SUBCATEGORY,
	"Hides percent at full health else shows at all times similar to following example: 100k | 85%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)

		if maxHp ~= currentHp then
			local currentPercent = (currentHp / maxHp) * 100
			return format("%s | %.1f%%", E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true), currentPercent)
		else
			return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		end
	end
)

-- Current + Percent (Percent first, hide percent at full)
MHCT.registerTag(
	"mh-health:current:percent:left-hidefull",
	HEALTH_SUBCATEGORY,
	"Hides percent at full health else shows at all times similar to following example: 85% |100k",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)

		if maxHp ~= currentHp then
			local currentPercent = (currentHp / maxHp) * 100
			return format("%.1f%% | %s", currentPercent, E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true))
		else
			return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		end
	end
)

-- Absorb + Current + Percent
MHCT.registerTag(
	"mh-health:absorb:current:percent:right",
	HEALTH_SUBCATEGORY,
	"Hides percent at full health else shows absorb, current, and percent to following example: (**absorb amount**) 100k | 85%",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		local returnString = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		if maxHp ~= currentHp then
			local currentPercent = (currentHp / maxHp) * 100
			returnString = format("%s | %.1f%%", returnString, currentPercent)
		end

		local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount ~= 0 then
			return format("|cff%s(%s)|r %s", ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount), returnString)
		end

		return returnString
	end
)

-- Simple Percent with status
MHCT.registerTag(
	"mh-health:simple:percent",
	HEALTH_SUBCATEGORY,
	"Shows max hp at full or percent with dynamic # of decimals (dynamic number within {} of tag) - Example: [mh-health:simple:percent{2}] will show percent to 2 decimal places",
	"PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH",
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
			local formatPattern = FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[decimalPlaces]
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
			local formatPattern = FORMAT_PATTERNS.DECIMAL_WITH_PERCENT[decimalPlaces]
				or format("%%.%sf%%%%", decimalPlaces)

			return format(formatPattern, (currentHp / maxHp) * 100)
		end

		return ""
	end
)

-- Deficit with status
MHCT.registerTag(
	"mh-deficit:num-status",
	HEALTH_SUBCATEGORY,
	"Shows deficit shortvalue number when less than 100% health and status + icon if dead/offline/ghost",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		return (currentHp == maxHp) and "" or format("-%s", E:ShortValue(maxHp - currentHp))
	end
)

-- Deficit without status
MHCT.registerTag(
	"mh-deficit:num-nostatus",
	HEALTH_SUBCATEGORY,
	"Shows deficit shortvalue number when less than 100% health (no status)",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		return (currentHp == maxHp) and "" or format("-%s", E:ShortValue(maxHp - currentHp))
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
		local formatPattern = FORMAT_PATTERNS.DEFICIT_WITH_PERCENT[decimalPlaces]
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
		local formatPattern = FORMAT_PATTERNS.DEFICIT_WITHOUT_PERCENT[decimalPlaces] or format("-%%.%sf", decimalPlaces)

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
		local formatPattern = FORMAT_PATTERNS.DEFICIT_WITH_PERCENT[decimalPlaces]
			or format("-%%.%sf%%%%", decimalPlaces)

		return format(formatPattern, 100 - (currentHp / maxHp) * 100)
	end
)

-- Add throttled versions of the most commonly used health tags
MHCT.registerMultiThrottledTag(
	"mh-health:current:percent:right",
	HEALTH_SUBCATEGORY,
	"Shows current + percent health (100k | 85%), updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)
		local currentPercent = (currentHp / maxHp) * 100
		return format("%s | %.1f%%", E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true), currentPercent)
	end
)

MHCT.registerMultiThrottledTag(
	"mh-health:simple:percent",
	HEALTH_SUBCATEGORY,
	"Shows health percent with % sign, updating every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
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
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		return (currentHp == maxHp) and "" or format("-%s", E:ShortValue(maxHp - currentHp))
	end
)
