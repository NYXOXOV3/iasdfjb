function SecurityLoader:Load(module, tag)
    if not SecurityLoader.Config.ENABLED then
        warnlog("SecurityLoader disabled, blocking load:", tag)
        return nil
    end

    if tag and SecurityLoader.Config.SINGLE_LOAD and LoadedAPIs[tag] then
        log("API already loaded:", tag)
        return LoadedAPIs[tag]
    end

    if not isApiAllowed(tag) then
        warnlog("API blocked by flag:", tag)
        return nil
    end

    if not module then
        warnlog("Nil module for tag:", tag)
        return nil
    end

    local result

    -- =================================================
    -- EXECUTOR MODE → module sudah TABLE
    -- =================================================
    if type(module) == "table" then
        result = module

    -- =================================================
    -- STUDIO MODE → module adalah Instance
    -- =================================================
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
