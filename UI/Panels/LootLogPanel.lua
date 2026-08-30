local addonName, NGL = ...

local lootPanel = CreateFrame("Frame", nil, NGL.ui)
lootPanel:SetPoint("TOPLEFT", 12, -64)
lootPanel:SetPoint("BOTTOMRIGHT", -12, 12)
NGL.panels[2] = lootPanel
NGL.panels.loot = lootPanel

local lootRows = {}
local activeFilter = "ALL"
local selectedUUID = nil

StaticPopupDialogs["NGL_CONFIRM_DELETE_LOOT"] = {
    text = "確定要刪除這筆 Loot Log 嗎？此操作無法復原。",
    button1 = "刪除",
    button2 = "取消",
    OnAccept = function(_, uuid)
        NGL.DeleteLoot(uuid)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

NGL.CreateLabel(lootPanel, "Loot Log", 12, -10, "GameFontHighlightLarge")
lootPanel.search = NGL.CreateEditBox(lootPanel, 240, 24, 12, -42)
lootPanel.search:SetScript("OnTextChanged", function() NGL.RefreshLootList() end)
NGL.CreateLabel(lootPanel, "搜尋裝備或 UUID", 258, -48)
NGL.CreateButton(lootPanel, "全部", 55, 405, -42, function() activeFilter = "ALL"; NGL.RefreshLootList() end)
NGL.CreateButton(lootPanel, "未分配", 65, 465, -42, function() activeFilter = "OPEN"; NGL.RefreshLootList() end)
NGL.CreateButton(lootPanel, "已分配", 65, 535, -42, function() activeFilter = "WON"; NGL.RefreshLootList() end)

local listScroll = CreateFrame("ScrollFrame", nil, lootPanel, "UIPanelScrollFrameTemplate")
listScroll:SetPoint("TOPLEFT", 12, -78)
listScroll:SetPoint("BOTTOMLEFT", 12, 12)
listScroll:SetWidth(330)
lootPanel.content = CreateFrame("Frame", nil, listScroll)
lootPanel.content:SetSize(330, 1)
listScroll:SetScrollChild(lootPanel.content)

local detail = CreateFrame("Frame", nil, lootPanel)
detail:SetPoint("TOPLEFT", 365, -78)
detail:SetPoint("BOTTOMRIGHT", -8, 12)
NGL.panels.lootDetails = detail
detail.title = NGL.CreateLabel(detail, "選擇一件裝備查看明細", 16, -8, "GameFontHighlightLarge")
detail.uuid = NGL.CreateLabel(detail, "", 16, -38, "GameFontDisableSmall")
detail.status = NGL.CreateLabel(detail, "", 16, -60)
NGL.CreateLabel(detail, "玩家", 16, -84, "GameFontHighlight")
NGL.CreateLabel(detail, "伺服器", 140, -84, "GameFontHighlight")
NGL.CreateLabel(detail, "職業", 220, -84, "GameFontHighlight")
NGL.CreateLabel(detail, "類型", 340, -84, "GameFontHighlight")
NGL.CreateLabel(detail, "點數", 420, -84, "GameFontHighlight")

local rollScroll = CreateFrame("ScrollFrame", nil, detail, "UIPanelScrollFrameTemplate")
rollScroll:SetPoint("TOPLEFT", 0, -102)
rollScroll:SetPoint("BOTTOMRIGHT", -22, 33)
detail.rollContent = CreateFrame("Frame", nil, rollScroll)
detail.rollContent:SetSize(500, 1)
rollScroll:SetScrollChild(detail.rollContent)

local assignPlayer = nil

local assignPlayerMenu = CreateFrame("Frame", "NGLAssignPlayerMenu", detail, "UIDropDownMenuTemplate")
UIDropDownMenu_SetWidth(assignPlayerMenu, 150)
UIDropDownMenu_SetText(assignPlayerMenu, "選擇團隊玩家")
assignPlayerMenu:Hide()

local function GetRaidPlayerNames()
    local names = {}
    for index = 1, GetNumGroupMembers() do
        local name = UnitName("raid" .. index)
        if name then table.insert(names, name) end
    end
    table.sort(names)
    return names
end

UIDropDownMenu_Initialize(assignPlayerMenu, function(self)
    for _, name in ipairs(GetRaidPlayerNames()) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = name
        info.func = function()
            assignPlayer = name
            UIDropDownMenu_SetText(assignPlayerMenu, name)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info)
    end
end)

