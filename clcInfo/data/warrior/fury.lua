-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "WARRIOR" then return end

local GetTime = GetTime
local version = 1


-- mod name in lower case
local modName = "_fury"

local defaults = {
	version = version,
	priorityList = {},
}

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule(modName)
local db
-- functions visible to exec should be attached to this
local emod = clcInfo.env

-- any error sets this to false
local enabled = true

-- spells used
local spellGCD		= 585		-- Rend for gcd

local spellBT 		= 23881	-- Bloodthirst
local spellRB			= 85288	-- Raging Blow
local spellHS			= 78		-- heroic strike
local spellSL			= 1464	-- Slam
local spellBS			= 6673	-- Battle Shout
local spellBR			= 18499	-- Berserker Rage
local spellEX			= 5308	-- Execute
local spellCS			= 86346	-- Colossus Smash
-- buff
local buffSurge		= GetSpellInfo(46915)		-- Bloodsurge
local buffEnrage	= GetSpellInfo(13046)		-- Enrage
local buffBerserk = GetSpellInfo(spellBR)	-- Enrage
-- debuff


-- list of actions available for the priority list
-- it's a list of functions that return cooldowns based on current status values
local actions = {}
-- when an action is selected, return is spell with the id from this table
local listActionId = {
	cs 		= spellCS,
	ex 		= spellEX,
	bt 		= spellBT,
	rb		= spellRB,
	bs		= spellBS,
	sl		= spellSL,
	
	-- hs		= spellHS,
	-- br		= spellBR,
}
-- names to display in option screen
local listActionName = {
	cs 		= GetSpellInfo(spellCS),
	ex 		= GetSpellInfo(spellEX),
	bt 		= GetSpellInfo(spellBT),
	rb		= GetSpellInfo(spellRB),
	bs		= GetSpellInfo(spellBS),
	sl		= GetSpellInfo(spellSL),
	
	-- hs		= GetSpellInfo(spellHS),
	-- br		= GetSpellInfo(spellBR),
}

-- status values
--------------------------------------------------------------------------------
local _gcd = 0 				-- current gcd value
local _ctime = 0 			-- current GetTime value
local _rage = 0				-- amount of rage :p
local _ragehs = 0			-- rage needed before we hs
local _ragesl = 0
local _surge = 0			-- bloodsurge duration
local _enrage = 0			-- enrage duration
local _br	= 0 				-- have br cooldown in status
local _hs = 0					-- used to not call actions.hs multiple times
--------------------------------------------------------------------------------

local pq, dq1, dq2
local mode = "single"

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleDB(modName, defaults)
	db.priorityList = { "cs", "ex", "bt", "rb", "sl" } 
	mod.UpdatePriorityList()
end

function mod.UpdatePriorityList()
	pq = {}
	local check = {} -- used to check for duplicates
	for k, v in ipairs(db.priorityList) do
		if not check[v] then
			if v ~= "none" and listActionId[v] then
				pq[#pq + 1] = { alias = v, id = listActionId[v] }
				check[v] = true
			end
		end
	end
end

-- action functions
-- if a function can be selected, then the function must be here
--------------------------------------------------------------------------------
function actions.bt()
	local start, duration = GetSpellCooldown(spellBT)
	local cd = start + duration - _ctime - _gcd
	if cd < 0 then cd = 0 end
	return cd
end

function actions.rb()
	if _enrage <= 0 and _br > _gcd then
		return 3
	else		
		local start, duration = GetSpellCooldown(spellRB)
		local cd = start + duration - _ctime - _gcd
		if cd < 0 then cd = 0 end
		return cd	
	end
end

function actions.sl()
	if _surge > (_gcd + 0.2) and _rage >= _ragesl then
		return 0
	else
		return 5
	end
end

function actions.bs()
	if _rage > 80 then return 5 end  -- rage check
	
	local start, duration = GetSpellCooldown(spellBS)
	local cd = start + duration - _ctime - _gcd
	if cd < 0 then cd = 0 end
	return cd
end
function actions.hs()
	local start, duration = GetSpellCooldown(spellHS)
	local cd = start + duration - _ctime
	if cd < 0 then cd = 0 end
	_hs = cd
	return cd
end

function actions.cs()
	local start, duration = GetSpellCooldown(spellCS)
	local cd = start + duration - _ctime - _gcd
	if cd < 0 then cd = 0 end
	return cd
end

function actions.ex()
	if IsUsableSpell(spellEX) then
		return 0
	end
	return 100
end
--------------------------------------------------------------------------------

mod.Rotation = {}
function mod.Rotation.single(ragehs, ragesl)
	_ctime = GetTime()
	
	-- gcd
	local start, duration = GetSpellCooldown(spellGCD)
	_gcd = start + duration - _ctime
	if _gcd < 0 then _gcd = 0 end
	
	start, duration = GetSpellCooldown(spellBR)
	_br = start + duration - _ctime
	if _br < 0 then _br = 0 end
	
	-- rage
	_rage = UnitPower("player")
	_ragehs = ragehs or 50
	_ragesl = ragesl or 80
	
	-- bloodsurge
	local _, _, _, _, _, _, expires = UnitBuff("player", buffSurge, nil, "PLAYER")
	if expires then _surge = expires - _ctime - _gcd else _surge = 0 end
	-- enrage
	_, _, _, _, _, _, expires = UnitBuff("player", buffEnrage, nil, "PLAYER")
	if expires then _enrage = expires - _ctime - _gcd else _enrage = 0 end
	if _enrage <= 0 then
		-- check for berserker rage
		_, _, _, _, _, _, expires = UnitBuff("player", buffBerserk, nil, "PLAYER")
		if expires then _enrage = expires - _ctime - _gcd else _enrage = 0 end
	end
	
	
	for i, v in ipairs(pq) do
		v.cd = actions[v.alias]()
	end
	
	local sel = 1
	local cd = pq[1].cd
	
	for i = 2, #pq do
		if pq[i].cd < pq[sel].cd then
			sel = i
			cd = pq[i].cd
		end
	end
	
	dq1 = pq[sel].id
	
	dq2 = 0
	if _rage >= _ragehs and _hs == 0 then
		dq2 = spellHS
	end
		
	return true
end

--------------------------------------------------------------------------------
-- function to be executed when OnUpdate is called manually
local function S2Exec()
	if not enabled then return end
	if dq2 ~= 0 then
		return emod.IconSpell(dq2, true)
	end
	return false
end
-- cleanup function for when exec changes
local function ExecCleanup()
	s2 = nil
end
function emod.IconFury1(...)
	local gotskill = false
	if enabled then
		gotskill = mod.Rotation[mode](...)
	end
	
	if s2 then UpdateS2(s2, 100) end	-- update with a big "elapsed" so it's updated on call
	if gotskill then
		return emod.IconSpell(dq1, true)
	end
end
function emod.IconFury2()
	-- remove this button's OnUpdate
	s2 = emod.___e
	UpdateS2 = s2:GetScript("OnUpdate")
	s2:SetScript("OnUpdate", nil)
	s2.exec = S2Exec
	s2.ExecCleanup = ExecCleanup
end
function emod.FuryMode() return mode end