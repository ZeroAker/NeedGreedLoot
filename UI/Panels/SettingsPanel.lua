local addonName, NGL = ...

local settingsPanel = CreateFrame("Frame", nil, NGL.ui)
settingsPanel:SetPoint("TOPLEFT", 12, -64)
settingsPanel:SetPoint("BOTTOMRIGHT", -12, 12)
NGL.panels[4] = settingsPanel

local titleLabel = NGL.CreateLabel(settingsPanel, NGL.L("settings.title"), 12, -10, "GameFontHighlightLarge")

local rowLeft = 18
local controlLeft = 150

local languageLabel = NGL.CreateLabel(settingsPanel, NGL.L("settings.language"), rowLeft, -62)
local dropdown = CreateFrame("Frame", nil, settingsPanel, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOPLEFT", controlLeft, -54)
UIDropDownMenu_SetWidth(dropdown, 150)

local debugLabel = NGL.CreateLabel(settingsPanel, NGL.L("settings.debug"):gsub("%s*:%s*%{state%}", ""), rowLeft, -114)
local debugBtn = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
debugBtn:SetSize(160, 26)
debugBtn:SetPoint("TOPLEFT", controlLeft, -108)

local timerLabel = NGL.CreateLabel(settingsPanel, NGL.L("settings.timer"), rowLeft, -166)
local timerInput = NGL.CreateEditBox(settingsPanel, 100, 24, controlLeft, -160, tostring(NGL_DefaultTimer))

local applyButton = NGL.CreateButton(settingsPanel, NGL.L("settings.apply"), 70, controlLeft + 110, -160, function()
    local value = tonumber(timerInput:GetText())
    if value and value >= 5 then
        NGL_DefaultTimer = value

        if NGL.scannerDurationInput then
            NGL.scannerDurationInput:SetText(tostring(NGL_DefaultTimer))
        end

        print("|cff00ff00[NGL]|r " .. NGL.L("settings.timer.saved", { value = value }))
    end
end)

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

local function UpdateDebugBtnText()
    if debugBtn then
        local state = NGL_DebugMode and NGL.L("common.enabled") or NGL.L("common.disabled")
        debugBtn:SetText(NGL.L("settings.debug", { state = state }))
    end
end

NGL.UpdateDebugButtonText = UpdateDebugBtnText

function NGL.RefreshSettingsPanel()
    titleLabel:SetText(NGL.L("settings.title"))
    languageLabel:SetText(NGL.L("settings.language"))
    debugLabel:SetText(NGL.L("settings.debug"):gsub("%s*:%s*%{state%}", ""))
    timerLabel:SetText(NGL.L("settings.timer"))
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