-- ===================================================================================
-- VERSION 1.0 of health related tags - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references directly
local E, L = unpack(ElvUI)

-- Localize Lua functions
local format = string.format
local tonumber = tonumber

-- Localize WoW API functions
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs

-- Local constants
local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [health-v1]"
local DEFAULT_DECIMAL_PLACE = MHCT.DEFAULT_DECIMAL_PLACE
local ABSORB_TEXT_COLOR = MHCT.ABSORB_TEXT_COLOR

-- FORMAT_PATTERNS table for cached decimal formats
local FORMAT_PATTERNS = {
	DECIMAL_WITH_PERCENT = {}, -- Stores patterns like "%.0f%%", "%.1f%%", etc.
	DECIMAL_WITHOUT_PERCENT = {}, -- Stores patterns like "%.0f", "%.1f", etc.
	DEFICIT_WITH_PERCENT = {}, -- Stores patterns like "-%.0f%%", "-%.1f%%", etc.
	DEFICIT_WITHOUT_PERCENT = {}, -- Stores patterns like "-%.0f", "-%.1f", etc.
}

-- Initialize patterns for common decimal place counts
for i = 0, 3 do
	FORMAT_PATTERNS.DECIMAL_WITH_PERCENT[i] = format("%%.%sf%%%%", i)
	FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[i] = format("%%.%sf", i)
	FORMAT_PATTERNS.DEFICIT_WITH_PERCENT[i] = format("-%%.%sf%%%%", i)
	FORMAT_PATTERNS.DEFICIT_WITHOUT_PERCENT[i] = format("-%%.%sf", i)
end

