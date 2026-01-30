-- ===================================================================================
-- COMBINED TAGS - All-in-one tags that combine classification, name, and level
-- ===================================================================================
--
-- Separation of concerns: keeps generic modules (name, classification, misc) lean.
-- Combined tags reuse the same logic via MHCT and WoW APIs.
-- ===================================================================================

local _, ns = ...
local MHCT = ns.MHCT

local E = MHCT.E
local UnitName = UnitName
local UnitEffectiveLevel = UnitEffectiveLevel
local strupper = strupper
local issecretvalue = issecretvalue

local COMBINED_SUBCATEGORY = "combined"
local DEFAULT_TEXT_LENGTH = MHCT.DEFAULT_TEXT_LENGTH
local EVENTS_COMBINED = "UNIT_CLASSIFICATION_CHANGED UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP"

-- Helper: get unit name, handle secret values (same behavior as name.lua)
local function getFormattedName(unit, length)
	if not unit then
		return nil
	end
	local name = UnitName(unit)
	if not name or name == "" then
		return nil
	end
	if issecretvalue(name) then
		return name
	end
	return E:ShortenString(strupper(name), length or DEFAULT_TEXT_LENGTH)
end

-- Helper: classification icon + name (optionally + difficulty level)
-- Icon logic matches mh-classification-icon-fixed exactly (classificationType → ICON_MAP → getFormattedIcon).
-- nameLength: max character length for name (default DEFAULT_TEXT_LENGTH).
local function getClassificationNameLevel(unit, includeLevel, nameLength)
	if not unit then
		return ""
	end

	-- Classification icon: same logic as mh-classification-icon-fixed
	local unitType = MHCT.classificationType(unit)
	local iconStr = (unitType and MHCT.ICON_MAP[unitType]) and MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], MHCT.DEFAULT_ICON_SIZE) or ""

	local nameStr = getFormattedName(unit, nameLength or DEFAULT_TEXT_LENGTH) or ""

	local result = iconStr .. nameStr
	if includeLevel then
		local unitLevel = UnitEffectiveLevel(unit)
		local levelStr = MHCT.difficultyLevelFormatter(unit, unitLevel)
		if levelStr and levelStr ~= "" then
			result = result .. " " .. levelStr
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
		return getClassificationNameLevel(unit, true, nameLength)
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
		return getClassificationNameLevel(unit, false, nameLength)
	end
)
