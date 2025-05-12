-- ===================================================================================
-- MISCELLANEOUS TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Localize Lua functions
local format = string.format

-- Localize WoW API functions
local UnitEffectiveLevel = UnitEffectiveLevel
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local strupper = strupper

-- ElvUI reference (for ShortValue)
local E = unpack(ElvUI)

-- Local constants
local MISC_SUBCATEGORY = "misc"
local MAX_PLAYER_LEVEL = MHCT.MAX_PLAYER_LEVEL
local ABSORB_TEXT_COLOR = MHCT.ABSORB_TEXT_COLOR

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
		local unitLevel = UnitEffectiveLevel(unit)
		local playerLevel = UnitEffectiveLevel("player")

		-- if player is NOT max level, show level
		if playerLevel ~= MAX_PLAYER_LEVEL then
			return unitLevel
		else
			-- else only show unit level if unit is NOT max level
			return MAX_PLAYER_LEVEL == unitLevel and "" or unitLevel
		end
	end
)

-- Absorb amount tag
MHCT.registerTag(
	"mh-absorb",
	MISC_SUBCATEGORY,
	"Simple absorb tag in parentheses (with yellow text color)",
	"UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount ~= 0 then
			return format("|cff%s(%s)|r", ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
		end
		return ""
	end
)

-- Difficulty colored level tag
MHCT.registerTag(
	"mh-difficultycolor:level",
	MISC_SUBCATEGORY,
	"Traditional ElvUI difficulty color + level with more modern updates (will always show level)",
	"UNIT_LEVEL PLAYER_LEVEL_UP",
	function(unit)
		return MHCT.difficultyLevelFormatter(unit, UnitEffectiveLevel(unit))
	end
)

-- Difficulty colored level that hides at max level
MHCT.registerTag(
	"mh-difficultycolor:level-hide",
	MISC_SUBCATEGORY,
	"Traditional ElvUI difficulty color + level with more modern updates (will always show level and only hide level when you reach max level and unit level is equal to player level)",
	"UNIT_LEVEL PLAYER_LEVEL_UP",
	function(unit)
		local unitLevel = UnitEffectiveLevel(unit)
		local playerLevel = UnitEffectiveLevel("player")

		if playerLevel == unitLevel and playerLevel == MAX_PLAYER_LEVEL then
			return ""
		end

		return MHCT.difficultyLevelFormatter(unit, unitLevel)
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
		return MHCT.formatWithStatusCheck(unit) or ""
	end
)

-- Status tag without icons
MHCT.registerTag(
	"mh-status-noicon",
	MISC_SUBCATEGORY,
	"Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (NO icon, text only)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local status = MHCT.statusCheck(unit)
		if status then
			return format("|cffD6BFA6%s|r", strupper(status))
		end
		return ""
	end
)
