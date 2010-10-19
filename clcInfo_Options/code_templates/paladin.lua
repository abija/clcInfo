-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local mod = clcInfo_Options.templates
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

-- list of items used to get localized versions
local items = {
	["Whispering Fanged Skull"] = 50342,
	["[H] Whispering Fanged Skull"] = 50343,
	["Death's Verdict"] = 47115,
}
-- get the real names
for k, v in pairs(items) do
	local name = GetItemInfo(v)
	if not name then name = "Unknown Item" end
	items[k] = { id = v, name = name }
end

--------------------------------------------------------------------------------
-- icons
--------------------------------------------------------------------------------

-- Avenging Wrath
name = spells["Avenging Wrath"].name
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
local visible, texture, start, duration, enable, reversed = IconAura("HELPFUL|PLAYER", "player", "%s")
if not visible then return IconSpell("%s") end
return visible, texture, start, duration, enable, reversed
]], name, name)
}
-- Divine Plea
name = spells["Divine Plea"].name
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
return IconSpell("%s", nil, "ready")
]], name)
}

-- Retribution Rotation Skill 1
name = "Retribution Rotation Skill 1"
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
return IconRet1(0.5)
]])
}
-- Retribution Rotation Skill 2
name = "Retribution Rotation Skill 2"
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
return IconRet2()
]])
}
-- Zealotry
name = spells["Zealotry"].name
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
local visible, texture, start, duration, enable, reversed = IconAura("HELPFUL|PLAYER", "player", "%s")
if not visible then return IconSpell("%s") end
return visible, texture, start, duration, enable, reversed
]], name, name)
}

-- Divine Favor
name = spells["Divine Favor"].name
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
return IconSpell("%s", nil, "ready")
]], name)
}
-- Holy Shock and World of Glory
mod.icons[#mod.icons+1] = {
name = spells["Holy Shock"].name .. " and " .. spells["Word of Glory"].name, exec = format([[
if UnitPower("player", SPELL_POWER_HOLY_POWER) == 3 then
  return IconSpell("%s")
else
  return IconSpell("%s")
end
]], spells["Word of Glory"].name, spells["Holy Shock"].name)
}

-- Protection Rotation Skill 1
name = "Protection Rotation Skill 1"
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
return IconProtection1()
]])
}
-- Protection Rotation Skill 2
name = "Protection Rotation Skill 2"
mod.icons[#mod.icons+1] = {
name = name, exec = format([[
return IconProtection2()
]])
}

-- [H] Whispering Fanged Skull
mod.icons[#mod.icons+1] = {
name = "Item: [H] " .. items["[H] Whispering Fanged Skull"].name, exec = format([[
return IconICD(71541, 45, 0, 1, 0.3)
]])
}
-- Death's Verdict
mod.icons[#mod.icons+1] = {
name = "Item: " .. items["Death's Verdict"].name, exec = format([[
return IconICD(67708, 45, 0, 1, 0.3)
]])
}

--------------------------------------------------------------------------------
-- bars
--------------------------------------------------------------------------------
-- Judgements of the Pure
name = spells["Judgements of the Pure"].name
mod.bars[#mod.bars+1] = {
name = name, exec = format([[
return BarAura("HELPFUL|PLAYER", "player", "%s", nil, false, true)
]], name)
}
-- Beacon of Light
name = spells["Beacon of Light"].name
mod.bars[#mod.bars+1] = {
name = name, exec = format([[
return BarSingleTargetRaidBuff("%s", false, true)
]], name)
}

--------------------------------------------------------------------------------
-- micons
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- mbars
--------------------------------------------------------------------------------
-- Censure on multiple targets
mod.mbars[#mod.mbars+1] = {
name = spells["Censure"].name, exec = format([[
MBarSoV(1, 0.5, "before", true)
]])
}

-- Beacon and JoL
mod.mbars[#mod.mbars+1] = {
name = spells["Beacon of Light"].name .. " and " .. spells["Judgements of the Pure"].name, exec = format([[
AddMBar("bol", 1, 1, 0, 0, 1, BarSingleTargetRaidBuff("%s", false, true))
AddMBar("jol", 1, 1, 1, 0, 1, BarAura("HELPFUL|PLAYER", "player", "%s", nil, false, true))
]], spells["Beacon of Light"].name, spells["Judgements of the Pure"].name)
}