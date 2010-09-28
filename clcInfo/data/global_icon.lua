local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\data\\global_icon> " .. table.concat(t, " "))
end

local mod = clcInfo.env

function mod.DoNothing() return end

--[[
IconAura
--------------------------------------------------------------------------------
args:
	filter
		a list of filters to use separated by the pipe '|' character; e.g. "RAID|PLAYER" will query group buffs cast by the player (string) 
			* HARMFUL 				- show debuffs only
	    * HELPFUL 				- show buffs only
			* CANCELABLE 			- show auras that can be cancelled
	    * NOT_CANCELABLE 	- show auras that cannot be cancelled
	    * PLAYER 					- show auras the player has cast
	    * RAID 						- when used with a HELPFUL filter it will show auras the player can cast on party/raid members (as opposed to self buffs). If used with a HARMFUL filter it will return debuffs the player can cure
	unitTarget
		unit on witch to check the auras
	spell
		name or id of the aura
	unitCaster
		if specified, it will check caster of the buff against this argument
--------------------------------------------------------------------------------		
expected return: visible, texture, start, duration, enable, reversed, count, alpha, svc, r, g, b, a
--]]
function mod.IconAura(filter, unitTarget, spell, unitCaster)
	-- check the unit
	if not UnitExists(unitTarget) then return end
	
	-- look for the buff
	local i = 1
	local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID  = UnitAura(unitTarget, i, filter)
	while name do
		if name == spell or spellID == spell then
			if unitCaster then												-- additional check
				if caster == unitCaster then						-- found -> return required info
					-- return count only if > 1
					if count <= 1 then count = nil end
					return true, icon, expires - duration, duration, 1, true, count
				end
			else																			-- found -> return required info
				if count <= 1 then count = nil end
				return true, icon, expires - duration, duration, 1, true, count
			end
		end
		
		i = i + 1
		name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID  = UnitAura(unitTarget, i, filter)
	end
	-- not found
end



--[[
IconSpell
--------------------------------------------------------------------------------
args:
	spell
		name or id of the spell to track
	checkRange
		* nil or false 		- do nothing
		* true						- display range of spell specified in spellName
		* string					- display range of spell specified in string
	showWhen
		*	nil or false		- do nothing
		*	"ready"					- display spell only when ready
		* "not ready"			- display spell only when not ready
--------------------------------------------------------------------------------
expected return: visible, texture, start, duration, enable, reversed, count, alpha, svc, r, g, b, a
--]]	
function mod.IconSpell(spell, checkRange, showWhen, mouseover)
	-- check if spell exists and get texture
	local name, _, texture = GetSpellInfo(spell)
	if not name then return end
	
	-- in case id was used
	spell = name
	
	-- cooldown and showWhen checks
	local start, duration, enable = GetSpellCooldown(spell)
	if showWhen then
		if showWhen == "ready" then
			if duration and duration > 1.5 then return end
		elseif showWhen == "not ready" then
			if not (duration and duration > 1.5) then return end
		end
	end
	
	
	-- current vertex color priority: oor > usable > oom
	local oor = nil
	if checkRange then
		local unit
		if mouseover and UnitExists("mouseover") then unit = "mouseover" end
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
	
	local isUsable, notEnoughMana = IsUsableSpell(spell)
	if notEnoughMana then
		return true, texture, start, duration, enable, nil, nil, nil, true, 0.1, 0.1, 0.8, 1
	elseif not isUsable then
		return true, texture, start, duration, enable, nil, nil, nil, true, 0.3, 0.3, 0.3, 1
	end

	return true, texture, start, duration, enable, nil, nil, nil, true, 1, 1, 1, 1
end


