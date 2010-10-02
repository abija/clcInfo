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
	obj:UpdateLayout()
end
local function Get(info)
	return modGrids.active[tonumber(info[3])].db[info[6]]
end

-- general skin functions
-- info: activeTemplate grids 1 tabSkins micons selectType skinType

local function SetSkin(info, val)
	local obj = modGrids.active[tonumber(info[3])]
	obj.db.skinOptions[info[5]][info[7]] = val
	obj:UpdateLayout() 
end
local function GetSkin(info)
	return modGrids.active[tonumber(info[3])].db.skinOptions[info[5]][info[7]]
end
local function SetSkinColor(info, r, g, b, a)
	local obj = modGrids.active[tonumber(info[3])]
	obj.db.skinOptions[info[5]][info[7]] = { r, g, b, a }
	obj:UpdateLayout()
end
local function GetSkinColor(info)
	return unpack(modGrids.active[tonumber(info[3])].db.skinOptions[info[5]][info[7]])
end

local function SetLocked(info, val)
	local obj = modGrids.active[tonumber(info[3])]
	obj.db.cellWidth = val
	obj.db.cellHeight = val
	obj:UpdateLayout()
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
	clcInfo.display.icons:Add(tonumber(info[3]))
	mod:UpdateIconList()
end

local function AddMIcon(info)
	clcInfo.display.micons:Add(tonumber(info[3]))
	mod:UpdateMIconList()
end

local function AddBar(info)
	clcInfo.display.bars:Add(tonumber(info[3]))
	mod:UpdateBarList()
end

