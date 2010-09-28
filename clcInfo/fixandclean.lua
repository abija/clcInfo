local function bprint(...)
	if true then return end	-- lazy full disable

	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\fixandclean> " .. table.concat(t, " "))
end

clcInfo.__version = 21

--------------------------------------------------------------------------------
-- TODO, make this GOOD
-- !!! think properly about this shit
--------------------------------------------------------------------------------
--[[
mirrors config table t2 to t1
	* looks for keys in t2 that do not exist in t1 and adds them
	* looks for keys in t1 that do not exist in t2 and deletes them
	* common keys are not changed
--]]
local function HasKey(t, key)
	for k, v in pairs(t) do
		if k == key then return true end
	end
	return false
end
-- IMPOTANT: does not delete not found keys due to the way it's called
local AdaptConfig
AdaptConfig = function(info, t1, t2)
	if t1 == nil or type(t1) ~= "table" then bprint(info, "t1 is not a table") return end
	if t2 == nil or type(t2) ~= "table" then bprint(info, "t2 is not a table") return end
	
	for k, v in pairs(t2) do
		if not HasKey(t1, k) then
			bprint("not found: " .. info .. ":" .. tostring(k))
			-- go recursive for tables
			if type(v) == "table" then
				t1[k] = {}
				if not AdaptConfig(info .. "." .. tostring(k), t1[k], v) then return end
			else
				t1[k] = v
			end
		else
			bprint("found: " .. info .. ":" .. tostring(k))
			if type(v) == "table" then
				if type(t1[k]) ~= "table" then t1[k] = {} end
				if not AdaptConfig(info .. "." .. tostring(k), t1[k], v) then return end
			end
		end
	end
	
	return true
end

-- to be done
local function CleanConfig()
	for k, v in pairs(t1) do
		if not HasKey(t2, k) then t1[k] = nil end
	end
end

-- NOT FINISHED
function clcInfo:FixSavedData()
	-- check last version
	
	if not clcInfo.cdb.version then clcInfo.cdb.version = 0 end
	if clcInfo.cdb.version == clcInfo.__version then return true end
	
	bprint("performing db maintenace")
	
	AdaptConfig("cdb", clcInfo.cdb, clcInfo:GetDefault())
	
	-- templates
	local x = clcInfo.cdb.templates
	for i = 1, #x do
		if not AdaptConfig("template" .. i, x[i], clcInfo.display.templates:GetDefault()) then return end
		if not AdaptConfig("template" .. i .. ".spec", x[i].spec, { tree = 1, talent = 0, rank = 1 }) then return end
		if not AdaptConfig("template" .. i .. ".options", x[i].options, { gridSize = 1, showWhen = "always" }) then return end
		
		if not AdaptConfig("template" .. i .. ".skinOptions", x[i].skinOptions, { icons = {}, bars = {}, mbars = {} }) then return end		
		if not AdaptConfig("template" .. i .. ".skinOptions.icons", x[i].skinOptions.icons, clcInfo.display.icons:GetDefaultSkin()) then return end
		if not AdaptConfig("template" .. i .. ".skinOptions.bars", x[i].skinOptions.bars, clcInfo.display.bars:GetDefaultSkin()) then return end
		if not AdaptConfig("template" .. i .. ".skinOptions.mbars", x[i].skinOptions.mbars, clcInfo.display.mbars:GetDefaultSkin()) then return end
		
		-- grids
		local y = x[i].grids
		for j =1, #y do
			if not AdaptConfig("template" .. i .. ".grid" .. j, y[j], clcInfo.display.grids.GetDefault()) then return end
		end
		-- icons
		local y = x[i].icons
		for j =1, #y do
			if not AdaptConfig("template" .. i .. ".icons" .. j, y[j], clcInfo.display.icons.GetDefault()) then return end
		end
		-- bars
		local y = x[i].bars
		for j =1, #y do
			if not AdaptConfig("template" .. i .. ".bars" .. j, y[j], clcInfo.display.bars.GetDefault()) then return end
		end
		-- mbars
		local y = x[i].mbars
		for j =1, #y do
			if not AdaptConfig("template" .. i .. ".bars" .. j, y[j], clcInfo.display.mbars.GetDefault()) then return end
		end
	end
	
	clcInfo.cdb.version = clcInfo.__version
	return true
end
--------------------------------------------------------------------------------