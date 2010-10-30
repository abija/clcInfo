-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "x" then return end

local modName = "_retribution"
local mod = clcInfo:RegisterClassModule(modName)

local GetTime = GetTime
local emod = clcInfo.env

-- gcd
local _gcdId 				= 85256 -- tv for gcd

-- list of spellId
local _howId 				=	24275	-- hammer of wrath
local _csId 				= 35395	-- crusader strike
local _tvId					= 85256	-- templar's verdict
local _inqId				= 84963	-- inquisition
local _dsId					= 53385	-- divine storm
local _jId					= 20271	-- judgement
local _consId				= 26573	-- consecration
local _exoId				= 879		-- exorcism
local _hwId					= 2812 	-- holy wrath
local _zealId				= 85696 -- zealotry

-- list of spellName
local _howName		= GetSpellInfo(_howId)
local _csName			= GetSpellInfo(_csId)
local _tvName			= GetSpellInfo(_tvId)
local _inqName		= GetSpellInfo(_inqId)
local _dsName			= GetSpellInfo(_dsId)
local _jName			= GetSpellInfo(_jId)
local _consName		= GetSpellInfo(_consId)
local _exoName		= GetSpellInfo(_exoId)
local _hwName			= GetSpellInfo(_hwId)
local _zealName 	= GetSpellInfo(_zealId)


-- buffs
local _buffZeal = _zealName									-- zealotry
local _buffAW 	= GetSpellInfo(31884)				-- avenging wrath
local _buffHoL	= GetSpellInfo(90174)				-- hand of light
local _buffAoW	= GetSpellInfo(59578)				-- the art of war


-- list of spells to be tracked with OnSpellCast
local tracked = {
	[_howName] 			= true,
	[_csName] 			= true,
	[_tvName] 			= true,
	[_inqName] 			= true,
	[_dsName] 			= true,
	[_jName] 				= true,
	[_consName] 		= true,
	[_exoName] 			= true,
	[_hwName] 			= true,
	[_zealName] 		= true,
}
clcInfo.spew = tracked

-- list of available actions for the priority list
local actionsId = {
		tv 		= _tvId,
		cs 		= _csId,
		j			= _jId,
		exo 	= _exoId,
		how 	= _howId,
		hw 		= _hwId,
		ds 		= _dsId,
		cons 	= _consId,
}
local actionsName = {
		tv 		= _tvName,
		cs 		= _csName,
		j			= _jName,
		exo 	= _exoName,
		how 	= _howName,
		hw 		= _hwName,
		ds 		= _dsName,
		cons 	= _consName,	
}

-- working priority queue, skill 1, skill 2
local pq, s1, s2

-- @temp
local db_priority = { "how", "tv", "cs", "exo", "j", "hw" }
local db_wspeed = 3.6
local db_useInq = false
local db_rangePerSkill = true

-- skill objects
local mainSkill, secondarySkill


-- status vars
local _ctime, _gcd, _hp, _zeal, _aw, _aow, _hol, _haste, _boost, _csHack, _cstvHack, _tvIndexHack
_cstvHack = 0
-- useful vars
local start, duration, cd