local function AddMBar(info)
	clcInfo.display.mbars:Add(tonumber(info[3]))
	mod:UpdateMBarList()
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
								addMIcon = { order = 3, type = "execute", name = "Add Multi Icon", func = AddMIcon },
								addMBar = { order = 4, type = "execute", name = "Add Multi Bar", func = AddMBar },
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
									order = 3, name = "Horizontal", type = "range", min = -10, max = 50, step = 1,
									get = Get, set = Set,
								},
								spacingY = {
									order = 4, name = "Vertical", type = "range", min = -10, max = 50, step = 1,
									get = Get, set = Set,
								},
							},
						},
					},
				},
				
				tabSkins = {
					order = 3, type = "group", name = "Skins", childGroups = "tab",
					args = {
						icons = {
							order = 3, type = "group", name = "Icons",
							args = {
								selectType = {
									order = 1, type = "group", inline = true, name = "Skin Type",
									args = {
										skinType = {
											order = 1, type = "select", name = "Skin type", values = GetSkinTypeList,
											get = GetSkin, set = SetSkin,
										},
									},
								},
							}
						},
						
						micons = {
							order = 4, type = "group", name = "Multi Icons",
							args = {
								selectType = {
									order = 1, type = "group", inline = true, name = "Skin Type",
									args = {
										skinType = {
											order = 1, type = "select", name = "Skin type", values = GetSkinTypeList,
											get = GetSkin, set = SetSkin,
										},
									},
								},
							}
						},
						
						bars = {
							order = 5, type = "group", name = "Bars",
							args = {
								hasBg = {
									order = 1, type = "group", inline = true, name = "",
									args = {
										barBg = {
											type = "toggle", width = "full", name = "Use background texture.",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								barColors = {
									order = 2, type = "group", inline = true, name = "Bar Colors",
									args = {
											barColor = {
												order = 1, type = "color", hasAlpha = true, name = "Bar",
												get = GetSkinColor, set = SetSkinColor,
											},
											__f1 = {
												order = 2, type = "description", width = "half", name = "",
											},
											barBgColor = {
												order = 3, type = "color", hasAlpha = true, name = "Background",
												get = GetSkinColor, set = SetSkinColor,
											},
									},
								},
								barTextures = {
									order = 3, type = "group", inline = true, name = "Bar Textures",
									args = {
										barTexture = {
											order = 1, type = 'select', dialogControl = 'LSM30_Statusbar', name = 'Bar',
											values = LSM:HashTable("statusbar"), get = GetSkin, set = SetSkin,
										},
										__f1 = {
											order = 2, type = "description", width = "half", name = "",
										},
										barBgTexture = {
											order = 3, type = 'select', dialogControl = 'LSM30_Statusbar', name = 'Background',
											values = LSM:HashTable("statusbar"), get = GetSkin, set = SetSkin,
										},
									},
								},
								
								
								
								advanced = {
									order = 5, type = "group", inline = true, name = "",
									args = {
										advancedSkin = {
											type = "toggle", width = "full", name = "Use advanced options",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								iconpos = {
									order = 7, type = "group", inline = true, name = "Icon Position",
									args = {
										iconAlign = {
											order = 1, type = "select", name = "Icon Alignment",
											values = { ["left"] = "Left", ["right"] = "Right", ["hidden"] = "hidden" },
											get = GetSkin, set = SetSkin,
										},
										iconSpacing = {
											order = 2, type = "range", min = -100, max = 100, step = 1, name = "Icon Spacing",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								fontLeft = {
									order = 8, type = "group", inline = true, name = "Left Text",
									args = {
										textLeftFont = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
											values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										textLeftPadding = {
											order = 2, type = "range", min = -100, max = 100, step = 1, name = "Text Padding",
											get = GetSkin, set = SetSkin,
										},
										textLeftSize = {
											order = 3, type = "range", min = 1, max = 100, step = 1, name = "Text Size",
											get = GetSkin, set = SetSkin,
										},
										textLeftColor = {
											order = 4, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								fontCenter = {
									order = 8, type = "group", inline = true, name = "Center Text",
									args = {
										textCenterFont = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
											values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										textCenterSize = {
											order = 3, type = "range", min = 1, max = 100, step = 1, name = "Text Size",
											get = GetSkin, set = SetSkin,
										},
										textCenterColor = {
											order = 4, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								fontRight = {
									order = 9, type = "group", inline = true, name = "Right Text",
									args = {
										textRightFont = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
											values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										textRightPadding = {
											order = 2, type = "range", min = -100, max = 100, step = 1, name = "Text Padding",
											get = GetSkin, set = SetSkin,
										},
										textRightSize = {
											order = 3, type = "range", min = 1, max = 100, step = 1, name = "Text Size",
											get = GetSkin, set = SetSkin,
										},
										textRightColor = {
											order = 4, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								bothbd = {
									order = 21, type = "group", inline = true, name = "Frame Backdrop",
									args = {
										bd = {
											order = 1, type = "toggle", width = "full", name = "Enable",
											get = GetSkin, set = SetSkin,
										},
										inset = {
											order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
											get = GetSkin, set = SetSkin,
										},
										padding = {
											order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
											get = GetSkin, set = SetSkin,
										},
										edgeSize = {
											order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
											get = GetSkin, set = SetSkin,
										},
										_bg = {
											order = 10, type = "header", name = "Background",
										},
										bdBg = {
											order = 11, type = 'select', dialogControl = 'LSM30_Background', name = 'Texture',
											values = LSM:HashTable("background"), get = GetSkin, set = SetSkin,
										},
										__f1 = {
											order = 12, type = "description", width = "half", name = "",
										},
										bdColor = {
											order = 13, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
										_border = {
											order = 20, type = "header", name = "Border",
										},
										bdBorder = {
											order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
											values = LSM:HashTable("border"), get = GetSkin, set = SetSkin,
										},
										__f2 = {
											order = 22, type = "description", width = "half", name = "",
										},
										bdBorderColor = {
											order = 23, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								iconbd = {
									order = 22, type = "group", inline = true, name = "Icon Backdrop",
									args = {
										iconBd = {
											order = 1, type = "toggle", width = "full", name = "Enable",
											get = GetSkin, set = SetSkin,
										},
										iconInset = {
											order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
											get = GetSkin, set = SetSkin,
										},
										iconPadding = {
											order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
											get = GetSkin, set = SetSkin,
										},
										iconEdgeSize = {
											order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
											get = GetSkin, set = SetSkin,
										},
										_bg = {
											order = 10, type = "header", name = "Background",
										},
										iconBdBg = {
											order = 11, type = 'select', dialogControl = 'LSM30_Background', name = 'Texture',
											values = LSM:HashTable("background"), get = GetSkin, set = SetSkin,
										},
										__f1 = {
											order = 12, type = "description", width = "half", name = "",
										},
										iconBdColor = {
											order = 13, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
										_border = {
											order = 20, type = "header", name = "Border",
										},
										iconBdBorder = {
											order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
											values = LSM:HashTable("border"), get = GetSkin, set = SetSkin,
										},
										__f2 = {
											order = 22, type = "description", width = "half", name = "",
										},
										iconBdBorderColor = {
											order = 23, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								barbd = {
									order = 23, type = "group", inline = true, name = "Bar Backdrop",
									args = {
										barBd = {
											order = 1, type = "toggle", width = "full", name = "Enable",
											get = GetSkin, set = SetSkin,
										},
										barInset = {
											order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
											get = GetSkin, set = SetSkin,
										},
										barPadding = {
											order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
											get = GetSkin, set = SetSkin,
										},
										barEdgeSize = {
											order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
											get = GetSkin, set = SetSkin,
										},
										_border = {
											order = 20, type = "header", name = "Border",
										},
										barBdBorder = {
											order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
											values = LSM:HashTable("border"), get = GetSkin, set = SetSkin,
										},
										__f2 = {
											order = 22, type = "description", width = "half", name = "",
										},
										barBdBorderColor = {
											order = 23, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
							},
						},
						
						mbars = {
							order = 6, type = "group", name = "Multi Bars",
							args = {
								hasBg = {
									order = 1, type = "group", inline = true, name = "",
									args = {
										barBg = {
											type = "toggle", width = "full", name = "Use background texture.",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								barColors = {
									order = 2, type = "group", inline = true, name = "Bar Colors",
									args = {
											barColor = {
												order = 1, type = "color", hasAlpha = true, name = "Bar",
												get = GetSkinColor, set = SetSkinColor,
											},
											__f1 = {
												order = 2, type = "description", width = "half", name = "",
											},
											barBgColor = {
												order = 3, type = "color", hasAlpha = true, name = "Background",
												get = GetSkinColor, set = SetSkinColor,
											},
									},
								},
								barTextures = {
									order = 3, type = "group", inline = true, name = "MBar Textures",
									args = {
										barTexture = {
											order = 1, type = 'select', dialogControl = 'LSM30_Statusbar', name = 'Bar',
											values = LSM:HashTable("statusbar"), get = GetSkin, set = SetSkin,
										},
										__f1 = {
											order = 2, type = "description", width = "half", name = "",
										},
										barBgTexture = {
											order = 3, type = 'select', dialogControl = 'LSM30_Statusbar', name = 'Background',
											values = LSM:HashTable("statusbar"), get = GetSkin, set = SetSkin,
										},
									},
								},
								
								
								
								advanced = {
									order = 5, type = "group", inline = true, name = "",
									args = {
										advancedSkin = {
											type = "toggle", width = "full", name = "Use advanced options",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								iconpos = {
									order = 7, type = "group", inline = true, name = "Icon Position",
									args = {
										iconAlign = {
											order = 1, type = "select", name = "Icon Alignment",
											values = { ["left"] = "Left", ["right"] = "Right", ["hidden"] = "hidden" },
											get = GetSkin, set = SetSkin,
										},
										iconSpacing = {
											order = 2, type = "range", min = -100, max = 100, step = 1, name = "Icon Spacing",
											get = GetSkin, set = SetSkin,
										},
									},
								},
								
								fontLeft = {
									order = 8, type = "group", inline = true, name = "Left Text",
									args = {
										textLeftFont = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
											values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										textLeftPadding = {
											order = 2, type = "range", min = -100, max = 100, step = 1, name = "Text Padding",
											get = GetSkin, set = SetSkin,
										},
										textLeftSize = {
											order = 3, type = "range", min = 1, max = 100, step = 1, name = "Text Size",
											get = GetSkin, set = SetSkin,
										},
										textLeftColor = {
											order = 4, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								fontCenter = {
									order = 8, type = "group", inline = true, name = "Center Text",
									args = {
										textCenterFont = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
											values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										textCenterSize = {
											order = 3, type = "range", min = 1, max = 100, step = 1, name = "Text Size",
											get = GetSkin, set = SetSkin,
										},
										textCenterColor = {
											order = 4, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								fontRight = {
									order = 9, type = "group", inline = true, name = "Right Text",
									args = {
										textRightFont = {
											order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font',
											values = LSM:HashTable("font"),
											get = GetSkin, set = SetSkin,
										},
										textRightPadding = {
											order = 2, type = "range", min = -100, max = 100, step = 1, name = "Text Padding",
											get = GetSkin, set = SetSkin,
										},
										textRightSize = {
											order = 3, type = "range", min = 1, max = 100, step = 1, name = "Text Size",
											get = GetSkin, set = SetSkin,
										},
										textRightColor = {
											order = 4, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								bothbd = {
									order = 21, type = "group", inline = true, name = "Frame Backdrop",
									args = {
										bd = {
											order = 1, type = "toggle", width = "full", name = "Enable",
											get = GetSkin, set = SetSkin,
										},
										inset = {
											order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
											get = GetSkin, set = SetSkin,
										},
										padding = {
											order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
											get = GetSkin, set = SetSkin,
										},
										edgeSize = {
											order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
											get = GetSkin, set = SetSkin,
										},
										_bg = {
											order = 10, type = "header", name = "Background",
										},
										bdBg = {
											order = 11, type = 'select', dialogControl = 'LSM30_Background', name = 'Texture',
											values = LSM:HashTable("background"), get = GetSkin, set = SetSkin,
										},
										__f1 = {
											order = 12, type = "description", width = "half", name = "",
										},
										bdColor = {
											order = 13, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
										_border = {
											order = 20, type = "header", name = "Border",
										},
										bdBorder = {
											order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
											values = LSM:HashTable("border"), get = GetSkin, set = SetSkin,
										},
										__f2 = {
											order = 22, type = "description", width = "half", name = "",
										},
										bdBorderColor = {
											order = 23, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								iconbd = {
									order = 22, type = "group", inline = true, name = "Icon Backdrop",
									args = {
										iconBd = {
											order = 1, type = "toggle", width = "full", name = "Enable",
											get = GetSkin, set = SetSkin,
										},
										iconInset = {
											order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
											get = GetSkin, set = SetSkin,
										},
										iconPadding = {
											order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
											get = GetSkin, set = SetSkin,
										},
										iconEdgeSize = {
											order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
											get = GetSkin, set = SetSkin,
										},
										_bg = {
											order = 10, type = "header", name = "Background",
										},
										iconBdBg = {
											order = 11, type = 'select', dialogControl = 'LSM30_Background', name = 'Texture',
											values = LSM:HashTable("background"), get = GetSkin, set = SetSkin,
										},
										__f1 = {
											order = 12, type = "description", width = "half", name = "",
										},
										iconBdColor = {
											order = 13, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
										_border = {
											order = 20, type = "header", name = "Border",
										},
										iconBdBorder = {
											order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
											values = LSM:HashTable("border"), get = GetSkin, set = SetSkin,
										},
										__f2 = {
											order = 22, type = "description", width = "half", name = "",
										},
										iconBdBorderColor = {
											order = 23, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
								},
								
								barbd = {
									order = 23, type = "group", inline = true, name = "Bar Backdrop",
									args = {
										barBd = {
											order = 1, type = "toggle", width = "full", name = "Enable",
											get = GetSkin, set = SetSkin,
										},
										barInset = {
											order = 2, type = "range", min = 0, max = 20, step = 0.1, name = "Inset",
											get = GetSkin, set = SetSkin,
										},
										barPadding = {
											order = 3, type = "range", min = 0, max = 20, step = 0.1, name = "Padding",
											get = GetSkin, set = SetSkin,
										},
										barEdgeSize = {
											order = 4, type = "range", min = 0, max = 64, step = 1, name = "Edge",
											get = GetSkin, set = SetSkin,
										},
										_border = {
											order = 20, type = "header", name = "Border",
										},
										barBdBorder = {
											order = 21, type = 'select', dialogControl = 'LSM30_Border', name = 'Texture',
											values = LSM:HashTable("border"), get = GetSkin, set = SetSkin,
										},
										__f2 = {
											order = 22, type = "description", width = "half", name = "",
										},
										barBdBorderColor = {
											order = 23, type = "color", hasAlpha = true, name = "Color",
											get = GetSkinColor, set = SetSkinColor,
										},
									},
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
	  	optionsGrids.args[tostring(i)].args.tabSkins.args.icons.args.bfOptions = {
	  		order = 2, type = "group", inline = true, name = "Button Facade Options",
	  		args = {
	  			bfSkin = {
	  				order = 1, type = "select", name = "Button Facade Skin", values = clcInfo.lbf.ListSkins,
	  				get = GetSkin, set = SetSkin,
	  			},
	  			bfGloss = {
	  				order = 1, type = "range", name = "Gloss", step = 1, min = 0, max = 100,
	  				get = GetSkin, set = SetSkin,
	  			},
	  		}
	  	}
	  	optionsGrids.args[tostring(i)].args.tabSkins.args.micons.args.bfOptions = {
	  		order = 2, type = "group", inline = true, name = "Button Facade Options",
	  		args = {
	  			bfSkin = {
	  				order = 1, type = "select", name = "Button Facade Skin", values = clcInfo.lbf.ListSkins,
	  				get = GetSkin, set = SetSkin,
	  			},
	  			bfGloss = {
	  				order = 1, type = "range", name = "Gloss", step = 1, min = 0, max = 100,
	  				get = GetSkin, set = SetSkin,
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