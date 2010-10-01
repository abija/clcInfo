local function bprint(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage("clcInfo\\data\\global_mbar> " .. table.concat(t, " "))
end

local mod = clcInfo.env

--[[
function mod.AddMBar(alpha, r, g, b, a, visible, ...)
	if (alpha ~= nil and alpha == 0) or not visible then return end
	
	local e = mod.___e
	e.___dc = e.___dc + 1
	if not e.___dt[e.___dc] then
		e.___dt[e.___dc] = {}
	end
	
	e.___dt[e.___dc][1], e.___dt[e.___dc][2], e.___dt[e.___dc][3], e.___dt[e.___dc][4], e.___dt[e.___dc][5] = alpha, r, g, b, a
	
	for i = 6, (5 + select("#", ...)) do
		e.___dt[e.___dc][i] = select(i - 5, ...)
	end
	
	for i = (6 + select("#", ...)), 13 do
		e.___dt[e.___dc][i] = nil
	end
end
--]]

-- garbage but less cpu apparently
function mod.AddMBar(id, alpha, r, g, b, a, visible, ...)
	if (alpha ~= nil and alpha == 0) or not visible then return end
	mod.___e:___AddBar(id, alpha, r, g, b, a, ...)
end
