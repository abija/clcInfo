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
function mod.BarSpell(spell, textRight)
	local name, _, texture = GetSpellInfo(spell)
	if not name then return end
	
	-- in case id was used
	spell = name
	
	local start, duration, enable = GetSpellCooldown(spell)
	
	if duration and duration > 1.5 then -- avoid GCD
		if textRight then
			textRight = tostring(math.floor(value + 0.5))
		end
		return true, texture, 0, duration, duration - (GetTime() - start), ElapsingDown, name, textRight
	end
end

function mod.BarAura(filter, unitTarget, spell, unitCaster, textRight)
		-- check the unit
	if not UnitExists(unitTarget) then return end
	
	-- look for the buff
	local i = 1
	local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID  = UnitAura(unitTarget, i, filter)
	while name do
		if name == spell or spellID == spell then
			if duration and duration > 0 then
				if unitCaster then												-- additional check
					if caster == unitCaster then						-- found -> return required info
						-- return count only if > 1
						if count <= 1 then count = nil end
						local value = expires - GetTime()
						if textRight then
							textRight = tostring(math.floor(value + 0.5))
						end
						return true, icon, 0, duration, value, ElapsingDown, name, textRight
					end
				else																			-- found -> return required info
					if count <= 1 then count = nil end
					local value = expires - GetTime()
					if textRight then
						textRight = tostring(math.floor(value + 0.5))
					end
					return true, icon, 0, duration, value, ElapsingDown, name, textRight
				end
			end
		end
		
		i = i + 1
		name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID  = UnitAura(unitTarget, i, filter)
	end
	-- not found
end