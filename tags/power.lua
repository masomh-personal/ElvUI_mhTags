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

-- Localize core utility functions
local GetPowerPercent = MHCT.GetPowerPercent
local FormatPercent   = MHCT.FormatPercent

-- Local constants
local POWER_SUBCATEGORY = "power"
local DEFAULT_DECIMAL_PLACE = MHCT.DEFAULT_DECIMAL_PLACE

-- ===================================================================================
-- HELPER FUNCTIONS
-- ===================================================================================

-- Format power percent using secret-safe utilities from core.lua.
-- Delegates clamping and formatting to MHCT.FormatPercent (no % sign for power).
-- Secret values: CurveConstants.ScaleTo100 path in GetPowerPercent returns 0-100 even
-- for secrets, so FormatPercent handles them correctly with no special-casing needed.
local function formatPowerPercent(unit, decimalPlaces, powerType)
	if not unit then return "" end

	local percent, isSecret = GetPowerPercent(unit, powerType)
	if percent == nil then return "" end

	-- Power tags omit the % sign by convention (user can append it in ElvUI text format)
	-- For secret values, fall back to 0 decimals since we can't know the precision
	local decimals = isSecret and 0 or decimalPlaces
	return FormatPercent(percent, decimals, false)
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