local assignGreedButton = NGL.CreateButton(detail, "分配貪婪", 100, 0, 0, function()
    NGL.ReassignSelectedLoot(selectedUUID, assignPlayer, "Greed")
end)
assignGreedButton:ClearAllPoints()
assignGreedButton:SetPoint("TOPRIGHT", detail, "TOPRIGHT", -110, -4)

local reassignButton = NGL.CreateButton(detail, "分配需求", 100, 0, 0, function()
    NGL.ReassignSelectedLoot(selectedUUID, assignPlayer, "Need")
end)
reassignButton:ClearAllPoints()
reassignButton:SetPoint("TOPRIGHT", detail, "TOPRIGHT", 0, -4)
assignPlayerMenu:ClearAllPoints()
assignPlayerMenu:SetPoint("TOPRIGHT", detail, "TOPRIGHT", -8, -38)
 
local rerollLabel = detail:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
rerollLabel:SetPoint("BOTTOMLEFT", detail, "BOTTOMLEFT", 0, 8)
rerollLabel:SetText("重擲: ")

local rerollAllButton = NGL.CreateButton(detail, "需求優先", 75, 0, 0, function()
    if selectedUUID then NGL.RerollLoot(selectedUUID, "ALL") end
end)
rerollAllButton:ClearAllPoints()
rerollAllButton:SetPoint("LEFT", rerollLabel, "RIGHT", 4, 0)

local rerollNeedButton = NGL.CreateButton(detail, "需求擲骰", 75, 0, 0, function()
    if selectedUUID then NGL.RerollLoot(selectedUUID, "NEED") end
end)
rerollNeedButton:ClearAllPoints()
rerollNeedButton:SetPoint("LEFT", rerollAllButton, "RIGHT", 4, 0)

local rerollGreedButton = NGL.CreateButton(detail, "貪婪擲骰", 75, 0, 0, function()
    if selectedUUID then NGL.RerollLoot(selectedUUID, "GREED") end
end)
rerollGreedButton:ClearAllPoints()
rerollGreedButton:SetPoint("LEFT", rerollNeedButton, "RIGHT", 4, 0)

function NGL.ClearLootDetails()
    selectedUUID = nil
    detail.title:SetText("選擇一件裝備查看明細")
    detail.uuid:SetText("")
    detail.status:SetText("")
    if detail.rows then NGL.ClearRows(detail.rows) end
    if detail.rollContent then detail.rollContent:SetHeight(1) end
    if assignPlayerMenu then assignPlayerMenu:Hide() end
    if assignGreedButton then assignGreedButton:Hide() end
    if reassignButton then reassignButton:Hide() end
    if rerollLabel then rerollLabel:Hide() end
    if rerollAllButton then rerollAllButton:Hide() end
    if rerollNeedButton then rerollNeedButton:Hide() end
    if rerollGreedButton then rerollGreedButton:Hide() end
end

function NGL.RebuildPlayerRecords(profile)
    profile.UsedNeedList = {}
    profile.HistoryList = {}
    profile.GreedCountList = {}

    for _, loot in pairs(profile.LootList) do
        if loot.winnerName then
            local winnerType = loot.consumableType or "Greed"
            local winnerRoll = loot.winnerRoll
            if not winnerRoll then
                for _, roll in ipairs(loot.rolls or {}) do
                    if roll.playerName == loot.winnerName then
                        winnerRoll = roll.roll
                        break
                    end
                end
            end

            profile.HistoryList[loot.winnerName] = profile.HistoryList[loot.winnerName] or {}
            table.insert(profile.HistoryList[loot.winnerName], {
                item = loot.itemLink,
                isNeed = winnerType == "Need",
                roll = winnerRoll or 0,
                uuid = loot.uuid
            })
            if winnerType == "Need" then
                profile.UsedNeedList[loot.winnerName] = true
            else
                profile.GreedCountList[loot.winnerName] = (profile.GreedCountList[loot.winnerName] or 0) + 1
            end
        end
    end
end

