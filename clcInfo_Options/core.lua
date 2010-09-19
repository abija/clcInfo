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
clcInfo.config = mod
mod.AceDialog = AceDialog
mod.AceRegistry = AceRegistry
mod.options = options

local function Init()
	mod:LoadTemplates()
	mod:LoadActiveTemplate()
end

function mod:Open()
	if( not registered ) then
		Init()
		
		LibStub("AceConfig-3.0"):RegisterOptionsTable("clcInfo", options)
		AceDialog:SetDefaultSize("clcInfo", 835, 525)
		registered = true
	end
	
	AceDialog:Open("clcInfo")
end


