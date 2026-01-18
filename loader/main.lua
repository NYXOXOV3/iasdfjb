-- =========================================================
-- NYXHUB – FISH IT
-- MAIN LOADER (EXECUTOR SAFE)
-- =========================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- =========================================================
-- BASE URL (WAJIB RAW TEXT, BUKAN WEBSITE)
-- =========================================================
local BASE_URL = "https://raw.githubusercontent.com/NYXOXOV3/iasdfjb/main"

-- helper require dari URL
local function requireURL(path)
    local url = BASE_URL .. "/" .. path
    local src = game:HttpGet(url)
    local fn, err = loadstring(src)
    if not fn then
        error("[NYXHUB] Load failed: " .. path .. "\n" .. err)
    end
    return fn()
end

-- =========================================================
-- SECURITY LOADER
-- =========================================================
local SecurityLoader = requireURL("security/SecurityLoader.lua")

-- =========================================================
-- LOAD APIs
-- =========================================================
local APIs = {
    Info          = SecurityLoader:Load(requireURL("methode/info/InfoAPI.lua"), "INFO"),
    Player        = SecurityLoader:Load(requireURL("methode/player/PlayerAPI.lua"), "PLAYER"),
    Fishing       = SecurityLoader:Load(requireURL("methode/fishing/FishingAPI.lua"), "FISHING"),
    Automatic     = SecurityLoader:Load(requireURL("methode/automatic/AutomaticAPI.lua"), "AUTOMATIC"),
    Teleport      = SecurityLoader:Load(requireURL("methode/teleport/TeleportAPI.lua"), "TELEPORT"),
    Shop          = SecurityLoader:Load(requireURL("methode/shop/ShopAPI.lua"), "SHOP"),
    Exclusive     = SecurityLoader:Load(requireURL("methode/exclusive/ExclusiveAPI.lua"), "EXCLUSIVE"),
    Quest         = SecurityLoader:Load(requireURL("methode/quest/QuestAPI.lua"), "QUEST"),
    Event         = SecurityLoader:Load(requireURL("methode/event/EventAPI.lua"), "EVENT"),
    Tools         = SecurityLoader:Load(requireURL("methode/tools/ToolsAPI.lua"), "TOOLS"),
    Webhook       = SecurityLoader:Load(requireURL("methode/webhook/WebhookAPI.lua"), "WEBHOOK"),
    Configuration = SecurityLoader:Load(requireURL("methode/configuration/ConfigurationAPI.lua"), "CONFIGURATION"),
}

-- =========================================================
-- UI LIB
-- =========================================================
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

-- =========================================================
-- WINDOW
-- =========================================================
local Window = WindUI:CreateWindow({
    Title = "NYXHUB - Fish It",
    Icon = "rbxassetid://137263312772667",
    Folder = "NYXHUB",
    Size = UDim2.fromOffset(600, 360),
    MinSize = Vector2.new(560, 250),
    MaxSize = Vector2.new(950, 760),
    Transparent = true,
    Theme = "Violet",
    Resizable = true,
    SideBarWidth = 190,
    HideSearchBar = true,
    ScrollBarEnabled = true,
})

Window:Tag({
    Title = "v1.0.3",
    Color = Color3.fromRGB(0,255,0),
    Radius = 16,
})

-- =========================================================
-- LOAD UI TABS
-- =========================================================
local function loadTab(path, api)
    pcall(function()
        requireURL(path)(Window, api, WindUI)
    end)
end

loadTab("ui/InfoTab.lua", APIs.Info)
loadTab("ui/PlayerTab.lua", APIs.Player)
loadTab("ui/FishingTab.lua", APIs.Fishing)
loadTab("ui/AutomaticTab.lua", APIs.Automatic)
loadTab("ui/TeleportTab.lua", APIs.Teleport)
loadTab("ui/ShopTab.lua", APIs.Shop)
loadTab("ui/ExclusiveTab.lua", APIs.Exclusive)
loadTab("ui/QuestTab.lua", APIs.Quest)
loadTab("ui/EventTab.lua", APIs.Event)
loadTab("ui/ToolsTab.lua", APIs.Tools)
loadTab("ui/WebhookTab.lua", APIs.Webhook)
loadTab("ui/ConfigurationTab.lua", APIs.Configuration)

-- =========================================================
-- GLOBAL FLAG
-- =========================================================
getgenv().NYXHUB_LOADED = true
print("✅ NYXHUB LOADED (EXECUTOR MODE)")
