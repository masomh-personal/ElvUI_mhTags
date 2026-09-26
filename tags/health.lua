-- Health tags. Health values may be secret in restricted content: shared helpers
-- format them directly, and deficit tags hide when their arithmetic is unavailable.
local _, ns = ...
local MHCT = ns.MHCT

local UnitHealth = UnitHealth
local UnitHealthMissing = UnitHealthMissing
local issecretvalue = issecretvalue

local FormatLargeNumber = MHCT.FormatLargeNumber
local FormatPercent = MHCT.FormatPercent
local GetHealthPercent = MHCT.GetHealthPercent
local getAbsorbText = MHCT.getAbsorbText

local HEALTH_SUBCATEGORY = "health"
local SECRET_FALLBACK_TEXT = MHCT.SECRET_VALUE_FALLBACK_TEXT
local VERTICAL_SEPARATOR = " | "

local EVENTS = {
	HEALTH_ONLY = "UNIT_HEALTH UNIT_MAXHEALTH",
	HEALTH_STATUS = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	HEALTH_ABSORB = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	HEALTH_ABSORB_STATUS = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
}

MHCT.registerTag(
	"mh-health-current",
	HEALTH_SUBCATEGORY,
	"Current health formatted. Example: 100k",
	EVENTS.HEALTH_ONLY,
	function(unit)
		if not unit then
			return ""
		end
		return FormatLargeNumber(UnitHealth(unit))
	end
)

MHCT.registerTag(
	"mh-health-current-absorb",
	HEALTH_SUBCATEGORY,
	"Current health with absorb shown first. No color applied to absorb; use color tags if desired. Example: (25k) 100k",
	EVENTS.HEALTH_ABSORB,
	function(unit)
		if not unit then
			return ""
		end
		return getAbsorbText(unit, true) .. FormatLargeNumber(UnitHealth(unit))
	end
)

MHCT.registerTag(
	"mh-health-percent",
	HEALTH_SUBCATEGORY,
	"Health percent, status-aware. Use {N} for decimals (default 1). Example: [mh-health-percent{1}]",
	EVENTS.HEALTH_STATUS,
	function(unit, _, args)
		if not unit then
			return ""
		end

		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return FormatPercent(GetHealthPercent(unit), MHCT.parseDecimalArg(args, 1), true)
	end
)

MHCT.registerTag(
	"mh-health-percent-nosign",
	HEALTH_SUBCATEGORY,
	"Health percent without % sign, status-aware. Use {N} for decimals (default 1). Example: [mh-health-percent-nosign{1}]",
	EVENTS.HEALTH_STATUS,
	function(unit, _, args)
		if not unit then
			return ""
		end

		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return FormatPercent(GetHealthPercent(unit), MHCT.parseDecimalArg(args, 1), false)
	end
)

MHCT.registerTag(
	"mh-health-current-percent",
	HEALTH_SUBCATEGORY,
	"Current health and percent. Example: 100k | 85%",
	EVENTS.HEALTH_STATUS,
	function(unit)
		if not unit then
			return ""
		end

		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local percent = GetHealthPercent(unit)
		if percent == nil then
			return SECRET_FALLBACK_TEXT
		end

		return FormatLargeNumber(UnitHealth(unit)) .. VERTICAL_SEPARATOR .. FormatPercent(percent, 1, true)
	end
)

MHCT.registerTag(
	"mh-health-percent-current",
	HEALTH_SUBCATEGORY,
	"Percent and current health. Example: 85% | 100k",
	EVENTS.HEALTH_STATUS,
	function(unit)
		if not unit then
			return ""
		end

		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local percent = GetHealthPercent(unit)
		if percent == nil then
			return SECRET_FALLBACK_TEXT
		end

		return FormatPercent(percent, 1, true) .. VERTICAL_SEPARATOR .. FormatLargeNumber(UnitHealth(unit))
	end
)

MHCT.registerTag(
	"mh-health-current-percent-absorb",
	HEALTH_SUBCATEGORY,
	"Absorb + current | percent. No color applied to absorb; use color tags if desired. Example: (25k) 100k | 85%",
	EVENTS.HEALTH_ABSORB_STATUS,
	function(unit)
		if not unit then
			return ""
		end

		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local absorbText = getAbsorbText(unit, true)
		local percent = GetHealthPercent(unit)
		if percent == nil then
			return absorbText .. SECRET_FALLBACK_TEXT
		end

		return absorbText
			.. FormatLargeNumber(UnitHealth(unit))
			.. VERTICAL_SEPARATOR
			.. FormatPercent(percent, 1, true)
	end
)

MHCT.registerTag(
	"mh-health-deficit",
	HEALTH_SUBCATEGORY,
	"Missing health or status (AFK/Dead/etc). Example: -15k",
	EVENTS.HEALTH_STATUS,
	function(unit)
		if not unit then
			return ""
		end

		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local missing = UnitHealthMissing(unit)
		if issecretvalue(missing) or missing == 0 then
			return ""
		end
		return "-" .. FormatLargeNumber(missing)
	end
)

MHCT.registerTag(
	"mh-health-deficit-nostatus",
	HEALTH_SUBCATEGORY,
	"Missing health only (no status). Example: -15k",
	EVENTS.HEALTH_ONLY,
	function(unit)
		if not unit then
			return ""
		end

		local missing = UnitHealthMissing(unit)
		if issecretvalue(missing) or missing == 0 then
			return ""
		end
		return "-" .. FormatLargeNumber(missing)
	end
)

MHCT.registerTag(
	"mh-health-deficit-percent",
	HEALTH_SUBCATEGORY,
	"Missing health as percent, status-aware. Use {N} for decimals (default 1). Example: [mh-health-deficit-percent{1}]",
	EVENTS.HEALTH_STATUS,
	function(unit, _, args)
		if not unit then
			return ""
		end

		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		-- Secret percentages cannot be subtracted from 100 in Lua.
		local percent, percentIsSecret = GetHealthPercent(unit)
		if percentIsSecret or percent == nil then
			return ""
		end

		local deficit = 100 - percent
		if deficit <= 0 then
			return ""
		end

		return "-" .. FormatPercent(deficit, MHCT.parseDecimalArg(args, 1), true)
	end
)
