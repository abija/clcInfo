-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local defaults = {
	movePPBar = false,
	hideBlizPPB = false,
	-- paladin power bar coords
	ppbX = 0,
	ppbY = 0,
	ppbScale = 1,
	ppbAlpha = 1,
	
	version = 1,
}

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule("global")
local db -- ! it's a tdb, change if needed
-- functions visible to exec should be attached to this
local emod = clcInfo.env

local myppb -- my hp bar

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleTDB("global", defaults)
	if db then
		-- small fix
		-- major changes should be handled in another way
		if not db.ppbAlpha then db.ppbAlpha = 1 end
		if not db.version then db.version = 1 end
		
		if not myppb then mod.CreatePPB() end
		
		mod.UpdatePPBar()
	end
end
mod.OnTemplatesUpdate = mod.OnInitialize

function mod.UpdatePPBar()
	if db.movePPBar then
		myppb:Show()
		myppb:ClearAllPoints()
		myppb:SetScale(db.ppbScale)
		myppb:SetAlpha(db.ppbAlpha)
		myppb:SetPoint("CENTER", UIParent, "CENTER", db.ppbX, db.ppbY)
	else
		myppb:Hide()
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
			local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitDebuff("target", j)
			while name do
				if name == sovName and caster == "player" then
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
				j = j + 1
				name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitDebuff("target", j)
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

--------------------------------------------------------------------------------
-- create a hp bar similar to blizzard's xml code
--------------------------------------------------------------------------------
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
	myppb.glow:SetAllPoints()
	t = myppb.glow:CreateTexture("clcInfoPaladinPowerBarGlowBGTexture", "BACKGROUND", nil, -1)
	t:SetPoint("TOP")
	t:SetSize(136, 39)
	t:SetTexture(tfile)
	t:SetTexCoord(0.00390625, 0.53515625, 0.00781250, 0.31250000)
	myppb.glow.pulse = myppb.glow:CreateAnimationGroup()
	local a = myppb.glow.pulse:CreateAnimation("Alpha")
	a:SetChange(1) a:SetDuration(0.5) a:SetOrder(1)
	a = myppb.glow.pulse:CreateAnimation("Alpha")
	a:SetChange(-1) a:SetStartDelay(0.3) a:SetDuration(0.6) a:SetOrder(2)
	myppb.glow.pulse:SetScript("OnFinished", function(self) if not self.stopPulse then self:Play() end end)
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
	
	myppb:SetScript("OnEvent", PaladinPowerBar_OnEvent)
	myppb:Hide()
	PaladinPowerBar_OnLoad(myppb)
end
--------------------------------------------------------------------------------
