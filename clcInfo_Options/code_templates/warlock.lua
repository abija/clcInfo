-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "WARLOCK" then return end

local mod = clcInfo_Options.templates
local defs = mod.defs
local format = string.format

-- retribution
--------------------------------------------------------------------------------
-- Retribution Rotation Skill 1 & 2
mod:Add("icons", defs.CLASS_3, "Destruction Rotation Skill 1", 'return IconDestruction1()')
