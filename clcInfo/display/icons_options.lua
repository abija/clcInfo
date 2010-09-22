--[[
local function DBPrepare_CDB()
	AdaptConfig(clcInfoCharDB, { classModules = {}, templates = {} })

	local xdb = clcInfoCharDB.templates
	for i = 1, #xdb do
		AdaptConfig(xdb[i], { spec = {}, grids = {}, icons = {}, options = {}, iconOptions = {} })
		AdaptConfig(xdb[i].spec, { tree = 1, talent = 0, rank = 1 })
		AdaptConfig(xdb[i].options, {
			gridSize = 1,
			showWhen = "always",
		})
		AdaptConfig(xdb[i].iconOptions, {
			skinType = "Default",
			bfSkin = "Blizzard",
			bfGloss = 0,
		})

		-- fix the icons
		for j = 1, #(xdb[i].icons) do
			AdaptConfig(xdb[i].icons[j], {
				x = 0,
				y = 0,
				point = "BOTTOMLEFT",
				relativeTo = "UIParent",
		    relativePoint = "BOTTOMLEFT",
				width = 30,
				height = 30,
				exec = "return DoNothing()",
				ups = 5,
				gridId = 0,
				gridX = 1,	
				gridY = 1,	
				sizeX = 1,
				sizeY = 1,
			})
		end

		-- fix the grids too
		for j = 1, #(xdb[i].grids) do
			AdaptConfig(xdb[i].grids[j], {
				cellWidth = 30,
				cellHeight = 30,
				spacingX = 2,
				spacingY = 2,
				cellsX = 3,
				cellsY = 3,
				x = 0,
				y = 0,
				point = "CENTER",
		    relativePoint = "CENTER",
		    skinType = "Default",
				bfSkin = "Blizzard",
				bfGloss = 0,
			})
		end
	end
end
--]]

--[[
-- adjust the settings to current button
function prototype:OpenOptions()
  local f = clcInfo.display.icons_options
  f.obj = self
  self:DBToOptions()
  f:Show()
end

-- open settings on rclick
local OnMouseUp
do	
	local tmpFlag = true
	OnMouseUp = function(self, button)
  	if button == "RightButton" then
    	self:OpenOptions()
    	if tmpFlag then
				clcInfo.display.icons_options.tabs:SelectTab("Layout")
				tmpFlag = false
			end
			
			-- show edit texture
			-- hide edit texture for everything else
			for i = 1, getn(mod.active) do
				mod.active[i].editTex:Hide()
			end
			self.editTex:Show()
  	end
	end
self:SetScript("OnMouseUp", OnMouseUp)
end--]]


local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\display\\icons_options> " .. table.concat(t, " "))
end

local gui = clcInfo.gui

-- gui frame and element
local f, e, tabs

f = gui:Create("Frame")
f:Hide()

clcInfo.display.icons_options = f
local options = clcInfo.display.icons_options

f:SetCallback("OnClose", function(widget)
	widget:Hide()
	options.obj.editTex:Hide()
end)

f:SetTitle("Options")
f:SetWidth(460)
f:SetHeight(600)
f:SetLayout("Fill")

-- initial init of the elements
f.dbx = {}
f.dbx.x = gui:Create("Slider")
f.dbx.y = gui:Create("Slider")
f.dbx.width = gui:Create("Slider")
f.dbx.height = gui:Create("Slider")
f.dbx.exec = gui:Create("MultiLineEditBox")

-- layout tab

local function OnValueChangedX(widget, event, value)
	options.obj.db.x = value
	options.obj:UpdateLayout()
end
local function OnValueChangedY(widget, event, value)
	options.obj.db.y = value
	options.obj:UpdateLayout()
end
local function OnValueChangedWidth(widget, event, value)
	options.obj.db.width = value
	options.obj:UpdateLayout()
end
local function OnValueChangedHeight(widget, event, value)
	options.obj.db.height = value
	options.obj:UpdateLayout()
end

local function DrawLayoutTab(widget)
	local f = options
	local e, g
	
	g = gui:Create("InlineGroup")
	widget:AddChild(g)
	g:SetTitle("Position & Size")
	g:SetWidth(400)
	g:SetLayout("Flow")
	
	
	-- positionx
	e = gui:Create("Slider")
	f.dbx.x = e
	g:AddChild(e)
	e:SetLabel("x")
	e:SetSliderValues(-5000, 5000)
	e:SetWidth(170)
	e:SetCallback("OnValueChanged", OnValueChangedX)
	
	-- position y
	e = gui:Create("Slider")
	f.dbx.y = e
	g:AddChild(e)
	e:SetLabel("y")
	e:SetSliderValues(-5000, 5000)
	e:SetWidth(170)
	e:SetCallback("OnValueChanged", OnValueChangedY)
	
	-- width
	e = gui:Create("Slider")
	f.dbx.width = e
	g:AddChild(e)
	e:SetLabel("width")
	e:SetSliderValues(1, 200)
	e:SetWidth(170)
	e:SetCallback("OnValueChanged", OnValueChangedWidth)
	
	-- height
	e = gui:Create("Slider")
	f.dbx.height = e
	g:AddChild(e)
	e:SetLabel("height")
	e:SetSliderValues(1, 200)
	e:SetWidth(170)
	e:SetCallback("OnValueChanged", OnValueChangedHeight)
	
	-- update the data in the controls
	f.obj:DBToOptions()
end

local function OnEnterPressedExec(widget, event, text)
	options.obj.db.exec = text
	options.obj:UpdateExec()
end

local function DrawBehaviorTab(widget)
	local f = options
	local e
	e = gui:Create("MultiLineEditBox")
	f.dbx.exec = e
	widget:AddChild(e)
	e:SetLabel("Exec")
	e:SetWidth(400)
	e:SetNumLines(10)
	e:SetCallback("OnEnterPressed", OnEnterPressedExec)
	
	-- update the data in the controls
	f.obj:DBToOptions()
end


-- delete tab
local deleteObj

-- static popup to make sure
StaticPopupDialogs["CLCINFO_CONFIRM_DELETE_ICON_X"] = {
	text = "Are you sure you want to delete this icon?",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		deleteObj:Delete()
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

local function OnClickDelete(widget)
	deleteObj = options.obj
	StaticPopup_Show("CLCINFO_CONFIRM_DELETE_ICON_X")
end

local function DrawDeleteTab(widget)
	local f = options
	local e
	e = gui:Create("Button")
	widget:AddChild(e)
	e:SetText("Delete")
	e:SetCallback("OnClick", OnClickDelete)
end

local function SelectTabs(widget, event, group)
	widget:ReleaseChildren()
	if group == "Layout" then DrawLayoutTab(widget)
	elseif group == "Behavior" then DrawBehaviorTab(widget)
	elseif group == "Delete" then DrawDeleteTab(widget) end
end

tabs = gui:Create("TabGroup")
f.tabs = tabs
tabs:SetTabs({
	{ value = "Layout", text = "Layout" },
	{ value = "Behavior", text = "Behavior" },
	{ value = "Delete", text = "Delete" },
})
tabs:SetCallback("OnGroupSelected", SelectTabs)
f:AddChild(tabs)