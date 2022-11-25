local addonName, addon = ...
local module = addon:CreateModule("UnitFrames")

module.defaultSettings = {
	hideFeedbackText = false,
	hidePvpIcons = false,
	classColorsPlayer = false,
	classColorsOthers = false,
	enablePlayerChain = false,
	chainStyle = 1,
	combatIndicator = false,
}

function module:XaryuSettings()
	local db = self.db

	db.hideFeedbackText = false
	db.hidePvpIcons = true
	db.combatIndicator = true
	db.classColorsPlayer = true
	db.classColorsOthers= true
	db.enablePlayerChain = true
	db.chainStyle = 3
end

module.optionsTable = {
	header_visibility = {
		order = 1,
		type = "header",
		name = "Visibility",
	},
	hideFeedbackText = {
		order = 2,
		type = "toggle",
		name = "Hide Feedback Text",
		desc = "Healing/damage text on the player & pet portraits",
		width = "full",
	},
	hidePvpIcons = {
		order = 3,
		type = "toggle",
		name = "Hide PvP Icons",
		desc = "Icons indicating if a player if flagged for PvP and/or prestige badge",
		width = "full",
	},
	header_classColors = {
		order = 4,
		type = "header",
		name = "Class Colors",
	},
	classColorsPlayer = {
		order = 5,
		type = "toggle",
		name = "Player",
		width = "full",
	},
	classColorsOthers = {
		order = 6,
		type = "toggle",
		name = "Others",
		desc = "Target, Target-of-Target, Focus, etc.",
		width = "full",
	},
	header_playerChain = {
		order = 7,
		type = "header",
		name = "Player Chain",
	},
	enablePlayerChain = {
		order = 8,
		type = "toggle",
		name = "Enable",
		desc = "Shows a rare, elite or rare elite chain around the player frame",
		width = "half",
	},
	chainStyle = {
		order = 9,
		type = "select",
		name = "Style",
		values = {
			"Elite",
			"Rare",
			"Rare Elite",
		},
		set = function(info, val)
			module.db[info[#info]] = val
			module.SetChainStyle()
		end,
	},
	header_miscellaneous = {
		order = 10,
		type = "header",
		name = "Miscellaneous",
	},
	combatIndicator = {
		order = 11,
		type = "toggle",
		name = "Combat Indicator",
		desc = "Small icon indicating when target & focus are in combat",
		width = "full",
	},
}

function module:OnLoad()
	local db = self.db

	if db.hideFeedbackText then
		local feedbackText = PlayerFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")

		PlayerFrame.feedbackText = feedbackText
		PlayerFrame.feedbackStartTime = 0
		PetFrame.feedbackText = feedbackText
		PetFrame.feedbackStartTime = 0

		PlayerHitIndicator:Hide()
		PetHitIndicator:Hide()
	end

	if db.hidePvpIcons then
		PlayerPVPIcon:SetAlpha(0)
		PlayerPrestigeBadge:SetAlpha(0)
		PlayerPrestigePortrait:SetAlpha(0)
		TargetFrameTextureFramePVPIcon:SetAlpha(0)
		TargetFrameTextureFramePrestigeBadge:SetAlpha(0)
		TargetFrameTextureFramePrestigePortrait:SetAlpha(0)
		FocusFrameTextureFramePVPIcon:SetAlpha(0)
		FocusFrameTextureFramePrestigeBadge:SetAlpha(0)
		FocusFrameTextureFramePrestigePortrait:SetAlpha(0)
	end

	if db.combatIndicator then
		local targetFrame = CreateFrame("Frame", nil , TargetFrame)
		targetFrame:SetPoint("LEFT", TargetFrame, "RIGHT", -25, 10)
		targetFrame:SetSize(26,26)
		targetFrame.icon = targetFrame:CreateTexture(nil, "BORDER")
		targetFrame.icon:SetAllPoints()
		targetFrame.icon:SetTexture([[Interface\Icons\ABILITY_DUALWIELD]])
		targetFrame:Hide()

		local focusFrame = CreateFrame("Frame", nil , FocusFrame)
		focusFrame:SetPoint("LEFT", FocusFrame, "RIGHT", -25, 10)
		focusFrame:SetSize(26,26)
		focusFrame.icon = focusFrame:CreateTexture(nil, "BORDER")
		focusFrame.icon:SetAllPoints()
		focusFrame.icon:SetTexture([[Interface\Icons\ABILITY_DUALWIELD]])
		focusFrame:Hide()

		local UnitAffectingCombat = UnitAffectingCombat

		local function CombatIndicator_Update()
			targetFrame:SetShown(UnitAffectingCombat("target"))
			focusFrame:SetShown(UnitAffectingCombat("focus"))
		end

		C_Timer.NewTicker(0.1, CombatIndicator_Update)
	end

	if db.classColorsPlayer or db.classColorsOthers then
		local	UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS, PlayerFrameHealthBar =
		UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS, PlayerFrameHealthBar
		local _, class, c

		local function ColorStatusbar(statusbar, unit)
			if statusbar == PlayerFrameHealthBar and not db.classColorsPlayer then return end
			if statusbar ~= PlayerFrameHealthBar and not db.classColorsOthers then return end

			if UnitIsPlayer(unit) and UnitIsConnected(unit) and UnitClass(unit) then
				if unit == statusbar.unit then
					_, class = UnitClass(unit)
					c = RAID_CLASS_COLORS[class]
					statusbar:SetStatusBarColor(c.r, c.g, c.b)
				end
			end
		end

		hooksecurefunc("UnitFrameHealthBar_Update", ColorStatusbar)
		hooksecurefunc("HealthBar_OnValueChanged", function(self) ColorStatusbar(self, self.unit) end)
	end

	self.SetChainStyle()
end

function module.SetChainStyle()
	local db = module.db

	if not db.enablePlayerChain then return end

	-- Ensure chain doesnt clip through pet portrait and rune frame
	PetPortrait:GetParent():SetFrameLevel(4)
	RuneFrame:SetFrameLevel(4)

	local chain = db.chainStyle

	if chain == 1 then -- Rare
		PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare")
	elseif chain == 2 then -- Elite
		PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite")
	elseif chain == 3 then -- Rare Elite
		PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite")
	end
end