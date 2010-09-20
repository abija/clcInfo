local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\display\\icons> " .. table.concat(t, " "))
end

-- button facade
local lbf = clcInfo.lbf

-- base frame object
local prototype = CreateFrame("Frame")
prototype:Hide()

local mod = clcInfo.display.icons
-- active objects
mod.active = {}				
-- cache of objects, to not make unnecesary frames
-- delete frame == hide and send to cache
mod.cache = {}				

local db

---------------------------------------------------------------------------------
-- icon prototype
---------------------------------------------------------------------------------

-- TODO!
-- OPTIMIZE! OPTIMIZE! OPTIMIZE! OPTIMIZE! OPTIMIZE!
local function OnUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	-- if self.elapsed < self.freq then return end					-- manual updates per second for dev testing
	if self.elapsed < 0.1 then return end
	self.elapsed = 0
	
	-- needed vars to cover all posibilities
	-- visible
	-- texture
	-- start, duration, enable, reversed 				(cooldown)
	-- count																			(stack)
	-- alpha
	-- svc, r, g, b, a                    				(svc - true if we change vertex info)
	local visible, texture, start, duration, enable, reversed, count, alpha, svc, r, g, b, a = self.exec()
	if not visible then self:FakeHide() return end
	if alpha ~= nil and alpha == 0 then self:FakeHide() return end	-- hide on alpha = 0
	
	-- texture
	if texture ~= self.lastTexture then
		self.elements.texMain:SetTexture(texture)
		self.lockTex:SetTexture(texture)
	end
	
	---[[
	-- cooldown
	reversed = not not reversed
	local e = self.elements.cooldown
	if (enable == 1) and duration and duration > 0 then
		-- direction
		if self.lastReversed ~= reversed then
			if reversed then
				e:SetReverse(true)
				e:SetDrawEdge(true)
			else
				e:SetReverse(false)
				e:SetDrawEdge(false)
			end
			self.lastReversed = reversed
		end
		e:SetCooldown(start, duration)
		e:Show()
	else
		e:Hide()
	end
	
	-- stack
	local e = self.elements.stack
	if count then
		e:SetText(count)
		e:Show()
	else
		e:Hide()
	end
	
	-- SetVertexColor
	svc = not not svc
	if svc then
		self.elements.texMain:SetVertexColor(r, g, b, a)
	else
		if self.lastSCV then	-- not changing vertex but call before was used, so reset to 1
			self.elements.texMain:SetVertexColor(1, 1, 1, 1)
		end
	end
	self.lastSVC = svc
	
	-- alpha
	if alpha ~= nil then
		self.elements:SetAlpha(alpha)
	end

	self:FakeShow()
end



function prototype:Init()
	-- create a child frame that holds all the elements and it's hidden/shown instead of main one that has update function
	self.elements = CreateFrame("Frame", nil, self)

	-- todo create only what's needed
	self.elements.backdrop = {}
	self.elements.texBackground = self.elements:CreateTexture(nil, "BACKGROUND")
	self.elements.texMain = self.elements:CreateTexture(nil, "BORDER")
	self.elements.texMain:SetAllPoints()
	self.elements.texNormal = self.elements:CreateTexture(nil, "ARTWORK")
	self.elements.texGloss = self.elements:CreateTexture(nil, "OVERLAY")
	-- cooldown
	self.elements.cooldown = CreateFrame("Cooldown", nil, self.elements)
	self.elements.cooldown:SetAllPoints(self.elements)
	-- stack (make a special frame so it's on top of cooldown)
	local stackFrame = CreateFrame("Frame", nil, self.elements)
	self.elements.stack = stackFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	self.elements.stack:SetJustifyH("RIGHT")
	-- self.elements.stack:SetFrameLevel(self.elements.cooldown:GetFrameLevel() + 1)
	
	
	-- lock and edit textures on a separate frame
	self.toolbox = CreateFrame("Frame", nil, self)
	self.toolbox:Hide()
	self.toolbox:SetFrameLevel(self.elements:GetFrameLevel() + 2)
	
	self.label = self.toolbox:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	self.label:SetPoint("BOTTOMLEFT", self.elements.texMain, "TOPLEFT", -2, 2)
	
	-- lock
	self.lockTex = self.toolbox:CreateTexture(nil, "BACKGROUND")
	self.lockTex:SetAllPoints(self)
	self.lockTex:SetTexture("Interface\\Icons\\ABILITY_SEAL")
	
	
	self:FakeHide()
	self:Show()
	self:SetScript("OnUpdate", OnUpdate)	
	
	-- last vars
	self.lastTexture = nil
	self.lastReversed = false
	self.lastSVC = false	-- set vertex color
	

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

--[[
Unlock()
  enables control of the frame
--]]
function prototype:Unlock()
  self:EnableMouse(true)
  self.toolbox:Show()
end

--[[
Lock()
  disables control of the frame
--]]
function prototype:Lock()
  self:EnableMouse(false)
  self.toolbox:Hide()
end


-- TODO! Not only square
-- TODO! also register callback support for the skins loaded after our addon
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
function prototype:ApplyButtonFacadeSkin(bfSkin, bfGloss)
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
	-- not stack
	-- if skin["Count"] then BFPosition(self.elements.stack, self.elements, skin["Count"], scalex, scaley) end
end

function prototype:ApplyMySkin()
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
	--[[
	t:SetTexture("Interface\\AddOns\\clcInfo\\textures\\IconGloss")
	t:ClearAllPoints()
	t:SetWidth(scalex * 40)
	t:SetHeight(scaley * 40)
	t:SetPoint("CENTER", self.elements)
	t:Show()
	--]]
	
	self.elements.cooldown:SetAllPoints(self.elements)
	--[[
	self.elements.stack:ClearAllPoints()
	self.elements.stack:SetWidth(scalex * 16)
	self.elements.stack:SetWidth(scaley * 16)
	self.elements.stack:SetPoint("BOTTOMRIGHT", self.elements, "BOTTOMRIGHT", -1, 1)
	--]]
end

--[[
UpdateLayout()
  apply settings
--]]
-- find a way to translate the positions between on grid and not on grid?
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
	self.db.height = g.cellHeight* self.db.sizeY + g.spacingY * (self.db.sizeY - 1)
	self:ClearAllPoints()
	self:SetWidth(self.db.width)
	self:SetHeight(self.db.height)
	
	-- position
	local x = 10 + g.cellWidth * (self.db.gridX - 1) + g.spacingX * (self.db.gridX - 1)
	local y = 10 + g.cellHeight * (self.db.gridY - 1) + g.spacingY * (self.db.gridY - 1)
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
	
	self.elements:ClearAllPoints()
	self.elements:SetAllPoints(self)
	
	-- stack
	local fontFace, _, fontFlags = self.elements.stack:GetFont()
	self.elements.stack:SetFont(fontFace, self.db.height / 2.7, fontFlags)
	
	self.elements.stack:ClearAllPoints()
	self.elements.stack:SetPoint("BOTTOMRIGHT", self.elements, "BOTTOMRIGHT", 2 * self.db.width / 30, -2 * self.db.height / 30)
	
	-- get the grid skin if on a grid
	local skinType, bfSkin, bfGloss, g
	if onGrid then g = clcInfo.display.grids.active[self.db.gridId].db
	else g = clcInfo.activeTemplate.iconOptions end
	skinType, bfSkin, bfGloss = g.skinType, g.bfSkin, g.bfGloss

	if skinType == "Button Facade" and lbf then
		self:ApplyButtonFacadeSkin(bfSkin, bfGloss)
	else
		self:ApplyMySkin()
	end
end

function prototype:UpdateExec()
	-- updates per second
	self.freq = 1/self.db.ups
	self.elapsed = 0

	-- exec
	self.exec = loadstring(self.db.exec)
  setfenv(self.exec, clcInfo.env)
  
  -- reset alpha
  self.elements:SetAlpha(1)
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
	mod:InitIcons()
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

-- read data from config and create the icons
function mod:InitIcons()
	-- send all active icons to cache
	local icon
	for i = 1, getn(self.active) do
		-- remove from active
		icon = table.remove(self.active)
		if icon then
			-- hide (also disables the updates)
			icon:Hide()
			-- add to cache
			table.insert(self.cache, icon)
		end
	end
	
	if not clcInfo.activeTemplate then return end

	db = clcInfo.activeTemplate.icons
	
	-- create them all over again :D
	for index in ipairs(db) do
		self:New(index)
	end
end

function mod:AddIcon()
	local x = (UIParent:GetWidth() - 30) / 2 * UIParent:GetScale()
	local y = (UIParent:GetHeight() - 30) / 2 * UIParent:GetScale()

	local data = {
		x = x,
		y = y,
		point = "BOTTOMLEFT",
		relativeTo = "UIParent",
    relativePoint = "BOTTOMLEFT",
		width = 30,
		height = 30,
		exec = "return DoNothing()",
		ups = 10,
		gridId = 0,
		gridX = 1,	-- column
		gridY = 1,	-- row
		sizeX = 1, 	-- size in cells
		sizeY = 1, 	-- size in cells
	}
	-- must be called after init
	table.insert(db, data)
	self:New(getn(db))
end


-- TODO!
-- make sure cached icons are locked
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







