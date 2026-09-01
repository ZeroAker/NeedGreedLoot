local addonName, NGL = ...

local scannerPanel = CreateFrame("Frame", nil, NGL.ui)
scannerPanel:SetPoint("TOPLEFT", 12, -64)
scannerPanel:SetPoint("BOTTOMRIGHT", -12, 12)
NGL.panels[1] = scannerPanel
NGL.scannerPanel = scannerPanel

NGL.CreateLabel(scannerPanel, NGL.L("scanner.title"), 12, -10, "GameFontHighlightLarge")
NGL.CreateLabel(scannerPanel, NGL.L("scanner.current_item"), 24, -42, "GameFontHighlight")

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

local currentItemName = NGL.CreateLabel(scannerPanel, NGL.L("scanner.no_item_selected"), 78, -70)
currentItemName:SetWidth(310)
currentItemName:SetWordWrap(false)

local currentItemUUID = NGL.CreateLabel(scannerPanel, "", 78, -92, "GameFontDisableSmall")
currentItemUUID:SetWidth(410)
currentItemUUID:SetWordWrap(false)

NGL.scannerDurationInput = NGL.CreateEditBox(scannerPanel, 70, 24, 540, -62, tostring(NGL_DefaultTimer))
local durationInput = NGL.scannerDurationInput
NGL.CreateLabel(scannerPanel, NGL.L("scanner.seconds"), 615, -68)

local scanDivider = scannerPanel:CreateTexture(nil, "ARTWORK")
scanDivider:SetColorTexture(0.5, 0.5, 0.5, 0.8)
scanDivider:SetPoint("TOPLEFT", 24, -122)
scanDivider:SetSize(820, 1)

NGL.CreateLabel(scannerPanel, NGL.L("scanner.bag_items"), 24, -142, "GameFontHighlight")

local scanScroll = CreateFrame("ScrollFrame", nil, scannerPanel, "UIPanelScrollFrameTemplate")
scanScroll:SetPoint("TOPLEFT", 24, -166)
scanScroll:SetSize(760, 310)

local scanList = CreateFrame("Frame", nil, scanScroll)
scanList:SetSize(720, 1)
scanScroll:SetScrollChild(scanList)

local scanSlots = {}
NGL.scannedItems = {}
NGL.selectedScanItem = nil

local function TooltipContains(text, patterns)
    if not text then return false end
    local lowerText = string.lower(text)
    for _, pattern in ipairs(patterns) do
        if string.find(lowerText, string.lower(pattern)) then
            return true
        end
    end
    return false
end

local function GetScannerDebugState(bag, slot, itemLink)
    local tooltipText = ""
    if C_TooltipInfo and C_TooltipInfo.GetBagItem then
        local tooltipData = C_TooltipInfo.GetBagItem(bag, slot)
        if tooltipData and tooltipData.lines then
            local textParts = {}
            for _, line in ipairs(tooltipData.lines) do
                if line.leftText then
                    table.insert(textParts, line.leftText)
                end
            end
            tooltipText = table.concat(textParts, " | ")
        end
    end

    local bindsWhenEquipped = TooltipContains(tooltipText, {
        "binds when equipped",
        "裝備後綁定",
        "装备后绑定"
    })

    local soulboundTradeWindow = TooltipContains(tooltipText, {
        "soulbound",
        "靈魂綁定",
        "灵魂绑定"
    }) and TooltipContains(tooltipText, {
        "you may trade this item",
        "trade",
        "交易此物品",
        "交易",
    })

    return {
        itemLink = itemLink,
        bag = bag,
        slot = slot,
        tooltipText = tooltipText,
        bindsWhenEquipped = bindsWhenEquipped,
        soulboundTradeWindow = soulboundTradeWindow,
        result = bindsWhenEquipped or soulboundTradeWindow,
    }
end

local function IsAllowedEquipSlot(equipLoc)
    if not equipLoc or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP" then
        return false
    end

    local allowed = {
        INVTYPE_HEAD = true,
        INVTYPE_NECK = true,
        INVTYPE_SHOULDER = true,
        INVTYPE_CLOAK = true,
        INVTYPE_CHEST = true,
        INVTYPE_WRIST = true,
        INVTYPE_HAND = true,
        INVTYPE_WAIST = true,
        INVTYPE_LEGS = true,
        INVTYPE_FEET = true,
        INVTYPE_FINGER = true,
        INVTYPE_TRINKET = true,
        INVTYPE_WEAPON = true,
        INVTYPE_SHIELD = true,
        INVTYPE_2HWEAPON = true,
        INVTYPE_WEAPONMAINHAND = true,
        INVTYPE_WEAPONOFFHAND = true,
        INVTYPE_HOLDABLE = true,
        INVTYPE_RANGED = true,
        INVTYPE_RANGEDRIGHT = true,
        INVTYPE_THROWN = true,
    }

    return allowed[equipLoc] == true
