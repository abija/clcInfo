local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo_Options\\activeTemplate> " .. table.concat(t, " "))
end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local LSM = clcInfo.LSM
local db

--[[----------------------------------------------------------------------------
Add functions
--]]----------------------------------------------------------------------------
local function AddGrid()
	clcInfo.display.grids:AddGrid()
	mod:UpdateGridList()
end
local function AddIcon()
	clcInfo.display.icons:AddIcon()
	mod:UpdateIconList()
end
local function AddBar()
	clcInfo.display.bars:AddBar()
	mod.UpdateBarList()
end

--------------------------------------------------------------------------------

-- set/get for skin icons
-- info: activeTemplate skins icons selectType skinType
local function SetSkinIcons(info, val)
	db.skinOptions.icons[info[5]] = val
	clcInfo.display.templates:UpdateElementsLayout()
end
local function GetSkinIcons(info)
	return db.skinOptions.icons[info[5]]
end
local function GetSkinTypeList()
	local list = { ["Default"] = "Default", ["BareBone"] = "BareBone" }
	if clcInfo.lbf then list["Button Facade"] = "Button Facade" end
	return list
end

--------------------------------------------------------------------------------

-- skin get and set
local function SetSkinBars(info, val)
	db.skinOptions.bars[info[5]] = val
	clcInfo.display.templates:UpdateElementsLayout()
end
local function GetSkinBars(info)
	return db.skinOptions.bars[info[5]]
end
-- color ones
local function SetSkinBarsColor(info, r, g, b, a)
	db.skinOptions.bars[info[5]] = { r, g, b, a }
	clcInfo.display.templates:UpdateElementsLayout()
end
local function GetSkinBarsColor(info)
	return unpack(db.skinOptions.bars[info[5]])
end

--------------------------------------------------------------------------------

function mod:LoadActiveTemplate()
  -- delete the old template
  options.args.activeTemplate = {
  	order = 1, type = "group", name = "Active Template", args = {}
  }  

  -- check if there's an active template
  if not clcInfo.activeTemplate then return end
  db = clcInfo.activeTemplate
  
  
  options.args.activeTemplate.args = {
  	lockElements = {
  		order = 1, type = "group", inline = true, name = "Lock Elements",
  		args = {
  			executeLockElements = {
  				type = "execute", name = "Lock Elements",
  				func = clcInfo.display.templates.LockElements,
  			},
  			executeUnlockElements = {
  				type = "execute", name = "Unlock Elements",
  				func = clcInfo.display.templates.UnlockElements,
  			},
  			rangeGridSize = {
  				type = "range", name = "Grid Size", min = 1, max = 50, step = 1,
  				get = function(info) return db.options.gridSize end,
  				set = function(info, val) db.options.gridSize = val end,
  			},
  		},
  	},
  	show = {
  		order = 20, type = "group", inline = true, name = "Show",
  		args = {
  			showWhen = {
  				order = 1, type = "select", name = "",
  				values = { always = "Always", combat = "In Combat", valid = "Valid Target", boss = "Boss" },
  				get = function(info) return db.options.showWhen end,
  				set = clcInfo.ChangeShowWhen,
  			},
  		},
  	},
  	skins = {
			order = 30, type = "group", name = "Skin", childGroups = "tab",
			args = {
				icons = {
					order = 1, type = "group", name = "Icons",
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
					},
				},
				bars = {
					order = 2, type = "group", name = "Bars",
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
			},
		},
		grids = {
  		order = 100, type = "group", name = "Grids",
  		args = {
  			addGrid = { order = 1, type = "execute", name = "Add Grid", func = AddGrid },
  		},
  	},
  	
  	icons = {
  		order = 200, type = "group", name = "Icons",
  		args = {
  			addIcon = { order = 1, type = "execute", name = "Add Icon", func = AddIcon },
  		},
  	},
  	
  	bars = {
  		order = 300, type = "group", name = "Bars",
  		args = {
  			addBar = { order = 1, type = "execute", name = "Add Bar", func = AddBar },
  		},
  	},
  }
  
  -- if we have lbf then add it to options
  if clcInfo.lbf then
  	options.args.activeTemplate.args.skins.args.icons.args.bfOptions = {
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
  		},
  	}
  end
  
  
  
  -- update the lists
  mod.lastGridCount = 0
  mod:UpdateGridList()
  
  mod.lastIconCount = 0
  mod:UpdateIconList()
  
  mod.lastBarCount = 0
  mod.UpdateBarList()
end