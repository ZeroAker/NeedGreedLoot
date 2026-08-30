local addonName, NGL = ...

local scannerPanel = CreateFrame("Frame", nil, NGL.ui)
scannerPanel:SetPoint("TOPLEFT", 12, -64)
scannerPanel:SetPoint("BOTTOMRIGHT", -12, 12)
NGL.panels[1] = scannerPanel
NGL.scannerPanel = scannerPanel

NGL.CreateLabel(scannerPanel, "掃描與發起擲骰", 12, -10, "GameFontHighlightLarge")
NGL.CreateLabel(scannerPanel, "當前裝備", 24, -42, "GameFontHighlight")

local currentItemIcon = scannerPanel:CreateTexture(nil, "ARTWORK")
currentItemIcon:SetSize(42, 42)
currentItemIcon:SetPoint("TOPLEFT", 24, -58)
currentItemIcon:SetTexture(134400)

local currentItemButton = CreateFrame("Button", nil, scannerPanel)
currentItemButton:SetSize(42, 42)
currentItemButton:SetPoint("TOPLEFT", 24, -58)
currentItemButton:SetScript("OnEnter", function(self)
    if NGL.selectedScanItem then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetBagItem(NGL.selectedScanItem.bag, NGL.selectedScanItem.slot)
        GameTooltip:Show()
    end
end)
currentItemButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

local currentItemName = NGL.CreateLabel(scannerPanel, "尚未選擇裝備", 78, -70)
currentItemName:SetWidth(310)
currentItemName:SetWordWrap(false)

local currentItemUUID = NGL.CreateLabel(scannerPanel, "", 78, -92, "GameFontDisableSmall")
currentItemUUID:SetWidth(410)
currentItemUUID:SetWordWrap(false)

NGL.scannerDurationInput = NGL.CreateEditBox(scannerPanel, 70, 24, 540, -62, tostring(NGL_DefaultTimer))
local durationInput = NGL.scannerDurationInput
NGL.CreateLabel(scannerPanel, "秒", 615, -68)

local scanDivider = scannerPanel:CreateTexture(nil, "ARTWORK")
scanDivider:SetColorTexture(0.5, 0.5, 0.5, 0.8)
scanDivider:SetPoint("TOPLEFT", 24, -122)
scanDivider:SetSize(820, 1)

NGL.CreateLabel(scannerPanel, "背包裝備", 24, -142, "GameFontHighlight")

local scanScroll = CreateFrame("ScrollFrame", nil, scannerPanel, "UIPanelScrollFrameTemplate")
scanScroll:SetPoint("TOPLEFT", 24, -166)
scanScroll:SetSize(760, 310)

local scanList = CreateFrame("Frame", nil, scanScroll)
scanList:SetSize(720, 1)
scanScroll:SetScrollChild(scanList)

local scanSlots = {}
NGL.scannedItems = {}
NGL.selectedScanItem = nil

local function IsWarboundItem(bag, slot)
    if C_TooltipInfo and C_TooltipInfo.GetBagItem then
        local tooltipData = C_TooltipInfo.GetBagItem(bag, slot)
        if tooltipData and tooltipData.lines then
            for _, line in ipairs(tooltipData.lines) do
                if line.leftText then
                    if string.find(line.leftText, "Warbound") or
                       string.find(line.leftText, "戰隊") or 
                       string.find(line.leftText, "战网") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function IsScannableItem(bag, slot)
    local itemLink = C_Container.GetContainerItemLink(bag, slot)
    if not itemLink then return nil end

    local itemID = tonumber(string.match(itemLink, "|Hitem:(%d+)"))
    if not itemID then return nil end

    local itemName, _, _, _, _, itemType, itemSubType, _, equipLoc, _, _, classID, subClassID = C_Item.GetItemInfo(itemID)
    if not classID then
        _, _, _, equipLoc, _, classID, subClassID = GetItemInfoInstant(itemID)
    end

    -- 1. Check target item types: Weapon, Armor, Triket, Miscellaneous, Tier Tokens
    local isTargetItem = false
    if classID then
        if classID == Enum.ItemClass.Weapon or classID == Enum.ItemClass.Armor then
            isTargetItem = true
        -- Check for trinkets (subclass 19) and tier tokens (subclass 20)
        elseif classID == Enum.ItemClass.Miscellaneous or classID == Enum.ItemClass.Container or classID == Enum.ItemClass.ItemEnhancement then
            isTargetItem = true
        end
    elseif equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP" then
        isTargetItem = true
    end

    if not isTargetItem then return nil end

    -- 2. Debug mode: If enabled, return the item link for all items regardless of restrictions
    if NGL_DebugMode then
        return itemLink
    end

    -- 3. filter out Warbound items (if applicable)
    if IsWarboundItem and IsWarboundItem(bag, slot) then return nil end

    local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if location and location:IsValid() then
        if C_Item.IsItemWarbound and C_Item.IsItemWarbound(location) then
            return nil
        end

        -- 4. Check for tradable time limits (Tradable Window)
        -- Prioritize using the API for checking
        if C_Item.IsItemTradable and C_Item.IsItemTradable(location) then
            return itemLink
        end

        -- fallback to tooltip scanning if the API is not available
        if C_TooltipInfo and C_TooltipInfo.GetBagItem then
            local tooltipData = C_TooltipInfo.GetBagItem(bag, slot)
            if tooltipData then
                for _, line in ipairs(tooltipData.lines) do
                    if line.leftText then
                        -- Check for tradable time remaining or trade-related text in the tooltip
                        if string.find(line.leftText, BIND_TRADE_TIME_REMAINING or "You may trade this item") or 
                           string.find(line.leftText, "trade") or string.find(line.leftText, "交易") then
                            return itemLink
                        end
                    end
                end
            end
        end
    end

    return nil
