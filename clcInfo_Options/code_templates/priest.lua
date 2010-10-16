-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PRIEST" then return end

local mod = clcInfo_Options.templates
local format = string.format

local spells = {
	["Power Infusion"] = 37274,
	["Archangel"] = 87151,
	["Pain Suppression"] = 33206,
	["Prayer of Mending"] = 33076,
	["Evangelism"] = 81662,
	["Power Word: Barrier"] = 62618,
}

-- get the real names
local name
for k, v in pairs(spells) do
	local name = GetSpellInfo(v)
	if not name then name = "Unknown Spell" end
	spells[k] = { id = v, name = name }
end

-- Prayer of Mending
name = spells["Prayer of Mending"].name
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
return IconSingleTargetRaidBuff("%s")
]], name)
}
-- Evangelism
name = spells["Evangelism"].name
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
return IconAura("HELPFUL|PLAYER", "player", "%s")
]], name)
}
-- Archangel
name = spells["Archangel"].name
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
local visible, texture, start, duration, enable, reversed = IconAura("HELPFUL|PLAYER", "player", "%s")
if not visible then return IconSpell("%s") end
return visible, texture, start, duration, enable, reversed
]], name, name)
}
-- Power Infusion
name = spells["Power Infusion"].name
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
return IconSpell("%s")
]], name)
}
-- Pain Suppression
name = spells["Pain Suppression"].name
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
local visible, texture, start, duration, enable, reversed, count = IconSingleTargetRaidBuff("%s")
if not visible then return IconSpell("%s") end
return visible, texture, start, duration, enable, reversed, count 
]], name, name)
}
