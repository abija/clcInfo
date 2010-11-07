-- don't load if class is wrong
local _, class = UnitClass("player")
if class ~= "WARLOCK" then return end

local version = 1

local defaults = {
	moveSB = false,
	hideBlizzSB = false,
	-- paladin power bar coords
	sbX = 0,
	sbY = 0,
	sbPoint = "CENTER",
  sbRelativePoint = "CENTER",
	sbScale = 1,
	sbAlpha = 1,
	
	version = version,
}

-- lower case module name
local modName = "_global"

-- create a module in the main addon
local mod = clcInfo:RegisterClassModule(modName)
local db -- it's per template based
local emod = clcInfo.env -- functions visible to exec should be attached to this

local mysb -- my runepower bar
mod.locked = true

-- this function, if it exists, will be called at init
function mod.OnInitialize()
	db = clcInfo:RegisterClassModuleTDB(modName, defaults)
	if db then
		if not db.version or db.version < version then
			-- fix stuff
			clcInfo.AdaptConfigAndClean("globalTDB", db, defaults)
			db.version = version
		end
		
		mod.UpdateSBar()
	else
		if mysb then mysb:Hide() end
	end
end
mod.OnTemplatesUpdate = mod.OnInitialize

function mod.UpdateSBar()
	if db.moveSB then
		if not mysb then mod.CreateSB() end
		mysb:EnableMouse(not mod.locked)
	
		mysb:Show()
		mysb:ClearAllPoints()
		mysb:SetScale(db.sbScale)
		mysb:SetAlpha(db.sbAlpha)
		mysb:SetPoint("CENTER", UIParent, "CENTER", db.sbX, db.sbY)
	else
		if mysb then mysb:Hide() end
	end
	
	if db.hideBlizzSB then
		ShardBarFrame:Hide()
		ShardBarFrame:UnregisterAllEvents()
		ShardBarFrame:SetScript("OnShow", function(self) self:Hide() end)
	else
		ShardBarFrame:SetScript("OnShow", nil)
		ShardBarFrame:Show()
		ShardBar_OnLoad(ShardBarFrame)
		ShardBar_OnEvent(ShardBarFrame, "PLAYER_ENTERING_WORLD")
	end
end

--------------------------------------------------------------------------------
-- create a rune bar similar to blizzard's xml code
--------------------------------------------------------------------------------
-- this is changed, their animation seemed buggy
local function SB_ToggleShards(self, visible)
	if visible then
		self.shardFill:Hide();
		self.shardGlow:Hide();
		self.shardSmoke1.animUsed:Play();
		self.shardSmoke2.animUsed:Play();
		else
		self.shardFill:Show();
		self.shardGlow:Show();
		self.shardSmoke1.animUsed:Play();
		self.shardSmoke2.animUsed:Play();
	end
end

local function SB_Update()
	local numShards = UnitPower( "player", SPELL_POWER_SOUL_SHARDS );
	for i = 1, SHARD_BAR_NUM_SHARDS do
		local shard = _G["clcInfoShardBarFrameShard"..i];
		local isShown = shard.shardFill:IsVisible() == 1;
		local shouldShow = i <= numShards;
		if isShown ~= shouldShow then 
			SB_ToggleShards(shard, isShown);
		end
	end
end
local function SB_OnEvent (self, event, arg1, arg2)
	if ( event == "UNIT_DISPLAYPOWER" ) then
		SB_Update();	
	elseif ( event=="PLAYER_ENTERING_WORLD" ) then
		SB_Update();	
	elseif ( (event == "UNIT_POWER") and (arg1 == "player") ) then
		if ( arg2 == "SOUL_SHARDS" ) then
			SB_Update();
		end
	elseif( event ==  "PLAYER_LEVEL_UP" ) then
		local level = arg1;
		if level >= SHARDBAR_SHOW_LEVEL then
			self:UnregisterEvent("PLAYER_LEVEL_UP");
			self.showAnim:Play();
			SB_Update();
		end
	end
end

-- rewrite on event function because it uses the buttons from the other frame
function mod.CreateSB()
	mysb = CreateFrame("Frame", "clcInfoShardBarFrame", clcInfo.mf)
	mysb:SetSize(115, 25)
	
	mysb.shard1 = CreateFrame("Frame", "clcInfoShardBarFrameShard1", mysb, "ShardTemplate")
	mysb.shard1:SetPoint("TOPLEFT")
	mysb.shard1.shardFill:Hide()
	mysb.shard2 = CreateFrame("Frame", "clcInfoShardBarFrameShard2", mysb, "ShardTemplate")
	mysb.shard2:SetPoint("TOPLEFT", "clcInfoShardBarFrameShard1", "TOPLEFT", 35, 0)
	mysb.shard2.shardFill:Hide()
	mysb.shard3 = CreateFrame("Frame", "clcInfoShardBarFrameShard3", mysb, "ShardTemplate")
	mysb.shard3:SetPoint("TOPLEFT", "clcInfoShardBarFrameShard2", "TOPLEFT", 35, 0)
	mysb.shard3.shardFill:Hide()
	mysb.showAnim = mysb:CreateAnimationGroup()
	local a = mysb.showAnim:CreateAnimation("Alpha")
	a:SetOrder(1) a:SetDuration(0.5) a:SetChange(1)
	a:SetScript("OnFinished", function(self) self:GetParent():SetAlpha(1.0) end)
	
	mysb:SetScript("OnEvent", SB_OnEvent)
	ShardBar_OnLoad(mysb)
	SB_OnEvent(mysb, "PLAYER_ENTERING_WORLD")
	
	mysb:Hide()
	
	-- register for drag
	mysb:SetMovable(true)
	mysb:RegisterForDrag("LeftButton")
	mysb:SetScript("OnDragStart", function(self)
      self:StartMoving()
  end)
	mysb:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		db.sbPoint, _, db.sbRelativePoint, db.sbX, db.sbY = self:GetPoint()
    -- update the data in options also
    clcInfo:UpdateOptions()
	end)
end
--------------------------------------------------------------------------------

-- get haste according to fear tooltip
-- spellId: 5782
--[[
do
	local strmatch = strmatch
	local tooltip = CreateFrame("GameTooltip")
	tooltip:Hide()
	local tooltipL, tooltipR = {}, {}
	-- 3 rows tooltip
	for i = 1, 3 do
		local left, right = tooltip:CreateFontString(), tooltip:CreateFontString()
		tooltip:AddFontStrings(left, right)
		tooltipL[i], tooltipR[i] = left, right
	end
	function emod.GetHaste()
		tooltip:SetOwner(clcInfo.mf)
		tooltip:SetSpellByID(5782)
		return 2 / tonumber(strmatch(tooltipL[3]:GetText(), "(%d+.%d+)")	or "2")
	end
end
--]]
