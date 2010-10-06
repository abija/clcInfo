local mod = clcInfo:RegisterDisplayModule("bars") -- register the module

-- base frame object
mod.hasSkinOptions = true
mod.onGrid = true

local prototype = CreateFrame("Frame")  -- base frame object
prototype:Hide()


mod.active = {}  -- active objects
mod.cache = {}  -- cache of objects, to not make unnecesary frames

local LSM = clcInfo.LSM  -- lsm

local db  -- option

-- local bindings
local GetTime = GetTime
local pcall = pcall

local modAlerts = clcInfo.display.alerts

---------------------------------------------------------------------------------
-- bar prototype
---------------------------------------------------------------------------------

-- to get proper animation for timers bars should update on each call
-- throttle exec calls and use some data from there to do some quick updates if possible
-- TODO check code
-- TODO move alerts to special functions?
local function OnUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed

	local bar = self.elements.bar
	
	if self.elapsed >= self.freq then
		-- this is were exec requests are done
		self.elapsed = 0
		
		-- expose the object
		clcInfo.env.___e = self
		
		local status, visible, texture, minValue, maxValue, value, mode, textLeft, textCenter, textRight, alpha, svc, r, g, b, a = pcall(self.exec)
		if not status then
			-- display the first error met into the behavior tab
			-- also announce the user we got an error
			if self.errExec == "" then
				print("clcInfo.Bar" .. self.index ..":", visible)
				self.errExec = visible
				clcInfo:UpdateOptions() -- request update of the tab
			end
			-- stop execution directly ?
			visible = false
		end
		
		-- not visibile -> save info for the quick updates and hide elements
		self.visible = visible
		if not visible then
			-- test for expiration alert
			if self.hasAlerts == 1 and self.alerts.expiration then
				local a = self.alerts.expiration
				if self.mode == "normal" then
					if a.last > a.timeLeft then
						a.last = 0
						modAlerts:Play(a.alertIndex, self.lastTexture, a.sound)
					end
				elseif self.mode == "reversed" then
					if a.last < a.timeLeft then
						a.last = 10000
						modAlerts:Play(a.alertIndex, self.lastTexture, a.sound)
					end
				end
			end
			self:FakeHide()
			return 
		end
		
		-- data used for quick updates
		self.mode = mode
		self.value = value
		
		-- set the text
		self.elements.textLeft:SetText(textLeft)
		self.elements.textCenter:SetText(textCenter)
		self.elements.textRight:SetText(textRight)
		
		if texture ~= self.lastTexture then
			self.elements.icon:SetTexture(texture)
			self.lastTexture = texture
		end
	
		bar:SetMinMaxValues(minValue, maxValue)
		bar:SetValue(value)
		
		-- alert handling
		if self.hasAlerts == 1 then
			-- expiration alert
			if self.alerts.expiration then
				local a = self.alerts.expiration
				-- mode selection
				if mode == "normal" then
					if value <= a.timeLeft and a.timeLeft < a.last then
						modAlerts:Play(a.alertIndex, texture, a.sound)
					end
				elseif mode == "reversed" then
					if value >= a.timeLeft and a.timeLeft > a.last then
						modAlerts:Play(a.alertIndex, texture, a.sound)
					end
				end
				a.last = value
			end
			-- start alert
			if self.alerts.start then
				local a = self.alerts.start
				if mode == "normal" then
					if value > a.last then
						modAlerts:Play(a.alertIndex, texture, a.sound)
					end
				elseif mode == "reversed" then
					if value < a.lastReversed then
						modAlerts:Play(a.alertIndex, texture, a.sound)
					end
				end
				a.last = value
			end
		end
	else
		-- on timer based bars, regardless if we update info or not, the bar still needs to progress
		-- on custom bars, probably will just skip
		if not self.visible then self:FakeHide() return end
		
		-- mode is either "normal" or "reversed" which refer to elapsed based bars or unspecified
		if self.mode == "normal" then
			self.value = self.value - elapsed
		elseif self.mode == "reversed" then
			self.value = self.value + elapsed
		end
		
		bar:SetValue(self.value)	
	end
	
	-- show the bar if we got there
	self:FakeShow()
end


-- stuff to do when the element is dragged
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


