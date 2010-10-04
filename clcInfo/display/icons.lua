local mod = clcInfo:RegisterDisplayModule("icons")  -- register the module
-- special options
mod.hasSkinOptions = true
mod.onGrid = true

-- button facade
local lbf = clcInfo.lbf
local LSM = clcInfo.LSM

local prototype = CreateFrame("Frame")  -- base frame object
prototype:Hide()


mod.active = {}  -- active objects
mod.cache = {}  -- cache of objects, to not make unnecesary frames

local db

-- some defaults used for skinning
local STACK_DEFAULT_WIDTH 		= 36
local STACK_DEFAULT_HEIGHT 		= 10
local STACK_DEFAULT_OFFSETX 	= -2
local STACK_DEFAULT_OFFSETY 	= -11
local ICON_DEFAULT_WIDTH 			= 30
local ICON_DEFAULT_HEIGHT			= 30

-- local bindings
local GetTime = GetTime

local modAlerts = clcInfo.display.alerts

---------------------------------------------------------------------------------
-- icon prototype
---------------------------------------------------------------------------------

-- called for each of the icons
local function OnUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed < self.freq then return end
	-- manual set updates per second for dev testing
	-- if self.elapsed < 0.2 then return end
	self.elapsed = 0
	
	-- expose the object
	clcInfo.env.___e = self
	
	-- needed vars to cover all posibilities
	-- visible
	-- texture
	-- start, duration, enable, reversed 				(cooldown)
	-- count																		(stack)
	-- alpha
	-- svc, r, g, b, a                    			(svc - true if we change vertex info)
	local visible, texture, start, duration, enable, reversed, count, alpha, svc, r, g, b, a = self.exec()
	
	-- hide when not visible
	if not visible then
		-- check if expiration alert ran 
		if self.hasAlerts == 1 and self.alerts.expiration then
			local a = self.alerts.expiration
			if a.last > a.timeLeft then
				a.last = 0
				modAlerts:Play(a.alertIndex, self.lastTexture, a.sound)
			end
		end
		self:FakeHide()
		return
	end
	
	-- texture
	if self.lastTexture ~= texture then
		self.elements.texMain:SetTexture(texture)
		self.lockTex:SetTexture(texture)
		self.lastTexture = texture
	end
	
	-- cooldown
	local e = self.elements.cooldown
	reversed = reversed or false
	if self.lastReversed ~= reversed then
		e:SetReverse(reversed)
		self.lastReversed = reversed
	end
	
	-- TODO
	-- check if this is working properly, don't want to miss timers
	if start ~= self.lastStart then
		CooldownFrame_SetTimer(e, start, duration, enable)
		self.lastStart = start
	end
	
	
	-- stack
	e = self.elements.stack
	if count then
		e:SetText(count)
		e:Show()
	else
		e:Hide()
	end
	
	-- SetVertexColor
	if svc then
		self.elements.texMain:SetVertexColor(r, g, b, a)
	else
		if self.lastSCV then	-- not changing vertex but call before was used, so reset to 1
			self.elements.texMain:SetVertexColor(1, 1, 1, 1)
		end
	end
	self.lastSVC = svc
	
	if self.lastAlpha ~= alpha then
		self.elements:SetAlpha(alpha or 1)
		self.lastAlpha = alpha
	end
	
	-- alert handling
	if self.hasAlerts == 1 then
		local v 
		if duration and duration > 0 then v = duration + start - GetTime()
		else v = -1 end
		-- expiration alert
		if self.alerts.expiration then
			local a = self.alerts.expiration
			if v <= a.timeLeft and a.timeLeft < a.last then
				modAlerts:Play(a.alertIndex, texture, a.sound)
			end
			a.last = v
		end
		-- start alert
		if self.alerts.start then
			local a = self.alerts.start
			if v ~= -1 and a.last == -1 then
				modAlerts:Play(a.alertIndex, self.lastTexture, a.sound)
			end
			a.last = v
		end
	end

	self:FakeShow()
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
	-- create a child frame that holds all the elements and it's hidden/shown instead of main one that has update function
	self.elements = CreateFrame("Frame", nil, self)

	-- todo create only what's needed
	self.elements.texMain = self.elements:CreateTexture(nil, "BORDER")
	self.elements.texMain:SetAllPoints()
	-- cooldown
	self.elements.cooldown = CreateFrame("Cooldown", nil, self.elements)
	self.elements.cooldown:SetAllPoints(self.elements)
	
	-- normal and gloss on top of cooldown
	local skinFrame = CreateFrame("Frame", nil, self.elements)
	skinFrame:SetFrameLevel(self.elements.cooldown:GetFrameLevel() + 1)
	self.elements.texNormal = skinFrame:CreateTexture(nil, "ARTWORK")
	self.elements.texGloss = skinFrame:CreateTexture(nil, "OVERLAY")
	
	-- put the fonts on a frame and scale it?
	self.elements.stackFrame = CreateFrame("Frame", nil, self.elements)
	self.elements.stackFrame:SetFrameLevel(self.elements.cooldown:GetFrameLevel() + 2)
	self.elements.stackFrame:SetWidth(STACK_DEFAULT_WIDTH)
	self.elements.stackFrame:SetHeight(STACK_DEFAULT_HEIGHT)
	
	self.elements.stack = self.elements.stackFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	self.elements.stack:SetJustifyH("RIGHT")
	self.elements.stack:SetPoint("RIGHT", self.elements.stackFrame, "RIGHT", 0, 0)
	
	-- lock and edit textures on a separate frame
	self.toolbox = CreateFrame("Frame", nil, self)
	self.toolbox:Hide()
	self.toolbox:SetFrameLevel(self.elements:GetFrameLevel() + 3)
	
	self.label = self.toolbox:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	self.label:SetPoint("BOTTOMLEFT", self.elements.texMain, "TOPLEFT", 0, 1)
	local fontFace, _, fontFlags = self.label:GetFont()
	self.label:SetFont(fontFace, 6, fontFlags)
	
	-- lock
	self.lockTex = self.toolbox:CreateTexture(nil, "BACKGROUND")
	self.lockTex:SetAllPoints(self)
	self.lockTex:SetTexture("Interface\\Icons\\ABILITY_SEAL")
	
	
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
	self:SetScript("OnDragStop", OnDragStop)
