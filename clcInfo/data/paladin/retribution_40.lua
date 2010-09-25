-- build check
local _, _, _, toc = GetBuildInfo()
if toc < 40000 then return end


-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\data\\paladin\\retribution> " .. table.concat(t, " "))
end

-- default settings for this module
--------------------------------------------------------------------------------
local defaults = {
	rangePerSkill = false,
}

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule(class, "retribution")
local db

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleDB(class, "retribution", defaults)
	
	mod:InitSpells()
end

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

-- priority queue generated from fcfs
local pq
local ppq
-- number of spells in the queue
local numSpells
-- display queue
local dq = { "", "" }

-- the spells available for the fcfs
local spells = {
	how		= { id = 24275 	},		-- hammer of wrath
	cs 		= { id = 35395 	},		-- crusader strike
	tv 		= { id = 85256 	},		-- templar's verdict
	tv1 	= { id = 85256 	},		-- templar's verdict
	tv2		= { id = 85256 	},		-- templar's verdict
	tv3 	= { id = 85256 	},		-- templar's verdict
	inq 	= { id = 84963	},		-- inquisition
	ds 		= { id = 53385 	},		-- divine storm
	jol 	= { id = 20271 	},		-- judgement
	cons 	= { id = 26573 	},		-- consecration
	exo 	= { id = 879 		},		-- exorcism
	hw		= { id = 2812  	},		-- holy wrath
}

-- get the spell names from ids
function mod.InitSpells()
	for alias, data in pairs(spells) do
		data.name = GetSpellInfo(data.id)
	end
end

--	algorithm:
--		get min cooldown
--		adjust all the others to cd - mincd - 1.5
--		get min cooldown

-- returns the lowest cooldown and skill index
local function GetMinCooldown()
	local cd, index, v
	index = 1
	cd = pq[1].cd
	-- old bug, fix them even if they are first
	if (pq[1].alias == "dp" and delayDP) or (pq[1].alias == "ss") then
		cd = cd + db.gcdDpSs
	end
	
	-- get min cooldown
	for i = 1, #pq do
		v = pq[i]
		-- if skill is a better choice change index
		if (v.alias == "dp" and delayDP) or (v.alias == "ss") then	
			-- special case with delay
			if ((v.cd + db.gcdDpSs) < cd) or (((v.cd + db.gcdDpSs) == cd) and (i < index)) then
				index = i
				cd = v.cd
			end
		else
			-- normal check
			if (v.cd < cd) or ((v.cd == cd and i < index)) then
				index = i
				cd = v.cd
			end
		end
	end
	
	return cd, index
end

-- gets first and 2nd skill in the queue
local function GetSkills()
	local cd, index, v
	
	-- dq[1] = skill with shortest cooldown
	cd, index = GetMinCooldown()
	dq[1] = pq[index].name
	pq[index].cd = 100
	
	-- adjust cd
	cd = cd + 1.5
	
	-- substract the cd from prediction cooldowns
	for i = 1, #pq do
		v = pq[i]
		if (dq[1].name == spells.tv.name) and (v.name == "tv1" or v.name == "tv2" or v.name == "tv3") then
			v.cd = 100
		else
			v.cd = max(0, v.cd - cd)
		end
	end
	
	-- dq[2] = get the skill with shortest cooldown
	cd, index = GetMinCooldown()
	dq[2] = pq[index].name
end

