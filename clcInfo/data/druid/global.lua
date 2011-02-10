-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "DRUID" then return end

local version = 1

local defaults = {
	moveEB = false,
	hideBlizzEB = false,
	-- paladin power bar coords
	ebX = 0,
	ebY = 0,
	ebPoint = "CENTER",
  ebRelativePoint = "CENTER",
	ebScale = 1,
	ebAlpha = 1,
	
	version = version,
}

-- lower case module name
local modName = "global"

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule(modName)
local db -- it's per template based
local emod = clcInfo.env -- functions visible to exec should be attached to this

local myeb -- my eclipse bar
local EB_Create
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
		
		mod.UpdateEBar()
	else
		if myeb then mod:HideEB() end
	end
end
mod.OnTemplatesUpdate = mod.OnInitialize

function mod.UpdateEBar()
	if db.moveEB then
		if not myeb then EB_Create() end
	
		myeb:EnableMouse(not mod.locked)
	
		mod:ShowEB()
		myeb:ClearAllPoints()
		myeb:SetScale(db.ebScale)
		myeb:SetAlpha(db.ebAlpha)
		myeb:SetPoint("CENTER", UIParent, "CENTER", db.ebX, db.ebY)
	else
		if myeb then mod:HideEB() end
	end
	
	if db.hideBlizzEB then
		EclipseBarFrame:UnregisterAllEvents()
		EclipseBarFrame:Hide()
		EclipseBarFrame:SetScript("OnShow", function(self) self:Hide() end)
	else
		EclipseBarFrame:SetScript("OnShow", EclipseBar_OnShow)
		EclipseBar_OnLoad(EclipseBarFrame)
		EclipseBarFrame:Show()
	end
end

--------------------------------------------------------------------------------

function mod:ShowEB()
	myeb:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	myeb:RegisterEvent("PLAYER_TALENT_UPDATE")
	myeb:RegisterEvent("UNIT_AURA")
	myeb:RegisterEvent("ECLIPSE_DIRECTION_CHANGE")
	myeb:Show()
end

function mod:HideEB()
	myeb:UnregisterAllEvents()
	myeb:Hide()
end



-- custom druid bar code
--------------------------------------------------------------------------------


-- defines
--------------------------------------------------------------------------------
local WIDTH = 120
local HEIGHT = 21
local X50 = 60
local X100 = 120
local GLOW_SIZE = 40
local PADDING = 2
local ICON_GLOW = [[Interface\Cooldown\starburst]]
local BUFF_SOLAR = GetSpellInfo(48517)
local BUFF_LUNAR = GetSpellInfo(48518)
local ICON_SUN	= [[Interface\AddOns\clcInfo\data\druid\sun]]
local ICON_MOON	= [[Interface\AddOns\clcInfo\data\druid\moon]]
local TEX_BAR = [[Interface\AddOns\clcInfo\data\druid\glamour_mirror]]
local TEX_MARKER = [[Interface\AddOns\clcInfo\data\druid\arrows]]
-- utility vars
--------------------------------------------------------------------------------
local lastPower = -1000

-- turn off the glows
local function EB_Deactivate()
	myeb.sun:SetAlpha(1)
	myeb.sun2:Hide()
	myeb.sun_glow:Hide()
	myeb.solar_glow:Hide()
	myeb.moon:SetAlpha(1)
	myeb.moon2:Hide()
	myeb.moon_glow:Hide()
	myeb.lunar_glow:Hide()
end

-- check for eclipse buffs and toggle glows
local function EB_CheckBuffs()
	local hasEclipseSolar = UnitBuff("player", BUFF_SOLAR, nil, "PLAYER")
	local hasEclipseLunar = UnitBuff("player", BUFF_LUNAR, nil, "PLAYER")
	
	if hasEclipseSolar then
		myeb.sun:SetAlpha(1)
		myeb.sun2:Show()
		myeb.sun_glow:Show()
		myeb.solar_glow:Show()
	elseif hasEclipseLunar then
		myeb.moon:SetAlpha(1)
		myeb.moon2:Show()
		myeb.moon_glow:Show()
		myeb.lunar_glow:Show()
	else
		EB_Deactivate()
	end
end

