-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "DEATHKNIGHT" then return end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local baseMod = clcInfo.classModules.global
local baseTDB

local function Get(info)
	return baseTDB[info[#info]]
end

local function Set(info, val)
	baseTDB[info[#info]] = val
	baseMod.UpdateRuneBar()
end

local function LoadModuleActiveTemplate()
	baseTDB = clcInfo.activeTemplate.classModules.global
	
	options.args.classModules.args.global = {
		order = 1, type = "group", childGroups = "tab", name = "Global",
		args = {
			tabGeneral = {
				order = 1, type = "group", name = "General", args = {
					moveRuneBar = {
						order = 1, type = "group", inline = true, name = "Rune Bar Position",
						args = {
							moveRuneBar = {
								order = 1, type = "toggle", width = "full",
								name = "Move RuneBar (relative to center of the screen).",
								get = Get, set = Set,
							},
							rbX = {
								order = 2, type = "range", min = -2000, max = 2000, step = 1, name = "X",
								get = Get, set = Set,
							},
							rbY = {
								order = 3, type = "range", min = -2000, max = 2000, step = 1, name = "Y",
								get = Get, set = Set,
							},
							rbScale = {
								order = 4, type = "range", min = 0.1, max = 10, step = 0.1, name = "Scale",
								get = Get, set = Set,
							},
							rbAlpha = {
								order = 5, type = "range", min = 0, max = 1, step = 0.01, name = "Alpha",
								get = Get, set = Set,
							},
						},
					},
				},
			},
		},
	}
end
-- these modules are loaded whenever template changes
clcInfo_Options.optionsCMLoadersActiveTemplate[#(clcInfo_Options.optionsCMLoadersActiveTemplate) + 1] = LoadModuleActiveTemplate