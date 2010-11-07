-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end


-- @todo:
-- test _boost in actions2


local GetTime = GetTime
local version = 3

-- default settings for this module
--------------------------------------------------------------------------------
local defaults = {
	version = version,
	
	rangePerSkill = false,
	fillers = { "how", "tv", "cs", "exo", "j", "hw" },
	csBoost = 0.5,
	wspeed = 3.5,
	useInq = false,
	preInq = 3,
}

local MAX_FILLERS = 8

-- create a module in the main addon
local modName = "retribution"
local mod = clcInfo:RegisterClassModule(modName)
local db

-- functions visible to exec should be attached to this
local emod = clcInfo.env

-- used for "pluging in"
local mainSkill, secondarySkill, ef

-- @defines
--------------------------------------------------------------------------------
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
local _inqId				= 84963
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
local _inqName		= GetSpellInfo(_inqId)
-- buffs
local _buffZeal = _zealName									-- zealotry
local _buffAW 	= GetSpellInfo(31884)				-- avenging wrath
local _buffHoL	= GetSpellInfo(90174)				-- hand of light
local _buffAoW	= GetSpellInfo(59578)				-- the art of war
local _buffInq 	= _inqName									-- inquisition

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
	[_inqName]			= true,
}

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
-- expose for options
mod.actionsName = actionsName
--------------------------------------------------------------------------------

-- working priority queue, skill 1, skill 2
local pq, s1, s2
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

--------------------------------------------------------------------------------
local lastgcd = 0
local waitforserver = false
local eq = 0
function RetRotation()
	-- get gcd value
	------------------------------------------------------------------------------
	_ctime = GetTime()
	start, duration = GetSpellCooldown(_gcdId)
	_gcd = start + duration - _ctime
	if _gcd < 0 then _gcd = 0 end
	
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
	_boost = db.csBoost or 0
	_haste = db.wspeed / UnitAttackSpeed("player")
	_hp = UnitPower("player", SPELL_POWER_HOLY_POWER)
	
	mod.GetBuffStatus()
	
	for i, v in ipairs(pq) do
		v.cd = actions[v.alias](i)
	end
	
	-- @hack
	if (_hp == 2 or _zeal > 0) and _csHack > 2 and (_ctime - _cstvHack) < 1 then
		pq[_tvIndexHack].cd = 0
	end
	
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
	
	-- put first skill at end of queue
	pq[sel].cd = 110
	
	-- second sort
	------------------------------------------------------------------------------
	-- get cooldowns again
	for i, v in ipairs(pq) do
		v.cd = actions2[v.alias](v.cd, xgcd)
	end
	
	-- sort again
	
	sel = 1
	
	for i = 2, #pq do
		if pq[i].cd < pq[sel].cd then
			sel = i
		end
	end
	s2 = pq[sel].id
	
	-- inquisition, if active and needed -> change first tv in s1 or s2 with inquisition
	------------------------------------------------------------------------------
	local preInq = db.preInq
	
	if db.useInq then
		local inqLeft = 0
		local _, _, _, _, _, _, expiration = UnitBuff("player", _buffInq, nil, "PLAYER")
		if expiration then 
			inqLeft = expiration - _ctime
		end
		
		-- test time for 2nd skill
		-- check for spell gcd?
		if (inqLeft - 1.5) <= preInq then
			if (s1 == _tvId or s1 == _dsId) and (inqLeft <= preInq) then
				s1 = _inqId
			elseif (s2 == _tvId or s2 == _dsId) and ((inqLeft - 1.5) <= preInq) then
				s2 = _inqId
			end
		end
	end
end
--------------------------------------------------------------------------------


-- plug in
--------------------------------------------------------------------------------
local notinit = true
local function ExecCleanup()
	ef:UnregisterAllEvents()
	mainSkill = nil
	notinit = true
end
local function DoInit()
	mainSkill = emod.___e
	mainSkill.ExecCleanup = ExecCleanup
	ef:RegisterEvent("UNIT_SPELLCAST_SENT")
	ef:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	notinit = false