-- check if bar should be hidden or shown
local function EB_UpdateShown()
	if VehicleMenuBar:IsShown() then return end
	
	local form  = GetShapeshiftFormID()
	if form == MOONKIN_FORM or not form then
		if GetPrimaryTalentTree() == 1 then
			myeb:Show()
			return
		end
	end
	lastPower = -1000
	myeb:Hide()
end

-- update bar position if power value changes
local function EB_OnUpdate()
	local power = UnitPower( "player", SPELL_POWER_ECLIPSE )
	if power == lastPower then return end
	
	myeb.powerText:SetText(abs(power))
	
	power = power * (X50 / 100)
	
	myeb.solar_bar:SetPoint("RIGHT", myeb, "CENTER", power, 0)
	myeb.solar_bar:SetTexCoord(0, 1 - ((X50 - power) / X100), 0, 1)
	myeb.solar_bar:SetGradientAlpha("HORIZONTAL", 1, 1, 0, 0, 1, 1, 0, (X50 + power) / X100)
	
	myeb.lunar_bar:SetPoint("LEFT", myeb, "CENTER", power, 0)
	myeb.lunar_bar:SetTexCoord((X50 + power) / X100, 1, 0, 1)
	myeb.lunar_bar:SetGradientAlpha("HORIZONTAL", 0, 0.5, 1, (X50 - power) / X100, 0, 0.5, 1, 0)
	
	myeb.marker:SetPoint("CENTER", myeb, "CENTER", power, 0)
	
	lastPower = power
end

-- event handling
function EB_OnEvent(self, event, arg1)
	if event == "UNIT_AURA" and arg1 == "player" then
		EB_CheckBuffs()
	elseif event == "ECLIPSE_DIRECTION_CHANGE" then
		if arg1 then
			myeb.marker:SetTexCoord(0.546875, 0.859375, 0.000000, 0.984375) -- >
		else
			myeb.marker:SetTexCoord(0.109375, 0.421875, 0.000000, 0.984375)	-- <
		end
	else
		EB_UpdateShown()
	end
end

-- activate events and setup initial bars
local function EB_OnShow()
	EB_Deactivate()
	
	local direction = GetEclipseDirection()
	if direction == "sun" then
		myeb.marker:SetTexCoord(0.546875, 0.859375, 0.000000, 0.984375) -- >
	elseif direction == "moon" then
		myeb.marker:SetTexCoord(0.109375, 0.421875, 0.000000, 0.984375)	-- <
	else
		myeb.marker:SetTexCoord(0, 0, 0, 0)
	end
	
	EB_CheckBuffs()
end

