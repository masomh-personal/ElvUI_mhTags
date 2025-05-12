-- ===================================================================================
-- MISCELLANEOUS TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references directly
local E, L = unpack(ElvUI)

-- Localize Lua functions
local format = string.format
local floor = math.floor

-- Localize WoW API functions
local UnitEffectiveLevel = UnitEffectiveLevel
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsConnected = UnitIsConnected
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local strupper = strupper

-- Local constants
local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [misc]"
local MAX_PLAYER_LEVEL = MHCT.MAX_PLAYER_LEVEL
local ABSORB_TEXT_COLOR = MHCT.ABSORB_TEXT_COLOR

-- ===================================================================================
-- LEVEL
-- ===================================================================================
do
	E:AddTagInfo(
		"mh-smartlevel",
		thisCategory,
		"Simple tag to show all unit levels if player is not max level. If max level, will show level of all non max level units"
	)
	E:AddTag("mh-smartlevel", "UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
		local unitLevel = UnitEffectiveLevel(unit)
		local playerLevel = UnitEffectiveLevel("player")

		-- if player is NOT max level, show level
		if playerLevel ~= MAX_PLAYER_LEVEL then
			return unitLevel
		else
			-- else only show unit level if unit is NOT max level
			return MAX_PLAYER_LEVEL == unitLevel and "" or unitLevel
		end
	end)

	E:AddTagInfo("mh-absorb", thisCategory, "Simple absorb tag in parentheses (with yellow text color)")
	E:AddTag("mh-absorb", "UNIT_ABSORB_AMOUNT_CHANGED", function(unit)
		local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount ~= 0 then
			return format("|cff%s(%s)|r", ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
		end
	end)

	E:AddTagInfo(
		"mh-difficultycolor:level",
		thisCategory,
		"Traditional ElvUI difficulty color + level with more modern updates (will always show level)"
	)
	E:AddTag("mh-difficultycolor:level", "UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
		return MHCT.difficultyLevelFormatter(unit, UnitEffectiveLevel(unit))
	end)

	E:AddTagInfo(
		"mh-difficultycolor:level-hide",
		thisCategory,
		"Traditional ElvUI difficulty color + level with more modern updates (will always show level and only hide level when you reach max level and unit level is equal to player level)"
	)
	E:AddTag("mh-difficultycolor:level-hide", "UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
		local unitLevel = UnitEffectiveLevel(unit)
		local playerLevel = UnitEffectiveLevel("player")

		if playerLevel == unitLevel and playerLevel == MAX_PLAYER_LEVEL then
			return ""
		end

		return MHCT.difficultyLevelFormatter(unit, unitLevel)
	end)
end

-- ===================================================================================
-- STATUS
-- ===================================================================================
do
	E:AddTagInfo(
		"mh-status",
		thisCategory,
		"Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (with their own icons)"
	)
	E:AddTag("mh-status", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
		return MHCT.formatWithStatusCheck(unit)
	end)

	E:AddTagInfo(
		"mh-status-noicon",
		thisCategory,
		"Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (NO icon, text only)"
	)
	E:AddTag("mh-status-noicon", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
		local status = MHCT.statusCheck(unit)
		if status then
			return format("|cffD6BFA6%s|r", strupper(status))
		end
	end)
end

-- ===================================================================================
-- HEALTH COLOR (red => yellow => green sequence from 0% health to 100% health)
-- ===================================================================================
do
	E:AddTagInfo(
		"mh-healthcolor",
		thisCategory,
		"Similar color tag to base ElvUI, but with brighter and high contrast gradient"
	)
	E:AddTag("mh-healthcolor", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
		if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
			return "|cffD6BFA6" -- Precomputed Hex for dead or disconnected units
		else
			-- Calculate health percentage and round to the nearest integer percent
			local healthPercent = (UnitHealth(unit) / UnitHealthMax(unit)) * 100
			local roundedPercent = floor(healthPercent)

			-- Lookup the color in the precomputed table
			return MHCT.HEALTH_GRADIENT_RGB[roundedPercent] or "|cffFFFFFF" -- Fallback to white if not found
		end
	end)
end
