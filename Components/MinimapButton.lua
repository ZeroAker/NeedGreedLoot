local addonName, NGL = ...

NGL_MinimapAngle = NGL_MinimapAngle or 0

local minimapButton = CreateFrame("Button", "NGLMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFixedFrameStrata(true)
minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 10)

-- Icon Texture
minimapButton.icon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapButton.icon:SetSize(20, 20)
minimapButton.icon:SetPoint("CENTER", 0, 0)
minimapButton.icon:SetTexture("Interface\\Icons\\INV_Misc_Dice_02")

-- Circle Alpha Mask
minimapButton.mask = minimapButton:CreateMaskTexture()
minimapButton.mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
minimapButton.mask:SetAllPoints(minimapButton.icon)
minimapButton.icon:AddMaskTexture(minimapButton.mask)

-- Gold Border
minimapButton.border = minimapButton:CreateTexture(nil, "OVERLAY")
minimapButton.border:SetSize(53, 53)
minimapButton.border:SetPoint("CENTER", 11, -11)
minimapButton.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

-- Mouse Highlight Texture
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Mouse Click Effects
minimapButton:SetScript("OnMouseDown", function(self)
    self.icon:SetPoint("CENTER", 1, -1)
end)
minimapButton:SetScript("OnMouseUp", function(self)
    self.icon:SetPoint("CENTER", 0, 0)
end)

-- Position Update Logic
local function UpdateMinimapButtonPosition()
    local minimapRadius = (Minimap:GetWidth() / 2) + 2
    if minimapRadius <= 2 then minimapRadius = 102 end

    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(NGL_MinimapAngle) * minimapRadius, math.sin(NGL_MinimapAngle) * minimapRadius)
end

minimapButton:SetScript("OnClick", function()
    if NGL_ToggleUI then NGL_ToggleUI() end
end)

minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("NeedGreedLoot")
    GameTooltip:AddLine("Click to toggle Control Panel", 1, 1, 1)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetScript("OnDragStart", function(self)
    self.dragging = true
end)
minimapButton:SetScript("OnDragStop", function(self)
    self.dragging = nil
end)
minimapButton:SetScript("OnUpdate", function(self)
    if not self.dragging then return end
    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local centerX, centerY = Minimap:GetCenter()
    NGL_MinimapAngle = math.atan2(cursorY / scale - centerY, cursorX / scale - centerX)
    UpdateMinimapButtonPosition()
end)

UpdateMinimapButtonPosition()