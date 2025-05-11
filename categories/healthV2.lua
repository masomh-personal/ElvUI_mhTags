-- ===================================================================================
-- VERSION 2.0 of health related tags. Focusing on efficiency for high CPU Usage (raids, etc)
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references directly
local E, L = unpack(ElvUI)
-- Don't localize these as standalone functions - they're methods of E
-- local GetFormattedText = E.GetFormattedText  -- INCORRECT
-- local ShortValue = E.ShortValue             -- INCORRECT

-- Localize WoW API functions directly
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs

-- Localize Lua functions directly
local format = string.format
local floor = math.floor
local tonumber = tonumber
local ipairs = ipairs

-- Set the category name for all v2 health tags
local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [health-v2]"

-- THROTTLE constants (seconds) **Does not work on nameplates**
local THROTTLE = {
	QUARTER = 0.25,
	HALF = 0.5,
	ONE = 1.0,
	TWO = 2.0,
}

-- ===================================================================================
-- HELPER FUNCTIONS - Efficient direct string formatting
-- ===================================================================================

-- Efficiently format health text with direct string concatenation
local function formatHealthText(unit, isPercentFirst)
	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)

	-- Early return for full health with no absorbs (most common case)
	local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
	if currentHp == maxHp and absorbAmount == 0 then
		return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
	end

	-- Get formatted current health
	local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	-- Format with absorb info if present
	local absorbText = ""
	if absorbAmount > 0 then
		absorbText = format("|cff%s(%s)|r ", MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
	end

	-- Add percent text if not at full health
	if currentHp < maxHp then
		local percentText = format("%.1f%%", (currentHp / maxHp) * 100)

		if isPercentFirst then
			return absorbText .. percentText .. " | " .. currentText
		else
			return absorbText .. currentText .. " | " .. percentText
		end
	end

	-- Just return current health for full health
	return absorbText .. currentText
end

-- Format health percent with status check
local function formatHealthPercentWithStatus(unit, decimalPlaces)
	-- First check for status
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)

	-- Handle full health
	if currentHp == maxHp then
		-- Full health, just return formatted current health
		return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
	end

	-- Calculate percentage with configured decimal places
	local decimals = tonumber(decimalPlaces) or 1
	local formatStr = format("%%.%sf%%%%", decimals)
	return format(formatStr, (currentHp / maxHp) * 100)
end

-- Format health deficit with status check
local function formatHealthDeficitWithStatus(unit)
	-- First check for status
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	local currentHp = UnitHealth(unit)
	local maxHp = UnitHealthMax(unit)

	-- Only show deficit if not at full health
	if currentHp < maxHp then
		return format("-%s", E:ShortValue(maxHp - currentHp))
	end

	return ""
end

-- Format health for hide-percent-at-full-health mode
local function formatHealthHideFullPercent(unit, isPercentFirst)
	-- Check for status first
	local statusFormatted = MHCT.formatWithStatusCheck(unit)
	if statusFormatted then
		return statusFormatted
	end

	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)

	-- Get formatted current health
	local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	-- If health is full, just return current health value
	if currentHp == maxHp then
		return currentText
	end

	-- Calculate percentage since health isn't full
	local percentText = format("%.1f%%", (currentHp / maxHp) * 100)

	-- Format in requested order
	if isPercentFirst then
		return percentText .. " | " .. currentText
	else
		return currentText .. " | " .. percentText
	end
end

