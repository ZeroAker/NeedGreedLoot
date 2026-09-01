local addonName, NGL = ...

-- Saved Variables initialization
NGL_Profiles = NGL_Profiles or {}
NGL_CurrentProfile = NGL_CurrentProfile or "default"
if NGL_DebugMode == nil then NGL_DebugMode = false end
NGL_DefaultTimer = NGL_DefaultTimer or 20
NGL_Locale = NGL_Locale or NGL.GetClientLocale()
NGL_ScannerSettings = NGL_ScannerSettings or {}
NGL_ScannerSettings.categoryMode = NGL_ScannerSettings.categoryMode or "NONE"
if NGL_ScannerSettings.showBindOnEquip == nil then
    NGL_ScannerSettings.showBindOnEquip = true
end
NGL_ScannerSettings.minQuality = NGL_ScannerSettings.minQuality or 4

function NGL.GetScannerSettings()
    NGL_ScannerSettings = NGL_ScannerSettings or {}
    NGL_ScannerSettings.categoryMode = NGL_ScannerSettings.categoryMode or "NONE"
    if NGL_ScannerSettings.showBindOnEquip == nil then
        NGL_ScannerSettings.showBindOnEquip = true
    end
    NGL_ScannerSettings.minQuality = NGL_ScannerSettings.minQuality or 4
    return NGL_ScannerSettings
