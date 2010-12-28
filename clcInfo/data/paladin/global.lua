-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local version = 4

local defaults = {
	movePPBar = false,
	hideBlizPPB = false,
	-- paladin power bar coords
	ppbX = 0,
	ppbY = 0,
	ppbPoint = "CENTER",
  ppbRelativePoint = "CENTER",
	ppbScale = 1,
	ppbAlpha = 1,
	
	version = version,
}

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule("global")
local db -- ! it's a tdb, change if needed
-- functions visible to exec should be attached to this
local emod = clcInfo.env

local myppb -- my hp bar
mod.locked = true

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleTDB("global", defaults)
	if db then
		if not db.version or db.version < version then
			-- fix stuff
			clcInfo.AdaptConfigAndClean("globalTDB", db, defaults)
			db.version = version
		end
		
		mod.UpdatePPBar()
	else
		if myppb then myppb:Hide() end
	end
end
mod.OnTemplatesUpdate = mod.OnInitialize

function mod.UpdatePPBar()
	if db.movePPBar then
		if not myppb then mod.CreatePPB() end
	
		myppb:ClearAllPoints()
		myppb:SetScale(db.ppbScale)
		myppb:SetAlpha(db.ppbAlpha)
		myppb:SetPoint("CENTER", UIParent, "CENTER", db.ppbX, db.ppbY)
		
		myppb:EnableMouse(not mod.locked)
		myppb:Show()
	else
		if myppb then
			myppb:Hide()
		end
	end
	
	if db.hideBlizPPB then
		PaladinPowerBar:Hide()
		PaladinPowerBar:UnregisterAllEvents()
		PaladinPowerBar:SetScript("OnShow", function(self) self:Hide() end)
	else
		PaladinPowerBar:SetScript("OnShow", nil)
		PaladinPowerBar:Show()
		PaladinPowerBar_OnLoad(PaladinPowerBar)
		PaladinPowerBar_Update(PaladinPowerBar)
	end
end

--------------------------------------------------------------------------------
--[[
	-- sov tracking
--]]
do
	local sovName, sovId, sovSpellTexture
	sovId = 31803
	sovName, _, sovSpellTexture = GetSpellInfo(sovId)						-- Censure
	
	local function ExecCleanup()
		emod.___e.___sovList = nil
	end

	function emod.MBarSoV(a1, a2, showStack, timeRight)
		-- setup the table for sov data
		if not emod.___e.___sovList then
			emod.___e.___sovList = {}
			emod.___e.ExecCleanup = ExecCleanup
		end
		
		local tsov = emod.___e.___sovList
	
		-- check target for sov
		local targetGUID
		if UnitExists("target") then
			targetGUID = UnitGUID("target")
			local j = 1
			local name, rank, icon, count, dispelType, duration, expires, caster = UnitDebuff("target", sovName, nil, "PLAYER")
			if name then
				-- found it
				if count > 0 and showStack then 
					if showStack == "before" then
						name = string.format("(%s) %s", count, UnitName("target"))
					else
						name = string.format("%s (%s)", UnitName("target"), count)
					end
				else
					name = UnitName("target")
				end
				tsov[targetGUID] = { name, duration, expires }
			end
		end
		
		-- go through the saved data
		-- delete the ones that expired
		-- display the rest
		local gt = GetTime()
		local value, tr, alpha
		for k, v in pairs(tsov) do
			-- 3 = expires
			if gt > v[3] then
				tsov[k] = nil
			else
				value = v[3] - gt
				if timeRight then tr = tostring(math.floor(value + 0.5))
				else tr = ""
				end
				if k == targetGUID then alpha = a1
				else alpha = a2
				end
				
				emod.___e:___AddBar(nil, alpha, nil, nil, nil, nil, sovSpellTexture, 0, v[2], value, "normal", v[1], "", tr)
			end
		end
	end
end

