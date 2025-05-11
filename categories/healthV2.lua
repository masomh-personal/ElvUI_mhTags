-- ===================================================================================
-- VERSION 3.0 of health related tags. Focusing on efficiency for high CPU Usage (raids, etc)
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Localize functions from MHCT for performance
local UnitHealthMax = MHCT.UnitHealthMax
local UnitHealth = MHCT.UnitHealth
local UnitGetTotalAbsorbs = MHCT.UnitGetTotalAbsorbs
local UnitIsDeadOrGhost = MHCT.UnitIsDeadOrGhost
local UnitIsConnected = MHCT.UnitIsConnected
local UnitIsFeignDeath = MHCT.UnitIsFeignDeath
local UnitIsDead = MHCT.UnitIsDead
local UnitIsGhost = MHCT.UnitIsGhost
local UnitIsAFK = MHCT.UnitIsAFK
local UnitIsDND = MHCT.UnitIsDND

-- Localize Lua functions from MHCT
local format = MHCT.format
local floor = MHCT.floor
local tonumber = MHCT.tonumber

-- Set the category name for all v3 health tags
local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [health-v3]"

-- THROTTLE constants (seconds) **Does not work on nameplates**
local THROTTLE = {
	QUARTER = 0.25,
	HALF = 0.5,
	ONE = 1.0,
	TWO = 2.0,
}

-- ===================================================================================
-- STRING BUILDER - Optimized for frequent health tag updates
-- ===================================================================================

-- Localize table functions for performance
local tconcat = table.concat

-- Create a reusable string builder to avoid excessive string concatenations
-- We pre-allocate these tables to avoid table creation overhead during updates
local healthTextBuilder = {
	parts = {},
	count = 0,
}

-- Reset the builder for reuse
local function resetBuilder(builder)
	builder.count = 0
	return builder
end

-- Add a string part to the builder
local function addToBuilder(builder, str)
	builder.count = builder.count + 1
	builder.parts[builder.count] = str
	return builder
end

-- Build the final string
local function buildString(builder)
	return tconcat(builder.parts, "", 1, builder.count)
end

-- Helper function to efficiently format health text using the string builder
local function buildHealthText(unit, isPercentFirst)
	local builder = resetBuilder(healthTextBuilder)
	local maxHp = UnitHealthMax(unit)
	local currentHp = UnitHealth(unit)

	-- Get formatted current health
	local currentText = MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

	-- Calculate percentage if not at full health
	local percentText
	if currentHp < maxHp then
		percentText = format("%.1f%%", (currentHp / maxHp) * 100)
	end

	-- Handle absorb information if present
	local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
	if absorbAmount > 0 then
		addToBuilder(builder, "|cff")
		addToBuilder(builder, MHCT.ABSORB_TEXT_COLOR)
		addToBuilder(builder, "(")
		addToBuilder(builder, MHCT.E:ShortValue(absorbAmount))
		addToBuilder(builder, ")|r ")
	end

	-- Add current and percent based on order preference
	if percentText then
		if isPercentFirst then
			addToBuilder(builder, percentText)
			addToBuilder(builder, " | ")
			addToBuilder(builder, currentText)
		else
			addToBuilder(builder, currentText)
			addToBuilder(builder, " | ")
			addToBuilder(builder, percentText)
		end
	else
		-- Just current health if at full health
		addToBuilder(builder, currentText)
	end

	return buildString(builder)
end

-- ===================================================================================
-- ABSORB + CURRENT + PERCENT HEALTH (no status)
-- ===================================================================================
do
	-- CURRENT | PERCENT (original version)
	MHCT.E:AddTagInfo(
		"mh-health-current-percent",
		thisCategory,
		"Shows health as: 100k | 85% with absorbs if applicable (NO STATUS)"
	)
	MHCT.E:AddTag("mh-health-current-percent", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED", function(unit)
		return buildHealthText(unit, false) -- false = current first
	end)

	-- PERCENT | CURRENT (reversed version)
	MHCT.E:AddTagInfo(
		"mh-health-percent-current",
		thisCategory,
		"Shows health as: 85% | 100k with absorbs if applicable (NO STATUS)"
	)
	MHCT.E:AddTag("mh-health-percent-current", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED", function(unit)
		return buildHealthText(unit, true) -- true = percent first
	end)
end

-- ===================================================================================
-- HEALTH PERCENT WITH STATUS - Multiple update frequencies
-- ===================================================================================
do
	-- Common function for all health percent status tags using string builder
	local function healthPercentWithStatus(unit, decimalPlaces)
		-- First check for status
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local builder = resetBuilder(healthTextBuilder)
		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)

		-- Handle full health
		if currentHp == maxHp then
			-- Full health, just return formatted current health
			return MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
		end

		-- Calculate percentage with configured decimal places
		local decimals = tonumber(decimalPlaces) or 1
		local formatStr = format("%%.%sf%%%%", decimals)
		local percentText = format(formatStr, (currentHp / maxHp) * 100)

		addToBuilder(builder, percentText)
		return buildString(builder)
	end

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
		MHCT.E:AddTagInfo(config.name, thisCategory, config.desc)
		MHCT.E:AddTag(config.name, config.throttle, function(unit, _, args)
			return healthPercentWithStatus(unit, args)
		end)
	end

	-- Add a configurable version that lets users specify decimals
	MHCT.E:AddTagInfo(
		"mh-health-percent:status-configurable",
		thisCategory,
		"Health percent with status and configurable decimal places - Example: [mh-health-percent:status-configurable{2}:1.0] for 2 decimal places at 1s update interval"
	)

	-- Register configurable versions for each throttle rate
	for _, throttleValue in pairs(THROTTLE) do
		MHCT.E:AddTag("mh-health-percent:status-configurable", throttleValue, function(unit, _, args)
			return healthPercentWithStatus(unit, args)
		end)
	end
