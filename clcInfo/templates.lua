local mod = clcInfo.templates -- the module

-- check if spec matches current talent build
local function IsActiveTemplate(spec, showWhen)
	-- check primary tree
	if spec.primary ~= GetPrimaryTalentTree() then return false end
	
	-- check distinctive talent
	local name, _, _, _, rank = GetTalentInfo(spec.tree, spec.talent)
	if name and (rank == spec.rank) then
		-- talents fit, check for showwhen
		local sw = "solo"
		
		if GetNumPartyMembers() > 0 then sw = "party" end
		
		local nrm = GetNumRaidMembers()
		if nrm > 10 then sw = "raid25"
		elseif nrm > 5 then sw = "raid10"
		elseif nrm > 0 then sw = "raid5" end
		
		if not showWhen[sw] then return false end
	
		return true
	end
	return false
end

-- look if the build is found in any of the saved templates
-- points activeTemplate to it and change the activeTemplateIndex
function mod:FindTemplate()
	local db = clcInfo.cdb.templates
	local ef = clcInfo.cdb.options.enforceTemplate -- allow to force a template
	
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
	
	-- look through the templates
	clcInfo.activeTemplate = nil
	clcInfo.activeTemplateIndex = 0
	for k, data in ipairs(db) do
		if IsActiveTemplate(data.spec, data.showWhen) then
			-- found, reference the table in a var
			clcInfo.activeTemplate = db[k]
			clcInfo.activeTemplateIndex = k
			return true
		end
	end
	return false
end


-- default template options
function mod:GetDefault()
	local t = {
		classModules = {},
		spec = { primary = 1, tree = 1, talent = 0, rank = 1 },
		showWhen = { solo = true, party = true, raid5 = true, raid10 = true, raid25 = true },
		options = {
			udLabel = "", -- user defined label
			gridSize = 1,
			showWhen = "always",
			strata = "MEDIUM",
			alpha = 1,
		},
		skinOptions = {},
	}
	
	-- add skin options from the module defaults
	for k, v in pairs(clcInfo.display) do
		if v.hasSkinOptions then
			t.skinOptions[k] = clcInfo.display[k]:GetDefaultSkin()
		end
	end
	
	-- add display modules
	for k in pairs(clcInfo.display) do
		t[k] = {}
	end
	
	return t
end

-- add a template
function mod:AddTemplate()
	table.insert(clcInfo.cdb.templates, mod:GetDefault())
	clcInfo:OnTemplatesUpdate()
	if clcInfo_Options then
		clcInfo_Options:UpdateTemplateList()
	end
end

-- call lock/unlock/update all for all modules
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

-- handle callback for lbf and lsm
-- TODO, optimize?
if clcInfo.lbf then
	clcInfo.lbf:RegisterSkinCallback("clcInfo", mod.UpdateElementsLayout, mod)
end
if clcInfo.LSM then
	clcInfo.LSM.RegisterCallback( mod, "LibSharedMedia_Registered", "UpdateElementsLayout" )
	clcInfo.LSM.RegisterCallback( mod, "LibSharedMedia_SetGlobal", "UpdateElementsLayout" )
end