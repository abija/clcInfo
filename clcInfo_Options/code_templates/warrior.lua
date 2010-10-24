-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "WARRIOR" then return end

local mod = clcInfo_Options.templates
local format = string.format

-- Frost Rotation Skill 1
mod.icons[#mod.icons+1] = { name = "Fury Rotation Skill 1", exec = "return IconFury1(50, 80)" }
mod.icons[#mod.icons+1] = { name = "Fury Rotation Skill 2", exec = "return IconFury2()" }