end
function emod.IconRet1(...)
	if notinit then DoInit() end
	RetRotation(...)
	if secondarySkill then secondarySkill:DoUpdate() end
	return emod.IconSpell(s1, db.rangePerSkill or _csName)
end

local function SecondaryExec()
	return emod.IconSpell(s2, db.rangePerSkill or _csName)
end
local function ExecCleanup2()
	secondarySkill = nil
end
function emod.IconRet2(...)
	secondarySkill = emod.___e
	secondarySkill:SetScript("OnUpdate", nil)
	secondarySkill.exec = SecondaryExec
	secondarySkill.ExecCleanup = ExecCleanup2
end

-- utility and console commands
--------------------------------------------------------------------------------
-- event frame to track 
ef = CreateFrame("Frame") 
ef:Hide()
ef:SetScript("OnEvent", function(self, event, unit, spell)
	if unit == "player" and tracked[spell] then
		if event == "UNIT_SPELLCAST_SENT"then
			eq = eq + 1
		else -- UNIT_SPELLCAST_SUCCEEDED
			eq = 0
			waitforserver = false
			mainSkill:Highlight(false)
		end
	end
end)

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
	for k, v in ipairs(db.fillers) do
		if not check[v] then
			if v ~= "none" and actionsId[v] then
				pq[#pq + 1] = { alias = v, id = actionsId[v] }
				check[v] = true
			end
		end
	end
end

-- pass filler order from command line
-- intended to be used in macros
local function CmdRetFillers(args)
	-- add args to options
	local num = 0
	for i, arg in ipairs(args) do
		if actionsName[arg] then
			if num < MAX_FILLERS then
				num = num + 1
				db.fillers[num] = arg
			else
				print("too many fillers specified, max is " .. MAX_FILLERS)
			end
		else
			-- inform on wrong arguments
			print(arg .. " not found")
		end
	end
	
	-- none on the rest
	if num < MAX_FILLERS then
		for i = num + 1, MAX_FILLERS do
			db.fillers[i] = "none"
		end
	end
	
	-- redo queue
	mod.UpdatePriorityQueue()
	
	-- update the options window
	clcInfo:UpdateOptions()
end
-- register for slashcmd
clcInfo.cmdList["ret_fillers"] = CmdRetFillers

-- edit options from command line
local function CmdRetOptions(args)
	if not args[1] or not args[2] then
		print("format: /clcInfo ret_opt option value")
		return
	end
	
	if args[1] == "rangeperskill" then
		db.rangePerSkill = args[2] == "true" or false
	elseif args[1] == "wspeed" then
		db.wspeed = tonumber(args[2]) or defaults.wspeed
	elseif args[1] == "useinq" then
		db.useInq = args[2] == "true" or false
	elseif args[1] == "preinq" then
		db.preInq = tonumber(args[2]) or defaults.preInq
	elseif args[1] == "csboost" then
		db.csBoost = tonumber(args[2]) or defaults.csBoost
	else
		print("valid options: rangeperskill, csboost, wspeed, useinq, preinq")
	end
	
	clcInfo:UpdateOptions()
end
clcInfo.cmdList["ret_opt"] = CmdRetOptions

-- this function, if it exists, will be called at init
--------------------------------------------------------------------------------
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleDB(modName, defaults)
	
	-- @todo: clear this sometime
	-- version check
	if not db.version then
		clcInfo.cdb.classModules[modName] = defaults
		db = clcInfo.cdb.classModules[modName]
		print("clcInfo/ClassModules/Retribution:", "Settings have been reset to clear 3.x data. Sorry for the inconvenience.")
	end
	
	if db.version < 2 then
		clcInfo.SPD("CS and TV are again included into the rotation. Make sure to adjust your settings.")
		db.fillers = { "how", "tv", "cs", "exo", "j", "hw" }
	end
	
	if db.version < 3 then
		clcInfo.SPD("New settings and console commands were added to Retribution module.")
	end
	
	if db.version < version then
		clcInfo.AdaptConfigAndClean(modName .. "DB", db, defaults)
		db.version = version
	end
	
	mod.UpdatePriorityQueue()
end
