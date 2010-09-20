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

-- create a module in the main addon
if not clcInfo.classModules then clcInfo.classModules = {} end
if not clcInfo.classModules.paladin then clcInfo.classModules.paladin = {} end
clcInfo.classModules.paladin.retribution = {}
local mod = clcInfo.classModules.paladin.retribution

-- environment mod, functions added here are visible to execs
local emod = clcInfo.env


-- any error sets this to false
local enabled = true

-- temp options
local db

-- used for "pluging in"
local s2
local UpdateS2

-- cleanse spell name, used for gcd
local cleanseSpellName = GetSpellInfo(4987)

-- various other spells
local taowSpellName = GetSpellInfo(59578) 				-- the art of war
local sovName, sovId, sovSpellTexture
if UnitFactionGroup("player") == "Alliance" then
	sovId = 31803
	sovName = GetSpellInfo(31803)						-- holy vengeance
	sovSpellTexture = GetSpellInfo(31801)
else
	sovId = 53742
	sovName = GetSpellInfo(53742)						-- blood corruption
	sovSpellTexture = GetSpellInfo(53736)
end

-- priority queue generated from fcfs
local pq
local ppq
-- number of spells in the queue
local numSpells
-- display queue
local dq = { cleanseSpellName, cleanseSpellName }

-- the spells available for the fcfs
local spells = {
		how		= { id = 48806 },		-- hammer of wrath
		cs 		= { id = 35395 },		-- crusader strike
		ds 		= { id = 53385 },		-- divine storm
		jud 	= { id = 53408 },		-- judgement (using wisdom atm)
		cons 	= { id = 48819 },		-- consecration
		exo 	= { id = 48801 },		-- exorcism
		dp 		= { id = 54428 },		-- divine plea
		ss 		= { id = 53601 },		-- sacred shield
		hw		= { id = 2812  },		-- holy wrath
		sor 	= { id = 53600 },		-- shield of righteousness
}
-- expose for options
mod.spells = spells

-- used for the highlight lock on skill use
local lastgcd = 0
local startgcd = -1
local lastMS = ""
local gcdMS = 0

-- get the spell names from ids
local function InitSpells()
	for alias, data in pairs(spells) do
		data.name = GetSpellInfo(data.id)
	end
end

local function UpdateFCFS()
	local newpq = {}
	local check = {}
	numSpells = 0
	
	for i, alias in ipairs(db.fcfs) do
		if not check[alias] then -- take care of double entries
			check[alias] = true
			if alias ~= "none" then
				-- fix blank entries
				if not spells[alias] then
					db.fcfs[i] = "none"
				else
					numSpells = numSpells + 1
					newpq[numSpells] = { alias = alias, name = spells[alias].name }
				end
			end
		end
	end
	
	pq = newpq
	
	-- check if people added enough spells
	if numSpells < 2 then
		bprint("You need at least 2 skills in the queue.")
		-- toggle it off
		enabled = false
	end
end
-- expose it
mod.UpdateFCFS = UpdateFCFS

-- only needed exposed to check shit
function mod:DisplayFCFS()
	bprint("Active Retribution FCFS:")
	for i, data in ipairs(pq) do
		bprint(i .. " " .. data.name)
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
	for i = 1, numSpells do
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
	for i = 1, numSpells do
		v = pq[i]
		v.cd = max(0, v.cd - cd)
	end
	
	-- dq[2] = get the skill with shortest cooldown
	cd, index = GetMinCooldown()
	dq[2] = pq[index].name
end

-- ret queue function
local function RetRotation()
	local ctime, gcd, gcdStart, gcdDuration, v
	ctime = GetTime()
	
	-- get gcd
	gcdStart, gcdDuration = GetSpellCooldown(cleanseSpellName)
	if gcdStart > 0 then
		gcd = gcdStart + gcdDuration - ctime
	else
		gcd = 0
	end

	-- highlight when used
	--[[
	if db.highlight then
		gcdStart, gcdDuration = GetSpellCooldown(dq[1])
		if not gcdDuration then return end -- try to solve respec issues
		if gcdStart > 0 then
			gcdMS = gcdStart + gcdDuration - ctime
		else
			gcdMS = 0
		end
		
		if lastMS == dq[1] then
			if lastgcd < gcdMS and gcdMS <= 1.5 then
				-- pressed main skill
				startgcd = gcdMS
				if db.highlightChecked then
					clcretSB1:SetChecked(true)
				else
					clcretSB1:LockHighlight()
				end
			end
			lastgcd = gcdMS
			if (startgcd >= gcdMS) and (gcd > 1) then
				self:UpdateUI()
				return
			end
			clcretSB1:UnlockHighlight()
			clcretSB1:SetChecked(false)
		end
		lastMS = dq[1]
		lastgcd = gcdMS
	end
	--]]
	
	-- update cooldowns
	for i = 1, numSpells do
		v = pq[i]
		
		v.cdStart, v.cdDuration = GetSpellCooldown(v.name)
		if not v.cdDuration then return end -- try to solve respec issues
		
		if v.cdStart > 0 then
			v.cd = v.cdStart + v.cdDuration - ctime
		else
			v.cd = 0
		end
		
		-- ds gcd fix?
		-- todo: check
		if v.cd < gcd then v.cd = gcd end
		
		-- how check
		if v.alias == "how" then
			if not IsUsableSpell(v.name) then v.cd = 100 end
		-- art of war for exorcism check
		elseif v.alias == "exo" then
			if UnitBuff("player", taowSpellName) == nil then v.cd = 100 end
		end
		
		-- adjust to gcd
		v.cd = v.cd - gcd
	end
	
	GetSkills()
	return true
end

-- default values for this module
local function PrepareCDB()
	if not clcInfo.cdb.classModules.paladin then
		clcInfo.cdb.classModules.paladin = {}
	end
	
	if not clcInfo.cdb.classModules.paladin.retribution then
		clcInfo.cdb.classModules.paladin.retribution = {
			fcfs = {
				"jud",
				"ds",
				"cs",
				"ds",
				"how",
				"cons",
				"exo",
				"none",
				"none",
				"none",
			},
			
			highlight = true,
			highlightChecked = true,
			rangePerSkill = false,
		}
	end
	
	db = clcInfo.cdb.classModules.paladin.retribution
end


--[[
--------------------------------------------------------------------------------
this part does the pluging in
--------------------------------------------------------------------------------
--]]
local function OnInitialize()
	PrepareCDB()
	InitSpells()
	UpdateFCFS()
end
-- register the init function so that the main emod runs it on init
clcInfo.initList[#(clcInfo.initList) + 1] = OnInitialize


function emod:PaladinRetribution_RotationS1()
	local gotskill = false
	if enabled then
		gotskill = RetRotation()
	end
	
	if s2 then UpdateS2(s2, 100) end	-- update with a big "elapsed" so it's updated on call
	if gotskill then
		return emod.Spell(dq[1], db.rangePerSkill or spells.cs.name)
	end
end

-- this function should be executed when OnUpdate is called manually
--------------------------------------------------------------------------------
local function S2Exec()
	if not enabled then return end
	return emod.Spell(dq[2], db.rangePerSkill or spells.cs.name)
end
-- call this when we update exec so first function doesn't still call it
local function ExecUpdate()
	s2 = nil
end
function emod:PaladinRetribution_RotationS2()
	-- remove this button's OnUpdate
	s2 = emod.cIcon
	s2.externalUpdate = true
	UpdateS2 = s2:GetScript("OnUpdate")
	s2:SetScript("OnUpdate", nil)
	s2.exec = S2Exec
	s2.ExecCleanup = ExecCleanup
end