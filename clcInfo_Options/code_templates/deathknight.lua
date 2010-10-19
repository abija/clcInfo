-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "DEATHKNIGHT" then return end

local mod = clcInfo_Options.templates
local format = string.format

local spells = {
	["Frost Fever"] = 59921,
	["Blood Plague"] = 59879,
	["Pillar of Frost"] = 51271,
}

-- get the real names
local name
for k, v in pairs(spells) do
	local name = GetSpellInfo(v)
	if not name then name = "Unknown Spell" end
	spells[k] = { id = v, name = name }
end

-- Frost Fever
name = spells["Frost Fever"].name
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
return IconAura("HARMFUL|PLAYER", "target", "%s")
]], name)
}
-- Blood Plague
name = spells["Blood Plague"].name
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
return IconAura("HARMFUL|PLAYER", "target", "%s")
]], name)
}

-- Pillar of Frost
name = spells["Pillar of Frost"].name
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
return IconSpell("%s", nil, "ready")
]], name)
}


-- Frost Rotation Skill 1
mod.icons[#mod.icons+1] = { name = "Frost Rotation Skill 1", exec = "return IconFrost1()" }
mod.texts[#mod.texts+1] = { name = "Frost Mode", exec = "return FrostMode()" }

-- Unholy Rotation Skill 1
mod.icons[#mod.icons+1] = { name = "Unholy Rotation Skill 1", exec = "return IconUnholy1()" }
mod.texts[#mod.texts+1] = { name = "Unholy Mode", exec = "return UnholyMode()" }