function NGL.SetSelectedLoot(uuid)
    selectedUUID = uuid
    local loot = NGL.GetCurrentProfileData().LootList[uuid]
    if not loot then return end

    detail.title:SetText(loot.itemLink or "")
    detail.uuid:SetText("UUID: " .. (loot.uuid or ""))
    detail.status:SetText(loot.winnerName and ("贏家: " .. loot.winnerName .. " (" .. (loot.consumableType or "") .. ")") or "狀態: 尚未指定勝者")
    if assignPlayerMenu then assignPlayerMenu:Show() end
    if assignGreedButton then assignGreedButton:Show() end
    if reassignButton then reassignButton:Show() end
    if rerollLabel then rerollLabel:Show() end
    if rerollAllButton then rerollAllButton:Show() end
    if rerollNeedButton then rerollNeedButton:Show() end
    if rerollGreedButton then rerollGreedButton:Show() end
    detail.rows = detail.rows or {}
    NGL.ClearRows(detail.rows)

    local sortedRolls = {}
    for _, roll in ipairs(loot.rolls or {}) do table.insert(sortedRolls, roll) end
    local typeOrder = { Need = 1, Greed = 2 }
    table.sort(sortedRolls, function(left, right)
        local leftOrder = typeOrder[left.rollType == "Need" and "Need" or "Greed"]
        local rightOrder = typeOrder[right.rollType == "Need" and "Need" or "Greed"]
        if leftOrder ~= rightOrder then return leftOrder < rightOrder end
        return (left.roll or 0) > (right.roll or 0)
    end)

    local y = -2
    for _, roll in ipairs(sortedRolls) do
        local row = detail.rows[#detail.rows + 1]
        if not row then
            row = CreateFrame("Frame", nil, detail.rollContent)
            row:SetSize(500, 20)
            row.player = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            row.player:SetPoint("LEFT", 16, 0)
            row.player:SetWidth(124)
            row.player:SetJustifyH("LEFT")
            row.server = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            row.server:SetPoint("LEFT", 140, 0)
            row.server:SetWidth(80)
            row.server:SetJustifyH("LEFT")
            row.class = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            row.class:SetPoint("LEFT", 220, 0)
            row.class:SetWidth(120)
            row.class:SetJustifyH("LEFT")
            row.type = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            row.type:SetPoint("LEFT", 340, 0)
            row.type:SetWidth(80)
            row.type:SetJustifyH("LEFT")
            row.roll = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            row.roll:SetPoint("LEFT", 420, 0)
            row.roll:SetWidth(80)
            row.roll:SetJustifyH("LEFT")
            detail.rows[#detail.rows + 1] = row
        end
        local color = roll.classColor or { r = 1, g = 1, b = 1 }
        row.player:SetText(roll.playerName or "?")
        row.player:SetTextColor(color.r, color.g, color.b)
        row.server:SetText(roll.serverName or "Unknown")
        row.class:SetText(roll.classToken or "Unknown")
        row.class:SetTextColor(color.r, color.g, color.b)
        row.type:SetText(roll.rollType == "Need" and "Need" or "Greed")
        row.roll:SetText(tostring(roll.roll or 0))
        row:SetPoint("TOPLEFT", 0, y)
        row:Show()
        y = y - 20
    end
    detail.rollContent:SetHeight(math.max(1, #sortedRolls * 20))
end

function NGL.DeleteLoot(uuid)
    if not uuid then return false end
    local profile = NGL.GetCurrentProfileData()
    if not profile.LootList[uuid] then return false end
    profile.LootList[uuid] = nil
    NGL.RebuildPlayerRecords(profile)
    if uuid == selectedUUID then NGL.ClearLootDetails() end
    NGL.RefreshLootList()
    return true
end

function NGL.RefreshLootList()
    local panel = NGL.panels.loot
    if not panel then return end
    NGL.ClearRows(lootRows)
    local query = string.lower(panel.search:GetText() or "")
    local index = 0
    local profile = NGL.GetCurrentProfileData()

    for uuid, loot in pairs(profile.LootList) do
        local searchable = string.lower((loot.itemLink or "") .. " " .. (loot.uuid or ""))
        local status = loot.winnerName and "WON" or "OPEN"
        local typeMatches = activeFilter == "ALL" or activeFilter == status
        if typeMatches and (query == "" or string.find(searchable, query, 1, true)) then
            index = index + 1
            local row = lootRows[index]
            if not row then
                row = CreateFrame("Button", nil, panel.content)
                row:SetSize(330, 40)
                row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                row.icon = row:CreateTexture(nil, "ARTWORK")
                row.icon:SetSize(28, 28)
                row.icon:SetPoint("TOPLEFT", 4, -4)
                row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                row.name:SetPoint("TOPLEFT", 40, -4)
                row.uuid = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
                row.uuid:SetPoint("TOPLEFT", 40, -20)
                row.deleteButton = CreateFrame("Button", nil, row)
                row.deleteButton:SetSize(16, 16)
                row.deleteButton:SetPoint("BOTTOMRIGHT", -4, 3)
                row.deleteButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                row.deleteButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
                row.deleteButton:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
                row.deleteButton:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("刪除 Loot Log")
                    GameTooltip:Show()
                end)
                row.deleteButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
                lootRows[index] = row
            end
            row:SetPoint("TOPLEFT", 0, -(index - 1) * 42)
            row.icon:SetTexture(loot.icon or 134400)
            row.name:SetText(loot.itemLink or "未知裝備")
            row.uuid:SetText((loot.uuid or "") .. (loot.winnerName and "  [已分配]" or "  [未分配]"))
            row:SetScript("OnClick", function() NGL.SetSelectedLoot(uuid) end)
            row.deleteButton:SetScript("OnClick", function() StaticPopup_Show("NGL_CONFIRM_DELETE_LOOT", nil, nil, uuid) end)
            row:Show()
        end
    end
    panel.content:SetHeight(math.max(1, index * 42))
end

function NGL.RerollLoot(uuid, mode)
    local loot = NGL.GetCurrentProfileData().LootList[uuid]
    if not loot then return end
    if IsNGLRollActive and IsNGLRollActive() then
        print("|cffff0000[NGL]|r 目前已有擲骰進行中，無法重新擲骰。")
        return
    end
    if not IsInRaid() or not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        print("|cffff0000[NGL]|r 只有團隊隊長或團隊助手可以重新擲骰。")
        return
    end
    local itemLink = loot.itemLink
    if NGL.DeleteLoot(uuid) then StartNGLRoll(itemLink, nil, mode) end
end

function NGL.ReassignSelectedLoot(targetUUID, targetPlayer, assignType)
    local profile = NGL.GetCurrentProfileData()
    local loot = targetUUID and profile.LootList[targetUUID]
    if not loot or not targetPlayer then return end
    if not IsInRaid() or not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        print("|cffff0000[NGL]|r 只有團隊隊長或團隊助手可以分配裝備。")
        return
    end

    local oldWinner = loot.winnerName
    local newType = "Need"
    if assignType and string.lower(assignType) == "greed" then
        newType = "Greed"
    elseif assignType and string.lower(assignType) == "need" then
        newType = "Need"
    elseif targetPlayer ~= oldWinner and profile.UsedNeedList[targetPlayer] then
        newType = "Greed"
    end

    if oldWinner and oldWinner ~= targetPlayer then
        for _, roll in ipairs(loot.rolls or {}) do
            if roll.playerName == oldWinner then
                roll.roll = -1
                break
            end
        end
    end

    local cleanName = string.match(targetPlayer, "([^-]+)") or targetPlayer
    local serverName, classToken, classColor = NGL.GetRollerInfo(cleanName, targetPlayer)

    local foundNewWinner = false
    for _, roll in ipairs(loot.rolls or {}) do
        if roll.playerName == cleanName or roll.playerName == targetPlayer then
            roll.roll = 999
            roll.rollType = newType
            roll.serverName = serverName
            roll.classToken = classToken
            roll.classColor = classColor
            foundNewWinner = true
            break
        end
    end

    if not foundNewWinner then
        table.insert(loot.rolls, {
            playerName = targetPlayer,
            serverName = serverName,
            classToken = classToken,
            classColor = classColor,
            roll = 999,
            rollType = newType,
            timestamp = time()
        })
    end

    loot.winnerName = targetPlayer
    loot.consumableType = newType
    loot.winnerRoll = 999
    NGL.RebuildPlayerRecords(profile)
    SendChatMessage("【" .. (newType == "Need" and "需求" or "貪婪") .. "】" .. targetPlayer .. " 被分配獲得 " .. (loot.itemLink or "裝備") .. " (" .. newType .. ")!", "RAID_WARNING")
    NGL.RefreshLootList()
    NGL.SetSelectedLoot(targetUUID)
end

NGL.ClearLootDetails()