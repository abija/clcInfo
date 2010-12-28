-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "WARLOCK" then return end

local GetTime = GetTime
local version = 2

local MAX_PRIORITY = 12

local defaults = {
	-- temp db stuff
	priority = { "isf", "imm", "con", "bd", "sf", "cor", "cb", "sbsf", "eisf", "inc" },
	clipImmolate = 0,
	clipCorruption = 0,
	clipBaneOfDoom = 0,
	debuffDelay = 0.5,

	version = version,
}

local modName = "_destruction"
local mod = clcInfo:RegisterClassModule(modName)
local emod = clcInfo.env
local db

-- static spell data
-- i_: spellId, n_: spellName, d_: debuffName, b_: buffName
--------------------------------------------------------------------------------
local i_gcd 						= 348 		-- immolate for gcd

local i_immolate				= 348			-- immolate
local i_conflagrate			= 17962		-- Conflagrate
local i_baneofdoom			= 603			-- Bane of Doom
local i_shadowflame			= 47897		-- Shadowflame
local i_corruption			= 172			-- Corruption
local i_chaosbolt				= 50796		-- Chaos Bolt
local i_soulburn				= 74434		-- Soulburn
local i_soulfire				= 6353		-- Soul Fire
local i_incinerate			= 29722		-- Incinerate
local i_empoweredimp		= 47220		-- Empowered Imp Talent

local n_immolate				= GetSpellInfo(i_immolate)
local n_conflagrate			= GetSpellInfo(i_conflagrate)
local n_baneofdoom			= GetSpellInfo(i_baneofdoom)
local n_shadowflame			= GetSpellInfo(i_shadowflame)
local n_corruption			= GetSpellInfo(i_corruption)
local n_chaosbolt				= GetSpellInfo(i_chaosbolt)
local n_soulburn				= GetSpellInfo(i_soulburn)
local n_soulfire				= GetSpellInfo(i_soulfire)
local n_incinerate			= GetSpellInfo(i_incinerate)

local b_isf 						= GetSpellInfo(85113) 	-- improved soul fire
local b_empoweredimp 		= GetSpellInfo(i_empoweredimp) 	-- empowered imp

local actionsId = {
	isf						= i_soulfire,
	imm				 		= i_immolate,
	con						= i_conflagrate,
	bd				 		= i_baneofdoom,
	sf						= i_shadowflame,
	cor						= i_corruption,
	cb						= i_chaosbolt,
	sbsf					= i_soulburn,
	eisf					= i_soulfire,
	inc						= i_incinerate,
}

local actionsName = {
	isf						= b_isf, 					-- improved soul fire // if target is above 80%, make sure this buff is up
	imm				 		= n_immolate,
	con						= n_conflagrate,
	bd				 		= n_baneofdoom,
	sf						= n_shadowflame,
	cor						= n_corruption,
	cb						= n_chaosbolt,
	sbsf					= n_soulburn .. " > " .. n_soulfire,
	eisf					= b_empoweredimp .. " > " .. n_soulfire,
	inc						= n_incinerate,
}
mod.actionsName = actionsName -- expose for options

-- temp db stuff
local db_c_soulfire = 3
local db_isfDelay = 2

-- working priority queue, skill 1
local pq, s1

local ef

-- status vars
local _gcd, _ctime, _casting, _haste
local _cd_soulburn, _b_soulburn
local _prevUse = {}
local _lastISF = 0			-- @hack: last time we got ISF buff, it has a 15s icd
-- work vars
local start, duration, cd

