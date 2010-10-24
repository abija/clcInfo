-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local GetTime = GetTime

-- default settings for this module
--------------------------------------------------------------------------------
local defaults = {
	version = 2,
	
	rangePerSkill = false,
	fillers = { "how", "tv", "cs", "exo", "j", "hw" },
}

local MAX_FILLERS = 9

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule("retribution")
local db

-- functions visible to exec should be attached to this
local emod = clcInfo.env

-- any error sets this to false
local enabled = true

-- used for "pluging in"
local s2
local UpdateS2

local buffTheArtOfWar = GetSpellInfo(59578)
local buffHandOfLight = GetSpellInfo(90174)
local buffZealotry = GetSpellInfo(85696)

-- priority queue generated from fillers
local pq
-- number of spells in the queue
local numSpells
-- display queue
local dq1, dq2

-- spells used
local spells = {
	how		= { id = 24275 	},		-- hammer of wrath
	cs 		= { id = 35395 	},		-- crusader strike
	tv 		= { id = 85256 	},		-- templar's verdict
	inq 	= { id = 84963	},		-- inquisition
	ds 		= { id = 53385 	},		-- divine storm
	j 		= { id = 20271 	},		-- judgement
	cons 	= { id = 26573 	},		-- consecration
	exo 	= { id = 879 		},		-- exorcism
	hw		= { id = 2812  	},		-- holy wrath
	cls 	= { id = 4987		},		-- cleanse
}
local spellDS, spellCS, spellTV, spellInq, spellCleanse

local fillers = { tv = {}, cs = {}, exo = {}, how = {}, j = {}, hw = {}, cons = {}, ds = {} }

-- expose for options
mod.fillers = fillers

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleDB("retribution", defaults)
	
	-- version check
	if not db.version then
		clcInfo.cdb.classModules["retribution"] = defaults
		db = clcInfo.cdb.classModules["retribution"]
		print("clcInfo/ClassModules/Retribution:", "Settings have been reset to clear 3.x data. Sorry for the inconvenience.")
	end
	
	if db.version < 2 then
		clcInfo.SPD("CS and TV are again included into the rotation. Make sure to adjust your settings.")
		db.fillers = { "how", "tv", "cs", "exo", "j", "hw" }
		db.version = 2
	end
	
	mod:InitSpells()
	mod.UpdateFillers()
end

-- get the spell names from ids
function mod.InitSpells()
	for alias, data in pairs(spells) do
		data.name = GetSpellInfo(data.id)
	end
	
	for alias, data in pairs(fillers) do
		data.id = spells[alias].id
		data.name = spells[alias].name
	end
	
	-- to be easier to access
	spellCS, spellTV, spellDS, spellInq, spellCleanse = spells.cs.name, spells.tv.name, spells.ds.name, spells.inq.name, spells.cls.name
end

function mod.UpdateFillers()
	local newpq = {}
	local check = {}
	numSpells = 0
	
	for i, alias in ipairs(db.fillers) do
		if not check[alias] then -- take care of double entries
			check[alias] = true
			if alias ~= "none" then
				-- fix blank entries
				if not fillers[alias] then
					db.fillers[i] = "none"
				else
					numSpells = numSpells + 1
					newpq[numSpells] = { alias = alias, name = fillers[alias].name }
				end
			end
		end
	end
	
	pq = newpq
end

function mod.DisplayFillers()
	print("Current filler order:")
	for i, data in ipairs(pq) do
		print(i .. " " .. data.name)
	end
end

-- pass filler order from command line
-- intended to be used in macros
local function CmdRetFillers(args)
	local lastCount = #db.fillers

	-- add args to options
	local num = 0
	for i, arg in ipairs(args) do
		if fillers[arg] then
			num = num + 1
			db.fillers[num] = arg
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
	mod.UpdateFillers()
	
	-- update the options window
	clcInfo:UpdateOptions()
end

