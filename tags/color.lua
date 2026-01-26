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

-- Local constants
local COLOR_SUBCATEGORY = "color"

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
	
	-- Item Quality Colors
	{ "poor", "9D9D9D", "Poor quality (gray)" },
	{ "common", "FFFFFF", "Common quality (white)" },
	{ "uncommon", "1EFF00", "Uncommon quality (green)" },
	{ "rare", "0070DD", "Rare quality (blue)" },
	{ "epic", "A335EE", "Epic quality (purple)" },
	{ "legendary", "FF8000", "Legendary quality (orange)" },
	{ "artifact", "E6CC80", "Artifact quality (gold)" },
	{ "heirloom", "E6CC80", "Heirloom quality (gold)" },
	
	-- Emerald Colors
	{ "emerald-green", "50C878", "Emerald green" },
	{ "emerald-red", "C85050", "Emerald red" },
	{ "emerald-blue", "50A0C8", "Emerald blue" },
	{ "emerald-yellow", "C8C850", "Emerald yellow" },
	{ "emerald-cyan", "50C8C8", "Emerald cyan" },
	{ "emerald-orange", "C87850", "Emerald orange" },
}

-- ===================================================================================
-- BUILDER PATTERN: REGISTER ALL COLOR TAGS
-- ===================================================================================

for _, colorData in ipairs(COLOR_TABLE) do
	local tagName = colorData[1]
	local hexColor = colorData[2]
	local description = colorData[3]
	
	-- Register the color tag
	MHCT.registerTag(
		"mh-color-" .. tagName,
		COLOR_SUBCATEGORY,
		"Color prefix: " .. description,
		"", -- No events needed - static color codes
		function()
			-- Return full color format string: |cffRRGGBB|r
			return format("|cff%s|r", hexColor)
		end
	)
end
