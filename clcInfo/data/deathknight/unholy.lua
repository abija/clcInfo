-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "DEATHKNIGHT" then return end

local GetTime = GetTime

-- mod name in lower case
local modName = "_unholy"
local version = 1

-- default settings for this module
local defaults = {
	version = version,
	
	rangePerSkill = false,
	useDT = false, -- suggest dark transformation
	usePest = false, -- suggest pestilence
}

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule(modName)
local db

-- functions visible to exec should be attached to this
local emod = clcInfo.env

-- any error sets this to false
local enabled = true

-- command line toggles
local mode = "single" -- single target/aoe toggle

-- spells used
local spellIT		= GetSpellInfo(45477)	-- icy touch
local spellPS 	= GetSpellInfo(45462)	-- plague strike
local spellSS 	= GetSpellInfo(55090)	-- scourge strike
local spellFS 	= GetSpellInfo(85948)	-- festering strike
local spellHoW 	= GetSpellInfo(57330)	-- horn of winter
local spellDC		= GetSpellInfo(47541) -- death coil
local spellDnD	= GetSpellInfo(43265) -- death and decay
local spellDT 	= GetSpellInfo(63560) -- Dark Transformation
local spellPT		= GetSpellInfo(50842)	-- Pestilence
local spellBB		= GetSpellInfo(48721)	-- Blood Boil

-- buffs
local buffSI		= GetSpellInfo(91342)	-- Shadow Infusion (this is on pet)
local buffRC		= GetSpellInfo(51460) -- Runic Corruption
local buffSD		= GetSpellInfo(81340)	-- Sudden Doom

-- debuffs
local debuffFF	= GetSpellInfo(59921)	-- frost fever
local debuffBP	= GetSpellInfo(59879)	-- blood plague

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleDB(modName, defaults)
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

local function CmdUnholyMode(args)
	if args[1] and args[1] == "aoe" then
		mode = "aoe"
	else
		mode = "single"
	end
end

local function CmdUnholyDT(args)
	if args[1] and args[1] == "disabled" then
		db.useDT = false
	else
		db.useDT = true
	end
end

local function CmdUnholyPest(args)
	if args[1] and args[1] == "disabled" then
		db.usePest = false
	else
		db.usePest = true
	end
end

-- register for slashcmd
clcInfo.cmdList["unholy_mode"] = CmdUnholyMode
clcInfo.cmdList["unholy_dt"] = CmdUnholyDT
clcInfo.cmdList["unholy_pest"] = CmdUnholyPest

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- priority based system
-- only suggesting first skill atm
--------------------------------------------------------------------------------
-- [1] Diseases
-- [2] Dark Transformation
-- [3] SS if both Unholy and/or all Death runes are up
-- [4] FeS if both pairs of Blood and Frost runes are up
-- [5] DC if SD, 100 RP, will overcap RP with anything else or if RC isn’t up
-- [6] SS
-- [7] FeS
-- [8] DC
-- [9] HoW
--------------------------------------------------------------------------------
local dq1
local rb1, rb2, rf1, rf2, ru1, ru2
local rb1d, rb2d, rf1d, rf2d, ru1d, ru2d
mod.UnholyRotation = {}

local function RuneCooldown(runeId, ctime, gcd)
	local cd = 0
	local cdStart, cdDuration, cdReady = GetRuneCooldown(runeId)
	if not cdReady then
		cd = cdStart + cdDuration - ctime - gcd
	end
	if cd < 0 then cd = 0 end
	return cd, GetRuneType(runeId) == 4
end

