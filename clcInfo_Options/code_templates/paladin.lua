-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local mod = clcInfo_Options.templates
local defs = mod.defs
local format = string.format

-- list of spells that are used to get localized versions
local spells = {
	["Avenging Wrath"] = 31884,
	["Censure"] = 31803,
	["Divine Plea"] = 54428,
	["Judgements of the Pure"] = 54151,
	
	["Zealotry"] = 85696,
	
	["Beacon of Light"] = 53563,
	["Divine Favor"] = 31842,
	["Holy Shock"] = 20473,
	["Word of Glory"] = 85673,
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
-- Avenging Wrath
name = spells["Avenging Wrath"].name
mod:Add("icons", defs.CLASS, name, format([[
local visible, texture, start, duration, enable, reversed = IconAura("HELPFUL|PLAYER", "player", "%s")
if not visible then return IconSpell("%s") end
return visible, texture, start, duration, enable, reversed
]], name, name))
-- Divine Plea
name = spells["Divine Plea"].name
mod:Add("icons", defs.CLASS, name, format([[
return IconSpell("%s", nil, "ready")
]], name))

-- Judgements of the Pure
mod:Add("bars", defs.CLASS, spells["Judgements of the Pure"].name, format('return BarAura("HELPFUL|PLAYER", "player", "%s", nil, false, true)', spells["Judgements of the Pure"].name))

-- Censure on multiple targets
mod:Add("mbars", defs.CLASS, spells["Censure"].name, 'MBarSoV(1, 0.5, "before", true)')


-- holy
--------------------------------------------------------------------------------
-- Divine Favor
name = spells["Divine Favor"].name
mod:Add("icons", defs.CLASS_1, name, format([[
return IconSpell("%s", nil, "ready")
]], name))
-- Holy Shock and World of Glory
mod:Add("icons", defs.CLASS_1, format("%s and %s", spells["Holy Shock"].name, spells["Word of Glory"].name), format([[
if UnitPower("player", SPELL_POWER_HOLY_POWER) == 3 then
  return IconSpell("%s")
else
  return IconSpell("%s")
end
]], spells["Word of Glory"].name, spells["Holy Shock"].name))
-- Beacon of Light Icon
name = spells["Beacon of Light"].name
mod:Add("icons", defs.CLASS_1, name, format([[
return IconSingleTargetRaidBuff("%s")
]], name))
-- Beacon of Light Bar
name = spells["Beacon of Light"].name
mod:Add("bars", defs.CLASS_1, name, format([[
return BarSingleTargetRaidBuff("%s", false, true)
]], name))

-- Beacon and JoL
mod:Add("mbars", defs.CLASS_1, format("%s and %s", spells["Beacon of Light"].name, spells["Judgements of the Pure"].name), format([[
AddMBar("bol", 1, 1, 0, 0, 1, BarSingleTargetRaidBuff("%s", false, true))
AddMBar("jol", 1, 1, 1, 0, 1, BarAura("HELPFUL|PLAYER", "player", "%s", nil, false, true))
]], spells["Beacon of Light"].name, spells["Judgements of the Pure"].name))


-- protection
--------------------------------------------------------------------------------
-- Protection Rotation Skill 1 & 2
mod:Add("icons", defs.CLASS_2, "Protection Rotation Skill 1", 'return IconProtection1()')
mod:Add("icons", defs.CLASS_2, "Protection Rotation Skill 2", 'IconProtection2()')


-- retribution
--------------------------------------------------------------------------------
-- Retribution Rotation Skill 1 & 2
mod:Add("icons", defs.CLASS_3, "Retribution Rotation Skill 1", 'return IconRet1()')
mod:Add("icons", defs.CLASS_3, "Retribution Rotation Skill 2", 'IconRet2()')
-- Zealotry
name = spells["Zealotry"].name
mod:Add("icons", defs.CLASS_3, name, format([[
local visible, texture, start, duration, enable, reversed = IconAura("HELPFUL|PLAYER", "player", "%s")
if not visible then return IconSpell("%s") end
return visible, texture, start, duration, enable, reversed
]], name, name))
