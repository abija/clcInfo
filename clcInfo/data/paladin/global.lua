-- build check
local _, _, _, toc = GetBuildInfo()
if toc >= 40000 then return end

local emod = clcInfo.env

--[[
	-- sov tracking
--]]
do
	local sovName, sovId, sovSpellTexture
	if UnitFactionGroup("player") == "Alliance" then
		sovId = 31803
		sovName, _, sovSpellTexture = GetSpellInfo(sovId)						-- holy vengeance
	else
		sovId = 53742
		sovName, _, sovSpellTexture = GetSpellInfo(sovId)						-- blood corruption
	end
	
	local function ExecCleanup()
		emod.___e.___sovList = nil
	end

	function emod.MBarSoV(a1, a2, showStack, timeRight)
		-- setup the table for sov data
		if not emod.___e.___sovList then
			emod.___e.___sovList = {}
			emod.___e.ExecCleanup = ExecCleanup
		end
		
		local tsov = emod.___e.___sovList
	
		-- check target for sov
		local targetGUID
		if UnitExists("target") then
			targetGUID = UnitGUID("target")
			local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitDebuff("target", sovName, nil, "PLAYER")
			if name then
			-- found it
				if count > 0 and showStack then 
					if showStack == "before" then
						name = string.format("(%s) %s", count, UnitName("target"))
					else
						name = string.format("%s (%s)", UnitName("target"), count)
					end
				else
					name = UnitName("target")
				end
				tsov[targetGUID] = { name, duration, expires }
			end
		end
		
		-- go through the saved data
		-- delete the ones that expired
		-- display the rest
		local gt = GetTime()
		local value, tr, alpha
		for k, v in pairs(tsov) do
			-- 3 = expires
			if gt > v[3] then
				tsov[k] = nil
			else
				value = v[3] - gt
				if timeRight then tr = tostring(math.floor(value + 0.5))
				else tr = ""
				end
				if k == targetGUID then alpha = a1
				else alpha = a2
				end
				
				emod.___e:___AddBar(nil, alpha, nil, nil, nil, nil, sovSpellTexture, 0, v[2], value, "normal", v[1], "", tr)
			end
		end
	end
end