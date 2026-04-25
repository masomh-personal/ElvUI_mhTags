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

-- Get ElvUI references from core (shared to avoid duplicate unpacking)
local E = MHCT.E

-- Localize Lua functions
local format = string.format
local pcall = pcall

-- Localize WoW 12.0+ API functions (required - no fallbacks)
local UnitHealth = UnitHealth
local UnitHealthMissing = UnitHealthMissing
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local issecretvalue = issecretvalue

-- ===================================================================================
-- CONSTANTS
-- ===================================================================================

local HEALTH_SUBCATEGORY = "health"

-- Common display constants
local VERTICAL_SEPARATOR = " | "

-- Pre-built common format strings to reduce concatenation
local PERCENT_FORMAT = "%.1f%%"
local DEFICIT_FORMAT = "-%s"

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
local PERCENT_FORMATS = MHCT.PERCENT_FORMATS
local GetHealthPercent = MHCT.GetHealthPercent

-- Fallback text for secret values
local SECRET_FALLBACK_TEXT = MHCT.SECRET_VALUE_FALLBACK_TEXT

-- Format absorb shield if present, secret-safe.
-- NOTE: Due to secret values, (0) may display when absorb is 0 and secret.
-- All comparison/detection methods are blocked: numeric comparison, string comparison, string length.
-- Returns plain text with parentheses; no color applied (user can use color tags if desired).
local function getAbsorbText(unit)
	if not unit then
		return ""
	end

	local absorbAmount = UnitGetTotalAbsorbs(unit)
	local absorbIsSecret = issecretvalue(absorbAmount)
	if not absorbIsSecret and absorbAmount == nil then
		return ""
	end

	-- Try to check if absorb is zero/negative (works for non-secret values only)
	local ok, isZeroOrNegative = pcall(function() return absorbAmount <= 0 end)
	
	-- If comparison succeeded and absorb is zero/negative, hide it
	if ok and isZeroOrNegative then
		return ""
	end
	
	-- If comparison failed (secret value), we cannot detect zero
	-- Display the formatted value - may show (0) for secret zero values
	local result = FormatLargeNumber(absorbAmount)
	if result == nil then
		return ""
	end
	
	-- Return plain text with parentheses and trailing space (no color)
	return "(" .. result .. ") "
end

-- Local format helper using shared PERCENT_FORMATS from core.lua
local function formatPercentValue(value, decimals)
	if decimals < 0 then
		decimals = 0
	elseif decimals > 3 then
		decimals = 3
	end

	local fmt = PERCENT_FORMATS[decimals]
	if fmt then
		return format(fmt, value)
	end
	-- Fallback for out-of-range decimals (shouldn't happen)
	return format("%.0f", value)
end

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
		local absorbText = getAbsorbText(unit)

		-- Use secret-safe formatting for current health
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

		-- Format with requested decimals - string.format works on secret values
		local decimals = MHCT.parseDecimalArg(args, 1)
		local percentText = formatPercentValue(percent, decimals) .. "%"
		return percentText
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

		-- Get percent (0-100 range) - works even for secret values
		local percent, percentIsSecret = GetHealthPercent(unit)
		if not percentIsSecret and percent == nil then
			return SECRET_FALLBACK_TEXT
		end

		-- Format with requested decimals - string.format works on secret values
		local decimals = MHCT.parseDecimalArg(args, 1)
		local percentText = formatPercentValue(percent, decimals)
		return percentText
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

		-- Use secret-safe formatting for both values
		local currentText = FormatLargeNumber(currentHp)
		local percentText = format(PERCENT_FORMAT, percent)
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

		-- Use secret-safe formatting for both values
		local currentText = FormatLargeNumber(currentHp)
		local percentText = format(PERCENT_FORMAT, percent)
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
		local absorbText = getAbsorbText(unit)

		if not percentIsSecret and percent == nil then
			return absorbText .. SECRET_FALLBACK_TEXT
		end

		-- Use secret-safe formatting for both values
		local currentText = FormatLargeNumber(currentHp)
		local percentText = format(PERCENT_FORMAT, percent)
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

		local deficitText = format(DEFICIT_FORMAT, E:ShortValue(missing))
		return deficitText
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

		local deficitText = format(DEFICIT_FORMAT, E:ShortValue(missing))
		return deficitText
	end
)

-- Percentage deficit with status
-- Note: For secret values, we show the formatted percent as-is (can't calculate deficit)
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
		if not percentIsSecret and percent == nil then
			return ""
		end

		-- For secret values, we can format but not do arithmetic
		-- Show as deficit format: display 100 - percent as "-X%"
		-- Since we can't do 100 - secret, we format the raw percent
		local decimals = MHCT.parseDecimalArg(args, 1)
		
		-- Use pcall to safely attempt arithmetic (will fail for secrets)
		local ok, deficit = pcall(function() return 100 - percent end)
		if ok and deficit > 0 then
			local deficitText = "-" .. formatPercentValue(deficit, decimals) .. "%"
			return deficitText
		end
		
		-- At full health or secret: no deficit to show
		return ""
	end
)
