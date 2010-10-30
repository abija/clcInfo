-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "WARRIOR" then return end

local mod = clcInfo_Options.templates
local defs = mod.defs
local format = string.format

-- fury
--------------------------------------------------------------------------------
-- Frost Rotation Skill 1
mod:Add("icons", defs.CLASS_2, "Fury Rotation Skill 1", "return IconFury1(50, 80)")
mod:Add("icons", defs.CLASS_2, "Fury Rotation Skill 2", "IconFury2()")
