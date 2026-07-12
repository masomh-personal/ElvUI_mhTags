-- Bootstrap the addon namespace before loading shared helper modules.
if not C_AddOns.IsAddOnLoaded("ElvUI") then
	return
end

local _, ns = ...
ns.MHCT = {}
local MHCT = ns.MHCT

MHCT.ADDON_VERSION = "v12-2"
MHCT.ADDON_NAME = "ElvUI_mhTags"

local format = string.format
local ipairs = ipairs
local tonumber = tonumber
local sub = string.sub
local tinsert = table.insert
local concat = table.concat
local unpack = unpack
local strtrim = strtrim

local GetMaxPlayerLevel = GetMaxPlayerLevel

local E = unpack(ElvUI)

local function validateElvUIAPI()
	local requiredFunctions = {
		"AddTag",
		"AddTagInfo",
		"ShortenString",
	}

	local missing = {}
	for _, funcName in ipairs(requiredFunctions) do
		if not E[funcName] then
			tinsert(missing, funcName)
		end
	end

	if #missing > 0 then
		error(
			format(
				"ElvUI_mhTags: Required ElvUI functions not found: %s\n"
					.. "This may indicate an incompatible ElvUI version. Please update both addons.",
				concat(missing, ", ")
			)
		)
	end
end

validateElvUIAPI()

local function checkCompatibility()
	local minElvUIVersion = 15.0
	local currentElvUIVersion = tonumber(E.version) or 0

	if currentElvUIVersion > 0 and currentElvUIVersion < minElvUIVersion then
		print(
			format(
				"|cffFF0000[ElvUI_mhTags Error]|r This addon requires ElvUI %.1f or higher for WoW 12.0.7 (Midnight). "
					.. "Current version: %.2f. Please update ElvUI.",
				minElvUIVersion,
				currentElvUIVersion
			)
		)
	end

	MHCT.debugInfo = {
		elvuiVersion = currentElvUIVersion,
	}
end

checkCompatibility()

MHCT.TAG_CATEGORY_NAME = "|cff0388fcmh|r|cffccff33Tags|r"
MHCT.MAX_PLAYER_LEVEL = GetMaxPlayerLevel()
MHCT.DEFAULT_ICON_SIZE = 14
MHCT.DEFAULT_TEXT_LENGTH = 28
MHCT.DEFAULT_DECIMAL_PLACE = 0
MHCT.SECRET_VALUE_FALLBACK_TEXT = "---"

MHCT.COLORS = {
	STATUS = "D6BFA6",
	BOSS = "fc495e",
	RARE = "fc49f3",
	ELITE = "ffcc00",
}

MHCT.EMERALD_HEX = {
	RED = "C85050",
	YELLOW = "C8C850",
	GREEN = "50C878",
}

local function gradientStopFromHex(hex)
	return tonumber(sub(hex, 1, 2), 16) / 255, tonumber(sub(hex, 3, 4), 16) / 255, tonumber(sub(hex, 5, 6), 16) / 255
end

do
	local lr, lg, lb = gradientStopFromHex(MHCT.EMERALD_HEX.RED)
	local mr, mg, mb = gradientStopFromHex(MHCT.EMERALD_HEX.YELLOW)
	local hr, hg, hb = gradientStopFromHex(MHCT.EMERALD_HEX.GREEN)
	MHCT.HEALTH_GRADIENT_STOPS = {
		LOW = { lr, lg, lb },
		MID = { mr, mg, mb },
		HIGH = { hr, hg, hb },
	}
end

MHCT.PERCENT_FORMATS = {
	[0] = "%.0f",
	[1] = "%.1f",
	[2] = "%.2f",
	[3] = "%.3f",
}

MHCT.registerTag = function(name, subCategory, description, events, func)
	local fullCategory = MHCT.TAG_CATEGORY_NAME .. " [" .. subCategory .. "]"
	E:AddTagInfo(name, fullCategory, description)
	E:AddTag(name, events, func)
	return name
end

SLASH_MHTAGS1 = "/mhtags"
SlashCmdList["MHTAGS"] = function(msg)
	local cmd = msg and strtrim(msg:lower()) or ""

	if cmd == "debug" or cmd == "info" then
		local info = MHCT.debugInfo or {}
		print("|cff0388fc[ElvUI_mhTags]|r Debug Information:")
		print(format("  Addon Version: |cffffcc00%s|r", MHCT.ADDON_VERSION))
		print(format("  ElvUI Version: |cffffcc00%.2f|r", info.elvuiVersion or 0))
		print("  Target WoW Version: |cffffcc0012.0.7 (Midnight)|r")
	elseif cmd == "help" then
		print("|cff0388fc[ElvUI_mhTags]|r Commands:")
		print("  |cffffcc00/mhtags|r - Show memory usage")
		print("  |cffffcc00/mhtags debug|r - Show version info")
		print("  |cffffcc00/mhtags help|r - Show this help")
	else
		UpdateAddOnMemoryUsage()
		local memoryUsage = GetAddOnMemoryUsage(MHCT.ADDON_NAME)
		print(format("|cff0388fc[ElvUI_mhTags %s]|r Memory: |cffffcc00%.2f KB|r", MHCT.ADDON_VERSION, memoryUsage))
	end
end
