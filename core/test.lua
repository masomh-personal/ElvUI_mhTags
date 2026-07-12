-- On-demand visual dashboard for exercising every registered tag in game.
local _, ns = ...
local MHCT = ns.MHCT

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local UIParent = UIParent
local format = string.format
local gmatch = string.gmatch
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local strconcat = string.concat
local tinsert = table.insert
local type = type

local DASHBOARD_WIDTH = 860
local DASHBOARD_HEIGHT = 620
local ROW_HEIGHT = 20
local NAME_WIDTH = 330
local VALUE_WIDTH = 220
local PLAYER_X = 344
local TARGET_X = 574
local REFRESH_DELAY = 0.25

local EXTRA_CASES = {
	{ name = "mh-health-percent", args = "0" },
	{ name = "mh-health-percent", args = "2" },
	{ name = "mh-health-percent", args = "3" },
	{ name = "mh-health-percent-nosign", args = "0" },
	{ name = "mh-health-percent-nosign", args = "2" },
	{ name = "mh-health-percent-nosign", args = "3" },
	{ name = "mh-health-deficit-percent", args = "0" },
	{ name = "mh-health-deficit-percent", args = "2" },
	{ name = "mh-health-deficit-percent", args = "3" },
	{ name = "mh-power-percent", args = "1" },
	{ name = "mh-power-percent", args = "2" },
	{ name = "mh-power-percent", args = "3" },
	{ name = "mh-name-caps", args = "10" },
	{ name = "mh-classification-icon", args = "18" },
	{ name = "mh-color-custom", args = "FF5733" },
}

local dashboard

local function addBackdrop(frame, color)
	local background = frame:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(color[1], color[2], color[3], color[4])
	return background
end

local function createTestCases()
	local cases = {}
	local definitionsByName = {}

	for _, definition in ipairs(MHCT.registeredTags) do
		definitionsByName[definition.name] = definition
		tinsert(cases, {
			definition = definition,
			label = format("[%s]", definition.name),
		})
	end

	for _, extra in ipairs(EXTRA_CASES) do
		local definition = definitionsByName[extra.name]
		if definition then
			tinsert(cases, {
				definition = definition,
				args = extra.args,
				label = format("[%s{%s}]", extra.name, extra.args),
			})
		end
	end

	return cases
end

local function setTestValue(fontString, testCase, unit)
	local definition = testCase.definition
	local ok, result = pcall(definition.func, unit, "MHTAGS_TEST", testCase.args)
	if not ok then
		fontString:SetText(format("|cffff5555ERROR: %s|r", result))
		return 1
	end

	if definition.subCategory == "colors" then
		fontString:SetText(strconcat(result, "Aa123 ■■|r"))
	else
		fontString:SetText(result)
	end

	return 0
end

local function refreshDashboard(frame)
	local errorCount = 0
	for _, row in ipairs(frame.rows) do
		errorCount = errorCount + setTestValue(row.playerValue, row.testCase, "player")
		errorCount = errorCount + setTestValue(row.targetValue, row.testCase, "target")
	end

	local errorColor = errorCount == 0 and "|cff50C878" or "|cffff5555"
	frame.status:SetText(
		format(
			"%sCallback errors: %d|r  |  Rows: %d  |  Hover a row for its description",
			errorColor,
			errorCount,
			#frame.rows
		)
	)
	frame.dirty = false
end

