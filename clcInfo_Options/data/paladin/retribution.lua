-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local baseMod = clcInfo.classModules.retribution
local baseDB = clcInfo.cdb.classModules.retribution

-- some lazy staic numbers
local MAX_FILLERS = 9

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
	baseMod:UpdateFillers()
end

local function GetSpellChoice()
	local spells = baseMod.fillers
	local sc = { none = "None" }
	for alias, data in pairs(spells) do
		sc[alias] = data.name
	end
	
	return sc
end

local function LoadModule()
	options.args.classModules.args.retribution = {
		order = 4, type = "group", childGroups = "tab", name = "Retribution",
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
			tabFillers = { order = 2, type = "group", name = "Priority", args = {} },
		},
	}
	
	-- filler selection
	local args = options.args.classModules.args.retribution.args.tabFillers.args
	for i = 1, MAX_FILLERS do
		args[tostring(i)] = {
			order = i, type = "select", name = tostring(i), 
			get = GetFiller, set = SetFiller, values = GetSpellChoice,
		}
	end
	
end
clcInfo.optionsCMLoaders[#(clcInfo.optionsCMLoaders) + 1] = LoadModule