-- create the object
function prototype:Init()
	-- create a child frame that holds all the elements and it's hidden/shown instead of main one that has update function
	self.elements = CreateFrame("Frame", nil, self)
	local ex = self.elements

	-- todo create only what's needed
	
	-- bar
	-- frame for icon backdrop
	-- frame for bar backdrop
	ex.bd = {}  -- backdrop that goes around bar and icon	
	
	ex.iconFrame = CreateFrame("Frame", nil, ex)  -- icon frame to allow backdrop
	ex.iconBd = {}  -- backdrop that goes around the icon
	ex.icon = ex.iconFrame:CreateTexture(nil, "ARTWORK") -- icon
	ex.icon:SetTexture("Interface\\Icons\\ABILITY_SEAL")
	ex.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	
	ex.barFrame = CreateFrame("Frame", nil, ex)  -- frame to allow backdrop
	ex.barBd = {}  -- backdrop that goes around the bar
	ex.bar = CreateFrame("StatusBar", nil, ex.barFrame) -- bar
	
	-- texts
	ex.textLeft = ex.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	ex.textLeft:SetJustifyH("LEFT")
	ex.textCenter = ex.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	ex.textCenter:SetJustifyH("CENTER")
	ex.textRight = ex.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	ex.textRight:SetJustifyH("RIGHT")
	
	-- hide the elements
	self:FakeHide()
	
	-- show and register for on update
	self.elapsed = 0
	self:Show()
	self:SetScript("OnUpdate", OnUpdate)	
	
	-- needed stuff
	self.lastTexture = nil
	
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
  -- here should be some code that makes the bar full, visible, maybe grayed out, hides right text and labels left text as barx
  
  -- remove update function
  self:SetScript("OnUpdate", nil)
  
  -- store important values
  local ex = self.elements
  self.lockTextLeft = ex.textLeft:GetText()
  self.lockTextCenter = ex.textCenter:GetText()
  self.lockTextRight = ex.textRight:GetText()
  self.lockValue = ex.bar:GetValue()
  self.lockMinValue, self.lockMaxValue = ex.bar:GetMinMaxValues()
  
  -- change them
  ex.textLeft:SetText(self.label)
  ex.textCenter:SetText(self.label)
  ex.textRight:SetText(self.label)
  ex.bar:SetMinMaxValues(0, 1)
  ex.bar:SetValue(0.55)
  
  self.locked = false
  
  self:FakeShow()
end

-- disables control of the frame
function prototype:Lock()
  self:EnableMouse(false)
  -- here should be some code that reverses changes from previous function :p
  
  -- restore changed values
  local ex = self.elements
  ex.textLeft:SetText(self.lockTextLeft)
  ex.textCenter:SetText(self.lockTextCenter)
  ex.textRight:SetText(self.lockTextRight)
  ex.bar:SetMinMaxValues(self.lockMinValue, self.lockMaxValue)
  ex.bar:SetValue(self.lockValue)
  
  self.locked = true
  
  -- restore update function
  self:FakeHide()
  self:SetScript("OnUpdate", OnUpdate)
end


-- try to position according to grid settings, return false if not possible
local function TryGridPositioning(self)
	if self.db.gridId <= 0 then return end
	
	local f = clcInfo.display.grids.active[self.db.gridId]
	if not f then return end
	
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


-- a simple skin, for faster use
local function SimpleSkin(self, skin)
	local opt = self.db
	local ex = self.elements
	
	-- hide backdrops like a bawss
	ex:SetBackdrop(nil)
	ex.iconFrame:SetBackdrop(nil)
	
	ex.bar:SetAllPoints(ex.barFrame)
	ex.icon:SetAllPoints(ex.iconFrame)
	
	if not skin.barBg then
		ex.barFrame:SetBackdrop(nil)
	else
		ex.barBd.bgFile = LSM:Fetch("statusbar", skin.barBgTexture)
		ex.barBd.insets 	= { left = 0, right = 0, top = 0, bottom = 0 }
		ex.barFrame:SetBackdrop(ex.barBd)
		ex.barFrame:SetBackdropColor(unpack(skin.barBgColor))
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
	
	ex.bar:SetStatusBarTexture(LSM:Fetch("statusbar", skin.barTexture))
	ex.bar:SetStatusBarColor(unpack(skin.barColor))
	
	-- font size should be height - 5 ? good balpark?
	-- stack
	local fh = opt.height * 0.7
	if fh < 6 then fh = 6 end
	local fontFace, _, fontFlags = ex.textLeft:GetFont()
	
	ex.textLeft:SetFont(fontFace, fh, fontFlags)
	ex.textLeft:SetPoint("LEFT", ex.barFrame, "LEFT", 2, 0)
	ex.textLeft:SetVertexColor(1, 1, 1, 1)
	
	ex.textCenter:SetFont(fontFace, fh, fontFlags)
	ex.textCenter:SetPoint("CENTER", ex.barFrame)
	ex.textCenter:SetVertexColor(1, 1, 1, 1)
	
	ex.textRight:SetFont(fontFace, fh, fontFlags)
	ex.textRight:SetPoint("RIGHT", ex.barFrame, "RIGHT", -2, 0)
	ex.textRight:SetVertexColor(1, 1, 1, 1)
end

