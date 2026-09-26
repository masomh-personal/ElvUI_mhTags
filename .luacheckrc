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
	"ElvUI_mhTags_OnAddonCompartmentClick",
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
	"C_AddOnProfiler",
	"C_AddOns",
	"C_StringUtil",
	"C_CurveUtil",
	"C_Timer",
	"Enum",
	"CurveConstants",
	"issecretvalue",
	"AbbreviateNumbers",
	"CreateFrame",
	"CreateColor",
	"GameTooltip",
	"UIParent",
	"UISpecialFrames",
	"GetAddOnMemoryUsage",
	"UpdateAddOnMemoryUsage",
	"GetBuildInfo",
	"GetCreatureDifficultyColor",
	"GetMaxPlayerLevel",
	"GetRaidRosterInfo",
	"IsInRaid",
	"UnitInRaid",
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
