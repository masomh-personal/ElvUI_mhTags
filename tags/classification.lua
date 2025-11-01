-- ===================================================================================
-- CLASSIFICATION TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references from core (shared to avoid duplicate unpacking)
local E = MHCT.E

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

		-- Map classification types to colored descriptive text
		local classificationText = {
			boss = format("|cff%s[Boss]|r", BOSS_COLOR),
			elite = format("|cff%s[Elite]|r", ELITE_COLOR),
			rare = format("|cff%s[Rare]|r", RARE_COLOR),
			rareelite = format("|cff%s[Rare Elite]|r", RARE_COLOR),
			eliteplus = format("|cff%s[Elite+]|r", ELITE_COLOR),
		}

		return classificationText[unitType] or ""
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

		-- Map classification types to compact colored text with symbols
		local compactText = {
			boss = format("|cff%sB|r", BOSS_COLOR),
			elite = format("|cff%sE|r", ELITE_COLOR),
			rare = format("|cff%sR|r", RARE_COLOR),
			rareelite = format("|cff%sR+|r", RARE_COLOR),
			eliteplus = format("|cff%sE+|r", ELITE_COLOR),
		}

		return compactText[unitType] or ""
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

		-- Map classification types to descriptive text
		local fullText = {
			boss = "Boss",
			elite = "Elite",
			rare = "Rare",
			rareelite = "Rare Elite",
			eliteplus = "Elite+",
		}

		return fullText[unitType] or ""
	end
)
