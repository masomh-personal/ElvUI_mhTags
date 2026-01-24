-- ===================================================================================
-- POWER RELATED TAGS - Optimized for efficiency
-- ===================================================================================
--
-- WoW 12.0+ Optimization:
-- Uses MHCT.GetUnitPowerPercent() which leverages native UnitPowerPercent()
-- when available (12.0+), providing better performance and secret value handling
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

-- Localize MHCT API wrappers (use 12.0 APIs when available)
local GetUnitPowerPercent = MHCT.GetUnitPowerPercent

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
-- Uses MHCT.GetUnitPowerPercent() which leverages 12.0 APIs when available
-- WoW 12.0: If value is secret (returns -1), we return empty string
local function formatPowerPercent(unit, decimalPlaces)
	if not unit then
		return ""
	end

	-- Get the unit's power type for the API call
	local powerType = UnitPowerType(unit)

	-- Use optimized percentage calculation (uses 12.0 API when available)
	local percent = GetUnitPowerPercent(unit, powerType)

	-- Early return for zero power
	if percent == 0 then
		return "0"
	end

	-- Secret value (-1): can't calculate percentage, return empty
	-- (In 12.0, power values can be secret in combat contexts)
	if percent < 0 then
		return ""
	end

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
		if not unit then
			return ""
		end
		return formatPowerPercent(unit, MHCT.parseDecimalArg(args, DEFAULT_DECIMAL_PLACE))
	end
)