-- full option skinning
local function AdvancedSkin(self, skin)
	local opt = self.db
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
		ex.barBd.bgFile = LSM:Fetch("statusbar", skin.barBgTexture)
		ex.barBd.edgeFile = LSM:Fetch("border", skin.barBdBorder)
		ex.barBd.insets 	= { left = skin.barInset, right = skin.barInset, top = skin.barInset, bottom = skin.barInset }
		ex.barBd.edgeSize = skin.barEdgeSize
		ex.barFrame:SetBackdrop(ex.barBd)
		ex.barFrame:SetBackdropColor(unpack(skin.barBgColor))
		ex.barFrame:SetBackdropBorderColor(unpack(skin.barBdBorderColor))
	else
		ex.barBd.bgFile = LSM:Fetch("statusbar", skin.barBgTexture)
		ex.barBd.insets 	= { left = skin.barInset, right = skin.barInset, top = skin.barInset, bottom = skin.barInset }
		ex.barFrame:SetBackdrop(ex.barBd)
		ex.barFrame:SetBackdropColor(unpack(skin.barBgColor))
	end
	
	-- bar
	ex.bar:ClearAllPoints()
	ex.bar:SetPoint("TOPLEFT", ex.barFrame, "TOPLEFT", skin.barPadding, -skin.barPadding)
	ex.bar:SetPoint("BOTTOMRIGHT", ex.barFrame, "BOTTOMRIGHT", -skin.barPadding, skin.barPadding)
	ex.bar:SetStatusBarTexture(LSM:Fetch("statusbar", skin.barTexture))
	ex.bar:SetStatusBarColor(unpack(skin.barColor))
	
	-- texts
	local fh = ex.bar:GetHeight() * skin.textLeftSize / 100
	if fh < 5 then fh = 5 end
	ex.textLeft:SetFont(LSM:Fetch("font", skin.textLeftFont), fh)
	ex.textLeft:ClearAllPoints()
	ex.textLeft:SetPoint("LEFT", ex.bar, "LEFT", skin.textLeftPadding, 0)
	ex.textLeft:SetVertexColor(unpack(skin.textLeftColor))
	
	fh = ex.bar:GetHeight() * skin.textCenterSize / 100
	if fh < 5 then fh = 5 end
	ex.textCenter:SetFont(LSM:Fetch("font", skin.textCenterFont), fh)
	ex.textCenter:ClearAllPoints()
	ex.textCenter:SetPoint("CENTER", ex.bar)
	ex.textCenter:SetVertexColor(unpack(skin.textCenterColor))
	
	fh = ex.bar:GetHeight() * skin.textRightSize / 100
	if fh < 5 then fh = 5 end
	ex.textRight:SetFont(LSM:Fetch("font", skin.textRightFont), fh)
	ex.textRight:ClearAllPoints()
	ex.textRight:SetPoint("RIGHT", ex.bar, "RIGHT", - skin.textRightPadding, 0)
	ex.textRight:SetVertexColor(unpack(skin.textRightColor))
end

-- update the display settings
function prototype:UpdateLayout()	
	-- check if it's attached to some grid
	local onGrid = TryGridPositioning(self)
	
	-- size and position
	if not onGrid then
		self:ClearAllPoints()
		self:SetWidth(self.db.width)
		self:SetHeight(self.db.height)
		self:SetPoint(self.db.point, self.db.relativeTo, self.db.relativePoint, self.db.x, self.db.y)
	end
	
	-- size and position for elements
	self.elements:ClearAllPoints()
	self.elements:SetAllPoints(self)
	
	-- skin options are per template, per grid or per element
	-- check which set to use
	local skin
	if onGrid and self.db.skinSource == "Grid" then
		skin = clcInfo.display.grids.active[self.db.gridId].db.skinOptions.bars
	elseif self.db.skinSource == "Template" then
		skin = clcInfo.activeTemplate.skinOptions.bars
	else
		skin = self.db.skin
	end
	
	-- apply the skin
	if skin.advancedSkin then
		AdvancedSkin(self, skin)
	else
		SimpleSkin(self, skin)
	end
	
	-- allow to configure bar colors per bar regardless of skin settings so it's easier to configure
	if self.db.ownColors then
		self.elements.bar:SetStatusBarColor(unpack(self.db.skin.barColor))
		self.elements.barFrame:SetBackdropColor(unpack(self.db.skin.barBgColor))
	end
end

