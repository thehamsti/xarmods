local addonName, addon = ...
addon.addonTitle = GetAddOnMetadata(addonName, "Title")
addon.exclamation = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:-1|t"

addon.defaultSettings = {
	profile = {
		minimap = {
			hide = false,
		},
	},
}

addon.optionsTable = {
	name = addon.addonTitle,
	type = "group",
	args = {
		title = {
			order = 1,
			type = "description",
			fontSize = "large",
			image = "Interface\\AddOns\\XarMods\\Media\\logo_transparent",
			imageWidth = 26,
			imageHeight = 26,
			name = addon.addonTitle .. " " .. GetAddOnMetadata(addonName, "Version")
		},
		description = {
			order = 2,
			type ="description",
			fontSize = "medium",
			name = "An assortment of minor modifications focused on improving gameplay by adding valuable interface elements & removing non-essential ones."
		},
		break2 = {
			order = 3,
			type = "header",
			name = ""
		},
		reloadNotice = {
			order = 4,
			type = "description",
			fontSize = "medium",
			name = addon.exclamation .. "UI must be reloaded for most changes to take effect.",
		},
		break3 = {
			order = 5,
			type = "header",
			name = ""
		},
		reloadButton = {
			order = 6,
			type = "execute",
			name = "Reload UI",
			func = ReloadUI,
			width = 0.6,
		},
	},
}

local function DebugPrintf(...)
  local status, res = pcall(format, ...)
  if status then
    if DLAPI then DLAPI.DebugLog(addonName, res) end
  end
end

addon.modules = {}

local moduleOrder = 1

function addon:CreateModule(name)
	self.modules[name] = {
		order = moduleOrder
	}

	moduleOrder = moduleOrder + 1

	return self.modules[name]
end

local eventHandler = CreateFrame("Frame", nil, UIParent)
eventHandler:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)
eventHandler:RegisterEvent("ADDON_LOADED")

function eventHandler:ADDON_LOADED(arg1)
	if arg1 ~= addonName then return end

	for mod, _ in pairs(addon.modules) do
		addon.optionsTable.args[mod] = {
			order = addon.modules[mod].order,
			type = "group",
			name = mod,
			get = function(info) return addon.modules[mod].db[info[#info]] end,
			set = function(info, val) addon.modules[mod].db[info[#info]] = val end,
			args = addon.modules[mod].optionsTable,
		}

		addon.defaultSettings.profile[mod] = addon.modules[mod].defaultSettings
	end

	addon.db = LibStub("AceDB-3.0"):New(addonName.."DB", addon.defaultSettings, true)

	addon.optionsTable.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db)
	addon.optionsTable.args.profile.args.reset.width = 0.8
	addon.optionsTable.args.profile.args.current.order = 12

	addon.optionsTable.args.profile.args.xaryu = {
		order = 11,
		type = "execute",
		name = "Xaryu's Profile",
		desc = "Changes to Xaryu's preferred settings",
		func = function()
			for mod, _ in pairs(addon.modules) do
				if addon.modules[mod].XaryuSettings then
					addon.modules[mod]:XaryuSettings()
				end
			end

			addon.db.profile.minimap.hide = false

			ReloadUI()
		end,
		width = 0.8,
	}

	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, addon.optionsTable)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addon.addonTitle)
	LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 550, 640)

	local function OnProfileChange()
		for mod, _ in pairs(addon.modules) do
			addon.modules[mod].db = addon.db.profile[mod]
		end
	end

	addon.db.RegisterCallback(self, "OnProfileChanged", OnProfileChange)
	addon.db.RegisterCallback(self, "OnProfileCopied", OnProfileChange)
	addon.db.RegisterCallback(self, "OnProfileReset", ReloadUI)

	local LDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
		type = "launcher",
		icon = "Interface\\AddOns\\XarMods\\Media\\logo",
		OnTooltipShow = function(tooltip) tooltip:AddLine(addon.addonTitle) end,
		OnClick = function()
			local config = LibStub("AceConfigDialog-3.0")

			if config.OpenFrames[addonName] then
				config:Close(addonName)
			else
				config:Open(addonName)
			end
		end,
	})

	addon.icon = LibStub("LibDBIcon-1.0")
	addon.icon:Register(addonName, LDB, addon.db.profile.minimap)

	for mod, _ in pairs(addon.modules) do
		addon.modules[mod].db = addon.db.profile[mod]
		if addon.modules[mod].OnLoad then
			addon.modules[mod]:OnLoad()
		end
	end

	_G["SLASH_"..addonName.."1"] = "/"..addonName
	_G["SLASH_"..addonName.."2"] = "/xar"
	SlashCmdList[addonName] = function() LibStub("AceConfigDialog-3.0"):Open(addonName) end

	_G["SLASH_"..addonName.."_RELOAD1"] = "/rl"
	SlashCmdList[addonName.."_RELOAD"] = ReloadUI
end
