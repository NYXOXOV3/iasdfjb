-- =========================================================
-- INFO TAB (UI ONLY)
-- =========================================================

return function(Window, InfoAPI, WindUI)

    if not InfoAPI then
        warn("[INFO TAB] InfoAPI missing, tab skipped")
        return
    end

    local home = Window:Tab({
        Title  = "Info",
        Icon   = "info",
        Locked = false,
    })

    home:Select()

    -- =====================================================
    -- DISCORD
    -- =====================================================

    home:Section({
        Title = "Join Discord Server NYXHUB",
        TextSize = 18,
    })

    home:Paragraph({
        Title = InfoAPI.Discord.Name,
        Desc  = "Join our community Discord for updates, support, and discussion.",
        Image = InfoAPI.Discord.Image,
        ImageSize = 24,
        Buttons = {
            {
                Title = "Copy Link",
                Icon  = "link",
                Callback = function()
                    if InfoAPI.CopyDiscord() then
                        WindUI:Notify({
                            Title = "Link Copied",
                            Content = "Discord invite copied to clipboard",
                            Duration = 3,
                            Icon = "copy",
                        })
                    else
                        WindUI:Notify({
                            Title = "Failed",
                            Content = "Clipboard not supported by executor",
                            Duration = 3,
                            Icon = "x",
                        })
                    end
                end,
            }
        }
    })

    home:Divider()

    -- =====================================================
    -- WHAT'S NEW
    -- =====================================================

    home:Section({
        Title = "What's New?",
        TextSize = 24,
        FontWeight = Enum.FontWeight.SemiBold,
    })

    home:Image({
        Image = InfoAPI.Discord.Image,
        AspectRatio = "16:9",
        Radius = 9,
    })

    home:Space()

    home:Paragraph({
        Title = "Current Version",
        Desc  = InfoAPI:GetVersionString(),
    })

    home:Paragraph({
        Title = "Before Update",
        Desc  = InfoAPI:FormatList(InfoAPI.Changelog.BeforeUpdate, "[~] "),
    })

    home:Paragraph({
        Title = "Stable Update",
        Desc  = InfoAPI:FormatList(InfoAPI.Changelog.StableUpdate, "[+] "),
    })
end
