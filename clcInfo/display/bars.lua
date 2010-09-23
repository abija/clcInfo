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
		
		self.elements.icon:SetTexture(texture)
	
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
	local ex = self.elements

	-- todo create only what's needed
	-- backdrop that goes around bar and icon
	-- backdrop that goes around the icon
	-- backdrop that goes around the bar
	-- bar
	-- icon
	-- frame for icon backdrop
	-- frame for bar backdrop
	
	ex.bd = {}
	
	ex.iconFrame = CreateFrame("Frame", nil, ex)
	ex.iconBd = {}
	ex.icon = ex.iconFrame:CreateTexture(nil, "ARTWORK")
	ex.icon:SetTexture("Interface\\Icons\\ABILITY_SEAL")
	ex.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	
	ex.barFrame = CreateFrame("Frame", nil, ex)
	ex.barBd = {}
	ex.bar = CreateFrame("StatusBar", nil, ex.barFrame)
	
	-- TODO - look for better fonts, there are some _LEFT fonts in blizzard's lists?
	ex.textLeft = ex.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	ex.textLeft:SetJustifyH("LEFT")
	ex.textRight = ex.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	ex.textRight:SetJustifyH("RIGHT")
	
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
  self.lockMinValue, self.lockMaxValue = ex.bar:GetMinMaxValues()
  
  -- change them
  ex.textLeft:SetText(self.label)
  ex.textRight:SetText("35")
  ex.bar:SetMinMaxValues(0, 1)
  ex.bar:SetValue(0.55)
  
  self:FakeShow()
end

-- disables control of the frame
function prototype:Lock()
  self:EnableMouse(false)
  -- here should be some code that reverses changes from previous function :p
  
  -- restore changed values
  local ex = self.elements
  ex.textLeft:SetText(self.lockTextLeft)
  ex.textRight:SetText(self.lockTextRight)
  ex.bar:SetMinMaxValues(self.lockMinValue, self.lockMaxValue)
  ex.bar:SetValue(self.lockValue)
  
  -- restore update function
  self:FakeHide()
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
	
	-- hide backdrops like a bawss
	ex:SetBackdrop(nil)
	ex.iconFrame:SetBackdrop(nil)
	
	ex.bar:SetAllPoints(ex.barFrame)
	ex.icon:SetAllPoints(ex.iconFrame)
	
	if not opt.barBg then
		ex.barFrame:SetBackdrop(nil)
	else
		ex.barBd.bgFile = LSM:Fetch("statusbar", opt.barBgTexture)
		ex.barBd.insets 	= { left = 0, right = 0, top = 0, bottom = 0 }
		ex.barFrame:SetBackdrop(ex.barBd)
		ex.barFrame:SetBackdropColor(unpack(opt.barBgColor))
		ex.barFrame:SetBackdropBorderColor(0, 0, 0, 0)
	end
	
	-- icon is same size as height and positioned to the left
	ex.iconFrame:SetWidth(opt.height)
	ex.iconFrame:SetHeight(opt.height)
	ex.iconFrame:SetPoint("LEFT", ex)
	
	-- 1px spacing
	ex.barFrame:SetWidth(opt.width - 1 - opt.height)
	ex.barFrame:SetHeight(opt.height)
	ex.barFrame:SetPoint("LEFT", ex, "LEFT", opt.height + 1, 0)
	
	ex.bar:SetStatusBarTexture(LSM:Fetch("statusbar", opt.barTexture))
	ex.bar:SetStatusBarColor(unpack(opt.barColor))
	
	-- font size should be height - 5 ? good balpark?
	-- stack
	local fh = opt.height * 0.7
	if fh < 6 then fh = 6 end
	local fontFace, _, fontFlags = ex.textLeft:GetFont()
	ex.textLeft:SetFont(fontFace, fh, fontFlags)
	ex.textLeft:SetPoint("LEFT", ex.barFrame, "LEFT", 2, 0)
	ex.textRight:SetFont(fontFace, fh, fontFlags)
	ex.textRight:SetPoint("RIGHT", ex.barFrame, "RIGHT", -2, 0)
end

