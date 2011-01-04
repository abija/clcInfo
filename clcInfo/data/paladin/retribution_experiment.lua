--[[
Notes:
* hol + 3hp and inq refresh should be tv, followed by inq ?
--]]


-- don't load if class is wrong
local _, class = UnitClass("player")
-- if true then return end
if class ~= "PALADIN" then return end

local GetTime = GetTime
local dbg

-- create a module in the main addon
local modName = "retributionex"
local mod = clcInfo:RegisterClassModule(modName)

-- functions visible to exec should be attached to this
local emod = clcInfo.env

local version = 2
local defaults = {
	rangePerSkill = false,
	useInq = true,
	preInq = 5,
	tolerance = 0,
	jClash = 0.5,
	hw = true,
	hwClash = 0.5,
	cons = false,
	consClash = 1,
	consMana = 20000,
	hpDelay = 0.5,
	undead = "Undead",
	demon = "Demon",
	
	version = 1,
}
local db -- per template

function mod.OnTemplatesUpdate()
	db = clcInfo:RegisterClassModuleTDB(modName, defaults)
	if db then
		if not db.version or db.version < version then
			-- fix stuff
			clcInfo.AdaptConfigAndClean(modName, db, defaults)
			db.version = version
		end
	end
end

--[[
Inq > HoW > Exo > 3 HP TV > CS > HoL TV at 1 or 2 HP > J > HW > Cons
Against Undead or Demons: Exo > HoW
--]]

-- @defines
--------------------------------------------------------------------------------
local gcdId 				= 85256 -- tv for gcd
-- list of spellId
local howId 				=	24275	-- hammer of wrath
local csId 					= 35395	-- crusader strike
local tvId					= 85256	-- templar's verdict
local inqId					= 84963	-- inquisition
local dsId					= 53385	-- divine storm
local jId						= 20271	-- judgement
local consId				= 26573	-- consecration
local exoId					= 879		-- exorcism
local hwId					= 2812 	-- holy wrath
local zealId				= 85696 -- zealotry
local inqId					= 84963 -- inquisition
-- csName to pass as argument for melee range checks
local csName			= GetSpellInfo(csId)
-- buffs
local buffZeal 	= GetSpellInfo(zealId)	-- zealotry
local buffHoL		= GetSpellInfo(90174)		-- hand of light
local buffAoW		= GetSpellInfo(59578)		-- the art of war
local buffInq 	= GetSpellInfo(inqId)		-- inquisition

-- skill 1, skill 2
local sx, s1, s2
-- status vars
local ctime, gcd, hp, zeal, aow, inq, hol, haste, s1time, targetType
local csCd, howCd, jCd, hwCd, consCd
local justCS, justCSHP = 0, 0
local start, duration, cd

-- get cooldown
local function GetCooldown(id)
	start, duration = GetSpellCooldown(id)
	cd = start + duration - ctime - gcd
	if cd < 0 then return 0 end
	return cd
end

local function GetBuffStatus()
	local expires
	_, _, _, _, _, _, expires = UnitBuff("player", buffAoW, nil, "PLAYER")
	if expires then
		aow = expires - ctime - gcd
		if aow < 0 then aow = 0 end
	else
		aow = 0
	end
	
	_, _, _, _, _, _, expires = UnitBuff("player", buffZeal, nil, "PLAYER")
	if expires then
		zeal = expires - ctime - gcd
		if zeal < 0 then zeal = 0 end
	else
		zeal = 0
	end
	
	_, _, _, _, _, _, expires = UnitBuff("player", buffHoL, nil, "PLAYER")
	if expires then
		hol = expires - ctime - gcd
		if hol < 0 then hol = 0 end
	else
		hol = 0
	end
	
	_, _, _, _, _, _, expires = UnitBuff("player", buffInq, nil, "PLAYER")
	if expires then
		inq = expires - ctime - gcd
		if inq < 0 then inq = 0 end
	else
		inq = 0
	end
end