-- Format health with low health coloring
local function formatHealthWithLowHealthColor(unit, isPercentFirst, threshold)
	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)
	local healthPercent = (currentHp / maxHp) * 100

	-- Check if health is below threshold
	local lowHealthThreshold = threshold or 20 -- Default to 20%
	local isLowHealth = healthPercent <= lowHealthThreshold

	-- Get formatted current health
	local currentText = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	-- Handle absorb information if present
	local absorbText = ""
	local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
	if absorbAmount > 0 then
		absorbText = format("|cff%s(%s)|r ", MHCT.ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount))
	end

	-- Calculate percentage if not at full health
	local percentText
	if currentHp < maxHp then
		percentText = format("%.1f%%", healthPercent)
	else
		return absorbText .. currentText -- Just return current health at full health
	end

	-- Format with color if health is low
	local result
	if isPercentFirst then
		result = percentText .. " | " .. currentText
	else
		result = currentText .. " | " .. percentText
	end

	-- Apply color for low health
	if isLowHealth then
		local colorCode = MHCT.HEALTH_GRADIENT_RGB[floor(healthPercent)] or "|cffFF0000"
		return absorbText .. colorCode .. result .. "|r"
	else
		return absorbText .. result
	end
end

-- ===================================================================================
-- HEALTH PERCENT WITH STATUS - Multiple update frequencies
-- ===================================================================================
do
	-- Define the tags with different throttle rates
	local healthPercentTags = {
		{
			name = "mh-health-percent:status-0.25",
			throttle = THROTTLE.QUARTER,
			desc = "Health percent with status @ 0.25s update interval",
		},
		{
			name = "mh-health-percent:status-0.5",
			throttle = THROTTLE.HALF,
			desc = "Health percent with status @ 0.5s update interval",
		},
		{
			name = "mh-health-percent:status-1.0",
			throttle = THROTTLE.ONE,
			desc = "Health percent with status @ 1.0s update interval",
		},
		{
			name = "mh-health-percent:status-2.0",
			throttle = THROTTLE.TWO,
			desc = "Health percent with status @ 2.0s update interval",
		},
	}

	-- Register all the tags using the configuration table
	for _, config in ipairs(healthPercentTags) do
		E:AddTagInfo(config.name, thisCategory, config.desc)
		E:AddTag(config.name, config.throttle, function(unit, _, args)
			return formatHealthPercentWithStatus(unit, args)
		end)
	end

	-- Add a configurable version that lets users specify decimals
	E:AddTagInfo(
		"mh-health-percent:status-configurable",
		thisCategory,
		"Health percent with status and configurable decimal places - Example: [mh-health-percent:status-configurable{2}:1.0] for 2 decimal places at 1s update interval"
	)

	-- Register configurable versions for each throttle rate
	for _, throttleValue in pairs(THROTTLE) do
		E:AddTag("mh-health-percent:status-configurable", throttleValue, function(unit, _, args)
			return formatHealthPercentWithStatus(unit, args)
		end)
	end
end

-- ===================================================================================
-- HEALTH DEFICIT WITH STATUS - Multiple update frequencies
-- ===================================================================================
do
	-- Define the tags with different throttle rates
	local healthDeficitTags = {
		{
			name = "mh-health-deficit:status-0.25",
			throttle = THROTTLE.QUARTER,
			desc = "Health deficit with status @ 0.25s update interval",
		},
		{
			name = "mh-health-deficit:status-0.5",
			throttle = THROTTLE.HALF,
			desc = "Health deficit with status @ 0.5s update interval",
		},
		{
			name = "mh-health-deficit:status-1.0",
			throttle = THROTTLE.ONE,
			desc = "Health deficit with status @ 1.0s update interval",
		},
		{
			name = "mh-health-deficit:status-2.0",
			throttle = THROTTLE.TWO,
			desc = "Health deficit with status @ 2.0s update interval",
		},
	}

	-- Register all the tags using the configuration table
	for _, config in ipairs(healthDeficitTags) do
		E:AddTagInfo(config.name, thisCategory, config.desc)
		E:AddTag(config.name, config.throttle, function(unit)
			return formatHealthDeficitWithStatus(unit)
		end)
	end

	-- Add a minimal version that doesn't show the minus sign (just the value)
	E:AddTagInfo(
		"mh-health-deficit:status-minimal",
		thisCategory,
		"Minimal health deficit display - no minus sign, just the missing health value"
	)

	-- Register minimal versions for each throttle rate
	for _, config in ipairs(healthDeficitTags) do
		local minimalName = config.name:gsub(":status%-", ":minimal%-")
		E:AddTagInfo(
			minimalName,
			thisCategory,
			"Minimal " .. config.desc:gsub("Health deficit with status", "health deficit")
		)

		E:AddTag(minimalName, config.throttle, function(unit)
			-- Check status first
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			-- Minimal deficit (no minus sign)
			local currentHp = UnitHealth(unit)
			local maxHp = UnitHealthMax(unit)

			if currentHp < maxHp then
				return ShortValue(maxHp - currentHp)
			end

			return ""
		end)
	end
