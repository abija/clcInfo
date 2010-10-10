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
	cls 	= { id = 4987		},		-- cleanse
}

local fillers = { exo = {}, how = {}, j = {}, hw = {}, cons = {} }

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
cs < filler + csBoost -> cs
--]]
--------------------------------------------------------------------------------

function mod.RetRotation(csBoost, useInq, preInq)
	csBoost = csBoost or 0
	minHPInq = minHPInq or 3
	preInq = preInq or 5

	local ctime, cdStart, cdDuration, cs, gcd
	ctime = GetTime()
	
	-- get HP, HoL
	local hp = UnitPower("player", SPELL_POWER_HOLY_POWER)
	local hol = UnitBuff("player", spellHandOfLight) or false
	
	if hp == 3 and hol then
		-- got lucky, double tv
		dq[1] = spells.tv.name
		dq[2] = spells.tv.name
	else
		-- didn't get lucky, find out cs + filler cooldowns
		
		-- gcd
		cdStart, cdDuration = GetSpellCooldown(spells.cls.name)
		if cdStart > 0 then
			gcd = cdStart + cdDuration - ctime
		else
			gcd = 0
		end
		
		-- cs
		cdStart, cdDuration = GetSpellCooldown(spells.cs.name)
		if cdStart > 0 then
			cs = cdStart + cdDuration - ctime
		else
			cs = 0
		end
		cs = cs - gcd - csBoost
		
		if hp == 3 or hol then
			-- tv + x
			dq[1] = spells.tv.name
			
			-- everything now is delayed by 1.5s
			cs = cs - 1.5  -- adjust cs
			
			-- test maybe we don't need to check rest of cooldowns
			if cs <= 0 then
				-- got lucky, tv + cs
				dq[2] = spells.cs.name
			else
				-- get cooldowns for fillers
				local v, cd, index
				
				for i = 1, #pq do
					v = pq[i]
					v.name = spells[v.alias].name
					
					cdStart, cdDuration = GetSpellCooldown(v.name)
					if cdStart > 0 then
						v.cd = cdStart + cdDuration - ctime - 1.5 - gcd
					else
						v.cd = 0
					end
					
					if v.alias == "how" then
						if not IsUsableSpell(v.name) then v.cd = 100 end
					elseif v.alias == "exo" then
						if UnitBuff("player", taowSpellName) == nil then v.cd = 100 end
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
				
				-- test vs cs
				if cs <= cd then
					-- tv + cs
					dq[2] = spells.cs.name
				else
					-- tv + f1
					dq[2] = pq[index].name
				end
			end
		else
			-- no tv -> it's either cs + filler or 2 fillers
			-- TODO : is 2 fillers even viable at low haste?
			
			-- get cooldowns for fillers
			local v, cd, index
			
			for i = 1, #pq do
				v = pq[i]
				v.name = spells[v.alias].name
				
				cdStart, cdDuration = GetSpellCooldown(v.name)
				if cdStart > 0 then
					v.cd = cdStart + cdDuration - ctime - gcd
				else
					v.cd = 0
				end
				
				if v.alias == "how" then
					if not IsUsableSpell(v.name) then v.cd = 100 end
				elseif v.alias == "exo" then
					if UnitBuff("player", taowSpellName) == nil then v.cd = 100 end
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
			
			-- test vs cs
			if cs <= cd then
				-- cs + f1
				dq[1] = spells.cs.name
				if hp == 2 then
					-- 3 hp ability
					dq[2] = spells.tv.name
				else
					dq[2] = pq[index].name
				end
			else
				-- f1 + cs or f2
				dq[1] = pq[index].name
				
				-- delay everything by 1.5 now
				-- todo: take haste into account here, since s1 might be a spell
				cs = cs - 1.5
				
				-- one more hope with cs
				if cs <= 0 then
					-- f1 + cs
					dq[2] = spells.cs.name
				else
					-- worst case scenario possible
					pq[index].cd = 1000 -- delay last used skill a lot
					
					-- get new clamped cooldowns
					for i = 1, #pq do
						v.cd = v.cd - 1.5
						if v.cd < 0 then v.cd = 0 end
					end
					
					-- get min again
					index = 1
					cd = pq[1].cd
					for i = 1, #pq do
						v = pq[i]
						if (v.cd < cd) or ((v.cd == cd) and (i < index)) then
							index = i
							cd = v.cd
						end
					end
						
					-- test vs cs
					if cs <= cd then
						-- f1 + cs
						dq[2] = spells.cs.name
					else
						-- f1 + f2
						dq[2] = pq[index].name
					end
				end
			end
			
		end
	end
	
	-- inquisition, if active and needed -> change first tv in dq1 or dq2 with inquisition
	if useInq then
		local inqLeft = 0
		local name, rank, icon, count, debuffType, duration, expirationTime = UnitBuff("player", spells.inq.name)
		if name then 
			inqLeft = expirationTime - ctime
		end
		
		-- test time for 2nd skill
		-- check for spell gcd?
		if (inqLeft - 1.5) <= preInq then
			if (dq[1] == spells.tv.name) and (inqLeft <= preInq) then
				dq[1] = spells.inq.name
			elseif (dq[2] == spells.tv.name) and ((inqLeft - 1.5) <= preInq) then
				dq[2] = spells.inq.name
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