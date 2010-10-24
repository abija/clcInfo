-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PRIEST" then return end

local GetTime = GetTime


-- mod name in lower case
local modName = "_shadow"

local defaults = {
	version = 1,
	priorityList = { "swp", "vt", "dp", "mb", "none" },
}

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule(modName)
local db
-- functions visible to exec should be attached to this
local emod = clcInfo.env

-- any error sets this to false
local enabled = true

-- spells used
local spellGCD		= 585		-- Smite for gcd

local spellMB 		= 8092	-- Mind Blast
local spellVT 		= 34914	-- Vampiric Touch
local spellDP 		= 2944	-- Devouring Plague
local spellMF 		= 15407	-- Mind Flay
local spellSWP 		= 589		-- Shadow Word: Pain
local spellSWD 		= 32379 -- Shadow Word: Death
local spellMS 		= 48045	-- Mind Sear
-- debuff
local debuffSWP 	= GetSpellInfo(spellSWP)
local debuffVT 		= GetSpellInfo(spellVT)
local debuffDP		= GetSpellInfo(spellDP)

-- list of actions available for the priority list
-- it's a list of functions that return cooldowns based on current status values
local actions = {}
-- when an action is selected, return is spell with the id from this table
local listActionId = {
	mb 		= spellMB,
	vt 		= spellVT,
	dp 		= spellDP,
	mf 		= spellMF,
	swp 	= spellSWP,
	swd 	= spellSWD,
	ms 		= spellMS,
}
-- names to display in option screen
local listActionName = {
	mb 		= GetSpellInfo(spellMB),
	vt 		= GetSpellInfo(spellVT),
	mf 		= GetSpellInfo(spellMF),
	dp 		= GetSpellInfo(spellDP),
	swp 	= GetSpellInfo(spellSWP),
	swd 	= GetSpellInfo(spellSWD),
	ms 		= GetSpellInfo(spellMS),	
}

-- status values
--------------------------------------------------------------------------------
local _swp = 0	-- swp duration on target
local _vt = 0	-- vt duration on target
local _dp = 0 -- dp duration on target
local _gcd = 0 -- current gcd value
local _ctime = 0 -- current GetTime value
--------------------------------------------------------------------------------

local pq, dq1, dq2
local mode = "single"

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleDB(modName, defaults)
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

mod.Rotation = {}
function mod.Rotation.single()
	-- needs valid target
	if not (UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")) then return end
	
	_ctime = GetTime()
	
	-- gcd
	local start, duration = GetSpellCooldown(spellGCD)
	_gcd = start + duration - _ctime
	if _gcd < 0 then _gcd = 0 end
	
	-- swp
	local _, _, _, _, _, _, expires = UnitDebuff("target", debuffSWP, nil, "PLAYER")
	if expires then _swp = expires - _ctime else _swp = 0 end
	-- vt
	_, _, _, _, _, _, expires = UnitDebuff("target", debuffVT, nil, "PLAYER")
	if expires then _vt = expires - _ctime else _vt = 0 end
	-- dp
	_, _, _, _, _, _, expires = UnitDebuff("target", debuffDP, nil, "PLAYER")
	if expires then _dp = expires - _ctime else _dp = 0 end
	
	-- debuging: print status
	print(_ctime, _gcd, _swp, _vt, _dp)
	
	dq1 = spellMB
	return true
end

function emod.IconShadow1()
	local gotskill = false
	if enabled then
		gotskill = mod.Rotation[mode]()
	end
	if gotskill then
		return emod.IconSpell(dq1, true)
	end
end
function emod.ShadowMode() return mode end