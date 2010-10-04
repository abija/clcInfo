-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local LSM = clcInfo.LSM

local modBars = clcInfo.display.bars

-- static popup to make sure
local deleteObj = nil
StaticPopupDialogs["CLCINFO_CONFIRM_DELETE_BAR"] = {
	text = "Are you sure you want to delete this bar?",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not deleteObj then return end
		deleteObj:Delete()
		mod:UpdateBarList()
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

-- info:
-- 	1 activeTemplate
-- 	2 bars
--	3 i
--	4 deleteTab
--	5 executeDelete
local function DeleteBar(info)
	local i = tonumber(info[3])
	deleteObj = modBars.active[i]
	StaticPopup_Show("CLCINFO_CONFIRM_DELETE_BAR")
end

-- info:
-- 	1 activeTemplate
-- 	2 bars
--	3 i
--	4 tabLayout
--	5 size, position, ... = group names
-- 	6 width, height, ...	= var names
local function Set(info, val)
	local obj = modBars.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:UpdateLayout()
end
local function Get(info)
	return modBars.active[tonumber(info[3])].db[info[6]]
end
-- color ones
local function SetColor(info, r, g, b, a)
	local obj = modBars.active[tonumber(info[3])]
	obj.db[info[6]] = { r, g, b, a } 
	obj:UpdateLayout()
end
local function GetColor(info)
	return unpack(modBars.active[tonumber(info[3])].db[info[6]])
end


-- skin get and set
local function SetSkinBars(info, val)
	local obj = modBars.active[tonumber(info[3])]
	obj.db.skin[info[6]] = val
	obj:UpdateLayout()
end
local function GetSkinBars(info)
	return modBars.active[tonumber(info[3])].db.skin[info[6]]
end
-- color ones
local function SetSkinBarsColor(info, r, g, b, a)
	local obj = modBars.active[tonumber(info[3])]
	obj.db.skin[info[6]] = { r, g, b, a }
	obj:UpdateLayout()
end
local function GetSkinBarsColor(info)
	return unpack(modBars.active[tonumber(info[3])].db.skin[info[6]])
end

local function Lock(info)
	modBars.active[tonumber(info[3])]:Lock()
end

local function Unlock(info)
	modBars.active[tonumber(info[3])]:Unlock()
end

local function SetExec(info, val)
	local obj = modBars.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:UpdateExec()
end

local function GetGridList()
	local list = { [0] = "None" }
	for i = 1, #(clcInfo.display.grids.active) do
		list[i] = "Grid" .. i
	end
	return list
end


-- sound donothing control
local sound = "None"
local function GetSound() return sound end
local function SetSound(info, val) sound = val end

function mod:UpdateBarList()
	local db = modBars.active
	local optionsBars = options.args.activeTemplate.args.bars
	
	for i = 1, #db do
		optionsBars.args[tostring(i)] = {
			type = "group",
			name = "Bar" .. i,
			order = i,
			childGroups = "tab",
			args = {
				tabGeneral = {
					order = 1, type = "group", name = "General",
					args = {
						lock = {
							order = 1, type = "group", inline = true, name = "",
							args = {
								lock = {
				  				type = "execute", name = "Lock", func = Lock
				  			},
				  			unlock = {
				  				type = "execute", name = "Unlock", func = Unlock,
				  			},
							},
						},
						grid = {
							order = 2, type = "group", inline = true, name = "",
							args = {
								gridId = {
									order = 1, type = "select", name = "Select Grid", values = GetGridList,
									get = Get, set = Set, 
								},
								skinSource = {
									order = 2, type = "select", name = "Use skin from",
									values = { Self = "Self", Template = "Template", Grid = "Grid" },
									get = Get, set = Set, 
								},
							},
						},
						ownColors = {
							order = 3, type = "group", inline = true, name = "Colors",
							args = {
								ownColors = {
									order = 1, type = "toggle", width = "full", name = "Force own colors.",
									get = Get, set = Set,
								},
								barColor = {
										order = 2, type = "color", hasAlpha = true, name = "Bar",
										get = GetSkinBarsColor, set = SetSkinBarsColor,
									},
								barBgColor = {
									order = 3, type = "color", hasAlpha = true, name = "Background",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
							},
						},
					},
				},
			
				-- grid options
				tabGrid = {
					order = 2, type = "group", name = "Grid",
					args = {
						grid = {
							order = 1,  type = "group", inline = true, name = "",
							args = {
								gridId = {
									order = 1, type = "select", name = "Select Grid", values = GetGridList,
									get = Get, set = Set, 
								},
								gridX = {
									order = 2, name = "Column", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
								gridY = {
									order = 3, name = "Row", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
								sizeX = {
									order = 4, name = "Width", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
								sizeY = {
									order = 5, name = "Height", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
							},
						},
					},
				},
			
				-- layout options
				tabLayout = {
					order = 3, type = "group", name = "Layout", args = {
						__dGrid = {
							order = 1, type = "description",
							name = "If a grid is selected, none of the following options have any real effect.\n",
						},
					
						position = {
							order = 101, type = "group", inline = true, name = "Position ( [0, 0] is bottom left corner )",
							args = {
								x = {
									order = 1, name = "X", type = "range", min = 0, max = 4000, step = 1,
									get = Get, set = Set,
								},
								y = {
									order = 2, name = "Y", type = "range", min = 0, max = 2000, step = 1,
									get = Get, set = Set,
								},
							},
						},
							
						size = {
							order = 102, type = "group", inline = true, name = "Size",
							args = {
								width = {
									order = 1, type = "range", min = 1, max = 1000, step = 1, name = "Width",
									get = Get, set = Set,
								},
								height = {
									order = 2, type = "range", min = 1, max = 500, step = 1, name = "Height", 
									get = Get, set = Set,
								},
							},
						},
					},
				},
				
				-- tab skin here
				tabSkin = {
					order = 4, type = "group", name = "Skin",
					args = {
						hasBg = {
							order = 1, type = "group", inline = true, name = "",
							args = {
								barBg = {
									type = "toggle", width = "full", name = "Use background texture.",
									get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						barColors = {
							order = 2, type = "group", inline = true, name = "Bar Colors",
							args = {
									barColor = {
										order = 1, type = "color", hasAlpha = true, name = "Bar",
										get = GetSkinBarsColor, set = SetSkinBarsColor,
									},
									__f1 = {
										order = 2, type = "description", width = "half", name = "",
									},
									barBgColor = {
										order = 3, type = "color", hasAlpha = true, name = "Background",
										get = GetSkinBarsColor, set = SetSkinBarsColor,
									},
							},
						},
						barTextures = {
							order = 3, type = "group", inline = true, name = "Bar Textures",
							args = {
								barTexture = {
									order = 1, type = 'select', dialogControl = 'LSM30_Statusbar', name = 'Bar',
									values = LSM:HashTable("statusbar"), get = GetSkinBars, set = SetSkinBars,
								},
								__f1 = {
									order = 2, type = "description", width = "half", name = "",
								},
								barBgTexture = {
									order = 3, type = 'select', dialogControl = 'LSM30_Statusbar', name = 'Background',
									values = LSM:HashTable("statusbar"), get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						
						
						
						advanced = {
							order = 5, type = "group", inline = true, name = "",
							args = {
								advancedSkin = {
									type = "toggle", width = "full", name = "Use advanced options",
									get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						
						iconpos = {
							order = 7, type = "group", inline = true, name = "Icon Position",
							args = {
								iconAlign = {
									order = 1, type = "select", name = "Icon Alignment",
									values = { ["left"] = "Left", ["right"] = "Right", ["hidden"] = "hidden" },
									get = GetSkinBars, set = SetSkinBars,
								},
								iconSpacing = {
									order = 2, type = "range", min = -100, max = 100, step = 1, name = "Icon Spacing",
									get = GetSkinBars, set = SetSkinBars,
								},
							},
						},
						
						fontLeft = {
							order = 8, type = "group", inline = true, name = "Left Text",
							args = {
								textLeftFont = {
									order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
									values = LSM:HashTable("font"),
									get = GetSkinBars, set = SetSkinBars,
								},
								textLeftPadding = {
									order = 2, type = "range", min = -100, max = 100, step = 1, name = "Text Padding",
									get = GetSkinBars, set = SetSkinBars,
								},
								textLeftSize = {
									order = 3, type = "range", min = 1, max = 100, step = 1, name = "Text Size",
									get = GetSkinBars, set = SetSkinBars,
								},
								textLeftColor = {
									order = 4, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
							},
						},
						
						fontCenter = {
							order = 8, type = "group", inline = true, name = "Center Text",
							args = {
								textCenterFont = {
									order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
									values = LSM:HashTable("font"),
									get = GetSkinBars, set = SetSkinBars,
								},
								textCenterSize = {
									order = 3, type = "range", min = 1, max = 100, step = 1, name = "Text Size",
									get = GetSkinBars, set = SetSkinBars,
								},
								textCenterColor = {
									order = 4, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
							},
						},
						
						fontRight = {
							order = 9, type = "group", inline = true, name = "Right Text",
							args = {
								textRightFont = {
									order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
									values = LSM:HashTable("font"),
									get = GetSkinBars, set = SetSkinBars,
								},
								textRightPadding = {
									order = 2, type = "range", min = -100, max = 100, step = 1, name = "Text Padding",
									get = GetSkinBars, set = SetSkinBars,
								},
								textRightSize = {
									order = 3, type = "range", min = 1, max = 100, step = 1, name = "Text Size",
									get = GetSkinBars, set = SetSkinBars,
								},
								textRightColor = {
									order = 4, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
							},
						},
						
						bothbd = {
							order = 21, type = "group", inline = true, name = "Frame Backdrop",
							args = {
								bd = {
									order = 1, type = "toggle", width = "full", name = "Enable",
									get = GetSkinBars, set = SetSkinBars,
								},
								inset = {
									order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
									get = GetSkinBars, set = SetSkinBars,
								},
								padding = {
									order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
									get = GetSkinBars, set = SetSkinBars,
								},
								edgeSize = {
									order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
									get = GetSkinBars, set = SetSkinBars,
								},
								_bg = {
									order = 10, type = "header", name = "Background",
								},
								bdBg = {
									order = 11, type = 'select', dialogControl = 'LSM30_Background', name = 'Texture',
									values = LSM:HashTable("background"), get = GetSkinBars, set = SetSkinBars,
								},
								__f1 = {
									order = 12, type = "description", width = "half", name = "",
								},
								bdColor = {
									order = 13, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
								_border = {
									order = 20, type = "header", name = "Border",
								},
								bdBorder = {
									order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
									values = LSM:HashTable("border"), get = GetSkinBars, set = SetSkinBars,
								},
								__f2 = {
									order = 22, type = "description", width = "half", name = "",
								},
								bdBorderColor = {
									order = 23, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
							},
						},
						
						iconbd = {
							order = 22, type = "group", inline = true, name = "Icon Backdrop",
							args = {
								iconBd = {
									order = 1, type = "toggle", width = "full", name = "Enable",
									get = GetSkinBars, set = SetSkinBars,
								},
								iconInset = {
									order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
									get = GetSkinBars, set = SetSkinBars,
								},
								iconPadding = {
									order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
									get = GetSkinBars, set = SetSkinBars,
								},
								iconEdgeSize = {
									order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
									get = GetSkinBars, set = SetSkinBars,
								},
								_bg = {
									order = 10, type = "header", name = "Background",
								},
								iconBdBg = {
									order = 11, type = 'select', dialogControl = 'LSM30_Background', name = 'Texture',
									values = LSM:HashTable("background"), get = GetSkinBars, set = SetSkinBars,
								},
								__f1 = {
									order = 12, type = "description", width = "half", name = "",
								},
								iconBdColor = {
									order = 13, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
								_border = {
									order = 20, type = "header", name = "Border",
								},
								iconBdBorder = {
									order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
									values = LSM:HashTable("border"), get = GetSkinBars, set = SetSkinBars,
								},
								__f2 = {
									order = 22, type = "description", width = "half", name = "",
								},
								iconBdBorderColor = {
									order = 23, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
							},
						},
						
						barbd = {
							order = 23, type = "group", inline = true, name = "Bar Backdrop",
							args = {
								barBd = {
									order = 1, type = "toggle", width = "full", name = "Enable",
									get = GetSkinBars, set = SetSkinBars,
								},
								barInset = {
									order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
									get = GetSkinBars, set = SetSkinBars,
								},
								barPadding = {
									order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
									get = GetSkinBars, set = SetSkinBars,
								},
								barEdgeSize = {
									order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
									get = GetSkinBars, set = SetSkinBars,
								},
								_border = {
									order = 20, type = "header", name = "Border",
								},
								barBdBorder = {
									order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
									values = LSM:HashTable("border"), get = GetSkinBars, set = SetSkinBars,
								},
								__f2 = {
									order = 22, type = "description", width = "half", name = "",
								},
								barBdBorderColor = {
									order = 23, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinBarsColor, set = SetSkinBarsColor,
								},
							},
						},
					},
				},
				
				
				-- behavior options
				tabBehavior = {
					order = 50, type = "group", name = "Behavior", 
					args = {
						code = {
							order = 1, type = "group", inline = true, name = "Code",
							args = {
								exec = {
									type = "input", multiline = true, name = "", width = "full",
									get = Get, set = SetExec,
								},
							},
						},
						ups = {
							order = 2, type = "group", inline = true, name = "Updates per second",
							args = {
								ups = {
									type = "range", min = 1, max = 100, step = 1, name = "", 
									get = Get, set = SetExec,
								},
							},
						},
						alerts = {
							order = 3, type = "group", inline = true, name = "Alerts",
							args = {
								execAlert = {
									order = 1, type = "input", multiline = true, name = "", width = "full",
									get = Get, set = SetExec,
								},
								_x1 = {
									order = 2, type = 'select', dialogControl = 'LSM30_Sound', name = 'List of available sounds',
									values = LSM:HashTable("sound"), get = GetSound, set = SetSound,
								},
							},
						},
					},
				},
				deleteTab = {
					order = 100, type = "group", name = "Delete", 
					args = {
						-- delete button
						executeDelete = {
							type = "execute", name = "Delete",
							func = DeleteBar,
						},
					},
				},
			},
		}
	end
	
	if mod.lastBarCount > #(db) then
		-- nil the rest of the args
		for i = #db + 1, mod.lastBarCount do
			optionsBars.args[tostring(i)] = nil
		end
	end
	mod.lastBarCount = #db
	
	AceRegistry:NotifyChange("clcInfo")
end