local _, ns = ...
local MHCT = ns.MHCT

local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [classification]"

-- ===================================================================================
-- UNIT CLASSICFICATION (ICONS)
-- ===================================================================================
do
	local dynamicTagName = "mh-classification:icon"
	MHCT.E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites)"
	)
	MHCT.E:AddTag(dynamicTagName, "UNIT_CLASSIFICATION_CHANGED", function(unit, _, args)
		local unitType = MHCT.classificationType(unit)
		local baseIconSize = MHCT.tonumber(args) or MHCT.DEFAULT_ICON_SIZE

		if unitType and MHCT.ICON_MAP[unitType] then
			return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], baseIconSize)
		end

		return ""
	end)

	dynamicTagName = "mh-classification:icon-V2"
	MHCT.E:AddTagInfo(
		dynamicTagName,
		thisCategory,
		"Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites) - NON Dynamic sizing"
	)
	MHCT.E:AddTag(dynamicTagName, "UNIT_CLASSIFICATION_CHANGED", function(unit)
		local unitType = MHCT.classificationType(unit)
		local baseIconSize = MHCT.DEFAULT_ICON_SIZE

		if unitType and MHCT.ICON_MAP[unitType] then
			return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], baseIconSize)
		end

		return ""
	end)
end