-- update the exec function and related stuff
function prototype:UpdateExec()
	-- updates per second
	self.freq = 1/self.db.ups
	self.elapsed = 100 --> forc instant update
	
	self.visible = false
	self.mode = nil
	self.value = 0
	
	-- clear error codes
	self.errExec = ""
	self.errExecAlert = ""
	
	local err
	-- exec
	self.exec, err = loadstring(self.db.exec)
	-- use a blank exec if we get an error
	if not self.exec then
		self.exec = loadstring("")
		print("code error:", err)
		print("in:", self.db.exec)
	end
  setfenv(self.exec, clcInfo.env)
  
  -- perform additional cleaning if required
  self.externalUpdate = false
  if self.ExecCleanup then
  	self.ExecCleanup()
  	self.ExecCleanup = nil
  end
  
  -- handle alert exec
  
  -- defaults
  self.alerts = {}
  self.hasAlerts = 0
  
  -- execute the code
  local f, err = loadstring(self.db.execAlert or "")
  if f then
  	setfenv(f, clcInfo.env)
  	clcInfo.env.___e = self
  	local status, err = pcall(f)
  	if not status then self.errExecAlert = err end
  else
  	print("alert code error:", err)
  	print("in:", self.db.execAlert)
  end
  
  -- in case we update while the element is unlocked
  if self.locked then
  	self:SetScript("OnUpdate", OnUpdate)
  end
end

-- hide only the elements frame so that we still get onupdate calls
function prototype:FakeShow()
	self.elements:Show()
end


-- show the elements
function prototype:FakeHide()
	self.elements:Hide()
end


-- caaaaaaaaaaaaaaaaaaareful
function prototype:Delete()
	-- delete the db entry
	-- rebuild frames
	table.remove(db, self.index)
	mod:ClearElements()
	mod:InitElements()
end

---------------------------------------------------------------------------------


---------------------------------------------------------------------------------
-- module functions
---------------------------------------------------------------------------------

-- takes a bar from cache or creates a new one, adds to active cache and updateslayout
function mod:New(index)
	-- see if we have stuff in cache
	local bar = table.remove(self.cache)
	if bar then
		-- cache hit
		bar.index = index
		bar.db = db[index]
		bar:Show()
	else
		-- cache miss
		bar = CreateFrame("Frame", nil, clcInfo.mf)	-- parented by the mother frame
		setmetatable(bar, { __index = prototype })
		bar.index = index
		bar.db = db[index]
		bar:SetFrameLevel(clcInfo.frameLevel + 2)
		bar:Init()
	end
	self.active[index] = bar
	
	-- change the text of the label here since it's done only now
	bar.label = "Bar" .. bar.index
	
	bar:UpdateLayout()
	bar:UpdateExec()
	if self.unlock then
  	bar:Unlock()
  end
end

-- send all active bars to cache
function mod:ClearElements()
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
function mod:InitElements()
	if not clcInfo.activeTemplate then return end

	db = clcInfo.activeTemplate.bars
	
	-- create them all over again :D
	for index in ipairs(db) do
		self:New(index)
	end
end


-- default skin options
function mod.GetDefaultSkin()
	return {
		advancedSkin = false,
			
		barColor 			= { 0.43, 0.56, 1, 1 },
		barBgColor 		= { 0.17, 0.22, 0.43, 0.5 },
		barTexture		= "Aluminium",
		barBgTexture	= "Aluminium",
		barBg = true,
		
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
		textLeftColor						= {1, 1, 1, 1},
		
		textCenterFont					= "Arial Narrow",
		textCenterSize					= 70,
		textCenterColor					= {1, 1, 1, 1},
		
		textRightFont						= "Arial Narrow",
		textRightSize						= 70,
		textRightPadding				= 2,
		textRightColor					= {1, 1, 1, 1},
	}
end

-- default options
function mod.GetDefault()
	local x = (UIParent:GetWidth() - 130) / 2 * UIParent:GetScale()
	local y = (UIParent:GetHeight() - 15) / 2 * UIParent:GetScale()
	

	-- bar default settings
	return {
		x = x,
		y = y,
		point = "BOTTOMLEFT",
		relativeTo = "UIParent",
    relativePoint = "BOTTOMLEFT",
		width = 200,
		height = 20,
		exec = "",
		alertExec = "",
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

-- add a bar element to the template
-- if gridId is set, adds the element directly to that grid
function mod:Add(gridId)
	local data = mod.GetDefault()
	gridId = gridId or 0
	data.gridId = gridId
	if gridId > 0 then data.skinSource = "Grid" end
	
	-- must be called after init
	table.insert(db, data)
	self:New(getn(db))
end


---------------------------------------------------------------------------------
-- lock/unlock/update
---------------------------------------------------------------------------------
function mod:LockElements()
	for i = 1, getn(self.active) do
		self.active[i]:Lock()
	end
	self.unlock = false
end
function mod:UnlockElements()
	for i = 1, getn(self.active) do
		self.active[i]:Unlock()
	end
	self.unlock = true
end
function mod:UpdateElementsLayout()
	for i = 1, getn(self.active) do
		self.active[i]:UpdateLayout()
	end
end
---------------------------------------------------------------------------------







