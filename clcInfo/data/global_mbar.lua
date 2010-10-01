local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\data\\global_mbar> " .. table.concat(t, " "))
end

local mod = clcInfo.env


function mod.AddMBar(id, alpha, r, g, b, a, visible, ...)
	if (alpha ~= nil and alpha == 0) or not visible then return end
	mod.___e:___AddBar(id, alpha, r, g, b, a, ...)
end