local function GetNextSkill()
	-- 1] Inquisition
	------------------------------------------------------------------------------
	if db.useInq then
		if inq <= db.tolerance and (hp >= 3 or hol > 0) then
			sx = inqId
			s1time = 1.5 / haste
			-- adjust hp
			if hol == 0 then
				hp = 0
			else
				hol = 0
			end
			-- random add inq
			inq = 100
			return
		end
	end
	
	-- test if target undead or demon
	-- exo > how in that case
	if targetType == db.undead or targetType == db.demon then
		-- 2] Exorcism
		----------------------------------------------------------------------------
		if aow >= db.tolerance then
			sx = exoId
			s1time = 1.5 / haste
			aow = 0
			return
		end
		
		-- 3] Hammer of Wrath
		----------------------------------------------------------------------------
		-- first test if the skill is out of cooldown and usable, otherwise it will be handled later
		if howCd <= db.tolerance then
			sx = howId
			s1time = 1.5 / haste
			howCd = 1000
			return
		end
	else
		-- 2] Hammer of Wrath
		----------------------------------------------------------------------------
		-- first test if the skill is out of cooldown and usable, otherwise it will be handled later
		if howCd <= db.tolerance then
			sx = howId
			s1time = 1.5 / haste
			howCd = 1000
			return
		end
		
		-- 3] Exorcism
		----------------------------------------------------------------------------
		if aow >= db.tolerance then
			sx = exoId
			s1time = 1.5 / haste
			aow = 0
			return
		end
	end
	
	-- 4] 3 HP
	------------------------------------------------------------------------------
	if hp >= 3 then
		-- first check if we need to refresh Inquisition
		-- adjust hp
		if hol == 0 then
			hp = 0
		else
			hol = 0
		end
		if db.useInq and inq < db.preInq then
			sx = inqId
			s1time = 1.5 / haste
			inq = 100
			return
		-- else do TV
		else
			sx = tvId
			s1time = 1.5
			return
		end
	end
	
	-- 5] CS
	------------------------------------------------------------------------------
	-- same as with HoW, this is only when it's out of cooldown, cooldown clashing later
	if csCd <= db.tolerance then
		sx = csId
		s1time = 1.5
		csCd = 4.5 / haste
		if zeal >= db.tolerance then
			hp = 3
		else
			hp = hp + 1
		end
		return
	end
	
	-- 6] HoL
	if hol > db.tolerance then
		-- first check if we need to refresh Inquisition
		hol = 0
		if db.useInq and inq < db.preInq then
			sx = inqId
			s1time = 1.5 / haste
			inq = 100
			return
		-- else do TV
		else
			sx = tvId
			s1time = 1.5
			return
		end
	end
	
	-- cooldown clashing now
	------------------------------------------------------------------------------
	-- new cooldown values are pretty irrelevant
	-- only cs could be in a cs, cs succesion
	local minCd = min(howCd, csCd, jCd, hwCd, consCd)
	if minCd == howCd then
		sx = howId
		s1time = 1.5 / haste
		howCd = 1000
	elseif minCd == csCd then
		sx = csId
		s1time = 1.5
		if zeal >= db.tolerance then
			hp = 3
		else
			hp = hp + 1
		end
		csCd = 4.5 / haste
	elseif minCd == jCd then
		sx = jId
		s1time = 1.5
		jCd = 100
	elseif minCd == hwCd then
		sx = hwId
		s1time = 1.5 / haste
		hwCd = 100
	else
		sx = consId
		s1time = 1.5 / haste
		consCd = 100
	end
end

local function RetRotation()
	-- dbg.ClearLines()

	-- how much s1 will take to complete
	-- should be latency + 1.5 or latency + 1.5 / haste
	local s1time = 0
	
	-- curent time
	ctime = GetTime()

	-- gcd
	start, duration = GetSpellCooldown(gcdId)
	gcd = start + duration - ctime
	if gcd < 0 then gcd = 0 end
	
	-- buff info
	-- adjusted to the time when gcd ends
	GetBuffStatus()
	
	-- status data
	-- TODO: adjust more
	hp = UnitPower("player", SPELL_POWER_HOLY_POWER)
	haste = mod.GetHaste()
	
	-- adjust hp with + 1 after a cs
	--[[
	if ctime - justCS < db.hpDelay then
		if justCSHP == hp then
			if zeal >= db.tolerance then
				hp = 3
			else
				hp = hp + 1
			end
		else
			justCS = 0
		end
	end
	--]]
	
	-- undead or demon -> different exorcism behavior
	targetType = UnitCreatureType("target")
	
	-- get cooldowns
	--[ --------------------------------------------------------------------------
	howCd = 1000
	if IsUsableSpell(howId) then
		howCd = GetCooldown(howId)
	end
	csCd = GetCooldown(csId)
	
	-- judgement, holy wrath and consecration have a configurable clash time
	-- if other abilities get of cooldown during that time, delay
	jCd	= GetCooldown(jId) + db.jClash
	
	-- check if we use consecration and hw 
	hwCd = 100
	if db.hw then
		hwCd = GetCooldown(hwId) + db.hwClash
	end
	
	consCd = 100
	if db.cons and UnitPower("player") >= db.consMana then
		consCd 	= GetCooldown(consId) + db.consClash
	end
	
	--] --------------------------------------------------------------------------
	
	
	-- first skill detection
	------------------------------------------------------------------------------
	-- dbg.AddStatus()
	
	GetNextSkill()
	s1 = sx
	
	-- dbg.AddBoth("s1", GetSpellInfo(s1))
	
	-- adjust status
	------------------------------------------------------------------------------
	s1time = s1time + db.tolerance
	-- dbg.AddBoth(s1time)
	aow = max(0, aow - s1time)
	hol = max(0, hol - s1time)
	zeal = max(0, zeal - s1time)
	inq = max(0, inq - s1time)
	csCd = max(0, csCd - s1time)
	howCd = max(0, howCd - s1time)
	jCd = max(0, jCd - s1time) + db.jClash
	hwCd = max (0, hwCd - s1time) + db.hwClash
	consCd = max(0, consCd - s1time) + db.consClash
	
	-- second skill
	------------------------------------------------------------------------------
	-- dbg.AddStatus()
	
	GetNextSkill()
	s2 = sx
	
	-- dbg.AddBoth("s2", GetSpellInfo(s2))
