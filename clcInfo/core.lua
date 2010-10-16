clcInfo = {}	-- the addon
clcInfo.display = {}	-- display elements go here
clcInfo.templates = {}	-- the templates
clcInfo.classModules = {}  -- stuff loaded per class
clcInfo.cmdList = {}	-- list of functions registered to call from command line parameteres

clcInfo.optionsCMLoaders = {} -- class module options loaders
clcInfo.optionsCMLoadersActiveTemplate = {} -- special list for the ones who need options based on active template

clcInfo.activeTemplate = nil  -- points to the active template
clcInfo.activeTemplateIndex = 0 -- index of the active template

clcInfo.lastBuild = nil	 -- string that has talent info, used to see if talents really changed

clcInfo.mf = CreateFrame("Frame", "clcInfoMF")  -- all elements parented to this frame, so it's easier to hide/show them

clcInfo.mf.unit = "player" -- fix parent unit for when we have to parent bars here

-- frame levels
-- grid: mf + 1
-- icons, bars: mf + 2
-- text: mf + 5
-- alerts: mf + 10
clcInfo.frameLevel = clcInfo.mf:GetFrameLevel()

clcInfo.env = setmetatable({}, {__index = _G})  -- add all data functions in this environment and pass them to the exec calls

clcInfo.LSM = LibStub("LibSharedMedia-3.0")  -- SharedMedia
clcInfo.lbf = LibStub("LibButtonFacade", true)  -- ButtonFacade

-- static popup dialog
StaticPopupDialogs["CLCINFO"] = {
	text = "",
	button1 = OKAY,
	timeout = 0,
}

--------------------------------------------------------------------------------
-- slash command and blizzard options
--------------------------------------------------------------------------------
local function OpenOptions()
	if not clcInfo_Options then
		local loaded, reason = LoadAddOn("clcInfo_Options")
		if( not clcInfo_Options ) then
			print("Failed to load configuration addon. Error returned: ", reason)
			return
		end
	end
	clcInfo_Options:Open()
end

-- add a button to open the config to blizzard's options
local panel = CreateFrame("Frame", "clcInfoPanel", UIParent)
panel.name = "clcInfo"
local b = CreateFrame("Button", "clcInfoPanelOpenConfig", panel, "UIPanelButtonTemplate")
b:SetText("Open config")
b:SetWidth(150)
b:SetHeight(22)
b:SetPoint("TOPLEFT", 10, -10)
b:SetScript("OnClick", OpenOptions)
InterfaceOptions_AddCategory(panel)

-- slash command
SLASH_CLCINFO_OPTIONS1 = "/clcinfo"
SlashCmdList["CLCINFO_OPTIONS"] = function(msg)
	msg = msg and string.lower(string.trim(msg))

	-- no arguments -> open options
	if msg == "" then return OpenOptions() end
	
	-- simple argument handling
	-- try to pass it to the registered function if it exists
	local args = {}
	for v in string.gmatch(msg, "[^ ]+") do tinsert(args, v) end
	local cmd = table.remove(args, 1)
	if clcInfo.cmdList[cmd] then
		clcInfo.cmdList[cmd](args)
	end
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- register functions
--------------------------------------------------------------------------------
-- display modules
function clcInfo:RegisterDisplayModule(name)
	clcInfo.display[name] = {}
	return clcInfo.display[name]
end

-- class modules
function clcInfo:RegisterClassModule(name)
	name = string.lower(name)
	clcInfo.classModules[name] = {}
	return clcInfo.classModules[name]
end

-- global options for class modules
function clcInfo:RegisterClassModuleDB(name, defaults)
	name = string.lower(name)
	defaults = defaults or {}
	if not clcInfo.cdb.classModules[name] then  clcInfo.cdb.classModules[name] = defaults end
	return clcInfo.cdb.classModules[name]
end

-- per template options for class modules
function clcInfo:RegisterClassModuleTDB(name, defaults)
	name = string.lower(name)
	defaults = defaults or {}
	if not clcInfo.activeTemplate then return end
	if not clcInfo.activeTemplate.classModules[name] then clcInfo.activeTemplate.classModules[name] = defaults end
	return clcInfo.activeTemplate.classModules[name]
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- main initialize function
--------------------------------------------------------------------------------
function clcInfo:OnInitialize()
	self:ReadSavedData()
	if not self:FixSavedData() then return end
	
	-- init the class modules
	for k in pairs(clcInfo.classModules) do
		if clcInfo.classModules[k].OnInitialize then
			clcInfo.classModules[k].OnInitialize()
		end
	end
	
	-- scan the talents
	self:TalentCheck()
	
	-- register events
	clcInfo.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")  -- to monitor talent changes
	clcInfo.eventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")  -- to hide while using vehicles
	clcInfo.eventFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
end
--------------------------------------------------------------------------------


-- checks talents and updates the templates if there are changes
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
-- attach it to the event
clcInfo.PLAYER_TALENT_UPDATE = clcInfo.TalentCheck


