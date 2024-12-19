local _, ns = ...
local MHCT = ns.MHCT

local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [misc]"

-- ===================================================================================
-- LEVEL
-- ===================================================================================
do
	MHCT.E:AddTagInfo(
		"mh-smartlevel",
		thisCategory,
		"Simple tag to show all unit levels if player is not max level. If max level, will show level of all non max level units"
	)
	MHCT.E:AddTag("mh-smartlevel", "UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
		local unitLevel = MHCT.UnitEffectiveLevel(unit)
		local playerLevel = MHCT.UnitEffectiveLevel("player")

		-- if player is NOT max level, show level
		if playerLevel ~= MHCT.MAX_PLAYER_LEVEL then
			return unitLevel
		else
			-- else only show unit level if unit is NOT max level
			return MHCT.MAX_PLAYER_LEVEL == unitLevel and "" or unitLevel
		end
	end)

	MHCT.E:AddTagInfo("mh-absorb", thisCategory, "Simple absorb tag in parentheses (with yellow text color)")
	MHCT.E:AddTag("mh-absorb", "UNIT_ABSORB_AMOUNT_CHANGED", function(unit)
		local absorbAmount = MHCT.UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount ~= 0 then
			return MHCT.format("|cff%s(%s)|r", MHCT.ABSORB_TEXT_COLOR, MHCT.E:ShortValue(absorbAmount))
		end
	end)

	MHCT.E:AddTagInfo(
		"mh-difficultycolor:level",
		thisCategory,
		"Traditional ElvUI difficulty color + level with more modern updates (will always show level)"
	)
	MHCT.E:AddTag("mh-difficultycolor:level", "UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
		return MHCT.difficultyLevelFormatter(unit, MHCT.UnitEffectiveLevel(unit))
	end)

	MHCT.E:AddTagInfo(
		"mh-difficultycolor:level-hide",
		thisCategory,
		"Traditional ElvUI difficulty color + level with more modern updates (will always show level and only hide level when you reach max level and unit level is equal to player level)"
	)
	MHCT.E:AddTag("mh-difficultycolor:level-hide", "UNIT_LEVEL PLAYER_LEVEL_UP", function(unit)
		local unitLevel = MHCT.UnitEffectiveLevel(unit)
		local playerLevel = MHCT.UnitEffectiveLevel("player")

		if playerLevel == unitLevel and playerLevel == MHCT.MAX_PLAYER_LEVEL then
			return ""
		end

		return MHCT.difficultyLevelFormatter(unit, unitLevel)
	end)
end

-- ===================================================================================
-- STATUS
-- ===================================================================================
do
	MHCT.E:AddTagInfo(
		"mh-status",
		thisCategory,
		"Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (with their own icons)"
	)
	MHCT.E:AddTag("mh-status", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
		return MHCT.formatWithStatusCheck(unit)
	end)

	MHCT.E:AddTagInfo(
		"mh-status-noicon",
		thisCategory,
		"Simple status tag that shows all the different flags: AFK, DND, OFFLINE, DEAD, or GHOST (NO icon, text only)"
	)
	MHCT.E:AddTag("mh-status-noicon", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
		local status = MHCT.statusCheck(unit)
		if status then
			return MHCT.format("|cffD6BFA6%s|r", MHCT.strupper(status))
		end
	end)
end

-- ===================================================================================
-- HEALTH COLOR (red => yellow => green sequence from 0% health to 100% health)
-- ===================================================================================
do
	MHCT.E:AddTagInfo(
		"mh-healthcolor",
		thisCategory,
		"Similar color tag to base ElvUI, but with brighter and high contrast gradient"
	)
	MHCT.E:AddTag("mh-healthcolor", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
		if UnitIsDeadOrGhost(unit) or not MHCT.UnitIsConnected(unit) then
			return "|cffD6BFA6" -- Precomputed Hex for dead or disconnected units
		else
			-- Calculate health percentage and round to the nearest 0.5%
			local healthPercent = (MHCT.UnitHealth(unit) / MHCT.UnitHealthMax(unit)) * 100
			local roundedPercent = MHCT.floor(healthPercent)

			-- Lookup the color in the precomputed table
			return MHCT.HEALTH_GRADIENT_RGB[roundedPercent] or "|cffFFFFFF" -- Fallback to white if not found
		end
	end)
end
