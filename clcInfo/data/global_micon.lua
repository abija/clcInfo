local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\data\\global_micon> " .. table.concat(t, " "))
end

local mod = clcInfo.env

-- IMPORTANT
-- really careful at the params
function mod.AddMIcon(id, visible, ...)
	if not visible then return end
	mod.___e:___AddIcon(id, ...)
end
