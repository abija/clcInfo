-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "DEATHKNIGHT" then return end

local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\data\\deathknight\\global> " .. table.concat(t, " "))
end

local defaults = {
	moveRuneBar = false,
	-- rune bar coords
	rbX = 0,
	rbY = 0,
	rbScale = 1,
}

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule(class, "global")
local db
-- functions visible to exec should be attached to this
local emod = clcInfo.env

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleDB(class, "global", defaults)
	mod.UpdateRuneBar()
end

local function MoveRuneBar()
	RuneFrame:ClearAllPoints()
	RuneFrame:SetScale(db.rbScale)
	RuneFrame:SetPoint("CENTER", "UIParent", "CENTER", db.rbX, db.rbY)
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
	if db.moveRuneBar then
		MoveRuneBar()
	else
		RestoreRuneBar()
	end
end


