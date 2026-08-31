local addonName, NGL = ...

local ui = CreateFrame("Frame", "NGLControlPanel", UIParent, "BasicFrameTemplateWithInset")
ui:SetSize(900, 600)
ui:SetPoint("CENTER")
ui:SetMovable(true)
ui:EnableMouse(true)
ui:RegisterForDrag("LeftButton")
ui:SetScript("OnDragStart", ui.StartMoving)
ui:SetScript("OnDragStop", ui.StopMovingOrSizing)
ui:Hide()
ui.TitleText:SetText(NGL.L("ui.title"))

NGL.ui = ui
NGL.tabs = {}
NGL.panels = {}

function NGL.RefreshLocaleUI()
    if ui and ui.TitleText then
        ui.TitleText:SetText(NGL.L("ui.title"))
    end

    for index, tab in ipairs(NGL.tabs or {}) do
        local key = nil
        if index == 1 then key = "ui.tabs.scan"
        elseif index == 2 then key = "ui.tabs.loot_log"
        elseif index == 3 then key = "ui.tabs.profile"
        elseif index == 4 then key = "ui.tabs.settings"
        elseif index == 5 then key = "ui.tabs.manual" end
        if key and tab then
            tab:SetText(NGL.L(key))
        end
    end

    if NGL.RefreshSettingsPanel then
        NGL.RefreshSettingsPanel()
    end
end

-- Utility creation functions
function NGL.CreateLabel(parent, text, x, y, size)
    local label = parent:CreateFontString(nil, "ARTWORK", size or "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end

function NGL.CreateEditBox(parent, width, height, x, y, text)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetSize(width, height)
    edit:SetPoint("TOPLEFT", x, y)
    edit:SetAutoFocus(false)
    edit:SetText(text or "")
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return edit
end

function NGL.CreateButton(parent, text, width, x, y, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

function NGL.ClearRows(rows)
    for _, row in ipairs(rows) do
        row:Hide()
    end
end

local function CreateTab(name, text, x)
    local tab = CreateFrame("Button", name, ui, "OptionsFrameTabButtonTemplate")
    tab:SetID(#NGL.tabs + 1)
    tab:SetText(text)
    
    local textFS = tab:GetFontString()
    if textFS then
        textFS:ClearAllPoints()
        textFS:SetPoint("CENTER", tab, "CENTER", 5, -3)
    end
    local highlight = tab:GetHighlightTexture()
    if highlight then
        highlight:ClearAllPoints()
        highlight:SetPoint("CENTER", tab, "CENTER", 5, -3)
    end
    
    tab:SetPoint("TOPLEFT", x, -28)
    NGL.tabs[#NGL.tabs + 1] = tab
    return tab
end

function NGL.SelectTab(index)
    for tabIndex, tab in ipairs(NGL.tabs) do
        if tabIndex == index then
            tab:Disable()
            NGL.panels[tabIndex]:Show()
        else
            tab:Enable()
            NGL.panels[tabIndex]:Hide()
        end
    end
    if index == 2 and NGL.RefreshLootList then NGL.RefreshLootList() end
    if index == 3 and NGL.RefreshProfiles then NGL.RefreshProfiles() end
end

-- Create Main Tabs
local tab1 = CreateTab("NGLTab1", NGL.L("ui.tabs.scan"), 18)
local tab2 = CreateTab("NGLTab2", NGL.L("ui.tabs.loot_log"), 0)
local tab3 = CreateTab("NGLTab3", NGL.L("ui.tabs.profile"), 0)
local tab4 = CreateTab("NGLTab4", NGL.L("ui.tabs.settings"), 0)
local tab5 = CreateTab("NGLTab5", NGL.L("ui.tabs.manual"), 0)

tab2:ClearAllPoints()
tab2:SetPoint("LEFT", tab1, "RIGHT", 12, 0)
tab3:ClearAllPoints()
tab3:SetPoint("LEFT", tab2, "RIGHT", 12, 0)
tab4:ClearAllPoints()
tab4:SetPoint("LEFT", tab3, "RIGHT", 12, 0)
tab5:ClearAllPoints()
tab5:SetPoint("LEFT", tab4, "RIGHT", 12, 0)

tab1:SetScript("OnClick", function() NGL.SelectTab(1) end)
tab2:SetScript("OnClick", function() NGL.SelectTab(2) end)
tab3:SetScript("OnClick", function() NGL.SelectTab(3) end)
tab4:SetScript("OnClick", function() NGL.SelectTab(4) end)
tab5:SetScript("OnClick", function() NGL.SelectTab(5) end)

if NGL.tabs[5] then NGL.tabs[5]:Hide() end -- Reserved

ui:SetScript("OnShow", function() NGL.SelectTab(1) end)

NGL_ToggleUI = function()
    if ui:IsShown() then ui:Hide() else ui:Show() end
end

NGL_RefreshUIProfile = function()
    if NGL.ClearLootDetails then NGL.ClearLootDetails() end
    if NGL.profileName then NGL.profileName:SetText(NGL_CurrentProfile) end
    if NGL.RefreshProfiles then NGL.RefreshProfiles() end
    if NGL.RefreshLootList then NGL.RefreshLootList() end
end