local function createRow(parent, testCase, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(DASHBOARD_WIDTH - 52, ROW_HEIGHT)
	row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
	row.testCase = testCase

	if index % 2 == 0 then
		addBackdrop(row, { 1, 1, 1, 0.04 })
	end

	local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	name:SetPoint("LEFT", row, "LEFT", 6, 0)
	name:SetWidth(NAME_WIDTH)
	name:SetJustifyH("LEFT")
	name:SetText(testCase.label)

	local playerValue = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	playerValue:SetPoint("LEFT", row, "LEFT", PLAYER_X, 0)
	playerValue:SetWidth(VALUE_WIDTH)
	playerValue:SetJustifyH("LEFT")
	playerValue:SetWordWrap(false)
	row.playerValue = playerValue

	local targetValue = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	targetValue:SetPoint("LEFT", row, "LEFT", TARGET_X, 0)
	targetValue:SetWidth(VALUE_WIDTH)
	targetValue:SetJustifyH("LEFT")
	targetValue:SetWordWrap(false)
	row.targetValue = targetValue

	row:EnableMouse(true)
	row:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.testCase.label)
		GameTooltip:AddLine(self.testCase.definition.description, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return row
end

local function createDashboard()
	local frame = CreateFrame("Frame", "ElvUI_mhTagsTestDashboard", UIParent, "BackdropTemplate")
	frame:SetSize(DASHBOARD_WIDTH, DASHBOARD_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(0.04, 0.04, 0.04, 0.96)
	frame:SetBackdropBorderColor(0.2, 0.8, 0.8, 0.9)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
	title:SetText("ElvUI_mhTags Test Dashboard")

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)

	local refresh = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	refresh:SetSize(80, 22)
	refresh:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -12)
	refresh:SetText("Refresh")
	refresh:SetScript("OnClick", function()
		refreshDashboard(frame)
	end)

	local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	status:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -42)
	status:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -42)
	status:SetJustifyH("LEFT")
	frame.status = status

	local header = CreateFrame("Frame", nil, frame)
	header:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -62)
	header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -34, -62)
	header:SetHeight(22)
	addBackdrop(header, { 0.1, 0.6, 0.65, 0.25 })

	local tagHeader = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	tagHeader:SetPoint("LEFT", header, "LEFT", 6, 0)
	tagHeader:SetWidth(NAME_WIDTH)
	tagHeader:SetJustifyH("LEFT")
	tagHeader:SetText("Tag")

	local playerHeader = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	playerHeader:SetPoint("LEFT", header, "LEFT", PLAYER_X, 0)
	playerHeader:SetWidth(VALUE_WIDTH)
	playerHeader:SetJustifyH("LEFT")
	playerHeader:SetText("Player")

	local targetHeader = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	targetHeader:SetPoint("LEFT", header, "LEFT", TARGET_X, 0)
	targetHeader:SetWidth(VALUE_WIDTH)
	targetHeader:SetJustifyH("LEFT")
	targetHeader:SetText("Target")

	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -86)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 16)

	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetWidth(DASHBOARD_WIDTH - 52)
	scrollFrame:SetScrollChild(content)

	frame.rows = {}
	local cases = createTestCases()
	for index, testCase in ipairs(cases) do
		tinsert(frame.rows, createRow(content, testCase, index))
	end
	content:SetHeight(#frame.rows * ROW_HEIGHT)

	local watchedEvents = {
		GROUP_ROSTER_UPDATE = true,
		PLAYER_ENTERING_WORLD = true,
		PLAYER_FLAGS_CHANGED = true,
		PLAYER_TARGET_CHANGED = true,
	}
	for _, definition in ipairs(MHCT.registeredTags) do
		if type(definition.events) == "string" then
			for event in gmatch(definition.events, "%S+") do
				watchedEvents[event] = true
			end
		end
	end
	for event in pairs(watchedEvents) do
		frame:RegisterEvent(event)
	end

	frame:SetScript("OnEvent", function(self)
		self.dirty = true
	end)
	frame:SetScript("OnUpdate", function(self, elapsed)
		if not self.dirty then
			return
		end
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed < REFRESH_DELAY then
			return
		end
		self.elapsed = 0
		refreshDashboard(self)
	end)
	frame:SetScript("OnShow", function(self)
		self.dirty = true
		self.elapsed = REFRESH_DELAY
	end)

	return frame
end

MHCT.toggleTestDashboard = function()
	if not dashboard then
		dashboard = createDashboard()
		refreshDashboard(dashboard)
		return
	end

	if dashboard:IsShown() then
		dashboard:Hide()
	else
		dashboard:Show()
	end
end
