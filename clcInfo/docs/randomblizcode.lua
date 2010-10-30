if ( isUsable ) then
	icon:SetVertexColor(1.0, 1.0, 1.0);
	normalTexture:SetVertexColor(1.0, 1.0, 1.0);
elseif ( notEnoughMana ) then
	icon:SetVertexColor(0.5, 0.5, 1.0);
	normalTexture:SetVertexColor(0.5, 0.5, 1.0);
else
	icon:SetVertexColor(0.4, 0.4, 0.4);
	normalTexture:SetVertexColor(1.0, 1.0, 1.0);
end



-- read main hand weapon speed from tooltip
-- used to determine haste
-- @warning: is 10 a decent value ?
-- @warning: should I clear strings between calls ?
do
	local tooltip = CreateFrame("GameTooltip")
	tooltip:Hide()
	local tooltipL, tooltipR = {}, {}
	for i = 1, 10 do
		local left, right = tooltip:CreateFontString(), tooltip:CreateFontString()
		tooltip:AddFontStrings(left, right)
		tooltipL[i], tooltipR[i] = left, right
	end
	mod.GetMainHandSpeed = function()
		tooltip:SetOwner(clcInfo.mf)
		tooltip:SetInventoryItem("player", 16)
		local count = 0
		local tr
		for i = 1, 10 do
			tr = tooltipR[i]:GetText()
			if tr then
				count = count + 1
				if count == 2 then
					return tonumber(strmatch(tr, "%a+ (%d+.%d%d)"))
				end
			end
		end
	end
end