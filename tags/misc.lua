-- ===================================================================================
-- MISCELLANEOUS TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references from core (shared to avoid duplicate unpacking)
local E = MHCT.E

-- Localize Lua functions
local format = string.format

-- Localize WoW API functions
local UnitEffectiveLevel = UnitEffectiveLevel
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local strupper = strupper
local UnitAura = UnitAura
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitAffectingCombat = UnitAffectingCombat

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
		if not unit then
			return ""
		end
		local unitLevel = UnitEffectiveLevel(unit)
		local playerLevel = UnitEffectiveLevel("player")

		-- Optimize conditional logic - check if we need to show level at all
		if playerLevel == MAX_PLAYER_LEVEL and unitLevel == MAX_PLAYER_LEVEL then
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
	"Simple absorb tag in parentheses (with yellow text color)",
	"UNIT_ABSORB_AMOUNT_CHANGED",
	function(unit)
		if not unit then
			return ""
		end

		local absorbAmount = UnitGetTotalAbsorbs(unit)

		-- Guard: Must be a valid positive number
		if not absorbAmount or type(absorbAmount) ~= "number" or absorbAmount <= 0 then
			return ""
		end

		-- Use ElvUI's ShortValue (wrap in pcall for safety)
		local success, result = pcall(function()
			return E:ShortValue(absorbAmount)
		end)
		if success and result then
			return format("|cff%s(%s)|r", ABSORB_TEXT_COLOR, result)
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
	if hideAtMax and playerLevel == unitLevel and playerLevel == MAX_PLAYER_LEVEL then
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
		if not unit then
			return ""
		end
		return formatDifficultyLevel(unit, false) -- false = don't hide at max level
	end
)

MHCT.registerTag(
	"mh-difficultycolor:level-hide",
	MISC_SUBCATEGORY,
	"Traditional ElvUI difficulty color + level with more modern updates (will always show level and only hide level when you reach max level and unit level is equal to player level)",
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

-- ===================================================================================
-- HEALER DRINKING TAG (5-MAN PARTY ONLY)
-- ===================================================================================

-- Check if unit is drinking (optimized for retail WoW 11.2.5+)
local function isDrinking(unit)
	if not unit then
		return false
	end

	-- CRITICAL: Cannot drink in combat - early exit (massive performance gain)
	if UnitAffectingCombat(unit) then
		return false
	end

	-- Scan all buffs (must be thorough since buffs can stack and drinks can appear anywhere)
	for i = 1, 40 do
		local name = UnitAura(unit, i, "HELPFUL")
		if not name then
			break -- No more buffs
		end

		-- Modern retail WoW: Nearly all drink buffs contain "Drink" or "Refreshment" in the name
		-- This covers: Water, Mage Food, Conjured items, vendor drinks, etc.
		-- Examples: "Drink", "Food & Drink", "Refreshing Spring Water", "Conjured Mana Strudel"
		if name:find("Drink") or name:find("Refreshment") then
			return true
		end
	end

	return false
end

-- Healer drinking tag - only shows in party (5-man) for healers
MHCT.registerTag(
	"mh-healer-drinking",
	MISC_SUBCATEGORY,
	"Shows 'Drinking...' only for healers drinking in 5-man party content (returns empty otherwise). Example: Drinking...",
	"UNIT_AURA",
	function(unit)
		if not unit then
			return ""
		end

		-- Fail early: Only show for healers (most units won't be healers)
		local role = UnitGroupRolesAssigned(unit)
		if role ~= "HEALER" then
			return ""
		end

		-- Only works in party (5-man), NOT in raids
		if not IsInGroup() or IsInRaid() then
			return ""
		end

		-- Check if drinking
		if isDrinking(unit) then
			return "|cff00ccffDrinking...|r"
		end

		return ""
	end
)
