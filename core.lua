-- Bootstrap the addon namespace before loading shared helper modules.
local addonName, ns = ...
ns.MHCT = {}
local MHCT = ns.MHCT

local format = string.format
local ipairs = ipairs
local tonumber = tonumber
local sub = string.sub
local tinsert = table.insert
local concat = table.concat
local unpack = unpack
local strtrim = strtrim

local GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local GetAddOnMetric = C_AddOnProfiler.GetAddOnMetric
local IsAddOnProfilerEnabled = C_AddOnProfiler.IsEnabled
local RECENT_AVERAGE_TIME = Enum.AddOnProfilerMetric.RecentAverageTime
local GetBuildInfo = GetBuildInfo
local GetMaxPlayerLevel = GetMaxPlayerLevel

MHCT.ADDON_NAME = addonName
MHCT.ADDON_VERSION = GetAddOnMetadata(addonName, "Version")

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
	local minElvUIVersion = tonumber(GetAddOnMetadata(addonName, "X-Min-ElvUI")) or 0
	local currentElvUIVersion = tonumber(E.version) or 0

	if currentElvUIVersion > 0 and currentElvUIVersion < minElvUIVersion then
		print(
			format(
				"|cffFF0000[ElvUI_mhTags Error]|r This addon requires ElvUI %.2f or higher. "
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
MHCT.UNKNOWN_LEVEL_TEXT = "??"

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

MHCT.registeredTags = {}
MHCT.registerTag = function(name, subCategory, description, events, func)
	local fullCategory = MHCT.TAG_CATEGORY_NAME .. " [" .. subCategory .. "]"
	E:AddTagInfo(name, fullCategory, description)
	E:AddTag(name, events, func)
	tinsert(MHCT.registeredTags, {
		name = name,
		subCategory = subCategory,
		description = description,
		events = events,
		func = func,
	})
	return name
end

local function printUsage()
	UpdateAddOnMemoryUsage()
	local memoryUsage = GetAddOnMemoryUsage(addonName)
	print(format("|cff0388fc[ElvUI_mhTags %s]|r Memory: |cffffcc00%.2f KB|r", MHCT.ADDON_VERSION, memoryUsage))
	if IsAddOnProfilerEnabled() then
		local cpuTime = GetAddOnMetric(addonName, RECENT_AVERAGE_TIME)
		print(format("  CPU: |cffffcc00%.3f ms|r per frame (average of the last 60 frames)", cpuTime))
	else
		print("  CPU: addon profiler is disabled")
	end
end

-- Referenced by the TOC AddonCompartmentFunc field, so it must be global.
function ElvUI_mhTags_OnAddonCompartmentClick()
	MHCT.toggleTestDashboard()
end

SLASH_MHTAGS1 = "/mhtags"
SlashCmdList["MHTAGS"] = function(msg)
	local cmd = msg and strtrim(msg:lower()) or ""

	if cmd == "debug" or cmd == "info" then
		local info = MHCT.debugInfo or {}
		local clientVersion, clientBuild = GetBuildInfo()
		print("|cff0388fc[ElvUI_mhTags]|r Debug Information:")
		print(format("  Addon Version: |cffffcc00%s|r", MHCT.ADDON_VERSION))
		print(format("  ElvUI Version: |cffffcc00%.2f|r", info.elvuiVersion or 0))
		print(format("  WoW Client: |cffffcc00%s (%s)|r", clientVersion, clientBuild))
	elseif cmd == "test" then
		MHCT.toggleTestDashboard()
	elseif cmd == "help" then
		print("|cff0388fc[ElvUI_mhTags]|r Commands:")
		print("  |cffffcc00/mhtags|r - Show memory and CPU usage")
		print("  |cffffcc00/mhtags debug|r - Show addon, ElvUI, and client versions")
		print("  |cffffcc00/mhtags test|r - Toggle the in-game tag test dashboard")
		print("  |cffffcc00/mhtags help|r - Show this help")
	else
		printUsage()
	end
end
