-- build check
local _, _, _, toc = GetBuildInfo()
if toc >= 40000 then return end

-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local emod = clcInfo.env

-- sacred shield shit
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
	function emod.BarSacredShield(timeRight)
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID
		local j
		for i = 1, #groupUnitList do
			if UnitExists(groupUnitList[i]) then
				j = 1
				name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitBuff(groupUnitList[i], j)
				while name do
					if spellID == 53601 and caster == "player" then
						local value = expires - GetTime()
						if timeRight then
							timeRight = tostring(math.floor(value + 0.5))
						end
						return true, icon, 0, duration, value, "normal", UnitName(groupUnitList[i]), "", timeRight
					end
					j = j + 1
					name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitBuff(groupUnitList[i], j)
				end
			end
		end
	end
end