local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\core> " .. table.concat(t, " "))
end

-- clcInfo = LibStub("AceAddon-3.0"):NewAddon("clcInfo", "AceConsole-3.0")
clcInfo = {}
clcInfo.display = { templates = {}, grids = {}, icons = {}, icons_options = nil, }
clcInfo.data = { auras = {}, }

-- list of functions to call on initialize
clcInfo.initList = {}

clcInfo.activeTemplate = nil
clcInfo.activeTemplateIndex = 0

-- spawn all elements parented in a single frame, so it's easier to hide/show them
-- the mother frame :D
clcInfo.mf = CreateFrame("Frame", "clcInfoMF")

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
	if( not clcInfo_Options ) then
		bprint("Failed to load configuration addon. Error returned: ", reason)
		return
	end
	
	clcInfo_Options:Open()
end

function clcInfo:OnInitialize()
	self:ReadSavedData()
	
	for i = 1, #(self.initList) do
		self.initList[i]()
	end
	self:TalentCheck()
end

function clcInfo:TalentCheck()
	clcInfo.display.templates:FindTemplate()
	--[[
	if not clcInfo.display.templates:FindTemplate() then
		-- announce or not ?
		-- bprint("No template available for current talent configuration.")
	end
	--]]
	
	-- clear stuff
	self.display.icons:ClearIcons()
	self.display.grids:ClearGrids()
	
	-- init stuff
	self.display.grids:InitGrids()
	self.display.icons:InitIcons()
	
	self:ChangeShowWhen()
	
	-- reload active template options
	if clcInfo_Options then
		clcInfo_Options:LoadActiveTemplate()
		clcInfo_Options:LoadClassModules()
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
	AdaptConfig(clcInfoCharDB, { classModules = {}, templates = {} })

	local xdb = clcInfoCharDB.templates
	for i = 1, #xdb do
		AdaptConfig(xdb[i], { spec = {}, grids = {}, icons = {}, options = {}, iconOptions = {} })
		AdaptConfig(xdb[i].spec, { tree = 1, talent = 0, rank = 1 })
		AdaptConfig(xdb[i].options, {
			gridSize = 1,
			showWhen = "always",
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
				ups = 5,
				gridId = 0,
				gridX = 1,	
				gridY = 1,	
				sizeX = 1,
				sizeY = 1,
			})
		end
		
		-- fix the grids too
		for j = 1, #(xdb[i].grids) do
			AdaptConfig(xdb[i].grids[j], {
				cellWidth = 30,
				cellHeight = 30,
				spacingX = 2,
				spacingY = 2,
				cellsX = 3,
				cellsY = 3,
				x = 0,
				y = 0,
				point = "CENTER",
		    relativePoint = "CENTER",
		    skinType = "Default",
				bfSkin = "Blizzard",
				bfGloss = 0,
			})
		end
	end
end

function clcInfo:ReadSavedData()
	
	-- global defaults
	if not clcInfoDB then
		clcInfoDB = {
		}
	end

	-- char defaults
	if not clcInfoCharDB then
		clcInfoCharDB = {
			classModules = {},
			templates = {
				-- this is a blank template
				{
					spec = { tree = 1, talent = 0, rank = 1 },
					grids = {},
					icons = {},
					options = {
						gridSize = 1,
						showWhen = "always",
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



--------------------------------------------------------------------------------
-- handle showing and hiding elements depending on target/combat/other stuff
--------------------------------------------------------------------------------
function clcInfo.ChangeShowWhen(info, val)
	if not clcInfo.activeTemplate then return end

	if val then
		clcInfo.activeTemplate.options.showWhen = val
	else
		val = clcInfo.activeTemplate.options.showWhen
	end
	
	local f = clcInfo.eventFrame
	local mf = clcInfo.mf
	
	-- unregister all events first
	f:UnregisterEvent("PLAYER_REGEN_ENABLED")
	f:UnregisterEvent("PLAYER_REGEN_DISABLED")
	f:UnregisterEvent("PLAYER_TARGET_CHANGED")
	f:UnregisterEvent("PLAYER_ENTERING_WORLD")
	f:UnregisterEvent("UNIT_FACTION")
	
	-- show in combat
	if val == "combat" then
		if UnitAffectingCombat("player") then
			mf:Show()
		else
			mf:Hide()
		end
		f:RegisterEvent("PLAYER_REGEN_ENABLED")
		f:RegisterEvent("PLAYER_REGEN_DISABLED")
		
	-- show on certain targets
	elseif val == "valid" or val == "boss" then
		clcInfo:PLAYER_TARGET_CHANGED()
		f:RegisterEvent("PLAYER_TARGET_CHANGED")
		f:RegisterEvent("PLAYER_ENTERING_WORLD")
		f:RegisterEvent("UNIT_FACTION")
		
	-- show always
	else
			mf:Show()
	end
end

function clcInfo.PLAYER_TARGET_CHANGED()
	local show = clcInfo.activeTemplate.options.showWhen

	if show == "boss" then
		if UnitClassification("target") ~= "worldboss" and UnitClassification("target") ~= "elite" then
			clcInfo.mf:Hide()
			return
		end
	end
	
	if UnitExists("target") and UnitCanAttack("player", "target") and (not UnitIsDead("target")) then
		clcInfo.mf:Show()
	else
		clcInfo.mf:Hide()
	end
end
clcInfo.PLAYER_ENTERING_WORLD = clcInfo.PLAYER_TARGET_CHANGED

function clcInfo.UNIT_FACTION(self, event, unit)
	if unit == "target" then
		self.PLAYER_TARGET_CHANGED()
	end
end

-- out of combat
function clcInfo.PLAYER_REGEN_ENABLED()
	clcInfo.mf:Hide()
end
-- in combat
function clcInfo.PLAYER_REGEN_DISABLED()
	clcInfo.mf:Show()
end

function clcInfo.PLAYER_TALENT_UPDATE()
	bprint("PLAYER_TALENT_UPDATE")
	clcInfo:TalentCheck()
end
--------------------------------------------------------------------------------


-- event frame
-- need an event that fires first time after talents are loaded and fires both at login and reloadui
-- in case this doesn't work have to do with delayed timer
local function OnEvent(self, event, ...)
	-- dispatch the event
	if clcInfo[event] then clcInfo[event](clcInfo, event, ...) end
end
clcInfo.eventFrame = CreateFrame("Frame")
clcInfo.eventFrame:Hide()
clcInfo.eventFrame:SetScript("OnEvent", function(self, event)
	if event == "QUEST_LOG_UPDATE" then
		-- intialize, unregister, change event function
		clcInfo:OnInitialize()
		clcInfo.eventFrame:UnregisterEvent("QUEST_LOG_UPDATE")
		clcInfo.eventFrame:SetScript("OnEvent", OnEvent)
	end
end)

clcInfo.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
clcInfo.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
