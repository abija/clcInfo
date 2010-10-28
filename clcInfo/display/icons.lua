local mod = clcInfo:RegisterDisplayModule("icons")  -- register the module
-- special options
mod.hasSkinOptions = true
mod.onGrid = true

-- button facade
local lbf = clcInfo.lbf

local prototype = CreateFrame("Frame")  -- base frame object
prototype:Hide()


mod.active = {}  -- active objects
mod.cache = {}  -- cache of objects, to not make unnecesary frames

local db

-- some defaults used for skinning
local ICON_DEFAULT_WIDTH 			= 36
local ICON_DEFAULT_HEIGHT			= 36
local defaultFontFace, defaultFontSize, defaultFontFlags = _G["NumberFontNormal"]:GetFont()

-- local bindings
local GetTime = GetTime
local pcall = pcall

local modAlerts = clcInfo.display.alerts

---------------------------------------------------------------------------------
-- icon prototype
---------------------------------------------------------------------------------

-- called for each of the icons
local function OnUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	
	if self.waitForCooldownEffect then
		if self.elapsed > 0.05 then
			self.waitForCooldownEffect = false
			self.elapsed = self.freq -- force update
			CooldownFrame_SetTimer(self.elements.cooldown, self.lastStart, self.lastDuration, self.lastEnable)
		else
			return
		end
	end
	
	if self.elapsed < self.freq then return end
	-- manual set updates per second for dev testing
	-- if self.elapsed < 0.2 then return end
	self.elapsed = 0
	
	-- expose the object
	clcInfo.env.___e = self
	
	-- visible
	-- texture
	-- start, duration, enable, reversed 				(cooldown)
	-- count																		
	-- alpha
	-- svc, r, g, b, a                    			(svc - true if we change vertex info)
	local status, visible, texture, start, duration, enable, reversed, count, alpha, svc, r, g, b, a = pcall(self.exec)
	if not status then
		-- display the first error met into the behavior tab
		-- also announce the user we got an error
		if self.errExec == "" then
			local en = self.db.udLabel
			if en == "" then en = "clcInfo.Icon" .. self.index end
			print( en ..":", visible)
			self.errExec = visible
			clcInfo:UpdateOptions() -- request update of the tab
		end
		-- stop execution directly?
		visible = false
	end
	
	-- fix the nil vars that you don't want nill
	duration = duration or 0
	
	-- hide when not visible
	if not visible then
		if self.elements:IsShown() then
			-- set lastDuration to 0
			self.lastDuration = 0
			self.lastStart = 0
			CooldownFrame_SetTimer(self.elements.cooldown, 0, 0, self.lastEnable or 1)
			
			-- check for alerts
			if self.hasAlerts == 1 then
				-- expiration alert
				if self.alerts.expiration then
					local a = self.alerts.expiration
					if a.last > a.timeLeft then
						a.last = 0
						modAlerts.Play(a.alertIndex, self.lastTexture, a.sound)
					end
				end
				-- start alert
				if self.alerts.start then
					self.alerts.start.last = -1
				end
			end
			self.elements:Hide() -- IMPORTANT, if you change FakeHide change this too
		end
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
	if duration > 0 then
		if start ~= self.lastStart or duration ~= self.lastDuration then
			-- e:StopAnimating()
			if self.lastDuration > 2 then
				self.waitForCooldownEffect = true
			else
				CooldownFrame_SetTimer(e, start, duration, enable)
			end
			self.lastStart = start
			self.lastDuration = duration
			self.lastEnable = enable
		end
	else
		self.lastDuration = 0
	end
	
	
	-- count
	e = self.elements.count
	if count then
		e:SetText(count)
		e:Show()
	else
		e:Hide()
	end
	
	-- SetVertexColor
	svc = svc or false
	if svc then
		self.elements.texMain:SetVertexColor(r, g, b, a)
	else
		if self.lastSCV then	-- not changing vertex but call before was used, so reset to 1
			self.elements.texMain:SetVertexColor(1, 1, 1, 1)
		end
	end
	self.lastSVC = svc
	
	alpha = alpha or 1
	if self.lastAlpha ~= alpha then
		self.elements:SetAlpha(alpha)
		self.lastAlpha = alpha
	end
	
	-- alert handling
	if self.hasAlerts == 1 then
		local v 
		if duration > 0 then v = duration + start - GetTime()
		else v = -1 end
		-- expiration alert
		if self.alerts.expiration then
			local a = self.alerts.expiration
			if v <= a.timeLeft and a.timeLeft < a.last then
				modAlerts.Play(a.alertIndex, texture, a.sound)
			end
			a.last = v
		end
		-- start alert
		if self.alerts.start then
			local a = self.alerts.start
			if (v ~= -1 and a.last == -1) or (v > 0 and v > a.last) then
				modAlerts.Play(a.alertIndex, self.lastTexture, a.sound)
			end
			a.last = v
		end
	end

	if not self.elements:IsShown() then self.elements:Show() end
