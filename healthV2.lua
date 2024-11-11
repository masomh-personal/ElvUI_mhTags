-- ===================================================================================
-- VERSION 2.0 of health related tags. Focusing on efficiency for high CPU Usage (raids, etc)
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [health-v2]"

-- THROTTLE (seconds) **Does not work on nameplates**
local THROTTLE_HALF_SECOND = 0.5
local THROTTLE_QUARTER_SECOND = 0.25
local THROTTLE_ONE_SECOND = 1
local THROTTLE_TWO_SECONDS = 2

-- ===================================================================================
-- ABSORB + CURRENT + PERCENT HEALTH (no status)
-- ===================================================================================
do
	local dynamicTagName = "mh-health-current-percent"

	-- CURRENT | Percent
	MHCT.E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Hides percent at full health else shows absorb, current, and percent to following example: (**absorb amount**) 100k | 85%"
	)

	MHCT.E:AddTag(dynamicTagName, "UNIT_HEALTH UNIT_MAXHEALTH", function(unit)
		local maxHp = MHCT.UnitHealthMax(unit)
		local currentHp = MHCT.UnitHealth(unit)
		local returnString = MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		if maxHp ~= currentHp then
			local currentPercent = (currentHp / maxHp) * 100
			returnString = MHCT.format("%s | %.1f%%", returnString, currentPercent)
		end

		local absorbAmount = MHCT.UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount ~= 0 then
			return MHCT.format("|cff%s(%s)|r %s", MHCT.ABSORB_TEXT_COLOR, MHCT.E:ShortValue(absorbAmount), returnString)
		end

		return returnString
	end)

	-- CURRENT | PERCENT HEALTH (no status)
	dynamicTagName = "mh-health-current-percent-V2"
	MHCT.E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Hides percent at full health else shows absorb, current, and percent to following example: (**absorb amount**) 85% | 100k"
	)

	MHCT.E:AddTag(dynamicTagName, "UNIT_HEALTH UNIT_MAXHEALTH", function(unit)
		local maxHp = MHCT.UnitHealthMax(unit)
		local currentHp = MHCT.UnitHealth(unit)
		local returnString = MHCT.E:GetFormattedText("CURRENT", currentHp, maxHp, nil, true)

		if maxHp ~= currentHp then
			local currentPercent = (currentHp / maxHp) * 100
			returnString = MHCT.format("%.1f%% | %s", currentPercent, returnString)
		end

		local absorbAmount = MHCT.UnitGetTotalAbsorbs(unit) or 0
		if absorbAmount ~= 0 then
			return MHCT.format("|cff%s(%s)|r %s", MHCT.ABSORB_TEXT_COLOR, MHCT.E:ShortValue(absorbAmount), returnString)
		end

		return returnString
	end)
end

-- ===================================================================================
-- HEALTH PERCENT
-- ===================================================================================
do
	local dynamicTagName = "mh-health-percent:status-1.0"
	MHCT.E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Shows percent health + any status if applicable @ 1.0 second interval updates"
	)

	MHCT.E:AddTag(dynamicTagName, THROTTLE_ONE_SECOND, function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthPercent(unit, _, true)
	end)

	dynamicTagName = "mh-health-percent:status-2.0"
	MHCT.E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Shows percent health + any status if applicable @ 2.0 second interval updates"
	)

	MHCT.E:AddTag(dynamicTagName, THROTTLE_TWO_SECONDS, function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthPercent(unit, _, true)
	end)

	dynamicTagName = "mh-health-percent:status-0.5"
	MHCT.E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Shows percent health + any status if applicable @ 0.5 second interval updates"
	)

	MHCT.E:AddTag(dynamicTagName, THROTTLE_HALF_SECOND, function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthPercent(unit, _, true)
	end)

	MHCT.E:AddTag(dynamicTagName, THROTTLE_TWO_SECONDS, function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthPercent(unit, _, true)
	end)

	dynamicTagName = "mh-health-percent:status-0.25"
	MHCT.E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Shows percent health + any status if applicable @ 0.25 second interval updates"
	)

	MHCT.E:AddTag(dynamicTagName, THROTTLE_QUARTER_SECOND, function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthPercent(unit, _, true)
	end)
end

-- ===================================================================================
-- HEALTH DEFICIT
-- ===================================================================================
do
	local dynamicTagName = "mh-health-deficit:status-0.5"
	MHCT.E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Shows health deficient (short value) + status @ 0.5 second interval updates"
	)

	MHCT.E:AddTag(dynamicTagName, THROTTLE_HALF_SECOND, function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthDeficit(unit)
	end)

	dynamicTagName = "mh-health-deficit:status-1.0"
	MHCT.E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Shows health deficient (short value) + status @ 1.0 second interval updates"
	)

	MHCT.E:AddTag(dynamicTagName, THROTTLE_ONE_SECOND, function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthDeficit(unit)
	end)

	dynamicTagName = "mh-health-deficit:status-2.0"
	MHCT.E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Shows health deficient (short value) + status @ 2.0 second interval updates"
	)

	MHCT.E:AddTag(dynamicTagName, THROTTLE_TWO_SECONDS, function(unit)
		local statusFormatted = MHCT.formatWithStatusCheck(unit)
		if statusFormatted then
			return statusFormatted
		end

		return MHCT.formatHealthDeficit(unit)
	end)
end