end

local function IsTierTokenLike(itemName, itemType, itemSubType, classID, subClassID)
    local text = string.lower((itemName or "") .. " " .. (itemType or "") .. " " .. (itemSubType or ""))
    local isTokenText = string.find(text, "token") or string.find(text, "omni") or string.find(text, "tier")
    if classID == Enum.ItemClass.Miscellaneous and (subClassID == 20 or isTokenText) then
        return true
    end
    return isTokenText == true
end

local function GetTooltipBindingStatus(bag, slot)
    local tooltipText = ""
    if C_TooltipInfo and C_TooltipInfo.GetBagItem then
        local tooltipData = C_TooltipInfo.GetBagItem(bag, slot)
        if tooltipData and tooltipData.lines then
            local textParts = {}
            for _, line in ipairs(tooltipData.lines) do
                if line.leftText then
                    table.insert(textParts, line.leftText)
                end
            end
            tooltipText = table.concat(textParts, "\n")
        end
    end

    local bindsWhenEquipped = TooltipContains(tooltipText, {
        "binds when equipped",
        "裝備後綁定",
        "装备后绑定"
    })

    local soulboundTradeWindow = TooltipContains(tooltipText, {
        "soulbound",
        "靈魂綁定",
        "灵魂绑定"
    }) and TooltipContains(tooltipText, {
        "you may trade this item",
        "trade",
        "交易此物品",
        "交易",
    })

    return tooltipText, bindsWhenEquipped, soulboundTradeWindow
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

    local isEquipSlotItem = IsAllowedEquipSlot(equipLoc)
    local isTierToken = IsTierTokenLike(itemName, itemType, itemSubType, classID, subClassID)
    if not (isEquipSlotItem or isTierToken) then
        return nil
    end

    local tooltipText, bindsWhenEquipped, soulboundTradeWindow = GetTooltipBindingStatus(bag, slot)

    if NGL_DebugMode then
        return itemLink
    end

    if bindsWhenEquipped or soulboundTradeWindow then
        return itemLink
    end

    return nil
end

function NGL.RefreshScanner()
    for _, slotButton in ipairs(scanSlots) do slotButton:Hide() end
    NGL.scannedItems = {}
    NGL.selectedScanItem = nil
    GameTooltip:Hide()
    currentItemIcon:SetTexture(134400)
    currentItemName:SetText(NGL.L("scanner.no_item_selected"))
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

                    local debugState = GetScannerDebugState(bag, slot, itemLink)
                    if NGL.DebugPrint then
                        NGL.DebugPrint(string.format(
                            "Clicked scan item: %s | bag=%d slot=%d | bindsWhenEquipped=%s | soulboundTradeWindow=%s | tooltip=%s",
                            tostring(debugState.itemLink),
                            debugState.bag,
                            debugState.slot,
                            tostring(debugState.bindsWhenEquipped),
                            tostring(debugState.soulboundTradeWindow),
                            tostring(debugState.tooltipText)
                        ))
                    end

                    currentItemIcon:SetTexture(itemInfo and itemInfo.iconFileID or 134400)
                    currentItemName:SetText(itemLink)
                    currentItemUUID:SetText(NGL.L("scanner.selected_slot", { bag = bag, slot = slot }))
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

NGL.CreateButton(scannerPanel, NGL.L("scanner.scan_bag"), 90, 24, -112, NGL.RefreshScanner)
NGL.CreateButton(scannerPanel, NGL.L("scanner.need_priority"), 90, 175, -112, function()
    if NGL.selectedScanItem then StartNGLRoll(NGL.selectedScanItem.itemLink, durationInput:GetText(), "ALL") end
end)
NGL.CreateButton(scannerPanel, NGL.L("scanner.need_roll"), 90, 270, -112, function()
    if NGL.selectedScanItem then StartNGLRoll(NGL.selectedScanItem.itemLink, durationInput:GetText(), "NEED") end
end)
NGL.CreateButton(scannerPanel, NGL.L("scanner.greed_roll"), 90, 365, -112, function()
    if NGL.selectedScanItem then StartNGLRoll(NGL.selectedScanItem.itemLink, durationInput:GetText(), "GREED") end
end)
NGL.CreateButton(scannerPanel, NGL.L("scanner.end_early"), 90, 460, -112, function()
    SlashCmdList["NGL"]("stop")
end)
NGL.CreateButton(scannerPanel, NGL.L("scanner.abort"), 90, 555, -112, function()
    SlashCmdList["NGL"]("abort")
end)

scannerPanel:SetScript("OnShow", function()
    if NGL.scannerDurationInput then
        NGL.scannerDurationInput:SetText(tostring(NGL_DefaultTimer))
    end
    NGL.RefreshScanner()
end)