-- plenty of options
local function AdvancedSkin(self)
	local opt = self.db
	local skin = opt.skin
	local ex = self.elements
	
	-- full backdrop
	if skin.bd then
		ex.bd.bgFile 		= LSM:Fetch("background", skin.bdBg)
		ex.bd.edgeFile	= LSM:Fetch("border", skin.bdBorder)
		ex.bd.edgeSize	= skin.edgeSize
		ex.bd.insets 		= { left = skin.inset, right = skin.inset, top = skin.inset, bottom = skin.inset }
		ex:SetBackdrop(ex.bd)
		ex:SetBackdropColor(unpack(skin.bdColor))
		ex:SetBackdropBorderColor(unpack(skin.bdBorderColor))
	else
		ex:SetBackdrop(nil)
	end
	
	-- icon positioning: right, left or hidden
	local iconSizeLeft, iconSpaceLeft, iconSizeRight, iconSpaceRight
	if skin.iconAlign == "right" then
		iconSizeLeft = 0
		iconSpaceLeft = 0
		iconSizeRight = opt.height - 2 * skin.padding
		iconSpaceRight = skin.iconSpacing
	elseif skin.iconAlign == "left" then
		iconSizeLeft = opt.height - 2 * skin.padding
		iconSpaceLeft = skin.iconSpacing
		iconSizeRight = 0
		iconSpaceRight = 0
	else
		iconSizeLeft = 0
		iconSpaceLeft = 0
		iconSizeRight = 0
		iconSpaceRight = 0
	end
	
	-- icon frame
	ex.iconFrame:ClearAllPoints()
	if skin.iconAlign == "right" then
		ex.iconFrame:Show()
		ex.iconFrame:SetPoint("TOPRIGHT", -skin.padding, -skin.padding)
		ex.iconFrame:SetPoint("BOTTOMLEFT", ex, "BOTTOMRIGHT", -skin.padding - iconSizeRight, skin.padding)
	elseif skin.iconAlign == "left" then
		ex.iconFrame:Show()
		ex.iconFrame:SetPoint("TOPLEFT", skin.padding, -skin.padding)
		ex.iconFrame:SetPoint("BOTTOMRIGHT", ex, "BOTTOMLEFT", skin.padding + iconSizeLeft, skin.padding)
	else
		ex.iconFrame:Hide()
	end
	ex.icon:SetPoint("TOPLEFT", skin.iconPadding, -skin.iconPadding)
	ex.icon:SetPoint("BOTTOMRIGHT", -skin.iconPadding, skin.iconPadding)
	
	-- icon backdrop
	if skin.iconBd then
		ex.iconBd.bgFile = LSM:Fetch("statusbar", skin.iconBdBg)
		ex.iconBd.edgeFile = LSM:Fetch("border", skin.iconBdBorder)
		ex.iconBd.insets 	= { left = skin.iconInset, right = skin.iconInset, top = skin.iconInset, bottom = skin.iconInset }
		ex.iconBd.edgeSize = skin.iconEdgeSize
		ex.iconFrame:SetBackdrop(ex.iconBd)
		ex.iconFrame:SetBackdropColor(unpack(skin.iconBdColor))
		ex.iconFrame:SetBackdropBorderColor(unpack(skin.iconBdBorderColor))
	else
		ex.iconFrame:SetBackdrop(nil)
	end
	
	-- barframe positioning
	ex.barFrame:ClearAllPoints()
	ex.barFrame:SetPoint("TOPLEFT", skin.padding + iconSizeLeft + iconSpaceLeft, -skin.padding)
	ex.barFrame:SetPoint("BOTTOMRIGHT", - skin.padding - iconSizeRight - iconSpaceRight, skin.padding)
	
	-- barframe backdrop
	ex.barBd = {}
	if skin.barBd then
		ex.barBd.bgFile = LSM:Fetch("statusbar", opt.barBgTexture)
		ex.barBd.edgeFile = LSM:Fetch("border", skin.barBdBorder)
		ex.barBd.insets 	= { left = skin.barInset, right = skin.barInset, top = skin.barInset, bottom = skin.barInset }
		ex.barBd.edgeSize = skin.barEdgeSize
		ex.barFrame:SetBackdrop(ex.barBd)
		ex.barFrame:SetBackdropColor(unpack(opt.barBgColor))
		ex.barFrame:SetBackdropBorderColor(unpack(skin.barBdBorderColor))
	else
		ex.barBd.bgFile = LSM:Fetch("statusbar", opt.barBgTexture)
		ex.barBd.insets 	= { left = skin.barInset, right = skin.barInset, top = skin.barInset, bottom = skin.barInset }
		ex.barFrame:SetBackdrop(ex.barBd)
		ex.barFrame:SetBackdropColor(unpack(opt.barBgColor))
	end
	
	-- bar
	ex.bar:ClearAllPoints()
	ex.bar:SetPoint("TOPLEFT", ex.barFrame, "TOPLEFT", skin.barPadding, -skin.barPadding)
	ex.bar:SetPoint("BOTTOMRIGHT", ex.barFrame, "BOTTOMRIGHT", -skin.barPadding, skin.barPadding)
	ex.bar:SetStatusBarTexture(LSM:Fetch("statusbar", opt.barTexture))
	ex.bar:SetStatusBarColor(unpack(opt.barColor))
	
	-- texts
	local fh = ex.bar:GetHeight() * skin.textLeftSize / 100
	if fh < 5 then fh = 5 end
	ex.textLeft:SetFont(LSM:Fetch("font", skin.textLeftFont), fh)
	ex.textLeft:ClearAllPoints()
	ex.textLeft:SetPoint("LEFT", ex.bar, "LEFT", skin.textLeftPadding, 0)
	
	fh = ex.bar:GetHeight() * skin.textRightSize / 100
	if fh < 5 then fh = 5 end
	ex.textRight:SetFont(LSM:Fetch("font", skin.textRightFont), fh)
	ex.textRight:ClearAllPoints()
	ex.textRight:SetPoint("RIGHT", ex.bar, "RIGHT", - skin.textRightPadding, 0)
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
	-- at least 1 px bar
	if self.db.width <= (self.db.height + 1) then self.db.width = self.db.height + 2 end
	if self.db.advancedSkin then
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
		width = 200,
		height = 20,
		exec = "return DoNothing()",
		ups = 5,
		gridId = gridId,
		gridX = 1,	-- column
		gridY = 1,	-- row
		sizeX = 10, 	-- size in cells
		sizeY = 1, 	-- size in cells
		advancedSkin = false,
		
		-- colors should be also specified per bar
		barColor 			= { 0.43, 0.56, 1, 1 },
		barBgColor 		= { 0.17, 0.22, 0.43, 0.5 },
		barTexture		= "Aluminium",
		barBgTexture	= "Aluminium",
		-- also should be able to disable bg for simple layout
		barBg = true,
		
		-- the bullcrap of skin related settings
		skin = {
			-- icon + bar
			inset										= 0,
			padding									= 0,
			edgeSize								= 8,
		
			-- full backdrop
			bd											= false,	-- false to hide it
			bdBg										= "Blizzard Tooltip",
			bdColor									= { 0, 0, 0, 0 },
			bdBorder								= "Blizzard Tooltip",
			bdBorderColor						= { 1, 1, 1, 1 },
			
		
			-- icon
			iconSpacing							= -1,
			iconAlign								= "left",
			iconInset								= 0,
			iconPadding							= 1,
			iconEdgeSize						= 8,
			
			-- icon backdrop
			iconBd									= true,	-- false to hide it
			iconBdBg								= "Blizzard Tooltip",
			iconBdColor							= { 0, 0, 0, 0 },
			iconBdBorder						= "Blizzard Tooltip",
			iconBdBorderColor				= { 1, 1, 1, 1 },
			
			-- bar
			barInset								= 2,
			barPadding							= 2,
			barEdgeSize							= 6,
			
			-- bar backdrop
			barBd										= true, -- false to hide it
			barBdBorder 						= "Blizzard Tooltip",
			barBdBorderColor 				= { 1, 1, 1, 1 },
			
			textLeftFont						= "Arial Narrow",
			textLeftSize						= 70,
			textLeftPadding					= 2,
			
			textRightFont						= "Arial Narrow",
			textRightSize						= 70,
			textRightPadding				= 2,
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







