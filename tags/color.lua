-- Color prefix tags. Each returns an opening color escape only; the tag string
-- must close it with |r. Example: [mh-color-red][mh-health-current]|r
local _, ns = ...
local MHCT = ns.MHCT

local format = string.format
local ipairs = ipairs
local unpack = unpack
local upper = string.upper
local match = string.match

local COLOR_SUBCATEGORY = "colors"
-- Aa123 plus black squares (U+25A0) show the color on both text and a solid fill.
local COLOR_SAMPLE_TEXT = "Aa123 ■■■"

-- { tagName, hexColor, description }
local COLOR_TABLE = {
	-- Basic colors (white, yellow, orange, and pink are covered by class colors)
	{ "red", "FF0000", "Basic: Red" },
	{ "green", "00FF00", "Basic: Green" },
	{ "blue", "0000FF", "Basic: Blue" },
	{ "cyan", "00FFFF", "Basic: Cyan" },
	{ "magenta", "FF00FF", "Basic: Magenta" },
	{ "black", "000000", "Basic: Black" },
	{ "gray", "808080", "Basic: Gray" },
	{ "grey", "808080", "Basic: Grey (alias for gray)" },
	{ "purple", "800080", "Basic: Purple" },
	{ "lime", "32CD32", "Basic: Lime" },
	{ "brown", "8B4513", "Basic: Brown" },

	-- WoW class colors
	{ "deathknight", "C41F3B", "Death Knight class color" },
	{ "demonhunter", "A330C9", "Demon Hunter class color" },
	{ "druid", "FF7D0A", "Druid class color" },
	{ "evoker", "33937F", "Evoker class color" },
	{ "hunter", "ABD473", "Hunter class color" },
	{ "mage", "69CCF0", "Mage class color" },
	{ "monk", "00FF96", "Monk class color" },
	{ "paladin", "F58CBA", "Paladin class color" },
	{ "priest", "FFFFFF", "Priest class color" },
	{ "rogue", "FFFF00", "Rogue class color" },
	{ "shaman", "0070DE", "Shaman class color" },
	{ "warlock", "9482C9", "Warlock class color" },
	{ "warrior", "C79C6E", "Warrior class color" },

	-- Emerald colors
	{ "emerald-green", "50C878", "Emerald: Green" },
	{ "emerald-red", "C85050", "Emerald: Red" },
	{ "emerald-blue", "50A0C8", "Emerald: Blue" },
	{ "emerald-yellow", "C8C850", "Emerald: Yellow" },
	{ "emerald-cyan", "50C8C8", "Emerald: Cyan" },
	{ "emerald-orange", "C87850", "Emerald: Orange" },

	-- Pastel colors
	{ "pastel-green", "B0E0B0", "Pastel: Green" },
	{ "pastel-red", "FFA0A0", "Pastel: Red" },
	{ "pastel-blue", "A0C0E0", "Pastel: Blue" },
	{ "pastel-yellow", "FFF8DC", "Pastel: Yellow" },
	{ "pastel-cyan", "B0E0E0", "Pastel: Cyan" },
	{ "pastel-orange", "FFC080", "Pastel: Orange" },
}

for _, colorData in ipairs(COLOR_TABLE) do
	local tagName, hexColor, description = unpack(colorData)
	local colorPrefix = "|cff" .. hexColor

	MHCT.registerTag(
		"mh-color-" .. tagName,
		COLOR_SUBCATEGORY,
		format("|cff%s%s|r Color prefix: %s (HEX: #%s)", hexColor, COLOR_SAMPLE_TEXT, description, hexColor),
		"",
		function()
			return colorPrefix
		end
	)
end

-- Returns an uppercase 6-digit hex string, or nil when the input is not valid hex.
local function validateHexColor(hex)
	if not hex or hex == "" then
		return nil
	end
	hex = upper(hex:gsub("#", ""))
	if match(hex, "^%x%x%x%x%x%x$") then
		return hex
	end
	return nil
end

MHCT.registerTag(
	"mh-color-custom",
	COLOR_SUBCATEGORY,
	"Color prefix: Custom hex color. Use {RRGGBB} for hex code (no #). Example: [mh-color-custom{FF5733}][mh-health-current]|r Invalid or missing hex applies no color.",
	"",
	function(unit, _, args)
		local hexColor = validateHexColor(args)
		if hexColor then
			return format("|cff%s", hexColor)
		end
		return ""
	end
)

-- Health gradient evaluated by a ColorCurve in C, because secret health percentages
-- cannot drive a Lua table lookup. Falls back to emerald-green when evaluation fails.
local SECRET_FALLBACK_COLOR = "|cff" .. MHCT.EMERALD_HEX.GREEN

MHCT.registerTag(
	"mh-color-health-gradient",
	COLOR_SUBCATEGORY,
	"Color prefix: 3-stop emerald gradient by health percent (emerald-red at low, emerald-yellow at mid, emerald-green at full). Composes with any health tag. Example: [mh-color-health-gradient][mh-health-current-percent]|r",
	"UNIT_HEALTH UNIT_MAXHEALTH",
	function(unit)
		return MHCT.getHealthGradientColorPrefix(unit) or SECRET_FALLBACK_COLOR
	end
)
