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

        ["common.enabled"] = "Enabled",
        ["common.disabled"] = "Disabled",
        ["common.warning"] = "Warning",
        ["common.ok"] = "OK",

        ["placeholder.item"] = "{item}",
        ["placeholder.player"] = "{player}",
        ["example.assignment"] = "{item} has been assigned to {player}",
        ["example.assignment.zh"] = "{item} 已分配給 {player}",
    },
    zhTW = {
        ["ui.title"] = "NeedGreedLoot 控制面板",
        ["ui.tabs.scan"] = "掃描開骰",
        ["ui.tabs.loot_log"] = "Loot Log",
        ["ui.tabs.profile"] = "Profile",
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

        ["common.enabled"] = "開啓",
        ["common.disabled"] = "關閉",
        ["common.warning"] = "警告",
        ["common.ok"] = "確定",

        ["placeholder.item"] = "{item}",
        ["placeholder.player"] = "{player}",
        ["example.assignment"] = "{item} 已分配給 {player}",
        ["example.assignment.en"] = "{item} has been assigned to {player}",
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
