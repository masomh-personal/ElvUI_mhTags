-- ===================================================================================
-- POWER RELATED TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references directly
local E, L = unpack(ElvUI)

-- Localize Lua functions
local format = string.format
local tonumber = tonumber

-- Localize WoW API functions
local UnitPowerType = UnitPowerType
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

-- Local constants
local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [power]"
local DEFAULT_DECIMAL_PLACE = MHCT.DEFAULT_DECIMAL_PLACE

-- FORMAT_PATTERNS table for cached decimal formats
local FORMAT_PATTERNS = {
	DECIMAL_WITHOUT_PERCENT = {}, -- Stores patterns like "%.0f", "%.1f", etc.
}

-- Initialize commonly used decimal precision patterns
for i = 0, 3 do -- Cache patterns for 0-3 decimal places (common use cases)
	FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[i] = format("%%.%df", i)
end

-- ===================================================================================
-- POWER PERCENT
-- ===================================================================================
do
	local dynamicTagName = "mh-target:frame:power-percent"
	E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Simple power percent, no percentage sign with dynamic number of decimals (dynamic number within {} of tag"
	)
	E:AddTag(dynamicTagName, "UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER", function(unit, _, args)
		local powerType = UnitPowerType(unit)
		local currentPower = UnitPower(unit, powerType)
		local maxPower = UnitPowerMax(unit)

		if currentPower ~= 0 and maxPower > 0 then -- Added check for maxPower to avoid div by zero
			local decimalPlaces = tonumber(args) or DEFAULT_DECIMAL_PLACE

			-- Use cached format pattern if available, or create one if not
			local formatPattern = FORMAT_PATTERNS.DECIMAL_WITHOUT_PERCENT[decimalPlaces]
				or format("%%.%df", decimalPlaces)

			return format(formatPattern, (currentPower / maxPower) * 100)
		end

		return ""
	end)
end
