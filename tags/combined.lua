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
local concat = table.concat

local COMBINED_SUBCATEGORY = "combined"
local DEFAULT_TEXT_LENGTH = MHCT.DEFAULT_TEXT_LENGTH
local MAX_PLAYER_LEVEL = MHCT.MAX_PLAYER_LEVEL
local EVENTS_COMBINED = "UNIT_CLASSIFICATION_CHANGED UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP"
local EVENTS_COMBINED_RAID = EVENTS_COMBINED .. " GROUP_ROSTER_UPDATE"

-- Helper: get unit name, handle secret values (same behavior as name.lua)
local function getFormattedName(unit, length)
	if not unit then
		return nil
	end
	local name = UnitName(unit)
	if not name then
		return nil
	end
	-- Check for secret value BEFORE doing any comparisons (WoW 12.0 group frames can return secrets)
	if issecretvalue(name) then
		return name
	end
	-- Safe to compare now (not a secret)
	if name == "" then
		return nil
	end
	return E:ShortenString(strupper(name), length or DEFAULT_TEXT_LENGTH)
end

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
	local iconStr = (unitType and MHCT.ICON_MAP[unitType]) and MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], MHCT.DEFAULT_ICON_SIZE) or ""

	local nameStr = getFormattedName(unit, nameLength or DEFAULT_TEXT_LENGTH) or ""
	-- Check for secret before comparing (PvP/targettarget can return secrets)
	local nameIsSecret = issecretvalue(nameStr)
	if includeRaidGroup and not nameIsSecret and nameStr ~= "" then
		nameStr = MHCT.appendRaidGroupToName(unit, nameStr)
	end

	-- Build result using table (avoid repeated string concatenation)
	local parts = {}
	if iconStr ~= "" then
		parts[#parts + 1] = iconStr
	end
	-- Add name if present (secrets can be added to table, just can't be compared)
	if nameStr and (nameIsSecret or nameStr ~= "") then
		parts[#parts + 1] = nameStr
	end

	if includeLevel then
		local unitLevel = UnitEffectiveLevel(unit)
		-- Smart level: same logic as mh-smartlevel — hide when both player and unit are max level
		-- Guard: only compare when both levels are comparable (WoW 12.0 can return secret values)
		if useSmartLevel and unitLevel and not issecretvalue(unitLevel) then
			local playerLevel = UnitEffectiveLevel("player")
			if playerLevel and not issecretvalue(playerLevel) and playerLevel == MAX_PLAYER_LEVEL and unitLevel == MAX_PLAYER_LEVEL then
				unitLevel = nil
			end
		end
		if unitLevel then
			local levelStr = MHCT.difficultyLevelFormatter(unit, unitLevel)
			if levelStr and levelStr ~= "" then
				parts[#parts + 1] = " "
				parts[#parts + 1] = levelStr
			end
		end
	end
	return concat(parts, "")
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