end

-- ===================================================================================
-- HIDE PERCENT AT FULL HEALTH TAGS - Shows percent only when health isn't full
-- ===================================================================================
do
	-- Register the "current | percent" version (same as original)
	E:AddTagInfo(
		"mh-health-current-percent-hidefull",
		thisCategory,
		"Shows health as: 100k | 85% but hides percent at full health"
	)
	E:AddTag(
		"mh-health-current-percent-hidefull",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			return formatHealthHideFullPercent(unit, false) -- false = current first
		end
	)

	-- Register the "percent | current" version
	E:AddTagInfo(
		"mh-health-percent-current-hidefull",
		thisCategory,
		"Shows health as: 85% | 100k but hides percent at full health"
	)
	E:AddTag(
		"mh-health-percent-current-hidefull",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			return formatHealthHideFullPercent(unit, true) -- true = percent first
		end
	)

	-- BACKWARDS compatibility, register the V1 tag names as aliases
	E:AddTagInfo(
		"mh-health:current:percent:right-hidefull",
		thisCategory,
		"Alias for mh-health-current-percent-hidefull (V3 version)"
	)
	E:AddTag(
		"mh-health:current:percent:right-hidefull",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			return formatHealthHideFullPercent(unit, false)
		end
	)

	E:AddTagInfo(
		"mh-health:current:percent:left-hidefull",
		thisCategory,
		"Alias for mh-health-percent-current-hidefull (V3 version)"
	)
	E:AddTag(
		"mh-health:current:percent:left-hidefull",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			return formatHealthHideFullPercent(unit, true)
		end
	)
end

-- ===================================================================================
-- LOW HEALTH COLORED VERSION - Direct string concatenation
-- ===================================================================================
do
	-- Register the "current | percent" version with low health coloring
	E:AddTagInfo(
		"mh-health-current-percent:low-health-colored",
		thisCategory,
		"Shows health as: 100k | 85% with color gradient for health below 20% (NO STATUS)"
	)
	E:AddTag(
		"mh-health-current-percent:low-health-colored",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
		function(unit, _, args)
			local threshold = tonumber(args) or 20 -- Default to 20%, override with tag args
			return formatHealthWithLowHealthColor(unit, false, threshold) -- false = current first
		end
	)

	-- Register the "percent | current" version with low health coloring
	E:AddTagInfo(
		"mh-health-percent-current:low-health-colored",
		thisCategory,
		"Shows health as: 85% | 100k with color gradient for health below 20% (NO STATUS)"
	)
	E:AddTag(
		"mh-health-percent-current:low-health-colored",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
		function(unit, _, args)
			local threshold = tonumber(args) or 20 -- Default to 20%, override with tag args
			return formatHealthWithLowHealthColor(unit, true, threshold) -- true = percent first
		end
	)
end

