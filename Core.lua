local addonName, NGL = ...

-- Saved Variables initialization
NGL_Profiles = NGL_Profiles or {}
NGL_CurrentProfile = NGL_CurrentProfile or "default"
if NGL_DebugMode == nil then NGL_DebugMode = false end
NGL_DefaultTimer = NGL_DefaultTimer or 20
NGL_Locale = NGL_Locale or NGL.GetClientLocale()

-- Pending confirmation state for deleting a profile
local pendingDeleteProfile = nil

-- Ensure default Profile exists
NGL_Profiles["default"] = NGL_Profiles["default"] or {
    UsedNeedList = {},
    HistoryList = {},
    GreedCountList = {},
    LootList = {}
}

-- Addon state variables
NGL.isRolling = false
NGL.currentItemLink = nil
NGL.currentLoot = nil
NGL.rolls = {}
NGL.mainTimer = nil
NGL.countdownTimer = nil
NGL.currentRollMode = "ALL" -- "ALL", "NEED", "GREED"

-- Get current profile data structure
function NGL.GetCurrentProfileData()
    if not NGL_Profiles[NGL_CurrentProfile] then
        NGL_Profiles[NGL_CurrentProfile] = {
            UsedNeedList = {},
            HistoryList = {},
            GreedCountList = {},
            LootList = {}
        }
    end
    NGL_Profiles[NGL_CurrentProfile].LootList = NGL_Profiles[NGL_CurrentProfile].LootList or {}
    return NGL_Profiles[NGL_CurrentProfile]
end

-- Debug print helper function
function NGL.DebugPrint(msg)
    if NGL_DebugMode then
        print("|cffff00ff[NGL Debug]|r " .. msg)
    end
end

function NGL.SetDebugMode(enabled)
    NGL_DebugMode = not not enabled
    if NGL.UpdateDebugButtonText then
        NGL.UpdateDebugButtonText()
    end
    if NGL.scannerPanel and NGL.scannerPanel:IsShown() and NGL.RefreshScanner then
        NGL.RefreshScanner()
    end
end

function NGL.IsValidRollValue(roll)
    local value = tonumber(roll)
    if not value then
        return false
    end
    return value >= 1 and value <= 100
end

function NGL.IsValidRollRange(lowerBound, upperBound)
    local minValue = tonumber(lowerBound)
    local maxValue = tonumber(upperBound)
    if not minValue or not maxValue then
        return false
    end
    return minValue == 1 and maxValue == 100
end

function NGL.NotifyProfileChanged()
    if NGL_RefreshUIProfile then NGL_RefreshUIProfile() end
end

-- Check raid permission
function NGL.HasPermission()
    if not IsInRaid() then
        return false, "您目前不在團隊中，無法使用此功能"
    end
    if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        return false, "您不是團隊隊長或團隊助手，無權發起或管理裝備分配！"
    end
    return true, nil
end

-- Send Raid Warning message
function NGL.SendRW(msg)
    if IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        SendChatMessage(msg, "RAID_WARNING")
    else
        SendChatMessage(msg, "RAID")
    end
end

function NGL.GenerateLootUUID(itemID)
    local randomPart = string.format("%04x", math.random(0, 65535))
    return string.format("%d-%s-%s", time(), itemID or "unknown", randomPart)
end

function NGL.GetItemSnapshot(itemLink)
    local itemID = tonumber(string.match(itemLink or "", "|Hitem:(%d+)"))
    local icon = itemID and select(5, GetItemInfoInstant(itemID))
    local loot = {
        itemLink = itemLink,
        itemID = itemID,
        icon = icon,
        uuid = NGL.GenerateLootUUID(itemID),
        rolls = {},
        winnerName = nil,
        consumableType = nil
    }
    return loot
end

function NGL.GetRollerInfo(cleanName, rawName)
    local serverName = string.match(rawName or "", "^[^-]+%-(.+)$") or GetRealmName()
    local classToken = nil
    local classColor = nil

    for index = 1, GetNumGroupMembers() do
        local unit = "raid" .. index
        local unitName = UnitName(unit)
        if unitName == cleanName or unitName == rawName then
            local _, token = UnitClass(unit)
            classToken = token
            if token and RAID_CLASS_COLORS[token] then
                local color = RAID_CLASS_COLORS[token]
                classColor = { r = color.r, g = color.g, b = color.b }
            end
            break
        end
    end

    return serverName, classToken, classColor
