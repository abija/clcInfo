-- ptr check
local build = GetBuildInfo()
if build ~= "4.0.6" then return end

-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local modName = "__retribution"

local baseMod, baseDB

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
	
	if info[#info] == "prio" then
		baseMod:UpdateQueue()
	end
end

local function LoadModule()
	if not clcInfo.activeTemplate then return end
	
	baseMod = clcInfo.classModules[modName]
	baseDB = clcInfo.activeTemplate.classModules[modName]
	
	local tx = {}
	for k, v in pairs(baseMod.actions) do
		table.insert(tx, format("\n%s - %s", k, v.info))
	end
	table.sort(tx)
	local prioInfo = "Legend:\n" .. table.concat(tx)
	
	options.args.classModules.args[modName] = {
		order = 4, type = "group", childGroups = "tab", name = "Retribution",
		args = {
			tabPriority = {
				order = 1, type = "group", name = "Priority", args = {
					igPrio = {
						order = 1, type = "group", inline = true, name = "",
						args = {
							info = {
								order = 1, type = "description", name = prioInfo,
							},
							prio = {
								order = 2, type = "input", width = "full", name = "",
								get = Get, set = Set,
							},
							infoCMD = {
								order = 3, type = "description", name = "Sample command line usage: /clcinfo retprio inqa tv cs exoud how exo",
							},
						},
					},
				},
			},
			tabSettings = {
				order = 2, type = "group", name = "Settings", args = {
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
							inqRefresh = {
								order = 1, type = "range", min = 1, max = 15, step = 0.1, name = "Time before refresh",
								get = Get, set = Set,
							},
							inqApplyMin = {
								order = 2, type = "range", min = 1, max = 3, step = 1, name = "Min HP for Inquisition Apply",
								get = Get, set = Set,
							},
							inqRefreshMin = {
								order = 3, type = "range", min = 1, max = 3, step = 1, name = "Min HP for Inquisition Refresh",
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
								order = 2, type = "range", min = 0, max = 2, step = 0.1, name = "Judgement Clash",
								get = Get, set = Set,
							},
							spacing1 = {
								order = 3, type = "description", name = "",
							},
							hwClash = {
								order = 5, type = "range", min = 0, max = 2, step = 0.1, name = "Holy Wrath Clash",
								get = Get, set = Set,
							},
							spacing2 = {
								order = 6, type = "description", name = "",
							},
							consClash = {
								order = 8, type = "range", min = 0, max = 2, step = 0.1, name = "Consecration Clash",
								get = Get, set = Set,
							},
							consMana = {
								order = 9, type = "range", min = 0, max = 30000, step = 1, name = "Minimum mana required",
								get = Get, set = Set,
							},
						},
					},
					igAdvanced = {
						order = 5, type = "group", inline = true, name = "Advanced tweaks",
						args = {
							hpDelay = {
								order = 1, type = "range", step = 0.1, min = 0, max = 1.5, name = "HP Delay",
								get = Get, set = Set,
							},
							predictCS = {
								order = 1, type = "toggle", name = "Predict that CS will generate HP",
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