--[[
IconItem
--------------------------------------------------------------------------------
args:
	item
		name or id of the item
	equipped
		if true, the item must be equipped or it will be ignored
	showWhen
		*	nil or false		- do nothing
		*	"ready"					- display spell only when ready
		* "not ready"			- display spell only when not ready
--------------------------------------------------------------------------------
expected return: visible, texture, start, duration, enable, reversed, count, alpha, svc, r, g, b, a
--------------------------------------------------------------------------------
TODO
	multiple items with same name ?
--]]
function mod.IconItem(item, equipped, showWhen, checkRange, mouseover)
	-- equipped check if requested
	if equipped and not IsEquippedItem(item) then return end
	
	local texture = GetItemIcon(item)
	-- if item has no texture it means the item doesn't exist?
	if not texture then return end
	
	-- cooldown and showWhen checks
	local start, duration, enable = GetItemCooldown(item)
	if showWhen then
		if showWhen == "ready" then
			if duration and duration > 1.5 then return end
		elseif showWhen == "not ready" then
			if not (duration and duration > 1.5) then return end
		end
	end
	
	-- current vertex color priority: oor > usable > oom
	local oor = nil
	if checkRange then
		local unit
		if mouseover and UnitExists("mouseover") then unit = "mouseover" end
		if UnitExists("target") then unit = "target" end
		if checkRange == true then
			if unit then
				oor = IsItemInRange(item, unit)
				oor = oor ~= nil and oor == 0
				if oor then
					return true, texture, start, duration, enable, nil, nil, nil, true, 0.8, 0.1, 0.1, 1
				end
			end
		else
			-- checks with a spell instead
			if unit then
				oor = IsSpellInRange(checkRange, unit)
				oor = oor ~= nil and oor == 0
				if oor then
					return true, texture, start, duration, enable, nil, nil, nil, true, 0.8, 0.1, 0.1, 1
				end
			end
		end
		
	end
	
	-- check if it's usable
	-- current vertex color priority: oor > oom > usable
	local isUsable, notEnoughMana = IsUsableItem(item)
	if notEnoughMana then
		return true, texture, start, duration, enable, nil, nil, nil, true, 0.1, 0.1, 0.8, 1
	elseif not isUsable then
		return true, texture, start, duration, enable, nil, nil, nil, true, 0.3, 0.3, 0.3, 1
	end

	return true, texture, start, duration, enable, nil, nil, nil, true, 1, 1, 1, 1
end


--[[
IconICD
	looks only for self buffs atm, if needed can be expanded
	states
		1 - ready to proc
		2 - proc active
		3 - proc on cooldown
--------------------------------------------------------------------------------
args:
	spell
		name or id of the spell to track
	icd
		duration of the internal cooldown
	alpha1, alpha2, alpha3,
		alpha values of the 3 states
	r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3
		maybe modify vertex color too?
--------------------------------------------------------------------------------
expected return: visible, texture, start, duration, enable, reversed, count, alpha, svc, r, g, b, a
--------------------------------------------------------------------------------
--]]
local icdList = {}
function mod.IconICD(spell, icd, alpha1, alpha2, alpha3)
	-- look for the buff
	local i = 1
	local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID  = UnitAura("player", i, "HELPFUL|PLAYER")
	while name do
		if spellID == spell then
			-- found it
			-- add expiration time to the list
			if not icdList[spellID] then icdList[spellID] = { expires = expires, duration = duration } end
			if icdList[spellID].expires ~= expires then
				icdList[spellID].expires = expires
				icdList[spellID].duration = duration
			end
			return true, icon, expires - duration, duration, 1, nil, nil, alpha2
		end
			
		i = i + 1
		name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID  = UnitAura("player", i, "HELPFUL|PLAYER")
	end
	
	-- not found
	-- need to check get spellinfo for icon
	name, rank, icon = GetSpellInfo(spell)
	-- check if it's a valid spell
	if not name then return end
	
	-- check if it's in the list
	if icdList[spell] then
		-- check if it's on cooldown
		expires = icdList[spell].expires
		duration = icdList[spell].duration
		if GetTime() < (expires + icd - duration) then
			-- on cooldown
			return true, icon, expires, icd - duration, 1, nil, nil, alpha3
		end
	end
	
	-- must be ready to proc
	return true, icon, 0, 0, 0, nil, nil, alpha1
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- EXPERIMENTAL
--------------------------------------------------------------------------------

