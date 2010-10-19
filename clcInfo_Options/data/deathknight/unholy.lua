-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "DEATHKNIGHT" then return end

-- mod name in lower case
local modName = "_unholy"

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local baseMod = clcInfo.classModules[modName]
local baseDB = clcInfo.cdb.classModules[modName]

--[[
classModules
protection
tabGeneral
igRange
rangePerSkill
--]]
local function Get(info)
	return baseDB[info[#info]]
end

local function Set(info, val)
	baseDB[info[#info]] = val
end

local function LoadModule()
	options.args.classModules.args[modName] = {
		order = 4, type = "group", childGroups = "tab", name = "Unholy",
		args = {
			tabGeneral = {
				order = 1, type = "group", name = "General", args = {
					igRange = {
						order = 1, type = "group", inline = true, name = "Range check",
						args = {
							rangePerSkill = {
								type = "toggle", width = "full", name = "Range check for each skill instead of only melee range.",
								get = Get, set = Set,
							},
						},
					},
					dt = {
						order = 1, type = "group", inline = true, name = "Suggest Dark Transformation",
						args = {
							useDT = {
								type = "toggle", width = "full", name = "Suggest Dark Transformation into the rotation, you need be sure the pet will be abble to attack at all times.",
								get = Get, set = Set,
							},
						},
					},
					pest = {
						order = 1, type = "group", inline = true, name = "Suggest Pestilence",
						args = {
							usePest = {
								type = "toggle", width = "full", name = "Tries to suggest pestilence for aoe mode. User decision is probably a better option.",
								get = Get, set = Set,
							},
						},
					},
				},
			},
		},
	}
end
table.insert(clcInfo_Options.optionsCMLoaders, LoadModule)