-- ===================================================================================
-- HEALTH RELATED TAGS
-- ===================================================================================
do
	-- Current + Percent (Percent first)
	E:AddTagInfo(
		"mh-health:current:percent:left",
		thisCategory,
		"Shows current + percent health at all times similar to following example: 85% | 100k"
	)
	E:AddTag(
		"mh-health:current:percent:left",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = UnitHealthMax(unit)
			local currentHp = UnitHealth(unit)
			local currentPercent = (currentHp / maxHp) * 100
			return format("%.1f%% | %s", currentPercent, E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true))
		end
	)

	-- Current + Percent (Current first)
	E:AddTagInfo(
		"mh-health:current:percent:right",
		thisCategory,
		"Shows current + percent health at all times similar to following example: 100k | 85%"
	)
	E:AddTag(
		"mh-health:current:percent:right",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = UnitHealthMax(unit)
			local currentHp = UnitHealth(unit)
			local currentPercent = (currentHp / maxHp) * 100
			return format("%s | %.1f%%", E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true), currentPercent)
		end
	)

	-- Current + Percent (Current first, hide percent at full)
	E:AddTagInfo(
		"mh-health:current:percent:right-hidefull",
		thisCategory,
		"Hides percent at full health else shows at all times similar to following example: 100k | 85%"
	)
	E:AddTag(
		"mh-health:current:percent:right-hidefull",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = UnitHealthMax(unit)
			local currentHp = UnitHealth(unit)

			if maxHp ~= currentHp then
				local currentPercent = (currentHp / maxHp) * 100
				return format("%s | %.1f%%", E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true), currentPercent)
			else
				return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
			end
		end
	)

	-- Current + Percent (Percent first, hide percent at full)
	E:AddTagInfo(
		"mh-health:current:percent:left-hidefull",
		thisCategory,
		"Hides percent at full health else shows at all times similar to following example: 85% |100k"
	)
	E:AddTag(
		"mh-health:current:percent:left-hidefull",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = UnitHealthMax(unit)
			local currentHp = UnitHealth(unit)

			if maxHp ~= currentHp then
				local currentPercent = (currentHp / maxHp) * 100
				return format("%.1f%% | %s", currentPercent, E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true))
			else
				return E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
			end
		end
	)

	-- Absorb + Current + Percent
	E:AddTagInfo(
		"mh-health:absorb:current:percent:right",
		thisCategory,
		"Hides percent at full health else shows absorb, current, and percent to following example: (**absorb amount**) 100k | 85%"
	)
	E:AddTag(
		"mh-health:absorb:current:percent:right",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_ABSORB_AMOUNT_CHANGED",
		function(unit)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = UnitHealthMax(unit)
			local currentHp = UnitHealth(unit)
			local returnString = E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

			if maxHp ~= currentHp then
				local currentPercent = (currentHp / maxHp) * 100
				returnString = format("%s | %.1f%%", returnString, currentPercent)
			end

			local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
			if absorbAmount ~= 0 then
				return format("|cff%s(%s)|r %s", ABSORB_TEXT_COLOR, E:ShortValue(absorbAmount), returnString)
			end

			return returnString
		end
	)

	-- Simple Percent with status
	E:AddTagInfo(
		"mh-health:simple:percent",
		thisCategory,
		"Shows max hp at full or percent with dynamic # of decimals (dynamic number within {} of tag) - Example: [mh-health:simple:percent{2}] will show percent to 2 decimal places"
	)
	E:AddTag("mh-health:simple:percent", "PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH", function(unit, _, args)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthPercent(unit, args, true)
	end)

	-- Simple Percent with status (no % sign)
	E:AddTagInfo(
		"mh-health:simple:percent-nosign",
		thisCategory,
		"Shows max hp at full or percent (with no % sign) with dynamic # of decimals (dynamic number within {} of tag) - [Example: mh-health:simple:percent{2}] will show percent to 2 decimal places"
	)
	E:AddTag(
		"mh-health:simple:percent-nosign",
		"PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH",
		function(unit, _, args)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			return MHCT.formatHealthPercent(unit, args, false)
		end
	)

	-- Simple Percent v2 (hidden at full, no % sign)
	E:AddTagInfo(
		"mh-health:simple:percent-nosign-v2",
		thisCategory,
		"Hidden at max hp at full or percent (with no % sign) with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places"
	)
	E:AddTag(
		"mh-health:simple:percent-nosign-v2",
		"PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
		function(unit, _, args)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = UnitHealthMax(unit)
			local currentHp = UnitHealth(unit)
			if currentHp ~= maxHp then
				local decimalPlaces = tonumber(args) or DEFAULT_DECIMAL_PLACE

				-- Use cached format pattern if available
				local formatPattern = FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[decimalPlaces]
					or format("%%.%sf", decimalPlaces)

				return format(formatPattern, (currentHp / maxHp) * 100)
			end

			return ""
		end
	)

	-- Simple Percent v2 (hidden at full, with % sign)
	E:AddTagInfo(
		"mh-health:simple:percent-v2",
		thisCategory,
		"Hidden at max hp at full or percent + % sign with dynamic # of decimals (dynamic number within {} of tag) - Example: [mh-health:simple:percent{2}] will show percent to 2 decimal places"
	)
	E:AddTag(
		"mh-health:simple:percent-v2",
		"PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
		function(unit, _, args)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = UnitHealthMax(unit)
			local currentHp = UnitHealth(unit)
			if currentHp ~= maxHp then
				local decimalPlaces = tonumber(args) or DEFAULT_DECIMAL_PLACE

				-- Use cached format pattern if available
				local formatPattern = FORMAT_PATTERNS.DECIMAL_WITH_PERCENT[decimalPlaces]
					or format("%%.%sf%%%%", decimalPlaces)

				return format(formatPattern, (currentHp / maxHp) * 100)
			end

			return ""
		end
	)

	-- Deficit with status
	E:AddTagInfo(
		"mh-deficit:num-status",
		thisCategory,
		"Shows deficit shortvalue number when less than 100% health and status + icon if dead/offline/ghost"
	)
	E:AddTag("mh-deficit:num-status", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED", function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		return (currentHp == maxHp) and "" or format("-%s", E:ShortValue(maxHp - currentHp))
	end)

	-- Deficit without status
	E:AddTagInfo(
		"mh-deficit:num-nostatus",
		thisCategory,
		"Shows deficit shortvalue number when less than 100% health (no status)"
	)
	E:AddTag("mh-deficit:num-nostatus", "UNIT_HEALTH UNIT_MAXHEALTH", function(unit)
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)
		return (currentHp == maxHp) and "" or format("-%s", E:ShortValue(maxHp - currentHp))
	end)

	-- Deficit percent with status
	E:AddTagInfo(
		"mh-deficit:percent-status",
		thisCategory,
		"Shows deficit percent with dynamic decimal when less than 100% health + status icon"
	)
	E:AddTag(
		"mh-deficit:percent-status",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit, _, args)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local decimalPlaces = tonumber(args) or 1
			local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)

			if currentHp == maxHp then
				return ""
			end

			-- Use cached format pattern if available
			local formatPattern = FORMAT_PATTERNS.DEFICIT_WITH_PERCENT[decimalPlaces]
				or format("-%%.%sf%%%%", decimalPlaces)

			return format(formatPattern, 100 - (currentHp / maxHp) * 100)
		end
	)

	-- Deficit percent with status (no % sign)
	E:AddTagInfo(
		"mh-deficit:percent-status-nosign",
		thisCategory,
		"Shows deficit percent with dynamic decimal when less than 100% health + status icon (does not include %)"
	)
	E:AddTag(
		"mh-deficit:percent-status-nosign",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit, _, args)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local decimalPlaces = tonumber(args) or 1
			local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)

			if currentHp == maxHp then
				return ""
			end

			-- Use cached format pattern if available
			local formatPattern = FORMAT_PATTERNS.DEFICIT_WITHOUT_PERCENT[decimalPlaces]
				or format("-%%.%sf", decimalPlaces)

			return format(formatPattern, 100 - (currentHp / maxHp) * 100)
		end
	)

	-- Deficit percent without status
	E:AddTagInfo(
		"mh-deficit:percent-nostatus",
		thisCategory,
		"Shows deficit percent with dynamic decimal when less than 100% health (no status)"
	)
	E:AddTag("mh-deficit:percent-nostatus", "UNIT_HEALTH UNIT_MAXHEALTH", function(unit, _, args)
		local decimalPlaces = tonumber(args) or 1
		local currentHp, maxHp = UnitHealth(unit), UnitHealthMax(unit)

		if currentHp == maxHp then
			return ""
		end

		-- Use cached format pattern if available
		local formatPattern = FORMAT_PATTERNS.DEFICIT_WITH_PERCENT[decimalPlaces]
			or format("-%%.%sf%%%%", decimalPlaces)

		return format(formatPattern, 100 - (currentHp / maxHp) * 100)
	end)
end
