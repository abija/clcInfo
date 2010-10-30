-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local modName = "retribution"

local baseMod = clcInfo.classModules[modName]
local baseDB = clcInfo.cdb.classModules[modName]

clcInfo.spew = baseMod

-- some lazy staic numbers
local MAX_FILLERS = 8

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

local function GetFiller(info)
	local i = tonumber(info[#info])
	return baseDB.fillers[i]
end

local function SetFiller(info, val)
	local i = tonumber(info[#info])
	baseDB.fillers[i] = val
	baseMod:UpdatePriorityQueue()
end

spellChoice = { none = "None" }
for alias, name in pairs(baseMod.actionsName) do
	spellChoice[alias] = name
end

local function LoadModule()
	options.args.classModules.args[modName] = {
		order = 4, type = "group", childGroups = "tab", name = "Retribution",
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
					igVarious = {
						order = 2, type = "group", inline = true, name = "Prediction",
						args = {
							csBoost = {
								order = 1, type = "range", min = 0, max = 1.5, step = 0.01, name = "CS Boost",
								get = Get, set = Set,
							},
							_csBoost = {
								order = 2, type = "description", width = "double", name = "If CS cooldown is lower than this value, it will be prioritized.",
							},
							_x1 = {
								order = 3, type = "description", name = "",
							},
							wspeed = {
								order = 4, type = "range", min = 1, max = 5, step = 0.01, name = "Weapon Speed",
								get = Get, set = Set,
							},
							_wspeed = {
								order = 5, type = "description", width = "double", name = "Value from Item Tooltip. Used to calculate current haste.",
							},
						},
					},
					igInq = {
						order = 3, type = "group", inline = true, name = "Inquisition (don't enable until you trained it).",
						args = {
							useInq = {
								order = 1, type = "toggle", name = "Enabled",
								get = Get, set = Set,
							},
							_x1 = {
								order = 2, type = "description", name = "",
							},
							preInq = {
								order = 3, type = "range", min = 0, max = 15, step = 0.1, name = "Clip",
								get = Get, set = Set,
							},
							_preInq = {
								order = 4, type = "description", width = "double", name = "Seconds to refresh before buff expires.",
							},
						},
					},
				},
			},
			tabFillers = { order = 2, type = "group", name = "Priority", args = {} },
		},
	}
	
	-- filler selection
	local args = options.args.classModules.args[modName].args.tabFillers.args
	for i = 1, MAX_FILLERS do
		args[tostring(i)] = {
			order = i, type = "select", name = tostring(i), 
			get = GetFiller, set = SetFiller, values = spellChoice,
		}
	end
	
end
clcInfo_Options.optionsCMLoaders[#(clcInfo_Options.optionsCMLoaders) + 1] = LoadModule