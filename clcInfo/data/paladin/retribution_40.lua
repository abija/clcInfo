-- build check
local _, _, _, toc = GetBuildInfo()
if toc < 40000 then return end


-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\data\\paladin\\retribution> " .. table.concat(t, " "))
end

-- TODO, maybe fix?
-- some lazy staic numbers
local MAX_FCFS = 10							-- elements in fcfs
local MAX_PRESETS = 10					-- number of presets

-- default settings for this module
--------------------------------------------------------------------------------
local defaults = {
	fcfs = { "j", "ds", "cs", "how", "cons", "exo", "none", "none", "none", "none" },
	presets = {},
	presetFrame = {
		visible = false,
		enableMouse = false,
		expandDown = false,
		alpha = 1,
		width = 200,
		height = 25,
		x = 0,
		y = 0,
		point = "CENTER",
		relativePoint = "CENTER",
		backdropColor = { 0.1, 0.1, 0.1, 0.5 },
		backdropBorderColor = { 0.4, 0.4, 0.4 },
		fontSize = 13,
		fontColor = { 1, 1, 1, 1 },
	},
	highlight = true,
	highlightChecked = true,
	rangePerSkill = false,
}
-- blank presets
for i = 1, MAX_PRESETS do 
	defaults.presets[i] = { name = "", data = "" }
end
--------------------------------------------------------------------------------

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule(class, "retribution")
local db

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleDB(class, "retribution", defaults)
	mod.InitSpells()
	mod.UpdateFCFS()
	
	if db.presetFrame.visible then
		mod.PresetFrame_Init()
	end
end

-- functions visible to exec should be attached to this
local emod = clcInfo.env


-- any error sets this to false
local enabled = true

-- preset frames
local presetFrame, presetPopup

-- used for "pluging in"
local s2
local UpdateS2

-- cleanse spell name, used for gcd
local cleanseSpellName = GetSpellInfo(4987)

-- various other spells
local taowSpellName = GetSpellInfo(59578) 				-- the art of war
local sovName, sovId, sovSpellTexture
if UnitFactionGroup("player") == "Alliance" then
	sovId = 31803
	sovName = GetSpellInfo(31803)						-- holy vengeance
	sovSpellTexture = GetSpellInfo(31801)
else
	sovId = 53742
	sovName = GetSpellInfo(53742)						-- blood corruption
	sovSpellTexture = GetSpellInfo(53736)
end

-- priority queue generated from fcfs
local pq
local ppq
-- number of spells in the queue
local numSpells
-- display queue
local dq = { cleanseSpellName, cleanseSpellName }

-- the spells available for the fcfs
local spells = {
		how		= { id = 48806 },		-- hammer of wrath
		cs 		= { id = 35395 },		-- crusader strike
		ds 		= { id = 53385 },		-- divine storm
		j 		= { id = 53408 },		-- judgement (using wisdom icon)
		cons 	= { id = 48819 },		-- consecration
		exo 	= { id = 48801 },		-- exorcism
		dp 		= { id = 54428 },		-- divine plea
		ss 		= { id = 53601 },		-- sacred shield
		hw		= { id = 2812  },		-- holy wrath
		sor 	= { id = 53600 },		-- shield of righteousness
}
-- expose for options
mod.spells = spells

-- used for the highlight lock on skill use
local lastgcd = 0
local startgcd = -1
local lastMS = ""
local gcdMS = 0

-- get the spell names from ids
function mod.InitSpells()
	for alias, data in pairs(spells) do
		data.name = GetSpellInfo(data.id)
	end
end

function mod.UpdateFCFS()
	local newpq = {}
	local check = {}
	numSpells = 0
	
	for i, alias in ipairs(db.fcfs) do
		if not check[alias] then -- take care of double entries
			check[alias] = true
			if alias ~= "none" then
				-- fix blank entries
				if not spells[alias] then
					db.fcfs[i] = "none"
				else
					numSpells = numSpells + 1
					newpq[numSpells] = { alias = alias, name = spells[alias].name }
				end
			end
		end
	end
	
	pq = newpq
	
	-- check if people added enough spells
	if numSpells < 2 then
		bprint("You need at least 2 skills in the queue.")
		-- toggle it off
		enabled = false
	end
	
	mod.PresetFrame_Update()
