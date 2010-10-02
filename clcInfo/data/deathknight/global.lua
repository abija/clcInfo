-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "DEATHKNIGHT" then return end

local defaults = {
	moveRuneBar = false,
	-- rune bar coords
	rbX = 0,
	rbY = 0,
	rbScale = 1,
}

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule("global")
local tdb
-- functions visible to exec should be attached to this
local emod = clcInfo.env

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	tdb = clcInfo:RegisterClassModuleTDB("global", defaults)
	if tdb then
		mod.UpdateRuneBar()
	end
end
mod.OnTemplatesUpdate = mod.OnInitialize

local function MoveRuneBar()
	RuneFrame:ClearAllPoints()
	RuneFrame:SetScale(tdb.rbScale)
	RuneFrame:SetPoint("CENTER", "UIParent", "CENTER", tdb.rbX, tdb.rbY)
end
local function RestoreRuneBar()
	if PlayerFrame then
		RuneFrame:ClearAllPoints()
		RuneFrame:SetScale(1)
		RuneFrame:SetPoint("TOP", "PlayerFrame", "BOTTOM", 54, 34)
	end
end
function mod.UpdateRuneBar()
	if not RuneFrame then return end -- don't do anything if someone removed it
	if not RuneFrame:IsVisible() then return end -- don't do anything if it's hidden by something
	if tdb.moveRuneBar then
		MoveRuneBar()
	else
		RestoreRuneBar()
	end
end


