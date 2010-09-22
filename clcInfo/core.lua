local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\core> " .. table.concat(t, " "))
end

-- clcInfo = LibStub("AceAddon-3.0"):NewAddon("clcInfo", "AceConsole-3.0")
clcInfo = {}
clcInfo.display = { templates = {}, grids = {}, icons = {} }

clcInfo.classModules = {}

-- list of functions registered to call from command line parameteres
clcInfo.cmdList = {}

-- active template
clcInfo.activeTemplate = nil
clcInfo.activeTemplateIndex = 0

-- string that has talent info
clcInfo.lastBuild = nil

-- spawn all elements parented in a single frame, so it's easier to hide/show them
-- the mother frame :D
clcInfo.mf = CreateFrame("Frame", "clcInfoMF")

-- add all data functions in this environment and pass them to the exec calls
clcInfo.env = setmetatable({}, {__index = _G})

-- Button Facade
clcInfo.lbf = LibStub("LibButtonFacade", true)

-- slash command to open options
SLASH_CLCINFO_OPTIONS1 = "/clcinfo"
SlashCmdList["CLCINFO_OPTIONS"] = function(msg)
	msg = msg and string.lower(string.trim(msg))

	-- no msg -> open options
	if msg == "" then
		local loaded, reason = LoadAddOn("clcInfo_Options")
		if( not clcInfo_Options ) then
			bprint("Failed to load configuration addon. Error returned: ", reason)
			return
		end
		
		clcInfo_Options:Open()
		return
	end
	
	-- simple argument handling
	local args = {}
	for v in string.gmatch(msg, "[^ ]+") do tinsert(args, v) end
	local cmd = table.remove(args, 1)
	if clcInfo.cmdList[cmd] then
		clcInfo.cmdList[cmd](args)
	end
end


function clcInfo:OnInitialize()
	self:ReadSavedData()
	
	-- init the class modules
	for c in pairs(clcInfo.classModules) do
		for s in pairs(clcInfo.classModules[c]) do
			if clcInfo.classModules[c][s].OnInitialize then
				clcInfo.classModules[c][s].OnInitialize()
			end
		end
	end
	
	-- scan the talents
	self:TalentCheck()
end

function clcInfo:TalentCheck()
	-- get current spec as a string
	local t = {}
	local name, rank, j
	for i = 1, 3 do
		t[#t + 1] = "_"
		j = 1
		name, _, _, _, rank = GetTalentInfo(i, j)
		while name do
			t[#t + 1] = tostring(rank)
			j = j + 1
			name, _, _, _, rank = GetTalentInfo(i, j)
		end
	end
	
	local build = table.concat(t, "")
	if build ~= self.lastBuild then
		self.lastBuild = build
		clcInfo:OnTemplatesUpdate()
	end
end

function clcInfo:OnTemplatesUpdate()
	clcInfo.display.templates:FindTemplate()
	
	-- clear stuff
	self.display.icons:ClearIcons()
	self.display.grids:ClearGrids()
	
	-- init stuff
	self.display.grids:InitGrids()
	self.display.icons:InitIcons()
	
	self:ChangeShowWhen()
	
	-- change active 
	if clcInfo_Options then
		clcInfo_Options:LoadActiveTemplate()
	end
	
	self:UpdateOptions()
end


function clcInfo:RegisterClassModule(class, name)
	class = string.lower(class)
	name = string.lower(name)
	if not clcInfo.classModules[class] then clcInfo.classModules[class] = {} end
	clcInfo.classModules[class][name] = {}
	return clcInfo.classModules[class][name]
end

function clcInfo:RegisterClassModuleDB(class, name, defaults)
	class = string.lower(class)
	name = string.lower(name)
	defaults = defaults or {}
	if not clcInfo.cdb.classModules[class] then clcInfo.cdb.classModules[class] = {} end
	if not clcInfo.cdb.classModules[class][name] then  clcInfo.cdb.classModules[class][name] = defaults end
	return clcInfo.cdb.classModules[class][name]
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
		clcInfo.eventFrame:UnregisterEvent("QUEST_LOG_UPDATE")
		clcInfo.eventFrame:SetScript("OnEvent", OnEvent)
		clcInfo:OnInitialize()
	end
end)

clcInfo.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
clcInfo.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
