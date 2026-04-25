-- ===================================================================================
-- MISCELLANEOUS TAGS - Optimized for efficiency
-- ===================================================================================
--
-- WoW 12.0+ Compatibility:
-- This file uses standard WoW APIs that are compatible with 12.0's secret value system.
-- Level and absorb APIs are not affected by the new restrictions.
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Localize Lua functions
local format = string.format
local pcall = pcall

-- Localize WoW API functions
local UnitEffectiveLevel = UnitEffectiveLevel
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local strupper = strupper
local issecretvalue = issecretvalue

-- Local constants
local MISC_SUBCATEGORY = "misc"
local MAX_PLAYER_LEVEL = MHCT.MAX_PLAYER_LEVEL

-- Check whether two level values can be safely compared.
-- Secret values cannot be compared in WoW 12.x.
local function canCompareLevels(levelA, levelB)
	if issecretvalue(levelA) or issecretvalue(levelB) then
		return false
	end
	return levelA ~= nil and levelB ~= nil
end

-- ===================================================================================
-- LEVEL TAGS
-- ===================================================================================

-- Smart level tag - only shows non-max levels when player is max level
MHCT.registerTag(
	"mh-smartlevel",
	MISC_SUBCATEGORY,
	"Simple tag to show all unit levels if player is not max level. If max level, will show level of all non max level units",
	"UNIT_LEVEL PLAYER_LEVEL_UP",
	function(unit)
		if not unit then
			return ""
		end
		local unitLevel = UnitEffectiveLevel(unit)
		local playerLevel = UnitEffectiveLevel("player")

		-- Optimize conditional logic - check if we need to show level at all
		if canCompareLevels(playerLevel, unitLevel)
			and playerLevel == MAX_PLAYER_LEVEL
			and unitLevel == MAX_PLAYER_LEVEL
		then
			return ""
		end

		-- Otherwise just return the level
		return unitLevel
	end
)

-- Removed - direct formatting is simpler

MHCT.registerTag(
	"mh-absorb",
	MISC_SUBCATEGORY,
	"Absorb shield amount in parentheses. No color applied; use with color tags if desired. Example: [mh-color-yellow][mh-absorb]|r",
	"UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		if not unit then
			return ""
		end

		local absorbAmount = UnitGetTotalAbsorbs(unit)
		local absorbIsSecret = issecretvalue(absorbAmount)

		-- Guard: only nil means unavailable (secret values are still displayable)
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
		local result = MHCT.FormatLargeNumber(absorbAmount)
		if result ~= nil then
			return format("(%s)", result)
		end

		return ""
	end
)

-- ===================================================================================
-- DIFFICULTY TAGS
-- ===================================================================================

-- Helper function for difficulty level formatting
local function formatDifficultyLevel(unit, hideAtMax)
	if not unit then
		return ""
	end
	local unitLevel = UnitEffectiveLevel(unit)
	local playerLevel = UnitEffectiveLevel("player")

	-- Check if we should hide the level
	if hideAtMax
		and canCompareLevels(playerLevel, unitLevel)
		and playerLevel == unitLevel
		and playerLevel == MAX_PLAYER_LEVEL
	then
		return ""
	end

	return MHCT.difficultyLevelFormatter(unit, unitLevel)
end

-- Then use this helper in both difficulty level tags
MHCT.registerTag(
	"mh-diff-level",
	MISC_SUBCATEGORY,
	"Unit level colored by difficulty (gray/green/red). Always shows level.",
	"UNIT_LEVEL PLAYER_LEVEL_UP",
	function(unit)
		if not unit then
			return ""
		end
		return formatDifficultyLevel(unit, false) -- false = don't hide at max level
	end
)

MHCT.registerTag(
	"mh-diff-level-hide",
	MISC_SUBCATEGORY,
	"Unit level colored by difficulty. Hides when you and the unit are both max level.",
	"UNIT_LEVEL PLAYER_LEVEL_UP",
	function(unit)
		if not unit then
			return ""
		end
		return formatDifficultyLevel(unit, true) -- true = hide at max level
	end
)

-- ===================================================================================
-- STATUS TAGS
-- ===================================================================================

-- Status tag with icons
MHCT.registerTag(
	"mh-status",
	MISC_SUBCATEGORY,
	"Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (with their own icons)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		if not unit then
			return ""
		end
		return MHCT.formatWithStatusCheck(unit) or ""
	end
)

-- Removed - direct formatting is simpler

MHCT.registerTag(
	"mh-status-noicon",
	MISC_SUBCATEGORY,
	"Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (NO icon, text only)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		if not unit then
			return ""
		end
		local status = MHCT.statusCheck(unit)
		-- Early return for common case
		if not status then
			return ""
		end

		return format("|cffD6BFA6%s|r", strupper(status))
	end
)

