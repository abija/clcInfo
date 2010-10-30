-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PRIEST" then return end

local mod = clcInfo_Options.templates
local defs = mod.defs
local format = string.format

local spells = {
	-- disc
	["Power Infusion"] = 37274,
	["Archangel"] = 87151,
	["Pain Suppression"] = 33206,
	["Prayer of Mending"] = 33076,
	["Evangelism"] = 81662,
	["Power Word: Barrier"] = 62618,
	["Penance"] = 47540,
	-- holy
	["Chakra"] = 14751,
	["Prayer of Healing"] = 596,
	["Heal"] = 2050,
	["Renew"] = 139,
	["Smite"] = 585,
	["Circle of Healing"] = 34861, 
	["Holy Word: Chastise"] = 88625,
	["Guardian Spirit"] = 47788,
	-- shadow
	["Shadow Word: Death"] = 32379,
}

-- get the real names
local name
for k, v in pairs(spells) do
	local name = GetSpellInfo(v)
	if not name then name = "Unknown Spell" end
	spells[k] = { id = v, name = name }
end


-- all
--------------------------------------------------------------------------------
-- Evangelism
name = spells["Evangelism"].name
mod:Add("icons", defs.CLASS, name, format([[
return IconAura("HELPFUL|PLAYER", "player", "%s")
]], name))
-- Archangel
name = spells["Archangel"].name
mod:Add("icons", defs.CLASS, name, format([[
local visible, texture, start, duration, enable, reversed = IconAura("HELPFUL|PLAYER", "player", "%s")
if not visible then return IconSpell("%s") end
return visible, texture, start, duration, enable, reversed
]], name, name))
-- Prayer of Mending
name = spells["Prayer of Mending"].name
mod:Add("icons", defs.CLASS, name, format([[
return IconSingleTargetRaidBuff("%s")
]], name))


-- disc
--------------------------------------------------------------------------------
-- Power Infusion
name = spells["Power Infusion"].name
mod:Add("icons", defs.CLASS_1, name, format([[
return IconSpell("%s")
]], name))
-- Pain Suppression
name = spells["Pain Suppression"].name
mod:Add("icons", defs.CLASS_1, name, format([[
local visible, texture, start, duration, enable, reversed, count = IconSingleTargetRaidBuff("%s")
if not visible then return IconSpell("%s") end
return visible, texture, start, duration, enable, reversed, count 
]], name, name))
-- Penance
name = spells["Penance"].name
mod:Add("icons", defs.CLASS_1, name, format([[
return IconSpell("%s")
]], name))


-- holy
--------------------------------------------------------------------------------
-- Circle of Healing
name = spells["Circle of Healing"].name
mod:Add("icons", defs.CLASS_2, name, format([[
return IconSpell("%s")
]], name))

-- Guardian Spirit
name = spells["Guardian Spirit"].name
mod:Add("icons", defs.CLASS_2, name, format([[
return IconSpell("%s")
]], name))

-- Holy Word: Chastise
name = spells["Holy Word: Chastise"].name
mod:Add("icons", defs.CLASS_2, name, format([[
return IconSpell("%s")
]], name))

-- Chakra
name = spells["Chakra"].name
mod:Add("icons", defs.CLASS_2, name, format([[
local visible, texture, start, duration, enable, reversed = IconMAura("HELPFUL|PLAYER", "player", "%s: %s", "%s: %s", "%s: %s", "%s: %s")
if not visible then return IconSpell("%s") end
return visible, texture, start, duration, enable, reversed, nil, nil, true, 1, 1, 1, 1
]], name, spells["Heal"].name, name, spells["Renew"].name, name, spells["Prayer of Healing"].name, name, spells["Smite"].name, name))


-- shadow
--------------------------------------------------------------------------------
-- Shadow Word: Death
name = spells["Shadow Word: Death"].name
mod:Add("icons", defs.CLASS_3, name, format([[
if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
  local c = floor(UnitHealth("target") / UnitHealthMax("target") * 100)
  if c <= 25 then
    return IconSpell("%s", true)
  end
end
]], name))