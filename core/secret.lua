-- WoW 12.0+ secret-value formatting and ColorCurve helpers.
local _, ns = ...
local MHCT = ns.MHCT

local format = string.format
local unpack = unpack

local UnitHealthPercent = UnitHealthPercent
local UnitPowerPercent = UnitPowerPercent
local UnitPowerType = UnitPowerType
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local CreateColor = CreateColor
local CreateColorCurve = C_CurveUtil and C_CurveUtil.CreateColorCurve
local LuaCurveTypeLinear = Enum.LuaCurveType and Enum.LuaCurveType.Linear
local AbbreviateNumbers = AbbreviateNumbers
local TruncateWhenZero = C_StringUtil and C_StringUtil.TruncateWhenZero
local WrapString = C_StringUtil and C_StringUtil.WrapString
local strconcat = string.concat
local issecretvalue = issecretvalue

-- Scale percentages in C so restricted values never require Lua arithmetic.
local CURVE_SCALE_TO_100 = CurveConstants and CurveConstants.ScaleTo100 or nil
if not CURVE_SCALE_TO_100 then
	error("ElvUI_mhTags: CurveConstants.ScaleTo100 is required on supported WoW clients.")
end

-- Returns percent (0-100), isSecret.
MHCT.GetHealthPercent = function(unit)
	if not unit then
		return nil, false
	end
	local pct = UnitHealthPercent(unit, true, CURVE_SCALE_TO_100)
	if pct == nil then
		return nil, false
	end
	if issecretvalue(pct) then
		return pct, true
	end
	return pct, false
end

-- Returns percent (0-100), isSecret.
MHCT.GetPowerPercent = function(unit, powerType)
	if not unit then
		return nil, false
	end
	if not powerType then
		powerType = UnitPowerType(unit)
	end
	local pct = UnitPowerPercent(unit, powerType, false, CURVE_SCALE_TO_100)
	if pct == nil then
		return nil, false
	end
	if issecretvalue(pct) then
		return pct, true
	end
	return pct, false
end

-- Format a number with K/M/B suffix. AbbreviateNumbers accepts secrets.
MHCT.FormatLargeNumber = function(value)
	if value == nil then
		return MHCT.SECRET_VALUE_FALLBACK_TEXT
	end
	return AbbreviateNumbers(value)
end

-- Format a 0-100 percentage using the supported 0-3 decimal patterns.
MHCT.FormatPercent = function(percentValue, decimals, includeSign)
	if percentValue == nil then
		return MHCT.SECRET_VALUE_FALLBACK_TEXT
	end
	decimals = decimals or 0
	if decimals < 0 then
		decimals = 0
	end
	if decimals > 3 then
		decimals = 3
	end

	local result = format(MHCT.PERCENT_FORMATS[decimals], percentValue)
	if includeSign == nil or includeSign then
		return result .. "%"
	end
	return result
end

-- Return an absorb amount in parentheses, optionally followed by a space.
MHCT.getAbsorbText = function(unit, withTrailingSpace)
	if not unit then
		return ""
	end

	local absorbAmount = UnitGetTotalAbsorbs(unit)
	if absorbAmount == nil then
		return ""
	end

	if not issecretvalue(absorbAmount) then
		if absorbAmount <= 0 then
			return ""
		end
		local result = AbbreviateNumbers(absorbAmount)
		if result == nil or result == "" or result == "0" then
			return ""
		end
		local text = strconcat("(", result, ")")
		return withTrailingSpace and strconcat(text, " ") or text
	end

	-- Secret zeros require C-side truncation and wrapping. AbbreviateNumbers
	-- would display "0", and no API combines abbreviation with zero-gating.
	if type(absorbAmount) ~= "number" or not TruncateWhenZero or not WrapString then
		return ""
	end

	local infix = TruncateWhenZero(absorbAmount)
	if infix == nil then
		return ""
	end

	local suffix = withTrailingSpace and ") " or ")"
	return WrapString(infix, "(", suffix)
end

-- Build the shared three-stop health ColorCurve once.
local HEALTH_COLOR_CURVE
if CreateColorCurve and CreateColor and LuaCurveTypeLinear then
	HEALTH_COLOR_CURVE = CreateColorCurve()
	HEALTH_COLOR_CURVE:SetType(LuaCurveTypeLinear)
	local lr, lg, lb = unpack(MHCT.HEALTH_GRADIENT_STOPS.LOW)
	local mr, mg, mb = unpack(MHCT.HEALTH_GRADIENT_STOPS.MID)
	local hr, hg, hb = unpack(MHCT.HEALTH_GRADIENT_STOPS.HIGH)
	HEALTH_COLOR_CURVE:AddPoint(0.0, CreateColor(lr, lg, lb))
	HEALTH_COLOR_CURVE:AddPoint(0.5, CreateColor(mr, mg, mb))
	HEALTH_COLOR_CURVE:AddPoint(1.0, CreateColor(hr, hg, hb))
end
MHCT.HEALTH_COLOR_CURVE = HEALTH_COLOR_CURVE

-- Return an opening color escape for the current health gradient.
MHCT.getHealthGradientColorPrefix = function(unit)
	if not unit or not HEALTH_COLOR_CURVE then
		return nil
	end
	local color = UnitHealthPercent(unit, true, HEALTH_COLOR_CURVE)
	if not color then
		return nil
	end
	return "|c" .. color:GenerateHexColor()
end