end

function mod.DisplayFCFS()
	bprint("Active Retribution FCFS:")
	for i, data in ipairs(pq) do
		bprint(i .. " " .. data.name)
	end
end

--	algorithm:
--		get min cooldown
--		adjust all the others to cd - mincd - 1.5
--		get min cooldown

-- returns the lowest cooldown and skill index
local function GetMinCooldown()
	local cd, index, v
	index = 1
	cd = pq[1].cd
	-- old bug, fix them even if they are first
	if (pq[1].alias == "dp" and delayDP) or (pq[1].alias == "ss") then
		cd = cd + db.gcdDpSs
	end
	
	-- get min cooldown
	for i = 1, numSpells do
		v = pq[i]
		-- if skill is a better choice change index
		if (v.alias == "dp" and delayDP) or (v.alias == "ss") then	
			-- special case with delay
			if ((v.cd + db.gcdDpSs) < cd) or (((v.cd + db.gcdDpSs) == cd) and (i < index)) then
				index = i
				cd = v.cd
			end
		else
			-- normal check
			if (v.cd < cd) or ((v.cd == cd and i < index)) then
				index = i
				cd = v.cd
			end
		end
	end
	
	return cd, index
end

-- gets first and 2nd skill in the queue
local function GetSkills()
	local cd, index, v
	
	-- dq[1] = skill with shortest cooldown
	cd, index = GetMinCooldown()
	dq[1] = pq[index].name
	pq[index].cd = 100
	
	-- adjust cd
	cd = cd + 1.5
	
	-- substract the cd from prediction cooldowns
	for i = 1, numSpells do
		v = pq[i]
		v.cd = max(0, v.cd - cd)
	end
	
	-- dq[2] = get the skill with shortest cooldown
	cd, index = GetMinCooldown()
	dq[2] = pq[index].name
end

-- ret queue function
function mod.RetRotation()
	local ctime, gcd, gcdStart, gcdDuration, v
	ctime = GetTime()
	
	-- get gcd
	gcdStart, gcdDuration = GetSpellCooldown(cleanseSpellName)
	if gcdStart > 0 then
		gcd = gcdStart + gcdDuration - ctime
	else
		gcd = 0
	end
	
	-- update cooldowns
	for i = 1, numSpells do
		v = pq[i]
		
		v.cdStart, v.cdDuration = GetSpellCooldown(v.name)
		if not v.cdDuration then return end -- try to solve respec issues
		
		if v.cdStart > 0 then
			v.cd = v.cdStart + v.cdDuration - ctime
		else
			v.cd = 0
		end
		
		-- ds gcd fix?
		-- todo: check
		if v.cd < gcd then v.cd = gcd end
		
		-- how check
		if v.alias == "how" then
			if not IsUsableSpell(v.name) then v.cd = 100 end
		-- art of war for exorcism check
		elseif v.alias == "exo" then
			if UnitBuff("player", taowSpellName) == nil then v.cd = 100 end
		end
		
		-- adjust to gcd
		v.cd = v.cd - gcd
	end
	
	GetSkills()
	return true
end


