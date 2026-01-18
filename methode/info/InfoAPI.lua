-- =========================================================
-- INFO API
-- NYXHUB - Fish It
-- =========================================================

local InfoAPI = {}

-- =========================================================
-- STATIC DATA
-- =========================================================

InfoAPI.Discord = {
    Name   = "NYXHUB Community",
    Invite = "https://discord.gg/gW9jjJjH",
    Image  = "rbxassetid://137263312772667"
}

InfoAPI.Version = {
    Name    = "1.0.3",
    Date    = "11 Des 2025",
    Type    = "Freemium"
}

InfoAPI.Changelog = {
    BeforeUpdate = {
        "Fix 3D Rendering Force Close Issue",
        "Fix Teleport & Freeze Detect Old Position",
        "Improve Load UI",
        "Add Freeze Player",
        "Add Detect Enchant Perfection On Blatant Mode",
        "Add Auto Spawn 9 Totem",
        "Bring Back 3 Setting On Blatant Mode",
    },

    StableUpdate = {
        "Load UI More Faster",
        "Add Back Old Cast Method Blatant Mode",
    }
}

-- =========================================================
-- ACTIONS
-- =========================================================

function InfoAPI.CopyDiscord()
    if setclipboard then
        setclipboard(InfoAPI.Discord.Invite)
        return true
    end
    return false
end

function InfoAPI:GetVersionString()
    return string.format(
        "Version %s\n- %s Release %s",
        self.Version.Name,
        self.Version.Date,
        self.Version.Type
    )
end

function InfoAPI:FormatList(list, prefix)
    prefix = prefix or "- "
    return prefix .. table.concat(list, "\n" .. prefix)
end

return InfoAPI
