-- build check
local _, _, _, toc = GetBuildInfo()
if toc < 40000 then return end

-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\data\\paladin\\global> " .. table.concat(t, " "))
end

local defaults = {
	movePPBar = false,
	-- paladin power bar coords
	ppbX = 0,
	ppbY = 0,
	ppbScale = 1,
}

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule("global")
local db -- ! it's a tdb, change if needed
-- functions visible to exec should be attached to this
local mod = clcInfo.env

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleTDB("global", defaults)
	if db then
		mod.UpdatePPBar()
	end
end
mod.OnTemplatesUpdate = mod.OnInitialize

local function MovePPBar()
	PaladinPowerBar:ClearAllPoints()
	PaladinPowerBar:SetScale(db.ppbScale)
	PaladinPowerBar:SetPoint("CENTER", "UIParent", "CENTER", db.ppbX, db.ppbY)
end
local function RestorePPBar()
	if PlayerFrame then
		PaladinPowerBar:ClearAllPoints()
		PaladinPowerBar:SetScale(1)
		PaladinPowerBar:SetPoint("TOP", "PlayerFrame", "BOTTOM", 43, 39)
	end
end
function mod.UpdatePPBar()
	if not PaladinPowerBar then return end -- don't do anything if someone removed it
	if not PaladinPowerBar:IsVisible() then return end -- don't do anything if it's hidden by something
	if db.movePPBar then
		MovePPBar()
	else
		RestorePPBar()
	end
end

--[[
	-- sov tracking
--]]
do
	local sovName, sovId, sovSpellTexture
	sovId = 31803
	sovName, _, sovSpellTexture = GetSpellInfo(sovId)						-- Censure
	
	local function ExecCleanup()
		mod.___e.___sovList = nil
	end

	function mod.MBarSoV(a1, a2, showStack, timeRight)
		-- setup the table for sov data
		if not mod.___e.___sovList then
			mod.___e.___sovList = {}
			mod.___e.ExecCleanup = ExecCleanup
		end
		
		local tsov = mod.___e.___sovList
	
		-- check target for sov
		local targetGUID
		if UnitExists("target") then
			targetGUID = UnitGUID("target")
			local j = 1
			local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitDebuff("target", j)
			while name do
				if name == sovName and caster == "player" then
					-- found it
					if count > 1 and showStack then 
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
				
				mod.___e:___AddBar(nil, alpha, nil, nil, nil, nil, sovSpellTexture, 0, v[2], value, "normal", v[1], "", tr)
			end
		end
	end
end


