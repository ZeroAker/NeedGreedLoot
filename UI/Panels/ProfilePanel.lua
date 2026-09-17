local addonName, NGL = ...

local profilePanel = CreateFrame("Frame", nil, NGL.ui)
profilePanel:SetPoint("TOPLEFT", 12, -64)
profilePanel:SetPoint("BOTTOMRIGHT", -12, 12)
NGL.panels[3] = profilePanel

StaticPopupDialogs["NGL_CONFIRM_DELETE_PROFILE"] = {
    text = NGL.L("profile.delete_confirm"),
    button1 = NGL.L("profile.delete"),
    button2 = NGL.L("loot.cancel"),
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
    text = NGL.L("profile.reset_confirm"),
    button1 = NGL.L("profile.reset"),
    button2 = NGL.L("loot.cancel"),
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

local function TrimProfileName(name)
    return string.match(name or "", "^%s*(.-)%s*$") or ""
end

local function SerializeShareValue(value)
    local valueType = type(value)
    if valueType == "nil" then
        return "z"
    elseif valueType == "boolean" then
        return value and "b1" or "b0"
    elseif valueType == "number" then
        local text = tostring(value)
        return "n" .. #text .. ":" .. text
    elseif valueType == "string" then
        return "s" .. #value .. ":" .. value
    elseif valueType == "table" then
        local keys = {}
        for key in pairs(value) do table.insert(keys, key) end
        table.sort(keys, function(left, right) return tostring(left) < tostring(right) end)
        local result = "t" .. #keys .. "["
        for _, key in ipairs(keys) do
            result = result .. SerializeShareValue(key) .. SerializeShareValue(value[key])
        end
        return result .. "]"
    end
    return "z"
end

local function DeserializeShareValue(text, position)
    local valueType = string.sub(text, position, position)
    position = position + 1
    if valueType == "z" then return nil, position end
    if valueType == "b" then
        local value = string.sub(text, position, position) == "1"
        return value, position + 1
    end
    if valueType == "s" or valueType == "n" then
        local separator = string.find(text, ":", position, true)
        if not separator then return nil end
        local length = tonumber(string.sub(text, position, separator - 1))
        if not length then return nil end
        local value = string.sub(text, separator + 1, separator + length)
        if #value ~= length then return nil end
        if valueType == "n" then value = tonumber(value) end
        return value, separator + length + 1
    end
    if valueType == "t" then
        local openBracket = string.find(text, "[", position, true)
        if not openBracket then return nil end
        local count = tonumber(string.sub(text, position, openBracket - 1))
        if not count then return nil end
        local result = {}
        position = openBracket + 1
        for _ = 1, count do
            local key, nextPosition = DeserializeShareValue(text, position)
            if nextPosition == nil then return nil end
            local value
            value, position = DeserializeShareValue(text, nextPosition)
            if position == nil then return nil end
            result[key] = value
        end
        if string.sub(text, position, position) ~= "]" then return nil end
        return result, position + 1
    end
end

local shareBase64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function EncodeShareText(text)
    local encoded = {}
    local index = 1
    while index <= #text do
        local first = string.byte(text, index) or 0
        local second = string.byte(text, index + 1)
        local third = string.byte(text, index + 2)
        local value = first * 65536 + (second or 0) * 256 + (third or 0)
        local firstIndex = math.floor(value / 262144) % 64 + 1
        local secondIndex = math.floor(value / 4096) % 64 + 1
        local thirdIndex = math.floor(value / 64) % 64 + 1
        local fourthIndex = value % 64 + 1
        encoded[#encoded + 1] = string.sub(shareBase64Alphabet, firstIndex, firstIndex)
        encoded[#encoded + 1] = string.sub(shareBase64Alphabet, secondIndex, secondIndex)
        encoded[#encoded + 1] = second and string.sub(shareBase64Alphabet, thirdIndex, thirdIndex) or "="
        encoded[#encoded + 1] = third and string.sub(shareBase64Alphabet, fourthIndex, fourthIndex) or "="
        index = index + 3
    end
    return table.concat(encoded)
end

local function DecodeShareText(text)
    if #text == 0 or #text % 4 ~= 0 or not string.match(text, "^[A-Za-z0-9+/]*=*=?$") then return nil end
    local decoded = {}
    for index = 1, #text, 4 do
        local first = string.find(shareBase64Alphabet, string.sub(text, index, index), 1, true)
        local second = string.find(shareBase64Alphabet, string.sub(text, index + 1, index + 1), 1, true)
        local thirdChar = string.sub(text, index + 2, index + 2)
        local fourthChar = string.sub(text, index + 3, index + 3)
        local third = thirdChar == "=" and 1 or string.find(shareBase64Alphabet, thirdChar, 1, true)
        local fourth = fourthChar == "=" and 1 or string.find(shareBase64Alphabet, fourthChar, 1, true)
        if not first or not second or not third or not fourth then return nil end
        local value = (first - 1) * 262144 + (second - 1) * 4096 + (third - 1) * 64 + fourth - 1
        decoded[#decoded + 1] = string.char(math.floor(value / 65536) % 256)
        if thirdChar ~= "=" then decoded[#decoded + 1] = string.char(math.floor(value / 256) % 256) end
        if fourthChar ~= "=" then decoded[#decoded + 1] = string.char(value % 256) end
    end
    return table.concat(decoded)
end

local function CreateProfileShareLink()
    local characterName = UnitName("player") or "Player"
    local shareName = characterName .. "-" .. NGL_CurrentProfile
    local packet = SerializeShareValue({ name = shareName, profile = NGL.GetCurrentProfileData() })
    return shareName, "NGL2:" .. EncodeShareText(packet)
end

local function ParseProfileExport(text)
    text = string.gsub(text or "", "%s+", "")
    local encoded = string.match(text or "", "^NGL2:([A-Za-z0-9+/]+=*)$")
    if not encoded then return nil end
    local decoded = DecodeShareText(encoded)
    if not decoded then return nil end
    local packet, position = DeserializeShareValue(decoded, 1)
    if not packet or position ~= #decoded + 1 then return nil end
    if type(packet.name) ~= "string" or packet.name == "" or type(packet.profile) ~= "table" then return nil end
    if type(packet.profile.UsedNeedList) ~= "table"
        or type(packet.profile.HistoryList) ~= "table"
        or type(packet.profile.GreedCountList) ~= "table"
        or type(packet.profile.LootList) ~= "table" then
        return nil
    end
    return packet
end

local function ImportSharedProfile(packet)
    if type(packet) ~= "table" or type(packet.name) ~= "string" or type(packet.profile) ~= "table" then return end
    NGL_Profiles[packet.name] = packet.profile
    NGL.RefreshProfiles()
    print("|cff00ff00[NGL]|r " .. NGL.L("profile.imported", { name = packet.name }))
end

local function CreateTransferDialog(title, buttonText)
    local dialog = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    dialog:SetSize(640, 360)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    dialog:Hide()

    dialog.TitleText:SetText(title)
    dialog.scroll = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    dialog.scroll:SetPoint("TOPLEFT", 20, -52)
    dialog.scroll:SetPoint("BOTTOMRIGHT", -36, 58)

    dialog.editBox = CreateFrame("EditBox", nil, dialog.scroll)
    dialog.editBox:SetMultiLine(true)
    dialog.editBox:SetAutoFocus(false)
    dialog.editBox:SetFontObject("ChatFontNormal")
    dialog.editBox:SetTextInsets(6, 6, 6, 6)
    dialog.editBox:SetWidth(570)
    dialog.editBox:SetHeight(230)
    dialog.editBox:SetPoint("TOPLEFT")
    dialog.scroll:SetScrollChild(dialog.editBox)

    dialog.status = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    dialog.status:SetPoint("BOTTOMLEFT", 22, 46)
    dialog.status:SetWidth(360)
    dialog.status:SetJustifyH("LEFT")
    dialog.status:SetTextColor(1, 0.2, 0.2)

    dialog.action = NGL.CreateButton(dialog, buttonText, 100, 405, 12, function() end)
    dialog.select = NGL.CreateButton(dialog, NGL.L("profile.select_all"), 100, 295, 12, function()
        dialog.editBox:SetFocus()
        dialog.editBox:HighlightText()
    end)
    dialog.cancel = NGL.CreateButton(dialog, NGL.L("loot.cancel"), 100, 515, 12, function()
        dialog:Hide()
    end)
    dialog.select:ClearAllPoints()
    dialog.select:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 20, 14)
    dialog.action:ClearAllPoints()
    dialog.action:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 14)
    dialog.cancel:ClearAllPoints()
    dialog.cancel:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -20, 14)
    return dialog
end

local exportDialog = CreateTransferDialog(NGL.L("profile.export_title"), NGL.L("profile.select_all"))
exportDialog.action:Hide()
exportDialog.action:SetScript("OnClick", function()
    exportDialog.editBox:SetFocus()
    exportDialog.editBox:HighlightText()
end)

local function ShowExportDialog()
    local shareName, exportText = CreateProfileShareLink()
    exportDialog.TitleText:SetText(NGL.L("profile.export_title") .. ": " .. shareName)
    exportDialog.status:SetText(NGL.L("profile.export_hint"))
    exportDialog.editBox:SetText(exportText)
    exportDialog:Show()
    exportDialog.editBox:SetFocus()
    exportDialog.editBox:HighlightText()
end

local importDialog = CreateTransferDialog(NGL.L("profile.import_title"), NGL.L("profile.import"))
importDialog.action:SetScript("OnClick", function()
    local packet = ParseProfileExport(importDialog.editBox:GetText())
    if not packet then
        importDialog.status:SetText(NGL.L("profile.import_invalid"))
        return
    end
    importDialog:Hide()
    StaticPopup_Show("NGL_CONFIRM_IMPORT_PROFILE", nil, nil, packet)
end)
importDialog.select:Hide()

StaticPopupDialogs["NGL_CONFIRM_IMPORT_PROFILE"] = {
    text = NGL.L("profile.import_title"),
    button1 = NGL.L("profile.import"),
    button2 = NGL.L("loot.cancel"),
    OnShow = function(dialog, packet)
        local overwrite = NGL_Profiles[packet.name] ~= nil
        dialog:GetTextFontString():SetText(NGL.L(overwrite and "profile.import_overwrite_confirm" or "profile.import_confirm", { name = packet.name }))
        dialog:Resize()
    end,
    OnAccept = function(_, packet)
        ImportSharedProfile(packet)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

local function UpdateRenameWarning(dialog)
    local oldName = dialog.data
    local editBox = dialog:GetEditBox()
    local newName = TrimProfileName(editBox:GetText())
    local duplicate = newName ~= "" and newName ~= oldName and NGL_Profiles[newName] ~= nil
    dialog.renameWarning:SetShown(duplicate)
    dialog.renameWarning:SetText(duplicate and NGL.L("profile.rename_duplicate") or "")
    dialog:GetButton1():SetEnabled(newName ~= "" and not duplicate)
end

StaticPopupDialogs["NGL_RENAME_PROFILE"] = {
    text = NGL.L("profile.rename_title"),
    button1 = NGL.L("common.ok"),
    button2 = NGL.L("loot.cancel"),
    hasEditBox = true,
    maxLetters = 64,
    OnShow = function(dialog, oldName)
        local editBox = dialog:GetEditBox()
        dialog.data = oldName
        editBox:SetText(oldName or "")
        editBox:HighlightText()
        if not dialog.renameWarning then
            dialog.renameWarning = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            dialog.renameWarning:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -4)
            dialog.renameWarning:SetWidth(280)
            dialog.renameWarning:SetHeight(18)
            dialog.renameWarning:SetJustifyH("LEFT")
            dialog.renameWarning:SetTextColor(1, 0.2, 0.2)
        end
        editBox:SetScript("OnTextChanged", function()
            UpdateRenameWarning(dialog)
        end)
        editBox:SetScript("OnEnterPressed", function()
            if dialog:GetButton1():IsEnabled() then dialog:GetButton1():Click() end
        end)
        editBox:SetScript("OnEscapePressed", function()
            dialog:Hide()
        end)
        UpdateRenameWarning(dialog)
        C_Timer.After(0, function()
            if dialog:IsShown() and dialog.which == "NGL_RENAME_PROFILE" then
                dialog:SetHeight(dialog:GetHeight() + 18)
                local button1 = dialog:GetButton1()
                local button2 = dialog:GetButton2()
                button1:ClearAllPoints()
                button1:SetPoint("BOTTOM", dialog, "BOTTOM", -55, 22)
                button2:SetPoint("BOTTOM", dialog, "BOTTOM", 55, 22)
            end
        end)
    end,
    OnAccept = function(dialog, oldName)
        local newName = TrimProfileName(dialog:GetEditBox():GetText())
        if newName == "" or (newName ~= oldName and NGL_Profiles[newName]) then return end
        if newName ~= oldName then
            NGL_Profiles[newName] = NGL_Profiles[oldName]
            NGL_Profiles[oldName] = nil
            NGL_CurrentProfile = newName
            NGL.profileName:SetText(newName)
            NGL.RefreshProfiles()
        end
    end,
    OnHide = function(dialog)
        if dialog.renameWarning then
            dialog.renameWarning:Hide()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

local titleLabel = NGL.CreateLabel(profilePanel, NGL.L("profile.manager"), 12, -10, "GameFontHighlightLarge")
NGL.profileName = NGL.CreateEditBox(profilePanel, 220, 24, 24, -52, NGL_CurrentProfile)
local nameLabel = NGL.CreateLabel(profilePanel, NGL.L("profile.name"), 24, -42)

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
        row.status:SetText(isUsed and NGL.L("profile.used") or NGL.L("profile.unused"))
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
        row:SetText(name == NGL_CurrentProfile and (name .. " " .. NGL.L("profile.in_use")) or name)
        row:SetScript("OnClick", function() NGL.SwitchProfile(name) end)
        row:Show()
    end
    profileListContent:SetHeight(math.max(1, index * 28))
    RefreshNeedStatus()
end

local createButton = NGL.CreateButton(profilePanel, NGL.L("profile.create"), 70, 270, -52, function()
    local name = NGL.profileName:GetText()
    if name ~= "" and not NGL_Profiles[name] then
        NGL_Profiles[name] = { UsedNeedList = {}, HistoryList = {}, GreedCountList = {}, LootList = {} }
        NGL.SwitchProfile(name)
    end
end)

local copyButton = NGL.CreateButton(profilePanel, NGL.L("profile.copy_current"), 90, 345, -52, function()
    local name = NGL.profileName:GetText()
    local source = NGL.GetCurrentProfileData()
    if name ~= "" and not NGL_Profiles[name] then
        local copy = {}
        for key, value in pairs(source) do copy[key] = value end
        NGL_Profiles[name] = copy
        NGL.SwitchProfile(name)
    end
end)

local renameButton = NGL.CreateButton(profilePanel, NGL.L("profile.rename"), 90, 440, -52, function()
    local name = NGL.profileName:GetText()
    if name ~= "" and NGL_Profiles[name] then
        StaticPopup_Show("NGL_RENAME_PROFILE", nil, nil, name)
    end
end)

local shareButton = NGL.CreateButton(profilePanel, NGL.L("profile.share"), 90, 535, -52, function()
    ShowExportDialog()
end)

local importButton = NGL.CreateButton(profilePanel, NGL.L("profile.import"), 90, 630, -52, function()
    importDialog.status:SetText("")
    importDialog.editBox:SetText("")
    importDialog:Show()
    importDialog.editBox:SetFocus()
end)

local resetButton = NGL.CreateButton(profilePanel, NGL.L("profile.reset"), 70, 725, -52, function()
    StaticPopup_Show("NGL_CONFIRM_RESET_PROFILE")
end)

local deleteButton = NGL.CreateButton(profilePanel, NGL.L("profile.delete"), 70, 800, -52, function()
    local name = NGL.profileName:GetText()
    if name ~= "" and name ~= "default" and NGL_Profiles[name] then
        StaticPopupDialogs["NGL_CONFIRM_DELETE_PROFILE"].text = NGL.L("profile.delete_confirm", { name = name })
        StaticPopup_Show("NGL_CONFIRM_DELETE_PROFILE", name, nil, name)
    end
end)

local existingLabel = NGL.CreateLabel(profilePanel, NGL.L("profile.existing"), 24, -92)
local needStatusLabel = NGL.CreateLabel(profilePanel, NGL.L("profile.need_status"), 390, -92, "GameFontHighlight")
local teamNoteLabel = NGL.CreateLabel(profilePanel, NGL.L("profile.team_note"), 390, -108, "GameFontNormalSmall")

function NGL.RefreshProfileLocale()
    titleLabel:SetText(NGL.L("profile.manager"))
    nameLabel:SetText(NGL.L("profile.name"))
    createButton:SetText(NGL.L("profile.create"))
    copyButton:SetText(NGL.L("profile.copy_current"))
    renameButton:SetText(NGL.L("profile.rename"))
    shareButton:SetText(NGL.L("profile.share"))
    importButton:SetText(NGL.L("profile.import"))
    resetButton:SetText(NGL.L("profile.reset"))
    deleteButton:SetText(NGL.L("profile.delete"))
    existingLabel:SetText(NGL.L("profile.existing"))
    needStatusLabel:SetText(NGL.L("profile.need_status"))
    teamNoteLabel:SetText(NGL.L("profile.team_note"))
    StaticPopupDialogs["NGL_CONFIRM_DELETE_PROFILE"].text = NGL.L("profile.delete_confirm")
    StaticPopupDialogs["NGL_CONFIRM_DELETE_PROFILE"].button1 = NGL.L("profile.delete")
    StaticPopupDialogs["NGL_CONFIRM_DELETE_PROFILE"].button2 = NGL.L("loot.cancel")
    StaticPopupDialogs["NGL_CONFIRM_RESET_PROFILE"].text = NGL.L("profile.reset_confirm")
    StaticPopupDialogs["NGL_CONFIRM_RESET_PROFILE"].button1 = NGL.L("profile.reset")
    StaticPopupDialogs["NGL_CONFIRM_RESET_PROFILE"].button2 = NGL.L("loot.cancel")
    StaticPopupDialogs["NGL_RENAME_PROFILE"].text = NGL.L("profile.rename_title")
    StaticPopupDialogs["NGL_RENAME_PROFILE"].button1 = NGL.L("common.ok")
    StaticPopupDialogs["NGL_RENAME_PROFILE"].button2 = NGL.L("loot.cancel")
    StaticPopupDialogs["NGL_CONFIRM_IMPORT_PROFILE"].text = NGL.L("profile.import_title")
    StaticPopupDialogs["NGL_CONFIRM_IMPORT_PROFILE"].button1 = NGL.L("profile.import")
    StaticPopupDialogs["NGL_CONFIRM_IMPORT_PROFILE"].button2 = NGL.L("loot.cancel")
    exportDialog.TitleText:SetText(NGL.L("profile.export_title"))
    exportDialog.select:SetText(NGL.L("profile.select_all"))
    exportDialog.cancel:SetText(NGL.L("loot.cancel"))
    importDialog.TitleText:SetText(NGL.L("profile.import_title"))
    importDialog.action:SetText(NGL.L("profile.import"))
    importDialog.cancel:SetText(NGL.L("loot.cancel"))
    NGL.RefreshProfiles()
end