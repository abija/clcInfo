local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\core> " .. table.concat(t, " "))
end

local debugMode = true
local function dbg(...)
	if debugMode then bprint(...) end
end

-- clcInfo = LibStub("AceAddon-3.0"):NewAddon("clcInfo", "AceConsole-3.0")
clcInfo = {}
clcInfo.display = { templates = {}, grids = {}, icons = {}, icons_options = nil, }
clcInfo.data = { auras = {}, }

clcInfo.activeTemplate = nil
clcInfo.activeTemplateIndex = 0

-- add all data functions in this environment and pass them to the exec calls
clcInfo.env = setmetatable({}, {__index = _G})

-- AceGUI
clcInfo.gui = LibStub("AceGUI-3.0")

-- Button Facade
clcInfo.lbf = LibStub("LibButtonFacade", true)

-- slash command to open options
SLASH_CLCINFO_OPTIONS1 = "/clcinfo"
SlashCmdList["CLCINFO_OPTIONS"] = function()
	local loaded, reason = LoadAddOn("clcInfo_Options")
	if( not clcInfo.config ) then
		bprint("Failed to load configuration addon. Error returned: ", reason)
		return
	end
	
	clcInfo.config:Open()
end

function clcInfo:OnInitialize()
	dbg("OnInitialize")
	self:ReadSavedData()
	self:TalentCheck()
end

function clcInfo:TalentCheck()
	dbg("TalentCheck")
	if not clcInfo.display.templates:FindTemplate() then
		-- bprint("No template available for current talent configuration.")
	end
	
	-- init stuff :D
	clcInfo.display.grids:InitGrids()
	clcInfo.display.icons:InitIcons()
	
	-- reload active template options
	if clcInfo_Options then
		clcInfo_Options:LoadActiveTemplate()
	end
end

function clcInfo:FindTemplate()

end

function clcInfo:CreateTemplate()
	local tlp = {}
end


-- config fix functions

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
local function AdaptConfig(t1, t2)
	for k, v in pairs(t2) do
		if not HasKey(t1, k) then t1[k] = v end
	end
	
	for k, v in pairs(t1) do
		if not HasKey(t2, k) then t1[k] = nil end
	end
end

--[[
templates
--------------------------------------------------------------------------------
spec = {tree, talent, rank}
icons = {}
iconOptions = { skinType, bfSkin }
--------------------------------------------------------------------------------
--]]
local function DBPrepare_CDB()
	local xdb = clcInfoCharDB.templates
	for i = 1, #xdb do
		AdaptConfig(xdb[i], { spec = {}, grids = {}, icons = {}, options = {}, iconOptions = {} })
		AdaptConfig(xdb[i].spec, { tree = 1, talent = 0, rank = 1 })
		AdaptConfig(xdb[i].options, {
			gridSize = 1,
		})
		AdaptConfig(xdb[i].iconOptions, {
			skinType = "Default",
			bfSkin = "Blizzard",
			bfGloss = 0,
		})
		
		-- fix the icons
		for j = 1, #(xdb[i].icons) do
			AdaptConfig(xdb[i].icons[j], {
				x = 0,
				y = 0,
				point = "BOTTOMLEFT",
				relativeTo = "UIParent",
		    relativePoint = "BOTTOMLEFT",
				width = 30,
				height = 30,
				exec = "return DoNothing()",
				ups = 10,
				gridId = 0,
				gridX = 1,	
				gridY = 1,	
				sizeX = 1,
				sizeY = 1,
			})
		end
	end
end

function clcInfo:ReadSavedData()
	dbg("ReadSavedData")
	
	-- global defaults
	if not clcInfoDB then
		clcInfoDB = {
		}
	end

	-- char defaults
	if not clcInfoCharDB then
		clcInfoCharDB = {
			templates = {
				-- this is a blank template
				{
					spec = { tree = 1, talent = 0, rank = 1 },
					grids = {},
					icons = {},
					options = {
						gridSize = 1,
					},
					iconOptions = {
						skinType = "Default",
						bfSkin = "Blizzard",
						bfGloss = 0,
					},
				},
			},
		}
	end
	DBPrepare_CDB()

	clcInfo.db = clcInfoDB	
	clcInfo.cdb = clcInfoCharDB
end

function clcInfo:UpdateOptions()
	if clcInfo_Options then
		clcInfo_Options.AceRegistry:NotifyChange("clcInfo")
	end
end


-- event frame
-- need an event that fires first time after talents are loaded and fires both at login and reloadui
-- in case this doesn't work have to do with delayed timer
do
	local function OnEvent(self, event)
		dbg("OnEvent", event)
		if event == "QUEST_LOG_UPDATE" then
			-- intialize & unregister
			clcInfo:OnInitialize()
			clcInfo.eventFrame:UnregisterEvent("QUEST_LOG_UPDATE")
		elseif event == "PLAYER_TALENT_UPDATE" then
			clcInfo:TalentCheck()
		end
	end
	clcInfo.eventFrame = CreateFrame("Frame")
	clcInfo.eventFrame:Hide()
	clcInfo.eventFrame:SetScript("OnEvent", OnEvent)
	
	clcInfo.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
	clcInfo.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
end