--------------------------------------------------------------------------------
-- mod.PresetFunctions
--------------------------------------------------------------------------------
-- update layout
function mod.PresetFrame_UpdateLayout()
	local opt = db.presetFrame

	-- preset frame
	local frame = presetFrame
		
	frame:SetWidth(opt.width)
	frame:SetHeight(opt.height)
	frame:ClearAllPoints()
	frame:SetPoint(opt.point, "UIParent", opt.relativePoint, opt.x, opt.y)
	
	frame:SetBackdropColor(unpack(opt.backdropColor))
	frame:SetBackdropBorderColor(unpack(opt.backdropBorderColor))
	
	frame.text:SetFont(STANDARD_TEXT_FONT, opt.fontSize)
	frame.text:SetVertexColor(unpack(opt.fontColor))
	
	frame.text:SetAllPoints(frame)
	frame.text:SetJustifyH("CENTER")
	frame.text:SetJustifyV("MIDDLE")
	
	-- popup
	local popup = presetPopup
	popup:SetBackdropColor(unpack(opt.backdropColor))
	popup:SetBackdropBorderColor(unpack(opt.backdropBorderColor))
	
	popup:SetWidth(opt.width)
	popup:SetHeight((opt.fontSize + 7) * MAX_PRESETS + 40)
	popup:ClearAllPoints()
	if opt.expandDown then
		popup:SetPoint("TOP", frame, "BOTTOM", 0, 0)
	else
		popup:SetPoint("BOTTOM", frame, "TOP", 0, 0)
	end
	
	local button
	for i = 1, MAX_PRESETS do
		button = presetButtons[i]
	
		button:SetWidth(opt.width - 20)
		button:SetHeight(opt.fontSize + 7)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -10 - (opt.fontSize + 9) * (i - 1))

		button.name:SetJustifyH("LEFT")
		button.name:SetJustifyV("MIDDLE")
		button.name:SetAllPoints()
		button.name:SetVertexColor(unpack(opt.fontColor))
		
		button.name:SetFont(STANDARD_TEXT_FONT, opt.fontSize)
	end
	
end

function mod.PresetFrame_UpdateMouse()
	if presetFrame then
		presetFrame:EnableMouse(db.presetFrame.enableMouse)
	end
end

-- checks if the current rotation is in any of the presets and updates text
function mod.PresetFrame_Update()
	if not presetFrame then return end

	local t = {}
	for i = 1, #pq do
		t[i] = pq[i].alias
	end
	local rotation = table.concat(t, " ")
	
	local preset = "no preset"
	for i = 1, MAX_PRESETS do
		-- bprint(rotation, " | ", db.presets[i].data)
		if db.presets[i].data == rotation and rotation ~= "" then
			preset = db.presets[i].name
			break
		end
	end
	
	presetFrame.text:SetText(preset)
	
	-- update the buttons
	if presetButtons then
		local button
		for i = 1, MAX_PRESETS do
			button = presetButtons[i]
			if db.presets[i].name ~= "" then
				button.name:SetText(db.presets[i].name)
				button:Show()
			else
				button:Hide()
			end
		end
	end
end

function mod.PresetFrame_UpdateAll()
	if presetFrame then
		mod.PresetFrame_UpdateLayout()
		mod.PresetFrame_UpdateMouse()
		mod.PresetFrame_Update()
	end
end

-- load a preset
function mod.Preset_Load(index)
	if db.presets[index].name == "" then return end

	if (not presetFrame) or (not presetFrame:IsVisible()) then
		bprint("Loading preset:", db.presets[index].name)
	end
	
	local list = { strsplit(" ", db.presets[index].data) }

	local num = 0
	for i = 1, #list do
		if spells[list[i]] then
			num = num + 1
			db.fcfs[num] = list[i]
		end
	end
	
	-- none on the rest
	if num < MAX_PRESETS then
		for i = num + 1, MAX_PRESETS do
			db.fcfs[i] = "none"
		end
	end
	
	-- redo queue
	mod.UpdateFCFS()
	mod.PresetFrame_Update()
end

function mod.PresetFrame_Init()
	local opt = db.presetFrame
	
	local backdrop = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
	}

	-- frame
	local frame = CreateFrame("Button")
	presetFrame = frame
	
	frame:EnableMouse(opt.enableMouse)
	frame:SetBackdrop(backdrop)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	
	-- fontstring
	local fs = frame:CreateFontString(nil, nil, "GameFontHighlight")
	frame.text = fs
	
	-- popup frame
	local popup = CreateFrame("Frame", nil, frame)
	presetPopup = popup
	
	popup:Hide()
	popup:SetBackdrop(backdrop)
	popup:SetFrameStrata("FULLSCREEN_DIALOG")
	
	-- buttons for the popup frame
	local button
	presetButtons = {}
	for i = 1, MAX_PRESETS do
		button = CreateFrame("Button", nil, popup)
		presetButtons[i] = button
		
		button.highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
		button.highlightTexture:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		button.highlightTexture:SetBlendMode("ADD")
		button.highlightTexture:SetAllPoints()
		
		button.name = button:CreateFontString(nil, nil, "GameFontHighlight")
		button.name:SetText(db.presets[i].name)
		
		button:SetScript("OnClick", function()
			mod.Preset_Load(i)
			popup:Hide()
		end)
	end
	
	-- toggle popup on click
	frame:SetScript("OnClick", function()
		if popup:IsVisible() then
			popup:Hide()
		else
			popup:Show()
		end
	end)
	
	-- update the layout
	mod.PresetFrame_UpdateAll()	
