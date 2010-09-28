local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\display\\mbars> " .. table.concat(t, " "))
end

--[[
-- general info
-- mbar -> spawns normal bars
-- onupdate is called on mbar
-- the spawned bars have same skin but can configure colors
--]]

-- base bar
local barPrototype = CreateFrame("Frame")
barPrototype:Hide()

-- base mbar
local prototype = CreateFrame("Frame")
prototype:Hide()

local mod = clcInfo.display.mbars
-- active objects
mod.active = {}
-- cache of objects, to not make unnecesary frames
mod.cache = {}
-- cache of bars that are used by the objects
-- their active list is hold by the object
mod.cacheBars = {}			

local LSM = clcInfo.LSM

local db

-- on update is used on the mbar object
local function OnUpdate(self, elapsed)
end

local function OnDragStop(self)
	self:StopMovingOrSizing()

	local g
	if self.db.gridId > 0 then
		g = clcInfo.display.grids.active[self.db.gridId]
	end
	if g then
		-- column
		self.db.gridX = 1 + floor((self:GetLeft() - g:GetLeft()) / (g.db.cellWidth + g.db.spacingX))
		-- row
		self.db.gridY = 1 + floor((self:GetBottom() - g:GetBottom()) / (g.db.cellHeight + g.db.spacingY))
	else
		self.db.gridId = 0
		self.db.x = self:GetLeft()
		self.db.y = self:GetBottom()
		
		local gs = clcInfo.activeTemplate.options.gridSize
		self.db.x = self.db.x - self.db.x % gs
		self.db.y = self.db.y - self.db.y % gs
	end

	self:UpdateLayout()
  clcInfo:UpdateOptions() -- update the data in options also
end

function prototype:Init()
	-- bg texture and label
	self.bg = self:CreateTexture(nil, "BACKGROUND")
	self.bg:SetAllPoints()
	self.bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	self.bg:SetVertexColor(1, 1, 1, 1)
	self.bg:Hide()
	self.label = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	self.label:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 1)
	local fontFace, _, fontFlags = self.label:GetFont()
	self.label:SetFont(fontFace, 6, fontFlags)
	self.label:Hide()

	self.elapsed = 0
	self:Show()
	self:SetScript("OnUpdate", OnUpdate)
	
	-- need a label
	
	-- the table where you get the var returns
	self.dt = {}
	self.children = {}

	-- move and config
  self:EnableMouse(false)
	self:SetMovable(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", function()
      self:StartMoving()
  end)
	self:SetScript("OnDragStop", OnDragStop)
end

-- shows and enables control of the frame
function prototype:Unlock()
  self:EnableMouse(true)
  self.bg:Show()
  self.label:Show()
  self:SetScript("OnUpdate", nil)
  self:DisableBars()
end

-- disables control of the frame
function prototype:Lock()
  self:EnableMouse(false)
  self.bg:Hide()
  self.label:Hide()
  self:SetScript("OnUpdate", OnUpdate)
  self:EnableBars()
end

-- display the elements according to the settings
local function TryGridPositioning(self, skin)
	if self.db.gridId <= 0 then return false end
	
	local f = clcInfo.display.grids.active[self.db.gridId]
	if not f then 
		self.db.gridId = 0
		return false
	end
	
	local g = f.db
	
	-- size
	self.db.width = g.cellWidth * self.db.sizeX + g.spacingX * (self.db.sizeX - 1) 
	self.db.height = g.cellHeight * self.db.sizeY + g.spacingY * (self.db.sizeY - 1)
	self:ClearAllPoints()
	self:SetWidth(self.db.width)
	self:SetHeight(self.db.height)
	
	-- position
	local x = g.cellWidth * (self.db.gridX - 1) + g.spacingX * (self.db.gridX - 1)
	local y = g.cellHeight * (self.db.gridY - 1) + g.spacingY * (self.db.gridY - 1)
	self:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, y)
		
	return true
end

function prototype:UpdateLayout()	
	-- check if it's attached to some grid
	local onGrid = TryGridPositioning(self)
	
	if not onGrid then
		self:ClearAllPoints()
		self:SetWidth(self.db.width)
		self:SetHeight(self.db.height)
		self:SetPoint(self.db.point, self.db.relativeTo, self.db.relativePoint, self.db.x, self.db.y)
	end
	
	-- at least 1 px bar
	if self.db.width <= (self.db.height + 1) then self.db.width = self.db.height + 2 end
	
	-- update children
	self:UpdateBarsLayout()	
end

