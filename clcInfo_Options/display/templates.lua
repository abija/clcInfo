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
	local i = tonumber(info[2])
	clcInfo.cdb.templates[i].spec[info[5]] = val
	options.args.templates.args[info[2]].args.tabSpec.args.spec.name = SpecToString(i)
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
							type = "group",
							inline = true,
							name = SpecToString(i),
							order = 1,
							args = {
								tree = {
									type = "range",
									name = "Tree",
									order = 1,
									min = 1,
									max = 3,
									step = 1,
									get = SpecGet,
									set = SpecSet,	
								},
								talent = {
									type = "range",
									name = "Talent",
									order = 2,
									min = 0,
									max = 50,
									step = 1,
									get = SpecGet,
									set = SpecSet,		
								},
								rank = {
									type = "range",
									name = "Rank",
									order = 3,
									min = 1,
									max = 5,
									step = 1,
									get = SpecGet,
									set = SpecSet,		
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
			executeAdd = {
				type = "execute",
				name = "Add template",
				func = clcInfo.display.templates.AddTemplate,
			},
		},
	}
	
	mod.lastTemplateCount = 0
	
	mod:UpdateTemplateList()
end