-- ===================================================================================
-- MISCELLANEOUS TAGS
-- ===================================================================================
--
-- WoW 12.0+ Compatibility:
-- UnitEffectiveLevel and UnitGetTotalAbsorbs CAN return secret values in restricted
-- contexts (rated PvP, encounters). Level comparisons are routed through
-- MHCT.isAtMaxLevelTogether; absorb display is handled by MHCT.getAbsorbText.
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Localize Lua functions
local format = string.format

-- Localize WoW API functions
local UnitEffectiveLevel = UnitEffectiveLevel
local strupper = strupper

-- Local constants
local MISC_SUBCATEGORY = "misc"

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
		-- Hide level entirely when both player and unit are confirmed max level
		if MHCT.isAtMaxLevelTogether(unit) then
			return ""
		end
		return UnitEffectiveLevel(unit)
	end
)

MHCT.registerTag(
	"mh-absorb",
	MISC_SUBCATEGORY,
	"Absorb shield amount in parentheses. No color applied; use with color tags if desired. Example: [mh-color-yellow][mh-absorb]|r",
	"UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		-- withTrailingSpace=false: standalone tag, no trailing space needed
		return MHCT.getAbsorbText(unit, false)
	end
)

-- ===================================================================================
-- DIFFICULTY TAGS
-- ===================================================================================

-- Helper function for difficulty level formatting.
-- hideAtMax: when true, returns "" if both player and unit are max level.
local function formatDifficultyLevel(unit, hideAtMax)
	if not unit then
		return ""
	end
	if hideAtMax and MHCT.isAtMaxLevelTogether(unit) then
		return ""
	end
	return MHCT.difficultyLevelFormatter(unit, UnitEffectiveLevel(unit))
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

		-- Use MHCT.COLORS.STATUS to stay in sync with the status color defined in core.lua
		return format("|cff%s%s|r", MHCT.COLORS.STATUS, strupper(status))
	end
)