function prototype:UpdateExec()
	-- updates per second
	self.freq = 1/self.db.ups
	self.elapsed = 100 --> force instant update
	
	local err
	-- exec
	self.exec, err = loadstring(self.db.exec)
	-- apply DoNothing if we have an error
	if not self.exec then
		self.exec = loadstring("return DoNothing()")
		bprint("code error:", err)
		bprint("in:", self.db.exec)
	end
  setfenv(self.exec, clcInfo.env)
  
  self.externalUpdate = false
  if self.ExecCleanup then
  	self.ExecCleanup()
  	self.ExecCleanup = nil
  end
end

function prototype:FakeShow()
	self.elements:Show()
end

-- caaaaaaaaaaaaaaaaaaareful
function prototype:Delete()
	-- delete the db entry
	-- rebuild frames
	table.remove(db, self.index)
	mod:ClearMBars()
	mod:InitMBars()
end

function prototype:ReleaseBars() end
function prototype:UpdateBarsLayout() end
-- set children bars state
function prototype:DisableBars() end
function prototype:EnableBars() end




---------------------------------------------------------------------------------
-- module functions
---------------------------------------------------------------------------------
function mod:New(index)
	-- see if we have stuff in cache
	local mbar = table.remove(self.cache)
	if mbar then
		-- cache hit
		mbar.index = index
		mbar.db = db[index]
		self.active[index] = mbar
		mbar:Show()
	else
		-- cache miss
		mbar = CreateFrame("Frame", nil, clcInfo.mf)	-- parented by the mother frame
		setmetatable(mbar, { __index = prototype })
		mbar.index = index
		mbar.db = db[index]
		self.active[index] = mbar
		mbar:SetFrameLevel(clcInfo.frameLevel + 2)
		mbar:Init()
	end
	
	-- change the text of the label here since it's done only now
	mbar.label:SetText("MBar" .. mbar.index)
	
	mbar:UpdateLayout()
	mbar:UpdateExec()
	if self.unlock then
  	mbar:Unlock()
  end
end

-- send all active bars to cache
function mod:ClearMBars()
	local mbar, n
	n = #(self.active)
	for i = 1, n do
		-- remove from active
		mbar = table.remove(self.active)
		if mbar then
			-- send children to cache too
			mbar:ReleaseBars()
			-- hide (also disables the updates)
			mbar:Hide()
			-- run cleanup functions
			if mbar.ExecCleanup then 
				mbar.ExecCleanup()
  			mbar.ExecCleanup = nil
  		end
			-- add to cache
			table.insert(self.cache, mbar)
		end
	end
end

-- read data from config and create the bars
-- IMPORTANT, always make sure you call clear first
function mod:InitMBars()
	if not clcInfo.activeTemplate then return end

	db = clcInfo.activeTemplate.mbars
	
	-- create them all over again :D
	for index in ipairs(db) do
		self:New(index)
	end
end


-- the bullcrap of skin related settings
-- same as for bars
mod.GetDefaultSkin = clcInfo.display.bars.GetDefaultSkin

-- mbar stuff
function mod:GetDefault()
	local x = (UIParent:GetWidth() - 130) / 2 * UIParent:GetScale()
	local y = (UIParent:GetHeight() - 15) / 2 * UIParent:GetScale()
	
	-- mbar default settings
	return {
		x = x,
		y = y,
		point = "BOTTOMLEFT",
		relativeTo = "UIParent",
    relativePoint = "BOTTOMLEFT",
		width = 200,
		height = 20,
		exec = "return DoNothing()",
		ups = 5,
		gridId = 0,
		gridX = 1,	-- column
		gridY = 1,	-- row
		sizeX = 1, 	-- size in cells
		sizeY = 1, 	-- size in cells
		
		skinSource = "Template",	-- template, grid, self
		ownColors	= false,
		skin = mod.GetDefaultSkin(),
	}
end
function mod:AddMBar(gridId)
	local data = mod.GetDefault()
	gridId = gridId or 0
	data.gridId = gridId
	if gridId > 0 then data.skinSource = "Grid" end
	
	-- must be called after init
	table.insert(db, data)
	self:New(getn(db))
end


-- TODO!
-- make sure cached bars are locked
function mod:LockAll()
	for i = 1, getn(self.active) do
		self.active[i]:Lock()
	end
	self.unlock = false
end

function mod:UnlockAll()
	for i = 1, getn(self.active) do
		self.active[i]:Unlock()
	end
	self.unlock = true
end

function mod:UpdateLayoutAll()
	for i = 1, getn(self.active) do
		self.active[i]:UpdateLayout()
	end
end