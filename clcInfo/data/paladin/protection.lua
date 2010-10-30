-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local GetTime = GetTime

-- mod name in lower case
local modName = "_protection"
local version = 1

-- default settings for this module
--------------------------------------------------------------------------------
local defaults = {
	version = version,
	
	rangePerSkill = false,
	fillers = { "sor", "cs", "j", "as", "hw" },
}

local MAX_FILLERS = 9

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule(modName)
local db

-- functions visible to exec should be attached to this
local emod = clcInfo.env

-- any error sets this to false
local enabled = true

-- used for "pluging in"
local s2
local UpdateS2

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
	sor		= { id = 53600	},		-- shield of the righteous
	inq 	= { id = 84963	},		-- inquisition
	hotr	= { id = 53595 	},		-- hammer of the righteous
	j 		= { id = 20271 	},		-- judgement
	as 		= { id = 31935	},		-- avenger's shield
	cons 	= { id = 26573 	},		-- consecration
	hw		= { id = 2812  	},		-- holy wrath
	cls 	= { id = 4987		},		-- cleanse
}
local spellHotR, spellCS, spellSoR, spellInq, spellCleanse

local fillers = { sor = {}, cs = {}, as = {}, how = {}, j = {}, hw = {}, cons = {}, hotr = {} }

-- expose for options
mod.fillers = fillers

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleDB(modName, defaults)
	
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
	spellCS, spellSoR, spellHotR, spellInq, spellCleanse = spells.cs.name, spells.sor.name, spells.hotr.name, spells.inq.name, spells.cls.name
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
local function CmdProtFillers(args)
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
clcInfo.cmdList["prot_fillers"] = CmdProtFillers

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- priority queue
--------------------------------------------------------------------------------
function mod.ProtRotation(useInq, preInq)
	local boost = 1

	local ctime, cdStart, cdDuration, cs, gcd
	ctime = GetTime()
	
	local preBoost = true -- skils before CS are boosted too

	-- get HP, HoL
	local hp = UnitPower("player", SPELL_POWER_HOLY_POWER)
	
	-- gcd
	cdStart, cdDuration = GetSpellCooldown(20154)	-- Seal of Righteousness used for GCD
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
		if preBoost then v.cd = v.cd - boost end
		
		if v.alias == "how" then
			if not IsUsableSpell(v.name) then
				v.cd = 100
			end
		-- sor = inq
		elseif v.alias == "sor" or v.alias == "inq" then
			if hp ~= 3 then
				v.cd = 15
			end
		-- cs = hotr
		elseif v.alias == "cs" or v.alias == "hotr" then
			preBoost = false
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
	if dq1 == spellCS or dq1 == spellHotR then
		hp = hp + 1
	elseif dq1 == spellSoR or dq1 == spellInq then
		hp = 0
	end
	pq[index].cd = 101 -- put first one at end of queue
	
	-- get new clamped cooldowns
	for i = 1, #pq do
		v = pq[i]
		if v.name == spellSoR or v.name == spellInq then
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
function emod.IconProtection1(...)
	local gotskill = false
	if enabled then
		gotskill = mod.ProtRotation(...)
	end
	
	if s2 then UpdateS2(s2, 100) end	-- update with a big "elapsed" so it's updated on call
	if gotskill then
		return emod.IconSpell(dq1, db.rangePerSkill or spellCS)
	end
end
function emod.IconProtection2()
	-- remove this button's OnUpdate
	s2 = emod.___e
	UpdateS2 = s2:GetScript("OnUpdate")
	s2:SetScript("OnUpdate", nil)
	s2.exec = S2Exec
	s2.ExecCleanup = ExecCleanup
end
--------------------------------------------------------------------------------
