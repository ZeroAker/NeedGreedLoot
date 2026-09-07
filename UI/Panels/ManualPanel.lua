local addonName, NGL = ...

local manualPanel = CreateFrame("Frame", nil, NGL.ui)
manualPanel:SetPoint("TOPLEFT", 12, -64)
manualPanel:SetPoint("BOTTOMRIGHT", -12, 12)
NGL.panels[5] = manualPanel

local titleLabel = NGL.CreateLabel(manualPanel, NGL.L("manual.title"), 12, -10, "GameFontHighlightLarge")
local subtitleLabel = NGL.CreateLabel(manualPanel, NGL.L("manual.subtitle"), 24, -38, "GameFontNormalSmall")

local itemInput = NGL.CreateEditBox(manualPanel, 520, 24, 24, -84)
local itemLabel = NGL.CreateLabel(manualPanel, NGL.L("manual.item_link"), 24, -74)

local playerInput = NGL.CreateEditBox(manualPanel, 220, 24, 24, -138)
local playerLabel = NGL.CreateLabel(manualPanel, NGL.L("manual.player_name"), 24, -128)

local rollInput = NGL.CreateEditBox(manualPanel, 100, 24, 260, -138)
local rollLabel = NGL.CreateLabel(manualPanel, NGL.L("manual.roll_points"), 260, -128)

local typeInput = NGL.CreateEditBox(manualPanel, 120, 24, 380, -138, "Need")
local typeLabel = NGL.CreateLabel(manualPanel, NGL.L("manual.type_need_greed"), 380, -128)

local winnerInput = NGL.CreateEditBox(manualPanel, 220, 24, 24, -192)
local winnerLabel = NGL.CreateLabel(manualPanel, NGL.L("manual.winner_optional"), 24, -182)

local function LoadSelectedIntoManual()
    local loot = NGL.selectedUUID and NGL.GetCurrentProfileData().LootList[NGL.selectedUUID]
    if loot then
        itemInput:SetText(loot.itemLink or "")
        winnerInput:SetText(loot.winnerName or "")
        if loot.rolls and loot.rolls[1] then
            playerInput:SetText(loot.rolls[1].playerName or "")
            rollInput:SetText(tostring(loot.rolls[1].roll or ""))
            typeInput:SetText(loot.rolls[1].rollType or "Need")
        end
    end
end

local loadButton = NGL.CreateButton(manualPanel, NGL.L("manual.load_selected"), 110, 260, -240, LoadSelectedIntoManual)

local saveButton = NGL.CreateButton(manualPanel, NGL.L("manual.save_record"), 120, 380, -240, function()
    local profile = NGL.GetCurrentProfileData()
    local loot = NGL.selectedUUID and profile.LootList[NGL.selectedUUID]
    if not loot then
        local itemLink = itemInput:GetText()
        if itemLink == "" then return end
        local itemID = tonumber(string.match(itemLink, "|Hitem:(%d+)"))
        local uuid = string.format("%d-%s-%04x", time(), itemID or "unknown", math.random(0, 65535))
        loot = { itemLink = itemLink, itemID = itemID, icon = itemID and select(5, GetItemInfoInstant(itemID)), uuid = uuid, rolls = {} }
        profile.LootList[uuid] = loot
        NGL.selectedUUID = uuid
    end
    local player = playerInput:GetText()
    local roll = tonumber(rollInput:GetText())
    local rollType = string.lower(typeInput:GetText()) == "greed" and "Greed" or "Need"
    if player ~= "" and roll then
        local updated = false
        for _, savedRoll in ipairs(loot.rolls) do
            if savedRoll.playerName == player then
                savedRoll.roll = roll
                savedRoll.rollType = rollType
                savedRoll.timestamp = time()
                updated = true
                break
            end
        end
        if not updated then
            table.insert(loot.rolls, { playerName = player, serverName = GetRealmName(), roll = roll, rollType = rollType, timestamp = time() })
        end
    end
    local winner = winnerInput:GetText()
    loot.winnerName = winner ~= "" and winner or nil
    loot.winnerRoll = nil
    for _, savedRoll in ipairs(loot.rolls) do
        if savedRoll.playerName == loot.winnerName then
            loot.winnerRoll = savedRoll.roll
            loot.consumableType = savedRoll.rollType
            break
        end
    end
    if not loot.winnerName then loot.consumableType = nil end
    NGL.RebuildPlayerRecords(profile)
    if NGL.RefreshLootList then NGL.RefreshLootList() end
    if NGL.SetSelectedLoot then NGL.SetSelectedLoot(NGL.selectedUUID) end
    print("|cff00ff00[NGL]|r Manual entry saved.")
end)

function NGL.RefreshManualLocale()
    titleLabel:SetText(NGL.L("manual.title"))
    subtitleLabel:SetText(NGL.L("manual.subtitle"))
    itemLabel:SetText(NGL.L("manual.item_link"))
    playerLabel:SetText(NGL.L("manual.player_name"))
    rollLabel:SetText(NGL.L("manual.roll_points"))
    typeLabel:SetText(NGL.L("manual.type_need_greed"))
    winnerLabel:SetText(NGL.L("manual.winner_optional"))
    loadButton:SetText(NGL.L("manual.load_selected"))
    saveButton:SetText(NGL.L("manual.save_record"))
end