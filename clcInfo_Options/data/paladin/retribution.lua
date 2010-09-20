-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo_Options\\data\\paladin\\retribution> " .. table.concat(t, " "))
end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options


--[[
classModules
retribution
tabGeneral
igRange
rangePerSkill
--]]
local function Get(info)
	return clcInfo.cdb.classModules.paladin.retribution[info[#info]]
end

local function Set(info, val)
	clcInfo.cdb.classModules.paladin.retribution[info[#info]] = val
end

local function GetFCFS(info)
	local i = tonumber(info[#info])
	return clcInfo.cdb.classModules.paladin.retribution.fcfs[i]
end

local function SetFCFS(info, val)
	local i = tonumber(info[#info])
	clcInfo.cdb.classModules.paladin.retribution.fcfs[i] = val
	clcInfo.classModules.paladin.retribution:UpdateFCFS()
end

local function GetSpellChoice()
	local spells = clcInfo.classModules.paladin.retribution.spells
	local sc = { none = "None" }
	for alias, data in pairs(spells) do
		sc[alias] = data.name
	end
	
	return sc
end

local function LoadModule()
	-- create tables if there aren't any
	if not options.args.classModules then 
		options.args.classModules = { order = 500, type = "group", name = "Class Modules", args = {} }
	end
	options = options.args.classModules
	
	-- retribution options
	options.args.retribution = {
		order = 3, type = "group", childGroups = "tab", name = "Retribution",
		args = {
			tabGeneral = {
				order = 1, type = "group", name = "General",
				args = {
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
			
			tabFCFS = { order = 2, type = "group", name = "FCFS", args = {} },
		},
	}
	
	-- don't manually add 10 fcfs buttons
	local args = options.args.retribution.args.tabFCFS.args
	for i = 1, 10 do
		args["label" .. i] = {
			order = i*2, type = "description", name = "", width = "double",
		}
		args[tostring(i)] = {
			order = i*2 - 1, type = "select", name = tostring(i), 
			get = GetFCFS, set = SetFCFS, values = GetSpellChoice,
		}
	end
	
end
mod.cmLoaders[#(mod.cmLoaders) + 1] = LoadModule