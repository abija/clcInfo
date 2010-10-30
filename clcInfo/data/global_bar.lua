local mod = clcInfo.env

local GetTime = GetTime

--[[
BarSpell
--------------------------------------------------------------------------------
args:
	spell
		name or id of the spell to track
	timeRight
		if true, display time left on right of the bar
--------------------------------------------------------------------------------
expected return: visible, texture, minValue, maxValue, value, mode, t1, t2, t3
--]]
--- Bar that shows cooldown for specified spell.
-- @param spell Name of the spell.
-- @param timeRight If true, remaining seconds are displayed on the right side.
do
	cache = {}
	function mod.BarSpell(spell, timeRight)
		local name, _, texture = GetSpellInfo(spell)
		if not name then return end
		
		-- in case id was used
		spell = name
		
		local start, duration, enable = GetSpellCooldown(spell)
		
		if not cache[spell] then cache[spell] = {} end
		local sc = cache[spell]
		if duration and duration > 1.5 then
			sc.duration, sc.start, sc.enable = duration, start, enable
			
			local v = duration + start - GetTime()
			if timeRight then
				timeRight = tostring(math.floor(v + 0.5))
			end
			
			return true, texture, 0, duration, v, "normal", name, nil, timeRight
		elseif sc.duration then
			local v = sc.duration + sc.start - GetTime()
			if v > 0 then
				if timeRight then
					timeRight = tostring(math.floor(v + 0.5))
				end
				return true, texture, 0, sc.duration, v, "normal", name, nil, timeRight
			else
				sc.duration = false
			end
		end
	end
end

--[[
BarAura
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
	showStack
		if and where the stack will be shown
			* false/nil 		- hidden
			* "before"			- before name
			* not false/nil - after name
	timeRight
		if true, display time left on right of the bar
--------------------------------------------------------------------------------
expected return: visible, texture, minValue, maxValue, value, mode, t1, t2, t3
--]]	
function mod.BarAura(filter, unitTarget, spell, unitCaster, showStack, timeRight)
		-- check the unit
	if not UnitExists(unitTarget) then return end
	
	-- look for the buff
	local i = 1
	local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID  = UnitAura(unitTarget, i, filter)
	while name do
		if name == spell or spellID == spell then
			if duration and duration > 0 then
				if (not unitCaster) or (caster == unitCaster) then												
					-- found -> return required info				
					if count > 1 and showStack then 
						if showStack == "before" then
							name = string.format("(%s) %s", count, name)
						else
							name = string.format("%s (%s)", name, count)
						end
					end
					local value = expires - GetTime()
					if timeRight then
						timeRight = tostring(math.floor(value + 0.5))
					end
					return true, icon, 0, duration, value, "normal", name, nil, timeRight
				end
			end
		end
		
		i = i + 1
		name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID  = UnitAura(unitTarget, i, filter)
	end
	-- not found
end


--[[
BarItem
--------------------------------------------------------------------------------
args:
	item
		name or id of the item
	equipped
		if true, the item must be equipped or it will be ignored
	timeRight
		if true, display time left on right of the bar
--------------------------------------------------------------------------------
expected return: visible, texture, minValue, maxValue, value, mode, t1, t2, t3
--------------------------------------------------------------------------------
TODO
	multiple items with same name ?
--]]
function mod.BarItem(item, equipped, timeRight)
	-- equipped check if requested
	if equipped and not IsEquippedItem(item) then return end
	
	local name = GetItemInfo(item)
	if not name then return end
	
	local texture = GetItemIcon(item)
	
	local start, duration, enable = GetItemCooldown(item)
	if not enable then return end
	if duration and duration > 0 then
		local value = (start + duration) - GetTime()
		if timeRight then
			timeRight = tostring(math.floor(value + 0.5))
		end
		return true, icon, 0, duration, value, "normal", name, nil, timeRight
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- EXPERIMENTAL
--------------------------------------------------------------------------------


--[[
BarSingleTargetRaidBuff(spell, showStack, timeRight)
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
	function mod.BarSingleTargetRaidBuff(spell, showStack, timeRight)
		local name, rank, icon, count, dispelType, duration, expires, caster
		for i = 1, #groupUnitList do
			if UnitExists(groupUnitList[i]) then
				name, rank, icon, count, _, duration, expires, caster = UnitBuff(groupUnitList[i], spell, nil, "player")
				if name and caster == "player" then
					-- found -> return required info				
					if count > 1 and showStack then 
						if showStack == "before" then
							name = string.format("(%s) %s", count, name)
						else
							name = string.format("%s (%s)", name, count)
						end
					end
					local value = expires - GetTime()
					if timeRight then
						timeRight = tostring(math.floor(value + 0.5))
					end
					return true, icon, 0, duration, value, "normal", UnitName(groupUnitList[i]), "", timeRight
				end
			end
		end
	end
end