-- this is where the logic for the actions available to priority list goes
-- @info
--[[
	2 returns, first is cooldown, second is gcd of the action since the spells have lower gcd
	spells: exo, hw, cons
--]]
local actions = {
	-- @hack
	tv = function(i)
		_tvIndexHack = i
		if _hp >= 3 or _hol > 0 then
			return 0, 1.5
		end
		return 100, 1.5
	end,
	
	cs = function()
		start, duration = GetSpellCooldown(_csId)
		-- @hack
		_csHack = start + duration - _ctime
		cd = _csHack  - _gcd - _boost
		if cd < 0 then cd = 0 end
		_boost = 0
		return cd, 1.5
	end,
	
	j = function()
		start, duration = GetSpellCooldown(_jId)
		cd = start + duration - _ctime - _gcd - _boost
		if cd < 0 then cd = 0 end
		_boost = 0
		return cd, 1.5
	end,
	
	exo = function()
		if _aow > 0 then
			return 0, 1.5 / _haste
		end
		return 100, 1.5 / _haste
	end,
	
	how = function()
		-- need target
		if not (UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")) then
			return 100, 1.5
		end
		
		-- health > 20% and not aw
		local hperc = UnitHealth("target") / UnitHealthMax("target")
		if hperc > 0.2 and _aw == 0 then
			return 100, 1.5
		end
		
		start, duration = GetSpellCooldown(_howId)
		cd = start + duration - _ctime - _gcd - _boost
		if cd < 0 then cd = 0 end
		_boost = 0
		return cd, 1.5
	end,
	
	hw = function()
		start, duration = GetSpellCooldown(_hwId)
		cd = start + duration - _ctime - _gcd - _boost
		if cd < 0 then cd = 0 end
		_boost = 0
		return cd, 1.5 / _haste
	end,
	
	cons = function()
		start, duration = GetSpellCooldown(_consId)
		cd = start + duration - _ctime - _gcd - _boost
		if cd < 0 then cd = 0 end
		_boost = 0
		return cd, 1.5 / _haste
	end,
}
actions.ds = actions.tv -- ds should be the same as tv

local actions2 = {
	tv = function(xcd, xgcd)
		if _hp >= 3 or _hol > xgcd then
			return 0
		end
		return 100
	end,
	
	cs = function(xcd, xgcd)
		cd = xcd - xgcd - _boost
		_boost = 0
		if cd < 0 then cd = 0 end
		return cd
	end,
	
	j = function(xcd, xgcd)
		cd = xcd - xgcd - _boost
		if cd < 0 then cd = 0 end
		return cd
	end,
	
	exo = function(xcd, xgcd)
		if _aow > xgcd then return 0 end
		return 100
	end,
	
	how = function(xcd, xgcd)
		-- need target
		if not (UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")) then
			return 100
		end
		
		-- health > 20% and not aw
		local hperc = UnitHealth("target") / UnitHealthMax("target")
		if hperc > 0.2 and _aw <= xgcd then
			return 100
		end
		
		cd = xcd - xgcd - _boost
		if cd < 0 then cd = 0 end
		return cd
	end,
	
	hw = function(xcd, xgcd)
		cd = xcd - xgcd - _boost
		if cd < 0 then cd = 0 end
		return cd
	end,
	
	cons = function(xcd, xgcd)
		cd = xcd - xgcd - _boost
		if cd < 0 then cd = 0 end
		return cd
	end,
}
actions2.ds = actions2.tv -- ds should be the same as tv

local dbg = CreateFrame("Frame")
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


local lastgcd = 0
local waitforserver = false
local eq = 0

function dbg.AddPQ()
	for i, v in ipairs(pq) do
		dbg.AddBoth(v.alias, v.cd)
	end
end

function dbg.AddStatus()
	dbg.AddBoth("_ctime", _ctime)
	dbg.AddBoth("_gcd", _gcd)
	dbg.AddBoth("_hp", _hp)
	dbg.AddBoth("_zeal", _zeal)
	dbg.AddBoth("_aw", _aw)
	dbg.AddBoth("_aow", _aow)
	dbg.AddBoth("_hol", _hol)
	dbg.AddBoth("_haste", _haste)
	dbg.AddBoth("_boost", _boost)
	dbg.AddBoth("_csHack", _csHack)
	dbg.AddBoth("_cstvHack", _cstvHack)
	dbg.AddBoth("_tvIndexHack", _tvIndexHack)
	dbg.AddBoth("lastgcd", lastgcd)
	dbg.AddBoth("waitforserver", waitforserver)
	dbg.AddBoth("eq", eq)
end

local ef = CreateFrame("Frame") -- event frame
ef:SetScript("OnEvent", function(self, event, unit, spell)
	if unit == "player" and tracked[spell] then
		print(GetTime(), event, spell)
		if event == "UNIT_SPELLCAST_SENT"then
			eq = eq + 1
		elseif event == "UNIT_SPELLCAST_FAILED_QUIET" then
			eq = eq - 1
			if eq < 0 then eq = 0 end
			if eq == 0 then
				waitforserver = false
				mainSkill:Highlight(false)
			end
		else -- UNIT_SPELLCAST_SUCCEEDED
			eq = 0
			waitforserver = false
			mainSkill:Highlight(false)
		end
	end
end)
ef:RegisterEvent("UNIT_SPELLCAST_SENT")
-- ef:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
ef:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")


function RetRotation(csBoost)
	-- get gcd value
	------------------------------------------------------------------------------
	local cdStart, cdDuration
	_ctime = GetTime()
	cdStart, cdDuration = GetSpellCooldown(_gcdId)
	_gcd = cdStart + cdDuration - _ctime
	if _gcd < 0 then _gcd = 0 end
	
	dbg.ClearLines()
	dbg.AddBoth("*gcd", _gcd)

	if waitforserver then
		if _gcd == 0 or _gcd < 0.7 then
			waitforserver = false
			mainSkill:Highlight(false)
		end
		return
	end
	
	if _gcd > lastgcd and eq > 0 then
		mainSkill:Highlight(true)
		lastgcd = _gcd
		waitforserver = true
	end
	lastgcd = _gcd
	
	-- get status
	------------------------------------------------------------------------------
	_boost = csBoost or 0
	_haste = db_wspeed / UnitAttackSpeed("player")
	_hp = UnitPower("player", SPELL_POWER_HOLY_POWER)
	
	mod.GetBuffStatus()
	dbg.AddStatus()
	
	for i, v in ipairs(pq) do
		v.cd = actions[v.alias](i)
	end
	
	dbg.AddPQ()
	
	-- @hack
	if (_hp == 2 or _zeal > 0) and _csHack > 2 and (_ctime - _cstvHack) < 1 then
		pq[_tvIndexHack].cd = 0
	end
	
	dbg.AddBoth(pq[_tvIndexHack].alias, pq[_tvIndexHack].cd)
	
	-- first sort
	------------------------------------------------------------------------------
	local sel = 1
	
	for i = 2, #pq do
		if pq[i].cd < pq[sel].cd then
			sel = i
		end
	end
	
	s1 = pq[sel].id
	
	------------------------------------------------------------------------------
	
	-- adjust for second sort
	------------------------------------------------------------------------------
	-- boost was already made 0, so it should return a proper value
	-- skill duration + skill gcd = predicted time
	local x, xgcd = actions[pq[sel].alias]()
	xgcd = x + xgcd
	
	-- adjust for predicted values
	if pq[sel].id == _csId then
	-- cs means you get guaranteed extra hp
		if _zeal > 0 then
			_hp = _hp + 3
		else
			_hp = _hp + 1
		end
		-- @hack
		-- avoid the temporary skill change until hp is generated
		if _hp >= 3 and _csHack < 2 then
			-- last time when we got this situation
			_cstvHack = _ctime
		end
	elseif (pq[sel].id == _tvId or pq[sel].id == _dsId) then
	-- if tv or ds -> hol or hp get used
		if _hol > 0 then
			_hol = 0
		else
			_hp = 0
		end
	elseif pq[sel].id == _exoId then
	-- exo first -> aow gets used
		_aow = 0
	end
	
	dbg.AddBoth("_cstvHack", _cstvHack)
	
	-- put first skill at end of queue
	pq[sel].cd = 110
	
	dbg.AddBoth("_hp", _hp)
	dbg.AddBoth("_hol", _hol)
	dbg.AddBoth("_aow", _aow)
	
	-- second sort
	------------------------------------------------------------------------------
	-- _boost = csBoost
	-- get cooldowns again
	for i, v in ipairs(pq) do
		v.cd = actions2[v.alias](v.cd, xgcd)
	end
	
	dbg.AddPQ()
	
	-- sort again
	
	sel = 1
	
	for i = 2, #pq do
		if pq[i].cd < pq[sel].cd then
			sel = i
		end
	end
	s2 = pq[sel].id
	
	-- inquisition goes here
	------------------------------------------------------------------------------
end

function emod.IconRetEx1(...)
	mainSkill = emod.___e
	RetRotation(...)
	if secondarySkill then secondarySkill:DoUpdate() end
	return emod.IconSpell(s1, db_rangePerSkill or _csId)
end

local function SecondaryExec()
	return emod.IconSpell(s2, db_rangePerSkill or _csId)
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

--------------------------------------------------------------------------------
function mod.GetBuffStatus()
	local expires
	_, _, _, _, _, _, expires = UnitBuff("player", _buffAoW, nil, "PLAYER")
	if expires then
		_aow = expires - _ctime - _gcd
		if _aow < 0 then _aow = 0 end
	else
		_aow = 0
	end
	
	_, _, _, _, _, _, expires = UnitBuff("player", _buffZeal, nil, "PLAYER")
	if expires then
		_zeal = expires - _ctime - _gcd
		if _zeal < 0 then _zeal = 0 end
	else
		_zeal = 0
	end
	
	_, _, _, _, _, _, expires = UnitBuff("player", _buffAW, nil, "PLAYER")
	if expires then
		_aw = expires - _ctime - _gcd
		if _aw < 0 then _aw = 0 end			
	else
		_aw = 0
	end
	
	_, _, _, _, _, _, expires = UnitBuff("player", _buffHoL, nil, "PLAYER")
	if expires then
		_hol = expires - _ctime - _gcd
		if _hol < 0 then _hol = 0 end
	else
		_hol = 0
	end
end

function mod.UpdatePriorityQueue()
	pq = {}
	local check = {} -- used to check for duplicates
	for k, v in ipairs(db_priority) do
		if not check[v] then
			if v ~= "none" and actionsId[v] then
				pq[#pq + 1] = { alias = v, id = actionsId[v] }
				check[v] = true
			end
		end
	end
end
mod.UpdatePriorityQueue()