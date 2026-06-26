std = "lua51"
max_line_length = false

exclude_files = {
	"types/",
}

ignore = {
	"212", -- unused argument (common in ElvUI tag callbacks: function(unit) ...)
	"611", -- line contains only whitespace (StyLua may leave intentional blank lines)
}

-- Writable globals defined by this addon
globals = {
	"SLASH_MHTAGS1",
	"SlashCmdList",
}

read_globals = {
	-- Lua / WoW runtime
	"error",
	"format",
	"ipairs",
	"pairs",
	"pcall",
	"print",
	"select",
	"tonumber",
	"tostring",
	"type",
	"unpack",
	"string",
	"table",
	"math",
	"strupper",
	"strtrim",
	"strconcat",
	"gsub",
	"gmatch",
	"sub",
	"tinsert",
	"concat",

	-- Addon / slash commands
	"ElvUI",

	-- WoW 12.0+ APIs used by ElvUI_mhTags
	"C_AddOns",
	"C_StringUtil",
	"C_CurveUtil",
	"Enum",
	"CurveConstants",
	"issecretvalue",
	"AbbreviateNumbers",
	"CreateColor",
	"GetAddOnMemoryUsage",
	"UpdateAddOnMemoryUsage",
	"GetCreatureDifficultyColor",
	"GetMaxPlayerLevel",
	"GetNumGroupMembers",
	"GetRaidRosterInfo",
	"IsInRaid",
	"UnitClassification",
	"UnitEffectiveLevel",
	"UnitGetTotalAbsorbs",
	"UnitHealth",
	"UnitHealthMissing",
	"UnitHealthPercent",
	"UnitIsAFK",
	"UnitIsConnected",
	"UnitIsDead",
	"UnitIsDND",
	"UnitIsFeignDeath",
	"UnitIsGhost",
	"UnitIsPlayer",
	"UnitName",
	"UnitPowerPercent",
	"UnitPowerType",
}
