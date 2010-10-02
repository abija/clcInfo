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
local MAX_FCFS = 10							-- elements in fcfs
local MAX_PRESETS = 10					-- number of presets


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

local function GetFCFS(info)
	local i = tonumber(info[#info])
	return baseDB.fcfs[i]
end

local function SetFCFS(info, val)
	local i = tonumber(info[#info])
	baseDB.fcfs[i] = val
	baseMod:UpdateFCFS()
end

local function GetSpellChoice()
	local spells = baseMod.spells
	local sc = { none = "None" }
	for alias, data in pairs(spells) do
		sc[alias] = data.name
	end
	
	return sc
end

-- preset frame get, set
local function GetPF(info)
	return baseDB.presetFrame[info[#info]]
end
local function SetPF(info, val)
	baseDB.presetFrame[info[#info]] = val
	baseMod:PresetFrame_UpdateAll()
end
local function GetPF_Color(info)
	return unpack(baseDB.presetFrame[info[#info]])
end
local function SetPF_Color(info, r, g, b, a)
	baseDB.presetFrame[info[#info]] = {r, g, b, a}
	baseMod:PresetFrame_UpdateAll()
end

-- preset get, set, load, save
--info: classModules retribution tabPresets 1 name
local function GetP(info)
	return baseDB.presets[tonumber(info[4])][info[5]]
end
local function SetP(info, val)
	baseDB.presets[tonumber(info[4])][info[5]] = strtrim(val)
	baseMod:PresetFrame_UpdateAll()
end
local function LoadP(info)
	baseMod.Preset_Load(tonumber(info[4]))
end
local function SaveP(info)
	baseMod.Preset_SaveCurrent(tonumber(info[4]))
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
			
			tabFCFS = { order = 2, type = "group", name = "FCFS", args = {} },
			
			tabPresets = {
				order = 3, type = "group", name = "Presets", args = {
					____info = {
						order = 1, type = "description",
						name = "This is a rudimentary presets module. Works only for retribution. It allows you to save current FCFS to a preset and to load it from there. You can also load the preset with |cffffff00/clcInfo ret_lp preset_name|cffffffff.\n"					
					},
					____presetFrameToggle = {
						order = 10, type = "description",
						name = "The Preset Frame shows the name of the active preset. Second option allows you to select the preset from the frame with a popup menu.",
					},
					toggle = {
						order = 11, type = "execute", name = "Toggle Preset Frame", func = baseMod.PresetFrame_Toggle,
					},
					enableMouse = {
						order = 12, type = "toggle", name = "Select from frame.",
						get = GetPF, set = SetPF,
					},
					
					-- preset frame Settings
					presetFrameLayout = {
						order = 40, type = "group", name = "Frame Layout",
						args = {
							expandDown = {
								order = 20, type = "toggle", width = "full", name = "Expand Down",
								get = GetPF, set = SetPF,
							},
							backdropColor = {
								order = 30, type = "color", hasAlpha = true, name = "Backdrop Color",
								get = GetPF_Color, set = SetPF_Color,
							},
							backdropBorderColor = {
								order = 31, type = "color", hasAlpha = true, name = "Backdrop Border Color",
								get = function(info) return unpack(db.presetFrame.backdropBorderColor) end,
								get = GetPF_Color, set = SetPF_Color,
							},
							fontSize = {
								order = 40, type = "range", min = 1, max = 30, step = 1, name = "Font Size", 
								get = GetPF, set = SetPF,
							},
							fontColor = {
								order = 41, type = "color", hasAlpha = true, name = "Font Color", 
								get = GetPF_Color, set = SetPF_Color,
							},
							point = {
								order = 50, type = "select", name = "Point", values = clcInfo_Options.anchorPoints,
								get = GetPF, set = SetPF,
							},
							relativePoint = {
								order = 51, type = "select", name = "Relative Point", values = mod.anchorPoints,
								get = GetPF, set = SetPF,
							},
							x = {
								order = 60, type = "range", min = -2000, max = 2000, step = 1, name = "X",
								get = GetPF, set = SetPF,
							},
							y = {
								order = 61, type = "range", min = -1000, max = 1000, step = 1, name = "Y",
								get = GetPF, set = SetPF,
							},
							width = {
								order = 70, type = "range", min = 1, max = 2000, step = 1, name = "Width",
								get = GetPF, set = SetPF,
							},
							height = {
								order = 71, type = "range", min = 1, max = 1000, step = 1, name = "Height",
								get = GetPF, set = SetPF,
							},
						},
					},
				},
			},
		},
	}
	
	-- fcfs buttons
	local args = options.args.classModules.args.retribution.args.tabFCFS.args
	for i = 1, MAX_FCFS do
		args["label" .. i] = {
			order = i*2, type = "description", name = "", width = "double",
		}
		args[tostring(i)] = {
			order = i*2 - 1, type = "select", name = tostring(i), 
			get = GetFCFS, set = SetFCFS, values = GetSpellChoice,
		}
	end
	
	-- options for each preset
	local args = options.args.classModules.args.retribution.args.tabPresets.args
	for i = 1, MAX_PRESETS do
		args[tostring(i)] = {
			order = 50 + i, type = "group", name = "Preset " .. i, args = {
				name = {
					order = 1, type = "input", name = "Name",
					get = GetP, set = SetP,
				},
				data = {
					order = 2, type = "input", name = "Rotation",
					get = GetP, set = SetP,
				},
				load = {
					order = 3, width = "half", type = "execute", name = "Load",
					func = LoadP
				},
				save = {
					order = 4, width = "half", type = "execute", name = "Import",
					func = SaveP
				},
			},
		}
	end
	
end
mod.cmLoaders[#(mod.cmLoaders) + 1] = LoadModule