local actions = {
	isf = function()
		-- test if we're casting it
		if _casting == n_soulfire then return 100 end
		
		-- @hack wait for some time after casting it before deciding buff is not up
		if _prevUse[n_soulfire] then
			if _ctime < _prevUse[n_soulfire] + db_isfDelay then
				return 100
			else
				_prevUse[n_soulfire] = nil
			end
		end
		
		-- check target hp
		local hperc = UnitHealth("target") / UnitHealthMax("target")
		if hperc < 0.8 then return 100 end
		
		-- test if we can get buff
		if (_ctime + _gcd) >= _lastISF then
			-- check for buff now
			local _, _, _, _, _, _, expiration = UnitBuff("player", b_isf, nil, "PLAYER")
			if expiration then
				_lastISF = expiration	-- @hack icd
				return 100
			end
			return 0
		end
		
		return 100
	end,
	
	imm = function()
		-- test if we're casting it
		if _casting == n_immolate then return 100 end
	
		-- @hack wait for some time after casting it before deciding buff is not up
		if _prevUse[n_immolate] then
			if _ctime < _prevUse[n_immolate] + db.debuffDelay then
				return 100
			else
				_prevUse[n_immolate] = nil
			end
		end
	
		local _, _, _, _, _, _, expiration = UnitDebuff("target", n_immolate, nil, "PLAYER")
		if expiration then
			expiration = expiration - _ctime - _gcd
			if expiration <= db.clipImmolate then
				return 0
			else
				return 100
			end
		end
		return 0
	end,
	
	con = function()
		local _, _, _, _, _, _, expiration = UnitDebuff("target", n_immolate, nil, "PLAYER")
		-- @hack assume it's up for a bit if immolate just cast
		if _prevUse[n_immolate] then
			if _ctime < _prevUse[n_immolate] + db.debuffDelay then
				expiration = 1
			end
		end
		-- @hack assume it's up for a bit if immolate is casting
		if _casting == n_immolate then
			expiration = 1
		end
		if expiration then
			start, duration = GetSpellCooldown(i_conflagrate)
			if (start + duration - _ctime - _gcd) > 0 then
				return 100
			end
			return 0
		end
		return 100
	end,
	
	bd = function()
		if _prevUse[n_baneofdoom] then
			if _ctime < _prevUse[n_baneofdoom] + db.debuffDelay then
				return 100
			else
				_prevUse[n_baneofdoom] = nil
			end
		end
	
		local _, _, _, _, _, _, expiration = UnitDebuff("target", n_baneofdoom, nil, "PLAYER")
		if expiration then
			expiration = expiration - _ctime - _gcd
			if expiration <= db.clipBaneOfDoom then
				return 0
			end
			return 100
		end
		return 0
	end,
	
	sf = function()
		start, duration = GetSpellCooldown(i_shadowflame)
		if (start + duration - _ctime - _gcd) > 0 then
			return 100
		end
		return 0
	end,
	
	cor = function()
		if _prevUse[n_corruption] then
			if _ctime < _prevUse[n_corruption] + db.debuffDelay then
				return 100
			else
				_prevUse[n_corruption] = nil
			end
		end
	
		local _, _, _, _, _, _, expiration = UnitDebuff("target", n_corruption, nil, "PLAYER")
		if expiration then
			expiration = expiration - _ctime - _gcd
			if expiration <= db.clipCorruption then
				return 0
			end
			return 100
		end
		return 0
	end,
	
	cb = function()
		start, duration = GetSpellCooldown(i_chaosbolt)
		if (start + duration - _ctime - _gcd) > 0 then
			return 100
		end
		return 0
	end,
	
	sbsf = function()
		-- special cooldown for soulburn
		local _, _, _, _, _, _, expiration = UnitBuff("player", n_soulburn, nil, "PLAYER")
		if (expiration or 0) > _gcd then
			return 0
		end
		
		if UnitPower("player", SPELL_POWER_SOUL_SHARDS) > 0 then
			-- buff not up, look for spell cd
			start, duration = GetSpellCooldown(i_soulburn)
			if (start + duration - _ctime - _gcd) <= 0 then
				return 0
			end
		end
		
		return 100
	end,
	
	eisf = function()
		local _, _, _, _, _, _, expiration = UnitBuff("player", b_empoweredimp, nil, "PLAYER")
		if expiration then
			expiration = expiration - _ctime - _gcd
			if expiration > 0 then
				return 0
			end
		end
		return 100
	end,
	
	inc = function()
		return 0
	end,
}

