-- ===================================================================================
-- POWER RELATED TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references from core (shared to avoid duplicate unpacking)
local E = MHCT.E

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

-- Pre-built format strings for common decimal cases (performance optimization)
local PERCENT_FORMATS = {
	[0] = "%.0f",
	[1] = "%.1f",
	[2] = "%.2f",
}

-- ===================================================================================
-- HELPER FUNCTIONS
-- ===================================================================================

-- Optimized power percent formatter
local function formatPowerPercent(unit, decimalPlaces)
	local powerType = UnitPowerType(unit)
	local maxPower = UnitPowerMax(unit, powerType)

	-- Early return for invalid max power
	if maxPower <= 0 then
		return ""
	end

	local currentPower = UnitPower(unit, powerType)

	-- Early return for zero power
	if currentPower == 0 then
		return "0"
	end

	-- Calculate percentage
	local percent = (currentPower / maxPower) * 100

	-- Use pre-built format strings for common cases, build dynamically for others
	local fmt = PERCENT_FORMATS[decimalPlaces]
	if fmt then
		return format(fmt, percent)
	else
		return format("%." .. decimalPlaces .. "f", percent)
	end
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
