-- Combined tags: classification icon, name, and level built from the shared MHCT helpers.
local _, ns = ...
local MHCT = ns.MHCT

local UnitEffectiveLevel = UnitEffectiveLevel
local issecretvalue = issecretvalue

local COMBINED_SUBCATEGORY = "combined"
local DEFAULT_TEXT_LENGTH = MHCT.DEFAULT_TEXT_LENGTH
local EVENTS_COMBINED = "UNIT_CLASSIFICATION_CHANGED UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP"
local EVENTS_COMBINED_RAID = EVENTS_COMBINED .. " GROUP_ROSTER_UPDATE"

-- The icon matches mh-classification-icon-fixed, the raid group matches
-- mh-name-caps-with-raid-group, and useSmartLevel matches mh-smartlevel.
local function getClassificationNameLevel(unit, includeLevel, nameLength, includeRaidGroup, useSmartLevel)
	if not unit then
		return ""
	end

	local unitLevel = UnitEffectiveLevel(unit)
	local unitType = MHCT.classificationType(unit, unitLevel)
	local iconStr = (unitType and MHCT.ICON_MAP[unitType])
			and MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], MHCT.DEFAULT_ICON_SIZE)
		or ""

	local nameStr = MHCT.getFormattedUnitName(unit, nameLength or DEFAULT_TEXT_LENGTH) or ""
	local nameIsSecret = issecretvalue(nameStr)
	if includeRaidGroup and not nameIsSecret and nameStr ~= "" then
		nameStr = MHCT.appendRaidGroupToName(unit, nameStr)
	end

	-- table.concat rejects secret values, so build with ..
	local result = iconStr .. nameStr

	if includeLevel then
		if not (useSmartLevel and MHCT.isAtMaxLevelTogether(unit, unitLevel)) then
			local levelStr = MHCT.difficultyLevelFormatter(unit, unitLevel, unitType)
			if levelStr and levelStr ~= "" then
				result = result .. " " .. levelStr
			end
		end
	end
	return result
end

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
