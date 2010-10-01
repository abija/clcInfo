local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\display\\micons> " .. table.concat(t, " "))
end

-- button facade
local lbf = clcInfo.lbf

--[[
-- general info
-- micon -> spawns normal icons
-- onupdate is called on micon
-- the spawned icons have same skin
--]]

-- base icon
local iconPrototype = CreateFrame("Frame")
iconPrototype:Hide()

-- base micon
local prototype = CreateFrame("Frame")
prototype:Hide()

local mod = clcInfo:RegisterDisplayModule("micons")
-- special options
mod.hasSkinOptions = true


-- active objects
mod.active = {}
-- cache of objects, to not make unnecesary frames
mod.cache = {}
-- cache of icons that are used by the objects
-- their active list is hold by the object
mod.cacheIcons = {}			

local LSM = clcInfo.LSM

local db

--------------------------------------------------------------------------------
-- icon object
--------------------------------------------------------------------------------

function iconPrototype:Init()
	self.texMain = self:CreateTexture(nil, "BORDER")
	self.texMain:SetAllPoints()
	-- cooldown
	self.cooldown = CreateFrame("Cooldown", nil, self)
	self.cooldown:SetAllPoints(self)
	-- stack (make a special frame so it's on top of cooldown)
	local stackFrame = CreateFrame("Frame", nil, self)
	
	-- normal and gloss on top of the cooldown
	self.texNormal = stackFrame:CreateTexture(nil, "ARTWORK")
	self.texGloss = stackFrame:CreateTexture(nil, "OVERLAY")
	
	self.stack = stackFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	self.stack:SetJustifyH("RIGHT")
	
	self:Hide()
end

local function BFPosition(e, p, layer, scalex, scaley)
	e:ClearAllPoints()
	e:SetWidth(scalex * (layer.Width or 36))
	e:SetHeight(scaley * (layer.Width or 36))
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
function ApplyButtonFacadeSkin(self, bfSkin, bfGloss)
	local opt = self.parent.db

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
	
	local scalex = opt.width / (skin.Icon.Width or 36)
	local scaley = opt.height / (skin.Icon.Height or 36)
	
	-- adjust tex coords for icon
	self.texMain:SetTexCoord(unpack(skin.Icon.TexCoords or { 0, 1, 0, 1 }))
	
	-- normal, gloss textures
	BFTexture(self.texNormal, self, skin.Normal, scalex, scaley) 
	BFTexture(self.texGloss, self, skin.Gloss, scalex, scaley)
	self.texGloss:SetAlpha(bfGloss / 100)
	
	-- rest of elements
	local layer, e
	-- cooldown
	if skin["Cooldown"] then BFPosition(self.cooldown, self, skin["Cooldown"], scalex, scaley) end
end

function ApplyMySkin(self)
	local opt = self.parent.db

	local t = self.texNormal
	local scalex = opt.width / 34
	local scaley = opt.height / 34
	
	t:SetTexture("Interface\\AddOns\\clcInfo\\textures\\IconNormal")
	t:ClearAllPoints()
	t:SetWidth(scalex * 36)
	t:SetHeight(scaley * 36)
	t:SetPoint("CENTER", self)
	t:Show()
	
	t = self.texGloss
	t:Hide()
	
	self.cooldown:SetAllPoints(self)
end

function iconPrototype:UpdateLayout(i, skin)
	local opt = self.parent.db
	self:SetWidth(opt.width)
	self:SetHeight(opt.height)	
	
	self:ClearAllPoints()
	if opt.growth == "left" then
		self:SetPoint("BOTTOMRIGHT", self.parent, "BOTTOMRIGHT", (1 - i) * (opt.width + opt.spacing), 0)
	elseif opt.growth == "right" then
		self:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT", (i - 1) * (opt.width + opt.spacing), 0)
	elseif opt.growth == "up" then
		self:SetPoint("BOTTOMLEFT", self.parent, "BOTTOMLEFT", 0, (i - 1) * (opt.height + opt.spacing))
	else
		self:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, (1 - i) * (opt.height + opt.spacing))
	end
	
	-- stack
	local fontFace, _, fontFlags = self.stack:GetFont()
	self.stack:SetFont(fontFace, opt.height / 2.7, fontFlags)
	
	self.stack:ClearAllPoints()
	self.stack:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 2 * opt.width / 30, -2 * opt.height / 30)

	if skin.skinType == "Button Facade" and lbf then
		ApplyButtonFacadeSkin(self, skin.bfSkin, skin.bfGloss)
	elseif skinType == "BareBone" then
		self.texGloss:Hide()
		self.texNormal:Hide()
	else
		ApplyMySkin(self)
	end
