-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "ROGUE" then return end

local emod = clcInfo.env

-- get combo points
-- returns 2 values:
-- value1: return of GetComboPoints("player") or leftover combo points
-- value2: 1 if value is leftover points, nil otherwise
-- needs at least recuperate
do
	local prevCP = 0
	local recup = GetSpellInfo(73651)
	function emod.GetCP()
		local cp = GetComboPoints("player")
		local isUsable, notEnoughMana = IsUsableSpell(recup)
		if cp > 0 or (isUsable == nil and notEnoughMana == nil) then
			prevCP = cp
			return cp
		end
		return prevCP, 1
	end
end