end

-- enables control of the frame
function prototype:Unlock()
  self:EnableMouse(true)
  self.toolbox:Show()
end

-- disables control of the frame
function prototype:Lock()
  self:EnableMouse(false)
  self.toolbox:Hide()
end


-- button facade helper functions
local function BFPosition(e, p, layer, scalex, scaley)
	e:ClearAllPoints()
	e:SetWidth(scalex * (layer.Width or 36))
	e:SetHeight(scaley * (layer.Height or 36))
	e:SetPoint("CENTER", p, "CENTER", scalex * (layer.OffsetX or 0), scaley * (layer.OffsetY or 0))
end
local function BFTexture(t, tx, layer, scalex, scaley)
	if not layer then t:Hide() return end
	t:Show()
	t:SetTexture(layer.Texture or "")
	BFPosition(t, tx, layer, scalex, scaley)
	t:SetBlendMode(layer.BlendMode or "BLEND")
	t:SetVertexColor(unpack(layer.Color or { 1, 1, 1, 1 }))
	t:SetTexCoord(unpack(layer.TexCoords or { 0, 1, 0, 1 }))
end
-- apply a button facade skin
local function ApplyButtonFacadeSkin(self, bfSkin, bfGloss)
	skin = (lbf:GetSkins())[bfSkin]
	if not skin then
		-- try with blizzard
		skin = lbf:GetSkins().Blizzard
		
		if not skin then
			-- cant find the skin so apply default non bf
			self:ApplyMySkin()
			return
		end
	end
	
	local scalex = self.db.width / (skin.Icon.Width or 36)
	local scaley = self.db.height / (skin.Icon.Height or 36)
	
	-- adjust tex coords for icon
	self.elements.texMain:SetTexCoord(unpack(skin.Icon.TexCoords or { 0, 1, 0, 1 }))
	
	-- normal, gloss textures
	BFTexture(self.elements.texNormal, self.elements, skin.Normal, scalex, scaley) 
	BFTexture(self.elements.texGloss, self.elements, skin.Gloss, scalex, scaley)
	self.elements.texGloss:SetAlpha(bfGloss / 100)
	
	-- rest of elements
	local layer, e
	-- cooldown
	if skin["Cooldown"] then BFPosition(self.elements.cooldown, self.elements, skin["Cooldown"], scalex, scaley) end
	
	-- stack is scaled so use default values
	if skin.Count then
		self.elements.stackFrame:SetWidth(skin.Count.Width or 36)
		self.elements.stackFrame:SetHeight(skin.Count.Height or 36)
		self.elements.stackFrame:SetPoint("CENTER", self, "CENTER", skin.Count.OffsetX or 0, skin.Count.OffsetY or 0)
	else
		self.elements.stackFrame:SetWidth(STACK_DEFAULT_WIDTH)
		self.elements.stackFrame:SetHeight(STACK_DEFAULT_HEIGHT)
		self.elements.stackFrame:SetPoint("CENTER", self, "CENTER", STACK_DEFAULT_OFFSETX, STACK_DEFAULT_OFFSETY)
	end
end

-- apply a rudimentary skin
local function ApplyMySkin(self)
	local t = self.elements.texNormal
	local scalex = self.db.width / 34
	local scaley = self.db.height / 34
	
	t:SetTexture("Interface\\AddOns\\clcInfo\\textures\\IconNormal")
	t:ClearAllPoints()
	t:SetWidth(scalex * 36)
	t:SetHeight(scaley * 36)
	t:SetPoint("CENTER", self.elements)
	t:Show()
	
	t = self.elements.texGloss
	t:Hide()
	
	self.elements.cooldown:SetAllPoints(self.elements)
	
	self.elements.stackFrame:SetWidth(STACK_DEFAULT_WIDTH)
	self.elements.stackFrame:SetHeight(STACK_DEFAULT_HEIGHT)
	self.elements.stackFrame:SetPoint("CENTER", self, "CENTER", STACK_DEFAULT_OFFSETX, STACK_DEFAULT_OFFSETY)
