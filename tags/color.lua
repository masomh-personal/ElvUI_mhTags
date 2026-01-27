-- ===================================================================================
-- COLOR TAGS - Builder Pattern Implementation
-- ===================================================================================
-- This file provides color prefix tags that can be used before other tags.
-- Example: [mh-color-red][mh-health-current] will display health in red.
--
-- Uses a builder pattern with a color table that gets looped through to register
-- all color tags automatically.
-- ===================================================================================

local _, ns = ...
local MHCT = ns.MHCT

-- Localize Lua functions
local format = string.format
local ipairs = ipairs
local upper = string.upper
local match = string.match

-- Local constants
local COLOR_SUBCATEGORY = "colors"
-- Sample text shown in tag descriptions; Aa123 + black square (U+25A0) for solid fill
local COLOR_SAMPLE_TEXT = "Aa123 ■"

-- ===================================================================================
-- COLOR TABLE
-- Structure: { tagName, hexColor, description }
-- ===================================================================================

local COLOR_TABLE = {
	-- Basic Colors
	{ "red", "FF0000", "Red" },
	{ "green", "00FF00", "Green" },
	{ "blue", "0000FF", "Blue" },
	{ "yellow", "FFFF00", "Yellow" },
	{ "cyan", "00FFFF", "Cyan" },
	{ "magenta", "FF00FF", "Magenta" },
	{ "white", "FFFFFF", "White" },
	{ "black", "000000", "Black" },
	{ "gray", "808080", "Gray" },
	{ "grey", "808080", "Grey (alias for gray)" },
	{ "orange", "FF7F00", "Orange" },
	{ "purple", "800080", "Purple" },
	{ "pink", "FF69B4", "Pink" },
	{ "lime", "32CD32", "Lime" },
	{ "brown", "8B4513", "Brown" },

	-- WoW Class Colors
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

	-- Emerald Colors
	{ "emerald-green", "50C878", "Emerald green" },
	{ "emerald-red", "C85050", "Emerald red" },
	{ "emerald-blue", "50A0C8", "Emerald blue" },
	{ "emerald-yellow", "C8C850", "Emerald yellow" },
	{ "emerald-cyan", "50C8C8", "Emerald cyan" },
	{ "emerald-orange", "C87850", "Emerald orange" },

	-- Pastel Colors
	{ "pastel-green", "B0E0B0", "Pastel green" },
	{ "pastel-red", "FFA0A0", "Pastel red" },
	{ "pastel-blue", "A0C0E0", "Pastel blue" },
	{ "pastel-yellow", "FFF8DC", "Pastel yellow" },
	{ "pastel-cyan", "B0E0E0", "Pastel cyan" },
	{ "pastel-orange", "FFC080", "Pastel orange" },
}

-- ===================================================================================
-- BUILDER PATTERN: REGISTER ALL COLOR TAGS
-- ===================================================================================

for _, colorData in ipairs(COLOR_TABLE) do
	local tagName = colorData[1]
	local hexColor = colorData[2]
	local description = colorData[3]

	-- Build enhanced description with color sample and hex code
	-- Format: [colored sample text] Color prefix: [description] (HEX: #[hex])
	-- Use colored "Aa" as sample; works with any font and clearly shows the color
	local enhancedDescription =
		format("|cff%s%s|r Color prefix: %s (HEX: #%s)", hexColor, COLOR_SAMPLE_TEXT, description, hexColor)

	-- Register the color tag
	MHCT.registerTag(
		"mh-color-" .. tagName,
		COLOR_SUBCATEGORY,
		enhancedDescription,
		"", -- No events needed - static color codes
		function()
			-- Return opening color code only (no |r) so it applies to following tags
			-- User must add |r at the end of their tag string to close the color
			return format("|cff%s", hexColor)
		end
	)
end

-- ===================================================================================
-- CUSTOM HEX COLOR TAG
-- Allows users to specify any hex color via tag arguments
-- Usage: [mh-color-custom{FF5733}][tag]|r
-- ===================================================================================

-- Helper function to validate and normalize hex color
local function validateHexColor(hex)
	if not hex or hex == "" then
		return nil
	end

	-- Remove # if present and convert to uppercase
	hex = upper(hex:gsub("#", ""))

	-- Validate: must be exactly 6 hex characters (0-9, A-F)
	if match(hex, "^[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]$") then
		return hex
	end

	return nil
end

-- Register custom hex color tag
MHCT.registerTag(
	"mh-color-custom",
	COLOR_SUBCATEGORY,
	"Color prefix: Custom hex color. Use {RRGGBB} for hex code (no #). Example: [mh-color-custom{FF5733}][tag]|r",
	"", -- No events needed - static color codes
	function(unit, _, args)
		local hexColor = validateHexColor(args)
		if hexColor then
			-- Return opening color code only (no |r) so it applies to following tags
			return format("|cff%s", hexColor)
		end
		-- Invalid hex color - return empty string (tag won't apply any color)
		return ""
	end
)
