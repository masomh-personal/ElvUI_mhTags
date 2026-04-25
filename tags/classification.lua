-- ===================================================================================
-- CLASSIFICATION TAGS - Optimized for efficiency
-- ===================================================================================
--
-- WoW 12.0+ Compatibility:
-- Classification APIs (UnitClassification, UnitEffectiveLevel) are not affected
-- by 12.0's secret value restrictions as they don't expose combat-sensitive data.
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Localize Lua functions
local format = string.format

-- Local constants
local CLASSIFICATION_SUBCATEGORY = "classification"
local DEFAULT_ICON_SIZE = MHCT.DEFAULT_ICON_SIZE

-- Classification color constants
local BOSS_COLOR = "fc495e" -- light red
local ELITE_COLOR = "ffcc00" -- gold
local RARE_COLOR = "fc49f3" -- light magenta

-- Pre-built classification text tables (avoid creating tables per call)
local CLASSIFICATION_TEXT = {
	boss = format("|cff%s[Boss]|r", BOSS_COLOR),
	elite = format("|cff%s[Elite]|r", ELITE_COLOR),
	rare = format("|cff%s[Rare]|r", RARE_COLOR),
	rareelite = format("|cff%s[Rare Elite]|r", RARE_COLOR),
	eliteplus = format("|cff%s[Elite+]|r", ELITE_COLOR),
}

local CLASSIFICATION_COMPACT = {
	boss = format("|cff%sB|r", BOSS_COLOR),
	elite = format("|cff%sE|r", ELITE_COLOR),
	rare = format("|cff%sR|r", RARE_COLOR),
	rareelite = format("|cff%sR+|r", RARE_COLOR),
	eliteplus = format("|cff%sE+|r", ELITE_COLOR),
}

local CLASSIFICATION_FULL = {
	boss = "Boss",
	elite = "Elite",
	rare = "Rare",
	rareelite = "Rare Elite",
	eliteplus = "Elite+",
}

-- ===================================================================================
-- UNIT CLASSIFICATION (ICONS)
-- ===================================================================================

-- Dynamic size classification icon
MHCT.registerTag(
	"mh-classification-icon",
	CLASSIFICATION_SUBCATEGORY,
	"Unit classification icon (Boss, Elite, Rare, etc.). Use {N} for icon size (default 14).",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit, _, args)
		if not unit then return "" end
		local unitType = MHCT.classificationType(unit)
		local baseIconSize = MHCT.parseDecimalArg(args, DEFAULT_ICON_SIZE)

		if unitType and MHCT.ICON_MAP[unitType] then
			return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], baseIconSize)
		end

		return ""
	end
)

-- Fixed size classification icon
MHCT.registerTag(
	"mh-classification-icon-fixed",
	CLASSIFICATION_SUBCATEGORY,
	"Unit classification icon at fixed size (no size argument).",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit)
		if not unit then return "" end
		local unitType = MHCT.classificationType(unit)

		if unitType and MHCT.ICON_MAP[unitType] then
			return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], DEFAULT_ICON_SIZE)
		end

		return ""
	end
)

-- ===================================================================================
-- UNIT CLASSIFICATION (TEXT)
-- ===================================================================================

-- Text-based classification with color coding (uses pre-built table)
MHCT.registerTag(
	"mh-classification-text",
	CLASSIFICATION_SUBCATEGORY,
	"Unit classification as text in brackets (e.g. [Boss], [Elite], [Rare]).",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit)
		if not unit then return "" end
		local unitType = MHCT.classificationType(unit)
		return unitType and CLASSIFICATION_TEXT[unitType] or ""
	end
)

-- Text-based classification with symbols (compact version, uses pre-built table)
MHCT.registerTag(
	"mh-classification-symbols",
	CLASSIFICATION_SUBCATEGORY,
	"Unit classification as single symbols (B, E, R, R+, E+).",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit)
		if not unit then return "" end
		local unitType = MHCT.classificationType(unit)
		return unitType and CLASSIFICATION_COMPACT[unitType] or ""
	end
)

-- Full descriptive classification without brackets (uses pre-built table)
MHCT.registerTag(
	"mh-classification-plain",
	CLASSIFICATION_SUBCATEGORY,
	"Unit classification as plain text without brackets (e.g. Boss, Elite, Rare).",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit)
		if not unit then return "" end
		local unitType = MHCT.classificationType(unit)
		return unitType and CLASSIFICATION_FULL[unitType] or ""
	end
)
