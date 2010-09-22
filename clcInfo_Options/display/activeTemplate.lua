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


local function GetSkinTypeList()
	local list = { ["Default"] = "Default", ["BareBone"] = "BareBone" }
	if clcInfo.lbf then list["Button Facade"] = "Button Facade" end
	return list
end

function mod:LoadActiveTemplate()
  -- delete the old template
  options.args.activeTemplate = {
  	order = 1, type = "group", name = "Active Template", args = {}
  }  

  -- check if there's an active template
  if not clcInfo.activeTemplate then return end
  local db = clcInfo.activeTemplate
  
  
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
  	iconSkins = {
			order = 30, type = "group", inline = true, name = "Icon Skins",
			args = {
				selectSkinType = {
					order = 1, type = "select", name = "Skin type", values = GetSkinTypeList,
					get = function(info) return db.iconOptions.skinType end,
					set = function(info, val)
						db.iconOptions.skinType = val
						clcInfo.display.templates:UpdateElementsLayout()
					end,
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
  	options.args.activeTemplate.args.iconSkins.args.bfOptions = {
  		order = 31, type = "group", inline = true, name = "Button Facade Options",
  		args = {
  			selectBFSkin = {
  				order = 1, type = "select", name = "Button Facade Skin", values = clcInfo.lbf.ListSkins,
  				get = function(info) return db.iconOptions.bfSkin end,
  				set = function(info, val)
  					db.iconOptions.bfSkin = val
  					clcInfo.display.templates:UpdateElementsLayout()
  				end,
  			},
  			rangeBFGloss = {
  				order = 1, type = "range", name = "Gloss", step = 1, min = 0, max = 100,
  				get = function(info) return db.iconOptions.bfGloss end,
  				set = function(info, val)
  					db.iconOptions.bfGloss = val
  					clcInfo.display.templates:UpdateElementsLayout()
  				end,
  			},
  		}
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