local _, ns = ...
local MHCT = ns.MHCT

local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [power]"

-- POWER PERCENT
do
	local dynamicTagName = "mh-target:frame:power-percent"
	MHCT.E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Simple power percent, no percentage sign with dynamic number of decimals (dynamic number within {} of tag - see examples above)"
	)
	MHCT.E:AddTag(dynamicTagName, "UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER", function(unit, _, args)
		local powerType = MHCT.UnitPowerType(unit)
		local currentPower = UnitPower(unit, powerType)
		local maxPower = UnitPowerMax(unit)

		if currentPower ~= 0 then
			local decimalPlaces = MHCT.tonumber(args) or MHCT.DEFAULT_DECIMAL_PLACE
			local formatDecimal = MHCT.format("%%.%sf", decimalPlaces)
			return MHCT.format(formatDecimal, (currentPower / maxPower) * 100)
		end

		return ""
	end)
end
