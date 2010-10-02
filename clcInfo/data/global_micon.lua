local mod = clcInfo.env

-- IMPORTANT
-- really careful at the params
function mod.AddMIcon(id, visible, ...)
	if not visible then return end
	mod.___e:___AddIcon(id, ...)
end