-- register for slashcmd
clcInfo.cmdList["ret_fillers"] = CmdRetFillers

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- rotation: priority system
--------------------------------------------------------------------------------
function mod.RetRotation(csBoost, useInq, preInq)
	csBoost = csBoost or 0
	useInq = useInq or false
	preInq = preInq or 5

	local ctime, cdStart, cdDuration, cs, gcd
	ctime = GetTime()
	
	local startCS, startHp
	
	local preCS = true -- skils before CS are boosted too

	-- get HP, HoL
	local hp = UnitPower("player", SPELL_POWER_HOLY_POWER)
	startHp = hp
	local hol = UnitBuff("player", buffHandOfLight) or false
	local zeal = UnitBuff("player", buffZealotry) or false
	
	-- gcd
	cdStart, cdDuration = GetSpellCooldown(20154) -- Seal of Righteousness used for GCD
	if cdStart > 0 then
		gcd = cdStart + cdDuration - ctime
	else
		gcd = 0
	end
	
	-- get cooldowns for fillers
	local v, cd, index
	
	for i = 1, #pq do
		v = pq[i]
		
		cdStart, cdDuration = GetSpellCooldown(v.name)
		if cdStart > 0 then
			v.cd = cdStart + cdDuration - ctime - gcd
		else
			v.cd = 0
		end
		
		-- boost skills before CS
		if preCS then v.cd = v.cd - csBoost end
		
		if v.alias == "how" then
			if not IsUsableSpell(v.name) then
				v.cd = 100
			end
		elseif v.alias == "tv" or v.alias == "ds" then
			if not (hol or hp == 3) then
				v.cd = 15
			end
		elseif v.alias == "cs" then
			startCS = v.cd + csBoost - 0.1
			preCS = false
		elseif v.alias == "exo" then
			if UnitBuff("player", buffTheArtOfWar) == nil then v.cd = 100 end
		end
		
		-- clamp so sorting is proper
		if v.cd < 0 then v.cd = 0 end
	end
	
	-- sort cooldowns once, get min cd and the index in the table
	index = 1
	cd = pq[1].cd
	for i = 1, #pq do
		v = pq[i]
		if (v.cd < cd) or ((v.cd == cd) and (i < index)) then
			index = i
			cd = v.cd
		end
	end
	
	dq1 = pq[index].name
	
	-- adjust hp for next skill
	if dq1 == spellCS then
		if zeal then
			hp = hp + 3
		else
			hp = hp + 1
		end
	elseif (dq1 == spellTV or dq1 == spellDS) and not hol then
		hp = 0
	end
	pq[index].cd = 101 -- put first one at end of queue
	
	-- get new clamped cooldowns
	for i = 1, #pq do
		v = pq[i]
		if v.name == spellTV or v.name == spellDS then
			if hp >= 3 then
				v.cd = 0
			else
				v.cd = 100
			end
		else
			v.cd = v.cd - 1.5 - cd
			if v.cd < 0 then v.cd = 0 end
		end
	end
	
	-- sort again
	index = 1
	cd = pq[1].cd
	for i = 1, #pq do
		v = pq[i]
		if (v.cd < cd) or ((v.cd == cd) and (i < index)) then
			index = i
			cd = v.cd
		end
	end
	dq2 = pq[index].name
	
	-- check for hol + hp < 2 
	if hol and startHp < 3 and startCS <= 0 then
		dq1 = spellCS
		dq2 = spellTV
	end
	
	-- inquisition, if active and needed -> change first tv in dq1 or dq2 with inquisition
	if useInq then
		local inqLeft = 0
		local name, rank, icon, count, debuffType, duration, expirationTime = UnitBuff("player", spellInq)
		if name then 
			inqLeft = expirationTime - ctime
		end
		
		-- test time for 2nd skill
		-- check for spell gcd?
		if (inqLeft - 1.5) <= preInq then
			if (dq1 == spellTV or dq1 == spellDS) and (inqLeft <= preInq) then
				dq1 = spellInq
			elseif (dq2 == spellTV or dq2 == spellDS) and ((inqLeft - 1.5) <= preInq) then
				dq2 = spellInq
			end
		end
	end
	
	return true	-- if not true, addon does nothing
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- emod. functions are usable by icon execs
-- S2 disables on update for that icon so that is called by first S1 update
--------------------------------------------------------------------------------
-- function to be executed when OnUpdate is called manually
local function S2Exec()
	if not enabled then return end
	return emod.IconSpell(dq2, db.rangePerSkill or spellCS)
end
-- cleanup function for when exec changes
local function ExecCleanup()
	s2 = nil
end
function emod.IconRet1(...)
	local gotskill = false
	if enabled then
		gotskill = mod.RetRotation(...)
	end
	
	if s2 then UpdateS2(s2, 100) end	-- update with a big "elapsed" so it's updated on call
	if gotskill then
		return emod.IconSpell(dq1, db.rangePerSkill or spellCS)
	end
end
function emod.IconRet2()
	-- remove this button's OnUpdate
	s2 = emod.___e
	s2.externalUpdate = true
	UpdateS2 = s2:GetScript("OnUpdate")
	s2:SetScript("OnUpdate", nil)
	s2.exec = S2Exec
	s2.ExecCleanup = ExecCleanup
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- various other rotation tries
--------------------------------------------------------------------------------
local rotations = {}

-- // test r1
do
	-- @findme
	-- rearange this list to change priority
	local pq = {
		{ alias = "how" },
		{ alias = "tv" },
		{ alias = "cs" },
		{ alias = "exo" },
		{ alias = "j" },
		{ alias = "hw" },
	}
	function rotations.r1(csBoost)
	end -- //
end
-- // test r1

function emod.IconRet1Ex(rotation, ...)
	local gotskill = false
	if enabled then
		gotskill = rotations[rotation](...)
	end
	
	if s2 then UpdateS2(s2, 100) end	-- update with a big "elapsed" so it's updated on call
	if gotskill then
		return emod.IconSpell(dq1, db.rangePerSkill or spellCS)
	end
end