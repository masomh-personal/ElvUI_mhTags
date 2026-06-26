-- ===================================================================================
-- COMBINED TAGS - All-in-one tags that combine classification, name, and level
-- ===================================================================================
--
-- Separation of concerns: keeps generic modules (name, classification, misc) lean.
-- Combined tags reuse the same logic via MHCT and WoW APIs.
-- ===================================================================================

local _, ns = ...
local MHCT = ns.MHCT

-- UnitEffectiveLevel still used directly to fetch the unit's level for display.
-- Level-comparison logic is delegated to MHCT.isAtMaxLevelTogether.
local UnitEffectiveLevel = UnitEffectiveLevel
local issecretvalue = issecretvalue

local COMBINED_SUBCATEGORY = "combined"
local DEFAULT_TEXT_LENGTH = MHCT.DEFAULT_TEXT_LENGTH
local EVENTS_COMBINED = "UNIT_CLASSIFICATION_CHANGED UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP"
local EVENTS_COMBINED_RAID = EVENTS_COMBINED .. " GROUP_ROSTER_UPDATE"

-- Helper: classification icon + name (optionally + difficulty level, optionally + raid group, optionally + smart level)
-- Icon logic matches mh-classification-icon-fixed exactly (classificationType → ICON_MAP → getFormattedIcon).
-- nameLength: max character length for name (default DEFAULT_TEXT_LENGTH).
-- includeRaidGroup: if true, append raid group via MHCT.appendRaidGroupToName (same as mh-name-caps-with-raid-group).
-- useSmartLevel: if true, only show level when mh-smartlevel would (hide when player and unit are both max level).
local function getClassificationNameLevel(unit, includeLevel, nameLength, includeRaidGroup, useSmartLevel)
	if not unit then
		return ""
	end

	-- Classification icon: same logic as mh-classification-icon-fixed
	local unitType = MHCT.classificationType(unit)
	local iconStr = (unitType and MHCT.ICON_MAP[unitType])
			and MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], MHCT.DEFAULT_ICON_SIZE)
		or ""

	-- MHCT.getFormattedUnitName centralizes the secret/nil/empty guard and CAPS+shorten
	local nameStr = MHCT.getFormattedUnitName(unit, nameLength or DEFAULT_TEXT_LENGTH) or ""
	-- Secret names pass through as-is; skip raid group append since we can't compare them
	local nameIsSecret = issecretvalue(nameStr)
	if includeRaidGroup and not nameIsSecret and nameStr ~= "" then
		nameStr = MHCT.appendRaidGroupToName(unit, nameStr)
	end

	-- Build result using .. (table.concat fails with secret values)
	local result = iconStr .. nameStr

	if includeLevel then
		-- Smart level: hide entirely when player and unit are both confirmed max level.
		-- Otherwise the difficulty formatter handles secret/nil internally.
		if not (useSmartLevel and MHCT.isAtMaxLevelTogether(unit)) then
			local unitLevel = UnitEffectiveLevel(unit)
			if unitLevel ~= nil then
				local levelStr = MHCT.difficultyLevelFormatter(unit, unitLevel, unitType)
				if levelStr and levelStr ~= "" then
					result = result .. " " .. levelStr
				end
			end
		end
	end
	return result
end

-- ===================================================================================
-- COMBINED TAG REGISTRATION
-- ===================================================================================

-- Classification icon + name + difficulty level
MHCT.registerTag(
	"mh-classification-name-level",
	COMBINED_SUBCATEGORY,
	"Combined: classification icon + name in CAPS + difficulty level. Use {N} for max name length (default 28). Example: [mh-classification-name-level{14}]",
	EVENTS_COMBINED,
	function(unit, _, args)
		local nameLength = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		return getClassificationNameLevel(unit, true, nameLength, false, false)
	end
)

-- Classification icon + name + difficulty level (smart: hide level when player and unit are both max)
MHCT.registerTag(
	"mh-classification-name-level-smart",
	COMBINED_SUBCATEGORY,
	"Same as mh-classification-name-level but uses mh-smartlevel logic: level hidden when you and unit are both max level. Use {N} for max name length (default 28). Example: [mh-classification-name-level-smart{14}]",
	EVENTS_COMBINED,
	function(unit, _, args)
		local nameLength = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		return getClassificationNameLevel(unit, true, nameLength, false, true)
	end
)

-- Classification icon + name (no level)
MHCT.registerTag(
	"mh-classification-name",
	COMBINED_SUBCATEGORY,
	"Combined: classification icon + name in CAPS. Use {N} for max name length (default 28). Example: [mh-classification-name{14}]",
	EVENTS_COMBINED,
	function(unit, _, args)
		local nameLength = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		return getClassificationNameLevel(unit, false, nameLength, false, false)
	end
)

-- Classification icon + name in CAPS + raid group (when in raid) + difficulty level
MHCT.registerTag(
	"mh-classification-name-level-raid-group",
	COMBINED_SUBCATEGORY,
	"Same as mh-classification-name-level; in raid appends group number (e.g. NAME (3)). Use {N} for max name length (default 28). Example: [mh-classification-name-level-raid-group{14}]",
	EVENTS_COMBINED_RAID,
	function(unit, _, args)
		local nameLength = MHCT.parseDecimalArg(args, DEFAULT_TEXT_LENGTH)
		return getClassificationNameLevel(unit, true, nameLength, true, false)
	end
)
