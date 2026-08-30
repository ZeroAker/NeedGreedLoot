local addonName, NGL = ...

local profilePanel = CreateFrame("Frame", nil, NGL.ui)
profilePanel:SetPoint("TOPLEFT", 12, -64)
profilePanel:SetPoint("BOTTOMRIGHT", -12, 12)
NGL.panels[3] = profilePanel

StaticPopupDialogs["NGL_CONFIRM_DELETE_PROFILE"] = {
    text = "確定要刪除 Profile [%s] 嗎？此操作無法復原。",
    button1 = "刪除",
    button2 = "取消",
    OnAccept = function(_, name)
        if name ~= "default" and NGL_Profiles[name] then
            NGL_Profiles[name] = nil
            NGL_Profiles["default"] = NGL_Profiles["default"] or { UsedNeedList = {}, HistoryList = {}, GreedCountList = {}, LootList = {} }
            NGL.SwitchProfile("default")
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

StaticPopupDialogs["NGL_CONFIRM_RESET_PROFILE"] = {
    text = "確定要重置目前 Profile 嗎？所有玩家與 Loot Log 都會被清除。",
    button1 = "重置",
    button2 = "取消",
    OnAccept = function()
        local profile = NGL.GetCurrentProfileData()
        profile.UsedNeedList = {}
        profile.HistoryList = {}
        profile.GreedCountList = {}
        profile.LootList = {}
        NGL.ClearLootDetails()
        NGL.RefreshLootList()
        NGL.RefreshProfiles()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

NGL.CreateLabel(profilePanel, "Profile Manager", 12, -10, "GameFontHighlightLarge")
NGL.profileName = NGL.CreateEditBox(profilePanel, 220, 24, 24, -52, NGL_CurrentProfile)
NGL.CreateLabel(profilePanel, "Profile 名稱", 24, -42)

local profileRows = {}
local profileScroll = CreateFrame("ScrollFrame", nil, profilePanel, "UIPanelScrollFrameTemplate")
profileScroll:SetPoint("TOPLEFT", 24, -110)
profileScroll:SetSize(320, 390)

local profileListContent = CreateFrame("Frame", nil, profileScroll)
profileListContent:SetSize(300, 1)
profileScroll:SetScrollChild(profileListContent)

local needStatusScroll = CreateFrame("ScrollFrame", nil, profilePanel, "UIPanelScrollFrameTemplate")
needStatusScroll:SetPoint("TOPLEFT", 390, -130)
needStatusScroll:SetSize(440, 370)

local needStatusContent = CreateFrame("Frame", nil, needStatusScroll)
needStatusContent:SetSize(420, 1)
needStatusScroll:SetScrollChild(needStatusContent)
local needStatusRows = {}

local function NormalizePlayerName(name)
    return string.match(name or "", "^([^-]+)") or name
end

local function RefreshNeedStatus()
    NGL.ClearRows(needStatusRows)
    local profile = NGL.GetCurrentProfileData()
    local teamPlayers = {}
    local teamColors = {}
    local players = {}
    for index = 1, GetNumGroupMembers() do
        local unit = "raid" .. index
        local name = UnitName(unit)
        if name then
            local cleanName = NormalizePlayerName(name)
            teamPlayers[cleanName] = true
            players[cleanName] = true
            local _, classToken = UnitClass(unit)
            local classColor = classToken and RAID_CLASS_COLORS[classToken]
            if classColor then
                teamColors[cleanName] = { r = classColor.r, g = classColor.g, b = classColor.b }
            end
        end
    end
    for name in pairs(profile.UsedNeedList) do players[NormalizePlayerName(name)] = true end
    for name in pairs(profile.HistoryList) do players[NormalizePlayerName(name)] = true end
    for name in pairs(profile.GreedCountList) do players[NormalizePlayerName(name)] = true end

    local sortedPlayers = {}
    for name in pairs(players) do table.insert(sortedPlayers, name) end
    table.sort(sortedPlayers, function(left, right)
        local leftUsed = profile.UsedNeedList[left] == true
        local rightUsed = profile.UsedNeedList[right] == true
        if leftUsed ~= rightUsed then return not leftUsed end
        if teamPlayers[left] ~= teamPlayers[right] then return teamPlayers[left] end
        return left < right
    end)

    local y = 0
    local index = 0
    for _, name in ipairs(sortedPlayers) do
        index = index + 1
        local row = needStatusRows[index]
        if not row then
            row = CreateFrame("Frame", nil, needStatusContent)
            row:SetSize(410, 22)
            row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            row.name:SetPoint("LEFT", 0, 0)
            row.name:SetWidth(180)
            row.name:SetJustifyH("LEFT")
            row.status = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            row.status:SetPoint("LEFT", 190, 0)
            row.status:SetWidth(190)
            row.status:SetJustifyH("LEFT")
            needStatusRows[index] = row
        end
        local isUsed = profile.UsedNeedList[name] == true
        local classColor = teamColors[name]
        row:SetPoint("TOPLEFT", 0, y)
        row.name:SetText(name)
        if classColor then
            row.name:SetTextColor(classColor.r, classColor.g, classColor.b)
        else
            row.name:SetTextColor(0.5, 0.5, 0.5)
        end
        row.status:SetText(isUsed and "已需求" or "未需求")
        if isUsed then
            row.status:SetTextColor(1, 0.2, 0.2)
        else
            row.status:SetTextColor(0.2, 1, 0.2)
        end
        row:Show()
        y = y - 22
    end
    needStatusContent:SetHeight(math.max(1, index * 22))
end

function NGL.SwitchProfile(name)
    if not NGL_Profiles[name] then return end
    NGL_CurrentProfile = name
    if NGL.ClearLootDetails then NGL.ClearLootDetails() end
    NGL.profileName:SetText(name)
    NGL.RefreshProfiles()
    if NGL.RefreshLootList then NGL.RefreshLootList() end
end

function NGL.RefreshProfiles()
    NGL.ClearRows(profileRows)
    local index = 0
    for name in pairs(NGL_Profiles) do
        index = index + 1
        local row = profileRows[index]
        if not row then
            row = CreateFrame("Button", nil, profileListContent, "UIPanelButtonTemplate")
            row:SetSize(260, 24)
            profileRows[index] = row
        end
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 28)
        row:SetText(name == NGL_CurrentProfile and (name .. " (使用中)") or name)
        row:SetScript("OnClick", function() NGL.SwitchProfile(name) end)
        row:Show()
    end
    profileListContent:SetHeight(math.max(1, index * 28))
    RefreshNeedStatus()
end

NGL.CreateButton(profilePanel, "建立", 70, 270, -52, function()
    local name = NGL.profileName:GetText()
    if name ~= "" and not NGL_Profiles[name] then
        NGL_Profiles[name] = { UsedNeedList = {}, HistoryList = {}, GreedCountList = {}, LootList = {} }
        NGL.SwitchProfile(name)
    end
end)

NGL.CreateButton(profilePanel, "複製目前", 90, 345, -52, function()
    local name = NGL.profileName:GetText()
    local source = NGL.GetCurrentProfileData()
    if name ~= "" and not NGL_Profiles[name] then
        local copy = {}
        for key, value in pairs(source) do copy[key] = value end
        NGL_Profiles[name] = copy
        NGL.SwitchProfile(name)
    end
end)

NGL.CreateButton(profilePanel, "重置", 70, 440, -52, function()
    StaticPopup_Show("NGL_CONFIRM_RESET_PROFILE")
end)

NGL.CreateButton(profilePanel, "刪除", 70, 515, -52, function()
    local name = NGL.profileName:GetText()
    if name ~= "" and name ~= "default" and NGL_Profiles[name] then
        StaticPopup_Show("NGL_CONFIRM_DELETE_PROFILE", name, nil, name)
    end
end)

NGL.CreateLabel(profilePanel, "已建立的 Profile", 24, -92)
NGL.CreateLabel(profilePanel, "需求使用狀態", 390, -92, "GameFontHighlight")
NGL.CreateLabel(profilePanel, "團隊成員優先；灰階名稱表示目前不在團隊", 390, -108, "GameFontNormalSmall")