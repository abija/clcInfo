local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\display\templates> " .. table.concat(t, " "))
end

local mod = clcInfo.templates

local function IsActiveTemplate(spec)
	local name, _, _, _, rank = GetTalentInfo(spec.tree, spec.talent)
	if name and (rank == spec.rank) then return true end
	return false
end

-- look if activeTalents are found in any of the saved templates
function mod:FindTemplate()
	local db = clcInfo.cdb.templates
	local ef = clcInfo.cdb.options.enforceTemplate
	
	-- check if a template isn't forced
	if ef then
		if not db[ef] then
			-- forced but doesn't exist, tough luck
			ef = 0
		else
			clcInfo.activeTemplateIndex = ef
			clcInfo.activeTemplate = db[ef]
			return
		end
	end
	
	clcInfo.activeTemplate = nil
	clcInfo.activeTemplateIndex = 0
	for k, data in ipairs(db) do
		if IsActiveTemplate(data.spec) then
			-- found, reference the table in a var
			clcInfo.activeTemplate = db[k]
			clcInfo.activeTemplateIndex = k
			return true
		end
	end
	return false
end

-- add a template
function mod:GetDefault()
	local v = {
		classModules = {},
		spec = { tree = 1, talent = 0, rank = 1 },
		options = {
			gridSize = 1,
			showWhen = "always",
		},
		skinOptions = {
    	icons = clcInfo.display.icons.GetDefaultSkin(),
    	bars = clcInfo.display.bars.GetDefaultSkin(),
    	mbars = clcInfo.display.mbars.GetDefaultSkin()
    },
	}
	
	-- add display modules
	for k in pairs(clcInfo.display) do
		v[k] = {}
	end
	
	return v
end
function mod:AddTemplate()
	table.insert(clcInfo.cdb.templates, mod:GetDefault())
	clcInfo:OnTemplatesUpdate()
	if clcInfo_Options then
		clcInfo_Options:UpdateTemplateList()
	end
end

function mod:LockElements()
	for k in pairs(clcInfo.display) do
		if clcInfo.display[k].LockElements then
			clcInfo.display[k]:LockElements()
		end
	end
end

function mod:UnlockElements()
	for k in pairs(clcInfo.display) do
		if clcInfo.display[k].UnlockElements then
			clcInfo.display[k]:UnlockElements()
		end
	end
end

function mod:UpdateElementsLayout()
	for k in pairs(clcInfo.display) do
		if clcInfo.display[k].UpdateElementsLayout then
			clcInfo.display[k]:UpdateElementsLayout()
		end
	end
end

-- TODO, optimize the callback handling ?
if clcInfo.lbf then
	-- register callback
	clcInfo.lbf:RegisterSkinCallback("clcInfo", mod.UpdateElementsLayout, mod)
end

if clcInfo.LSM then
	-- register callback
	clcInfo.LSM.RegisterCallback( mod, "LibSharedMedia_Registered", "UpdateElementsLayout" )
	clcInfo.LSM.RegisterCallback( mod, "LibSharedMedia_SetGlobal", "UpdateElementsLayout" )
end