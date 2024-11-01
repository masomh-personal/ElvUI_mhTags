local _, ns = ...
local MHCT = ns.MHCT

local thisCategory = MHCT.TAG_CATEGORY_NAME .. " [classification]"

MHCT.E:AddTagInfo(
	"mh-classification:icon",
	MHCT.TAG_CATEGORY_NAME .. " [classification]",
	"Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites)"
)
MHCT.E:AddTag("mh-classification:icon", "UNIT_CLASSIFICATION_CHANGED", function(unit, _, args)
	local unitType = MHCT.classificationType(unit)
	local baseIconSize = MHCT.tonumber(args) or MHCT.DEFAULT_ICON_SIZE

	if unitType and MHCT.ICON_MAP[unitType] then
		return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], baseIconSize)
	end

	return ""
end)

MHCT.E:AddTagInfo(
	"mh-classification:icon-V2",
	MHCT.TAG_CATEGORY_NAME .. " [classification]",
	"Classification custom blp icons (elite, minibosses, bosses, rares, and rare elites) - NON Dynamic sizing"
)
MHCT.E:AddTag("mh-classification:icon-V2", "UNIT_CLASSIFICATION_CHANGED", function(unit)
	local unitType = MHCT.classificationType(unit)
	local baseIconSize = MHCT.DEFAULT_ICON_SIZE

	if unitType and MHCT.ICON_MAP[unitType] then
		return MHCT.getFormattedIcon(MHCT.ICON_MAP[unitType], baseIconSize)
	end

	return ""
end)
