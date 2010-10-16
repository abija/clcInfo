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
	clcInfo.display.grids:Add()
	mod:UpdateGridList()
end
local function AddIcon()
	clcInfo.display.icons:Add()
	mod:UpdateIconList()
end
local function AddMIcon()
	clcInfo.display.micons:Add()
	mod:UpdateMIconList()
end
local function AddBar()
	clcInfo.display.bars:Add()
	mod.UpdateBarList()
end
local function AddMBar()
	clcInfo.display.mbars:Add()
	mod.UpdateMBarList()
end
local function AddAlert()
	clcInfo.display.alerts:Add()
	mod.UpdateAlertList()
end
local function AddText()
	clcInfo.display.texts:Add()
	mod.UpdateTextList()
end

local function GetSkinTypeList()
	local list = { ["Default"] = "Default", ["BareBone"] = "BareBone" }
	if clcInfo.lbf then list["Button Facade"] = "Button Facade" end
	return list
end

--------------------------------------------------------------------------------
-- skins
-- general skin functions
-- info: activeTemplate skins bars barTextures barTexture
--------------------------------------------------------------------------------
local function SetSkin(info, val)
	db.skinOptions[info[3]][info[5]] = val
	clcInfo.templates:UpdateElementsLayout() 
end
local function GetSkin(info)
	return db.skinOptions[info[3]][info[5]]
end
local function SetSkinColor(info, r, g, b, a)
	db.skinOptions[info[3]][info[5]] = { r, g, b, a }
	clcInfo.templates:UpdateElementsLayout()
end
local function GetSkinColor(info)
	return unpack(db.skinOptions[info[3]][info[5]])
end
--------------------------------------------------------------------------------

-- stratalevels
local strataLevels = {
	"BACKGROUND",
	"LOW",
	"MEDIUM",
	"HIGH",
	"DIALOG",
	"FULLSCREEN",
	"FULLSCREEN_DIALOG",
	"TOOLTIP",
}
local function GetStrata(info)
	for i = 1, #strataLevels do
		if strataLevels[i] == db.options.strata then
			return i
		end
	end
end
local function SetStrata(info, val)
	db.options.strata = strataLevels[val]
	clcInfo.mf:SetFrameStrata(db.options.strata)
end

local function GetAlpha(info)
	return db.options.alpha
end
local function SetAlpha(info, val)
	db.options.alpha = val
	clcInfo.mf:SetAlpha(val)
end

--------------------------------------------------------------------------------
-- TODO: remove the inline functions from the tables
--------------------------------------------------------------------------------