-- looks for the first template that matches current talent build
-- reinitializes the elements
function clcInfo:OnTemplatesUpdate()
	clcInfo.templates:FindTemplate()  -- find first template if it exists
	
	-- clear elements
	for k in pairs(clcInfo.display) do
		if self.display[k].ClearElements then
			self.display[k]:ClearElements()
		end
	end
	
	-- init elements
	for k in pairs(clcInfo.display) do
		if self.display[k].InitElements then
			self.display[k]:InitElements()
		end
	end
	
	self:ChangeShowWhen()	-- visibility option is template based
	
	if clcInfo.activeTemplate then
		-- call OnTemplatesUpdate on all class modules so they can change options if needed
		for k, v in pairs(clcInfo.classModules) do
			if v.OnTemplatesUpdate then v.OnTemplatesUpdate() end
		end
		
		-- strata of mother frame
		clcInfo.mf:SetFrameStrata(clcInfo.activeTemplate.options.strata)
		-- alpha
		clcInfo.mf:SetAlpha(clcInfo.activeTemplate.options.alpha)
	end
	
	-- change active template and update the options
	if clcInfo_Options then
		clcInfo_Options:LoadActiveTemplate()
	end
	self:UpdateOptions()
end


-- defaults for the db
function clcInfo:GetDefault()
	local data = {
		options = {
			enforceTemplate = 0,
		},
		classModules = {},
		templates = {},
	}
	return data
end


-- read data from saved variables
function clcInfo:ReadSavedData()
	-- global defaults
	if not clcInfoDB then
		clcInfoDB = {}
	end
	clcInfo.db = clcInfoDB	

	-- perchar defaults
	if not clcInfoCharDB then
		clcInfoCharDB = clcInfo:GetDefault()
		table.insert(clcInfoCharDB.templates, clcInfo.templates:GetDefault())
	end

	clcInfo.cdb = clcInfoCharDB
end


-- checks if options are loaded and notifies the changes
function clcInfo:UpdateOptions()
	if clcInfo_Options then
		clcInfo_Options.AceRegistry:NotifyChange("clcInfo")
	end
end


--------------------------------------------------------------------------------
-- hide/show according to combat status, target, etc
--------------------------------------------------------------------------------

-- called when the setting updates
function clcInfo.ChangeShowWhen()
	if not clcInfo.activeTemplate then return end
	
	local mf = clcInfo.mf  -- parent of all frames
	
	-- vehicle check
	if UnitUsingVehicle("player") then
		mf:Hide()
		return
	end

	local val = clcInfo.activeTemplate.options.showWhen

	-- unregister all events first
	local f = clcInfo.eventFrame
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

-- hide/show according to target
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
-- force target update on rezoning
clcInfo.PLAYER_ENTERING_WORLD = clcInfo.PLAYER_TARGET_CHANGED

-- for when target goes from friendly to unfriendly
function clcInfo.UNIT_FACTION(self, event, unit)
	if unit == "target" then
		self.PLAYER_TARGET_CHANGED()
	end
end

-- hide out of combat
function clcInfo.PLAYER_REGEN_ENABLED() clcInfo.mf:Hide() end
function clcInfo.PLAYER_REGEN_DISABLED() clcInfo.mf:Show() end

-- hide in vehicles
function clcInfo.UNIT_ENTERED_VEHICLE(self, event, unit)
	if unit == "player" then
	-- vehicle check
		if UnitUsingVehicle("player") then
			clcInfo.mf:Hide()
			return
		end
	end
end
function clcInfo.UNIT_EXITED_VEHICLE(self, event, unit)
	if unit == "player" then
		clcInfo.ChangeShowWhen()
	end
end
--------------------------------------------------------------------------------

-- OnEvent dispatcher
local function OnEvent(self, event, ...)
	if clcInfo[event] then clcInfo[event](clcInfo, event, ...) end
end
-- event frame
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
-- need an event that fires first time after talents are loaded and fires both at login and reloadui
-- in case this doesn't work have to do with delayed timer
-- using QUEST_LOG_UPDATE atm
clcInfo.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")

-- register some sounds for LSM just to be sure I have them
clcInfo.LSM:Register("sound", "clcInfo: Default", [[Sound\Doodad\BellTollAlliance.wav]])
clcInfo.LSM:Register("sound", "clcInfo: Run", [[Sound\Creature\HoodWolf\HoodWolfTransformPlayer01.wav]])
clcInfo.LSM:Register("sound", "clcInfo: Explosion", [[Sound\Doodad\Hellfire_Raid_FX_Explosion05.wav]])
clcInfo.LSM:Register("sound", "clcInfo: Die", [[Sound\Creature\CThun\CThunYouWillDIe.wav]])
clcInfo.LSM:Register("sound", "clcInfo: Cheer", [[Sound\Event Sounds\OgreEventCheerUnique.wav]])

-- static popup dialog call
function clcInfo:SPD(s)
	StaticPopupDialogs.CLCINFO.text = s
	StaticPopup_Show("CLCINFO")
end


