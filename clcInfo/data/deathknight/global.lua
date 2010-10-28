-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "DEATHKNIGHT" then return end

local version = 2

local defaults = {
	moveRB = false,
	hideBlizzRB = false,
	-- paladin power bar coords
	rbX = 0,
	rbY = 0,
	rbPoint = "CENTER",
  rbRelativePoint = "CENTER",
	rbScale = 1,
	rbAlpha = 1,
	
	version = version,
}

-- lower case module name
local modName = "global"

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule(modName)
local db -- it's per template based
local emod = clcInfo.env -- functions visible to exec should be attached to this

local myrb -- my runepower bar
mod.locked = true

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleTDB(modName, defaults)
	if db then
		if not db.version or db.version < version then
			-- fix stuff
			clcInfo.AdaptConfigAndClean("globalTDB", db, defaults)
			db.version = version
		end
		
		mod.UpdateRBar()
	else
		if myrb then myrb:Hide() end
	end
end
mod.OnTemplatesUpdate = mod.OnInitialize

function mod.UpdateRBar()
	if db.moveRB then
		if not myrb then mod.CreateRB() end
	
		myrb:EnableMouse(not mod.locked)
	
		myrb:Show()
		myrb:ClearAllPoints()
		myrb:SetScale(db.rbScale)
		myrb:SetAlpha(db.rbAlpha)
		myrb:SetPoint("CENTER", UIParent, "CENTER", db.rbX, db.rbY)
	else
		if myrb then myrb:Hide() end
	end
	
	if db.hideBlizzRB then
		RuneFrame:Hide()
		RuneFrame:UnregisterAllEvents()
		RuneFrame:SetScript("OnShow", function(self) self:Hide() end)
	else
		RuneFrame:SetScript("OnShow", nil)
		RuneFrame:Show()
		RuneFrame_OnLoad(RuneFrame)
	end
end

--------------------------------------------------------------------------------
-- create a rune bar similar to blizzard's xml code
--------------------------------------------------------------------------------
-- rewrite on event function because it uses the buttons from the other frame

local function RB_OnEvent(self, event, ...)
	local MAX_RUNES = 6
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		for i=1,MAX_RUNES do
			local runeButton = _G["clcInfoRuneButton"..i]
			if runeButton then
				RuneButton_Update(runeButton, i, true)
			end
		end
	elseif ( event == "RUNE_POWER_UPDATE" ) then
		local runeIndex, isEnergize = ...
		if runeIndex and runeIndex >= 1 and runeIndex <= MAX_RUNES  then 
			local runeButton = _G["clcInfoRuneButton"..runeIndex]
			local cooldown = _G[runeButton:GetName().."Cooldown"]
			
			local start, duration, runeReady = GetRuneCooldown(runeIndex)
			
			if not runeReady  then
				if start then
					CooldownFrame_SetTimer(cooldown, start, duration, 1)
				end
				runeButton.energize:Stop()
			else
				cooldown:Hide()
				runeButton.shine:SetVertexColor(1, 1, 1)
				RuneButton_ShineFadeIn(runeButton.shine)
			end
			
			if isEnergize  then
				runeButton.energize:Play()
			end
		else 
			assert(false, "Bad rune index")
		end
	elseif ( event == "RUNE_TYPE_UPDATE" ) then
		local runeIndex = ...
		if ( runeIndex and runeIndex >= 1 and runeIndex <= MAX_RUNES ) then
			RuneButton_Update(_G["clcInfoRuneButton"..runeIndex], runeIndex)
		end
	end
end

function mod.CreateRB()
	myrb = CreateFrame("Frame", "clcInfoRuneFrame", clcInfo.mf)
	myrb:SetFrameLevel(clcInfo.frameLevel + 2)
	myrb:SetSize(123, 18)
	myrb:SetFrameStrata("MEDIUM")
	
	-- Rune order is 1,2,5,6,3,4  which coresponds to Blood, Blood, Frost, Frost, Unholy, Unholy
	local b = CreateFrame("Button", "clcInfoRuneButton1", myrb, "RuneButtonIndividualTemplate")
	b:SetPoint("LEFT", "clcInfoRuneFrame", "LEFT", 0, 0)
	b:SetFrameStrata("LOW")
	RuneButton_OnLoad(b)
	b:EnableMouse(false)
	
	b = CreateFrame("Button", "clcInfoRuneButton2", myrb, "RuneButtonIndividualTemplate")
	b:SetPoint("LEFT", "clcInfoRuneButton1", "RIGHT", 3, 0)
	b:SetFrameStrata("LOW")
	RuneButton_OnLoad(b)
	b:EnableMouse(false)
	
	b = CreateFrame("Button", "clcInfoRuneButton5", myrb, "RuneButtonIndividualTemplate")
	b:SetPoint("LEFT", "clcInfoRuneButton2", "RIGHT", 3, 0)
	b:SetFrameStrata("LOW")
	RuneButton_OnLoad(b)
	b:EnableMouse(false)
	
	b = CreateFrame("Button", "clcInfoRuneButton6", myrb, "RuneButtonIndividualTemplate")
	b:SetPoint("LEFT", "clcInfoRuneButton5", "RIGHT", 3, 0)
	b:SetFrameStrata("LOW")
	RuneButton_OnLoad(b)
	b:EnableMouse(false)
	
	b = CreateFrame("Button", "clcInfoRuneButton3", myrb, "RuneButtonIndividualTemplate")
	b:SetPoint("LEFT", "clcInfoRuneButton6", "RIGHT", 3, 0)
	b:SetFrameStrata("LOW")
	RuneButton_OnLoad(b)
	b:EnableMouse(false)
	
	b = CreateFrame("Button", "clcInfoRuneButton4", myrb, "RuneButtonIndividualTemplate")
	b:SetPoint("LEFT", "clcInfoRuneButton3", "RIGHT", 3, 0)
	b:SetFrameStrata("LOW")
	RuneButton_OnLoad(b)
	b:EnableMouse(false)
	
	myrb:Hide()
	RuneFrame_OnLoad(myrb)
	myrb:SetScript("OnEvent", RB_OnEvent)
	RB_OnEvent(myrb, "PLAYER_ENTERING_WORLD")
	
	-- register for drag
	myrb:SetMovable(true)
	myrb:RegisterForDrag("LeftButton")
	myrb:SetScript("OnDragStart", function(self)
      self:StartMoving()
  end)
	myrb:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		db.rbPoint, _, db.rbRelativePoint, db.rbX, db.rbY = self:GetPoint()
    -- update the data in options also
    clcInfo:UpdateOptions()
	end)
end
--------------------------------------------------------------------------------