-- create the bar :p
EB_Create = function()
	local t, fs

	myeb = CreateFrame("Frame", "clcInfoEclipseFrame", clcInfo.mf)
	myeb:SetSize(WIDTH, HEIGHT)
	myeb:Hide()
	
	-- bg
	t = myeb:CreateTexture(nil, "BACKGROUND")
	myeb.bg = t
	t:SetTexture(TEX_BAR)
	t:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 0.3, 1, 1, 1, 0.3)
	t:SetSize(WIDTH, HEIGHT)
	t:SetPoint("CENTER")
	
	-- solar bar
	t = myeb:CreateTexture(nil, "ARTWORK")
	myeb.solar_bar = t
	t:SetTexture(TEX_BAR)
	t:SetSize(WIDTH, HEIGHT)
	t:SetPoint("LEFT", myeb, "CENTER", -X50, 0)
	-- solar bar blow
	t = myeb:CreateTexture(nil, "OVERLAY")
	myeb.solar_glow = t
	t:SetTexture(ICON_GLOW)
	t:SetBlendMode("ADD")
	t:SetGradientAlpha("HORIZONTAL", 1, 1, 0.5, 0, 1, 1, 0.5, 0.7)
	t:SetTexCoord(0.5, 1, 0, 1)
	t:SetSize(WIDTH, 2 * HEIGHT)
	t:SetPoint("LEFT", myeb, "CENTER")
	
	
	-- lunar bar
	t = myeb:CreateTexture(nil, "ARTWORK")
	myeb.lunar_bar = t
	t:SetTexture(TEX_BAR)
	t:SetSize(WIDTH, HEIGHT)
	t:SetPoint("RIGHT", myeb, "CENTER", X50, 0)
	-- lunar bar glow
	t = myeb:CreateTexture(nil, "OVERLAY")
	myeb.lunar_glow = t
	t:SetTexture(ICON_GLOW)
	t:SetBlendMode("ADD")
	t:SetGradientAlpha("HORIZONTAL", 0.6, 0.6, 1, 1, 0.6, 0.6, 1, 0)
	t:SetTexCoord(0, 0.5, 0, 1)
	t:SetSize(WIDTH, 2 * HEIGHT)
	t:SetPoint("RIGHT", myeb, "CENTER")
	
	-- sun icon
	t = myeb:CreateTexture(nil, "ARTWORK")
	myeb.sun = t	
	t:SetTexture(ICON_SUN)
	t:SetSize(HEIGHT, HEIGHT)
	t:SetPoint("LEFT", myeb, "RIGHT", 1, 0)
	-- double effect when activated
	t = myeb:CreateTexture(nil, "ARTWORK", nil, 1)
	myeb.sun2 = t
	t:SetTexture(ICON_SUN)
	t:SetBlendMode("ADD")
	t:SetSize(HEIGHT, HEIGHT)
	t:SetPoint("LEFT", myeb, "RIGHT", 1, 0)
	t:Hide()
	-- glow
	t = myeb:CreateTexture(nil, "OVERLAY")
	myeb.sun_glow = t
	t:SetTexture(ICON_GLOW)
	t:SetBlendMode("ADD")
	t:SetVertexColor(1, 1, 0.5, 0.7)
	t:ClearAllPoints()
	t:SetSize(GLOW_SIZE, GLOW_SIZE)
	t:SetPoint("CENTER", myeb.sun)
	t:Hide()
	
	-- moon icon
	t = myeb:CreateTexture(nil, "ARTWORK")
	myeb.moon = t
	t:SetTexture(ICON_MOON)
	t:SetSize(HEIGHT, HEIGHT)
	t:SetPoint("RIGHT", myeb, "LEFT", -1, 0)
	-- double effect when activated
	t = myeb:CreateTexture(nil, "ARTWORK", nil, 1)
	myeb.moon2 = t
	t:SetTexture(ICON_MOON)
	t:SetBlendMode("ADD")
	t:SetSize(HEIGHT, HEIGHT)
	t:SetPoint("RIGHT", myeb, "LEFT", -1, 0)
	t:Hide()
	t = myeb:CreateTexture(nil, "OVERLAY")
	myeb.moon_glow = t
	t:SetTexture(ICON_GLOW)
	t:SetBlendMode("ADD")
	t:SetVertexColor(0.6, 0.6, 1, 1)
	t:SetSize(GLOW_SIZE, GLOW_SIZE)
	t:SetPoint("CENTER", myeb.moon)
	t:Hide()
	
	-- marker
	t = myeb:CreateTexture(nil, "OVERLAY")
	myeb.marker = t
	t:SetTexture(TEX_MARKER)
	t:SetSize(15, 25)
	t:SetPoint("CENTER", 0, 00)
	
	fs = myeb:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	myeb.powerText = fs
	fs:SetText(0)
	fs:SetPoint("CENTER", 0, 0)
	
	myeb:SetScript("OnEvent", EB_OnEvent)
	myeb:SetScript("OnUpdate", EB_OnUpdate)
	myeb:SetScript("OnShow", EB_OnShow)
	
	-- register for drag
	myeb:SetMovable(true)
	myeb:RegisterForDrag("LeftButton")
	myeb:SetScript("OnDragStart", function(self)
      self:StartMoving()
  end)
	myeb:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		db.ebPoint, _, db.ebRelativePoint, db.ebX, db.ebY = self:GetPoint()
    -- update the data in options also
    clcInfo:UpdateOptions()
	end)
end



-- get combo points
-- returns 2 values:
-- value1: return of GetComboPoints("player") or leftover combo points
-- value2: 1 if value is leftover points, nil otherwise
-- needs at least savage roar
do
	local prevCP = 0
	local roar = GetSpellInfo(52610)
	function emod.GetCP()
		local cp = GetComboPoints("player")
		local isUsable, notEnoughMana = IsUsableSpell(roar)
		if cp > 0 or (isUsable == nil and notEnoughMana == nil) then
			prevCP = cp
			return cp
		end
		return prevCP, 1
	end
end