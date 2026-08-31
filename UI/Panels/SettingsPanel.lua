local addonName, NGL = ...

local settingsPanel = CreateFrame("Frame", nil, NGL.ui)
settingsPanel:SetPoint("TOPLEFT", 12, -64)
settingsPanel:SetPoint("BOTTOMRIGHT", -12, 12)
NGL.panels[4] = settingsPanel

local titleLabel = NGL.CreateLabel(settingsPanel, NGL.L("settings.title"), 12, -10, "GameFontHighlightLarge")
local timerLabel = NGL.CreateLabel(settingsPanel, NGL.L("settings.timer"), 24, -58)
local languageLabel = NGL.CreateLabel(settingsPanel, NGL.L("settings.language"), 24, -128)

local timerInput = NGL.CreateEditBox(settingsPanel, 100, 24, 160, -52, tostring(NGL_DefaultTimer))

local dropdown = CreateFrame("Frame", nil, settingsPanel, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOPLEFT", 160, -122)
UIDropDownMenu_SetWidth(dropdown, 150)

local function RefreshLocaleDropdown()
    local options = {
        { text = "English", value = "enUS" },
        { text = "繁體中文", value = "zhTW" },
    }

    local function InitDropdown(_, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, option in ipairs(options) do
            info.text = option.text
            info.value = option.value
            info.checked = (NGL.GetLocale() == option.value)
            info.func = function(self)
                NGL.SetLocale(self.value)
                UIDropDownMenu_SetSelectedValue(dropdown, NGL.GetLocale())
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(dropdown, InitDropdown)
    UIDropDownMenu_SetSelectedValue(dropdown, NGL.GetLocale())
end

local applyButton = NGL.CreateButton(settingsPanel, NGL.L("settings.apply"), 70, 270, -52, function()
    local value = tonumber(timerInput:GetText())
    if value and value >= 5 then
        NGL_DefaultTimer = value

        if NGL.scannerDurationInput then
            NGL.scannerDurationInput:SetText(tostring(NGL_DefaultTimer))
        end

        print("|cff00ff00[NGL]|r " .. NGL.L("settings.timer.saved", { value = value }))
    end
end)

local debugBtn = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
debugBtn:SetSize(160, 26)
debugBtn:SetPoint("TOPLEFT", 24, -92)

local function UpdateDebugBtnText()
    if debugBtn then
        local state = NGL_DebugMode and NGL.L("common.enabled") or NGL.L("common.disabled")
        debugBtn:SetText(NGL.L("settings.debug", { state = state }))
    end
end

NGL.UpdateDebugButtonText = UpdateDebugBtnText

function NGL.RefreshSettingsPanel()
    titleLabel:SetText(NGL.L("settings.title"))
    timerLabel:SetText(NGL.L("settings.timer"))
    languageLabel:SetText(NGL.L("settings.language"))
    applyButton:SetText(NGL.L("settings.apply"))
    RefreshLocaleDropdown()
    UpdateDebugBtnText()
end

UpdateDebugBtnText()

settingsPanel:SetScript("OnShow", function()
    timerInput:SetText(tostring(NGL_DefaultTimer))
    NGL.RefreshSettingsPanel()
end)

debugBtn:SetScript("OnClick", function()
    NGL.SetDebugMode(not NGL_DebugMode)
    if NGL.scannerPanel and NGL.scannerPanel:IsShown() and NGL.RefreshScanner then
        NGL.RefreshScanner()
    end
    local state = NGL_DebugMode and NGL.L("common.enabled") or NGL.L("common.disabled")
    print("|cff00ff00[NGL]|r " .. NGL.L("settings.debug.toggle", { state = state }))
end)