end

-- ===================================================================================
-- HEALTH DEFICIT WITH STATUS - Multiple update frequencies
-- ===================================================================================
do
	-- Common function for all health deficit status tags using string builder
	local function healthDeficitWithStatus(unit)
		-- First check for status
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local builder = resetBuilder(healthTextBuilder)
		local currentHp = UnitHealth(unit)
		local maxHp = UnitHealthMax(unit)

		-- Only show deficit if not at full health
		if currentHp < maxHp then
			addToBuilder(builder, "-")
			addToBuilder(builder, MHCT.E:ShortValue(maxHp - currentHp))
		end

		return buildString(builder)
	end

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
		MHCT.E:AddTagInfo(config.name, thisCategory, config.desc)
		MHCT.E:AddTag(config.name, config.throttle, function(unit)
			return healthDeficitWithStatus(unit)
		end)
	end

	-- Add a minimal version that doesn't show the minus sign (just the value)
	MHCT.E:AddTagInfo(
		"mh-health-deficit:status-minimal",
		thisCategory,
		"Minimal health deficit display - no minus sign, just the missing health value"
	)

	-- Register minimal versions for each throttle rate
	for _, config in ipairs(healthDeficitTags) do
		local minimalName = config.name:gsub(":status%-", ":minimal%-")
		MHCT.E:AddTagInfo(
			minimalName,
			thisCategory,
			"Minimal " .. config.desc:gsub("Health deficit with status", "health deficit")
		)

		MHCT.E:AddTag(minimalName, config.throttle, function(unit)
			-- Check status first
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			-- Minimal deficit (no minus sign) using string builder
			local builder = resetBuilder(healthTextBuilder)
			local currentHp = UnitHealth(unit)
			local maxHp = UnitHealthMax(unit)

			if currentHp < maxHp then
				addToBuilder(builder, MHCT.E:ShortValue(maxHp - currentHp))
			end

			return buildString(builder)
		end)
	end
end

-- ===================================================================================
-- HIDE PERCENT AT FULL HEALTH TAGS - Shows percent only when health isn't full
-- ===================================================================================
do
	-- Helper function that builds health text with configurable order
	-- Hides percentage when health is full
	local function buildHealthTextHideFullPercent(unit, isPercentFirst)
		-- Check for status first
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local maxHp = UnitHealthMax(unit)
		local currentHp = UnitHealth(unit)

		-- Use string builder for efficiency
		local builder = resetBuilder(healthTextBuilder)

		-- Get formatted current health
		local currentText = MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		-- If health is full, just return current health value
		if currentHp == maxHp then
			addToBuilder(builder, currentText)
			return buildString(builder)
		end

		-- Calculate percentage since health isn't full
		local percentText = format("%.1f%%", (currentHp / maxHp) * 100)

		-- Build the string in requested order
		if isPercentFirst then
			addToBuilder(builder, percentText)
			addToBuilder(builder, " | ")
			addToBuilder(builder, currentText)
		else
			addToBuilder(builder, currentText)
			addToBuilder(builder, " | ")
			addToBuilder(builder, percentText)
		end

		return buildString(builder)
	end

	-- Register the "current | percent" version (same as original)
	MHCT.E:AddTagInfo(
		"mh-health-current-percent-hidefull",
		thisCategory,
		"Shows health as: 100k | 85% but hides percent at full health"
	)
	MHCT.E:AddTag(
		"mh-health-current-percent-hidefull",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			return buildHealthTextHideFullPercent(unit, false) -- false = current first
		end
	)

	-- Register the "percent | current" version
	MHCT.E:AddTagInfo(
		"mh-health-percent-current-hidefull",
		thisCategory,
		"Shows health as: 85% | 100k but hides percent at full health"
	)
	MHCT.E:AddTag(
		"mh-health-percent-current-hidefull",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			return buildHealthTextHideFullPercent(unit, true) -- true = percent first
		end
	)

	--------------------------------------------------------------------
	-- BACKWARDS compatibility, register the V1 tag names as aliases
	MHCT.E:AddTagInfo(
		"mh-health:current:percent:right-hidefull",
		thisCategory,
		"Alias for mh-health-current-percent-hidefull (V3 version)"
	)
	MHCT.E:AddTag(
		"mh-health:current:percent:right-hidefull",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			return buildHealthTextHideFullPercent(unit, false)
		end
	)

	MHCT.E:AddTagInfo(
		"mh-health:current:percent:left-hidefull",
		thisCategory,
		"Alias for mh-health-percent-current-hidefull (V3 version)"
	)
	MHCT.E:AddTag(
		"mh-health:current:percent:left-hidefull",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			return buildHealthTextHideFullPercent(unit, true)
		end
	)
end
