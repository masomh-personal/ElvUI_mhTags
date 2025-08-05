-- ===================================================================================
-- CLASSIFICATION TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Localize Lua functions
local tonumber = tonumber
local format = string.format

-- Local constants
local CLASSIFICATION_SUBCATEGORY = "classification"
local DEFAULT_ICON_SIZE = MHCT.DEFAULT_ICON_SIZE

-- Classification color constants
local BOSS_COLOR = "fc495e" -- light red
local ELITE_COLOR = "ffcc00" -- gold
local RARE_COLOR = "fc49f3" -- light magenta
local NORMAL_COLOR = "ffffff" -- white

-- Pre-computed classification text formats (one-time cost)
local CLASSIFICATION_TEXT_FORMATS = {
	boss = format("|cff%s[Boss]|r", BOSS_COLOR),
	elite = format("|cff%s[Elite]|r", ELITE_COLOR),
	rare = format("|cff%s[Rare]|r", RARE_COLOR),
	rareelite = format("|cff%s[Rare Elite]|r", RARE_COLOR),
	eliteplus = format("|cff%s[Elite+]|r", ELITE_COLOR),
}

local CLASSIFICATION_COMPACT_FORMATS = {
	boss = format("|cff%sB|r", BOSS_COLOR),
	elite = format("|cff%sE|r", ELITE_COLOR),
	rare = format("|cff%sR|r", RARE_COLOR),
	rareelite = format("|cff%sR+|r", RARE_COLOR),
	eliteplus = format("|cff%sE+|r", ELITE_COLOR),
}

local CLASSIFICATION_FULL_TEXT = {
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
	"mh-classification:icon",
	CLASSIFICATION_SUBCATEGORY,
	"Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites)",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit, _, args)
		local unitType = MHCT.classificationType(unit)
		local baseIconSize = tonumber(args) or DEFAULT_ICON_SIZE

		if unitType and MHCT.ICON_MAP[unitType] then
			return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], baseIconSize)
		end

		return ""
	end
)

-- Fixed size classification icon
MHCT.registerTag(
	"mh-classification:icon-V2",
	CLASSIFICATION_SUBCATEGORY,
	"Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites) - NON Dynamic sizing",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit)
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

-- Text-based classification with color coding
MHCT.registerTag(
	"mh-classification:text",
	CLASSIFICATION_SUBCATEGORY,
	"Unit classification as color-coded text (Boss, Elite, Rare, etc.)",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit)
		local unitType = MHCT.classificationType(unit)

		if not unitType then
			return ""
		end

		return CLASSIFICATION_TEXT_FORMATS[unitType] or ""
	end
)

-- Text-based classification with symbols (compact version)
MHCT.registerTag(
	"mh-classification:text-compact",
	CLASSIFICATION_SUBCATEGORY,
	"Unit classification as compact colored symbols (B, E, R, R+, E+)",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit)
		local unitType = MHCT.classificationType(unit)

		if not unitType then
			return ""
		end

		return CLASSIFICATION_COMPACT_FORMATS[unitType] or ""
	end
)

-- Full descriptive classification without brackets
MHCT.registerTag(
	"mh-classification:text-full",
	CLASSIFICATION_SUBCATEGORY,
	"Full descriptive classification text without brackets",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit)
		local unitType = MHCT.classificationType(unit)

		if not unitType then
			return ""
		end

		return CLASSIFICATION_FULL_TEXT[unitType] or ""
	end
)
