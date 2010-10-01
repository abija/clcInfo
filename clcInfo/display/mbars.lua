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

--------------------------------------------------------------------------------
-- bar object
--------------------------------------------------------------------------------

function barPrototype:Init()
	self.bd = {}
	
	self.iconFrame = CreateFrame("Frame", nil, self)
	self.iconBd = {}
	self.icon = self.iconFrame:CreateTexture(nil, "ARTWORK")
	self.icon:SetTexture("Interface\\Icons\\ABILITY_SEAL")
	self.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	
	self.barFrame = CreateFrame("Frame", nil, self)
	self.barBd = {}
	self.bar = CreateFrame("StatusBar", nil, self.barFrame)
	
	self.textLeft = self.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	self.textLeft:SetJustifyH("LEFT")
	self.textCenter = self.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	self.textCenter:SetJustifyH("CENTER")
	self.textRight = self.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	self.textRight:SetJustifyH("RIGHT")
	
	self:Hide()
	
	-- needed stuff
	self.lastTexture = nil
end

-- for lazy/normal? people
local function SimpleSkin(self, skin)
	local opt = self.parent.db
	
	-- hide backdrops like a bawss
	self:SetBackdrop(nil)
	self.iconFrame:SetBackdrop(nil)
	
	self.bar:SetAllPoints(self.barFrame)
	self.icon:SetAllPoints(self.iconFrame)
	
	if not skin.barBg then
		self.barFrame:SetBackdrop(nil)
	else
		self.barBd.bgFile = LSM:Fetch("statusbar", skin.barBgTexture)
		self.barBd.insets 	= { left = 0, right = 0, top = 0, bottom = 0 }
		self.barFrame:SetBackdrop(self.barBd)
		self.barFrame:SetBackdropColor(unpack(skin.barBgColor))
		self.barFrame:SetBackdropBorderColor(0, 0, 0, 0)
	end
	
	-- icon is same size as height and positioned to the left
	self.iconFrame:SetWidth(opt.height)
	self.iconFrame:SetHeight(opt.height)
	self.iconFrame:SetPoint("LEFT", self)
	
	-- 1px spacing
	self.barFrame:SetWidth(opt.width - 1 - opt.height)
	self.barFrame:SetHeight(opt.height)
	self.barFrame:SetPoint("LEFT", self, "LEFT", opt.height + 1, 0)
	
	self.bar:SetStatusBarTexture(LSM:Fetch("statusbar", skin.barTexture))
	self.bar:SetStatusBarColor(unpack(skin.barColor))
	
	-- font size should be height - 5 ? good balpark?
	-- stack
	local fh = opt.height * 0.7
	if fh < 6 then fh = 6 end
	local fontFace, _, fontFlags = self.textLeft:GetFont()
	
	self.textLeft:SetFont(fontFace, fh, fontFlags)
	self.textLeft:SetPoint("LEFT", self.barFrame, "LEFT", 2, 0)
	self.textLeft:SetVertexColor(1, 1, 1, 1)
	
	self.textCenter:SetFont(fontFace, fh, fontFlags)
	self.textCenter:SetPoint("CENTER", self.barFrame)
	self.textCenter:SetVertexColor(1, 1, 1, 1)
	
	self.textRight:SetFont(fontFace, fh, fontFlags)
	self.textRight:SetPoint("RIGHT", self.barFrame, "RIGHT", -2, 0)
	self.textRight:SetVertexColor(1, 1, 1, 1)
end

