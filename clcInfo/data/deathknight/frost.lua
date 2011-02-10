-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "DEATHKNIGHT" then return end

local GetTime = GetTime

-- mod name in lower case
local modName = "_frost"
local version = 1

-- default settings for this module
local defaults = {
	version = version,
	
	rangePerSkill = false,
}

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule(modName)
local db

-- functions visible to exec should be attached to this
local emod = clcInfo.env

-- any error sets this to false
local enabled = true

local mode = "single" -- single target/aoe toggle

-- spells used
local spellHB 	= GetSpellInfo(49184)	-- howling blast
local spellPS 	= GetSpellInfo(45462)	-- plague strike
local spellOB 	= GetSpellInfo(67725)	-- obliterate
local spellBS 	= GetSpellInfo(61696)	-- blood strike
local spellFS 	= GetSpellInfo(49143)	-- frost strike
local spellHoW 	= GetSpellInfo(57330)	-- horn of winter
local spellDC		= GetSpellInfo(47541) -- death coil
local spellDnD	= GetSpellInfo(43265) -- death and decay
local spellFP 	= GetSpellInfo(48266) -- frost presence

-- buffs
local buffKM		= GetSpellInfo(51124)	-- killing machine
local buffRM		= GetSpellInfo(59052) -- freezing fog (rime proc)

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

local function CmdFrostMode(args)
	if args[1] and args[1] == "aoe" then
		mode = "aoe"
	else
		mode = "single"
	end
end

local function CmdFrostModeSwitch()
	if mode == "single" then
		mode = "aoe"
	else
		mode = "single"
	end
end

-- register for slashcmd
clcInfo.cmdList["frost_mode"] = CmdFrostMode
clcInfo.cmdList["frost_mode_switch"] = CmdFrostModeSwitch

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- priority based system
-- only suggesting first skill atm
--------------------------------------------------------------------------------
-- Diseases
-- Ob if both Frost/Unholy pairs and/or both Death runes are up, or if KM is procced
-- BS if both Blood Runes are up
-- FS if RP capped
-- Rime
-- Ob
-- BS
-- HoW
--------------------------------------------------------------------------------
local dq1
local readyRunes = { 0, 0, 0, 0 }
mod.FrostRotation = {}

