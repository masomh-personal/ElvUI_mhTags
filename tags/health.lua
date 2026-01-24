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
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitHealthPercent = UnitHealthPercent
local UnitHealthMissing = UnitHealthMissing
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local issecretvalue = issecretvalue

-- ===================================================================================
-- CONSTANTS
-- ===================================================================================

local HEALTH_SUBCATEGORY = "health"
local ABSORB_TEXT_COLOR = MHCT.ABSORB_TEXT_COLOR

-- Common display constants
local VERTICAL_SEPARATOR = " | "

-- Pre-built common format strings to reduce concatenation
local PERCENT_FORMAT = "%.1f%%"
local DEFICIT_FORMAT = "-%s"
local ABSORB_FORMAT_START = "|cff" .. ABSORB_TEXT_COLOR .. "("
local ABSORB_FORMAT_END = ")|r "

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

-- Fallback text for secret values
local SECRET_FALLBACK_TEXT = MHCT.SECRET_VALUE_FALLBACK_TEXT

-- Format absorb shield if present, secret-safe
local function getAbsorbText(unit)
	if not unit then
		return ""
	end

	local absorbAmount = UnitGetTotalAbsorbs(unit)

	-- Guard: Check for nil first
	if not absorbAmount then
		return ""
	end

	-- Secret value check - can't compare or use in math
	if issecretvalue(absorbAmount) then
		return ""
	end

	-- Now safe to compare - must be positive
	if absorbAmount <= 0 then
		return ""
	end

	-- Use MHCT.FormatLargeNumber (secret-safe)
	local result = FormatLargeNumber(absorbAmount)
	if result then
		return ABSORB_FORMAT_START .. result .. ABSORB_FORMAT_END
	end

	return ""
end

-- Safe wrapper for E:GetFormattedText that handles secret values
-- Returns formatted text or nil if values are secret
local function safeGetFormattedText(formatType, currentHp, maxHp)
	if issecretvalue(currentHp) or issecretvalue(maxHp) then
		return nil
	end
	local ok, result = pcall(E.GetFormattedText, E, formatType, currentHp, maxHp, nil, true)
	return ok and result or nil
end

-- Check if any health value is secret
local function isHealthDataSecret(currentHp, maxHp, percent)
	return issecretvalue(currentHp) or issecretvalue(maxHp) or (percent and issecretvalue(percent))
end

-- Local format helper using shared PERCENT_FORMATS from core.lua
local function formatPercentValue(value, decimals)
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

