local mod = clcInfo_Options.templates
local format = string.format
local name

--------------------------------------------------------------------------------
-- icons
--------------------------------------------------------------------------------

-- Trinket Slot 1
mod.icons[#mod.icons+1] = {
name = "Item: Trinket Slot 1", exec = format([[
return IconItem(GetInventoryItemID("player", 13))
]])
}