-- inquisition
function emod.IconInq(e)
	local _, _, _, _, _, dur, exp = UnitBuff("player", "Inquisition", nil, "PLAYER")
	if exp then 
	  if (exp - GetTime()) <= e then
	    return true, "Interface\\Icons\\spell_paladin_inquisition", (exp - dur), dur, 1, nil, nil, 0.5
	  end
	else
		return true, "Interface\\Icons\\spell_paladin_inquisition"
	end
end


--------------------------------------------------------------------------------
-- create a hp bar similar to blizzard's xml code
--------------------------------------------------------------------------------
local PPB_OnUpdate
do
	local lhp = -1
	PPB_OnUpdate = function()
		local hp = UnitPower( "player", SPELL_POWER_HOLY_POWER )
		if hp ~= lhp then
			lhp = hp
			if hp > 2 then myppb.rune3:SetAlpha(1) else myppb.rune3:SetAlpha(0) end
			if hp > 1 then myppb.rune2:SetAlpha(1) else myppb.rune2:SetAlpha(0) end
			if hp > 0 then myppb.rune1:SetAlpha(1) else myppb.rune1:SetAlpha(0) end
			
			if hp == MAX_HOLY_POWER then
				myppb.glow.pulse:Play()
			else
				myppb.glow:StopAnimating()
			end
		end
	end
end