function mod.FrostRotation.single()
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
	-- runeMapping: 1 - blood, 2 - unholy, 3 - frost, 4 - death
	for i = 1, 4 do readyRunes[i] = 0 end
	
	for i = 1, 6 do
		cdStart, cdDuration, cdReady = GetRuneCooldown(i)
		cd = 0
		if not cdReady then
			cd = cdStart + cdDuration - ctime - gcd
		end
		if cd < 0 then cd = 0 end
		runeType = GetRuneType(i)
		if cd == 0 then readyRunes[runeType] = readyRunes[runeType] + 1 end
	end
	-- unholy frost pairs
	local readyUF = min(readyRunes[2], readyRunes[3])
	
	-- [1] Diseases
	------------------------------------------------------------------------------
	
	-- ff
	if not UnitDebuff("target", debuffFF, nil, "PLAYER") then
		dq1 = spellHB
		return true
	end
	
	-- bp
	local _, _, _, _, _, duration, expires = UnitDebuff("target", debuffBP, nil, "PLAYER")
	local bpLeft = 0
	if duration and duration > 0 then
		bpLeft = expires - ctime
	end
	
	if bpLeft <= 0 then
		dq1 = spellPS
		return true
	elseif (bpLeft < 6) and (readyRunes[3] > 0 or readyRunes[4] > 0) then 
		dq1 = spellPS
		return true
	end
	
	-- check if we can obliterate
	local ob = (readyUF > 0) or (readyRunes[4] >= 2) or (readyRunes[2] > 0 and readyRunes[4] > 0) or (readyRunes[3] > 0 and readyRunes[4] > 0)
	
	-- [2] Ob if both Frost/Unholy pairs and/or both Death runes are up, or if KM is procced
	------------------------------------------------------------------------------
	local KM = UnitBuff("player", buffKM, nil, "PLAYER")
	if (KM and ob) or (readyUF >= 2) or (readyRunes[4] >= 2) then
		dq1 = spellOB
		return true
	end
	
	-- [3] BS if both Blood Runes are up
	------------------------------------------------------------------------------
	if readyRunes[1] >= 2 then
		dq1 = spellBS
		return true
	end
	
	-- [4] FS
	------------------------------------------------------------------------------
	if UnitPower("player") == UnitPowerMax("player") then
		dq1 = spellFS
		return true
	end
	
	-- [5] Rime
	------------------------------------------------------------------------------
	if UnitBuff("player", buffRM, nil, "PLAYER") then
		dq1 = spellHB
		return true
	end
	
	-- [6] Ob
	------------------------------------------------------------------------------
	if ob then
		dq1 = spellOB
		return true
	end
	
	-- [7] BS
	------------------------------------------------------------------------------
	if readyRunes[1] > 0 then
		dq1 = spellBS
		return true
	end
		
	-- [8] HoW
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
-- priority based system
-- only suggesting first skill atm
--------------------------------------------------------------------------------
-- HB if both Frost runes and/or both Death runes are up
-- DnD/PS if both Unholy Runes are up
-- FS
-- HB
-- BS
-- DnD/PS
-- HoW
--------------------------------------------------------------------------------
function mod.FrostRotation.aoe()
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
	-- runeMapping: 1 - blood, 2 - unholy, 3 - frost, 4 - death
	for i = 1, 4 do readyRunes[i] = 0 end
	
	for i = 1, 6 do
		cdStart, cdDuration, cdReady = GetRuneCooldown(i)
		cd = 0
		if not cdReady then
			cd = cdStart + cdDuration - ctime - gcd
		end
		if cd < 0 then cd = 0 end
		runeType = GetRuneType(i)
		if cd == 0 then readyRunes[runeType] = readyRunes[runeType] + 1 end
	end
	
	-- [1] HB if both Frost runes and/or both Death runes are up
	if (readyRunes[3] >= 2) or (readyRunes[4] >= 2) then
		dq1 = spellHB
		return true
	end
	
	-- [2] DnD/PS if both Unholy Runes are up
	if readyRunes[2] >= 2 then
		cdStart, cdDuration = GetSpellCooldown(spellDnD)
		if cdStart > 0 then
			cd = cdStart + cdDuration - ctime - gcd
		else
			cd = 0
		end
		
		if cd <= 0 then
			dq1 = spellDnD
			return true
		else
			dq1 = spellPS
			return true
		end
	end
	
	-- [3] FS
	if UnitPower("player") == UnitPowerMax("player") then
		dq1 = spellFS
		return true
	end
	
	-- [4] HB
	if readyRunes[3] > 0 or readyRunes[4] > 0 then
		dq1 = spellHB
		return true
	end

	-- [5] BS	
	if readyRunes[1] > 0 then
		dq1 = spellBS
		return true
	end

	-- [6] DnD/PS	
	if readyRunes[2] > 0 then
		cdStart, cdDuration = GetSpellCooldown(spellDnD)
		if cdStart > 0 then
			cd = cdStart + cdDuration - ctime - gcd
		else
			cd = 0
		end
		if cd <= 0 then
			dq1 = spellDnD
			return true
		else
			dq1 = spellPS
			return true
		end
	end

	-- [7] HoW
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
function emod.IconFrost1()
	local gotskill = false
	if enabled then
		gotskill = mod.FrostRotation[mode]()
	end
	if gotskill then
		return UtilIconSpell(dq1, db.rangePerSkill or spellPS)
	end
end
function emod.FrostMode() return mode end
--------------------------------------------------------------------------------
