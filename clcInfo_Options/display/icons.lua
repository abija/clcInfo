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
				-- layout options
				tabLayout = {
					order = 1, type = "group", name = "Layout",
					args = {
						grid = {
							order = 1,  type = "group", inline = true, name = "Grid Options",
							args = {
								gridId = {
									order = 1, type = "select", name = "Select Grid", values = GetGridList,
									get = Get, set = Set, 
								},
								gridX = {
									order = 2, name = "Column", type = "range", min = 1, max = 50, step = 1,
									get = Get, set = Set,
								},
								gridY = {
									order = 3, name = "Row", type = "range", min = 1, max = 50, step = 1,
									get = Get, set = Set,
								},
								sizeX = {
									order = 4, name = "Width", type = "range", min = 1, max = 50, step = 1,
									get = Get, set = Set,
								},
								sizeY = {
									order = 5, name = "Height", type = "range", min = 1, max = 50, step = 1,
									get = Get, set = Set,
								},
							},
						},
					
						position = {
							order = 2, type = "group", inline = true, name = "Position ( [0, 0] is bottom left corner )",
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
							order = 3,
							type = "group",
							name = "Size",
							inline = true,
							args = {
								width = {
									order = 1, type = "range", min = 1, max = 200, step = 1, name = "Width",
									get = Get, set = Set,
								},
								height = {
									order = 2, type = "range", min = 1, max = 200, step = 1, name = "Height", 
									get = Get, set = Set,
								},
							},
						},
					},
				},
				
				
				-- behavior options
				tabBehavior = {
					order = 2, type = "group", name = "Behavior", 
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
					order = 3, type = "group", name = "Delete", 
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