end

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
        return false, NGL.L("core.permission.not_in_raid")
    end
    if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        return false, NGL.L("core.permission.not_leader")
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
        local typeStr = winnerIsNeed and "Need" or "Greed"
        local typeLabel = winnerIsNeed and NGL.L("loot.need") or NGL.L("loot.greed")
        NGL.SendRW(NGL.L("core.roll.winner", {
            player = winner,
            roll = highestRoll,
            item = NGL.currentItemLink,
            type = typeLabel
        }))

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
            print("|cff00ff00[NGL Profile: " .. NGL_CurrentProfile .. "]|r " .. NGL.L("core.roll.need_used", {
                profile = NGL_CurrentProfile,
                player = winner
            }))
        else
            profData.GreedCountList[winner] = (profData.GreedCountList[winner] or 0) + 1
            print("|cff00ff00[NGL Profile: " .. NGL_CurrentProfile .. "]|r " .. NGL.L("core.roll.greed_count", {
                profile = NGL_CurrentProfile,
                player = winner,
                count = profData.GreedCountList[winner]
            }))
        end
    else
        NGL.SendRW(NGL.L("core.roll.no_winner", { item = (NGL.currentItemLink or NGL.L("common.unknown")) }))
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
        print("|cffff0000[NGL]|r " .. NGL.L("core.roll.already_running"))
        return
    end

    if not itemLink then
        print("|cffff0000[NGL]|r " .. NGL.L("core.roll.invalid_item"))
        return
    end

    local totalTime = tonumber(duration) or NGL_DefaultTimer
    if totalTime < 5 then totalTime = 5 end

    NGL.isRolling = true
    NGL.currentItemLink = itemLink
    NGL.currentLoot = NGL.GetItemSnapshot(itemLink)
    NGL.currentRollMode = mode or "ALL"
    NGL.rolls = {}

    local modeTag = NGL.L("core.roll.need_priority")
    if NGL.currentRollMode == "NEED" then
        modeTag = NGL.L("core.roll.need_roll")
    elseif NGL.currentRollMode == "GREED" then
        modeTag = NGL.L("core.roll.greed_roll")
    end

    NGL.DebugPrint("Roll start! Profile: " .. NGL_CurrentProfile .. " | Mode: " .. NGL.currentRollMode .. " | Seconds: " .. totalTime)

    NGL.SendRW(NGL.L("core.roll.start", { mode = modeTag, item = itemLink, seconds = totalTime }))

    local warningStartSec = 5
    local waitTime = totalTime - warningStartSec

    if waitTime > 0 then
        NGL.countdownTimer = C_Timer.NewTimer(waitTime, function()
            if not NGL.isRolling then return end
            
            local secondsLeft = warningStartSec
            NGL.SendRW(NGL.L("core.roll.warning", { mode = modeTag, item = NGL.currentItemLink, seconds = secondsLeft }))
            
            NGL.countdownTimer = C_Timer.NewTicker(1, function()
                secondsLeft = secondsLeft - 1
                if NGL.isRolling and secondsLeft > 0 then
                    NGL.SendRW(NGL.L("core.roll.warning", { mode = modeTag, item = NGL.currentItemLink, seconds = secondsLeft }))
                end
            end, warningStartSec - 1)
        end)
    else
        local secondsLeft = totalTime
        NGL.SendRW(NGL.L("core.roll.warning", { mode = modeTag, item = NGL.currentItemLink, seconds = secondsLeft }))
        NGL.countdownTimer = C_Timer.NewTicker(1, function()
            secondsLeft = secondsLeft - 1
            if NGL.isRolling and secondsLeft > 0 then
                NGL.SendRW(NGL.L("core.roll.warning", { mode = modeTag, item = NGL.currentItemLink, seconds = secondsLeft }))
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
        print("|cffff0000[NGL]|r " .. NGL.L("core.roll.hover_required"))
    end
end

-- Display help command
local function PrintHelp()
    print("|cff00ff00" .. NGL.L("core.help.title") .. "|r")
    print(" |cffffd100" .. NGL.L("core.help.current_profile", { profile = NGL_CurrentProfile }) .. "|r")
    print(NGL.L("core.help.ngl"))
    print(NGL.L("core.help.ngln"))
    print(NGL.L("core.help.nglg"))
    print(NGL.L("core.help.ngl_timer"))
    print(NGL.L("core.help.ngl_item"))
    print(NGL.L("core.help.profile_switch"))
    print(NGL.L("core.help.profile_new"))
    print(NGL.L("core.help.profile_delete"))
    print(NGL.L("core.help.yes"))
    print(NGL.L("core.help.default"))
    print(NGL.L("core.help.profiles"))
    print(NGL.L("core.help.list"))
    print(NGL.L("core.help.reset"))
    print(NGL.L("core.help.timer", { seconds = NGL_DefaultTimer }))
    print(NGL.L("core.help.stop"))
    print(NGL.L("core.help.abort"))
    print(NGL.L("core.help.ui"))
    print(NGL.L("core.help.debug"))
    print(NGL.L("core.help.help"))
    print(NGL.L("core.help.footer"))
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

        local cleaned = string.gsub(msg, "|c%x%x%x%x%x%x%x%x", "")
        cleaned = string.gsub(cleaned, "|r", "")
        cleaned = string.gsub(cleaned, "^%s*(.-)%s*$", "%1")

        local numbers = {}
        for num in string.gmatch(cleaned, "%d+") do
            table.insert(numbers, tonumber(num))
        end

        if #numbers >= 3 then
            local firstNumberPos = string.find(cleaned, "%d+")
            local beforeRoll = firstNumberPos and string.sub(cleaned, 1, firstNumberPos - 1) or ""
            beforeRoll = string.gsub(beforeRoll, "%s+$", "")

            local suffixes = { "擲出", "掷出", "rolls" }
            for _, suffix in ipairs(suffixes) do
                local suffixLen = #suffix
                if suffixLen > 0 and #beforeRoll >= suffixLen and string.sub(beforeRoll, -suffixLen) == suffix then
                    beforeRoll = string.sub(beforeRoll, 1, #beforeRoll - suffixLen)
                    break
                end
            end

            name = string.gsub(beforeRoll, "%s+$", "")
            name = string.gsub(name, "^%s*(.-)%s*$", "%1")
            rollStr = numbers[1]
            lowerBound = numbers[2]
            upperBound = numbers[3]
        end

        NGL.DebugPrint(string.format("Parsed roll: name=[%s] roll=[%s] range=[%s-%s] raw=[%s]", tostring(name), tostring(rollStr), tostring(lowerBound), tostring(upperBound), tostring(cleaned)))
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
                        print("|cffff0000[NGL]|r " .. NGL.L("core.command.player_not_found", { name = cleanName }))
                        return
                    else
                        NGL.rolls[cleanName] = { roll = roll, isNeed = true, rollType = "Need" }
                        recorded = true
                        print("|cff00ff00[NGL]|r " .. NGL.L("core.command.roll_recorded", {
                            player = cleanName,
                            roll = roll,
                            type = NGL.L("loot.need")
                        }))
                    end
                elseif NGL.currentRollMode == "GREED" then
                    NGL.rolls[cleanName] = { roll = roll, isNeed = false, rollType = "Greed" }
                    recorded = true
                    print("|cff00ff00[NGL]|r " .. NGL.L("core.command.roll_recorded", {
                        player = cleanName,
                        roll = roll,
                        type = NGL.L("loot.greed")
                    }))
                else
                    local isNeed = not isUsedNeed
                    NGL.rolls[cleanName] = { roll = roll, isNeed = isNeed, rollType = isNeed and "Need" or "Greed" }
                    recorded = true
                    local typeText = isNeed and NGL.L("loot.need") or NGL.L("loot.greed")
                    print("|cff00ff00[NGL]|r " .. NGL.L("core.command.roll_recorded", {
                        player = cleanName,
                        roll = roll,
                        type = typeText
                    }))
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
            print("|cffff0000[NGL]|r " .. NGL.L("core.command.ui_missing"))
        end

    elseif cmd == "yes" then
        if not pendingDeleteProfile then
            print("|cffff0000[NGL]|r " .. NGL.L("profile.no_pending"))
            return
        end

        local targetProf = pendingDeleteProfile.profileName
        if pendingDeleteProfile.timer then
            pendingDeleteProfile.timer:Cancel()
        end
        pendingDeleteProfile = nil

        if not NGL_Profiles[targetProf] then
            print("|cffff0000[NGL]|r " .. NGL.L("profile.not_found", { name = targetProf }))
            return
        end

        NGL_Profiles[targetProf] = nil
        print("|cff00ff00[NGL]|r " .. NGL.L("profile.deleted", { name = targetProf }))

        if targetProf == NGL_CurrentProfile then
            NGL_Profiles["default"] = NGL_Profiles["default"] or {
                UsedNeedList = {},
                HistoryList = {},
                GreedCountList = {},
                LootList = {}
            }
            NGL_CurrentProfile = "default"
            NGL.NotifyProfileChanged()
            print("|cff00ff00[NGL]|r " .. NGL.L("profile.auto_switch_default"))
        end

    elseif cmd == "profile" then
        if rest == "" then
            print("|cffff0000[NGL]|r " .. NGL.L("profile.no_name", { name = NGL_CurrentProfile }))
            return
        end

        local subCmd, subRest = string.match(rest, "^(%S+)%s*(.-)$")
        subCmd = string.lower(subCmd or "")
        subRest = string.gsub(subRest or "", "^%s*(.-)%s*$", "%1")

        if subCmd == "new" then
            if subRest == "" then
                print("|cffff0000[NGL]|r " .. NGL.L("profile.no_create_name"))
                return
            end
            if NGL_Profiles[subRest] then
                print("|cffff0000[NGL]|r " .. NGL.L("profile.exists", { name = subRest }))
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
            print("|cff00ff00[NGL]|r " .. NGL.L("profile.create_success", { name = subRest }))

        elseif subCmd == "delete" then
            if subRest == "" then
                print("|cffff0000[NGL]|r " .. NGL.L("core.command.profile_delete_required"))
                return
            end
            if not NGL_Profiles[subRest] then
                print("|cffff0000[NGL]|r " .. NGL.L("profile.not_found", { name = subRest }))
                return
            end

            if pendingDeleteProfile and pendingDeleteProfile.timer then
                pendingDeleteProfile.timer:Cancel()
            end

            local timer = C_Timer.NewTimer(30, function()
                if pendingDeleteProfile and pendingDeleteProfile.profileName == subRest then
                    print("|cffff0000[NGL]|r " .. NGL.L("profile.delete_timeout", { name = subRest }))
                    pendingDeleteProfile = nil
                end
            end)

            pendingDeleteProfile = {
                profileName = subRest,
                timer = timer
            }

            local warnMsg = "|cffff0000[NGL 警告]|r " .. NGL.L("profile.delete_confirm", { name = subRest })
            if subRest == NGL_CurrentProfile then
                warnMsg = warnMsg .. " (包含當前正在使用的紀錄！刪除後將自動切換回 default)"
            end
            print(warnMsg)
            print("👉" .. NGL.L("core.command.profile_delete_prompt"))

        else
            if not NGL_Profiles[rest] then
                print("|cffff0000[NGL]|r " .. NGL.L("core.command.profile_missing", { name = rest }))
                return
            end
            NGL_CurrentProfile = rest
            NGL.NotifyProfileChanged()
            print("|cff00ff00[NGL]|r " .. NGL.L("profile.switch_success", { name = rest }))
        end

    elseif cmd == "default" then
        NGL_Profiles["default"] = NGL_Profiles["default"] or { UsedNeedList = {}, HistoryList = {}, GreedCountList = {}, LootList = {} }
        NGL_CurrentProfile = "default"
        NGL.NotifyProfileChanged()
        print("|cff00ff00[NGL]|r " .. NGL.L("profile.default_success"))

    elseif cmd == "profiles" then
        print("|cff00ff00========== [" .. NGL.L("profile.list_title") .. "] ==========|r")
        for pName, _ in pairs(NGL_Profiles) do
            if pName == NGL_CurrentProfile then
                print(" -> |cff00ff00[" .. pName .. "]|r " .. NGL.L("profile.in_use"))
            else
                print("    |cffffd100[" .. pName .. "]|r")
            end
        end
        print("|cff00ff00==================================================|r")

    elseif cmd == "timer" then
        local sec = tonumber(rest)
        if sec and sec >= 5 then
            NGL_DefaultTimer = sec
            print("|cff00ff00[NGL]|r " .. NGL.L("settings.timer.saved", { value = sec }))
        else
            print("|cffff0000[NGL]|r " .. NGL.L("core.command.invalid_timer"))
        end
    elseif cmd == "debug" then
        NGL.SetDebugMode(not NGL_DebugMode)
        local status = NGL_DebugMode and NGL.L("common.enabled") or NGL.L("common.disabled")
        print("|cff00ff00[NGL]|r " .. NGL.L("core.command.debug_status", { status = status }))
    elseif cmd == "reset" then
        NGL_Profiles[NGL_CurrentProfile] = {
            UsedNeedList = {},
            HistoryList = {},
            GreedCountList = {},
            LootList = {}
        }
        print("|cff00ff00[NGL]|r " .. NGL.L("core.command.reset_done", { name = NGL_CurrentProfile }))
    elseif cmd == "list" then
        print("|cff00ff00========== [" .. NGL.L("core.command.list_title", { name = NGL_CurrentProfile }) .. "] ==========|r")
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
            print(NGL.L("core.command.list_empty", { name = NGL_CurrentProfile }))
        end
        print("|cff00ff00========================================|r")
    elseif cmd == "stop" then
        local canUse, errorMsg = NGL.HasPermission()
        if not canUse then
            print("|cffff0000[NGL]|r " .. errorMsg)
            return
        end

        if NGL.isRolling then
            NGL.SendRW(NGL.L("core.command.roll_ended_early", { mode = NGL.L("core.roll.need_priority") }))
            NGL.FinishRoll()
        else
            print("|cffff0000[NGL]|r " .. NGL.L("core.command.no_active_roll"))
        end
    elseif cmd == "abort" then
        local canUse, errorMsg = NGL.HasPermission()
        if not canUse then
            print("|cffff0000[NGL]|r " .. errorMsg)
            return
        end

        if NGL.isRolling then
            local abortedItem = NGL.currentItemLink or NGL.L("common.unknown")
            NGL.AbortRoll()
            NGL.SendRW(NGL.L("core.command.roll_aborted", { mode = NGL.L("core.roll.need_priority"), item = abortedItem }))
            print("|cff00ff00[NGL]|r " .. NGL.L("core.command.roll_aborted_done"))
        else
            print("|cffff0000[NGL]|r " .. NGL.L("core.command.no_active_roll"))
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