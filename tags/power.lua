-- ===================================================================================
-- POWER RELATED TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Localize Lua functions
local format = string.format
local tonumber = tonumber

-- Get ElvUI references from core
local E = unpack(ElvUI)

-- Localize WoW API functions
local UnitPowerType = UnitPowerType
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

-- Local constants
local POWER_SUBCATEGORY = "power"
local DEFAULT_DECIMAL_PLACE = MHCT.DEFAULT_DECIMAL_PLACE

-- Direct formatting is used instead of cached patterns to avoid memory overhead

-- Variables are defined locally in functions to avoid state issues

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

	-- Direct formatting based on decimal places
	if decimalPlaces == 0 then
		return format("%.0f", percent)
	elseif decimalPlaces == 1 then
		return format("%.1f", percent)
	elseif decimalPlaces == 2 then
		return format("%.2f", percent)
	else
		return format("%%.%df", decimalPlaces):format(percent)
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
