English Version
NeedGreedLoot
NeedGreedLoot is a World of Warcraft loot distribution helper for raid and dungeon groups. It helps track Need/Greed rolls, scan available items in the bag, announce roll windows, and record loot history for later review.

Core logic and UI are implemented in Core.lua, ScannerPanel.lua, ManualPanel.lua, and MainUI.lua.

Features
Scan the bag for lootable items
Start Need / Greed / Need-Priority roll sessions
Parse player roll results automatically
Accept only valid roll values within 1–100
Record player Need status and Greed counts
Save loot history and winners
Support multiple profiles
Manual entry and edit for missing or incorrect records
Installation
Download the addon folder
Place the full NeedGreedLoot folder into your WoW AddOns directory
Reload the interface
Run /ngl ui to open the panel
Commands
/ngl
Start a Need-Priority roll

/ngln
Start a Need-only roll

/nglg
Start a Greed-only roll

/ngl [seconds]
Start a roll on the hovered item for the specified duration

/ngl [item link] [seconds]
Start a roll on a specific item

/ngl help
Show the command list

/ngl stop
End the current roll immediately and resolve it

/ngl abort
Cancel the current roll without recording results

/ngl timer [seconds]
Set the default countdown duration

/ngl profile [name]
Switch to a profile

/ngl profile new [name]
Create a new profile

/ngl default
Switch back to the default profile

/ngl list
View current Need status, Greed counts, and award history

/ngl reset
Reset current profile data

Roll Modes
Need-Priority
Players who have not spent their Need roll are prioritized
Players who already used Need are treated as Greed
Need Roll
Only players with remaining Need eligibility can participate
Used Need players are ignored
Greed Roll
Everyone may participate
No Need is spent
Greed counts are tracked
Roll Validation
The addon parses roll outputs and accepts only rolls whose range is explicitly 1–100.

Valid example:

Ancient One rolls 18 (1-100)
Invalid examples:

Ancient One rolls 18 (1-90)
Ancient One rolls 18 (0-100)
Ancient One rolls 18 (5-100)
Only values matching the exact 1–100 range are accepted and counted.

Scan and Roll Flow
Click “Scan Bag”
Pick the target item
Choose:
Need Priority
Need Roll
Greed Roll
The addon announces the roll in raid chat
Players use /roll
The addon parses the result
The winner is announced and recorded
Profile Management
Profiles allow you to separate data for different groups, characters, or raid contexts.

Examples:

/ngl profile new Mythic
/ngl profile Mythic
/ngl profile delete Mythic
/ngl default
Manual Record Editing
The manual panel allows you to:

Enter an item link
Input player name
Enter roll value
Choose Need or Greed
Mark winner manually
This is useful when:

automatic parsing fails
data needs correction
a record must be added manually
Notes
Only party/raid leaders or assistants can start a roll
Users must be in a group to use the addon’s roll functions
Roll parsing depends on the expected WoW system output format
Only valid 1–100 roll ranges are counted


中文版本
NeedGreedLoot
NeedGreedLoot 是一個用於團隊裝備分配的 WoW 插件，適合在 raid / dungeon / 活動中快速處理需求、貪婪與 roll 結算。它會掃描背包中的可分配物品，支援開骰、結算、歷史紀錄、Profile 管理與手動補錄。

相關主要實作位於 Core.lua、ScannerPanel.lua、ManualPanel.lua 與 MainUI.lua。

功能概覽
掃描背包中可供分配的裝備
支援需求優先 / 需求擲骰 / 貪婪擲骰
自動解析玩家 roll 結果
只接受括號範圍為 1–100 的有效 roll
記錄每位玩家的需求狀態與貪婪次數
保存每次分配歷史
支援多個 Profile 分開管理
提供手動修正與補錄功能
安裝方式
下載插件資料夾
將整個 NeedGreedLoot 資料夾放入 WoW 的 AddOns 目錄
重新載入介面
輸入 /ngl ui 開啟面板
基本指令
/ngl
啟動需求優先開骰

/ngln
啟動需求擲骰

/nglg
啟動貪婪擲骰

/ngl [秒數]
以指定秒數開啟當前懸停物品的擲骰

/ngl [裝備連結] [秒數]
直接對指定物品開骰

/ngl help
顯示指令說明

/ngl stop
提前結束當前開骰並結算

/ngl abort
中止當前開骰，不結算、不記錄

/ngl timer [秒數]
設定全域預設倒數秒數

/ngl profile [名稱]
切換 Profile

/ngl profile new [名稱]
建立新 Profile

/ngl default
切回 default Profile

/ngl list
查看需求狀態、貪婪次數與歷史

/ngl reset
重置當前 Profile 的資料

角色與分配模式
需求優先
未消耗需求的玩家優先
已消耗需求者視為貪婪
若仍有需求玩家存在，需求玩家勝出
需求擲骰
只允許尚未消耗需求的玩家參與
已消耗需求玩家的 roll 無效
貪婪擲骰
所有人都可參與
全部視為貪婪
會記錄貪婪次數
Roll 規則
插件會解析玩家的 /roll 結果，並要求 roll 的範圍必須是 1–100。

接受格式範例：

古萊哈姆擲出18（1-100）
不接受的範例：

古萊哈姆擲出18（1-90）
古萊哈姆擲出18（0-100）
古萊哈姆擲出18（5-100）
只有括號內明確為 1–100 的 roll 才會被記錄與計入結算。

扫描與分配流程
點擊「掃描背包」
選擇目標物品
按下「需求優先」「需求擲骰」或「貪婪擲骰」
系統發布團隊警告並開始倒數
玩家使用 /roll
插件解析結果並在結束時顯示勝出者
Profile 管理
插件支援多個 Profile，適合區分不同團隊、不同角色或不同活動。

常用操作：

/ngl profile new 25人團
/ngl profile 25人團
/ngl profile delete 25人團
/ngl default
手動修正
在手動紀錄面板中，可：

手動輸入物品連結
輸入玩家名稱
輸入 roll 點數
指定 Need / Greed
設定獲勝者
這適合補錄遺失紀錄或修正結算結果。

注意事項
只有隊長或助理可發起開骰
若使用者不在團隊內，插件會拒絕執行
需要正確使用 WoW 原生 roll 格式，插件才能解析
只有符合 1–100 範圍的 roll 才會計入分配
