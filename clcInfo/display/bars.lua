local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\display\\bars> " .. table.concat(t, " "))
end

-- base frame object
local prototype = CreateFrame("Frame")
prototype:Hide()

local mod = clcInfo.display.bars
-- active objects
mod.active = {}				
-- cache of objects, to not make unnecesary frames
-- delete frame == hide and send to cache
mod.cache = {}				

local LSM = clcInfo.LSM

local db

---------------------------------------------------------------------------------
-- bar prototype
---------------------------------------------------------------------------------

-- TODO!
-- OPTIMIZE! OPTIMIZE! OPTIMIZE! OPTIMIZE! OPTIMIZE!
local function OnUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	-- manual set updates per second for dev testing
	-- if self.elapsed < 0.2 then

	local bar = self.elements.bar
	if self.elapsed >= self.freq then
		-- this is were exec requests are done
		self.elapsed = 0
		
		-- expose the object
		clcInfo.env.cBar = self
		
		local visible, texture, minValue, maxValue, value, valueFunc, textLeft, textRight, alpha, svc, r, g, b, a = self.exec()
		self.visible = visible
		if not visible then self:FakeHide() return end
		
		self.valueFunc = valueFunc
		self.value = value
		
		textLeft = textLeft or ""
		righText = textRight or ""
		
		self.elements.textLeft:SetText(textLeft)
		self.elements.textRight:SetText(textRight)
	
		bar:SetMinMaxValues(minValue, maxValue)
		bar:SetValue(value)
	else
		if not self.visible then self:FakeHide() return end
		if self.valueFunc then
			self.value = self.valueFunc(self.value, elapsed)
		end
		bar:SetValue(self.value)	
	end
	
	-- regardless if we update info or not, the bar still needs to progress
	self:FakeShow()
end



function prototype:Init()
	-- create a child frame that holds all the elements and it's hidden/shown instead of main one that has update function
	self.elements = CreateFrame("Frame", nil, self)

	-- todo create only what's needed
	-- backdrop that goes around bar and icon
	-- backdrop that goes around the icon
	-- backdrop that goes around the bar
	-- bar
	-- icon
	-- frame for icon backdrop
	-- frame for bar backdrop
	
	self.elements.bd = {}
	
	self.elements.iconFrame = CreateFrame("Frame", nil, self.elements)
	self.elements.iconBd = {}
	self.elements.icon = self.elements.iconFrame:CreateTexture(nil, "ARTWORK")
	
	self.elements.barFrame = CreateFrame("Frame", nil, self.elements)
	self.elements.barBd = {}
	self.elements.bar = CreateFrame("StatusBar", nil, self.elements.barFrame)
	
	-- TODO - look for better fonts, there are some _LEFT fonts in blizzard's lists?
	self.elements.textLeft = self.elements.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	self.elements.textLeft:SetJustifyH("LEFT")
	self.elements.textRight = self.elements.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	self.elements.textRight:SetJustifyH("RIGHT")
	
	self.elapsed = 0
	self:FakeHide()
	self:Show()
	self:SetScript("OnUpdate", OnUpdate)	
	
	-- move and config
  self:EnableMouse(false)
	self:SetMovable(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", function()
      self:StartMoving()
  end)
	self:SetScript("OnDragStop", function()
		self:StopMovingOrSizing()
		self.db.x = self:GetLeft()
		self.db.y = self:GetBottom()
		
		local gs = clcInfo.activeTemplate.options.gridSize
		self.db.x = self.db.x - self.db.x % gs
		self.db.y = self.db.y - self.db.y % gs
		
		self:UpdateLayout()
    -- update the data in options also
    clcInfo:UpdateOptions()
	end)
end

-- shows and enables control of the frame
function prototype:Unlock()
  self:EnableMouse(true)
  -- here should be some code that makes the bar full, visible, maybe grayed out, hides right text and labels left text as barx
  
  -- remove update function
  self:SetScript("OnUpdate", nil)
  
  -- store important values
  local ex = self.elements
  self.lockTextLeft = ex.textLeft:GetText()
  self.lockTextRight = ex.textRight:GetText()
  self.lockValue = ex.bar:GetValue()
  -- change them
  ex.textLeft:SetText(self.label)
  ex.textRight:SetText("")
  local _, maxv = ex.bar:GetMinMaxValues()
  ex.bar:SetValue(maxv)