end

-- Finalize and announce results
function NGL.FinishRoll()
    if not NGL.isRolling then return end

    NGL.isRolling = false
    if NGL.mainTimer then NGL.mainTimer:Cancel(); NGL.mainTimer = nil end
    if NGL.countdownTimer then NGL.countdownTimer:Cancel(); NGL.countdownTimer = nil end

    local winner = nil
    local highestRoll = -1
    local winnerIsNeed = false

    for name, data in pairs(NGL.rolls) do
        if data.isNeed then
            if not winnerIsNeed or data.roll > highestRoll then
                winner = name
                highestRoll = data.roll
                winnerIsNeed = true
            end
        else
            if not winnerIsNeed and data.roll > highestRoll then
                winner = name
                highestRoll = data.roll
                winnerIsNeed = false
            end
        end
    end

    local profData = NGL.GetCurrentProfileData()

    if winner then
        local typeStr = winnerIsNeed and "【需求】" or "【貪婪】"
        NGL.SendRW("恭喜 " .. winner .. " 以 " .. highestRoll .. " 點 " .. typeStr .. " 獲得 " .. NGL.currentItemLink .. "！")

        NGL.currentLoot.winnerName = winner
        NGL.currentLoot.consumableType = winnerIsNeed and "Need" or "Greed"
        NGL.currentLoot.winnerRoll = highestRoll
        
        profData.HistoryList[winner] = profData.HistoryList[winner] or {}
        table.insert(profData.HistoryList[winner], {
            item = NGL.currentItemLink,
            isNeed = winnerIsNeed,
            roll = highestRoll,
            uuid = NGL.currentLoot.uuid
        })

        if winnerIsNeed then
            profData.UsedNeedList[winner] = true
            print("|cff00ff00[NGL Profile: " .. NGL_CurrentProfile .. "]|r 已消耗 " .. winner .. " 的需求機會。")
        else
            profData.GreedCountList[winner] = (profData.GreedCountList[winner] or 0) + 1
            print("|cff00ff00[NGL Profile: " .. NGL_CurrentProfile .. "]|r 已記錄 " .. winner .. " 貪婪獲勝 (+1，累計: " .. profData.GreedCountList[winner] .. " 次)。")
        end
    else
        NGL.SendRW((NGL.currentItemLink or "裝備") .. " 擲骰結束，無人擲骰。")
    end

    profData.LootList[NGL.currentLoot.uuid] = NGL.currentLoot

    NGL.currentItemLink = nil
    NGL.currentLoot = nil
    NGL.rolls = {}
    NGL.currentRollMode = "ALL"
end

function NGL.AbortRoll()
    if not NGL.isRolling then return end

    NGL.isRolling = false
    if NGL.mainTimer then NGL.mainTimer:Cancel(); NGL.mainTimer = nil end
    if NGL.countdownTimer then NGL.countdownTimer:Cancel(); NGL.countdownTimer = nil end

    NGL.currentItemLink = nil
    NGL.currentLoot = nil
    NGL.rolls = {}
    NGL.currentRollMode = "ALL"
end

