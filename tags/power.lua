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

-- FORMAT_PATTERNS table for cached decimal formats
local FORMAT_PATTERNS = {
	DECIMAL_WITHOUT_PERCENT = {}, -- Stores patterns like "%.0f", "%.1f", etc.
}

-- Initialize commonly used decimal precision patterns
for i = 0, 3 do -- Cache patterns for 0-3 decimal places (common use cases)
	FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[i] = format("%%.%df", i)
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
		local powerType = UnitPowerType(unit)
		local currentPower = UnitPower(unit, powerType)
		local maxPower = UnitPowerMax(unit)

		if currentPower ~= 0 and maxPower > 0 then -- Added check for maxPower to avoid div by zero
			local decimalPlaces = tonumber(args) or DEFAULT_DECIMAL_PLACE

			-- Use cached format pattern if available, or create one if not
			local formatPattern = FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[decimalPlaces]
				or format("%%.%df", decimalPlaces)

			return format(formatPattern, (currentPower / maxPower) * 100)
		end

		return ""
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
		local powerType = UnitPowerType(unit)
		local currentPower = UnitPower(unit, powerType)
		local maxPower = UnitPowerMax(unit)

		if currentPower ~= 0 and maxPower > 0 then
			-- Default to 0 decimal places for throttled versions
			local formatPattern = FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[0]
			return format(formatPattern, (currentPower / maxPower) * 100)
		end

		return ""
	end
)
