-- CONFIG
local barcolor = {.8,.8,.8}
local fontsize = 14
local font = [[Fonts\FRIZQT__.ttf]]
local statusbar = [[Interface\AddOns\ncNameplates\flat]]
local solid = [[Interface\AddOns\ncNameplates\solid]]
local flags = ""

-- DON'T EDIT BELOW THIS LINE
local numkids, lastupdate, select = 0, 0, select
local f = CreateFrame("Frame")
local backdrop = {
	edgeFile = nil, edgeSize = 3,
	insets = {left = 3, right = 3, top = 3, bottom = 3}
}

local function GetClass(r, g, b)
	local r, g, b = floor(r*100+.5)/100, floor(g*100+.5)/100, floor(b*100+.5)/100
	for class, color in pairs(RAID_CLASS_COLORS) do
		if RAID_CLASS_COLORS[class].r == r and RAID_CLASS_COLORS[class].g == g and RAID_CLASS_COLORS[class].b == b then
			return class
		end
	end
	return 0
end

local function ClassIconTexCoord(r, g, b)
	class = GetClass(r,g,b)
	if not (class==0) then
		local texcoord = CLASS_BUTTONS[class]
		if (texcoord) then
			return unpack(texcoord)
		end
	end
	return 0.5, 0.75, 0.5, 0.75
end

local isvalidframe = function(frame)
	if frame:GetName() then
		return
	end
	overlayRegion = select(2, frame:GetRegions())
	return overlayRegion and overlayRegion:GetObjectType() == "Texture" and overlayRegion:GetTexture() == "Interface\\Tooltips\\Nameplate-Border"
end

local function updatetime(self, curValue)
	local minValue, maxValue = self:GetMinMaxValues()
	if self.channeling then
		self.time:SetFormattedText("%.1f ", curValue)
	else
		self.time:SetFormattedText("%.1f ", maxValue - curValue)
	end
end