end

function NGL.RefreshScanner()
    for _, slotButton in ipairs(scanSlots) do slotButton:Hide() end
    NGL.scannedItems = {}
    NGL.selectedScanItem = nil
    GameTooltip:Hide()
    currentItemIcon:SetTexture(134400)
    currentItemName:SetText("尚未選擇裝備")
    currentItemUUID:SetText("")
    for _, slotButton in ipairs(scanSlots) do
        slotButton:UnlockHighlight()
        if slotButton.selectedBorder then slotButton.selectedBorder:Hide() end
    end
    local index = 0
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLink = IsScannableItem(bag, slot)
            if itemLink then
                index = index + 1
                NGL.scannedItems[index] = { bag = bag, slot = slot, itemLink = itemLink }
                local slotButton = scanSlots[index]
                if not slotButton then
                    slotButton = CreateFrame("Button", nil, scanList)
                    slotButton:SetSize(58, 58)
                    slotButton.border = slotButton:CreateTexture(nil, "BORDER")
                    slotButton.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
                    slotButton.border:SetAllPoints()
                    slotButton.icon = slotButton:CreateTexture(nil, "ARTWORK")
                    slotButton.icon:SetAllPoints()
                    slotButton.highlight = slotButton:CreateTexture(nil, "HIGHLIGHT")
                    slotButton.highlight:SetTexture("Interface\\Buttons\\CheckButtonHilight")
                    slotButton.highlight:SetBlendMode("ADD")
                    slotButton.highlight:SetPoint("TOPLEFT", slotButton.icon, "TOPLEFT", -2, 2)
                    slotButton.highlight:SetPoint("BOTTOMRIGHT", slotButton.icon, "BOTTOMRIGHT", 2, -2)
                                    
                    slotButton.selectedBorder = slotButton:CreateTexture(nil, "OVERLAY")
                    slotButton.selectedBorder:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
                    slotButton.selectedBorder:SetBlendMode("ADD")
                    slotButton.selectedBorder:SetPoint("TOPLEFT", slotButton.icon, "TOPLEFT", -2, 2)
                    slotButton.selectedBorder:SetPoint("BOTTOMRIGHT", slotButton.icon, "BOTTOMRIGHT", 2, -2)
                    slotButton.selectedBorder:Hide()
                    slotButton.count = slotButton:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
                    slotButton.count:SetPoint("BOTTOMRIGHT", -3, 3)
                    scanSlots[index] = slotButton
                end
                local scanItem = NGL.scannedItems[index]
                local column = (index - 1) % 10
                local row = math.floor((index - 1) / 10)
                local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                slotButton:SetPoint("TOPLEFT", column * 64, -row * 64)
                slotButton.icon:SetTexture(itemInfo and itemInfo.iconFileID or 134400)
                slotButton.count:SetText(itemInfo and itemInfo.stackCount and itemInfo.stackCount > 1 and itemInfo.stackCount or "")
                slotButton:SetScript("OnClick", function()
                    NGL.selectedScanItem = scanItem
                    currentItemIcon:SetTexture(itemInfo and itemInfo.iconFileID or 134400)
                    currentItemName:SetText(itemLink)
                    currentItemUUID:SetText("已選取背包 " .. bag .. ", 格位 " .. slot)
                    for _, otherButton in ipairs(scanSlots) do
                        if otherButton.selectedBorder then otherButton.selectedBorder:Hide() end
                    end
                    slotButton.selectedBorder:Show()
                end)
                slotButton:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(slotButton, "ANCHOR_RIGHT")
                    GameTooltip:SetBagItem(scanItem.bag, scanItem.slot)
                    GameTooltip:Show()
                end)
                slotButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
                slotButton:Show()
            end
        end
    end
    scanList:SetHeight(math.max(1, math.ceil(index / 10) * 64))
end

NGL.CreateButton(scannerPanel, "掃描背包", 90, 24, -112, NGL.RefreshScanner)
NGL.CreateButton(scannerPanel, "需求優先", 90, 175, -112, function()
    if NGL.selectedScanItem then StartNGLRoll(NGL.selectedScanItem.itemLink, durationInput:GetText(), "ALL") end
end)
NGL.CreateButton(scannerPanel, "需求擲骰", 90, 270, -112, function()
    if NGL.selectedScanItem then StartNGLRoll(NGL.selectedScanItem.itemLink, durationInput:GetText(), "NEED") end
end)
NGL.CreateButton(scannerPanel, "貪婪擲骰", 90, 365, -112, function()
    if NGL.selectedScanItem then StartNGLRoll(NGL.selectedScanItem.itemLink, durationInput:GetText(), "GREED") end
end)
NGL.CreateButton(scannerPanel, "提前結束", 90, 460, -112, function()
    SlashCmdList["NGL"]("stop")
end)
NGL.CreateButton(scannerPanel, "終止", 90, 555, -112, function()
    SlashCmdList["NGL"]("abort")
end)

scannerPanel:SetScript("OnShow", function()
    if NGL.scannerDurationInput then
        NGL.scannerDurationInput:SetText(tostring(NGL_DefaultTimer))
    end
    NGL.RefreshScanner()
end)