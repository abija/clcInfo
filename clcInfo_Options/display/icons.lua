local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo_Options\\icons> " .. table.concat(t, " "))
end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local modIcons = clcInfo.display.icons

-- static popup to make sure
local deleteObj = nil
StaticPopupDialogs["CLCINFO_CONFIRM_DELETE_ICON"] = {
	text = "Are you sure you want to delete this icon?",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		if not deleteObj then return end
		deleteObj:Delete()
		mod:UpdateIconList()
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

-- info:
-- 	1 activeTemplate
-- 	2 icons
--	3 i
--	4 deleteTab
--	5 executeDelete
local function DeleteIcon(info)
	local i = tonumber(info[3])
	deleteObj = modIcons.active[i]
	StaticPopup_Show("CLCINFO_CONFIRM_DELETE_ICON")
end

-- info:
-- 	1 activeTemplate
-- 	2 icons
--	3 i
--	4 tabLayout
--	5 size, position, ... = group names
-- 	6 width, height, ...	= var names
local function Set(info, val)
	local obj = modIcons.active[tonumber(info[3])]
	obj.db[info[6]] = val
	obj:UpdateLayout()
end
local function Get(info)
	return modIcons.active[tonumber(info[3])].db[info[6]]
end

local function SetLockedGrid(info, val)
	local obj = modIcons.active[tonumber(info[3])]
	obj.db.sizeX = val
	obj.db.sizeY = val
	obj:UpdateLayout()
end
local function GetLockedGrid(info)
	return modIcons.active[tonumber(info[3])].db.sizeX
end

local function SetLockedLayout(info, val)
	local obj = modIcons.active[tonumber(info[3])]
	obj.db.width = val
	obj.db.height = val
	obj:UpdateLayout()
end
local function GetLockedLayout(info)
	return modIcons.active[tonumber(info[3])].db.width
end

local function Lock(info)
	modIcons.active[tonumber(info[3])]:Lock()
end

local function Unlock(info)
	modIcons.active[tonumber(info[3])]:Unlock()
end

local function SetExec(info, val)
	local obj = modIcons.active[tonumber(info[3])]
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

function mod:UpdateIconList()
	local db = modIcons.active
	local optionsIcons = options.args.activeTemplate.args.icons
	
	for i = 1, #db do
		optionsIcons.args[tostring(i)] = {
			type = "group",
			name = "Icon" .. i,
			childGroups = "tab",
			args = {
				-- grid options
				tabGrid = {
					order = 1, type = "group", name = "Grid",
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
					order = 2, type = "group", name = "Layout",
					args = {
						__dGrid = {
							order = 1, type = "description",
							name = "If a grid is selected, none of the following options have any real effect.\n",
						},
						
						lock = {
							order = 100, type = "group", inline = true, name = "Lock",
							args = {
								lock = {
				  				type = "execute", name = "Lock", func = Lock
				  			},
				  			unlock = {
				  				type = "execute", name = "Unlock", func = Unlock,
				  			},
							},
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
				
				
				-- behavior options
				tabBehavior = {
					order = 3, type = "group", name = "Behavior", 
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
							func = DeleteIcon,
						},
					},
				},
			},
		}
	end
	
	if mod.lastIconCount > #(db) then
		-- nil the rest of the args
		for i = #db + 1, mod.lastIconCount do
			optionsIcons.args[tostring(i)] = nil
		end
	end
	mod.lastIconCount = #db
	
	AceRegistry:NotifyChange("clcInfo")
end