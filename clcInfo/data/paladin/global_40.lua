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
local mod = clcInfo:RegisterClassModule(class, "global")
local db
-- functions visible to exec should be attached to this
local emod = clcInfo.env

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleDB(class, "global", defaults)
	mod.UpdatePPBar()
end

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


