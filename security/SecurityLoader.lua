-- =========================================================
-- NYXHUB SECURITY LOADER
-- PURPOSE:
--  - Gate API load
--  - Prevent double execution
--  - Fail-safe require
--  - Executor friendly
-- =========================================================

local SecurityLoader = {}

-- =========================================================
-- CONFIG
-- =========================================================
SecurityLoader.Config = {
    ENABLED = true,

    -- Matikan API tertentu tanpa hapus file
    API_FLAGS = {
        INFO     = true,
        PLAYER   = true,
        FISHING  = true,
        AUTOMATIC = true,
        TELEPORT = true,
        SHOP     = true,
        EXCLUSIVE = true,
        QUEST    = true,
        EVENT    = true,
        TOOLS    = true,
        WEBHOOK  = true,
        CONFIGURATION = true,
        -- tambahin flag API lain DI SINI
    },

    -- Anti double load
    SINGLE_LOAD = true,

    -- Debug print
    DEBUG = true,
}

-- =========================================================
-- INTERNAL STATE
-- =========================================================
local LoadedAPIs = {}

-- =========================================================
-- INTERNAL HELPERS
-- =========================================================
local function log(...)
    if SecurityLoader.Config.DEBUG then
        print("[NYXHUB][SECURITY]", ...)
    end
end

local function warnlog(...)
    warn("[NYXHUB][SECURITY]", ...)
end

-- =========================================================
-- VALIDATION
-- =========================================================
local function isApiAllowed(tag)
    if not tag then return true end
    local flags = SecurityLoader.Config.API_FLAGS
    return flags[tag] ~= false
end

-- =========================================================
-- PUBLIC: LOAD API
-- =========================================================
function SecurityLoader:Load(moduleScript, tag)
    if not SecurityLoader.Config.ENABLED then
        warnlog("SecurityLoader disabled, blocking load:", tag)
        return nil
    end

    if SecurityLoader.Config.SINGLE_LOAD and tag then
        if LoadedAPIs[tag] then
            log("API already loaded:", tag)
            return LoadedAPIs[tag]
        end
    end

    if not isApiAllowed(tag) then
        warnlog("API blocked by flag:", tag)
        return nil
    end

    if not moduleScript then
        warnlog("Invalid module reference for tag:", tag)
        return nil
    end

    local ok, result = pcall(require, moduleScript)
    if not ok then
        warnlog("Failed to load API:", tag, "\n", result)
        return nil
    end

    if type(result) ~= "table" then
        warnlog("API did not return table:", tag)
        return nil
    end

    LoadedAPIs[tag] = result
    log("API loaded:", tag)

    return result
end

-- =========================================================
-- PUBLIC: UNLOAD API (OPTIONAL)
-- =========================================================
function SecurityLoader:Unload(tag)
    if LoadedAPIs[tag] then
        LoadedAPIs[tag] = nil
        log("API unloaded:", tag)
        return true
    end
    return false
end

-- =========================================================
-- PUBLIC: GET STATUS
-- =========================================================
function SecurityLoader:GetLoaded()
    return LoadedAPIs
end

-- =========================================================
-- PUBLIC: EXECUTOR INFO (OPTIONAL)
-- =========================================================
function SecurityLoader:GetExecutor()
    local exec =
        identifyexecutor and identifyexecutor()
        or getexecutorname and getexecutorname()
        or "Unknown"

    return exec
end

return SecurityLoader