end

-- disables control of the frame
function prototype:Lock()
  self:EnableMouse(false)
  -- here should be some code that reverses changes from previous function :p
  
  -- restore changed values
  local ex = self.elements
  ex.textLeft:SetText(self.lockTextLeft)
  ex.textRight:SetText(self.lockTextRight)
  ex.bar:SetValue(self.lockValue)
  
  -- restore update function
  self:SetScript("OnUpdate", OnUpdate)
end


-- display the elements according to the settings
local function TryGridPositioning(self)
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
	local x = 10 + g.cellWidth * (self.db.gridX - 1) + g.spacingX * (self.db.gridX - 1)
	local y = 10 + g.cellHeight * (self.db.gridY - 1) + g.spacingY * (self.db.gridY - 1)
	self:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, y)
		
	return true
end

-- for lazy/normal? people
local function SimpleSkin(self)
	local opt = self.db
	local ex = self.elements
	
	-- at least 1 px bar
	if opt.width <= (opt.height + 1) then opt.width = opt.height + 2 end
	
	-- hide backdrops like a bawss
	ex:SetBackdrop(nil)
	ex.iconFrame:SetBackdrop(nil)
	
	ex.bar:SetAllPoints(ex.barFrame)
	ex.icon:SetAllPoints(ex.iconFrame)
	
	if not opt.barBg then
		ex.barFrame:SetBackdrop(nil)
	else
		ex.barBd.bgFile = LSM:Fetch("statusbar", "Minimalist")
		ex.barFrame:SetBackdrop(ex.barBd)
		ex.barFrame:SetBackdropColor(unpack(opt.barBgColor))
	end
	
	-- icon is same size as height and positioned to the left
	ex.iconFrame:SetWidth(opt.height)
	ex.iconFrame:SetHeight(opt.height)
	ex.iconFrame:SetPoint("LEFT", ex)
	
	-- 1px spacing
	ex.barFrame:SetWidth(opt.width - 1 - opt.height)
	ex.barFrame:SetHeight(opt.height)
	ex.barFrame:SetPoint("LEFT", ex, "LEFT", opt.height + 1, 0)
	
	ex.bar:SetStatusBarTexture(LSM:Fetch("statusbar", "Minimalist"))
	ex.bar:SetStatusBarColor(unpack(opt.barColor))
	
	-- font size should be height - 5 ? good balpark?
	-- stack
	local fh = opt.height - 3
	if fh < 6 then fh = 6 end
	local fontFace, _, fontFlags = ex.textLeft:GetFont()
	ex.textLeft:SetFont(fontFace, fh, fontFlags)
	ex.textLeft:SetPoint("LEFT", ex.barFrame, "LEFT", 2, 0)
	ex.textRight:SetFont(fontFace, fh, fontFlags)
	ex.textRight:SetPoint("RIGHT", ex.barFrame, "RIGHT", -2, 0)
end

local function AdvancedSkin(self)
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
	
	self.elements:ClearAllPoints()
	self.elements:SetAllPoints(self)
	
	-- fix the looks
	-- TODO remember to implement grid skinning
	if db.advancedSkin then
		AdvancedSkin(self)
	else
		SimpleSkin(self)
	end
end

function prototype:UpdateExec()
	-- updates per second
	self.freq = 1/self.db.ups
	self.elapsed = 100 --> forc instant update
	
	self.visible = false
	self.valueFunc = nil
	self.value = 0
	
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
  
  -- reset stuff changed when update is removed
  self:SetScript("OnUpdate", OnUpdate)
  self.externalUpdate = false
  if self.ExecCleanup then
  	self.ExecCleanup()
  	self.ExecCleanup = nil
  end
end

function prototype:FakeShow()
	self.elements:Show()
end

function prototype:FakeHide()
	self.elements:Hide()
end


-- caaaaaaaaaaaaaaaaaaareful
function prototype:Delete()
	-- delete the db entry
	-- rebuild frames
	table.remove(db, self.index)
	mod:ClearBars()
	mod:InitBars()
end

---------------------------------------------------------------------------------