end

-- try to position on grid
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

-- adjust the elements according to the settings
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
	
	-- select the skin from template/grid/self
	local skinType, bfSkin, bfGloss, g
	if onGrid and self.db.skinSource == "Grid" then
		g = clcInfo.display.grids.active[self.db.gridId].db.skinOptions.icons
	elseif self.db.skinSource == "Template" then
		g = clcInfo.activeTemplate.skinOptions.icons
	else
		g = self.db.skin
	end
	skinType, bfSkin, bfGloss = g.skinType, g.bfSkin, g.bfGloss

	-- apply the skin
	if skinType == "Button Facade" and lbf then
		ApplyButtonFacadeSkin(self, bfSkin, bfGloss)
	elseif skinType == "BareBone" then
		self.elements.texGloss:Hide()
		self.elements.texNormal:Hide()
	else
		ApplyMySkin(self)
	end
	
	-- scale the stack text
	self.elements.stackFrame:SetScale(self.db.height / ICON_DEFAULT_HEIGHT)
end

-- update the exec function and perform cleanup
function prototype:UpdateExec()
	-- updates per second
	self.freq = 1/self.db.ups
	self.elapsed = 100 -- force instant update

	local err
	-- exec
	self.exec, err = loadstring(self.db.exec)
	-- apply DoNothing if we have an error
	if not self.exec then
		self.exec = loadstring("")
		print("code error:", err)
		print("in:", self.db.exec)
	end
  setfenv(self.exec, clcInfo.env)
  
  -- reset alpha
  self.elements:SetAlpha(1)
  
  -- cleanup if required
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
  	f()
  else
  	print("alert code error:", err)
  	print("in:", self.db.execAlert)
  end
  
  self:SetScript("OnUpdate", OnUpdate)
end

-- show/hide only elements
function prototype:FakeShow() self.elements:Show() end
function prototype:FakeHide() self.elements:Hide() end

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

-- create or take from cache and initialize
function mod:New(index)
	-- see if we have stuff in cache
	local icon = table.remove(self.cache)
	if icon then
		-- cache hit
		icon.index = index
		icon.db = db[index]
		self.active[index] = icon
		icon:Show()
	else
		-- cache miss
		icon = CreateFrame("Frame", nil, clcInfo.mf)	-- parented by the mother frame
		setmetatable(icon, { __index = prototype })
		icon.index = index
		icon.db = db[index]
		self.active[index] = icon
		icon:SetFrameLevel(clcInfo.frameLevel + 2)
		icon:Init()
	end
	
	-- change the text of the label here since it's done only now
	icon.label:SetText("Icon" .. icon.index)
	
	icon:UpdateLayout()
	icon:UpdateExec()
	if self.unlock then
  	icon:Unlock()
  end
end

-- send all active icons to cache
function mod:ClearElements()
	local icon
	for i = 1, getn(self.active) do
		-- remove from active
		icon = table.remove(self.active)
		if icon then
			-- hide (also disables the updates)
			icon:Hide()
			-- run cleanup functions
			if icon.ExecCleanup then 
				icon.ExecCleanup()
  			icon.ExecCleanup = nil
  		end
			-- add to cache
			table.insert(self.cache, icon)
		end
	end
end

-- read data from config and create the icons
function mod:InitElements()
	if not clcInfo.activeTemplate then return end

	db = clcInfo.activeTemplate.icons
	
	-- create them all over again :D
	for index in ipairs(db) do
		self:New(index)
	end
end

-- default skin options
function mod:GetDefaultSkin()
	return {
		skinType = "Default",
		bfSkin = "Blizzard",
		bfGloss = 0,
	}
end

-- default options
function mod:GetDefault()
	local x = (UIParent:GetWidth() - ICON_DEFAULT_WIDTH) / 2 * UIParent:GetScale()
	local y = (UIParent:GetHeight() - ICON_DEFAULT_HEIGHT) / 2 * UIParent:GetScale()
	
	return {
		x = x,
		y = y,
		point = "BOTTOMLEFT",
		relativeTo = "UIParent",
    relativePoint = "BOTTOMLEFT",
		width = ICON_DEFAULT_WIDTH,
		height = ICON_DEFAULT_HEIGHT,
		exec = "",
		alertExec = "",
		ups = 5,
		gridId = 0,
		gridX = 1,	-- column
		gridY = 1,	-- row
		sizeX = 1, 	-- size in cells
		sizeY = 1, 	-- size in cells
		
		skinSource = "Template",	-- template, grid, self
		skin = mod:GetDefaultSkin(),
	}
end
function mod:Add(gridId)
	local data = mod:GetDefault()
	gridId = gridId or 0
	data.gridId = gridId
	if gridId > 0 then data.skinSource = "Grid" end
	
	-- must be called after init
	table.insert(db, data)
	self:New(getn(db))
end


-- global lock/unlock/update
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