end

--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- micon object
--------------------------------------------------------------------------------

-- TODO
-- check if caching data is worth it when they change a lot
function prototype:___AddIcon(id, texture, start, duration, enable, reversed, count, alpha, svc, r, g, b, a)
	-- another test for alpha
	-- TODO, see if this can be done better
	if alpha ~= nil and alpha == 0 then return end
	
	self.___dc = self.___dc + 1
	
	local icon
	if self.___dc > #self.___c then
		icon = self:New()
	else
		icon = self.___c[self.___dc]
	end
	
	-- texture
	icon.texMain:SetTexture(texture)
	
	-- cooldown
	local e = icon.cooldown
	if (enable == 1) and duration and duration > 0 then
		-- direction
		e:SetReverse(reversed)
		e:SetCooldown(start, duration)
		e:Show()
	else
		e:Hide()
	end
	
	-- stack
	local e = icon.stack
	if count then
		e:SetText(count)
		e:Show()
	else
		e:Hide()
	end
	
	-- SetVertexColor
	if svc then
		icon.texMain:SetVertexColor(r, g, b, a)
	else
		icon.texMain:SetVertexColor(1, 1, 1, 1)
	end
	
	-- alpha
	icon:SetAlpha(alpha or 1)
	
	icon:Show()
end


-- on update is used on the micon object
local function OnUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed < self.freq then return end
	
	self.elapsed = 0
		
	-- expose the object
	clcInfo.env.___e = self
	
	-- reset the counter for the data tables
	self.___dc = 0
	
	-- update data
	self.exec()
	
	
	if self.___dc < #self.___c then
		-- hide the extra icons
		for i = self.___dc + 1, #self.___c do
			self.___c[i]:Hide()
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
  self:HideIcons()
  self.___dc = 0
end

-- disables control of the frame
function prototype:Lock()
  self:EnableMouse(false)
  self.bg:Hide()
  self.label:Hide()
  self:SetScript("OnUpdate", OnUpdate)
end

-- display the elements according to the settings
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


function prototype:UpdateLayout()
	-- check if it's attached to some grid
	local onGrid = TryGridPositioning(self)
	
	if not onGrid then
		self:ClearAllPoints()
		self:SetWidth(self.db.width)
		self:SetHeight(self.db.height)
		self:SetPoint(self.db.point, self.db.relativeTo, self.db.relativePoint, self.db.x, self.db.y)
	end
	
	local skin
	if onGrid and self.db.skinSource == "Grid" then
		skin = clcInfo.display.grids.active[self.db.gridId].db.skinOptions.micons
	elseif self.db.skinSource == "Template" then
		skin = clcInfo.activeTemplate.skinOptions.micons
	else
		skin = self.db.skin
	end
	
	self.skin = skin
	
	-- update children
	self:UpdateIconsLayout()	
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
		self.exec = loadstring("")
		bprint("code error:", err)
		bprint("in:", self.db.exec)
	end
  setfenv(self.exec, clcInfo.env)
  
  self.externalUpdate = false
  if self.ExecCleanup then
  	self.ExecCleanup()
  	self.ExecCleanup = nil
  end
  
  -- release the icons
  self:ReleaseIcons()
end

