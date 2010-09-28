local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo_Options\\templates> " .. table.concat(t, " "))
end

-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options

local currentTree

-- TODO!
-- use temp spec entry and a save button isntead of updating every change
-- TODO
-- less functions inline defined

local function SpecToString(i)
	local spec = clcInfo.cdb.templates[i].spec
	
	local treeName = GetTalentTabInfo(spec.tree)
	if not treeName then return "Undefined" end
	local talentName = GetTalentInfo(spec.tree, spec.talent)
	if not talentName then return "Undefined" end

	return treeName .. " > " .. talentName .. ": " .. spec.rank
end

local selectedForDelete = 0
StaticPopupDialogs["CLCINFO_CONFIRM_DELETE_TEMPLATE"] = {
	text = "Are you sure you want to delete this template?",
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		local db = clcInfo.cdb.templates
		if db[selectedForDelete] then 				
			table.remove(db, selectedForDelete)
			clcInfo:OnTemplatesUpdate()
			mod:UpdateTemplateList()
		end
	end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

local function SpecGet(info)
	return clcInfo.cdb.templates[tonumber(info[2])].spec[info[5]]
end

local function SpecSet(info, val)
	--local db = clcInfo.cdb.templates
	clcInfo.cdb.templates[tonumber(info[2])].spec[info[5]] = val
	clcInfo:OnTemplatesUpdate()
end

local function GetTalentTrees()
	local list = {}
	local name
	for i = 1, 3 do  
		name = GetTalentTabInfo(i)
		table.insert(list, name)
	end
	return list
end
local function GetTreeTalents(tree)
	local list = {}
	local n = GetNumTalents(tree)
	local name
	for i = 1, n do
		name = GetTalentInfo(tree, i)
		table.insert(list, name)
	end
	return list
end

local specTrees = GetTalentTrees()
local specTalents = { GetTreeTalents(1), GetTreeTalents(2), GetTreeTalents(3) }
local function GetTalentList(info)
	return specTalents[clcInfo.cdb.templates[tonumber(info[2])].spec.tree]
end

local function GetForceTemplateList()
	local list = { [0] = "Disabled" }
	for i = 1, #(clcInfo.cdb.templates) do
		list[i] = "Template" .. i
	end
	return list
end
local function GetForceTemplate(info)
	return clcInfo.cdb.options.enforceTemplate
end
local function SetForceTemplate(info, val)
	clcInfo.cdb.options.enforceTemplate = val
	clcInfo:OnTemplatesUpdate()
end

function mod:UpdateTemplateList()
	local db = clcInfo.cdb.templates
	local optionsTemplates = options.args.templates
	for i = 1, #(db) do
		optionsTemplates.args[tostring(i)] = {
			type = "group",
			name = "Template " .. i,
			childGroups = "tab",
			args = {
				tabSpec = {
					type="group",
					name = "Spec",
					order = 1,
					args = {
						spec = {
							order = 1, type = "group", inline = true, name = "",							
							args = {
								tree = {
									order = 1, type = "select", name = "Tree", values = specTrees,
									get = SpecGet, set = SpecSet,	
								},
								talent = {
									order = 2, type = "select", name = "Talent", values = GetTalentList,
									get = SpecGet, set = SpecSet,		
								},
								rank = {
									order = 3, type = "range", min = 1, max = 5, step = 1, name = "Rank",
									get = SpecGet, set = SpecSet,		
								},
							},
						},
					},
				},
				tabDelete = {
					type = "group",
					name = "Delete",
					order = 2,
					args = {
							execDelete = {
							type = "execute",
							name = "Delete",
							order = 100,
							func = function(info)						
								selectedForDelete = i,
								StaticPopup_Show("CLCINFO_CONFIRM_DELETE_TEMPLATE")
							end
						},
					},
				},
			},
		}
	end
	
	if mod.lastTemplateCount > #(db) then
		-- nil the rest of the args
		for i = #(db) + 1, mod.lastTemplateCount do
			optionsTemplates.args[tostring(i)] = nil
		end
	end
	mod.lastTemplateCount = #(db)
	AceRegistry:NotifyChange("clcInfo")
end

-- global template options
-- 		+ add template
-- 		+	delete template
function mod:LoadTemplates()
	options.args.templates = {
		order = 100, type = "group", name = "Templates", args = {
			-- add template button
			add = {
				order = 1, type = "execute", name = "Add template",
				func = clcInfo.display.templates.AddTemplate,
			},
			_space1 = {
				order = 2, type = "description", name = ""
			},
			forceTemplate = {
				order = 3, type = "select", name = "Force template regardless of spec:", values = GetForceTemplateList,
				get = GetForceTemplate, set = SetForceTemplate,
				
			},
		},
	}
	
	mod.lastTemplateCount = 0
	
	mod:UpdateTemplateList()
end