local function DestructionRotation()
	-- needs target
	if not (UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")) then return end
	
	_ctime = GetTime()
	
	local endTime
	_casting, _, _, _, _, endTime = UnitCastingInfo("player")
	if _casting then
		-- casting a non instant spell	
		_gcd = endTime / 1000 - _ctime
	else
		-- instant or no cast
		start, duration = GetSpellCooldown(i_gcd)
		if duration > 0 then
			_gcd = start + duration - _ctime
		else
			_gcd = 0
		end
	end
	
	-- get cooldowns
	------------------------------------------------------------------------------
	for i, v in ipairs(pq) do
		v.cd = actions[v.alias](i)
	end
	
	-- get first 0
	------------------------------------------------------------------------------
	local sel = 1
	for i = 1, #pq do
		if pq[i].cd == 0 then
			sel = i
			break
		end
	end
	
	s1 = pq[sel].id
	return true
end

local notinit = true
local function ExecCleanup()
	ef:UnregisterAllEvents()
	notinit = true
end
local function DoInit()
	emod.___e.ExecCleanup = ExecCleanup
	ef:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	notinit = false
end
function emod.IconDestruction1()
	if notinit then DoInit() end
	if DestructionRotation() then
		return emod.IconSpell(s1, true)
	end
end

--------------------------------------------------------------------------------
function mod.UpdatePriorityQueue()
	pq = {}
	local check = {} -- used to check for duplicates
	for k, v in ipairs(db.priority) do
		if not check[v] then
			if v ~= "none" and actionsId[v] then
				pq[#pq + 1] = { alias = v, id = actionsId[v] }
				check[v] = true
			end
		end
	end
end

function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleDB(modName, defaults)
	
	if db.version < version then
		clcInfo.AdaptConfigAndClean(modName .. "DB", db, defaults)
		db.version = version
	end
	
	mod.UpdatePriorityQueue()
end

ef = CreateFrame("Frame")
ef:Hide()
ef:SetScript("OnEvent", function(self, event, unit, spell)
	if unit == "player" then
		_prevUse[spell] = GetTime()
	end
end)

-- pass filler order from command line
-- intended to be used in macros
local function CmdDestructionPriority(args)
	-- add args to options
	local num = 0
	for i, arg in ipairs(args) do
		if actionsName[arg] then
			if num < MAX_PRIORITY then
				num = num + 1
				db.priority[num] = arg
			else
				print("too many priority specified, max is " .. MAX_PRIORITY)
			end
		else
			-- inform on wrong arguments
			print(arg .. " not found")
		end
	end
	
	-- none on the rest
	if num < MAX_PRIORITY then
		for i = num + 1, MAX_PRIORITY do
			db.priority[i] = "none"
		end
	end
	
	-- redo queue
	mod.UpdatePriorityQueue()
	
	-- update the options window
	clcInfo:UpdateOptions()
end
-- register for slashcmd
clcInfo.cmdList["destro_prio"] = CmdDestructionPriority

-- edit options from command line
local function CmdDestructionOptions(args)
	if not args[1] or not args[2] then
		print("format: /clcInfo destro_opt option value")
		return
	end
	
	if args[1] == "clipimmolate" then
		db.clipImmolate = tonumber(args[2]) or defaults.clipImmolate
	elseif args[1] == "clipcorruption" then
		db.clipCorruption = tonumber(args[2]) or defaults.clipCorruption
	elseif args[1] == "clipbaneofdoom" then
		db.clipBaneOfDoom = tonumber(args[2]) or defaults.clipBaneOfDoom
	elseif args[1] == "debuffdelay" then
		db.debuffDelay = tonumber(args[2]) or defaults.debuffDelay
	else
		print("valid options: debuffdelay, clipimmolate, clipcorruption, clipbaneofdoom")
	end
	
	clcInfo:UpdateOptions()
end
clcInfo.cmdList["destro_opt"] = CmdDestructionOptions