function mod.UnholyRotation.single(diseaseClip)
	diseaseClip = diseaseClip or 0

	-- needs target
	if not (UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")) then return end

	local ctime, gcd, cd, cdStart, cdDuration, cdReady, runeType
	ctime = GetTime()
	
	-- gcd (from death coil cooldown)
	cdStart, cdDuration = GetSpellCooldown(spellDC)
	if cdStart > 0 then
		gcd = cdStart + cdDuration - ctime
	else
		gcd = 0
	end

	-- get rune status
	------------------------------------------------------------------------------
	-- runeMapping: 1 - blood, 2 - unholy, 3 - frost, 4 - death
	rb1, rb1d = RuneCooldown(1, ctime, gcd)
	rb2, rb2d = RuneCooldown(2, ctime, gcd)
	ru1, ru1d = RuneCooldown(3, ctime, gcd)
	ru2, ru2d = RuneCooldown(4, ctime, gcd)
	rf1, rf1d = RuneCooldown(5, ctime, gcd)
	rf2, rf2d = RuneCooldown(6, ctime, gcd)
	
	-- get count of ready runes
	-- blood, frost, unholy, death, blood + death, frost + death, unholy + death
	local readyB, readyF, readyU, readyD, readyBD, readyFD, readyUD = 0, 0, 0, 0, 0, 0, 0
	if rb1 == 0 then
		if rb1d then
			readyD = readyD + 1 readyBD = readyBD + 1 readyFD = readyFD + 1 readyUD = readyUD + 1
		else
			readyB = readyB + 1 readyBD = readyBD + 1
		end	
	end
	if rb2 == 0 then
		if rb2d then
			readyD = readyD + 1 readyBD = readyBD + 1 readyFD = readyFD + 1 readyUD = readyUD + 1
		else
			readyB = readyB + 1 readyBD = readyBD + 1
		end	
	end
	if rf1 == 0 then
		if rf1d then
			readyD = readyD + 1 readyBD = readyBD + 1 readyFD = readyFD + 1 readyUD = readyUD + 1
		else
			readyF = readyF + 1 readyFD = readyFD + 1
		end
	end
	if rf2 == 0 then
		if rf2d then
			readyD = readyD + 1 readyBD = readyBD + 1 readyFD = readyFD + 1 readyUD = readyUD + 1
		else
			readyF = readyF + 1 readyFD = readyFD + 1
		end
	end
	if ru1 == 0 then readyU = readyU + 1 readyUD = readyUD + 1 end
	if ru2 == 0 then readyU = readyU + 1 readyUD = readyUD + 1 end
	------------------------------------------------------------------------------
			
	-- [1] Diseases
	------------------------------------------------------------------------------
	local _, _, _, _, _, duration, expires = UnitDebuff("target", debuffBP, nil, "PLAYER")
	local bpLeft = 0
	if duration and duration > 0 then
		bpLeft = expires - ctime
	end
	_, _, _, _, _, duration, expires = UnitDebuff("target", debuffFF, nil, "PLAYER")
	local ffLeft = 0
	if duration and duration > 0 then
		ffLeft = expires - ctime
	end
	
	if bpLeft <= diseaseClip then 
		if readyUD == 0 then
			-- no runes, check for ff
			if ffLeft <= diseaseClip and readyFD > 0 then
				dq1 = spellIT return true
			end
		end
		dq1 = spellPS return true
	end
	
	if ffLeft <= diseaseClip then
		dq1 = spellIT return true
	end
	
	-- [2] Dark Transformation
	-- can be disabled with command line for when pet can't do damage
	------------------------------------------------------------------------------
	if db.useDT and IsUsableSpell(spellDT) then
		dq1 = spellDT return true
	end
	
	-- [3] SS if both Unholy and/or all Death runes are up
	------------------------------------------------------------------------------
	if readyU == 2 or readyD == 4 then dq1 = spellSS return true end
	
	-- [4] FeS if both pairs of Blood and Frost runes are up
	------------------------------------------------------------------------------
	if readyB == 2 and readyF == 2 then dq1 = spellFS return true end
	
	-- [5] DC if SD, 100 RP, will overcap RP with anything else or if RC isn’t up
	------------------------------------------------------------------------------
	if UnitBuff("player", buffSD, nil, "PLAYER") then dq1 = spellDC return true end
	
	-- delay if RC is up
	if (not UnitBuff("player", buffRC, nil, "PLAYER")) and IsUsableSpell(spellDC) then
		dq1 = spellDC return true
	end
	
	local rp = UnitPowerMax("player") - UnitPower("player")
	-- max rp
	if rp == 0 then dq1 = spellDC return true end
	-- SS or HoW -> 100 rp
	if rp < 10 and (readyUD > 0 or IsUsableSpell(spellHoW)) then dq1 = spellDC return true
	end
	-- check if next ability will be FS (can't use SS and got b + f)
	if rp < 20 and readyUD == 0 and (readyB > 0 and readyF > 0) then dq1 = spellDC return true end
	
	-- [6] SS
	------------------------------------------------------------------------------
	if readyUD > 0 then dq1 = spellSS return true end
	
	-- [7] FeS
	------------------------------------------------------------------------------
	if readyB > 0 and readyF > 0 then dq1 = spellFS return true end
	
	-- [8] DC
	------------------------------------------------------------------------------
	if IsUsableSpell(spellDC) then dq1 = spellDC return true end
	
	-- [9] HoW
	------------------------------------------------------------------------------
	local cdStart, cdDuration = GetSpellCooldown(spellHoW)
	if cdDuration and gcd < 0.5 then
		if (cdStart + cdDuration - ctime - gcd) < 1.5 then 
			dq1 = spellHoW
			return true
		end
	end
	
	return false
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- priority based system
-- only suggesting first skill atm
--------------------------------------------------------------------------------
-- [1] Diseases
-- [2] Dark Transformation
-- [3] Death and Decay
-- [4] SS if both Unholy and/or all Death runes are up
-- [5] BB + IT if both pairs of Blood and Frost runes are up
-- [6] DC if SD, 100 RP, will overcap RP with anything else or if RC isn’t up
-- [7] SS
-- [8] BB + IT
-- [9] DC
-- [10] HoW
--------------------------------------------------------------------------------
local lastDisease = 0
function mod.UnholyRotation.aoe(diseaseClip)
	diseaseClip = diseaseClip or 0

	-- needs target
	if not (UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")) then return end

	local ctime, gcd, cd, cdStart, cdDuration, cdReady, runeType
	ctime = GetTime()
	
	-- gcd (from death coil cooldown)
	cdStart, cdDuration = GetSpellCooldown(spellDC)
	if cdStart > 0 then
		gcd = cdStart + cdDuration - ctime
	else
		gcd = 0
	end

	-- get rune status
	------------------------------------------------------------------------------
	-- runeMapping: 1 - blood, 2 - unholy, 3 - frost, 4 - death
	rb1, rb1d = RuneCooldown(1, ctime, gcd)
	rb2, rb2d = RuneCooldown(2, ctime, gcd)
	ru1, ru1d = RuneCooldown(3, ctime, gcd)
	ru2, ru2d = RuneCooldown(4, ctime, gcd)
	rf1, rf1d = RuneCooldown(5, ctime, gcd)
	rf2, rf2d = RuneCooldown(6, ctime, gcd)
	
	-- get count of ready runes
	-- blood, frost, unholy, death, blood + death, frost + death, unholy + death
	local readyB, readyF, readyU, readyD, readyBD, readyFD, readyUD = 0, 0, 0, 0, 0, 0, 0
	if rb1 == 0 then
		if rb1d then
			readyD = readyD + 1 readyBD = readyBD + 1 readyFD = readyFD + 1 readyUD = readyUD + 1
		else
			readyB = readyB + 1 readyBD = readyBD + 1
		end	
	end
	if rb2 == 0 then
		if rb2d then
			readyD = readyD + 1 readyBD = readyBD + 1 readyFD = readyFD + 1 readyUD = readyUD + 1
		else
			readyB = readyB + 1 readyBD = readyBD + 1
		end	
	end
	if rf1 == 0 then
		if rf1d then
			readyD = readyD + 1 readyBD = readyBD + 1 readyFD = readyFD + 1 readyUD = readyUD + 1
		else
			readyF = readyF + 1 readyFD = readyFD + 1
		end
	end
	if rf2 == 0 then
		if rf2d then
			readyD = readyD + 1 readyBD = readyBD + 1 readyFD = readyFD + 1 readyUD = readyUD + 1
		else
			readyF = readyF + 1 readyFD = readyFD + 1
		end
	end
	if ru1 == 0 then readyU = readyU + 1 readyUD = readyUD + 1 end
	if ru2 == 0 then readyU = readyU + 1 readyUD = readyUD + 1 end
	------------------------------------------------------------------------------
			
	-- [1] Diseases
	------------------------------------------------------------------------------
	local _, _, _, _, _, duration, expires = UnitDebuff("target", debuffBP, nil, "PLAYER")
	local bpLeft = 0
	if duration and duration > 0 then
		bpLeft = expires - ctime
	end
	_, _, _, _, _, duration, expires = UnitDebuff("target", debuffFF, nil, "PLAYER")
	local ffLeft = 0
	if duration and duration > 0 then
		ffLeft = expires - ctime
	end
	
	if bpLeft <= diseaseClip then 
		if readyUD == 0 then
			-- no runes, check for ff
			if ffLeft <= diseaseClip and readyFD > 0 then
				lastDisease = ctime
				dq1 = spellIT return true
			end
		end
		lastDisease = ctime
		dq1 = spellPS return true
	end
	
	if ffLeft <= diseaseClip then
		lastDisease = ctime
		dq1 = spellIT return true
	end
	
	-- try pestilence
	if db.usePest then
		if ctime - lastDisease < 1.3 then
			dq1 = spellPT return true
		end
	
		if ctime - lastDisease > 1.2 then
			lastDisease = 0
		end
	end
	
	-- [2] Dark Transformation
	-- can be disabled with command line for when pet can't do damage
	------------------------------------------------------------------------------
	if db.useDT and IsUsableSpell(spellDT) then
		dq1 = spellDT return true
	end
	
	-- [3] Death and Decay
	------------------------------------------------------------------------------
	cdStart, cdDuration = GetSpellCooldown(spellDnD)
	if cdDuration and gcd < 0.5 then
		if (cdStart + cdDuration - ctime - gcd) < 1.5 then 
			dq1 = spellDnD
			return true
		end
	end
	
	-- [4] SS if both Unholy and/or all Death runes are up
	------------------------------------------------------------------------------
	if readyU == 2 or readyD == 4 then dq1 = spellSS return true end
	
	-- [5] BB + IT if both pairs of Blood and Frost runes are up
	------------------------------------------------------------------------------
	if readyB == 2 and readyF == 2 then
		dq1 = spellBB return true
	end
	if readyB > 0 and readyF == 2 then
		dq1 = spellIT return true
	end
	
	-- [6] DC if SD, 100 RP, will overcap RP with anything else or if RC isn’t up
	------------------------------------------------------------------------------
	if UnitBuff("player", buffSD, nil, "PLAYER") then dq1 = spellDC return true end
	
	-- delay if RC is up
	if (not UnitBuff("player", buffRC, nil, "PLAYER")) and IsUsableSpell(spellDC) then
		dq1 = spellDC return true
	end
	
	local rp = UnitPowerMax("player") - UnitPower("player")
	-- max rp
	if rp == 0 then dq1 = spellDC return true end
	-- SS or HoW -> 100 rp
	if rp < 10 and (readyUD > 0 or IsUsableSpell(spellHoW)) then dq1 = spellDC return true
	end
	-- check if next ability will be FS (can't use SS and got b + f)
	if rp < 20 and readyUD == 0 and (readyB > 0 and readyF > 0) then dq1 = spellDC return true end
	
	-- [7] SS
	------------------------------------------------------------------------------
	if readyUD > 0 then dq1 = spellSS return true end
	
	-- [8] BB + IT
	------------------------------------------------------------------------------
	if readyB > 0 and readyF > 0 then
		dq1 = spellBB return true
	end
	if readyF > 0 then
		dq1 = spellIT return true
	end
	
	-- [9] DC
	------------------------------------------------------------------------------
	if IsUsableSpell(spellDC) then dq1 = spellDC return true end
	
	-- [10] HoW
	------------------------------------------------------------------------------
	cdStart, cdDuration = GetSpellCooldown(spellHoW)
	if cdDuration and gcd < 0.5 then
		if (cdStart + cdDuration - ctime - gcd) < 1.5 then 
			dq1 = spellHoW
			return true
		end
	end
	
	return false
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- emod. functions are usable by icon execs
--------------------------------------------------------------------------------
-- drop not wanted information
local function UtilIconSpell(spell, checkRange)
	local name, _, texture = GetSpellInfo(spell)
	
	-- cooldown and showWhen checks
	local start, duration, enable = GetSpellCooldown(spell)
	local timeLeft = start + duration - GetTime()
	
	if checkRange then
		local unit
		if UnitExists("target") then unit = "target" end
		if checkRange == true then checkRange = spell end
		if unit then
			oor = IsSpellInRange(checkRange, unit)
			oor = oor ~= nil and oor == 0
			if oor then
				return true, texture, start, duration, enable, nil, nil, nil, true, 0.8, 0.1, 0.1, 1
			end
		end
	end

	return true, texture, start, duration, enable, nil, nil, nil, true, 1, 1, 1, 1
end
function emod.IconUnholy1(...)
	local gotskill = false
	if enabled then
		gotskill = mod.UnholyRotation[mode](...)
	end
	if gotskill then
		return UtilIconSpell(dq1, db.rangePerSkill or spellPS)
	end
end
function emod.UnholyMode() return mode end
function emod.UnholyDT() return db.useDT end
function emod.UnholyPest() return db.usePest end
--------------------------------------------------------------------------------
