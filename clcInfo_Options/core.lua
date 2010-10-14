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
mod.cmLoadersActiveTemplate = {}

-- useful tables for options
mod.anchorPoints = { CENTER = "CENTER", TOP = "TOP", BOTTOM = "BOTTOM", LEFT = "LEFT", RIGHT = "RIGHT", TOPLEFT = "TOPLEFT", TOPRIGHT = "TOPRIGHT", BOTTOMLEFT = "BOTTOMLEFT", BOTTOMRIGHT = "BOTTOMRIGHT" }

local function Init()
	mod:LoadTemplates()
	-- info: class modules are loaded together with active template because of the data that might be template stored
	mod:LoadActiveTemplate()
end

function mod:LoadClassModules()
	-- delete old table
	options.args.classModules = { order = 50, type = "group", name = "Class Modules", args = {} }
	for i = 1, #(mod.cmLoaders) do
		mod.cmLoaders[i]()
	end
	
	-- update all the class modules that save options in templates
	if clcInfo.activeTemplate then
  	for i = 1, #(mod.cmLoadersActiveTemplate) do
			mod.cmLoadersActiveTemplate[i]()
		end
	end
end

function mod:Open()
	if( not registered ) then
		Init()
		
		LibStub("AceConfig-3.0"):RegisterOptionsTable("clcInfo", options)
		AceDialog:SetDefaultSize("clcInfo", 830, 600)
		registered = true
	end
	
	AceDialog:Open("clcInfo")
end

--------------------------------------------------------------------------------
-- functions that are identical for elements
--------------------------------------------------------------------------------
-- grid list
function mod.GetGridList()
	local list = { [0] = "None" }
	local name
	for i = 1, #(clcInfo.display.grids.active) do
		name = clcInfo.display.grids.active[i].db.udLabel
		if name == "" then name = "Grid" .. i end
		list[i] = name
	end
	return list
end