-- plenty of options
local function AdvancedSkin(self, skin)
	local opt = self.parent.db
	
	-- full backdrop
	if skin.bd then
		self.bd.bgFile 		= LSM:Fetch("background", skin.bdBg)
		self.bd.edgeFile	= LSM:Fetch("border", skin.bdBorder)
		self.bd.edgeSize	= skin.edgeSize
		self.bd.insets 		= { left = skin.inset, right = skin.inset, top = skin.inset, bottom = skin.inset }
		self:SetBackdrop(self.bd)
		self:SetBackdropColor(unpack(skin.bdColor))
		self:SetBackdropBorderColor(unpack(skin.bdBorderColor))
	else
		self:SetBackdrop(nil)
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
	self.iconFrame:ClearAllPoints()
	if skin.iconAlign == "right" then
		self.iconFrame:Show()
		self.iconFrame:SetPoint("TOPRIGHT", -skin.padding, -skin.padding)
		self.iconFrame:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -skin.padding - iconSizeRight, skin.padding)
	elseif skin.iconAlign == "left" then
		self.iconFrame:Show()
		self.iconFrame:SetPoint("TOPLEFT", skin.padding, -skin.padding)
		self.iconFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", skin.padding + iconSizeLeft, skin.padding)
	else
		self.iconFrame:Hide()
	end
	self.icon:SetPoint("TOPLEFT", skin.iconPadding, -skin.iconPadding)
	self.icon:SetPoint("BOTTOMRIGHT", -skin.iconPadding, skin.iconPadding)
	
	-- icon backdrop
	if skin.iconBd then
		self.iconBd.bgFile = LSM:Fetch("statusbar", skin.iconBdBg)
		self.iconBd.edgeFile = LSM:Fetch("border", skin.iconBdBorder)
		self.iconBd.insets 	= { left = skin.iconInset, right = skin.iconInset, top = skin.iconInset, bottom = skin.iconInset }
		self.iconBd.edgeSize = skin.iconEdgeSize
		self.iconFrame:SetBackdrop(self.iconBd)
		self.iconFrame:SetBackdropColor(unpack(skin.iconBdColor))
		self.iconFrame:SetBackdropBorderColor(unpack(skin.iconBdBorderColor))
	else
		self.iconFrame:SetBackdrop(nil)
	end
	
	-- barframe positioning
	self.barFrame:ClearAllPoints()
	self.barFrame:SetPoint("TOPLEFT", skin.padding + iconSizeLeft + iconSpaceLeft, -skin.padding)
	self.barFrame:SetPoint("BOTTOMRIGHT", - skin.padding - iconSizeRight - iconSpaceRight, skin.padding)
	
	-- barframe backdrop
	self.barBd = {}
	if skin.barBd then
		self.barBd.bgFile = LSM:Fetch("statusbar", skin.barBgTexture)
		self.barBd.edgeFile = LSM:Fetch("border", skin.barBdBorder)
		self.barBd.insets 	= { left = skin.barInset, right = skin.barInset, top = skin.barInset, bottom = skin.barInset }
		self.barBd.edgeSize = skin.barEdgeSize
		self.barFrame:SetBackdrop(self.barBd)
		self.barFrame:SetBackdropColor(unpack(skin.barBgColor))
		self.barFrame:SetBackdropBorderColor(unpack(skin.barBdBorderColor))
	else
		self.barBd.bgFile = LSM:Fetch("statusbar", skin.barBgTexture)
		self.barBd.insets 	= { left = skin.barInset, right = skin.barInset, top = skin.barInset, bottom = skin.barInset }
		self.barFrame:SetBackdrop(self.barBd)
		self.barFrame:SetBackdropColor(unpack(skin.barBgColor))
	end
	
	-- bar
	self.bar:ClearAllPoints()
	self.bar:SetPoint("TOPLEFT", self.barFrame, "TOPLEFT", skin.barPadding, -skin.barPadding)
	self.bar:SetPoint("BOTTOMRIGHT", self.barFrame, "BOTTOMRIGHT", -skin.barPadding, skin.barPadding)
	self.bar:SetStatusBarTexture(LSM:Fetch("statusbar", skin.barTexture))
	self.bar:SetStatusBarColor(unpack(skin.barColor))
	
	-- texts
	local fh = self.bar:GetHeight() * skin.textLeftSize / 100
	if fh < 5 then fh = 5 end
	self.textLeft:SetFont(LSM:Fetch("font", skin.textLeftFont), fh)
	self.textLeft:ClearAllPoints()
	self.textLeft:SetPoint("LEFT", self.bar, "LEFT", skin.textLeftPadding, 0)
	self.textLeft:SetVertexColor(unpack(skin.textLeftColor))
	
	fh = self.bar:GetHeight() * skin.textCenterSize / 100
	if fh < 5 then fh = 5 end
	self.textCenter:SetFont(LSM:Fetch("font", skin.textCenterFont), fh)
	self.textCenter:ClearAllPoints()
	self.textCenter:SetPoint("CENTER", self.bar)
	self.textCenter:SetVertexColor(unpack(skin.textCenterColor))
	
	fh = self.bar:GetHeight() * skin.textRightSize / 100
	if fh < 5 then fh = 5 end
	self.textRight:SetFont(LSM:Fetch("font", skin.textRightFont), fh)
	self.textRight:ClearAllPoints()
	self.textRight:SetPoint("RIGHT", self.bar, "RIGHT", - skin.textRightPadding, 0)
	self.textRight:SetVertexColor(unpack(skin.textRightColor))
end

function barPrototype:UpdateLayout(i, skin)
	local opt = self.parent.db
	self:SetWidth(opt.width)
	self:SetHeight(opt.height)	
	
	self:ClearAllPoints()
	if opt.growth == "up" then
		self:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT", 0, (i - 1) * (opt.height + opt.spacing))
	else
		self:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, (1 - i) * (opt.height + opt.spacing))
	end
	
	if skin.advancedSkin then
		AdvancedSkin(self, skin)
	else
		SimpleSkin(self, skin)
	end
	
	-- reset alpha
	self:SetAlpha(1)
	
	-- fix text width/height
	self.textLeft:SetWidth(self.bar:GetWidth() * 0.8)
	self.textLeft:SetHeight(self.bar:GetHeight())
	self.textCenter:SetWidth(self.bar:GetWidth())
	self.textCenter:SetHeight(self.bar:GetHeight())
	self.textRight:SetWidth(self.bar:GetWidth() * 0.3)
	self.textCenter:SetHeight(self.bar:GetHeight())
	
	-- own colors to make it easier to configure
	if opt.ownColors then
		self.bar:SetStatusBarColor(unpack(opt.skin.barColor))
		self.barFrame:SetBackdropColor(unpack(opt.skin.barBgColor))
	end
	
	self.r, self.g, self.b, self.a = self.bar:GetStatusBarColor()