-- Start roll process
function StartNGLRoll(itemLink, duration, mode)
    local canUse, errorMsg = NGL.HasPermission()
    if not canUse then
        print("|cffff0000[NGL]|r " .. errorMsg)
        return
    end

    if NGL.isRolling then
        print("|cffff0000[NGL]|r 目前已有裝備正在進行擲骰中！")
        return
    end

    if not itemLink then
        print("|cffff0000[NGL]|r 無法識別裝備連結！")
        return
    end

    local totalTime = tonumber(duration) or NGL_DefaultTimer
    if totalTime < 5 then totalTime = 5 end

    NGL.isRolling = true
    NGL.currentItemLink = itemLink
    NGL.currentLoot = NGL.GetItemSnapshot(itemLink)
    NGL.currentRollMode = mode or "ALL"
    NGL.rolls = {}

    local modeTag = "【需求優先】"
    if NGL.currentRollMode == "NEED" then
        modeTag = "【需求擲骰】"
    elseif NGL.currentRollMode == "GREED" then
        modeTag = "【貪婪擲骰】"
    end

    NGL.DebugPrint("擲骰開始！Profile: " .. NGL_CurrentProfile .. " | 模式: " .. NGL.currentRollMode .. " | 秒數: " .. totalTime)

    NGL.SendRW(modeTag .. " " .. itemLink .. " 開放擲骰！請使用 /roll (倒數 " .. totalTime .. " 秒)")

    local warningStartSec = 5
    local waitTime = totalTime - warningStartSec

    if waitTime > 0 then
        NGL.countdownTimer = C_Timer.NewTimer(waitTime, function()
            if not NGL.isRolling then return end
            
            local secondsLeft = warningStartSec
            NGL.SendRW(modeTag .. " " .. NGL.currentItemLink .. " 倒數最後 " .. secondsLeft .. " 秒！")
            
            NGL.countdownTimer = C_Timer.NewTicker(1, function()
                secondsLeft = secondsLeft - 1
                if NGL.isRolling and secondsLeft > 0 then
                    NGL.SendRW(modeTag .. " " .. NGL.currentItemLink .. " 倒數最後 " .. secondsLeft .. " 秒！")
                end
            end, warningStartSec - 1)
        end)
    else
        local secondsLeft = totalTime
        NGL.SendRW(modeTag .. " " .. NGL.currentItemLink .. " 倒數最後 " .. secondsLeft .. " 秒！")
        NGL.countdownTimer = C_Timer.NewTicker(1, function()
            secondsLeft = secondsLeft - 1
            if NGL.isRolling and secondsLeft > 0 then
                NGL.SendRW(modeTag .. " " .. NGL.currentItemLink .. " 倒數最後 " .. secondsLeft .. " 秒！")
            end
        end, totalTime - 1)
    end

    NGL.mainTimer = C_Timer.NewTimer(totalTime, function()
        NGL.FinishRoll()
    end)
end

function IsNGLRollActive()
    return NGL.isRolling
end

-- Mouseover roll trigger
function StartNGLRollFromMouseover(duration, mode)
    local canUse, errorMsg = NGL.HasPermission()
    if not canUse then
        print("|cffff0000[NGL]|r " .. errorMsg)
        return
    end

    local _, itemLink = GameTooltip:GetItem()
    if itemLink then
        StartNGLRoll(itemLink, duration, mode)
    else
        print("|cffff0000[NGL]|r 請將滑鼠指在背包或裝備欄的物品上方！")
    end
end

-- Display help command
local function PrintHelp()
    print("|cff00ff00=== [NeedGreedLoot 一需多貪助手] 指令表 ===|r")
    print(" |cffffd100[當前 Profile: " .. NGL_CurrentProfile .. "]|r")
    print(" |cffffd100/ngl|r - 需求優先 (尚有需求者為需求，已消耗者為貪婪)")
    print(" |cffffd100/ngln|r - 需求擲骰 (僅未消耗需求的玩家可參與，已消耗者 Roll 無效)")
    print(" |cffffd100/nglg|r - 貪婪擲骰 (所有人皆可參與且全算貪婪，不消耗需求，記錄貪婪次數)")
    print(" |cffffd100/ngl [秒數]|r / |cffffd100/ngln [秒數]|r / |cffffd100/nglg [秒數]|r - 對懸停物品發起指定秒數開骰")
    print(" |cffffd100/ngl [裝備] [秒數]|r - 對指定裝備連結發起開骰")
    print(" |cffffd100/ngl profile [名稱]|r - 切換至指定 Profile")
    print(" |cffffd100/ngl profile new [名稱]|r - 建立新的 Profile 並自動切換過去")
    print(" |cffffd100/ngl profile delete [名稱]|r - 準備刪除指定的 Profile (需輸入 /ngl yes 確認)")
    print(" |cffffd100/ngl yes|r - 確認刪除處於等待狀態的 Profile")
    print(" |cffffd100/ngl default|r - 切換回預設 (default) Profile")
    print(" |cffffd100/ngl profiles|r - 列出所有已建立的 Profile 清單")
    print(" |cffffd100/ngl list|r - 查看當前 Profile 玩家需求狀態、貪婪次數與獲獎歷史")
    print(" |cffffd100/ngl reset|r - 重置當前 Profile 所有玩家紀錄")
    print(" |cffffd100/ngl timer [秒數]|r - 設定全域預設倒數秒數 (目前: " .. NGL_DefaultTimer .. " 秒)")
    print(" |cffffd100/ngl stop|r - 提前結束當前開骰並立即結算")
    print(" |cffffd100/ngl abort|r - 終止當前開骰，不結算且不計數")
    print(" |cffffd100/ngl ui|r - 開啟 NeedGreedLoot 控制面板")
    print(" |cffffd100/ngl debug|r - 開關 Debug 除錯模式訊息輸出")
    print(" |cffffd100/ngl help|r - 顯示此指令說明選單")
    print("|cff00ff00========================================|r")
