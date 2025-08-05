-- ===================================================================================
-- POWER RELATED TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Localize Lua functions
local format = string.format
local tonumber = tonumber

-- Localize WoW API functions
local UnitPowerType = UnitPowerType
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

-- Local constants
local POWER_SUBCATEGORY = "power"
local DEFAULT_DECIMAL_PLACE = MHCT.DEFAULT_DECIMAL_PLACE
local ZERO_STRING = "0"
local EMPTY_STRING = ""

-- Pre-define variables to reuse (reduces memory allocation)
local powerType, currentPower, maxPower, percent

-- ===================================================================================
-- HELPER FUNCTIONS
-- ===================================================================================

-- Optimized power percent formatter
local function formatPowerPercent(unit, decimalPlaces)
	powerType = UnitPowerType(unit)
	maxPower = UnitPowerMax(unit, powerType)

	-- Early return for invalid max power
	if maxPower <= 0 then
		return EMPTY_STRING
	end

	currentPower = UnitPower(unit, powerType)

	-- Early return for zero power
	if currentPower == 0 then
		return ZERO_STRING
	end

	-- Calculate percentage
	percent = (currentPower / maxPower) * 100

	-- Use cached format pattern if available
	local formatPattern = MHCT.FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[decimalPlaces] or format("%%.%df", decimalPlaces)

	return format(formatPattern, percent)
end

-- ===================================================================================
-- POWER PERCENT
-- ===================================================================================

-- Main power percent tag with simpler name
MHCT.registerTag(
	"mh-power-percent",
	POWER_SUBCATEGORY,
	"Simple power percent, no percentage sign with dynamic number of decimals (dynamic number within {} of tag)",
	"UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER",
	function(unit, _, args)
		return formatPowerPercent(unit, tonumber(args) or DEFAULT_DECIMAL_PLACE)
	end
)

-- ===================================================================================
-- THROTTLED POWER PERCENT TAGS
-- ===================================================================================

-- Create throttled versions of the power percent tag with the new naming
MHCT.registerMultiThrottledTag(
	"mh-power-percent",
	POWER_SUBCATEGORY,
	"Simple power percent, updates every %throttle% seconds",
	MHCT.THROTTLE_SETS.STANDARD,
	function(unit)
		return formatPowerPercent(unit, 0) -- Default to 0 decimal places for throttled versions
	end
)
