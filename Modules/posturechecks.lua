local addonName, addon = ...
local module = addon:CreateModule("Posture Checks")

module.defaultSettings = {
	enable = false,
	disableInInstances = false,
	frequency = 45,
}

module.optionsTable = {
	description = {
		order = 1,
		type ="description",
		fontSize = "medium",
		name = "Periodically notifies you to maintain good posture during your gaming session."
	},
	break1 = {
		order = 2,
		type = "header",
		name = ""
	},
	description2 = {
		order = 3,
		type ="description",
		fontSize = "medium",
		name = addon.exclamation .. "Right click the notification to close it faster."
	},
	break2 = {
		order = 4,
		type = "header",
		name = ""
	},
	enable = {
		order = 5,
		type = "toggle",
		name = "Enable",
		width = "full",
		set = function(info, val) module.db[info[#info]] = val module:UpdateFrequency() end,
	},
	disableInInstances = {
		order = 6,
		type = "toggle",
		name = "Disable in Instances",
		width = "full",
	},
	break3 = {
		order = 7,
		type = "header",
		name = ""
	},
	frequency = {
		order = 8,
		type = "range",
		name = "Frequency",
		desc = "Measured in minutes",
		width = 1,
		min = 1,
		max = 180,
		softMin = 5,
		softMax = 180,
		step = 1,
		bigStep = 5,
		set = function(info, val) module.db[info[#info]] = val module:UpdateFrequency() end,
	},
}

function module:XaryuSettings()
	local db = self.db

	db.enable = true
	db.disableInInstances = true
	db.frequency = 60
end

function module:OnLoad()
	local function AlertSystem_Setup(frame, icon, text, desc)
		frame.Icon:SetTexture(icon)
		frame.Title:SetFontObject(GameFontNormalLarge)
		frame.Title:SetText(text)
		frame.Description:SetText(desc)

		if frame.Title:IsTruncated() then
			frame.Title:SetFontObject(GameFontNormal)
		end

		PlaySound(SOUNDKIT.UI_DIG_SITE_COMPLETION_TOAST)
	end

	self.AlertSystem = AlertFrame:AddSimpleAlertFrameSubSystem("EntitlementDeliveredAlertFrameTemplate", AlertSystem_Setup)

	local eventHandler = CreateFrame("Frame", nil , UIParent)

	eventHandler:SetScript("OnEvent", function()
		if module.queuedAlert then
			module.queuedAlert = false
			C_Timer.After(5, module.SendAlert)
		end
	end)

	eventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")

	self:UpdateFrequency()
end

function module:UpdateFrequency()
	local db = self.db

	if self.ticker then
		self.ticker:Cancel()
	end

	if not db.enable then return end

	self.ticker = C_Timer.NewTicker(db.frequency * 60, self.SendAlert)
end

function module.SendAlert()
	local _, instanceType = IsInInstance()
	if instanceType == "none" or instanceType == "scenario" or not module.db.disableInInstances then
		module.AlertSystem:AddAlert(135898, "Posture Check", "No slouching!")
	else
		module.queuedAlert = true
	end
end