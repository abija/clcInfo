local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\data\\global_bar> " .. table.concat(t, " "))
end

local mod = clcInfo.env


local function ElapsingDown(value, elapsed)
	return value - elapsed
end
-- local visible, texture, minValue, maxValue, value, valueFunc, leftText, rightText, alpha, svc, r, g, b, a, ... 
function mod.BarSpell(spell, timeRight)
	local name, _, texture = GetSpellInfo(spell)
	if not name then return end
	
	-- in case id was used
	spell = name
	
	local start, duration, enable = GetSpellCooldown(spell)
	
	if duration and duration > 1.5 then -- avoid GCD
		if timeRight then
			timeRight = tostring(math.floor(value + 0.5))
		end
		
		return true, texture, 0, duration, duration - (GetTime() - start), ElapsingDown, name, timeRight
	end
end

-- local visible, texture, minValue, maxValue, value, valueFunc, leftText, rightText, alpha, svc, r, g, b, a, ... 
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
					return true, icon, 0, duration, value, ElapsingDown, name, timeRight
				end
			end
		end
		
		i = i + 1
		name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID  = UnitAura(unitTarget, i, filter)
	end
	-- not found
end


-- local visible, texture, minValue, maxValue, value, valueFunc, leftText, rightText, alpha, svc, r, g, b, a, ... 
-- experiment
function mod.BarUnitHP(unit, hpRight)
	if not UnitExists(unit) then return end
	local hp = UnitHealth(unit)
	if hpRight then hpRight = tonumber(hp) end
	return true, TargetFrame.portrait:GetTexture(), 0, UnitHealthMax(unit), hp, nil, UnitName(unit), hp
	
end