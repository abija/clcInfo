local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo_Options\\grids> " .. table.concat(t, " "))
end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local modGrids = clcInfo.display.grids

local LSM = clcInfo.LSM

-- static popup to make sure
local deleteObj = nil
StaticPopupDialogs["CLCINFO_CONFIRM_DELETE_GRID"] = {
	text = "Are you sure you want to delete this grid?",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not deleteObj then return end
		deleteObj:Delete()
		mod:UpdateGridList()
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

-- info:
-- 	1 activeTemplate
-- 	2 grids
--	3 i
--	4 deleteTab
--	5 executeDelete
local function DeleteGrid(info)
	local i = tonumber(info[3])
	deleteObj = modGrids.active[i]
	StaticPopup_Show("CLCINFO_CONFIRM_DELETE_GRID")
end

-- info:
-- 	1 activeTemplate
-- 	2 grids
--	3 i
--	4 tabLayout
--	5 size, position, ... = group names
-- 	6 width, height, ...	= var names
local function Set(info, val)
	local obj = modGrids.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:Update()
end
local function Get(info)
	return modGrids.active[tonumber(info[3])].db[info[6]]
end

--------------------------------------------------------------------------------
local function SetSkinIcons(info, val)
	local obj = modGrids.active[tonumber(info[3])]
	obj.db.skinOptions.icons[info[6]] = val
	obj:Update()
end
local function GetSkinIcons(info)
	return modGrids.active[tonumber(info[3])].db.skinOptions.icons[info[6]]
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- skin bars get and set
local function SetSkinBars(info, val)
	local obj = modGrids.active[tonumber(info[3])]
	obj.db.skinOptions.bars[info[6]] = val
	obj:Update()
end
local function GetSkinBars(info)
	return modGrids.active[tonumber(info[3])].db.skinOptions.bars[info[6]]
end
-- color ones
local function SetSkinBarsColor(info, r, g, b, a)
	local obj = modGrids.active[tonumber(info[3])]
	obj.db.skinOptions.bars[info[6]] = { r, g, b, a }
	obj:Update()
end
local function GetSkinBarsColor(info)
	return unpack(modGrids.active[tonumber(info[3])].db.skinOptions.bars[info[6]])
end
--------------------------------------------------------------------------------


local function SetLocked(info, val)
	local obj = modGrids.active[tonumber(info[3])]
	obj.db.cellWidth = val
	obj.db.cellHeight = val
	obj:Update()
end
local function GetLocked(info)
	return modGrids.active[tonumber(info[3])].db.cellWidth
end

local function Lock(info)
	modGrids.active[tonumber(info[3])]:Lock()
end

local function Unlock(info)
	modGrids.active[tonumber(info[3])]:Unlock()
end

local function AddIcon(info)
	clcInfo.display.icons:AddIcon(tonumber(info[3]))
	mod:UpdateIconList()
end

local function AddBar(info)
	clcInfo.display.bars:AddBar(tonumber(info[3]))
	mod:UpdateBarList()
end

local function GetSkinTypeList()
	local list = { ["Default"] = "Default", ["BareBone"] = "BareBone" }
	if clcInfo.lbf then list["Button Facade"] = "Button Facade" end
	return list
end

function mod:UpdateGridList()
	local db = modGrids.active
	local optionsGrids = options.args.activeTemplate.args.grids
	
	for i = 1, #db do
		optionsGrids.args[tostring(i)] = {
			type = "group", childGroups = "tab", name = "Grid" .. i,
			args = {
				tabGeneral = {
					order = 1, type = "group", name = "General",
					args = {
						add = {
							order = 1, type = "group", inline = true, name = "Add Elements", args = {
								addIcon = { order = 1, type = "execute", name = "Add Icon", func = AddIcon },
								addBar = { order = 2, type = "execute", name = "Add Bar", func = AddBar },
				  		}
						},
						lock = {
							order = 2, type = "group", inline = true, name = "Lock",
							args = {
								lock = {
				  				order = 1, type = "execute", name = "Lock", func = Lock
				  			},
				  			unlock = {
				  				order = 2, type = "execute", name = "Unlock", func = Unlock,
				  			},
							},
						},
					},
				},
			
				-- layout options
				tabLayout = {
					order = 2, type = "group", name = "Layout",
					args = {
						position = {
							order = 3, type = "group", inline = true, name = "Position",
							args = {
								x = {
									order = 1, name = "X", type = "range", min = -2000, max = 2000, step = 1,
									get = Get, set = Set,
								},
								y = {
									order = 2, name = "Y", type = "range", min = -1000, max = 1000, step = 1,
									get = Get, set = Set,
								},
							},
						},
							
						cellSize = {
							order = 4, type = "group", inline = true, name = "Cell Size",
							args = {
								cellWidth = {
									order = 1, name = "Cell Width", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
								cellHeight = {
									order = 2, name = "Cell Height", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
								WandH = {
									order = 3, name = "Width and Height", type = "range", min = 1, max = 200, step = 1,
									get = GetLocked, set = SetLocked,
								},
							},
						},
							
						cellNum = {
							order = 5, type = "group", inline = true, name = "Number of cells",
							args = {
								cellsX = {
									order = 1, name = "Columns", type = "range", min = 1, max = 50, step = 1,
									get = Get, set = Set,
								},
								cellsY = {
									order = 2, name = "Rows", type = "range", min = 1, max = 50, step = 1,
									get = Get, set = Set,
								},
							},
						},
						spacing = {
							order = 6, type = "group", inline = true, name = "Spacing",
							args = {
								spacingX = {
									order = 3, name = "Horizontal", type = "range", min = 1, max = 50, step = 1,
									get = Get, set = Set,
								},
								spacingY = {
									order = 4, name = "Vertical", type = "range", min = 1, max = 50, step = 1,
									get = Get, set = Set,
								},
							},
						},
					},
				},
				
				tabSkinIcons = {
					order = 3, type = "group", name = "Skin Icons",
					args = {
						selectType = {
							order = 1, type = "group", inline = true, name = "Skin Type",
							args = {
								skinType = {
									order = 1, type = "select", name = "Skin type", values = GetSkinTypeList,
									get = GetSkinIcons, set = SetSkinIcons,
								},
							},
						},
					}
				},
				
				tabSkinBars = {
					order = 4, type = "group", name = "Skin Bars",
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
				
				deleteTab = {
					order = 100, type = "group", name = "Delete",
					args = {
						-- delete button
						executeDelete = {
							type = "execute", name = "Delete",
							func = DeleteGrid,
						},
					},
				},
			},
		}
	end
	
	-- if we have lbf then add it to options
  if clcInfo.lbf then
  	for i = 1, #db do
	  	optionsGrids.args[tostring(i)].args.tabSkinIcons.args.bfOptions = {
	  		order = 2, type = "group", inline = true, name = "Button Facade Options",
	  		args = {
	  			bfSkin = {
	  				order = 1, type = "select", name = "Button Facade Skin", values = clcInfo.lbf.ListSkins,
	  				get = GetSkinIcons, set = SetSkinIcons,
	  			},
	  			bfGloss = {
	  				order = 1, type = "range", name = "Gloss", step = 1, min = 0, max = 100,
	  				get = GetSkinIcons, set = SetSkinIcons,
	  			},
	  		}
	  	}
	  end
  end
	
	if mod.lastGridCount > #(db) then
		-- nil the rest of the args
		for i = #db + 1, mod.lastGridCount do
			optionsGrids.args[tostring(i)] = nil
		end
	end
	mod.lastGridCount = #db
	
	AceRegistry:NotifyChange("clcInfo")
end