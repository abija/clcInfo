-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "DEATHKNIGHT" then return end

local mod = clcInfo_Options.templates
local defs = mod.defs
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

-- all
--------------------------------------------------------------------------------
-- Frost Fever
name = spells["Frost Fever"].name
mod:Add("icons", defs.CLASS, name, format([[
return IconAura("HARMFUL|PLAYER", "target", "%s")
]], name))
-- Blood Plague
name = spells["Blood Plague"].name
mod:Add("icons", defs.CLASS, name, format([[
return IconAura("HARMFUL|PLAYER", "target", "%s")
]], name))

-- blood
--------------------------------------------------------------------------------


-- frost
--------------------------------------------------------------------------------
-- Frost Rotation Skill 1
mod:Add("icons", defs.CLASS_2, "Frost Rotation Skill 1","return IconFrost1()")
mod:Add("texts", defs.CLASS_2, "Frost Mode","return FrostMode()")
-- Pillar of Frost
name = spells["Pillar of Frost"].name
mod:Add("icons", defs.CLASS_2, name, format([[
return IconSpell("%s", nil, "ready")
]], name))

-- unholy
--------------------------------------------------------------------------------
-- Unholy Rotation Skill 1
mod:Add("icons", defs.CLASS_3, "Unholy Rotation Skill 1", "return IconUnholy1()")
mod:Add("texts", defs.CLASS_3, "Unholy Mode", "return UnholyMode()")







