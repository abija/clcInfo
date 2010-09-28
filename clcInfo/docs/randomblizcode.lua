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