end

-- System Event Handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1, msg)
    if event == "ADDON_LOADED" and arg1 == "NeedGreedLoot" then
        NGL_Profiles[NGL_CurrentProfile] = NGL.GetCurrentProfileData()
        NGL.DebugPrint("NeedGreedLoot  載入完成，目前 Profile: " .. NGL_CurrentProfile)
    elseif event == "CHAT_MSG_SYSTEM" then
        msg = arg1
        if not NGL.isRolling then return end

        NGL.DebugPrint("Received system msg: " .. tostring(msg))

        local name, rollStr, lowerBound, upperBound
        name, rollStr, lowerBound, upperBound = string.match(msg, "^(.-)%s*(%d+)%s*[（%(]%s*(%d+)%s*[-─－]%s*(%d+)%s*[）%)]")
        if not name or not rollStr then name, rollStr, lowerBound, upperBound = string.match(msg, "^(.-)%s*rolls%s*(%d+)%s*[（%(]%s*(%d+)%s*[-─－]%s*(%d+)%s*[）%)]") end
        if not name or not rollStr then name, rollStr, lowerBound, upperBound = string.match(msg, "^(.-)%s*擲出%s*(%d+)%s*[（%(]%s*(%d+)%s*[-─－]%s*(%d+)%s*[）%)]") end
        if not name or not rollStr then name, rollStr, lowerBound, upperBound = string.match(msg, "^(.-)%s*擲出%s*(%d+)%s*%(%s*(%d+)%s*[-─－]%s*(%d+)%s*%)") end
        if not name or not rollStr then name, rollStr, lowerBound, upperBound = string.match(msg, "^(.-)%s*掷出%s*(%d+)%s*[（%(]%s*(%d+)%s*[-─－]%s*(%d+)%s*[）%)]") end

        if name and rollStr then
            local roll = tonumber(rollStr)
            local rawName = name

            name = string.gsub(name, "|c%x%x%x%x%x%x%x%x", "")
            name = string.gsub(name, "|r", "")
            name = string.gsub(name, "^%s*(.-)%s*$", "%1")
            local cleanName = string.match(name, "([^-]+)") or name

            if not lowerBound or not upperBound then
                NGL.DebugPrint("忽略缺少範圍的 roll -> 玩家: [" .. cleanName .. "] Roll: [" .. tostring(roll) .. "]")
                return
            end

            if not NGL.IsValidRollRange(lowerBound, upperBound) then
                NGL.DebugPrint("忽略非 1-100 範圍 roll -> 玩家: [" .. cleanName .. "] Roll: [" .. tostring(roll) .. "] 範圍: [" .. tostring(lowerBound) .. "-" .. tostring(upperBound) .. "]")
                return
            end

            if not NGL.IsValidRollValue(roll) then
                NGL.DebugPrint("忽略無效 roll -> 玩家: [" .. cleanName .. "] Roll: [" .. tostring(roll) .. "] (限定 1-100)")
                return
            end

            NGL.DebugPrint("解析成功 -> 玩家: [" .. cleanName .. "] Roll: [" .. roll .. "] 範圍: [" .. lowerBound .. "-" .. upperBound .. "]")

            if not NGL.rolls[cleanName] then
                local recorded = false
                local profData = NGL.GetCurrentProfileData()
                local isUsedNeed = profData.UsedNeedList[cleanName]

                if NGL.currentRollMode == "NEED" then
                    if isUsedNeed then
                        print("|cffff0000[NGL]|r 玩家 " .. cleanName .. " 已消耗需求資格，本次【僅限需求】開骰點數無效！")
                        return
                    else
                        NGL.rolls[cleanName] = { roll = roll, isNeed = true, rollType = "Need" }
                        recorded = true
                        print("|cff00ff00[NGL]|r 成功記錄 " .. cleanName .. ": " .. roll .. " 點 (|cff00ff00需求|r)")
                    end
                elseif NGL.currentRollMode == "GREED" then
                    NGL.rolls[cleanName] = { roll = roll, isNeed = false, rollType = "Greed" }
                    recorded = true
                    print("|cff00ff00[NGL]|r 成功記錄 " .. cleanName .. ": " .. roll .. " 點 (|cffff9900貪婪|r)")
                else
                    local isNeed = not isUsedNeed
                    NGL.rolls[cleanName] = { roll = roll, isNeed = isNeed, rollType = isNeed and "Need" or "Greed" }
                    recorded = true
                    local typeText = isNeed and "|cff00ff00需求|r" or "|cffff9900貪婪|r"
                    print("|cff00ff00[NGL]|r 成功記錄 " .. cleanName .. ": " .. roll .. " 點 (" .. typeText .. ")")
                end

                if recorded then
                    local serverName, classToken, classColor = NGL.GetRollerInfo(cleanName, rawName)
                    table.insert(NGL.currentLoot.rolls, {
                        playerName = cleanName,
                        serverName = serverName,
                        classToken = classToken,
                        classColor = classColor,
                        roll = roll,
                        rollType = NGL.rolls[cleanName].rollType,
                        timestamp = time()
                    })
                end
            else
                NGL.DebugPrint(cleanName .. " 已經擲骰過，忽略第二次點數。")
            end
        end
    end
