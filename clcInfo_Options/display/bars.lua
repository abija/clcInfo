local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo_Options\\bars> " .. table.concat(t, " "))
end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

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

function mod:UpdateBarList()
	local db = modBars.active
	local optionsBars = options.args.activeTemplate.args.bars
	
	for i = 1, #db do
		optionsBars.args[tostring(i)] = {
			type = "group",
			name = "Bar" .. i,
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
				
				
				-- behavior options
				tabBehavior = {
					order = 4, type = "group", name = "Behavior", 
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