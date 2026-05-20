-- ===================================================================================
-- UNIFIED HEALTH TAGS - WoW 12.0+ (Midnight)
-- ===================================================================================
-- This file contains all health-related tags for ElvUI_mhTags
-- Requires WoW 12.0+ - uses native UnitHealthPercent/UnitHealthMissing APIs
--
-- Secret Value Handling:
-- In rated PvP and competitive content, health values may be "secret" and cannot
-- be compared or used in arithmetic. We use issecretvalue() to detect this and
-- fall back to displaying raw health values with a neutral color.
-- ===================================================================================

local _, ns = ...
local MHCT = ns.MHCT

-- Localize WoW 12.0+ API functions (required - no fallbacks)
local UnitHealth = UnitHealth
local UnitHealthMissing = UnitHealthMissing
local issecretvalue = issecretvalue

-- ===================================================================================
-- CONSTANTS
-- ===================================================================================

local HEALTH_SUBCATEGORY = "health"

-- Common display constants
local VERTICAL_SEPARATOR = " | "

-- Event constant groups for clarity and maintainability
local EVENTS = {
	HEALTH_ONLY = "UNIT_HEALTH UNIT_MAXHEALTH",
	HEALTH_STATUS = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	HEALTH_ABSORB = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
	HEALTH_ABSORB_STATUS = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
}

-- ===================================================================================
-- SHARED HELPER FUNCTIONS
-- Uses utility functions from core.lua for DRY secret-safe operations
-- ===================================================================================

-- Localize core utility functions for performance
local FormatLargeNumber = MHCT.FormatLargeNumber
local FormatPercent     = MHCT.FormatPercent
local GetHealthPercent  = MHCT.GetHealthPercent
local getAbsorbText     = MHCT.getAbsorbText

-- Fallback text for secret values
local SECRET_FALLBACK_TEXT = MHCT.SECRET_VALUE_FALLBACK_TEXT

-- ===================================================================================
-- SECTION 1: BASIC HEALTH DISPLAY
-- ===================================================================================
-- These tags show current health value with various formatting options

-- Current health value only (uses secret-safe formatting)
MHCT.registerTag(
	"mh-health-current",
	HEALTH_SUBCATEGORY,
	"Current health formatted. Example: 100k",
	EVENTS.HEALTH_ONLY,
	function(unit)
		if not unit then
			return ""
		end
		
		local currentHp = UnitHealth(unit)

		-- Use secret-safe formatting
		local currentText = FormatLargeNumber(currentHp)
		if currentText == nil then
			return SECRET_FALLBACK_TEXT
		end

		return currentText
	end
)

-- Current health with absorb shield
MHCT.registerTag(
	"mh-health-current-absorb",
	HEALTH_SUBCATEGORY,
	"Current health with absorb shown first. No color applied to absorb; use color tags if desired. Example: (25k) 100k",
	EVENTS.HEALTH_ABSORB,
	function(unit)
		if not unit then
			return ""
		end

		local currentHp = UnitHealth(unit)
		-- withTrailingSpace=true so absorb and health are separated: "(25k) 100k"
		local absorbText = getAbsorbText(unit, true)

		local currentText = FormatLargeNumber(currentHp)
		if currentText == nil then
			return absorbText .. SECRET_FALLBACK_TEXT
		end

		return absorbText .. currentText
	end
)

-- ===================================================================================
-- SECTION 2: HEALTH PERCENTAGE
-- ===================================================================================
-- Tags that display health as a percentage with various options

-- Simple percentage with configurable decimals and status check
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

		-- Get percent (0-100 range) - works even for secret values
		local percent, percentIsSecret = GetHealthPercent(unit)
		if not percentIsSecret and percent == nil then
			return SECRET_FALLBACK_TEXT
		end

		local decimals = MHCT.parseDecimalArg(args, 1)
		return FormatPercent(percent, decimals, true)
	end
)

-- Percentage without % sign
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

		local percent, percentIsSecret = GetHealthPercent(unit)
		if not percentIsSecret and percent == nil then
			return SECRET_FALLBACK_TEXT
		end

		local decimals = MHCT.parseDecimalArg(args, 1)
		-- includeSign=false: returns raw number, no % appended
		return FormatPercent(percent, decimals, false)
	end
)

-- ===================================================================================
-- SECTION 3: COMBINED HEALTH AND PERCENTAGE
-- ===================================================================================
-- Tags that show both current health and percentage in various formats

-- Current | Percent (always shows both)
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

		local currentHp = UnitHealth(unit)
		local percent, percentIsSecret = GetHealthPercent(unit)

		if not percentIsSecret and percent == nil then
			return SECRET_FALLBACK_TEXT
		end

		local currentText = FormatLargeNumber(currentHp)
		-- Fixed at 1 decimal to match original PERCENT_FORMAT ("%.1f%%")
		local percentText = FormatPercent(percent, 1, true)
		return currentText .. VERTICAL_SEPARATOR .. percentText
	end
)

-- Percent | Current (always shows both)
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

		local currentHp = UnitHealth(unit)
		local percent, percentIsSecret = GetHealthPercent(unit)

		if not percentIsSecret and percent == nil then
			return SECRET_FALLBACK_TEXT
		end

		local currentText = FormatLargeNumber(currentHp)
		local percentText = FormatPercent(percent, 1, true)
		return percentText .. VERTICAL_SEPARATOR .. currentText
	end
)

-- Current | Percent with absorb shield (always shows both)
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

		local currentHp = UnitHealth(unit)
		local percent, percentIsSecret = GetHealthPercent(unit)
		-- withTrailingSpace=true so absorb prefixes inline: "(25k) 100k | 85%"
		local absorbText = getAbsorbText(unit, true)

		if not percentIsSecret and percent == nil then
			return absorbText .. SECRET_FALLBACK_TEXT
		end

		local currentText = FormatLargeNumber(currentHp)
		local percentText = FormatPercent(percent, 1, true)
		return absorbText .. currentText .. VERTICAL_SEPARATOR .. percentText
	end
)

-- ===================================================================================
-- SECTION 4: HEALTH DEFICIT
-- ===================================================================================
-- Tags that show missing health in various formats
-- Uses WoW 12.0+ native UnitHealthMissing() API

-- Numeric deficit with status
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

		-- Secret value or no deficit: return empty
		if issecretvalue(missing) or missing == 0 then
			return ""
		end

		-- FormatLargeNumber matches the abbreviation style of mh-health-current
		-- (AbbreviateNumbers, e.g. "15k") so paired tags stay visually consistent
		return "-" .. MHCT.FormatLargeNumber(missing)
	end
)

-- Numeric deficit without status check
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

		-- Secret value or no deficit: return empty
		if issecretvalue(missing) or missing == 0 then
			return ""
		end

		return "-" .. MHCT.FormatLargeNumber(missing)
	end
)

-- Percentage deficit with status
-- Note: Secret values (restricted PvP/encounters) cannot have arithmetic applied —
-- 100 - secret would error. We already know isSecret from GetHealthPercent, so we
-- branch directly instead of using a pcall closure.
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

		local percent, percentIsSecret = GetHealthPercent(unit)

		-- Can't compute deficit on secret values; also nothing to show at full health
		if percentIsSecret or percent == nil then
			return ""
		end

		local deficit = 100 - percent
		if deficit <= 0 then
			return ""
		end

		local decimals = MHCT.parseDecimalArg(args, 1)
		return "-" .. FormatPercent(deficit, decimals, true)
	end
)