end

--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- mbar object
--------------------------------------------------------------------------------

function prototype:___AddBar(id, alpha, r, g, b, a, texture, minValue, maxValue, value, mode, textLeft, textCenter, textRight)
	self.___dc = self.___dc + 1
	
	local bar
	if self.___dc > #self.___c then
		bar = self:New()
	else
		bar = self.___c[self.___dc]
	end

	bar:SetAlpha(alpha or 1)
	if r then bar.bar:SetStatusBarColor(r, g, b, a)
	else bar.bar:SetStatusBarColor(bar.r, bar.g, bar.b, bar.a) end
	
	bar.icon:SetTexture(texture)
	bar.bar:SetMinMaxValues(minValue, maxValue)
	bar.bar:SetValue(value)
	bar.textLeft:SetText(textLeft)
	bar.textCenter:SetText(textCenter)
	bar.textRight:SetText(textRight)
	bar:Show()
	
	-- save important stuff for quick updates
	bar.value = value
	bar.mode = mode
end


-- on update is used on the mbar object
local function OnUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed >= self.freq then
		self.elapsed = 0
		
		-- expose the object
		clcInfo.env.___e = self
		
		-- reset the counter for the data tables
		self.___dc = 0
		
		-- update data
		self.exec()
		
		
		if self.___dc < #self.___c then
			-- hide the extra bars
			for i = self.___dc + 1, #self.___c do
				self.___c[i]:Hide()
			end
		end
		
	else
		-- quick update display 
		local bar
		for i = 1, self.___dc do
			bar = self.___c[i]
			if bar.mode == "normal" then
					bar.value = bar.value - elapsed
			elseif bar.mode == "reversed" then
				bar.value = bar.value + elapsed
			end
			
			bar.bar:SetValue(bar.value)	
		end
	end
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
	
	self.___dc = 0			-- data count
	self.___c = {}			-- children

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
  self:HideBars()
  
  -- show first bar
  -- alpha, r, g, b, a, texture, minValue, maxValue, value, mode, textLeft, textCenter, textRight
  self.___dc = 0
 	self:___AddBar(nil, nil, nil, nil, nil, nil, "Interface\\Icons\\ABILITY_SEAL", 1, 100, 50, nil, "left", "center", "right")
end

-- disables control of the frame
function prototype:Lock()
  self:EnableMouse(false)
  self.bg:Hide()
  self.label:Hide()
  self:SetScript("OnUpdate", OnUpdate)
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
	
	local skin
	if onGrid and self.db.skinSource == "Grid" then
		skin = clcInfo.display.grids.active[self.db.gridId].db.skinOptions.mbars
	elseif self.db.skinSource == "Template" then
		skin = clcInfo.activeTemplate.skinOptions.mbars
	else
		skin = self.db.skin
	end
	
	self.skin = skin
	
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
  
  -- release the bars
  self:ReleaseBars()
end

-- caaaaaaaaaaaaaaaaaaareful
function prototype:Delete()
	-- delete the db entry
	-- rebuild frames
	table.remove(db, self.index)
	mod:ClearMBars()
	mod:InitMBars()
end

function prototype:New()
	-- see if we have stuff in cache
	local bar = table.remove(mod.cacheBars)
	if not bar then
		-- cache miss
		bar = CreateFrame("Frame", nil, clcInfo.mf)	-- parented by the mother frame
		setmetatable(bar, { __index = barPrototype })
		bar:SetFrameLevel(clcInfo.frameLevel + 2)
		bar:Init()
	end
	
	bar.parent = self
	
	self.___c[#self.___c + 1] = bar
	
	bar:UpdateLayout(#self.___c, self.skin)
	
	return bar
end

function prototype:ReleaseBars()
	local bar
	local b = #self.___c
	for i = 1, b do
		bar = table.remove(self.___c)
		bar:Hide()
		table.insert(mod.cacheBars, bar)
	end
end
function prototype:UpdateBarsLayout()
	for i = 1, #self.___c do
		self.___c[i]:UpdateLayout(i, self.skin)
	end
end
-- set children bars state
function prototype:HideBars()
	for i = 1, #self.___c do
		self.___c[i]:Hide()
	end
end
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
		growth = "up", -- up or down
		spacing = 1, -- space between bars
	
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