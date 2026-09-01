local addonName, NGL = ...

NGL.Locale = NGL.Locale or {}
NGL.Locale.fallback = "enUS"

NGL.Locale.translations = {
    enUS = {
        ["ui.title"] = "NeedGreedLoot Control Panel",
        ["ui.tabs.scan"] = "Scan & Roll",
        ["ui.tabs.loot_log"] = "Loot Log",
        ["ui.tabs.profile"] = "Profile",
        ["ui.tabs.settings"] = "Settings",
        ["ui.tabs.manual"] = "Manual",

        ["settings.title"] = "Settings",
        ["settings.timer"] = "Global timer (seconds)",
        ["settings.apply"] = "Apply",
        ["settings.language"] = "Language",
        ["settings.debug"] = "Debug mode: {state}",
        ["settings.debug.enabled"] = "Enabled",
        ["settings.debug.disabled"] = "Disabled",
        ["settings.debug.toggle"] = "Debug mode {state}.",
        ["settings.timer.saved"] = "Global timer set to {value} seconds.",
        ["settings.scanner_category"] = "Scanner category",
        ["settings.scanner_category.none"] = "Uncategorized",
        ["settings.scanner_category.type"] = "Equipment Type",
        ["settings.scanner_category.trade_time"] = "Remaining Trade Time",
        ["settings.scanner_boe"] = "Show bind-on-equip equipment",
        ["settings.scanner_quality"] = "Minimum item quality",
        ["settings.scanner_quality.all"] = "All",
        ["settings.scanner_quality.uncommon"] = "Uncommon",
        ["settings.scanner_quality.rare"] = "Rare",
        ["settings.scanner_quality.epic"] = "Epic",
        ["settings.scanner_quality.legendary"] = "Legendary",

        ["common.enabled"] = "Enabled",
        ["common.disabled"] = "Disabled",
        ["common.warning"] = "Warning",
        ["common.ok"] = "OK",
        ["common.yes"] = "Yes",
        ["common.no"] = "No",
        ["common.unknown"] = "Unknown",
        ["common.second"] = "sec",

        ["scanner.title"] = "Scan & Roll",
        ["scanner.category"] = "Scanner category",
        ["scanner.min_quality"] = "Minimum item quality",
        ["scanner.current_item"] = "Current Item",
        ["scanner.no_item_selected"] = "No item selected",
        ["scanner.seconds"] = "sec",
        ["scanner.bag_items"] = "Bag Items",
        ["scanner.scan_bag"] = "Scan Bag",
        ["scanner.need_priority"] = "Need Priority",
        ["scanner.need_roll"] = "Need Roll",
        ["scanner.greed_roll"] = "Greed Roll",
        ["scanner.end_early"] = "End Early",
        ["scanner.abort"] = "Abort",
        ["scanner.selected_slot"] = "Selected bag {bag}, slot {slot}",
        ["scanner.dropdown.choose_player"] = "Select team player",
        ["scanner.status.empty"] = "No item selected",
        ["scanner.status.selected"] = "Selected bag {bag}, slot {slot}",

        ["loot.title"] = "Loot Log",
        ["loot.search"] = "Search item or UUID",
        ["loot.all"] = "All",
        ["loot.unassigned"] = "Unassigned",
        ["loot.assigned"] = "Assigned",
        ["loot.select_detail"] = "Select an item to view details",
        ["loot.player"] = "Player",
        ["loot.server"] = "Server",
        ["loot.class"] = "Class",
        ["loot.type"] = "Type",
        ["loot.points"] = "Points",
        ["loot.choose_player"] = "Select team player",
        ["loot.assign_greed"] = "Assign Greed",
        ["loot.assign_need"] = "Assign Need",
        ["loot.reroll"] = "Reroll:",
        ["loot.reroll_all"] = "Need Priority",
        ["loot.reroll_need"] = "Need Roll",
        ["loot.reroll_greed"] = "Greed Roll",
        ["loot.status_unassigned"] = "Status: winner not assigned",
        ["loot.status_winner"] = "Winner: {player} ({type})",
        ["loot.uuid"] = "UUID: {uuid}",
        ["loot.delete_confirm"] = "Are you sure you want to delete this Loot Log entry? This cannot be undone.",
        ["loot.delete"] = "Delete",
        ["loot.cancel"] = "Cancel",
        ["loot.need"] = "Need",
        ["loot.greed"] = "Greed",

        ["profile.manager"] = "Profile Manager",
        ["profile.name"] = "Profile Name",
        ["profile.create"] = "Create",
        ["profile.copy_current"] = "Copy Current",
        ["profile.reset"] = "Reset",
        ["profile.delete"] = "Delete",
        ["profile.existing"] = "Existing Profiles",
        ["profile.need_status"] = "Need Usage Status",
        ["profile.team_note"] = "Team members prioritized; gray names indicate not currently in the team.",
        ["profile.using"] = "{name} (active)",
        ["profile.used"] = "Used",
        ["profile.unused"] = "Unused",
        ["profile.delete_confirm"] = "Are you sure you want to delete Profile [{name}]? This cannot be undone.",
        ["profile.reset_confirm"] = "Are you sure you want to reset the current Profile? All players and Loot Log data will be cleared.",
        ["profile.not_found"] = "Profile [{name}] does not exist and cannot be deleted.",
        ["profile.no_name"] = "Please enter the Profile name you want to switch to. Current profile: {name}",
        ["profile.no_create_name"] = "Please enter the Profile name to create. Example: /ngl profile new 25man",
        ["profile.exists"] = "Profile [{name}] already exists. To switch, use: /ngl profile {name}",
        ["profile.deleted"] = "Profile [{name}] was deleted successfully.",
        ["profile.auto_switch_default"] = "Because you just deleted the current profile, it has been switched back to: [default]",
        ["profile.switch_success"] = "Profile switched to: [{name}]",
        ["profile.create_success"] = "New Profile created and switched to: [{name}]",
        ["profile.default_success"] = "Profile switched back to the default: [default]",
        ["profile.list_title"] = "NeedGreedLoot Profile List",
        ["profile.in_use"] = "(active)",
        ["profile.no_pending"] = "There is no pending Profile deletion to confirm.",
        ["profile.delete_timeout"] = "Profile [{name}] deletion timed out and was cancelled.",

        ["manual.title"] = "Manual Entry & Edit",
        ["manual.subtitle"] = "Edit selected Loot Log, or add new if unselected.",
        ["manual.item_link"] = "Item Link",
        ["manual.player_name"] = "Player Name",
        ["manual.roll_points"] = "Roll Points",
        ["manual.type_need_greed"] = "Type (Need/Greed)",
        ["manual.winner_optional"] = "Winner Name (Optional)",
        ["manual.load_selected"] = "Load Selected",
        ["manual.save_record"] = "Save Record",

        ["core.permission.not_in_raid"] = "You are not in a raid.",
        ["core.permission.not_leader"] = "You are not the raid leader or assistant, and cannot start or manage loot rolls.",
        ["core.roll.already_running"] = "A roll is already in progress.",
        ["core.roll.invalid_item"] = "Could not recognize the item link.",
        ["core.roll.hover_required"] = "Please hover over the item in your bag or equipped slot.",
        ["core.roll.need_priority"] = "Need Priority",
        ["core.roll.need_roll"] = "Need Roll",
        ["core.roll.greed_roll"] = "Greed Roll",
        ["core.roll.start"] = "{mode} {item} is open for rolls! Use /roll (countdown {seconds} seconds)",
        ["core.roll.warning"] = "{mode} {item} final countdown {seconds} seconds!",
        ["core.roll.winner"] = "Congratulations {player} rolled {roll} and won {item} via {type}!",
        ["core.roll.no_winner"] = "{item} ended without any rolls.",
        ["core.roll.need_used"] = "[NGL Profile: {profile}] {player} has used their Need opportunity.",
        ["core.roll.greed_count"] = "[NGL Profile: {profile}] {player} won Greed (+1, total: {count}).",
        ["core.roll.reroll_need"] = "Need Roll",
        ["core.roll.reroll_greed"] = "Greed Roll",
        ["core.roll.reroll_all"] = "Need Priority",

        ["core.help.title"] = "=== [NeedGreedLoot] Command List ===",
        ["core.help.current_profile"] = "Current Profile: {profile}",
        ["core.help.ngl"] = "/ngl - Need Priority (players with remaining Need wins over Greed)",
        ["core.help.ngln"] = "/ngln - Need Roll (only players with remaining Need can participate)",
        ["core.help.nglg"] = "/nglg - Greed Roll (everyone may participate, counts as Greed, does not consume Need)",
        ["core.command.ui_missing"] = "Control panel is not loaded yet. Please reload the interface.",
        ["core.command.no_profile"] = "There is no pending Profile deletion to confirm.",
        ["core.command.invalid_timer"] = "Please enter a valid number of seconds (at least 5), for example: /ngl timer 30",
        ["core.command.profile_switch_required"] = "Please enter the Profile name you want to switch to. Current profile: {name}",
        ["core.command.profile_create_required"] = "Please enter the Profile name you want to create. Example: /ngl profile new 25man",
        ["core.command.profile_missing"] = "Profile [{name}] does not exist. You can create it with: /ngl profile new {name}",
        ["core.command.profile_delete_required"] = "Please enter the Profile name to delete. Example: /ngl profile delete 25man",
        ["core.command.profile_delete_timeout"] = "Delete Profile [{name}] timed out and was cancelled.",
        ["core.command.profile_delete_confirm"] = "Warning: Are you sure you want to delete Profile [{name}]?",
        ["core.command.profile_delete_prompt"] = "Please enter /ngl yes within 30 seconds to confirm deletion.",
        ["core.command.profile_current_context"] = "(currently in use)",
        ["core.command.profile_delete_failed"] = "Profile [{name}] does not exist and cannot be deleted.",
        ["core.command.profile_keep_default"] = "Default profile restored automatically after deleting the current one.",
        ["core.command.debug_status"] = "Debug mode {status}",
        ["core.command.reset_done"] = "Reset all player records for the current Profile [{name}].",
        ["core.command.list_title"] = "NGL Record - Profile: {name}",
        ["core.command.list_empty"] = "The current Profile [{name}] has no player records yet.",
        ["core.command.no_active_roll"] = "There is no roll currently in progress.",
        ["core.command.roll_ended_early"] = "{mode} leader ended the countdown early. Resolving now...",
        ["core.command.roll_aborted"] = "{mode} leader stopped the roll for {item}. This roll will not be counted.",
        ["core.command.roll_aborted_done"] = "The current roll was cancelled and no records were updated.",
        ["core.command.player_not_found"] = "Player {name} has already used their Need eligibility; this roll cannot count in Need-only mode.",
        ["core.command.roll_recorded"] = "Recorded {player}: {roll} points ({type})",
        ["core.command.player_in_team"] = "Player {name} is already in the team; no duplicate entry added.",
        ["core.help.ngl_timer"] = "/ngl [seconds] / /ngln [seconds] / /nglg [seconds] - start a roll on the hovered item with the selected duration",
        ["core.help.ngl_item"] = "/ngl [item] [seconds] - start a roll for the specified item link",
        ["core.help.profile_switch"] = "/ngl profile [name] - switch to the specified Profile",
        ["core.help.profile_new"] = "/ngl profile new [name] - create a new Profile and switch to it",
        ["core.help.profile_delete"] = "/ngl profile delete [name] - prepare to delete a Profile (requires /ngl yes to confirm)",
        ["core.help.yes"] = "/ngl yes - confirm deletion of a pending Profile",
        ["core.help.default"] = "/ngl default - switch back to the default Profile",
        ["core.help.profiles"] = "/ngl profiles - list all existing Profiles",
        ["core.help.list"] = "/ngl list - view the current Profile's need/greed history and usage", 
        ["core.help.reset"] = "/ngl reset - clear all data for the current Profile",
        ["core.help.timer"] = "/ngl timer [seconds] - set the global default countdown value (current: {seconds} sec)",
        ["core.help.stop"] = "/ngl stop - end the current roll early and resolve the result",
        ["core.help.abort"] = "/ngl abort - stop the current roll without resolving or counting",
        ["core.help.ui"] = "/ngl ui - open the NeedGreedLoot control panel",
        ["core.help.debug"] = "/ngl debug - toggle Debug output",
        ["core.help.help"] = "/ngl help - display this commands menu",
        ["core.help.footer"] = "========================================",
        ["core.help.profile_current"] = "Current Profile: {profile}",
    },
    zhTW = {
        ["ui.title"] = "NeedGreedLoot 控制面板",
        ["ui.tabs.scan"] = "掃描開骰",
        ["ui.tabs.loot_log"] = "戰利品記錄",
        ["ui.tabs.profile"] = "設定檔",
        ["ui.tabs.settings"] = "設定",
        ["ui.tabs.manual"] = "Manual",

        ["settings.title"] = "設定",
        ["settings.timer"] = "全局計時器 (秒)",
        ["settings.apply"] = "套用",
        ["settings.language"] = "語言",
        ["settings.debug"] = "Debug 模式: {state}",
        ["settings.debug.enabled"] = "開啓",
        ["settings.debug.disabled"] = "關閉",
        ["settings.debug.toggle"] = "Debug 模式 {state}.",
        ["settings.timer.saved"] = "全局計時器設為 {value} 秒.",
        ["settings.scanner_category"] = "掃描分類",
        ["settings.scanner_category.none"] = "無分類",
        ["settings.scanner_category.type"] = "裝備類型",
        ["settings.scanner_category.trade_time"] = "剩餘可交易時間",
        ["settings.scanner_boe"] = "顯示裝備後綁定的裝備",
        ["settings.scanner_quality"] = "最低裝備品質",
        ["settings.scanner_quality.all"] = "全部",
        ["settings.scanner_quality.uncommon"] = "優秀",
        ["settings.scanner_quality.rare"] = "稀有",
        ["settings.scanner_quality.epic"] = "史詩",
        ["settings.scanner_quality.legendary"] = "傳說",

        ["common.enabled"] = "開啓",
        ["common.disabled"] = "關閉",
        ["common.warning"] = "警告",
        ["common.ok"] = "確定",
        ["common.yes"] = "是",
        ["common.no"] = "否",
        ["common.unknown"] = "未知",
        ["common.second"] = "秒",

        ["scanner.title"] = "掃描與發起擲骰",
        ["scanner.category"] = "掃描分類",
        ["scanner.min_quality"] = "最低品質裝備",
        ["scanner.current_item"] = "當前裝備",
        ["scanner.no_item_selected"] = "尚未選擇裝備",
        ["scanner.seconds"] = "秒",
        ["scanner.bag_items"] = "背包裝備",
        ["scanner.scan_bag"] = "掃描背包",
        ["scanner.need_priority"] = "需求優先",
        ["scanner.need_roll"] = "需求擲骰",
        ["scanner.greed_roll"] = "貪婪擲骰",
        ["scanner.end_early"] = "提前結束",
        ["scanner.abort"] = "終止",
        ["scanner.selected_slot"] = "已選取背包 {bag}, 格位 {slot}",

        ["loot.title"] = "戰利品記錄",
        ["loot.search"] = "搜尋裝備或 UUID",
        ["loot.all"] = "全部",
        ["loot.unassigned"] = "未分配",
        ["loot.assigned"] = "已分配",
        ["loot.select_detail"] = "選擇一件裝備查看明細",
        ["loot.player"] = "玩家",
        ["loot.server"] = "伺服器",
        ["loot.class"] = "職業",
        ["loot.type"] = "類型",
        ["loot.points"] = "點數",
        ["loot.choose_player"] = "選擇團隊玩家",
        ["loot.assign_greed"] = "分配貪婪",
        ["loot.assign_need"] = "分配需求",
        ["loot.reroll"] = "重擲: ",
        ["loot.reroll_all"] = "需求優先",
        ["loot.reroll_need"] = "需求擲骰",
        ["loot.reroll_greed"] = "貪婪擲骰",
        ["loot.status_unassigned"] = "狀態: 尚未指定勝者",
        ["loot.status_winner"] = "贏家: {player} ({type})",
        ["loot.uuid"] = "UUID: {uuid}",
        ["loot.delete_confirm"] = "確定要刪除這筆戰利品記錄嗎？此操作無法復原。",
        ["loot.delete"] = "刪除",
        ["loot.cancel"] = "取消",
        ["loot.need"] = "需求",
        ["loot.greed"] = "貪婪",

        ["profile.manager"] = "設定檔管理",
        ["profile.name"] = "設定檔名稱",
        ["profile.create"] = "建立",
        ["profile.copy_current"] = "複製目前",
        ["profile.reset"] = "重置",
        ["profile.delete"] = "刪除",
        ["profile.existing"] = "已建立的設定檔",
        ["profile.need_status"] = "需求使用狀態",
        ["profile.team_note"] = "團隊成員優先；灰階名稱表示目前不在團隊",
        ["profile.using"] = "{name} (使用中)",
        ["profile.used"] = "已需求",
        ["profile.unused"] = "未需求",
        ["profile.delete_confirm"] = "確定要刪除設定檔 [{name}] 嗎？此操作無法復原。",
        ["profile.reset_confirm"] = "確定要重置目前設定檔嗎？所有玩家與戰利品記錄都會被清除。",
        ["profile.not_found"] = "找不到名為 [{name}] 的設定檔，無法刪除。",
        ["profile.no_name"] = "請輸入欲切換的設定檔名稱！目前使用中：{name}",
        ["profile.no_create_name"] = "請輸入欲建立的設定檔名稱！範例：/ngl profile new 25人團",
        ["profile.exists"] = "設定檔 [{name}] 已經存在！切換請用：/ngl profile {name}",
        ["profile.deleted"] = "已成功刪除設定檔：[{name}]",
        ["profile.auto_switch_default"] = "由於剛刪除了當前正使用的設定檔，已自動切換回：[default]",
        ["profile.switch_success"] = "已成功切換至設定檔：[{name}]",
        ["profile.create_success"] = "已成功建立並切換至新設定檔：[{name}]",
        ["profile.default_success"] = "已成功切換回預設設定檔：[default]",
        ["profile.list_title"] = "NeedGreedLoot 設定檔清單",
        ["profile.in_use"] = "(使用中)",
        ["profile.no_pending"] = "沒有待刪除的設定檔！",
        ["profile.delete_timeout"] = "刪除設定檔 [{name}] 已超時取消。",

        ["manual.title"] = "Manual Entry & Edit",
        ["manual.subtitle"] = "Edit selected Loot Log, or add new if unselected.",
        ["manual.item_link"] = "Item Link",
        ["manual.player_name"] = "Player Name",
        ["manual.roll_points"] = "Roll Points",
        ["manual.type_need_greed"] = "Type (Need/Greed)",
        ["manual.winner_optional"] = "Winner Name (Optional)",
        ["manual.load_selected"] = "Load Selected",
        ["manual.save_record"] = "Save Record",

        ["core.permission.not_in_raid"] = "您目前不在團隊中，無法使用此功能",
        ["core.permission.not_leader"] = "您不是團隊隊長或團隊助手，無權發起或管理裝備分配！",
        ["core.roll.already_running"] = "目前已有裝備正在進行擲骰中！",
        ["core.roll.invalid_item"] = "無法識別裝備連結！",
        ["core.roll.hover_required"] = "請將滑鼠指在背包或裝備欄的物品上方！",
        ["core.roll.need_priority"] = "【需求優先】",
        ["core.roll.need_roll"] = "【需求擲骰】",
        ["core.roll.greed_roll"] = "【貪婪擲骰】",
        ["core.roll.start"] = "{mode} {item} 開放擲骰！請使用 /roll (倒數 {seconds} 秒)",
        ["core.roll.warning"] = "{mode} {item} 倒數最後 {seconds} 秒！",
        ["core.roll.winner"] = "恭喜 {player} 以 {roll} 點 {type} 獲得 {item}！",
        ["core.roll.no_winner"] = "{item} 擲骰結束，無人擲骰。",
        ["core.roll.need_used"] = "[NGL Profile: {profile}] 已消耗 {player} 的需求機會。",
        ["core.roll.greed_count"] = "[NGL Profile: {profile}] 已記錄 {player} 貪婪獲勝 (+1，累計: {count} 次)。",
        ["core.roll.reroll_need"] = "需求擲骰",
        ["core.roll.reroll_greed"] = "貪婪擲骰",
        ["core.roll.reroll_all"] = "需求優先",

        ["core.help.title"] = "=== [NeedGreedLoot 一需多貪助手] 指令表 ===",
        ["core.help.current_profile"] = "[目前設定檔: {profile}]",
        ["core.help.ngl"] = " |cffffd100/ngl|r - 需求優先 (尚有需求者為需求，已消耗者為貪婪)",
        ["core.help.ngln"] = " |cffffd100/ngln|r - 需求擲骰 (僅未消耗需求的玩家可參與，已消耗者 Roll 無效)",
        ["core.help.nglg"] = " |cffffd100/nglg|r - 貪婪擲骰 (所有人皆可參與且全算貪婪，不消耗需求，記錄貪婪次數)",
        ["core.help.ngl_timer"] = " |cffffd100/ngl [秒數]|r / |cffffd100/ngln [秒數]|r / |cffffd100/nglg [秒數]|r - 對懸停物品發起指定秒數開骰",
        ["core.help.ngl_item"] = " |cffffd100/ngl [裝備] [秒數]|r - 對指定裝備連結發起開骰",
        ["core.help.profile_switch"] = " |cffffd100/ngl profile [名稱]|r - 切換至指定設定檔",
        ["core.help.profile_new"] = " |cffffd100/ngl profile new [名稱]|r - 建立新的設定檔並自動切換過去",
        ["core.help.profile_delete"] = " |cffffd100/ngl profile delete [名稱]|r - 準備刪除指定的設定檔 (需輸入 /ngl yes 確認)",
        ["core.help.yes"] = " |cffffd100/ngl yes|r - 確認刪除處於等待狀態的設定檔",
        ["core.help.default"] = " |cffffd100/ngl default|r - 切換回預設 (default) 設定檔",
        ["core.help.profiles"] = " |cffffd100/ngl profiles|r - 列出所有已建立的設定檔清單",
        ["core.help.list"] = " |cffffd100/ngl list|r - 查看目前設定檔玩家需求狀態、貪婪次數與獲獎歷史",
        ["core.help.reset"] = " |cffffd100/ngl reset|r - 重置目前設定檔所有玩家紀錄",
        ["core.help.timer"] = " |cffffd100/ngl timer [秒數]|r - 設定全域預設倒數秒數 (目前: {seconds} 秒)",
        ["core.help.stop"] = " |cffffd100/ngl stop|r - 提前結束當前開骰並立即結算",
        ["core.help.abort"] = " |cffffd100/ngl abort|r - 終止當前開骰，不結算且不計數",
        ["core.help.ui"] = " |cffffd100/ngl ui|r - 開啟 NeedGreedLoot 控制面板",
        ["core.help.debug"] = " |cffffd100/ngl debug|r - 開關 Debug 除錯模式訊息輸出",
        ["core.help.help"] = " |cffffd100/ngl help|r - 顯示此指令說明選單",
        ["core.help.footer"] = "|cff00ff00========================================|r",
        ["core.help.profile_label"] = "設定檔列表",
    },
}

