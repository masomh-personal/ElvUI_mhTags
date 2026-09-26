-- Classification tags. MHCT.classificationType returns nil when Blizzard restricts
-- the unit's classification or level.
local _, ns = ...
local MHCT = ns.MHCT

local format = string.format

local CLASSIFICATION_SUBCATEGORY = "classification"
local DEFAULT_ICON_SIZE = MHCT.DEFAULT_ICON_SIZE

local BOSS_COLOR = MHCT.COLORS.BOSS
local ELITE_COLOR = MHCT.COLORS.ELITE
local RARE_COLOR = MHCT.COLORS.RARE

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

MHCT.registerTag(
	"mh-classification-icon",
	CLASSIFICATION_SUBCATEGORY,
	"Unit classification icon (Boss, Elite, Rare, etc.). Use {N} for icon size (default 14).",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit, _, args)
		if not unit then
			return ""
		end
		local unitType = MHCT.classificationType(unit)
		local baseIconSize = MHCT.parseDecimalArg(args, DEFAULT_ICON_SIZE)

		if unitType and MHCT.ICON_MAP[unitType] then
			return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], baseIconSize)
		end

		return ""
	end
)

MHCT.registerTag(
	"mh-classification-icon-fixed",
	CLASSIFICATION_SUBCATEGORY,
	"Unit classification icon at fixed size (no size argument).",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit)
		if not unit then
			return ""
		end
		local unitType = MHCT.classificationType(unit)

		if unitType and MHCT.ICON_MAP[unitType] then
			return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], DEFAULT_ICON_SIZE)
		end

		return ""
	end
)

MHCT.registerTag(
	"mh-classification-text",
	CLASSIFICATION_SUBCATEGORY,
	"Unit classification as text in brackets (e.g. [Boss], [Elite], [Rare]).",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit)
		if not unit then
			return ""
		end
		local unitType = MHCT.classificationType(unit)
		return unitType and CLASSIFICATION_TEXT[unitType] or ""
	end
)

MHCT.registerTag(
	"mh-classification-symbols",
	CLASSIFICATION_SUBCATEGORY,
	"Unit classification as single symbols (B, E, R, R+, E+).",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit)
		if not unit then
			return ""
		end
		local unitType = MHCT.classificationType(unit)
		return unitType and CLASSIFICATION_COMPACT[unitType] or ""
	end
)

MHCT.registerTag(
	"mh-classification-plain",
	CLASSIFICATION_SUBCATEGORY,
	"Unit classification as plain text without brackets (e.g. Boss, Elite, Rare).",
	"UNIT_CLASSIFICATION_CHANGED",
	function(unit)
		if not unit then
			return ""
		end
		local unitType = MHCT.classificationType(unit)
		return unitType and CLASSIFICATION_FULL[unitType] or ""
	end
)
