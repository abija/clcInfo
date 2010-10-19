-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "DEATHKNIGHT" then return end

-- mod name in lower case
local modName = "_frost"

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
		order = 4, type = "group", childGroups = "tab", name = "Frost",
		args = {
			tabGeneral = {
				order = 1, type = "group", name = "General", args = {
					igRange = {
						order = 1, type = "group", inline = true, name = "Range check",
						args = {
							rangePerSkill = {
								type = "toggle", width = "full",
								name = "Range check for each skill instead of only melee range.",
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