function mod:LoadActiveTemplate()
	-- name
	local atn = ""
	if clcInfo.activeTemplate then
		atn = clcInfo.activeTemplate.options.udLabel
		if atn == "" then atn = "Template" .. clcInfo.activeTemplateIndex end
	end
		
  -- delete the old template
  options.args.activeTemplate = {
  	order = 1, type = "group", name = "Active: " .. atn, args = {}
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
  				func = clcInfo.templates.LockElements,
  			},
  			executeUnlockElements = {
  				type = "execute", name = "Unlock Elements",
  				func = clcInfo.templates.UnlockElements,
  			},
  			rangeGridSize = {
  				type = "range", name = "Grid Size", min = 1, max = 50, step = 1,
  				get = function(info) return db.options.gridSize end,
  				set = function(info, val) db.options.gridSize = val end,
  			},
  		},
  	},
  	visibility = {
  		order = 20, type = "group", inline = true, name = "Visibility",
  		args = {
  			showWhen = {
  				order = 1, type = "select", name = "Show",
  				values = { always = "Always", combat = "In Combat", valid = "Valid Target", boss = "Boss" },
  				get = function(info) return db.options.showWhen end,
  				set = function(info, val)
	  				db.options.showWhen = val
  					clcInfo:ChangeShowWhen()
  				end
  			},
  			strata = {
  				order = 2, type = "select", name = "Strata", values = strataLevels,
  				get = GetStrata, set = SetStrata,
  			},
  			alpha = {
  				order = 3, type = "range", min = 0, max = 1, step = 0.01, name = "Alpha",
  				get = GetAlpha, set = SetAlpha,
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
									get = GetSkin, set = SetSkin,
								},
							},
						},
					},
				},
				micons = {
					order = 2, type = "group", name = "Multi Icons",
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
					},
				},
				bars = {
					order = 3, type = "group", name = "Bars",
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
							order = 9, type = "group", inline = true, name = "Center Text",
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
							order = 10, type = "group", inline = true, name = "Right Text",
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
					order = 4, type = "group", name = "Multi Bars",
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
							order = 9, type = "group", inline = true, name = "Center Text",
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
							order = 10, type = "group", inline = true, name = "Right Text",
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
				texts = {
					order = 5, type = "group", name = "Texts",
					args = {
						base = {
							order = 2, type = "group", inline = true, name = "Base",
							args = {
								family = {
									order = 1, type = 'select', dialogControl = 'LSM30_Font', name = 'Font', values = LSM:HashTable("font"),
									get = GetSkin, set = SetSkin,
								},
								size = {
									order = 2, type = "range", min = 0, max = 200, step = 1, name = "Size%",
									get = GetSkin, set = SetSkin,
								},
								color = {
									order = 3, type = "color", hasAlpha = true, name = "Color",
									get = GetSkinColor, set = SetSkinColor,
								},
							},
						},
						shadow = {
							order = 3, type = "group", inline = true, name = "Shadow",
							args = {
								shadowOffsetX = {
									order = 1, type = "range", min = -20, max = 20, step = 0.01, name = "Shadow Offset X",
									get = GetSkin, set = SetSkin,
								},
								shadowOffsetY = {
									order = 2, type = "range", min = -20, max = 20, step = 0.01, name = "Shadow Offset Y",
									get = GetSkin, set = SetSkin,
								},
								shadowColor = {
									order = 3, type = "color", hasAlpha = true, name = "Shadow Color",
									get = GetSkinColor, set = SetSkinColor,
								},
							},
						},
						flags = {
							order = 4, type = "group", inline = true, name = "Flags",
							args = {
								aliasing = {
									order = 1, type = "toggle", name = "Aliasing",
									get = GetSkin, set = SetSkin,
								},
								outline = {
									order = 2, type = "toggle", name = "Outline",
									get = GetSkin, set = SetSkin,
								},
								thickoutline = {
									order = 3, type = "toggle", name = "Thick Outline",
									get = GetSkin, set = SetSkin,
								},
							},
						},
					},
				},
			},
		},
		grids = {
  		order = 50, type = "group", name = "Grids",
  		args = {
  			addGrid = { order = 1, type = "execute", name = "Add Grid", func = AddGrid },
  		},
  	},
  	
  	icons = {
  		order = 60, type = "group", name = "Icons",
  		args = {
  			addIcon = { order = 1, type = "execute", name = "Add Icon", func = AddIcon },
  		},
  	},
  	
  	micons = {
  		order = 70, type = "group", name = "Multi Icons",
  		args = {
  			addIcon = { order = 1, type = "execute", name = "Add MIcon", func = AddMIcon },
  		},
  	},
  	
  	bars = {
  		order = 80, type = "group", name = "Bars",
  		args = {
  			addBar = { order = 1, type = "execute", name = "Add Bar", func = AddBar },
  		},
  	},
  	
  	mbars = {
  		order = 90, type = "group", name = "Multi Bars",
  		args = {
  			addBar = { order = 1, type = "execute", name = "Add MBar", func = AddMBar },
  		},
  	},
  	
  	texts = {
  		order = 100, type = "group", name = "Texts",
  		args = {
  			addBar = { order = 1, type = "execute", name = "Add Text", func = AddText },
  		},
  	},
  	
  	alerts = {
  		order = 110, type = "group", name = "Alerts",
  		args = {
  			addAlert = { order = 1, type = "execute", name = "Add Alert", func = AddAlert },
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
  				get = GetSkin, set = SetSkin,
  			},
  			bfGloss = {
  				order = 1, type = "range", name = "Gloss", step = 1, min = 0, max = 100,
  				get = GetSkin, set = SetSkin,
  			},
  		},
  	}
  	
  	options.args.activeTemplate.args.skins.args.micons.args.bfOptions = {
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
  		},
  	}
  end
  
  
  
  -- update the lists
  mod.lastGridCount = 0
  mod:UpdateGridList()
  
  mod.lastIconCount = 0
  mod:UpdateIconList()
  
  mod.lastMIconCount = 0
  mod:UpdateMIconList()
  
  mod.lastBarCount = 0
  mod.UpdateBarList()
  
  mod.lastMBarCount = 0
  mod.UpdateMBarList()
  
  mod.lastTextCount = 0
  mod.UpdateTextList()
  
  mod.lastAlertCount = 0
  mod.UpdateAlertList()
  
  -- info: class modules are loaded together with active template because of the data that might be template stored
  mod:LoadClassModules()
end