local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo_Options\\micons> " .. table.concat(t, " "))
end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local modMIcons = clcInfo.display.micons

-- static popup to make sure
local deleteObj = nil
StaticPopupDialogs["CLCINFO_CONFIRM_DELETE_MICON"] = {
	text = "Are you sure you want to delete this multi icon?",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not deleteObj then return end
		deleteObj:Delete()
		mod:UpdateMIconList()
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

local directionValues = { up = "up", down = "down", left = "left", right = "right" }

-- info:
-- 	1 activeTemplate
-- 	2 micons
--	3 i
--	4 deleteTab
--	5 executeDelete
local function DeleteMIcon(info)
	local i = tonumber(info[3])
	deleteObj = modMIcons.active[i]
	StaticPopup_Show("CLCINFO_CONFIRM_DELETE_MICON")
end

-- info:
-- 	1 activeTemplate
-- 	2 micons
--	3 i
--	4 tabLayout
--	5 size, position, ... = group names
-- 	6 width, height, ...	= var names
local function Set(info, val)
	local obj = modMIcons.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:UpdateLayout()
end
local function Get(info)
	return modMIcons.active[tonumber(info[3])].db[info[6]]
end

local function SetLockedGrid(info, val)
	local obj = modMIcons.active[tonumber(info[3])]
	obj.db.sizeX = val
	obj.db.sizeY = val
	obj:UpdateLayout()
end
local function GetLockedGrid(info)
	return modMIcons.active[tonumber(info[3])].db.sizeX
end

local function SetLockedLayout(info, val)
	local obj = modMIcons.active[tonumber(info[3])]
	obj.db.width = val
	obj.db.height = val
	obj:UpdateLayout()
end
local function GetLockedLayout(info)
	return modMIcons.active[tonumber(info[3])].db.width
end

local function Lock(info)
	modMIcons.active[tonumber(info[3])]:Lock()
end

local function Unlock(info)
	modMIcons.active[tonumber(info[3])]:Unlock()
end

local function SetExec(info, val)
	local obj = modMIcons.active[tonumber(info[3])]
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

-- set/get for skin micons
local function SetSkinMIcons(info, val)
	local obj = modMIcons.active[tonumber(info[3])]
	obj.db.skin[info[6]] = val
	obj:UpdateLayout()
end
local function GetSkinMIcons(info)
	return modMIcons.active[tonumber(info[3])].db.skin[info[6]]
end
local function GetSkinTypeList()
	local list = { ["Default"] = "Default", ["BareBone"] = "BareBone" }
	if clcInfo.lbf then list["Button Facade"] = "Button Facade" end
	return list
end

function mod:UpdateMIconList()
	local db = modMIcons.active
	local optionsMIcons = options.args.activeTemplate.args.micons
	
	for i = 1, #db do
		optionsMIcons.args[tostring(i)] = {
			type = "group",
			name = "MIcon" .. i,
			order = i,
			childGroups = "tab",
			args = {
				-- general
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
							order = 11, type = "group", inline = true, name = "",
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
						children = {
							order = 20, type = "group", inline = true, name = "Icons",
							args = {
								growth = {
									order = 1, type = "select", values = directionValues, name = "Direction",
									get = Get, set = Set,
								},
								spacing = {
									order = 2, type = "range", min = -10, max = 50, step = 1, name = "Spacing",
									get = Get, set = Set,
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
								sizeXY = {
									order = 6, name = "Width and Height", type = "range", min = 1, max = 200, step = 1,
									get = GetLockedGrid, set = SetLockedGrid,
								},
							},
						},
					},
				},
			
				-- layout options
				tabLayout = {
					order = 3, type = "group", name = "Layout",
					args = {
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
									order = 1, type = "range", min = 1, max = 200, step = 1, name = "Width",
									get = Get, set = Set,
								},
								height = {
									order = 2, type = "range", min = 1, max = 200, step = 1, name = "Height", 
									get = Get, set = Set,
								},
								wandh = {
									order = 3, type = "range", min = 1, max = 200, step = 1, name = "Width and Height", 
									get = GetLockedLayout, set = SetLockedLayout,
								},
							},
						},
					},
				},
				
				tabSkin = {
					order = 4, type = "group", name = "Skin",
					args = {
						selectType = {
							order = 1, type = "group", inline = true, name = "Skin Type",
							args = {
								skinType = {
									order = 1, type = "select", name = "Skin type", values = GetSkinTypeList,
									get = GetSkinMIcons, set = SetSkinMIcons,
								},
							},
						},
					},
				},
				
				
				-- behavior options
				tabBehavior = {
					order = 5, type = "group", name = "Behavior", 
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
					},
				},
				deleteTab = {
					order = 100, type = "group", name = "Delete", 
					args = {
						-- delete button
						executeDelete = {
							type = "execute", name = "Delete",
							func = DeleteMIcon,
						},
					},
				},
			},
		}
	end
	
	-- if we have lbf then add it to options
  if clcInfo.lbf then
  	for i = 1, #db do
	  	optionsMIcons.args[tostring(i)].args.tabSkin.args.bfOptions = {
	  		order = 2, type = "group", inline = true, name = "Button Facade Options",
	  		args = {
	  			bfSkin = {
	  				order = 1, type = "select", name = "Button Facade Skin", values = clcInfo.lbf.ListSkins,
	  				get = GetSkinMIcons, set = SetSkinMIcons,
	  			},
	  			bfGloss = {
	  				order = 1, type = "range", name = "Gloss", step = 1, min = 0, max = 100,
	  				get = GetSkinMIcons, set = SetSkinMIcons,
	  			},
	  		}
	  	}
	  end
  end
	
	if mod.lastMIconCount > #(db) then
		-- nil the rest of the args
		for i = #db + 1, mod.lastMIconCount do
			optionsMIcons.args[tostring(i)] = nil
		end
	end
	mod.lastMIconCount = #db
	
	AceRegistry:NotifyChange("clcInfo")
end