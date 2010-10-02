local mod = clcInfo.env


function mod.AddMBar(id, alpha, r, g, b, a, visible, ...)
	if (alpha ~= nil and alpha == 0) or not visible then return end
	mod.___e:___AddBar(id, alpha, r, g, b, a, ...)
end
