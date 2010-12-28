-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local modName = "retributionex"

local baseMod = clcInfo.classModules[modName]
local baseDB = clcInfo.activeTemplate.classModules[modName]

--[[
classModules
retribution
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
		order = 4, type = "group", childGroups = "tab", name = "RetributionEx",
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
					igInquisition = {
						order = 2, type = "group", inline = true, name = "Inquisition",
						args = {
							useInq = {
								type = "toggle", name = "Enable",
								get = Get, set = Set,
							},
							preInq = {
								type = "range", min = 1, max = 15, step = 0.1, name = "Time before refresh",
								get = Get, set = Set,
							},
						},
					},
					igLocalization = {
						order = 3, type = "group", inline = true, name = "Creature type localization",
						args = {
							undead = {
								order = 1, type = "input", name = "Undead",
								get = Get, set = Set,
							},
							demon = {
								order = 2, type = "input", name = "Demon",
								get = Get, set = Set,
							},
						},
					},
					igFillers = {
						order = 4, type = "group", inline = true, name = "Fillers",
						args = {
							infoClash = {
								order = 1, type = "description", name = "Clash means the value of CS cooldown before the filler is used.",
							},
							jClash = {
								order = 2, type = "range", min = 0, max = 1.5, step = 0.1, name = "Judgement Clash",
								get = Get, set = Set,
							},
							spacing1 = {
								order = 3, type = "description", name = "",
							},
							hw = {
								order = 4, type = "toggle", name = "Use Holy Wrath",
								get = Get, set = Set,
							},
							hwClash = {
								order = 5, type = "range", min = 0, max = 1.5, step = 0.1, name = "Holy Wrath Clash",
								get = Get, set = Set,
							},
							spacing2 = {
								order = 6, type = "description", name = "",
							},
							cons = {
								order = 7, type = "toggle", name = "Use Consecration",
								get = Get, set = Set,
							},
							consClash = {
								order = 8, type = "range", min = 0, max = 1.5, step = 0.1, name = "Consecration Clash",
								get = Get, set = Set,
							},
							consMana = {
								order = 9, type = "range", min = 0, max = 30000, step = 1, name = "Minimum mana required",
								get = Get, set = Set,
							},
						},
					},

				},
			},
		},
	}
end
clcInfo_Options.optionsCMLoaders[#(clcInfo_Options.optionsCMLoaders) + 1] = LoadModule