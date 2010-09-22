local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\display\templates> " .. table.concat(t, " "))
end

local mod = clcInfo.display.templates

local function IsActiveTemplate(spec)
	local name, _, _, _, rank = GetTalentInfo(spec.tree, spec.talent)
	if name and (rank == spec.rank) then return true end
	return false
end

-- look if activeTalents are found in any of the saved templates
function mod:FindTemplate()
	local db = clcInfo.cdb.templates
	clcInfo.activeTemplate = nil
	clcInfo.activeTemplateIndex = 0
	for k, data in ipairs(db) do
		if IsActiveTemplate(data.spec) then
			-- found, reference the table in a var
			clcInfo.activeTemplate = clcInfo.cdb.templates[k]
			clcInfo.activeTemplateIndex = k
			return true
		end
	end
	return false
end

-- add a template
function mod:AddTemplate()
	table.insert(clcInfo.cdb.templates, {
		spec = { tree = 1, talent = 0, rank = 1 },
		grids = {},
		icons = {},
		bars = {},
		options = {
			gridSize = 1,
			showWhen = "always",
		},
		iconOptions = {
			skinType = "Default",
			bfSkin = "Blizzard",
			bfGloss = 0,
		},
	})
	if clcInfo_Options then
		clcInfo_Options:UpdateTemplateList()
	end
end

function mod:LockElements()
	clcInfo.display.grids:LockAll()
	clcInfo.display.icons:LockAll()
	clcInfo.display.bars:LockAll()
end

function mod:UnlockElements()
	clcInfo.display.grids:UnlockAll()
	clcInfo.display.icons:UnlockAll()
	clcInfo.display.bars:UnlockAll()
end

function mod:UpdateElementsLayout()
	clcInfo.display.grids:UpdateAll()
	clcInfo.display.icons:UpdateLayoutAll()
	clcInfo.display.bars:UpdateLayoutAll()
end

if clcInfo.lbf then
	-- register callback
	clcInfo.lbf:RegisterSkinCallback("clcInfo", mod.UpdateElementsLayout, mod)
end