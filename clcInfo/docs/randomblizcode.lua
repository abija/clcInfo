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









IGNITE:
-- icon:
local name, _, icon, _, _, duration, expires = UnitDebuff("target", "Ignite", nil, "PLAYER")
if name then
	local start = expires - duration
	local count
	local ctime = GetTime()
	local guid = UnitGUID("target")
	if ___e.___storage[guid] then
		local info = ___e.___storage[guid]
		if (ctime - info.ctime) < 3 then
			count = info.value
		end
	end
	return true, icon, start, duration, 1, false, count
end

-- event:
local pguid = UnitGUID("player")
local function cleu(storage, event, timestamp, combatEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed)
	if sourceGUID == pguid and spellName == "Ignite" then
		if combatEvent == "SPELL_PERIODIC_DAMAGE" then
			if not storage[destGUID] then storage[destGUID] = {} end
			local info = storage[destGUID]
			info.ctime = GetTime()
			info.value = floor((amount or 0 + overkill or 0 + resisted or 0 + absorbed or 0) / 100 + 0.5) / 10
		elseif combatEvent == "SPELL_AURA_REMOVED" then
			local info = storage[destGUID]
			if not info then return end
			info.ctime = GetTime()
			info.value = nil
		end
	end
end
AddEventListener(cleu, "COMBAT_LOG_EVENT_UNFILTERED")