-- ===================================================================================
-- MISCELLANEOUS TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references from core (shared to avoid duplicate unpacking)
local E = MHCT.E

-- Localize Lua functions
local format = string.format
local lower = string.lower

-- Localize WoW API functions
local UnitEffectiveLevel = UnitEffectiveLevel
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local strupper = strupper
local C_UnitAuras = C_UnitAuras
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
-- HEALER DRINKING TAG
-- ===================================================================================

-- Exact match lookup for common drinking/food buffs (fastest path)
local DRINK_EXACT_MATCHES = {
	["drink"] = true,
	["food"] = true,
	["food & drink"] = true,
	["refreshment"] = true,
}

-- Fallback substring keywords for variations (e.g., "Refreshing Spring Water")
local DRINK_SUBSTRING_KEYWORDS = { "drink", "food", "refreshment" }

-- Pre-built drinking text constant (avoid allocating on every call)
local DRINKING_TEXT = "|cff1f6bffDRINKING...|r"

-- Check if name contains any drink/food keywords (optimized)
local function containsDrinkKeyword(nameLower)
	-- Fast path: exact match lookup (O(1))
	if DRINK_EXACT_MATCHES[nameLower] then
		return true
	end

	-- Fallback: substring search for variations
	for _, keyword in ipairs(DRINK_SUBSTRING_KEYWORDS) do
		if nameLower:find(keyword, 1, true) then -- true = plain search (faster)
			return true
		end
	end
	return false
end

-- Check if unit is drinking (optimized for retail WoW 11.2.5+)
local function isDrinking(unit)
	if not unit then
		return false
	end

	-- CRITICAL: Cannot drink in combat - early exit (massive performance gain)
	if UnitAffectingCombat(unit) then
		return false
	end

	-- Scan all buffs using modern C_UnitAuras API (WoW 10.0+)
	for i = 1, 40 do
		local auraData = C_UnitAuras.GetBuffDataByIndex(unit, i)
		if not auraData then
			break -- No more buffs
		end

		-- Modern retail WoW: Nearly all drink/food buffs contain "Drink", "Food", or "Refreshment" in the name
		-- This covers: Water, Mage Food, Conjured items, vendor drinks, food items, etc.
		-- Examples: "Drink", "Food", "Food & Drink", "Refreshing Spring Water", "Conjured Mana Strudel"
		local name = auraData.name
		if name then
			local nameLower = lower(name)
			if containsDrinkKeyword(nameLower) then
				return true
			end
		end
	end

	return false
end

-- Healer drinking tag - shows for healers in any scenario (solo, party, raid)
MHCT.registerTag(
	"mh-healer-drinking",
	MISC_SUBCATEGORY,
	"Shows 'DRINKING...' only for healers drinking/eating (works in any scenario: solo, party, or raid). Example: DRINKING...",
	"UNIT_AURA UNIT_POWER_UPDATE",
	function(unit)
		if not unit then
			return ""
		end

		-- Early exit: Only show for healers (most units won't be healers)
		local role = UnitGroupRolesAssigned(unit)
		if role ~= "HEALER" then
			return ""
		end

		-- Check if drinking/eating (combat check happens inside isDrinking)
		if isDrinking(unit) then
			return DRINKING_TEXT
		end

		return ""
	end
)