-- Current health value only (uses ElvUI's smart formatting)
MHCT.registerTag(
	"mh-health-current",
	HEALTH_SUBCATEGORY,
	"Current health using ElvUI formatting. Example: 100k",
	EVENTS.HEALTH_ONLY,
	function(unit)
		if not unit then
			return ""
		end
		local currentHp = UnitHealth(unit)
		local maxHp = UnitHealthMax(unit)

		-- Secret values: show fallback
		local currentText = safeGetFormattedText("CURRENT", currentHp, maxHp)
		if not currentText then
			return SECRET_FALLBACK_TEXT
		end

		if maxHp == 0 then
			return ""
		end
		return currentText
	end
)

-- Current health with absorb shield
MHCT.registerTag(
	"mh-health-current-absorb",
	HEALTH_SUBCATEGORY,
	"Current health with absorb shown first. Example: (25k) 100k",
	EVENTS.HEALTH_ABSORB,
	function(unit)
		if not unit then
			return ""
		end
		local currentHp = UnitHealth(unit)
		local maxHp = UnitHealthMax(unit)
		local absorbText = getAbsorbText(unit)

		-- Secret values: show fallback
		local currentText = safeGetFormattedText("CURRENT", currentHp, maxHp)
		if not currentText then
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
	"Health percent with status check. Use {N} for decimals. Example: 85.2%",
	EVENTS.HEALTH_STATUS,
	function(unit, _, args)
		if not unit then
			return ""
		end

		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp = UnitHealth(unit)
		local maxHp = UnitHealthMax(unit)
		local percent = UnitHealthPercent(unit)

		-- Secret value: show fallback
		if isHealthDataSecret(currentHp, maxHp, percent) then
			return SECRET_FALLBACK_TEXT
		end

		-- At full health: show formatted health value
		if percent >= 100 then
			return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		end

		local decimals = MHCT.parseDecimalArg(args, 1)
		return formatPercentValue(percent, decimals) .. "%"
	end
)

-- Percentage without % sign
MHCT.registerTag(
	"mh-health-percent-nosign",
	HEALTH_SUBCATEGORY,
	"Health percent without % sign; status-aware. Use {N} for decimals. Example: 85.2",
	EVENTS.HEALTH_STATUS,
	function(unit, _, args)
		if not unit then
			return ""
		end

		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp = UnitHealth(unit)
		local maxHp = UnitHealthMax(unit)
		local percent = UnitHealthPercent(unit)

		-- Secret value: show fallback
		if isHealthDataSecret(currentHp, maxHp, percent) then
			return SECRET_FALLBACK_TEXT
		end

		-- At full health: show formatted health value
		if percent >= 100 then
			return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		end

		local decimals = MHCT.parseDecimalArg(args, 1)
		return formatPercentValue(percent, decimals)
	end
)

-- ===================================================================================
-- SECTION 3: COMBINED HEALTH AND PERCENTAGE
-- ===================================================================================
-- Tags that show both current health and percentage in various formats

-- Current | Percent (shows both always)
MHCT.registerTag(
	"mh-health-current-percent",
	HEALTH_SUBCATEGORY,
	"Current and percent. Example: 100k | 85%",
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
		local maxHp = UnitHealthMax(unit)
		local percent = UnitHealthPercent(unit)

		-- Secret value: show fallback
		if isHealthDataSecret(currentHp, maxHp, percent) then
			return SECRET_FALLBACK_TEXT
		end

		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		local percentText = format(PERCENT_FORMAT, percent)
		return currentText .. VERTICAL_SEPARATOR .. percentText
	end
)

-- Percent | Current (shows both always)
MHCT.registerTag(
	"mh-health-percent-current",
	HEALTH_SUBCATEGORY,
	"Percent and current. Example: 85% | 100k",
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
		local maxHp = UnitHealthMax(unit)
		local percent = UnitHealthPercent(unit)

		-- Secret value: show fallback
		if isHealthDataSecret(currentHp, maxHp, percent) then
			return SECRET_FALLBACK_TEXT
		end

		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		local percentText = format(PERCENT_FORMAT, percent)
		return percentText .. VERTICAL_SEPARATOR .. currentText
	end
)

-- Current | Percent (hides percent at full health)
MHCT.registerTag(
	"mh-health-current-percent-hidefull",
	HEALTH_SUBCATEGORY,
	"Current | percent; hides percent at full. Example: 100k | 85%",
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
		local maxHp = UnitHealthMax(unit)
		local percent = UnitHealthPercent(unit)

		-- Secret value: show fallback
		if isHealthDataSecret(currentHp, maxHp, percent) then
			return SECRET_FALLBACK_TEXT
		end

		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		-- Full health: show only current
		if percent >= 100 then
			return currentText
		end

		local percentText = format(PERCENT_FORMAT, percent)
		return currentText .. VERTICAL_SEPARATOR .. percentText
	end
)

-- Percent | Current (hides percent at full health)
MHCT.registerTag(
	"mh-health-percent-current-hidefull",
	HEALTH_SUBCATEGORY,
	"Percent | current; hides percent at full. Example: 85% | 100k",
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
		local maxHp = UnitHealthMax(unit)
		local percent = UnitHealthPercent(unit)

		-- Secret value: show fallback
		if isHealthDataSecret(currentHp, maxHp, percent) then
			return SECRET_FALLBACK_TEXT
		end

		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		-- Full health: show only current
		if percent >= 100 then
			return currentText
		end

		local percentText = format(PERCENT_FORMAT, percent)
		return percentText .. VERTICAL_SEPARATOR .. currentText
	end
)

-- Current | Percent with absorb shield
MHCT.registerTag(
	"mh-health-current-percent-absorb",
	HEALTH_SUBCATEGORY,
	"Absorb + current | percent. Example: (25k) 100k | 85%",
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
		local maxHp = UnitHealthMax(unit)
		local percent = UnitHealthPercent(unit)
		local absorbText = getAbsorbText(unit)

		-- Secret value: show fallback
		if isHealthDataSecret(currentHp, maxHp, percent) then
			return absorbText .. SECRET_FALLBACK_TEXT
		end

		local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		-- Full health: show only current with absorb
		if percent >= 100 then
			return absorbText .. currentText
		end

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

		return format(DEFICIT_FORMAT, E:ShortValue(missing))
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

		return format(DEFICIT_FORMAT, E:ShortValue(missing))
	end
)

-- Percentage deficit with status
MHCT.registerTag(
	"mh-health-deficit-percent",
	HEALTH_SUBCATEGORY,
	"Missing health as percent with status. Use {N} for decimals. Example: -15%",
	EVENTS.HEALTH_STATUS,
	function(unit, _, args)
		if not unit then
			return ""
		end

		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local percent = UnitHealthPercent(unit)

		-- Secret value or full health: no deficit to show
		if issecretvalue(percent) or percent >= 100 then
			return ""
		end

		local decimals = MHCT.parseDecimalArg(args, 1)
		local deficit = 100 - percent
		return "-" .. formatPercentValue(deficit, decimals) .. "%"
	end
)

-- ===================================================================================
-- SECTION 5: DEPRECATED - COLORED HEALTH DISPLAYS
-- ===================================================================================
-- NOTE: Health-based gradient coloring is NOT POSSIBLE in WoW 12.0+ for secret values.
-- Blizzard's secret value system blocks ALL operations needed for gradient lookup:
-- - Cannot use secret values as table keys
-- - Cannot do tonumber() on secret-derived strings  
-- - Cannot do string.byte(), string.len(), or pattern matching on secret strings
-- - Only string.format() works for display purposes
--
-- All colored health tags have been REMOVED in v9.0.
-- Use non-colored tags or reaction-based coloring (UnitReaction) instead.
-- ===================================================================================

-- ===================================================================================
-- SECTION 8: LEGACY/COMPATIBILITY TAGS
-- ===================================================================================
-- These maintain backwards compatibility with old tag names using aliases
-- Aliases share the same function reference (zero performance overhead, no duplication)

MHCT.registerTagAlias("mh-health:current:percent:right", "mh-health-current-percent")
MHCT.registerTagAlias("mh-health:current:percent:left", "mh-health-percent-current")
MHCT.registerTagAlias("mh-health:current:percent:right-hidefull", "mh-health-current-percent-hidefull")
MHCT.registerTagAlias("mh-health:current:percent:left-hidefull", "mh-health-percent-current-hidefull")

