local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\display\\grids> " .. table.concat(t, " "))
end

--[[
@info:
	grid = frame to which display elements are attached
	grid operations
		- add/delete (with reusability of frames)
		- move
	grid settings
		- cell width
		- cell height
		- spacing x
		- spacing y
		- positioning info relative to UIParent (x, y, point, relativePoint)
		- skin information to apply to elements in grid
--]]


local prototype = CreateFrame("Frame")
prototype:Hide()

local mod = clcInfo.display.grids
mod.active = {}				
mod.cache = {}

local db

--[[
Prototype 
-- ----------------------------------------------------------------------------
--]]

function prototype:Init()
	-- black texture to display when unlocked
	self.bg = self:CreateTexture(nil, "BACKGROUND")
	self.bg:SetAllPoints()
	self.bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
	self.bg:SetVertexColor(1, 1, 1, 1)
	
  -- move and config
  self:EnableMouse(true)
	self:SetMovable(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", function()
      self:StartMoving()
  end)
	self:SetScript("OnDragStop", function()
		self:StopMovingOrSizing()
		self.db.point, _, self.db.relativePoint, self.db.x, self.db.y = self:GetPoint()
    -- update the data in options also
    clcInfo:UpdateOptions()
	end)
	
	self.label = self:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	self.label:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -2, 2)
	
	self:Hide()
	
	self:Update()
end

-- update display according to options
function prototype:Update()
	local g = self.db
	
	-- make sure we have at least 1 cell at least 1x1
	if g.cellsX < 1 then g.cellsX = 1 end
	if g.cellsY < 1 then g.cellsY = 1 end
	if g.cellWidth < 1 then g.cellWidth = 1 end
	if g.cellHeight < 1 then g.cellHeight = 1 end
	
	self:ClearAllPoints() -- TODO check if it's any difference
	self:SetWidth(g.cellsX * g.cellWidth + (g.cellsX - 1) * g.spacingX)
	self:SetHeight(g.cellsY * g.cellHeight + (g.cellsY - 1) * g.spacingY)
	self:SetPoint(g.point, "UIParent", g.relativePoint, g.x, g.y)	
	
	self:UpdateElements()
end

--[[
Unlock()
  enables control of the frame
--]]
function prototype:Unlock()
  self:Show()
end

--[[
Lock()
  disables control of the frame
--]]
function prototype:Lock()
  self:Hide()
end

-- caaaaaaaaaaaaaaaaaaareful
function prototype:Delete()
	-- delete the db entry
	table.remove(db, self.index)
	-- rebuild frames
	mod:ClearGrids()
	mod:InitGrids()
end

-- TODO!
-- this should not be hardcoded, implement some sort of register system?
function prototype:UpdateElements()
	-- update icons
	local il = clcInfo.display.icons.active
	for i = 1, #il do
		if il[i].db.gridId == self.index then
			il[i]:UpdateLayout()
		end
	end
	
	il = clcInfo.display.bars.active
	for i = 1, #il do
		if il[i].db.gridId == self.index then
			il[i]:UpdateLayout()
		end
	end
end

--[[
Module
-- ----------------------------------------------------------------------------
--]]
function mod:New(index)
	-- see if we have stuff in cache
	local grid = table.remove(self.cache)
	if grid then
		-- cache hit
		grid.index = index
		grid.db = db[index]
		self.active[index] = grid
	else
		-- cache miss
		grid = CreateFrame("Frame", nil, clcInfo.mf)
		setmetatable(grid, { __index = prototype })
		grid.index = index
		grid.db = db[index]
		self.active[index] = grid
		grid:SetFrameLevel(clcInfo.frameLevel + 1)
		grid:Init()
	end
	
	-- change the text of the label here since it's done only now
	grid.label:SetText("Grid" .. grid.index)
	
	grid:Update()
	if self.unlock then
		grid:Unlock()
	end
end


-- send all active grids to cache
function mod:ClearGrids()
	local grid
	for i = 1, getn(self.active) do
		-- remove from active
		grid = table.remove(self.active)
		if grid then
			-- hide
			grid:Hide()
			-- add to cache
			table.insert(self.cache, grid)
		end
	end
end

-- read data from config and create the grids
-- IMPORTANT, always make sure you call clear first
function mod:InitGrids()
	if not clcInfo.activeTemplate then return end

	db = clcInfo.activeTemplate.grids
	
	-- create them all over again :D
	for index in ipairs(db) do
		self:New(index)
	end
end

function mod:GetDefault()
	return {
		-- cell size
		cellWidth = 30,
		cellHeight = 30,
		-- cell spacing
		spacingX = 2,
		spacingY = 2,
		-- number of cells
		cellsX = 3,
		cellsY = 3,
		-- positioning relative to UIParent, defaults to center of screen
		x = 0,
		y = 0,
		point = "CENTER",
    relativePoint = "CENTER",
    -- skin settings, so that we use grid skin when in a grid
    skinOptions = {
    	icons = clcInfo.display.icons:GetDefaultSkin(),
    	bars = clcInfo.display.bars:GetDefaultSkin()
    },
	}
end
function mod:AddGrid()
	local data = mod:GetDefault()
		
	-- must be called after init
	table.insert(db, data)
	self:New(getn(db))
end


-- TODO!
-- make sure cached grids are locked ?
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

function mod:UpdateAll()
	for i = 1, getn(self.active) do
		self.active[i]:Update()
	end
end