end
function prototype:DoUpdate()
	OnUpdate(self, 100)
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
	self.etype = "icon"
	-- event dispatcher
	self:SetScript("OnEvent", clcInfo.DisplayElementsEventDispatch)
	
	-- create a child frame that holds all the elements and it's hidden/shown instead of main one that has update function
	self.elements = CreateFrame("Frame", nil, self)

	-- todo create only what's needed
	self.elements.texMain = self.elements:CreateTexture(nil, "BORDER")
	-- cooldown
	self.elements.cooldown = CreateFrame("Cooldown", nil, self.elements)
	-- icon for omnicc pulse
	self.elements.icon = self.elements.texMain
	
	-- normal and gloss on top of cooldown
	local skinFrame = CreateFrame("Frame", nil, self.elements)
	skinFrame:SetFrameLevel(self.elements.cooldown:GetFrameLevel() + 1)
	self.elements.texNormal = skinFrame:CreateTexture(nil, "ARTWORK")
	self.elements.texGloss = skinFrame:CreateTexture(nil, "OVERLAY")
	
	self.elements.count = skinFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	self.elements.count:SetJustifyH("RIGHT")
	
	-- lock and edit textures on a separate frame
	self.toolbox = CreateFrame("Frame", nil, self)
	self.toolbox:Hide()
	self.toolbox:SetFrameLevel(self.elements:GetFrameLevel() + 3)
	
	self.label = self.toolbox:CreateFontString(nil, "OVERLAY", "GameFontHighlightExtraSmall")
	local fontFace, _, fontFlags = self.label:GetFont()
	self.label:SetFont(fontFace, 8, fontFlags)
	
	-- lock
	self.lockTex = self.toolbox:CreateTexture(nil, "BACKGROUND")
	self.lockTex:SetAllPoints(self)
	self.lockTex:SetTexture("Interface\\Icons\\ABILITY_SEAL")
	
	
	self:FakeHide()
	self:Show()

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

function prototype:UpdateEnabled()
	if self.db.enabled then
		clcInfo.UpdateExecEvent(self)	-- reenable event code
		self:SetScript("OnUpdate", OnUpdate)
	else
		self:UnregisterAllEvents()
		self:SetScript("OnUpdate", nil)
		self:FakeHide()
	end
end


-- button facade helper functions
local function BFPosition(e, p, layer, xScale, yScale)
	e:SetSize(xScale * (layer.Scale or 1) * (layer.Width or 36), yScale * (layer.Scale or 1) * (layer.Height or 36))
	e:ClearAllPoints()
	e:SetPoint("CENTER", p, "CENTER", xScale * (layer.Scale or 1) * (layer.OffsetX or 0), yScale * (layer.Scale or 1) * (layer.OffsetY or 0))
