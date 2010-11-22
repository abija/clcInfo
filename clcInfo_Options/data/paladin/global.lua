-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local baseMod = clcInfo.classModules.global
local baSetPPBDB

local function GetPPB(info)
	return baSetPPBDB[info[#info]]
end
local function SetPPB(info, val)
	baSetPPBDB[info[#info]] = val
	baseMod.UpdatePPBar()
end

local function GetLocked(info)
	return baseMod.locked
end
local function SetLocked(info, val)
	baseMod.locked = val
	baseMod.UpdatePPBar()
end

local function LoadModuleActiveTemplate()
	baSetPPBDB = clcInfo.activeTemplate.classModules.global

	options.args.classModules.args.global = {
		order = 1, type = "group", childGroups = "tab", name = "Global",
		args = {
			tabGeneral = {
				order = 1, type = "group", name = "General", args = {
					movePPBar = {
						order = 1, type = "group", inline = true, name = "Custom Holy Power Bar",
						args = {
							movePPBar = {
								order = 1, type = "toggle", name = "Use own bar", get = GetPPB, set = SetPPB,
							},
							movePPBarLock = {
								order = 2, type = "toggle", name = "Locked own bar", get = GetLocked, set = SetLocked,
							},
							hideBlizPPB = {
								order = 3, type = "toggle", width="double", name = "Hide Blizzard", get = GetPPB, set = SetPPB,
							},
							_s1 = {
								order = 11, type = "description", name = "",
							},
							ppbX = {
								order = 12, type = "range", min = -2000, max = 2000, step = 1, name = "X", get = GetPPB, set = SetPPB,
							},
							ppbY = {
								order = 13, type = "range", min = -2000, max = 2000, step = 1, name = "Y", get = GetPPB, set = SetPPB,
							},
							ppbScale = {
								order = 14, type = "range", min = 0.1, max = 10, step = 0.1, name = "Scale", get = GetPPB, set = SetPPB,
							},
							ppbAlpha = {
								order = 15, type = "range", min = 0, max = 1, step = 0.01, name = "Alpha", get = GetPPB, set = SetPPB,
							},
						},
					},
				},
			},
		},
	}
end
clcInfo_Options.optionsCMLoadersActiveTemplate[#(clcInfo_Options.optionsCMLoadersActiveTemplate) + 1] = LoadModuleActiveTemplate