local function getNormalizedLocale(code)
    if not code then
        return NGL.Locale.fallback
    end

    local normalized = string.lower(code)
    if normalized == "zhtw" or normalized == "zh-tw" or normalized == "zhhk" or normalized == "zh-hk" then
        return "zhTW"
    end
    if normalized == "zhcn" or normalized == "zh-cn" then
        return "zhTW"
    end
    return "enUS"
end

function NGL.GetClientLocale()
    local locale = GetLocale() or NGL.Locale.fallback
    return getNormalizedLocale(locale)
end

function NGL.GetLocale()
    local locale = NGL_Locale or NGL.GetClientLocale()
    if NGL.Locale.translations[locale] then
        return locale
    end
    return NGL.Locale.fallback
end

function NGL.SetLocale(code)
    local locale = getNormalizedLocale(code)
    NGL_Locale = locale

    if NGL.RefreshLocaleUI then
        NGL.RefreshLocaleUI()
    end

    return locale
end

local function replaceParameters(text, data)
    if not text then
        return ""
    end
    if type(data) ~= "table" then
        return text
    end

    return (text:gsub("{(%w+)}", function(key)
        if data[key] ~= nil then
            return tostring(data[key])
        end
        return "{" .. key .. "}"
    end))
end

function NGL.L(key, data)
    local locale = NGL.GetLocale()
    local translationSet = NGL.Locale.translations[locale] or NGL.Locale.translations[NGL.Locale.fallback]
    local text = translationSet and translationSet[key]

    if not text and NGL.Locale.translations[NGL.Locale.fallback] then
        text = NGL.Locale.translations[NGL.Locale.fallback][key]
    end

    if not text then
        return key
    end

    return replaceParameters(text, data)
end
