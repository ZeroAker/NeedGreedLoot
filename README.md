# NeedGreedLoot

NeedGreedLoot is a World of Warcraft addon for raid loot distribution. It helps raid leaders and assistants manage Need/Greed rolls, scan bag items, track winner history, and keep separate saved profiles for different groups or runs.

## Features

- Scan bag items and select a target loot item
- Start rolls in three modes:
  - Need Priority
  - Need Roll
  - Greed Roll
- Validate rolls using the expected WoW 1–100 range
- Record player roll results and winner history
- Track per-player Need usage and Greed counts
- Maintain multiple saved profiles
- Support locale switching for English and Traditional Chinese
- Include minimap toggle and main UI control panel

## UI Tabs

- Scan & Roll
- Loot Log
- Profile
- Settings

## Installation

1. Download the addon folder.
2. Place the full NeedGreedLoot folder into your WoW AddOns directory.
3. Reload the interface.
4. Use /ngl ui to open the control panel.

## Commands

- /ngl
  - Start a Need Priority roll on the hovered item
- /ngln
  - Start a Need Roll
- /nglg
  - Start a Greed Roll
- /ngl [seconds]
  - Start a roll on the hovered item with a specific duration
- /ngl [itemLink] [seconds]
  - Start a roll for a specified item
- /ngl help
  - Show the command list
- /ngl stop
  - End the current roll early and resolve it
- /ngl abort
  - Cancel the current roll without recording results
- /ngl timer [seconds]
  - Set the default global timer
- /ngl profile [name]
  - Switch to a profile
- /ngl profile new [name]
  - Create a new profile and switch to it
- /ngl profile delete [name]
  - Prepare to delete a profile
- /ngl default
  - Return to the default profile
- /ngl profiles
  - List all existing profiles
- /ngl list
  - Show current player Need/Greed history and usage
- /ngl reset
  - Clear the current profile data
- /ngl debug
  - Toggle debug output
- /ngl ui
  - Open the addon panel

## Roll Modes

### Need Priority
- Players who still have a valid Need usage are prioritized.
- Players who already used Need are treated as Greed.

### Need Roll
- Only players with remaining Need availability can participate.
- Used Need players cannot join the roll.

### Greed Roll
- Everyone may participate.
- All rolls count as Greed.
- Greed counts are recorded for each player.

## Roll Validation

The addon follows WoW roll output patterns and only accepts valid 1–100 roll ranges.

Examples of accepted rolls:
- Ancient One rolls 18 (1-100)

Examples rejected:
- Ancient One rolls 18 (1-90)
- Ancient One rolls 18 (0-100)
- Ancient One rolls 18 (5-100)

## Profile Management

Profiles let you separate information for different groups, raid contexts, or characters.

Examples:
- /ngl profile new Mythic
- /ngl profile Mythic
- /ngl profile delete Mythic
- /ngl default

## Locale Support

The addon supports:
- English
- Traditional Chinese

The locale is selected automatically from the client language by default, and it can also be changed from the Settings tab.

## Permissions and Notes

- Only raid leaders or assistants can start or manage rolls.
- The addon requires the player to be in a raid or group.
- Roll parsing depends on WoW system output format.
- Only valid 1–100 rolls are counted.

---

# NeedGreedLoot 中文簡介

NeedGreedLoot 是一個用於團隊裝備分配的 WoW 插件，主要用來處理團隊中的 Need / Greed 開骰、裝備掃描、勝出記錄與多設定檔管理。

## 功能

- 掃描背包中的裝備並選擇目標物品
- 支援以下三種開骰模式：
  - 需求優先
  - 需求擲骰
  - 貪婪擲骰
- 依照 WoW 的 1–100 roll 範圍進行驗證
- 記錄每位玩家的擲骰結果與獲勝歷史
- 追蹤每位玩家的需求使用狀態與貪婪次數
- 支援多個設定檔分開管理
- 支援英文與繁體中文語系切換
- 提供小地圖按鈕與主控制面板

## 安裝方式

1. 下載插件資料夾。
2. 將整個 NeedGreedLoot 資料夾放入 WoW 的 AddOns 目錄。
3. 重新載入介面。
4. 使用 /ngl ui 開啟控制面板。

## 指令

- /ngl
  - 對懸停物品啟動需求優先開骰
- /ngln
  - 啟動需求擲骰
- /nglg
  - 啟動貪婪擲骰
- /ngl [秒數]
  - 以指定秒數對懸停物品開骰
- /ngl [裝備連結] [秒數]
  - 對指定物品開骰
- /ngl help
  - 顯示指令列表
- /ngl stop
  - 提前結束目前開骰並結算
- /ngl abort
  - 中止目前開骰且不記錄結果
- /ngl timer [秒數]
  - 設定全域倒數秒數
- /ngl profile [名稱]
  - 切換設定檔
- /ngl profile new [名稱]
  - 建立新設定檔並切換
- /ngl profile delete [名稱]
  - 準備刪除設定檔
- /ngl default
  - 切回預設設定檔
- /ngl profiles
  - 列出全部設定檔
- /ngl list
  - 顯示目前設定檔內玩家的需求 / 貪婪歷史
- /ngl reset
  - 清除目前設定檔資料
- /ngl debug
  - 切換除錯輸出
- /ngl ui
  - 打開插件介面

## 分配模式

### 需求優先
- 仍可使用需求的玩家優先。
- 已耗盡需求者視為貪婪。

### 需求擲骰
- 只有仍可使用需求的玩家可參與。
- 已用掉需求的玩家無法參與。

### 貪婪擲骰
- 所有人都可以參與。
- 全部計為貪婪。
- 會記錄貪婪次數。

## 設定檔管理

設定檔可用來分開不同團隊、活動或角色的資料。

範例：
- /ngl profile new 25人團
- /ngl profile 25人團
- /ngl profile delete 25人團
- /ngl default

這適合在自動解析失敗時補錄或修正記錄。

## 語言支援

目前支援：
- 英文
- 繁體中文

語系會依照客戶端語言預設，或可在設定頁面手動切換。

## 注意事項

- 只有隊長或助理可發起或管理開骰。
- 必須在團隊或團隊群組中才能使用相關功能。
- 插件依賴 WoW 原生的 roll 輸出格式。
- 只有符合 1–100 範圍的 roll 會被計算與記錄。
