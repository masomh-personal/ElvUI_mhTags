-- Power tags. MHCT.GetPowerPercent scales to 0-100 in C, so secret values need no Lua math.
local _, ns = ...
local MHCT = ns.MHCT

local GetPowerPercent = MHCT.GetPowerPercent
local FormatPercent = MHCT.FormatPercent

local POWER_SUBCATEGORY = "power"
local DEFAULT_DECIMAL_PLACE = MHCT.DEFAULT_DECIMAL_PLACE

-- Power omits the % sign for compact layouts; secret values always use 0 decimals.
local function formatPowerPercent(unit, decimalPlaces)
	local percent, isSecret = GetPowerPercent(unit)
	if percent == nil then
		return ""
	end
	return FormatPercent(percent, isSecret and 0 or decimalPlaces, false)
end

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
