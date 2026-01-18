-- security/SecurityLoader.lua

local SecurityLoader = {}

SecurityLoader.Config = {
    ENABLED = true,
    SINGLE_LOAD = true,
    DEBUG = true,

    API_FLAGS = {
        INFO = true,
        PLAYER = true,
        FISHING = true,
        AUTOMATIC = true,
        TELEPORT = true,
        SHOP = true,
        EXCLUSIVE = true,
        QUEST = true,
        EVENT = true,
        TOOLS = true,
        WEBHOOK = true,
        CONFIGURATION = true,
    }
}

local LoadedAPIs = {}

local function log(...)
    if SecurityLoader.Config.DEBUG then
        print("[NYXHUB][SECURITY]", ...)
    end
end

local function warnlog(...)
    warn("[NYXHUB][SECURITY]", ...)
end

function SecurityLoader:Load(module, tag)
    if not SecurityLoader.Config.ENABLED then
        warnlog("Loader disabled:", tag)
        return nil
    end

    if tag and SecurityLoader.Config.SINGLE_LOAD and LoadedAPIs[tag] then
        return LoadedAPIs[tag]
    end

    if tag and SecurityLoader.Config.API_FLAGS[tag] == false then
        warnlog("API blocked:", tag)
        return nil
    end

    if not module then
        warnlog("Nil module:", tag)
        return nil
    end

    local result

    -- EXECUTOR MODE
    if type(module) == "table" then
        result = module

    -- STUDIO MODE
    elseif typeof(module) == "Instance" then
        local ok, res = pcall(require, module)
        if not ok then
            warnlog("Require failed:", tag, res)
            return nil
        end
        result = res
    else
        warnlog("Invalid module type:", tag, typeof(module))
        return nil
    end

    if type(result) ~= "table" then
        warnlog("API must return table:", tag)
        return nil
    end

    LoadedAPIs[tag] = result
    log("API loaded:", tag)
    return result
end

return SecurityLoader
