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

-- Cache player level to avoid repeated API calls
local cachedPlayerLevel = UnitEffectiveLevel("player")

-- Update cached player level when it changes
local function updatePlayerLevel()
	cachedPlayerLevel = UnitEffectiveLevel("player")
end

-- Register event to update cached player level
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:SetScript("OnEvent", updatePlayerLevel)

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

		-- Optimize conditional logic - check if we need to show level at all
		if cachedPlayerLevel == MAX_PLAYER_LEVEL and unitLevel == MAX_PLAYER_LEVEL then
			return ""
		end

		-- Otherwise just return the level
		return unitLevel
	end
)

MHCT.registerTag(
	"mh-absorb",
	MISC_SUBCATEGORY,
	"Simple absorb tag in parentheses (with yellow text color)",
	"UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
		-- Early return for common case
		if absorbAmount == 0 then
			return ""
		end

		return format(MHCT.COLOR_FORMATS.ABSORB, ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
	end
)

-- ===================================================================================
-- DIFFICULTY TAGS
-- ===================================================================================

-- Helper function for difficulty level formatting
local function formatDifficultyLevel(unit, hideAtMax)
	local unitLevel = UnitEffectiveLevel(unit)

	-- Check if we should hide the level
	if hideAtMax and cachedPlayerLevel == unitLevel and cachedPlayerLevel == MAX_PLAYER_LEVEL then
		return ""
	end

	return MHCT.difficultyLevelFormatter(unit, unitLevel)
end

-- Then use this helper in both difficulty level tags
MHCT.registerTag(
	"mh-difficultycolor:level",
	MISC_SUBCATEGORY,
	"Traditional ElvUI difficulty color + level with more modern updates (will always show level)",
	"UNIT_LEVEL PLAYER_LEVEL_UP",
	function(unit)
		return formatDifficultyLevel(unit, false) -- false = don't hide at max level
	end
)

MHCT.registerTag(
	"mh-difficultycolor:level-hide",
	MISC_SUBCATEGORY,
	"Traditional ElvUI difficulty color + level with more modern updates (will always show level and only hide level when you reach max level and unit level is equal to player level)",
	"UNIT_LEVEL PLAYER_LEVEL_UP",
	function(unit)
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
		return MHCT.formatWithStatusCheck(unit) or ""
	end
)

MHCT.registerTag(
	"mh-status-noicon",
	MISC_SUBCATEGORY,
	"Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (NO icon, text only)",
	"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
	function(unit)
		local status = MHCT.statusCheck(unit)
		-- Early return for common case
		if not status then
			return ""
		end

		return format(MHCT.COLOR_FORMATS.STATUS, strupper(status))
	end
)
