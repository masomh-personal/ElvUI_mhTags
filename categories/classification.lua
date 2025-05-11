-- ===================================================================================
-- CLASSIFICATION TAGS - Optimized for efficiency
-- ===================================================================================
local _, ns = ...
local MHCT = ns.MHCT

-- Get ElvUI references directly
local E, L = unpack(ElvUI)

-- Localize Lua functions
local tonumber = tonumber

-- Local constants
local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [classification]"
local DEFAULT_ICON_SIZE = MHCT.DEFAULT_ICON_SIZE

-- ===================================================================================
-- UNIT CLASSIFICATION (ICONS)
-- ===================================================================================
do
	-- Dynamic size version
	local dynamicTagName = "mh-classification:icon"
	E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites)"
	)
	E:AddTag(dynamicTagName, "UNIT_CLASSIFICATION_CHANGED", function(unit, _, args)
		local unitType = MHCT.classificationType(unit)
		local baseIconSize = tonumber(args) or DEFAULT_ICON_SIZE

		if unitType and MHCT.ICON_MAP[unitType] then
			return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], baseIconSize)
		end

		return ""
	end)

	-- Fixed size version
	dynamicTagName = "mh-classification:icon-V2"
	E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites) - NON Dynamic sizing"
	)
	E:AddTag(dynamicTagName, "UNIT_CLASSIFICATION_CHANGED", function(unit)
		local unitType = MHCT.classificationType(unit)

		if unitType and MHCT.ICON_MAP[unitType] then
			return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], DEFAULT_ICON_SIZE)
		end

		return ""
	end)
end