---------------------------------------------------------------------------------
-- module functions
-- TODO
--    fix names
--    reuse frames
---------------------------------------------------------------------------------
function mod:New(index)
	-- see if we have stuff in cache
	local bar = table.remove(self.cache)
	if bar then
		-- cache hit
		bar.index = index
		bar.db = db[index]
		self.active[index] = bar
		bar:Show()
	else
		-- cache miss
		bar = CreateFrame("Frame", nil, clcInfo.mf)	-- parented by the mother frame
		setmetatable(bar, { __index = prototype })
		bar.index = index
		bar.db = db[index]
		self.active[index] = bar
		bar:SetFrameLevel(clcInfo.frameLevel + 2)
		bar:Init()
	end
	
	-- change the text of the label here since it's done only now
	bar.label = "Bar" .. bar.index
	
	bar:UpdateLayout()
	bar:UpdateExec()
	if self.unlock then
  	bar:Unlock()
  end
end

-- send all active bars to cache
function mod:ClearBars()
	local bar
	for i = 1, getn(self.active) do
		-- remove from active
		bar = table.remove(self.active)
		if bar then
			-- hide (also disables the updates)
			bar:Hide()
			-- run cleanup functions
			if bar.ExecCleanup then 
				bar.ExecCleanup()
  			bar.ExecCleanup = nil
  		end
			-- add to cache
			table.insert(self.cache, bar)
		end
	end
end

-- read data from config and create the bars
-- IMPORTANT, always make sure you call clear first
function mod:InitBars()
	if not clcInfo.activeTemplate then return end

	db = clcInfo.activeTemplate.bars
	
	-- create them all over again :D
	for index in ipairs(db) do
		self:New(index)
	end
end

function mod:AddBar(gridId)
	local x = (UIParent:GetWidth() - 130) / 2 * UIParent:GetScale()
	local y = (UIParent:GetHeight() - 15) / 2 * UIParent:GetScale()
	
	if gridId == nil then gridId = 0 end
	
	-- bar default settings
	local data = {
		x = x,
		y = y,
		point = "BOTTOMLEFT",
		relativeTo = "UIParent",
    relativePoint = "BOTTOMLEFT",
		width = 130,
		height = 15,
		exec = "return DoNothing()",
		ups = 5,
		gridId = gridId,
		gridX = 1,	-- column
		gridY = 1,	-- row
		sizeX = 7, 	-- size in cells
		sizeY = 1, 	-- size in cells
		advancedSkin = false,
		
		-- colors should be also specified per bar
		barColor = { 1, 1, 0, 1 },
		barBgColor = { 0, 0, 0, 0.3 },
		-- also should be able to disable bg for simple layout
		barBg = true,
		
		-- the bullcrap of skin related settings
		skin = {
			-- icon + bar
			inset										= 0,
			padding									= 0,
			edgeSize								= 8,
		
			-- full backdrop
			bd											= true,	-- false to hide it
			bdBg										= "Blizzard Tooltip",
			bdColor									= { 0, 0, 0, 0 },
			bdBorder								= "clcCastBar Border",
			bdBorderColor						= { 0, 0, 0, 0 },
			
		
			-- icon
			iconSpacing							= 2,
			iconAlign								= "left",
			iconInset								= 0,
			iconPadding							= 0,
			iconEdgeSize						= 8,
			
			-- icon backdrop
			iconBd									= true,	-- false to hide it
			iconBdBg								= "Blizzard Tooltip",
			iconBdColor							= { 0, 0, 0, 0 },
			iconBdBorder						= "clcCastBar Border",
			iconBdBorderColor				= { 0, 0, 0, 0 },
			
			-- bar
			barTexture							= "clcCastBar Statusbar",
			barInset								= 0,
			barPadding							= 0,
			barEdgeSize							= 8,
			
			-- bar backdrop
			barBd										= true, -- false to hide it
			barBdBg									= "clcCastBar Statusbar",		-- this is the background bar texture
			barBdColor 							= { 0, 0, 0, 0 },
			barBdBorder 						= "clcCastBar Border",
			barBdBorderColor 				= { 0, 0, 0, 0 },
			
			font										= "Friz Quadrata TT",
			textPadding							= 4,
		}
	}
	
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

---------------------------------------------------------------------------------