end
--------------------------------------------------------------------------------


-- plug in
--------------------------------------------------------------------------------
local secondarySkill
function emod.IconRetEx1(...)
	RetRotation(...)
	if secondarySkill then secondarySkill:DoUpdate() end
	return emod.IconSpell(s1, db.rangePerSkill or csName)
end
local function SecondaryExec()
	return emod.IconSpell(s2, db.rangePerSkill or csName)
end
local function ExecCleanup2()
	secondarySkill = nil
end
function emod.IconRetEx2(...)
	secondarySkill = emod.___e
	secondarySkill:SetScript("OnUpdate", nil)
	secondarySkill.exec = SecondaryExec
	secondarySkill.ExecCleanup = ExecCleanup2
end

local ef = CreateFrame("Frame") 
ef:Hide()
ef:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
ef:SetScript("OnEvent", function(self, event, unit, spell)
	if spell == csName then
		justCSHP = UnitPower("player", SPELL_POWER_HOLY_POWER)
		if justCSHP < 3 then
			justCS = GetTime()
		end
	end
end)

-- get haste from CS cooldown
do
	local tooltip = CreateFrame("GameTooltip")
	tooltip:Hide()
	local tooltipL, tooltipR = {}, {}
	for i = 1, 3 do
		local left, right = tooltip:CreateFontString(), tooltip:CreateFontString()
		tooltip:AddFontStrings(left, right)
		tooltipL[i], tooltipR[i] = left, right
	end
	function mod.GetHaste()
		tooltip:SetOwner(clcInfo.mf)
		tooltip:SetSpellByID(csId)
		return 4.5 / tonumber(strmatch(tooltipR[3]:GetText(), "[^%d]*(%d[^%s]*).*"))
	end
end

local function CmdRetEx(args)
	if not args[1] then
		print("format: /clcInfo retex inqon/inqoff")
		return
	end
	
	if args[1] == "inqon" then
		db.useInq = true
	else
		db.useInq = false
	end
	
	clcInfo:UpdateOptions()
end
clcInfo.cmdList["retex"] = CmdRetEx



-- todo
-- worth checking aw expiration for 2nd skill ?


-- debug stuff
--[[
dbg = CreateFrame("Frame")
dbg:SetSize(200, 600)
dbg:SetPoint("LEFT", UIParent, 300, 30)
dbg:SetBackdrop(GameTooltip:GetBackdrop())
dbg:SetBackdropColor(GameTooltip:GetBackdropColor())
dbg.numLeft, dbg.numRight = 0, 0
dbg.left, dbg.right = {}, {}

for i = 1, 50 do
	dbg.left[i] = dbg:CreateFontString(nil, nil, "GameTooltipTextSmall")
	dbg.left[i]:SetJustifyH("LEFT")
	dbg.left[i]:SetPoint("TOPLEFT", 10, -15 * i)
	dbg.right[i] = dbg:CreateFontString(nil, nil, "GameTooltipTextSmall")
	dbg.right[i]:SetJustifyH("RIGHT")
	dbg.right[i]:SetPoint("TOPRIGHT", -10, -15 * i)
end

function dbg.ClearLines()
	dbg.numLeft, dbg.numRight = 0, 0
	for i = 1, 30 do
		dbg.left[i]:SetText("")
		dbg.right[i]:SetText("")
	end
end

function dbg.AddLeft(text)
	dbg.numLeft = dbg.numLeft + 1
	dbg.left[dbg.numLeft]:SetText(text)
end

function dbg.AddRight(text)
	dbg.numRight = dbg.numRight + 1
	dbg.right[dbg.numRight]:SetText(text)
end

function dbg.AddBoth(t1, t2)
	dbg.AddLeft(t1)
	dbg.AddRight(t2)
end

function dbg.AddStatus()
	dbg.AddBoth("ctime", ctime)
	dbg.AddBoth("gcd", gcd)
	dbg.AddBoth("hp", hp)
	dbg.AddBoth("zeal", zeal)
	dbg.AddBoth("aow", aow)
	dbg.AddBoth("inq", inq)
	dbg.AddBoth("hol", hol)
	dbg.AddBoth("haste", haste)
	dbg.AddBoth("csCd", csCd)
	dbg.AddBoth("howCd", howCd)
	dbg.AddBoth("jCd", jCd)
	dbg.AddBoth("hwCd", hwCd)
	dbg.AddBoth("consCd", consCd)
end
--]]