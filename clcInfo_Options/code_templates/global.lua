local mod = clcInfo_Options.templates
local format = string.format
local name

-- list of items used to get localized versions
local items = {
	["Whispering Fanged Skull"] = 50342,
	["Death's Verdict"] = 47115,
	["Deathbringer's Will"] = 50362,
	["Ashen Band of Endless Might"] = 52572,
	["Sharpened Twilight Scale"] = 54569,
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

-- Trinket Slot 1
mod.icons[#mod.icons+1] = {
name = "Item: Trinket Slot 1", exec = format([[
return IconItem(GetInventoryItemID("player", 13))
]])
}

-- Ashen Band of Endless Might
mod.icons[#mod.icons+1] = {
name = "Item: " .. items["Ashen Band of Endless Might"].name, exec = "return IconICD(72412, 60, 0, 1, 0.3)" }

-- Whispering Fanged Skull
mod.icons[#mod.icons+1] = {
name = "Item: " .. items["Whispering Fanged Skull"].name, exec = "return IconICD(71401, 45, 0, 1, 0.3)" }
mod.icons[#mod.icons+1] = {
name = "Item: [H] " .. items["Whispering Fanged Skull"].name, exec = "return IconICD(71541, 45, 0, 1, 0.3)" }

-- Death's Verdict
mod.icons[#mod.icons+1] = {
name = "Item: " .. items["Death's Verdict"].name, exec = "return IconICD(67708, 45, 0, 1, 0.3)" }
mod.icons[#mod.icons+1] = {
name = "Item: [H] " .. items["Death's Verdict"].name, exec = "return IconICD(67773, 45, 0, 1, 0.3)" }

-- Deathbringer's Will
mod.icons[#mod.icons+1] = {
name = "Item: " .. items["Deathbringer's Will"].name, exec = "return IconMICD(105, 0, 1, 0.3, 71484, 71491, 71492)" }
mod.icons[#mod.icons+1] = {
name = "Item: [H] " .. items["Deathbringer's Will"].name, exec = "return IconMICD(105, 0, 1, 0.3, 71561, 71559, 71560)" }

-- Sharpened Twilight Scale
mod.icons[#mod.icons+1] = {
name = "Item: " .. items["Sharpened Twilight Scale"].name, exec = "return IconICD(75458, 45, 0, 1, 0.3)" }
mod.icons[#mod.icons+1] = {
name = "Item: [H] " .. items["Sharpened Twilight Scale"].name, exec = "return IconICD(75456, 45, 0, 1, 0.3)" }