-- ===================================================================================
-- MEMORY LEAK TESTING - Add to the end of your health tag file
-- ===================================================================================
do
	local leakTestFrame = CreateFrame("Frame")

	-- Memory leak test function
	local function testForMemoryLeaks(iterations)
		iterations = iterations or 100000

		print("|cff0388fcmhTags|r Memory Leak Test:")
		print(format("Running %s iterations per test phase", iterations))
		print("----------------------------------------")

		local startMem = collectgarbage("count")

		-- Force garbage collection before test
		collectgarbage("collect")
		collectgarbage("collect")

		-- Run a large number of tag updates for various tag types
		print("Phase 1: Testing standard health tags...")
		for i = 1, iterations do
			formatHealthText("player", false)
		end

		-- Measure memory after first run
		collectgarbage("collect")
		collectgarbage("collect")
		local midMem1 = collectgarbage("count")

		-- Run again to see if memory continues to grow
		print("Phase 2: Testing standard health tags again...")
		for i = 1, iterations do
			formatHealthText("player", false)
		end

		-- Force garbage collection and measure memory
		collectgarbage("collect")
		collectgarbage("collect")
		local midMem2 = collectgarbage("count")

		-- Test another tag type
		print("Phase 3: Testing health deficit tags...")
		for i = 1, iterations do
			formatHealthDeficitWithStatus("player")
		end

		-- Force garbage collection and measure memory
		collectgarbage("collect")
		collectgarbage("collect")
		local midMem3 = collectgarbage("count")

		-- Test colored health tags
		print("Phase 4: Testing colored health tags...")
		for i = 1, iterations do
			formatHealthWithLowHealthColor("player", false, 20)
		end

		-- Force garbage collection and measure final memory
		collectgarbage("collect")
		collectgarbage("collect")
		local endMem = collectgarbage("count")

		-- Compare memory usage
		print("----------------------------------------")
		print(format("Initial memory: |cffccff33%.2f KB|r", startMem))
		print(format("After phase 1: |cffccff33%.2f KB|r (delta: %.2f KB)", midMem1, midMem1 - startMem))
		print(format("After phase 2: |cffccff33%.2f KB|r (delta: %.2f KB)", midMem2, midMem2 - midMem1))
		print(format("After phase 3: |cffccff33%.2f KB|r (delta: %.2f KB)", midMem3, midMem3 - midMem2))
		print(format("Final memory: |cffccff33%.2f KB|r (delta: %.2f KB)", endMem, endMem - midMem3))
		print(format("Total memory growth: |cffccff33%.2f KB|r", endMem - startMem))

		-- Analyze results
		local leakThreshold = 20 -- KB threshold for considering it a leak
		local phaseResults = {
			{ name = "Standard health tags (repeated)", delta = midMem2 - midMem1 },
			{ name = "Health deficit tags", delta = midMem3 - midMem2 },
			{ name = "Colored health tags", delta = endMem - midMem3 },
		}

		print("----------------------------------------")
		print("ANALYSIS:")

		local anyLeak = false
		for _, result in ipairs(phaseResults) do
			if result.delta > leakThreshold then
				print(format("|cffFF0000Possible memory leak in %s: %.2f KB growth|r", result.name, result.delta))
				anyLeak = true
			else
				print(format("|cff00FF00No memory leak detected in %s: %.2f KB growth|r", result.name, result.delta))
			end
		end

		if not anyLeak then
			print("|cff00FF00All tests passed! No significant memory leaks detected.|r")
		else
			print("|cffFF0000Warning: Possible memory leaks detected. Review the results above.|r")
		end

		-- Testing complete
		print("----------------------------------------")
		print("Memory leak test complete!")
	end

	-- Register slash command
	SLASH_MHTAGSLEAK1 = "/mhtagsleak"
	SlashCmdList["MHTAGSLEAK"] = function(msg)
		local iterations = tonumber(msg) or 100000
		testForMemoryLeaks(iterations)
	end

	-- Add to MHCT for programmatic access
	MHCT.runMemoryLeakTest = testForMemoryLeaks

	-- Print instruction on load
	leakTestFrame:RegisterEvent("PLAYER_LOGIN")
	leakTestFrame:SetScript("OnEvent", function(self, event)
		if event == "PLAYER_LOGIN" then
			C_Timer.After(3, function()
				print("|cff0388fcmhTags|r: Use |cffccff33/mhtagsleak [iterations]|r to run memory leak test")
			end)
		end
	end)
end
