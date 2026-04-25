-- ===================================================================================
-- POWER RELATED TAGS - WoW 12.0+ (Midnight)
-- ===================================================================================
-- Requires WoW 12.0+ - uses native UnitPowerPercent API with CurveConstants.ScaleTo100
--
-- Secret Value Handling:
-- Power values may be "secret" on nameplates and in competitive content.
-- We use MHCT.GetPowerPercent() which handles secrets via CurveConstants.ScaleTo100.
-- For secret values, we format with string.format() which accepts secrets.
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Localize Lua functions
local format = string.format

-- Localize core utility functions
local GetPowerPercent = MHCT.GetPowerPercent
local PERCENT_FORMATS = MHCT.PERCENT_FORMATS

-- Local constants
local POWER_SUBCATEGORY = "power"
local DEFAULT_DECIMAL_PLACE = MHCT.DEFAULT_DECIMAL_PLACE

-- ===================================================================================
-- HELPER FUNCTIONS
-- ===================================================================================

-- Format power percent using secret-safe utility from core.lua
-- Returns formatted percent string or empty string for zero/unavailable
local function formatPowerPercent(unit, decimalPlaces, powerType)
	if not unit then
		return ""
	end
	if decimalPlaces < 0 then
		decimalPlaces = 0
	elseif decimalPlaces > 3 then
		decimalPlaces = 3
	end

	-- Get percent (0-100 range) using secret-safe utility
	local percent, isSecret = GetPowerPercent(unit, powerType)

	-- For secret values, we can still format using string.format
	-- (CurveConstants.ScaleTo100 gives us 0-100 even for secrets)
	if isSecret then
		if percent == nil then
			return ""
		end
		-- Basic format for secret values
		return format("%.0f", percent)
	end

	if percent == nil then
		return ""
	end

	-- Non-secret: use requested decimal places
	local fmt = PERCENT_FORMATS[decimalPlaces]
	if fmt then
		return format(fmt, percent)
	end
	return format("%.0f", percent)
end

-- ===================================================================================
-- POWER PERCENT
-- ===================================================================================

-- Main power percent tag with simpler name
-- Uses MHCT.GetPowerPercent() for secret-safe 0-100 percent
MHCT.registerTag(
	"mh-power-percent",
	POWER_SUBCATEGORY,
	"Power percent (0–100). Use {N} for decimal places (default 0). Example: [mh-power-percent{1}]",
	"UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER",
	function(unit, _, args)
		if not unit then
			return ""
		end
		return formatPowerPercent(unit, MHCT.parseDecimalArg(args, DEFAULT_DECIMAL_PLACE))
	end
)