end
local function BFLayer(t, tx, layer, xScale, yScale)
	if not layer then t:Hide() return end
	t:Show()
	t:SetTexture(layer.Texture or "")
	BFPosition(t, tx, layer, xScale, yScale)
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
	
	local xScale = self.db.width / 36
	local yScale = self.db.height / 36
	
	-- main texture
	local t = self.elements.texMain
	local l = skin.Icon
	t:SetSize((l.Width or 36) * (l.Scale or 1) * xScale, (l.Height or 36) * (l.Scale or 1) * yScale)
	t:ClearAllPoints()
	t:SetPoint("CENTER", self.elements, "CENTER", xScale * (l.Scale or 1) * (l.OffsetX or 0), yScale * (l.Scale or 1) * (l.OffsetY or 0))
	self.elements.texMain:SetTexCoord(unpack(skin.Icon.TexCoords or { 0, 1, 0, 1 }))
	
	-- normal, gloss textures
	BFLayer(self.elements.texNormal, self.elements, skin.Normal, xScale, yScale) 
	BFLayer(self.elements.texGloss, self.elements, skin.Gloss, xScale, yScale)
	self.elements.texGloss:SetAlpha(bfGloss / 100)
	
	-- cooldown
	self.elements.cooldown:SetSize(self.db.width * xScale, self.db.height * yScale)
	if skin["Cooldown"] then BFPosition(self.elements.cooldown, self.elements, skin["Cooldown"], xScale, yScale) end
	
	-- adjust the text size
	local count = self.elements.count
	if skin.Count then
		l = skin.Count
		count:SetSize((l.Width or 36) * (l.Scale or 1) * xScale, (l.Height or 36) * (l.Scale or 1) * yScale)
		count:ClearAllPoints()
		count:SetPoint("CENTER", self.elements, "CENTER", xScale * (l.Scale or 1) * (l.OffsetX or 0), yScale * (l.Scale or 1) * (l.OffsetY or 0))
		count:SetFont(defaultFontFace, defaultFontSize * yScale * (l.Scale or 1), defaultFontFlags)
	else
		count:SetSize(40 * xScale, 10 * yScale)
		count:ClearAllPoints()
		count:SetPoint("CENTER", self.elements, "CENTER", -2 * xScale, -8 * yScale)
		local fontFamily, _, fontFlags = count:GetFont()
		count:SetFont(defaultFontFace, defaultFontSize * yScale, defaultFontFlags)
	end
end

-- apply a rudimentary skin
local function ApplyMySkin(self)
	local xScale = self.db.width / 36
	local yScale = self.db.height / 36

	local t = self.elements.texMain
	t:SetSize(34 * xScale, 34 * yScale)
	t:ClearAllPoints()
	t:SetPoint("CENTER", self.elements, "CENTER", 0, 0)
	t:SetTexCoord(0, 1, 0, 1)

	t = self.elements.texNormal
	
	t:SetTexture("Interface\\AddOns\\clcInfo\\textures\\IconNormal")
	t:SetSize(self.db.width, self.db.height)
	t:ClearAllPoints()
	t:SetPoint("CENTER", self.elements, "CENTER", 0, 0)
	t:Show()
	
	t = self.elements.texGloss
	t:Hide()
	
	local t = self.elements.cooldown
	t:SetSize(self.db.width, self.db.height)
	t:ClearAllPoints()
	t:SetPoint("CENTER", self.elements, "CENTER", 0, 0)
	
	-- adjust the text size
	local count = self.elements.count
	count:SetSize(40 * xScale, 10 * yScale)
	count:ClearAllPoints()
	count:SetPoint("CENTER", self.elements, "CENTER", -2 * xScale, -8 * yScale)
	count:SetFont(defaultFontFace, defaultFontSize * yScale, defaultFontFlags)
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
	
	self.label:ClearAllPoints()
	self.label:SetPoint("BOTTOMLEFT", self.elements, "TOPLEFT", 0, 1)
	
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
		ApplyMySkin(self)
		self.elements.texNormal:Hide()
	else
		ApplyMySkin(self)
	end
	
	-- change the text of the label
	local udl = self.db.udLabel
	if udl == "" then udl = "Icon" .. self.index end
	self.label:SetText(udl)
	
	-- enable/disable
	self:UpdateEnabled()
end

-- update the exec function and perform cleanup
function prototype:UpdateExec()
	clcInfo.UpdateExec(self)
  clcInfo.UpdateExecAlert(self)
  
  -- defaults
  self.waitForCooldownEffect = false
  self.lastDuration = 0
  self.elements:SetAlpha(1)
  self.lastAlpha = 1
  
  self:UpdateEnabled()
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
	local x = (UIParent:GetWidth() - ICON_DEFAULT_WIDTH) / 2
	local y = (UIParent:GetHeight() - ICON_DEFAULT_HEIGHT) / 2
	
	return {
		enabled = true,
		udLabel = "", -- user defined label
	
		x = x,
		y = y,
		point = "BOTTOMLEFT",
		relativeTo = "UIParent",
    relativePoint = "BOTTOMLEFT",
		width = ICON_DEFAULT_WIDTH,
		height = ICON_DEFAULT_HEIGHT,
		exec = "",
		alertExec = "",
		eventExec = "",
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







