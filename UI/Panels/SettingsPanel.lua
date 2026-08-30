local addonName, NGL = ...

local settingsPanel = CreateFrame("Frame", nil, NGL.ui)
settingsPanel:SetPoint("TOPLEFT", 12, -64)
settingsPanel:SetPoint("BOTTOMRIGHT", -12, 12)
NGL.panels[4] = settingsPanel

NGL.CreateLabel(settingsPanel, "設定", 12, -10, "GameFontHighlightLarge")
NGL.CreateLabel(settingsPanel, "全局計時器 (秒)", 24, -58)

local timerInput = NGL.CreateEditBox(settingsPanel, 100, 24, 160, -52, tostring(NGL_DefaultTimer))

NGL.CreateButton(settingsPanel, "Apply", 70, 270, -52, function()
    local value = tonumber(timerInput:GetText())
    if value and value >= 5 then
        NGL_DefaultTimer = value

        if NGL.scannerDurationInput then
            NGL.scannerDurationInput:SetText(tostring(NGL_DefaultTimer))
        end

        print("|cff00ff00[NGL]|r 全局計時器設爲 " .. value .. " 秒.")
    end
end)

settingsPanel:SetScript("OnShow", function()
    timerInput:SetText(tostring(NGL_DefaultTimer))
end)

local debugBtn = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
debugBtn:SetSize(160, 26)
debugBtn:SetPoint("TOPLEFT", 24, -92)

local function UpdateDebugBtnText()
    debugBtn:SetText("Debug 模式: " .. (NGL_DebugMode and "|cff00ff00開啓|r" or "|cffff0000關閉|r"))
end

UpdateDebugBtnText()

debugBtn:SetScript("OnClick", function()
    NGL_DebugMode = not NGL_DebugMode
    UpdateDebugBtnText()
    if NGL.scannerPanel and NGL.scannerPanel:IsShown() and NGL.RefreshScanner then
        NGL.RefreshScanner()
    end
    print("|cff00ff00[NGL]|r Debug 模式 " .. (NGL_DebugMode and "開啓" or "關閉") .. ".")
end)