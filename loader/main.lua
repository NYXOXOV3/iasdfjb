-- =========================================================
-- NYXHUB – FISH IT
-- MAIN LOADER (EXECUTOR SAFE + DEBUG)
-- =========================================================

-- =========================
-- GLOBAL DEBUG
-- =========================
local DEBUG = true

local function dprint(...)
    if DEBUG then
        print("[NYXHUB][DEBUG]", ...)
    end
end

local function dwarn(...)
    warn("[NYXHUB][WARN]", ...)
end

-- =========================
-- WAIT GAME
-- =========================
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- =========================
-- BASE URL (RAW TEXT ONLY)
-- =========================
local BASE_URL = "https://raw.githubusercontent.com/NYXOXOV3/iasdfjb/main"

-- =========================
-- REQUIRE FROM URL (SAFE)
-- =========================
local function requireURL(path)
    local url = BASE_URL .. "/" .. path
    dprint("Requesting:", url)

    local ok, src = pcall(game.HttpGet, game, url)
    if not ok then
        dwarn("HttpGet FAILED:", path)
        error("[NYXHUB] HttpGet failed: " .. url)
    end

    if not src or src == "" then
        dwarn("Empty response:", path)
        error("[NYXHUB] Empty response: " .. url)
    end

    -- HTML DETECTION (KRUSIAL)
    if src:sub(1, 1) == "<" then
        dwarn("HTML detected instead of Lua:", path)
        print(src:sub(1, 300))
        error("[NYXHUB] HTML response detected: " .. url)
    end

    local fn, err = loadstring(src)
    if not fn then
        dwarn("Compile error:", path)
        error("[NYXHUB] Compile error in " .. path .. "\n" .. tostring(err))
    end

    local result
    local okRun, runErr = pcall(function()
        result = fn()
    end)

    if not okRun then
        dwarn("Runtime error in module:", path)
        error("[NYXHUB] Runtime error in " .. path .. "\n" .. tostring(runErr))
    end

    if result == nil then
        dwarn("Module returned nil:", path)
        error("[NYXHUB] Module did not return value: " .. path)
    end

    dprint("Loaded OK:", path, "type =", type(result))
    return result
end

-- =========================
-- LOAD SECURITY LOADER
-- =========================
dprint("Loading SecurityLoader...")
local SecurityLoader = requireURL("security/SecurityLoader.lua")

-- =========================
-- LOAD APIs (DEBUGGED)
-- =========================
dprint("Loading APIs...")

local APIs = {}

local function loadAPI(tag, path)
    dprint("API ->", tag)
    local api = requireURL(path)
    local loaded = SecurityLoader:Load(api, tag)
    if not loaded then
        dwarn("API FAILED:", tag)
    end
    return loaded
end

APIs.Info          = loadAPI("INFO", "methode/info/InfoAPI.lua")
APIs.Player        = loadAPI("PLAYER", "methode/player/PlayerAPI.lua")
--APIs.Fishing       = loadAPI("FISHING", "methode/fishing/FishingAPI.lua")
--APIs.Automatic     = loadAPI("AUTOMATIC", "methode/automatic/AutomaticAPI.lua")
--APIs.Teleport      = loadAPI("TELEPORT", "methode/teleport/TeleportAPI.lua")
--APIs.Shop          = loadAPI("SHOP", "methode/shop/ShopAPI.lua")
--APIs.Exclusive     = loadAPI("EXCLUSIVE", "methode/exclusive/ExclusiveAPI.lua")
--APIs.Quest         = loadAPI("QUEST", "methode/quest/QuestAPI.lua")
--APIs.Event         = loadAPI("EVENT", "methode/event/EventAPI.lua")
--APIs.Tools         = loadAPI("TOOLS", "methode/tools/ToolsAPI.lua")
--APIs.Webhook       = loadAPI("WEBHOOK", "methode/webhook/WebhookAPI.lua")
--APIs.Configuration = loadAPI("CONFIGURATION", "methode/configuration/ConfigurationAPI.lua")

dprint("API loading DONE")

-- =========================
-- LOAD UI LIB
-- =========================
dprint("Loading WindUI...")
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

-- =========================
-- CREATE WINDOW
-- =========================
dprint("Creating Window...")
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
Window:SetToggleKey(Enum.KeyCode.G)
Window:Tag({
    Title = "v1.0.3",
    Color = Color3.fromRGB(0, 255, 0),
    Radius = 16,
})

-- =========================
-- LOAD UI TABS (DEBUGGED)
-- =========================
local function loadTab(path, api)
    dprint("UI TAB ->", path)
    local ok, err = pcall(function()
        local tabFn = requireURL(path)
        if type(tabFn) ~= "function" then
            error("UI tab did not return function")
        end
        tabFn(Window, api, WindUI)
    end)

    if not ok then
        dwarn("UI TAB FAILED:", path)
        warn(err)
    else
        dprint("UI TAB OK:", path)
    end
end

loadTab("ui/InfoTab.lua", APIs.Info)
loadTab("ui/PlayerTab.lua", APIs.Player)
--loadTab("ui/FishingTab.lua", APIs.Fishing)
--loadTab("ui/AutomaticTab.lua", APIs.Automatic)
--loadTab("ui/TeleportTab.lua", APIs.Teleport)
--loadTab("ui/ShopTab.lua", APIs.Shop)
--loadTab("ui/ExclusiveTab.lua", APIs.Exclusive)
--loadTab("ui/QuestTab.lua", APIs.Quest)
--loadTab("ui/EventTab.lua", APIs.Event)
--loadTab("ui/ToolsTab.lua", APIs.Tools)
--loadTab("ui/WebhookTab.lua", APIs.Webhook)
--loadTab("ui/ConfigurationTab.lua", APIs.Configuration)

-- =========================
-- GLOBAL FLAG
-- =========================
WindUI:Notify({
    Title = "Script Loader",
    Content = "Script Success Loader",
    Duration = 3, 
})
getgenv().NYXHUB_LOADED = true
dprint("NYXHUB FULLY LOADED (EXECUTOR MODE)")
