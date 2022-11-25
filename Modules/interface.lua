local addonName, addon = ...
local module = addon:CreateModule("Interface")

module.defaultSettings = {
	hideLOCBackground = false,
	hideUIErrorsFrame = false,
	hideBags = false,
	hideMicroButtons = false,
	hideGlow = false,
	hideEffects = false,
	hideZoom = false,
	scrollZoom = false,
	sellGrays = false,
	repair = false,
	dampeningDisplay = false,
}

module.optionsTable = {
	header_visibility = {
		order = 1,
		type = "header",
		name = "Visibility",
	},
	hideLOCBackground = {
		order = 2,
		type = "toggle",
		name = "Hide Loss of Control Background",
		desc = "Black background on the \"Loss of Control\" frame",
		width = "full",
	},
	hideUIErrorsFrame = {
		order = 3,
		type = "toggle",
		name = "Hide UI Errors & Objective Updates",
		desc = "Text at center of screen that appears when errors occur or quest objectives are updated (Out of range spells, killing quest NPCs, etc)",
		width = "full",
	},
	hideBags = {
		order = 4,
		type = "toggle",
		name = "Hide Bags",
		width = "full",
	},
	hideMicroButtons = {
		order = 5,
		type = "toggle",
		name = "Hide Micro Buttons",
		desc = "Buttons at the bottom right corner",
		width = "full",
	},
	hideGlow = {
		order = 6,
		type = "toggle",
		name = "Disable Screen Glow",
		desc = "Bloom effects in the world",
		width = "full",
	},
	hideEffects = {
		order = 7,
		type = "toggle",
		name = "Disable Screen Effects",
		desc = "Effects such as \"blurry\" invisibility",
		width = "full",
	},
	header_minimap = {
		order = 8,
		type = "header",
		name = "Minimap",
	},
	hideMinimapButton = {
		order = 9,
		type = "toggle",
		name = "Hide " .. addon.addonTitle .. " Button",
		width = "full",
		get = function(info) return addon.db.profile.minimap.hide end,
		set = function(info, val)
			addon.db.profile.minimap.hide = val
			if val then
				addon.icon:Hide(addonName)
			else
				addon.icon:Show(addonName)
			end
		end,
	},
	hideZoom = {
		order = 10,
		type = "toggle",
		name = "Hide Zoom Buttons",
		width = "full",
	},
	scrollZoom = {
		order = 11,
		type = "toggle",
		name = "Enable Scroll Wheel Zooming",
		desc = "Zoom in & out on minimap using mousewheel",
		width = "full",
	},
	header_automation = {
		order = 12,
		type = "header",
		name = "Automation",
	},
	sellGrays = {
		order = 13,
		type = "toggle",
		name = "Auto Sell Grays",
		width = "full",
	},
	repair = {
		order = 14,
		type = "toggle",
		name = "Auto Repair",
		width = "full",
	},
	header_arena = {
		order = 15,
		type = "header",
		name = "Arena",
	},
	-- dampeningDisplay = {
	-- 	order = 16,
	-- 	type = "toggle",
	-- 	name = "Dampening Display",
	-- 	desc = "Text at the top of the screen to indicate dampening severity in arenas",
	-- 	width = "full",
	-- },
}

local eventHandler = CreateFrame("Frame", nil , UIParent)
eventHandler:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)

function module:XaryuSettings()
	local db = self.db

	db.hideLOCBackground = true
	db.hideUIErrorsFrame = false
	db.hideBags = true
	db.hideMicroButtons = false
	db.hideGlow = true
	db.hideEffects = true
	db.hideZoom = true
	db.scrollZoom = true
	db.sellGrays = true
	db.repair = true
	db.dampeningDisplay = true
end

function module:OnLoad()
	local db = self.db

	eventHandler:RegisterEvent("MERCHANT_SHOW")

	if db.hideLOCBackground then
		LossOfControlFrame.blackBg:SetAlpha(0)
		LossOfControlFrame.RedLineTop:SetAlpha(0)
		LossOfControlFrame.RedLineBottom:SetAlpha(0)
	end

	if db.hideUIErrorsFrame then
		UIErrorsFrame:Hide()
	end

	if db.hideBags then
		MicroButtonAndBagsBar:Hide()
	end

	if db.hideMicroButtons then
		local tframe = CreateFrame("FRAME")
		tframe:Hide()

		hooksecurefunc("UpdateMicroButtonsParent", function()
			for i=1, #MICRO_BUTTONS do
				_G[MICRO_BUTTONS[i]]:SetParent(tframe)
			end
		end)

		UpdateMicroButtonsParent(tframe)
	end

	if db.hideZoom then
		MinimapZoomIn:Hide()
		MinimapZoomOut:Hide()
	end

	if db.scrollZoom then
		Minimap:EnableMouseWheel(true)

		Minimap:SetScript("OnMouseWheel", function(self, arg1)
			if arg1 > 0 then
				Minimap_ZoomIn()
			else
				Minimap_ZoomOut()
			end
		end)
	end

	SetCVar("ffxGlow", db.hideGlow and 0 or 1)

	SetCVar("ffxDeath", db.hideEffects and 0 or 1)
	SetCVar("ffxNether", db.hideEffects and 0 or 1)

	if db.dampeningDisplay then
		local dampeningText = GetSpellInfo(110310)

		local dampeningFrame = CreateFrame("Frame", nil , UIParent)
		dampeningFrame:SetSize(200, 12)
		dampeningFrame:SetPoint("TOP", UIWidgetTopCenterContainerFrame, "BOTTOM", 0, -2)
		dampeningFrame.text = dampeningFrame:CreateFontString(nil, "BACKGROUND")
		dampeningFrame.text:SetFontObject(GameFontNormalSmall)
		dampeningFrame.text:SetAllPoints()

		local function DampeningDisplay_Update()
			dampeningFrame.text:SetText(dampeningText..": "..C_Commentator.GetDampeningPercent().."%")
		end

		local dampeningTicker

		dampeningFrame:SetScript("OnEvent", function(self)
			if dampeningTicker then
				dampeningTicker:Cancel()
			end

			if select(2, IsInInstance()) == "arena" then
				dampeningFrame:Show()
				dampeningTicker = C_Timer.NewTicker(5, DampeningDisplay_Update)
			else
				dampeningFrame:Hide()
			end
		end)

		dampeningFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	end
end

function eventHandler:MERCHANT_SHOW()
	if module.db.sellGrays then
		local timer = 0.15
		for bag = 0, 4 do
			for slot = 0, GetContainerNumSlots(bag) do
				local link = GetContainerItemLink(bag, slot)
				if link and select(3, GetItemInfo(link)) == 0 then
					C_Timer.After(timer, function() UseContainerItem(bag, slot) end)
					timer = timer + 0.15
				end
			end
		end
	end

	if module.db.repair then
		local repairAllCost, canRepair = GetRepairAllCost()
		if canRepair and repairAllCost <= GetMoney() then
			RepairAllItems(false)
		end
	end
end