--------------------------------------------------------------------------------
--[[
test rotation r2:
put priority on tv2 and tv1
--]]
--------------------------------------------------------------------------------
do
	local xq = {
		{ alias = "tv3" },
		{ alias = "cs" },
		{ alias = "how" },
		{ alias = "tv2" },
		{ alias = "jol" },
		{ alias = "exo" },
		{ alias = "hw" },
		{ alias = "tv1" },
	}
	function rmod.r2(csBoost, useInq, minHPInq, preInq)
		csBoost = csBoost or 0
		minHPInq = minHPInq or 3
		preInq = preInq or 5
	
		pq = xq
	
		local ctime, gcd, gcdStart, gcdDuration, v
		ctime = GetTime()
		
		-- get gcd
		gcdStart, gcdDuration = GetSpellCooldown(spells.tv.name)
		if gcdStart > 0 then
			gcd = gcdStart + gcdDuration - ctime
		else
			gcd = 0
		end
		
		-- adjust for inq and tv
		-- holy balls
		local hp = UnitPower("player", SPELL_POWER_HOLY_POWER)
		local HoL = UnitBuff("player", spellHandOfLight)
	
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
			
			if v.alias == "tv1" and (hp ~= 1 or HoL) then
				v.cd = 100
			elseif v.alias == "tv2" and (hp ~= 2 or HoL) then
				v.cd = 100
			elseif v.alias == "tv3" and (hp ~= 3 and (not HoL)) then
				v.cd = 100
			elseif v.alias == "cs" then
				v.cd = v.cd - csBoost
			elseif v.alias == "how" then
				if not IsUsableSpell(v.name) then v.cd = 100 end
			elseif v.alias == "exo" then
				if UnitBuff("player", taowSpellName) == nil then v.cd = 100 end
			end
			
			-- adjust to gcd
			v.cd = v.cd - gcd
		end
		
		GetSkills()
		
		clcInfo.spew = { dq, pq }
		
		local inqLeft = 0
		local name, rank, icon, count, debuffType, duration, expirationTime, caster, spellId
		if useInq then
			name, rank, icon, count, debuffType, duration, expirationTime = UnitBuff("player", spells.inq.name)
			if name then 
				inqLeft = expirationTime - ctime
			end
		end
		
		if useInq then
			if HoL then
				dq[2] = dq[1]
				if inqLeft <= preInq then
					dq[1] = spells.inq.name
				else
					dq[1] = spells.tv.name
				end
			else
				if inqLeft == 0 and hp >= minHPInq then
					dq[2] = dq[1]
					dq[1] = spells.inq.name
				end
			end
		else
			if HoL then
				dq[2] = dq[1]
				dq[1] = spells.tv.name
			end
		end
		
		return true
	end
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--[[
test rotation r1:
tv 3 only
cs >>>> fillers
--]]
--------------------------------------------------------------------------------
do
	local xq = {
		{ alias = "how" },
		{ alias = "jol" },
		{ alias = "exo" },
		{ alias = "hw" },
	}
	function rmod.r1(useInq, minHPInq, preInq)
		minHPInq = minHPInq or 3
		preInq = preInq or 5
	
		pq = xq
	
		local ctime, gcd, gcdStart, gcdDuration, v
		ctime = GetTime()
		
		-- get gcd
		gcdStart, gcdDuration = GetSpellCooldown(spells.tv.name)
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
		
		-- cs bullshit
		
		local mcd, index = GetMinCooldown()
		ff = pq[index].name
		
		-- bprint(cs, mcd)
		if cs == 0 or cs <= gcd then
			dq[1] = spells.cs.name
			dq[2] = ff
		elseif mcd < cs then
			if cs - gcd < 1.1 then
				dq[1] = spells.cs.name
				dq[2] = ff
			else
				dq[1] = ff
				dq[2] = spells.cs.name
			end
		else
			dq[1] = spells.cs.name
			dq[2] = ff
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
function emod.IconRetFCFS_S1(rotation, ...)
	local gotskill = false
	if enabled then
		if rmod[rotation] then
			gotskill = rmod[rotation](...)
		end
	end
	
	if s2 then UpdateS2(s2, 100) end	-- update with a big "elapsed" so it's updated on call
	if gotskill then
		return emod.IconSpell(dq[1], db.rangePerSkill or spells.cs.name)
	end
end
function emod.IconRetFCFS_S2()
	-- remove this button's OnUpdate
	s2 = emod.cIcon
	s2.externalUpdate = true
	UpdateS2 = s2:GetScript("OnUpdate")
	s2:SetScript("OnUpdate", nil)
	s2.exec = S2Exec
	s2.ExecCleanup = ExecCleanup
end
--------------------------------------------------------------------------------