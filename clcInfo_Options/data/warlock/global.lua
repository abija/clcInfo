-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "WARLOCK" then return end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

-- lower case module name
local modName = "_global"

local baseMod = clcInfo.classModules[modName]
local baseTDB

local function Get(info)
	return baseTDB[info[#info]]
end
local function Set(info, val)
	baseTDB[info[#info]] = val
	baseMod.UpdateSBar()
end

local function GetLocked(info)
	return baseMod.locked
end
local function SetLocked(info, val)
	baseMod.locked = val
	baseMod.UpdateSBar()
end

local function LoadModuleActiveTemplate()
	baseTDB = clcInfo.activeTemplate.classModules[modName]

	options.args.classModules.args[modName] = {
		order = 1, type = "group", childGroups = "tab", name = "Global",
		args = {
			tabGeneral = {
				order = 1, type = "group", name = "General", args = {
					moveRB = {
						order = 1, type = "group", inline = true, name = "Custom Shard Bar",
						args = {
							moveSB = {
								order = 1, type = "toggle", name = "Use own bar", get = Get, set = Set,
							},
							moveSBLock = {
								order = 2, type = "toggle", name = "Locked own bar", get = GetLocked, set = SetLocked,
							},
							hideBlizzSB = {
								order = 3, type = "toggle", width="double", name = "Hide Blizzard", get = Get, set = Set,
							},
							_s1 = {
								order = 11, type = "description", name = "",
							},
							sbX = {
								order = 12, type = "range", min = -2000, max = 2000, step = 1, name = "X", get = Get, set = Set,
							},
							sbY = {
								order = 13, type = "range", min = -2000, max = 2000, step = 1, name = "Y", get = Get, set = Set,
							},
							sbScale = {
								order = 14, type = "range", min = 0.1, max = 10, step = 0.1, name = "Scale", get = Get, set = Set,
							},
							sbAlpha = {
								order = 15, type = "range", min = 0, max = 1, step = 0.01, name = "Alpha", get = Get, set = Set,
							},
						},
					},
				},
			},
		},
	}
end
table.insert(clcInfo_Options.optionsCMLoadersActiveTemplate, LoadModuleActiveTemplate)
