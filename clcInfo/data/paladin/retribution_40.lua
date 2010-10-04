-- build check
local _, _, _, toc = GetBuildInfo()
if toc < 40000 then return end


-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local GetTime = GetTime

-- default settings for this module
--------------------------------------------------------------------------------
local defaults = {
	rangePerSkill = false,
	fillers = { "exo", "j", "how", "hw" }
}

local MAX_FILLERS = 5

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule("retribution")
local db

-- functions visible to exec should be attached to this
local emod = clcInfo.env

-- rotations
local rmod = {}

-- any error sets this to false
local enabled = true

-- used for "pluging in"
local s2
local UpdateS2

local taowSpellName = GetSpellInfo(59578) 				-- the art of war
local spellHandOfLight = GetSpellInfo(90174)

-- priority queue generated from fillers
local pq
local ppq
-- number of spells in the queue
local numSpells
-- display queue
local dq = { "", "" }

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
}

local fillers = { exo = {}, how = {}, j = {}, hw = {} }

-- expose for options
mod.fillers = fillers

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleDB("retribution", defaults)
	if not db.fillers then db.fillers = { "exo", "j", "how", "hw" } end
	
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
				if not spells[alias] then
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
	local lastCount = #db.filler

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

-- returns the lowest cooldown and skill index
local function GetMinCooldown()
	local cd, index, v
	index = 1
	cd = pq[1].cd
	
	-- get min cooldown
	for i = 1, #pq do
		v = pq[i]
		if (v.cd < cd) or ((v.cd == cd and i < index)) then
			index = i
			cd = v.cd
		end
	end
	
	return cd, index
end

--------------------------------------------------------------------------------
--[[
test rotation:
tv 3 only
cs >>>> fillers
--]]
--------------------------------------------------------------------------------

function mod.RetRotation(csBoost, useInq, minHPInq, preInq)
	csBoost = csBoost or 0
	minHPInq = minHPInq or 3
	preInq = preInq or 5

	local ctime, gcd, gcdStart, gcdDuration, v
	ctime = GetTime()
	
	-- get gcd
	gcdStart, gcdDuration = GetSpellCooldown(spells.tv.name)
	if not gcdDuration then return end -- problem with the spell
	
	if gcdStart > 0 then
		gcd = gcdStart + gcdDuration - ctime
	else
		gcd = 0
	end

	-- update cooldowns
	for i = 1, #pq do
		v = pq[i]
		v.name = spells[v.alias].name
		
		v.cdStart, v.cdDuration = GetSpellCooldown(v.name)
		if not v.cdDuration then return end -- try to solve respec issues
		
		if v.cdStart > 0 then
			v.cd = v.cdStart + v.cdDuration - ctime
		else
			v.cd = 0
		end
		
		if v.alias == "how" then
			if not IsUsableSpell(v.name) then v.cd = 100 end
		elseif v.alias == "exo" then
			if UnitBuff("player", taowSpellName) == nil then v.cd = 100 end
		end
		
		-- adjust to gcd
		v.cd = v.cd - gcd
	end
	
	-- cs cooldown
	-- ff = first filler
	local cs, ff
	gcdStart, gcdDuration = GetSpellCooldown(spells.cs.name)
	if gcdStart > 0 then
		cs = gcdStart + gcdDuration - ctime
	else
		cs = 0
	end
	
	-- adjust for inq and tv
	-- holy balls
	local hp = UnitPower("player", SPELL_POWER_HOLY_POWER)
	local HoL = UnitBuff("player", spellHandOfLight)
	
	-- inquisition check
	local inqLeft = 0
	local name, rank, icon, count, debuffType, duration, expirationTime, caster, spellId
	if useInq then
		name, rank, icon, count, debuffType, duration, expirationTime = UnitBuff("player", spells.inq.name)
		if name then 
			inqLeft = expirationTime - ctime
		end
	end
	
	-- cs tests
	
	local mcd, index = GetMinCooldown()
	ff = pq[index].name
	
	-- print(cs, mcd)
	if cs == 0 or cs <= gcd then
		dq[1] = spells.cs.name
		if hp == 2 then dq[2] = spells.tv.name else dq[2] = ff end
	elseif mcd < cs then
		if cs - gcd < csBoost then
			dq[1] = spells.cs.name
			if hp == 2 then dq[2] = spells.tv.name else dq[2] = ff end
		else
			dq[1] = ff
			dq[2] = spells.cs.name
		end
	else
		dq[1] = spells.cs.name
		if hp == 2 then dq[2] = spells.tv.name else dq[2] = ff end
	end

	if useInq then
		if HoL then
			dq[2] = dq[1]
			if inqLeft <= preInq then
				dq[1] = spells.inq.name
			else
				dq[1] = spells.tv.name
			end
			
			if hp == 3 then dq[2] = spells.tv.name end
		else
			if inqLeft == 0 and hp >= minHPInq then
				dq[2] = dq[1]
				dq[1] = spells.inq.name
			elseif hp == 3 then
				dq[2] = dq[1]
				if inqLeft <= preInq then
					dq[1] = spells.inq.name
				else
					dq[1] = spells.tv.name
				end
			end
		end
	else
		if HoL then
			dq[2] = dq[1]
			dq[1] = spells.tv.name
			if hp == 3 then dq[2] = spells.tv.name end
		elseif hp == 3 then
			dq[2] = dq[1]
			dq[1] = spells.tv.name
		end
	end
	
	return true
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- emod. functions are usable by icon execs
-- S2 disables on update for that icon so that is called by first S1 update
--------------------------------------------------------------------------------
-- function to be executed when OnUpdate is called manually
local function S2Exec()
	if not enabled then return end
	return emod.IconSpell(dq[2], db.rangePerSkill or spells.cs.name)
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
		return emod.IconSpell(dq[1], db.rangePerSkill or spells.cs.name)
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