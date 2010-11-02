-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local emod = clcInfo.env

