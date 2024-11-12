-- ===================================================================================
-- VERSION 1.0 of health related tags
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- ===================================================================================
-- HEALTH RELATED TAGS
-- ===================================================================================
do
	MHCT.E:AddTagInfo(
		"mh-health:current:percent:left",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Shows current + percent health at all times similar to following example: 85% | 100k"
	)
	MHCT.E:AddTag(
		"mh-health:current:percent:left",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = MHCT.UnitHealthMax(unit)
			local currentHp = MHCT.UnitHealth(unit)
			local currentPercent = (currentHp / maxHp) * 100
			return MHCT.format(
				"%.1f%% | %s",
				currentPercent,
				MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
			)
		end
	)

	MHCT.E:AddTagInfo(
		"mh-health:current:percent:right",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Shows current + percent health at all times similar to following example: 100k | 85%"
	)
	MHCT.E:AddTag(
		"mh-health:current:percent:right",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = MHCT.UnitHealthMax(unit)
			local currentHp = MHCT.UnitHealth(unit)
			local currentPercent = (currentHp / maxHp) * 100
			return MHCT.format(
				"%s | %.1f%%",
				MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true),
				currentPercent
			)
		end
	)

	MHCT.E:AddTagInfo(
		"mh-health:current:percent:right-hidefull",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Hides percent at full health else shows at all times similar to following example: 100k | 85%"
	)
	MHCT.E:AddTag(
		"mh-health:current:percent:right-hidefull",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = MHCT.UnitHealthMax(unit)
			local currentHp = MHCT.UnitHealth(unit)

			if maxHp ~= currentHp then
				local currentPercent = (currentHp / maxHp) * 100
				return MHCT.format(
					"%s | %.1f%%",
					MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true),
					currentPercent
				)
			else
				return MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
			end
		end
	)

	MHCT.E:AddTagInfo(
		"mh-health:current:percent:left-hidefull",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Hides percent at full health else shows at all times similar to following example: 85% |100k"
	)
	MHCT.E:AddTag(
		"mh-health:current:percent:left-hidefull",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = MHCT.UnitHealthMax(unit)
			local currentHp = MHCT.UnitHealth(unit)

			if maxHp ~= currentHp then
				local currentPercent = (currentHp / maxHp) * 100
				return MHCT.format(
					"%.1f%% | %s",
					currentPercent,
					MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
				)
			else
				return MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)
			end
		end
	)

	MHCT.E:AddTagInfo(
		"mh-health:absorb:current:percent:right",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Hides percent at full health else shows absorb, current, and percent to following example: (**absorb amount**) 100k | 85%"
	)
	MHCT.E:AddTag(
		"mh-health:absorb:current:percent:right",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED UNIT_ABSORB_AMOUNT_CHANGED",
		function(unit)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = MHCT.UnitHealthMax(unit)
			local currentHp = MHCT.UnitHealth(unit)
			local returnString = MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

			if maxHp ~= currentHp then
				local currentPercent = (currentHp / maxHp) * 100
				returnString = MHCT.format("%s | %.1f%%", returnString, currentPercent)
			end

			local absorbAmount = MHCT.UnitGetTotalAbsorbs(unit) or 0
			if absorbAmount ~= 0 then
				return MHCT.format(
					"|cff%s(%s)|r %s",
					MHCT.ABSORB_TEXT_COLOR,
					MHCT.E:ShortValue(absorbAmount),
					returnString
				)
			end

			return returnString
		end
	)

	MHCT.E:AddTagInfo(
		"mh-health:simple:percent",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Shows max hp at full or percent with dynamic # of decimals (dynamic number within {} of tag) - Example: [mh-health:simple:percent{2}] will show percent to 2 decimal places"
	)
	MHCT.E:AddTag(
		"mh-health:simple:percent",
		"PLAYER_FLAGS_CHANGED UNIT_CONNECTION UNIT_HEALTH",
		function(unit, _, args)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			return MHCT.formatHealthPercent(unit, args, true)
		end
	)

	MHCT.E:AddTagInfo(
		"mh-health:simple:percent-nosign",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Shows max hp at full or percent (with no % sign) with dynamic # of decimals (dynamic number within {} of tag) - [Example: mh-health:simple:percent{2}] will show percent to 2 decimal places"
	)
	MHCT.E:AddTag(
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

	MHCT.E:AddTagInfo(
		"mh-health:simple:percent-nosign-v2",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Hidden at max hp at full or percent (with no % sign) with dynamic # of decimals (dynamic number within {} of tag) - Example: mh-health:simple:percent{2} will show percent to 2 decimal places"
	)
	MHCT.E:AddTag(
		"mh-health:simple:percent-nosign-v2",
		"PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
		function(unit, _, args)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = MHCT.UnitHealthMax(unit)
			local currentHp = MHCT.UnitHealth(unit)
			if currentHp ~= maxHp then
				local decimalPlaces = MHCT.tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
				local formatDecimal = MHCT.format("%%.%sf", decimalPlaces)
				return MHCT.format(formatDecimal, (currentHp / maxHp) * 100)
			end

			return ""
		end
	)

	MHCT.E:AddTagInfo(
		"mh-health:simple:percent-v2",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Hidden at max hp at full or percent + % sign with dynamic # of decimals (dynamic number within {} of tag) - Example: [mh-health:simple:percent{2}] will show percent to 2 decimal places"
	)
	MHCT.E:AddTag(
		"mh-health:simple:percent-v2",
		"PLAYER_FLAGS_CHANGED UNIT_NAME_UPDATE UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH",
		function(unit, _, args)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local maxHp = MHCT.UnitHealthMax(unit)
			local currentHp = MHCT.UnitHealth(unit)
			if currentHp ~= maxHp then
				local decimalPlaces = MHCT.tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
				local formatDecimal = MHCT.format("%%.%sf%%%%", decimalPlaces)
				return MHCT.format(formatDecimal, (currentHp / maxHp) * 100)
			end

			return ""
		end
	)

	MHCT.E:AddTagInfo(
		"mh-deficit:num-status",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Shows deficit shortvalue number when less than 100% health and status + icon if dead/offline/ghost"
	)
	MHCT.E:AddTag(
		"mh-deficit:num-status",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local currentHp, maxHp = MHCT.UnitHealth(unit), MHCT.UnitHealthMax(unit)
			return (currentHp == maxHp) and "" or MHCT.format("-%s", MHCT.E:ShortValue(maxHp - currentHp))
		end
	)

	MHCT.E:AddTagInfo(
		"mh-deficit:num-nostatus",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Shows deficit shortvalue number when less than 100% health (no status)"
	)
	MHCT.E:AddTag("mh-deficit:num-nostatus", "UNIT_HEALTH UNIT_MAXHEALTH", function(unit)
		local currentHp, maxHp = MHCT.UnitHealth(unit), MHCT.UnitHealthMax(unit)
		return (currentHp == maxHp) and "" or MHCT.format("-%s", MHCT.E:ShortValue(maxHp - currentHp))
	end)

	MHCT.E:AddTagInfo(
		"mh-deficit:percent-status",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Shows deficit percent with dynamic decimal when less than 100% health + status icon"
	)
	MHCT.E:AddTag(
		"mh-deficit:percent-status",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit, _, args)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local decimalPlaces = MHCT.tonumber(args) or 1
			local currentHp, maxHp = MHCT.UnitHealth(unit), MHCT.UnitHealthMax(unit)
			local formatDecimal = MHCT.format("-%%.%sf%%%%", decimalPlaces)
			return (currentHp == maxHp) and "" or MHCT.format(formatDecimal, 100 - (currentHp / maxHp) * 100)
		end
	)

	MHCT.E:AddTagInfo(
		"mh-deficit:percent-status-nosign",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Shows deficit percent with dynamic decimal when less than 100% health + status icon (does not include %)"
	)
	MHCT.E:AddTag(
		"mh-deficit:percent-status-nosign",
		"UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED",
		function(unit, _, args)
			local statusFormatted = MHCT.formatWithStatusCheck(unit)
			if statusFormatted then
				return statusFormatted
			end

			local decimalPlaces = MHCT.tonumber(args) or 1
			local currentHp, maxHp = MHCT.UnitHealth(unit), MHCT.UnitHealthMax(unit)
			local formatDecimal = MHCT.format("-%%.%sf", decimalPlaces)
			return (currentHp == maxHp) and "" or MHCT.format(formatDecimal, 100 - (currentHp / maxHp) * 100)
		end
	)

	MHCT.E:AddTagInfo(
		"mh-deficit:percent-nostatus",
		MHCT.TAG_CATEGORY_NAME .. " [health-v1]",
		"Shows deficit percent with dynamic decimal when less than 100% health (no status)"
	)
	MHCT.E:AddTag("mh-deficit:percent-nostatus", "UNIT_HEALTH UNIT_MAXHEALTH", function(unit, _, args)
		local decimalPlaces = MHCT.tonumber(args) or 1
		local currentHp, maxHp = MHCT.UnitHealth(unit), MHCT.UnitHealthMax(unit)
		local formatDecimal = MHCT.format("-%%.%sf%%%%", decimalPlaces)
		return (currentHp == maxHp) and "" or MHCT.format(formatDecimal, 100 - (currentHp / maxHp) * 100)
	end)
end