--[[
--------------------------------------------------------------------------------
IconMAura
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--]]
do
	local function ExecCleanup()
		mod.___e.___mAuras = nil
	end
	function mod.IconMAura(filter, unitTarget, ...)
		-- check the unit
		if not UnitExists(unitTarget) then return end
		
		-- we'll keep the args in a table attached to the obect
		-- the table will be cleaned when exec is changed
		if not mod.___e.___mAuras then
			mod.___e.___mAuras = {}
			for i = 1, select("#", ...) do
				mod.___e.___mAuras[select(i, ...)] = 1
			end
			mod.___e.ExecCleanup = ExecCleanup
		end
		
		-- look for the buff
		local i = 1
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID  = UnitAura(unitTarget, i, filter)
		while name do
			if mod.___e.___mAuras[name] then
				if count <= 1 then count = nil end
				return true, icon, expires - duration, duration, 1, true, count
			end
			
			i = i + 1
			name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID  = UnitAura(unitTarget, i, filter)
		end
		-- not found
	end
end

--------------------------------------------------------------------------------



--[[
--------------------------------------------------------------------------------
IconAction
--------------------------------------------------------------------------------
--]]

function mod.IconAction(slot, checkRange, showWhen)
	local texture = GetActionTexture(slot)
	-- no texture = no action
	if not texture then return end
	
	-- cooldown and showWhen checks
	local start, duration, enable = GetActionCooldown(slot)

	if showWhen then
		if showWhen == "ready" then
			if duration and duration > 1.5 then return end
		elseif showWhen == "not ready" then
			if not (duration and duration > 1.5) then return end
		end
	end
	
	
	-- current vertex color priority: oor > usable > oom
	--[[
	local oor = nil
	if checkRange and UnitExists("target") then
		if checkRange == true then checkRange = spell end
		oor = IsSpellInRange(checkRange, "target")
		oor = oor ~= nil and oor == 0
		if oor then
			return true, texture, start, duration, enable, nil, nil, nil, true, 0.8, 0.1, 0.1, 1
		end
	end
	--]]
	if checkRange and ActionHasRange(slot) and (IsActionInRange(slot) == 0) then
		return true, texture, start, duration, enable, nil, nil, nil, true, 0.8, 0.1, 0.1, 1
	end
	
	local isUsable, notEnoughMana = IsUsableAction(slot)
	if notEnoughMana then
		return true, texture, start, duration, enable, nil, nil, nil, true, 0.1, 0.1, 0.8, 1
	elseif not isUsable then
		return true, texture, start, duration, enable, nil, nil, nil, true, 0.3, 0.3, 0.3, 1
	end

	return true, texture, start, duration, enable, nil, nil, nil, true, 1, 1, 1, 1
end

--[[
--------------------------------------------------------------------------------
intended to be used with beacon of light, earth shield, etc
buff, cast by you, that can be active on only one target at same time
intended for raid environment
scans for current party/raid/boss
known issues: can't see people in other zones (after portals and stuff)
it's also probably resource intensive so don't do it too much
--------------------------------------------------------------------------------
--]]

-- build the list of units to be checked first
do
	local groupUnitList = { "player", "playerpet" }
	-- add group
	for i = 1, 4 do
		groupUnitList[#groupUnitList + 1] = "party" .. i
		groupUnitList[#groupUnitList + 1] = "partypet" .. i
	end
	-- add raid
	for i = 1, 40 do
		groupUnitList[#groupUnitList + 1] = "raid" .. i
		groupUnitList[#groupUnitList + 1] = "raidpet" .. i
	end
	-- add bosses
	for i = 1, 5 do
		groupUnitList[#groupUnitList + 1] = "boss" .. i
	end
	function mod.IconSingleTargetRaidBuff(spell)
		local name, rank, icon, count, dispelType, duration, expires, caster
		for i = 1, #groupUnitList do
			if UnitExists(groupUnitList[i]) then
				name, rank, icon, count, _, duration, expires, caster = UnitBuff(groupUnitList[i], spell)
				if name and caster == "player" then
					-- found -> return required info				
					if count <= 1 then count = nil end
					return true, icon, expires - duration, duration, 1, true, count
				end
			end
		end
	end
end