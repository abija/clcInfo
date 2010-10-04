local mod = clcInfo.env

-- IMPORTANT
-- really careful at the params
function mod.AddMIcon(id, visible, ...)
	if visible then
		mod.___e:___AddIcon(id, ...)
	else
		if id then mod.___e:___HideIcon(id) end
	end
end
