-- don't load if class is wrong
--[[
local _, class = UnitClass("player")
if class ~= "WARRIOR" then return end

local GetTime = GetTime
local version = 1


-- mod name in lower case
local modName = "_protection"

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule(modName)
local db
-- functions visible to exec should be attached to this
local emod = clcInfo.env
--]]