function mod.CreatePPB()
	local tfile = [[Interface\AddOns\clcInfo\data\paladin\PaladinPowerTextures]]
	myppb = CreateFrame("Frame", "clcInfoPaladinPowerBar", clcInfo.mf)
	myppb:SetFrameLevel(clcInfo.frameLevel + 2)
	myppb:SetSize(136, 39)
	local t = myppb:CreateTexture("clcInfoPaladinPowerBarBG", "BACKGROUND", nil, -5)
	t:SetPoint("TOP")
	t:SetSize(136, 39)
	t:SetTexture(tfile)
	t:SetTexCoord(0.00390625, 0.53515625, 0.32812500, 0.63281250)
	-- glow
	myppb.glow = CreateFrame("Frame", "clcInfoPaladinPowerBarGlowBG", myppb)
	myppb.glow:SetAlpha(0)
	myppb.glow:SetAllPoints()
	t = myppb.glow:CreateTexture("clcInfoPaladinPowerBarGlowBGTexture", "BACKGROUND", nil, -1)
	t:SetPoint("TOP")
	t:SetSize(136, 39)
	t:SetTexture(tfile)
	t:SetTexCoord(0.00390625, 0.53515625, 0.00781250, 0.31250000)
	myppb.glow.pulse = myppb.glow:CreateAnimationGroup()
	myppb.glow.pulse:SetLooping("REPEAT")
	local a = myppb.glow.pulse:CreateAnimation("Alpha")
	a:SetChange(1) a:SetDuration(0.5) a:SetOrder(1)
	a = myppb.glow.pulse:CreateAnimation("Alpha")
	a:SetChange(-1) a:SetStartDelay(0.3) a:SetDuration(0.6) a:SetOrder(2)
	-- rune1
	myppb.rune1 = CreateFrame("Frame", "clcInfoPaladinPowerBarRune1", myppb)
	myppb.rune1:SetPoint("TOPLEFT", 21, -11)
	myppb.rune1:SetSize(36, 22)
	t = myppb.rune1:CreateTexture("clcInfoPaladinPowerBarRune1Texture", "OVERLAY", nil, -1)
	t:SetAllPoints()
	t:SetTexture(tfile)
	t:SetTexCoord(0.00390625, 0.14453125, 0.64843750, 0.82031250)
	myppb.rune1.activate = myppb.rune1:CreateAnimationGroup()
	a =	myppb.rune1.activate:CreateAnimation("Alpha")
	a:SetChange(1) a:SetDuration(0.2) a:SetOrder(1)
	myppb.rune1.activate:SetScript("OnFinished", function(self) self:GetParent():SetAlpha(1) end)
	myppb.rune1.deactivate = myppb.rune1:CreateAnimationGroup()
	a =	myppb.rune1.deactivate:CreateAnimation("Alpha")
	a:SetChange(-1) a:SetDuration(0.3) a:SetOrder(1)
	myppb.rune1.deactivate:SetScript("OnFinished", function(self) self:GetParent():SetAlpha(0) end)
	-- rune2
	myppb.rune2 = CreateFrame("Frame", "clcInfoPaladinPowerBarRune2", myppb)
	myppb.rune2:SetPoint("LEFT", "clcInfoPaladinPowerBarRune1", "RIGHT")
	myppb.rune2:SetSize(31, 17)
	t = myppb.rune2:CreateTexture("clcInfoPaladinPowerBarRune2Texture", "OVERLAY", nil, -1)
	t:SetAllPoints()
	t:SetTexture(tfile)
	t:SetTexCoord(0.00390625, 0.12500000, 0.83593750, 0.96875000)
	myppb.rune2.activate = myppb.rune2:CreateAnimationGroup()
	a =	myppb.rune2.activate:CreateAnimation("Alpha")
	a:SetChange(1) a:SetDuration(0.2) a:SetOrder(1)
	myppb.rune2.activate:SetScript("OnFinished", function(self) self:GetParent():SetAlpha(1) end)
	myppb.rune2.deactivate = myppb.rune2:CreateAnimationGroup()
	a =	myppb.rune2.deactivate:CreateAnimation("Alpha")
	a:SetChange(-1) a:SetDuration(0.3) a:SetOrder(1)
	myppb.rune2.deactivate:SetScript("OnFinished", function(self) self:GetParent():SetAlpha(0); end)
	-- rune3
	myppb.rune3 = CreateFrame("Frame", "clcInfoPaladinPowerBarRune3", myppb)
	myppb.rune3:SetPoint("LEFT", "clcInfoPaladinPowerBarRune2", "RIGHT", 2, -1)
	myppb.rune3:SetSize(27, 21)
	t = myppb.rune3:CreateTexture("clcInfoPaladinPowerBarRune2Texture", "OVERLAY", nil, -1)
	t:SetAllPoints()
	t:SetTexture(tfile)
	t:SetTexCoord(0.15234375, 0.25781250, 0.64843750, 0.81250000)
	myppb.rune3.activate = myppb.rune3:CreateAnimationGroup()
	a =	myppb.rune3.activate:CreateAnimation("Alpha")
	a:SetChange(1) a:SetDuration(0.2) a:SetOrder(1)
	myppb.rune3.activate:SetScript("OnFinished", function(self) self:GetParent():SetAlpha(1) end)
	myppb.rune3.deactivate = myppb.rune3:CreateAnimationGroup()
	a =	myppb.rune3.deactivate:CreateAnimation("Alpha")
	a:SetChange(-1) a:SetDuration(0.3) a:SetOrder(1)
	myppb.rune3.deactivate:SetScript("OnFinished", function(self) self:GetParent():SetAlpha(0); end)
	-- showanim
	myppb.showAnim = myppb:CreateAnimationGroup()
	a = myppb.showAnim:CreateAnimation("Alpha")
	a:SetChange(1) a:SetDuration(0.5) a:SetOrder(1)
	myppb.showAnim:SetScript("OnFinished", function(self) self:GetParent():SetAlpha(1.0) end)
	
	myppb:Hide()
	
	myppb:SetScript("OnUpdate", PPB_OnUpdate)
	
	-- register for drag
	myppb:SetMovable(true)
	myppb:RegisterForDrag("LeftButton")
	myppb:SetScript("OnDragStart", function(self)
      self:StartMoving()
  end)
	myppb:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		db.ppbPoint, _, db.ppbRelativePoint, db.ppbX, db.ppbY = self:GetPoint()
    -- update the data in options also
    clcInfo:UpdateOptions()
	end)
end
--------------------------------------------------------------------------------
