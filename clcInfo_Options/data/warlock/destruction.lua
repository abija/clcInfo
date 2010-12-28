-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "WARLOCK" then return end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local modName = "_destruction"

local baseMod = clcInfo.classModules[modName]
local baseDB = clcInfo.cdb.classModules[modName]

-- some lazy staic numbers
local MAX_PRIORITY = 12

local function Get(info)
	return baseDB[info[#info]]
end

local function Set(info, val)
	baseDB[info[#info]] = val
end

local function GetPriority(info)
	local i = tonumber(info[#info])
	return baseDB.priority[i]
end

local function SetPriority(info, val)
	local i = tonumber(info[#info])
	baseDB.priority[i] = val
	baseMod:UpdatePriorityQueue()
end

spellChoice = { none = "None" }
for alias, name in pairs(baseMod.actionsName) do
	spellChoice[alias] = name
end

local function LoadModule()
	options.args.classModules.args[modName] = {
		order = 4, type = "group", childGroups = "tab", name = "Destruction",
		args = {
			tabGeneral = {
				order = 1, type = "group", name = "General", args = {
					igVarious = {
						order = 1, type = "group", inline = true, name = "Prediction",
						args = {
							clipImmolate = {
								order = 1, type = "range", min = 0, max = 3, step = 0.01, name = "Immolate Clip",
								get = Get, set = Set,
							},
							_clipImmolate = {
								order = 2, type = "description", width = "double", name = "Seconds left on debuffs before considering refreshing debuff.",
							},
							_x1 = {
								order = 3, type = "description", name = "",
							},
							clipCorruption = {
								order = 4, type = "range", min = 0, max = 3, step = 0.01, name = "Corruption Clip",
								get = Get, set = Set,
							},
							_clipCorruption = {
								order = 5, type = "description", width = "double", name = "Seconds left on debuffs before considering refreshing debuff.",
							},
							_x2 = {
								order = 6, type = "description", name = "",
							},
							clipBaneOfDoom = {
								order = 7, type = "range", min = 0, max = 3, step = 0.01, name = "Bane Of Doom Clip",
								get = Get, set = Set,
							},
							_clipBaneOfDoom = {
								order = 8, type = "description", width = "double", name = "Seconds left on debuffs before considering refreshing debuff.",
							},
							_x3 = {
								order = 9, type = "description", name = "",
							},
							debuffDelay = {
								order = 10, type = "range", min = 0, max = 2, step = 0.01, name = "Debuff application delay",
								get = Get, set = Set,
							},
							_debuffDelay = {
								order = 11, type = "description", width = "double", name = "Time needed in seconds for debuff to show on your target.",
							},
						},
					},
				},
			},
			tabPriority = { order = 2, type = "group", name = "Priority", args = {} },
		},
	}
	
	-- filler selection
	local args = options.args.classModules.args[modName].args.tabPriority.args
	for i = 1, MAX_PRIORITY do
		args[tostring(i)] = {
			order = i, type = "select", name = tostring(i), 
			get = GetPriority, set = SetPriority, values = spellChoice,
		}
	end
	
end
clcInfo_Options.optionsCMLoaders[#(clcInfo_Options.optionsCMLoaders) + 1] = LoadModule