local ThreatUpdate = function(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed >= 0.2 then
		if not self.oldglow:IsShown() then
			self.healthBar.hpGlow:SetBackdropBorderColor(0, 0, 0)
		else
			self.healthBar.hpGlow:SetBackdropBorderColor(self.oldglow:GetVertexColor())
		end
		self.healthBar:SetStatusBarColor(self.r, self.g, self.b)
		self.elapsed = 0
	end
end
local UpdateFrame = function(self)	
	SetCVar("ShowClassColorInNameplate", 1)
	local r, g, b = self.healthBar:GetStatusBarColor()
	
	newr, newg, newb = unpack(barcolor)
	self.icon:SetTexCoord(ClassIconTexCoord(r, g, b))
	
	self.healthBar:SetStatusBarColor(unpack(barcolor))
	
	self.r, self.g, self.b = newr, newg, newb	
	
	self.healthBar:ClearAllPoints()
	self.healthBar:SetPoint("CENTER", self.healthBar:GetParent())
	self.healthBar:SetHeight(10)
	self.healthBar:SetWidth(100)

	self.castBar:ClearAllPoints()
	self.castBar:SetPoint("TOP", self.healthBar, "BOTTOM", 0, -4)
	self.castBar:SetHeight(10)
	self.castBar:SetWidth(100)

	self.highlight:ClearAllPoints()
	self.highlight:SetAllPoints(self.healthBar)
	self.overlay:SetAllPoints(self.healthBar)

	self.name:SetText(self.oldname:GetText())
	self.name:SetTextColor(r, g, b)

	local level, elite, mylevel = tonumber(self.level:GetText()), self.elite:IsShown(), UnitLevel("player")
	self.level:ClearAllPoints()
	self.level:SetPoint("RIGHT", self.healthBar, "LEFT", -2, 1)
	if self.boss:IsShown() then
		self.level:SetText("B")
		self.level:SetTextColor(0.8, 0.05, 0)
		self.level:Show()
	else
		self.level:SetText(level..(elite and "+" or ""))
	end
end

local FixCastbar = function(self)
	self.castbarOverlay:Hide()
	self:SetHeight(5)
	self:ClearAllPoints()
	self:SetPoint("TOP", self.healthBar, "BOTTOM", 0, -4)
end

local ColorCastBar = function(self, shielded)
	if shielded then
		self:SetStatusBarColor(0.8, 0.05, 0)
		self.cbGlow:SetBackdropBorderColor(0.75, 0.75, 0.75)
	else
		self.cbGlow:SetBackdropBorderColor(0, 0, 0)
	end
end

local OnSizeChanged = function(self)
	self.needFix = true
end

local OnValueChanged = function(self, curValue)
	updatetime(self, curValue)
	if self.needFix then
		FixCastbar(self)
		self.needFix = nil
	end
end

local OnShow = function(self)
	self.channeling  = UnitChannelInfo("target") 
	FixCastbar(self)
	ColorCastBar(self, self.shieldedRegion:IsShown())
end

local OnHide = function(self)
	self.highlight:Hide()
	self.healthBar.hpGlow:SetBackdropBorderColor(0, 0, 0)
end

local OnEvent = function(self, event, unit)
	if unit == "target" then
		if self:IsShown() then
			ColorCastBar(self, event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
		end
	end
end

local CreateFrame = function(frame)
	if frame.done then
		return
	end
	frame.nameplate = true
	frame.healthBar, frame.castBar = frame:GetChildren()
	local r, g, b = frame.healthBar:GetStatusBarColor()
	local healthBar, castBar = frame.healthBar, frame.castBar
	local glowRegion, overlayRegion, castbarOverlay, shieldedRegion, spellIconRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()
	
	frame.overlay = overlayRegion
	
	frame.oldname = nameTextRegion
	nameTextRegion:Hide()
	
	local newNameRegion = frame:CreateFontString()
	newNameRegion:SetPoint("BOTTOM", healthBar, "TOP", 0, 3)
	newNameRegion:SetFont(font, fontsize, flags)
	frame.name = newNameRegion
	
	frame.border = CreateFrame("Frame", nil, frame.healthBar)
	frame.border:SetAllPoints(healthBar)
	frame.border:SetBackdrop( { 
		bgFile = nil, 
		edgeFile = solid, 
		tile = false, tileSize = 0, edgeSize = 1, 
		insets = { left = -1, right = -1, top = -1, bottom = -1 }
	})
	frame.border:SetBackdropBorderColor(unpack(barcolor))

	local classicontexture = frame:CreateTexture(nil, "OVERLAY")
	classicontexture:SetPoint("BOTTOM", healthBar, "TOP", 0, 10)
	classicontexture:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
	classicontexture:SetWidth(40)
	classicontexture:SetHeight(40)
	frame.icon = classicontexture
	
	frame.level = levelTextRegion
	levelTextRegion:SetFont(font, fontsize, flags)	
	frame.level:SetShadowOffset(0,0)
	
	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_REGEN_ENABLED")
	f:SetScript("OnEvent", function()
		frame:SetHeight(10)
		frame:SetWidth(100)
	end)
 
	if not InCombatLockdown() then
		frame:SetHeight(10)
		frame:SetWidth(100)
	end
	
	healthBar:SetStatusBarTexture(statusbar)

	healthBar.hpBackground = healthBar:CreateTexture(nil, "BORDER")
	healthBar.hpBackground:SetAllPoints(healthBar)
	healthBar.hpBackground:SetTexture(statusbar)
	healthBar.hpBackground:SetVertexColor(0.15, 0.15, 0.15)

	healthBar.hpGlow = CreateFrame("Frame", nil, healthBar)
	healthBar.hpGlow:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -4.5, 4)
	healthBar.hpGlow:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 4.5, -4.5)
	healthBar.hpGlow:SetBackdrop(backdrop)
	healthBar.hpGlow:SetBackdropColor(0, 0, 0)
	healthBar.hpGlow:SetBackdropBorderColor(0, 0, 0)

	castBar.castbarOverlay = castbarOverlay
	castBar.healthBar = healthBar
	castBar.shieldedRegion = shieldedRegion
	castBar:SetStatusBarTexture(statusbar)

	castBar:HookScript("OnShow", OnShow)
	castBar:HookScript("OnSizeChanged", OnSizeChanged)
	castBar:HookScript("OnValueChanged", OnValueChanged)
	castBar:HookScript("OnEvent", OnEvent)
	castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
	castBar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

	castBar.time = castBar:CreateFontString(nil, "ARTWORK")
	castBar.time:SetPoint("RIGHT", castBar, "LEFT", -2, 1)
	castBar.time:SetFont(font, fontsize, flags)
	castBar.time:SetTextColor(0.84, 0.75, 0.65)
	castBar.time:SetShadowOffset(1.25, -1.25)

	castBar.cbBackground = castBar:CreateTexture(nil, "BORDER")
	castBar.cbBackground:SetAllPoints(castBar)
	castBar.cbBackground:SetTexture(statusbar)
	castBar.cbBackground:SetVertexColor(0.15, 0.15, 0.15)

	castBar.cbGlow = CreateFrame("Frame", nil, castBar)
	castBar.cbGlow:SetPoint("TOPLEFT", castBar, "TOPLEFT", -4.5, 4)
	castBar.cbGlow:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 4.5, -4.5)
	castBar.cbGlow:SetBackdrop(backdrop)
	castBar.cbGlow:SetBackdropColor(0, 0, 0)
	castBar.cbGlow:SetBackdropBorderColor(0, 0, 0)

	spellIconRegion:SetHeight(0.01)
	spellIconRegion:SetWidth(0.01)
	
	highlightRegion:SetTexture(statusbar)
	highlightRegion:SetVertexColor(0.25, 0.25, 0.25)
	frame.highlight = highlightRegion

	raidIconRegion:ClearAllPoints()
	raidIconRegion:SetPoint("LEFT", healthBar, "RIGHT", 2, 0)
	raidIconRegion:SetHeight(15)
	raidIconRegion:SetWidth(15)

	frame.oldglow = glowRegion
	frame.elite = stateIconRegion
	frame.boss = bossIconRegion

	frame.done = true

	glowRegion:SetTexture(nil)
	overlayRegion:SetTexture(nil)
	shieldedRegion:SetTexture(nil)
	castbarOverlay:SetTexture(nil)
	stateIconRegion:SetTexture(nil)
	bossIconRegion:SetTexture(nil)

	UpdateFrame(frame)
	frame:SetScript("OnShow", UpdateFrame)
	frame:SetScript("OnHide", OnHide)

	frame.elapsed = 0
	frame:SetScript("OnUpdate", ThreatUpdate)
end


local function OnUpdate(self, elapsed)
	lastupdate = lastupdate + elapsed
	if lastupdate > 0.1 then
		lastupdate = 0
		if WorldFrame:GetNumChildren() ~= numkids then
			numkids = WorldFrame:GetNumChildren()
			for i = 1, select("#", WorldFrame:GetChildren()) do
				frame = select(i, WorldFrame:GetChildren())
				if isvalidframe(frame) then
					CreateFrame(frame)
				end
			end
		end
	end
end

f:SetScript("OnUpdate", OnUpdate)
f:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)