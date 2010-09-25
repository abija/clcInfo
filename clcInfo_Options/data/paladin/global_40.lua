-- build check
local _, _, _, toc = GetBuildInfo()
if toc < 40000 then return end

-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo_Options\\data\\paladin\\global> " .. table.concat(t, " "))
end

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
	baseMod.UpdatePPBar()
end

local function LoadModuleActiveTemplate()
	baseTDB = clcInfo.activeTemplate.classModules.global

	options.args.classModules.args.global = {
		order = 1, type = "group", childGroups = "tab", name = "Global",
		args = {
			tabGeneral = {
				order = 1, type = "group", name = "General", args = {
					movePPBar = {
						order = 1, type = "group", inline = true, name = "Paladin Power Bar Position",
						args = {
							movePPBar = {
								order = 1, type = "toggle", width = "full",
								name = "Enabled",
								get = Get, set = Set,
							},
							ppbX = {
								order = 2, type = "range", min = -2000, max = 2000, step = 1, name = "X",
								get = Get, set = Set,
							},
							ppbY = {
								order = 3, type = "range", min = -2000, max = 2000, step = 1, name = "Y",
								get = Get, set = Set,
							},
							ppbScale = {
								order = 4, type = "range", min = 0.1, max = 10, step = 0.1, name = "Scale",
								get = Get, set = Set,
							},
						},
					},
				},
			},
		},
	}
end
mod.cmLoadersActiveTemplate[#(mod.cmLoadersActiveTemplate) + 1] = LoadModuleActiveTemplate
