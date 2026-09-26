-- Level, absorb, difficulty, and status tags. Level comparisons go through
-- MHCT.isAtMaxLevelTogether and absorb display through MHCT.getAbsorbText.
local _, ns = ...
local MHCT = ns.MHCT

local UnitEffectiveLevel = UnitEffectiveLevel
local issecretvalue = issecretvalue

local MISC_SUBCATEGORY = "misc"
local UNKNOWN_LEVEL_TEXT = MHCT.UNKNOWN_LEVEL_TEXT

MHCT.registerTag(
	"mh-smartlevel",
	MISC_SUBCATEGORY,
	"Simple tag to show all unit levels if player is not max level. If max level, will show level of all non max level units",
	"UNIT_LEVEL PLAYER_LEVEL_UP",
	function(unit)
		if not unit then
			return ""
		end
		if MHCT.isAtMaxLevelTogether(unit) then
			return ""
		end
		local level = UnitEffectiveLevel(unit)
		if not issecretvalue(level) and level < 0 then
			return UNKNOWN_LEVEL_TEXT
		end
		return level
	end
)

MHCT.registerTag(
	"mh-absorb",
	MISC_SUBCATEGORY,
	"Absorb shield amount in parentheses. No color applied; use with color tags if desired. Example: [mh-color-yellow][mh-absorb]|r",
	"UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		return MHCT.getAbsorbText(unit, false)
	end
)

local function formatDifficultyLevel(unit, hideAtMax)
	if not unit then
		return ""
	end
	if hideAtMax and MHCT.isAtMaxLevelTogether(unit) then
		return ""
	end
	return MHCT.difficultyLevelFormatter(unit, UnitEffectiveLevel(unit))
end

MHCT.registerTag(
	"mh-diff-level",
	MISC_SUBCATEGORY,
	"Unit level colored by difficulty (gray/green/red). Always shows level.",
	"UNIT_LEVEL PLAYER_LEVEL_UP",
	function(unit)
		return formatDifficultyLevel(unit, false)
	end
)

MHCT.registerTag(
	"mh-diff-level-hide",
	MISC_SUBCATEGORY,
	"Unit level colored by difficulty. Hides when you and the unit are both max level.",
	"UNIT_LEVEL PLAYER_LEVEL_UP",
	function(unit)
		return formatDifficultyLevel(unit, true)
	end
)

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
		if not status then
			return ""
		end
		return MHCT.getStatusText(status)
	end
)