-- caaaaaaaaaaaaaaaaaaareful
function prototype:Delete()
	-- delete the db entry
	-- rebuild frames
	table.remove(db, self.index)
	mod:ClearElements()
	mod:InitElements()
end

function prototype:New()
	-- see if we have stuff in cache
	local icon = table.remove(mod.cacheIcons)
	if not icon then
		-- cache miss
		icon = CreateFrame("Frame", nil, clcInfo.mf)	-- parented by the mother frame
		setmetatable(icon, { __index = iconPrototype })
		icon:SetFrameLevel(clcInfo.frameLevel + 2 + #self.___c + 1)
		icon:Init()
	end
	
	icon.parent = self
	
	self.___c[#self.___c + 1] = icon
	
	icon:UpdateLayout(#self.___c, self.skin)
	
	return icon
end

function prototype:ReleaseIcons()
	local icon
	local b = #self.___c
	for i = 1, b do
		icon = table.remove(self.___c)
		icon:Hide()
		table.insert(mod.cacheIcons, icon)
	end
end
function prototype:UpdateIconsLayout()
	for i = 1, #self.___c do
		self.___c[i]:UpdateLayout(i, self.skin)
	end
end
-- set children icons state
function prototype:HideIcons()
	for i = 1, #self.___c do
		self.___c[i]:Hide()
	end
end


---------------------------------------------------------------------------------
-- module functions
---------------------------------------------------------------------------------
function mod:New(index)
	-- see if we have stuff in cache
	local micon = table.remove(self.cache)
	if micon then
		-- cache hit
		micon.index = index
		micon.db = db[index]
		self.active[index] = micon
		micon:Show()
	else
		-- cache miss
		micon = CreateFrame("Frame", nil, clcInfo.mf)	-- parented by the mother frame
		setmetatable(micon, { __index = prototype })
		micon.index = index
		micon.db = db[index]
		self.active[index] = micon
		micon:SetFrameLevel(clcInfo.frameLevel + 2)
		micon:Init()
	end
	
	-- change the text of the label here since it's done only now
	micon.label:SetText("MIcon" .. micon.index)
	
	micon:UpdateLayout()
	micon:UpdateExec()
	
	if self.unlock then
  	micon:Unlock()
  end
end

-- send all active icons to cache
function mod:ClearElements()
	local micon, n
	n = #(self.active)
	for i = 1, n do
		-- remove from active
		micon = table.remove(self.active)
		if micon then
			-- run cleanup functions
			if micon.ExecCleanup then 
				micon.ExecCleanup()
  			micon.ExecCleanup = nil
  		end
			-- send children to cache too
			micon:ReleaseIcons()
			-- hide (also disables the updates)
			micon:Hide()
			-- add to cache
			table.insert(self.cache, micon)
		end
	end
end

-- read data from config and create the icons
-- IMPORTANT, always make sure you call clear first
function mod:InitElements()
	if not clcInfo.activeTemplate then return end

	db = clcInfo.activeTemplate.micons
	
	-- create them all over again :D
	for index in ipairs(db) do
		self:New(index)
	end
end


-- the bullcrap of skin related settings
-- same as for icons
mod.GetDefaultSkin = clcInfo.display.icons.GetDefaultSkin

-- micon stuff
function mod:GetDefault()
	local x = (UIParent:GetWidth() - 30) / 2 * UIParent:GetScale()
	local y = (UIParent:GetHeight() - 30) / 2 * UIParent:GetScale()
	
	return {
		growth = "up", -- up or down
		spacing = 1, -- space between icons
	
		x = x,
		y = y,
		point = "BOTTOMLEFT",
		relativeTo = "UIParent",
    relativePoint = "BOTTOMLEFT",
		width = 30,
		height = 30,
		exec = "",
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
	local data = mod.GetDefault()
	gridId = gridId or 0
	data.gridId = gridId
	if gridId > 0 then data.skinSource = "Grid" end
	
	-- must be called after init
	table.insert(db, data)
	self:New(getn(db))
end


-- TODO!
-- make sure cached icons are locked
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