end)

-- Slash Command Handler
local function HandleNGLSlash(msg, mode)
    msg = string.gsub(msg, "^%s*(.-)%s*$", "%1")
    
    if msg == "" then
        StartNGLRollFromMouseover(nil, mode)
        return
    end

    local cmd, rest = string.match(msg, "^(%S+)%s*(.-)$")
    cmd = string.lower(cmd or "")
    rest = string.gsub(rest or "", "^%s*(.-)%s*$", "%1")

    if cmd == "help" or cmd == "?" then
        PrintHelp()

    elseif cmd == "ui" then
        if NGL_ToggleUI then
            NGL_ToggleUI()
        else
            print("|cffff0000[NGL]|r 控制面板尚未載入，請重新載入介面。")
        end

    elseif cmd == "yes" then
        if not pendingDeleteProfile then
            print("|cffff0000[NGL]|r 沒有待刪除的 Profile!")
            return
        end

        local targetProf = pendingDeleteProfile.profileName
        if pendingDeleteProfile.timer then
            pendingDeleteProfile.timer:Cancel()
        end
        pendingDeleteProfile = nil

        if not NGL_Profiles[targetProf] then
            print("|cffff0000[NGL]|r Profile [" .. targetProf .. "] 不存在，無法刪除！")
            return
        end

        NGL_Profiles[targetProf] = nil
        print("|cff00ff00[NGL]|r 已成功刪除 Profile：|cffffd100[" .. targetProf .. "]|r")

        if targetProf == NGL_CurrentProfile then
            NGL_Profiles["default"] = NGL_Profiles["default"] or {
                UsedNeedList = {},
                HistoryList = {},
                GreedCountList = {},
                LootList = {}
            }
            NGL_CurrentProfile = "default"
            NGL.NotifyProfileChanged()
            print("|cff00ff00[NGL]|r  由於剛刪除了當前正使用的 Profile，已自動切換回：|cffffd100[default]|r")
        end

    elseif cmd == "profile" then
        if rest == "" then
            print("|cffff0000[NGL]|r 請輸入欲切換的 Profile 名稱！目前使用中：|cffffd100[" .. NGL_CurrentProfile .. "]|r")
            return
        end

        local subCmd, subRest = string.match(rest, "^(%S+)%s*(.-)$")
        subCmd = string.lower(subCmd or "")
        subRest = string.gsub(subRest or "", "^%s*(.-)%s*$", "%1")

        if subCmd == "new" then
            if subRest == "" then
                print("|cffff0000[NGL]|r 請輸入欲建立的 Profile 名稱！範例：/ngl profile new 25人團")
                return
            end
            if NGL_Profiles[subRest] then
                print("|cffff0000[NGL]|r Profile [" .. subRest .. "] 已經存在！切換請用：/ngl profile " .. subRest)
                return
            end
            NGL_Profiles[subRest] = {
                UsedNeedList = {},
                HistoryList = {},
                GreedCountList = {},
                LootList = {}
            }
            NGL_CurrentProfile = subRest
            NGL.NotifyProfileChanged()
            print("|cff00ff00[NGL]|r 已成功建立並切換至新 Profile：|cffffd100[" .. subRest .. "]|r")

        elseif subCmd == "delete" then
            if subRest == "" then
                print("|cffff0000[NGL]|r 請輸入欲刪除的 Profile 名稱！範例：/ngl profile delete 25人團")
                return
            end
            if not NGL_Profiles[subRest] then
                print("|cffff0000[NGL]|r 找不到名為 [" .. subRest .. "] 的 Profile！")
                return
            end

            if pendingDeleteProfile and pendingDeleteProfile.timer then
                pendingDeleteProfile.timer:Cancel()
            end

            local timer = C_Timer.NewTimer(30, function()
                if pendingDeleteProfile and pendingDeleteProfile.profileName == subRest then
                    print("|cffff0000[NGL]|r 刪除 Profile [" .. subRest .. "] 已超時取消。")
                    pendingDeleteProfile = nil
                end
            end)

            pendingDeleteProfile = {
                profileName = subRest,
                timer = timer
            }

            local warnMsg = "|cffff0000[NGL 警告]|r 您確定要刪除 Profile |cffffd100[" .. subRest .. "]|r 嗎？"
            if subRest == NGL_CurrentProfile then
                warnMsg = warnMsg .. " (包含當前正在使用的紀錄！刪除後將自動切換回 default)"
            end
            print(warnMsg)
            print("👉請在 30 秒內輸入 |cff00ff00/ngl yes|r 以確認刪除。")

        else
            if not NGL_Profiles[rest] then
                print("|cffff0000[NGL]|r 找不到名為 [" .. rest .. "] 的 Profile！可用 /ngl profile new " .. rest .. " 建立它。")
                return
            end
            NGL_CurrentProfile = rest
            NGL.NotifyProfileChanged()
            print("|cff00ff00[NGL]|r 已成功切換至 Profile：|cffffd100[" .. rest .. "]|r")
        end

    elseif cmd == "default" then
        NGL_Profiles["default"] = NGL_Profiles["default"] or { UsedNeedList = {}, HistoryList = {}, GreedCountList = {}, LootList = {} }
        NGL_CurrentProfile = "default"
        NGL.NotifyProfileChanged()
        print("|cff00ff00[NGL]|r 已成功切換回預設 Profile：|cffffd100[default]|r")

    elseif cmd == "profiles" then
        print("|cff00ff00========== [NeedGreedLoot Profile 清單] ==========|r")
        for pName, _ in pairs(NGL_Profiles) do
            if pName == NGL_CurrentProfile then
                print(" -> |cff00ff00[" .. pName .. "]|r (使用中)")
            else
                print("    |cffffd100[" .. pName .. "]|r")
            end
        end
        print("|cff00ff00==================================================|r")

    elseif cmd == "timer" then
        local sec = tonumber(rest)
        if sec and sec >= 5 then
            NGL_DefaultTimer = sec
            print("|cff00ff00[NGL]|r 已將全域預設倒數時間設為" .. sec .. " 秒。")
        else
            print("|cffff0000[NGL]|r 請輸入有效的秒數 (至少 5 秒)，例如：/ngl timer 30")
        end
    elseif cmd == "debug" then
        NGL.SetDebugMode(not NGL_DebugMode)
        local status = NGL_DebugMode and "|cff00ff00已開啟|r" or "|cffff0000已關閉|r"
        print("|cff00ff00[NGL]|r Debug 模式 " .. status)
    elseif cmd == "reset" then
        NGL_Profiles[NGL_CurrentProfile] = {
            UsedNeedList = {},
            HistoryList = {},
            GreedCountList = {},
            LootList = {}
        }
        print("|cff00ff00[NGL]|r已重置當前 Profile [" .. NGL_CurrentProfile .. "] 的所有玩家紀錄。")
    elseif cmd == "list" then
        print("|cff00ff00========== [NGL 紀錄 - Profile: " .. NGL_CurrentProfile .. "] ==========|r")
        local profData = NGL.GetCurrentProfileData()
        local count = 0
        
        local allPlayers = {}
        for name, _ in pairs(profData.UsedNeedList) do allPlayers[name] = true end
        for name, _ in pairs(profData.HistoryList) do allPlayers[name] = true end
        for name, _ in pairs(profData.GreedCountList) do allPlayers[name] = true end

        for name, _ in pairs(allPlayers) do
            count = count + 1
            local needStatus = profData.UsedNeedList[name] and "|cffff0000[已消耗需求]|r" or "|cff00ff00[尚有需求]|r"
            local greedWins = profData.GreedCountList[name] or 0
            
            print("Player: |cffffd100" .. name .. "|r " .. needStatus .. " | 貪婪獲勝: |cffff9900" .. greedWins .. "|r 次")

            local history = profData.HistoryList[name]
            if history and #history > 0 then
                for _, record in ipairs(history) do
                    local typeStr = record.isNeed and "|cff00ff00【需求】|r" or "|cffff9900【貪婪】|r"
                    print("   - " .. record.item .. " (" .. record.roll .. " 點 " .. typeStr .. ")")
                end
            else
                print("   - (無裝備獲獎紀錄)")
            end
        end

        if count == 0 then
            print("當前 Profile [" .. NGL_CurrentProfile .. "] 尚無任何玩家紀錄。")
        end
        print("|cff00ff00========================================|r")
    elseif cmd == "stop" then
        local canUse, errorMsg = NGL.HasPermission()
        if not canUse then
            print("|cffff0000[NGL]|r " .. errorMsg)
            return
        end

        if NGL.isRolling then
            NGL.SendRW("【需求優先】主控者已提前結束倒數！結算中...")
            NGL.FinishRoll()
        else
            print("|cffff0000[NGL]|r 當前沒有正在進行中的開骰。")
        end
    elseif cmd == "abort" then
        local canUse, errorMsg = NGL.HasPermission()
        if not canUse then
            print("|cffff0000[NGL]|r " .. errorMsg)
            return
        end

        if NGL.isRolling then
            local abortedItem = NGL.currentItemLink or "本次裝備"
            NGL.AbortRoll()
            NGL.SendRW("【需求優先】主控者已終止 " .. abortedItem .. " 的開骰，本次不予結算。")
            print("|cff00ff00[NGL]|r 已終止本次開骰，未更新任何紀錄。")
        else
            print("|cffff0000[NGL]|r 當前沒有正在進行中的開骰。")
        end
    elseif tonumber(cmd) then
        StartNGLRollFromMouseover(tonumber(cmd), mode)
    else
        local itemLink, duration = string.match(msg, "(|c%x+|Hitem:.-|h%[.-%]|h|r)%s*(%d*)")
        if itemLink then
            StartNGLRoll(itemLink, tonumber(duration), mode)
        else
            StartNGLRoll(msg, nil, mode)
        end
    end
end

-- Slash Commands Registration
SLASH_NGL1 = "/ngl"
SlashCmdList["NGL"] = function(msg) HandleNGLSlash(msg, "ALL") end

SLASH_NGLN1 = "/ngln"
SlashCmdList["NGLN"] = function(msg) HandleNGLSlash(msg, "NEED") end

SLASH_NGLG1 = "/nglg"
SlashCmdList["NGLG"] = function(msg) HandleNGLSlash(msg, "GREED") end