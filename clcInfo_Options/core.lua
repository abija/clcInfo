local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo_Options\\core> " .. table.concat(t, " "))
end

clcInfo_Options = {}
local mod = clcInfo_Options
local AceDialog, AceRegistry, AceGUI, SML, registered, options

AceDialog = AceDialog or LibStub("AceConfigDialog-3.0")
AceRegistry = AceRegistry or LibStub("AceConfigRegistry-3.0")

options = {
	type = "group",
	name = "clcInfo",
	args = {}
}

-- expose
mod.AceDialog = AceDialog
mod.AceRegistry = AceRegistry
mod.options = options

-- list of class modules
mod.cmLoaders = {}

-- useful tables for options
mod.anchorPoints = { CENTER = "CENTER", TOP = "TOP", BOTTOM = "BOTTOM", LEFT = "LEFT", RIGHT = "RIGHT", TOPLEFT = "TOPLEFT", TOPRIGHT = "TOPRIGHT", BOTTOMLEFT = "BOTTOMLEFT", BOTTOMRIGHT = "BOTTOMRIGHT" }

local function Init()
	mod:LoadTemplates()
	mod:LoadActiveTemplate()
	mod:LoadClassModules()
end

function mod:LoadClassModules()
	-- delete old table
	options.args.classModules = { order = 50, type = "group", name = "Class Modules", args = {} }
	
	for i = 1, #(mod.cmLoaders) do
		mod.cmLoaders[i]()
	end
end

function mod:Open()
	if( not registered ) then
		Init()
		
		LibStub("AceConfig-3.0"):RegisterOptionsTable("clcInfo", options)
		AceDialog:SetDefaultSize("clcInfo", 810, 600)
		registered = true
	end
	
	AceDialog:Open("clcInfo")
end