end



-- toggles show and hide
function mod.PresetFrame_Toggle()
	-- the frame is not loaded by default, so check if init took place
	if not presetFrame then
		-- need to do init
		mod.PresetFrame_Init()
		presetFrame:Show()
		db.presetFrame.visible = true
		return
	end

	if presetFrame:IsVisible() then
		presetFrame:Hide()
		db.presetFrame.visible = false
	else
		presetFrame:Show()
		db.presetFrame.visible = true
	end
end

-- save current to preset
function mod.Preset_SaveCurrent(index)
	local t = {}
	for i = 1, #pq do
		t[i] = pq[i].alias
	end
	local rotation = table.concat(t, " ")
	db.presets[index].data = rotation
	
	mod.PresetFrame_Update()
end

--------------------------------------------------------------------------------
-- Cmd line arguments
--------------------------------------------------------------------------------
-- IMPORTANT: args is an indexed table
--------------------------------------------------------------------------------

-- pass a full rotation from command line
-- intended to be used in macros
local function CmdRetFCFS(args)
	-- add args to options
	local num = 0
	for i, arg in ipairs(args) do
		if spells[arg] then
			num = num + 1
			db.fcfs[num] = arg
		else
			-- inform on wrong arguments
			bprint(arg .. " not found")
		end
	end
	
	-- none on the rest
	if num < MAX_FCFS then
		for i = num + 1, MAX_FCFS do
			db.fcfs[i] = "none"
		end
	end
	
	-- redo queue
	mod.UpdateFCFS()
	
	-- update the options window
	clcInfo:UpdateOptions()
	
	--[[
	if InterfaceOptionsFrame:IsVisible() then
		InterfaceOptionsFrame_OpenToCategory("FCFS")
	end
	--]]
	
	if presetFrame then
		mod.PresetFrame_Update()
	end
end


-- load a preset from cmd line
-- intended to be used in macros
local function CmdRetLP(args)
	local name = table.concat(args, " ")
	if name == "" then return end
	
	for i = 1, MAX_PRESETS do
		if name == string.lower(db.presets[i].name) then return mod.Preset_Load(i) end
	end
end

-- register for slashcmd
clcInfo.cmdList["ret_fcfs"] = CmdRetFCFS
clcInfo.cmdList["ret_lp"] = CmdRetLP

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- emod. functions are usable by icon execs
-- S2 disables on update for that icon so that is called by first S1 update
--------------------------------------------------------------------------------
-- function to be executed when OnUpdate is called manually
local function S2Exec()
	if not enabled then return end
	return emod.IconSpell(dq[2], db.rangePerSkill or spells.cs.name)
end
-- cleanup function for when exec changes
local function ExecCleanup()
	s2 = nil
end
function emod.IconRetFCFS_S1()
	local gotskill = false
	if enabled then
		gotskill = mod.RetRotation()
	end
	
	if s2 then UpdateS2(s2, 100) end	-- update with a big "elapsed" so it's updated on call
	if gotskill then
		return emod.IconSpell(dq[1], db.rangePerSkill or spells.cs.name)
	end
end
function emod.IconRetFCFS_S2()
	-- remove this button's OnUpdate
	s2 = emod.cIcon
	s2.externalUpdate = true
	UpdateS2 = s2:GetScript("OnUpdate")
	s2:SetScript("OnUpdate", nil)
	s2.exec = S2Exec
	s2.ExecCleanup = ExecCleanup
end
--------------------------------------------------------------------------------