local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo_Options\\grids> " .. table.concat(t, " "))
end

-- exposed vars
local mod = clcInfo.config
local AceRegistry = mod.AceRegistry
local options = mod.options

local modGrids = clcInfo.display.grids

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

local function GetSkinTypeList()
	local list = { ["Default"] = "Default" }
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
				-- layout options
				tabLayout = {
					order = 1, type = "group", name = "Layout",
					args = {
						position = {
							order = 1, type = "group", inline = true, name = "Position",
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
							order = 2, type = "group", inline = true, name = "Cell Size",
							args = {
								cellWidth = {
									order = 1, name = "Cell Width", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
								cellHeight = {
									order = 2, name = "Cell Height", type = "range", min = 1, max = 200, step = 1,
									get = Get, set = Set,
								},
							},
						},
							
						cellNum = {
							order = 3, type = "group", inline = true, name = "Number of cells",
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
							order = 4, type = "group", inline = true, name = "Spacing",
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
				
				tabSkin = {
					order = 2, type = "group", name = "Skin",
					args = {
						selectType = {
							order = 1, type = "group", inline = true, name = "Skin Type",
							args = {
								skinType = {
									order = 1, type = "select", name = "Skin type", values = GetSkinTypeList,
									get = Get, set = Set,
								},
							},
						}
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
	  	optionsGrids.args[tostring(i)].args.tabSkin.args.bfOptions = {
	  		order = 2, type = "group", inline = true, name = "Button Facade Options",
	  		args = {
	  			bfSkin = {
	  				order = 1, type = "select", name = "Button Facade Skin", values = clcInfo.lbf.ListSkins,
	  				get = Get, set = Set,
	  			},
	  			bfGloss = {
	  				order = 1, type = "range", name = "Gloss", step = 1, min = 0, max = 100,
	  				get = Get, set = Set,
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