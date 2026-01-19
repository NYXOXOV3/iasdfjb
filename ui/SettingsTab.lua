-- =========================================================
-- SETTINGS TAB (UI ONLY)
-- NYXHUB - Fish It
-- =========================================================

return function(Window, SettingsAPI, WindUI)

    if not SettingsAPI then
        warn("[SETTINGS TAB] SettingsAPI missing")
        return
    end

    -- =====================================================
    -- TAB
    -- =====================================================
    local tab = Window:Tab({
        Title = "Settings",
        Icon = "settings",
        Locked = false,
    })

    -- =====================================================
    -- SECURITY
    -- =====================================================
    local security = tab:Section({
        Title = "Security"
    })

    security:Toggle({
        Title = "Hide Username",
        Default = false,
        Callback = function(state)
            SettingsAPI:SetHideUsername(state)
        end
    })

    -- =====================================================
    -- MOVEMENT
    -- =====================================================
    local movement = tab:Section({
        Title = "Movement"
    })

    movement:Slider({
        Title = "WalkSpeed",
        Step = 1,
        Value = {
            Min = 16,
            Max = 200,
            Default = 16
        },
        Callback = function(value)
            SettingsAPI:SetWalkSpeed(value)
        end
    })

    movement:Slider({
        Title = "JumpPower",
        Step = 1,
        Value = {
            Min = 50,
            Max = 200,
            Default = 50
        },
        Callback = function(value)
            SettingsAPI:SetJumpPower(value)
        end
    })

    movement:Button({
        Title = "Reset Movement",
        Icon = "rotate-ccw",
        Callback = function()
            SettingsAPI:ResetMovement()
            WindUI:Notify({
                Title = "Reset",
                Content = "Movement reset to default",
                Duration = 2,
                Icon = "check",
            })
        end
    })

    -- =====================================================
    -- MODES
    -- =====================================================
    local modes = tab:Section({
        Title = "Modes"
    })

    modes:Toggle({
        Title = "Infinite Jump",
        Default = false,
        Callback = function(state)
            SettingsAPI:SetInfiniteJump(state)
        end
    })

    modes:Toggle({
        Title = "NoClip",
        Default = false,
        Callback = function(state)
            SettingsAPI:SetNoClip(state)
        end
    })

    modes:Toggle({
        Title = "Walk On Water",
        Default = false,
        Callback = function(state)
            SettingsAPI:SetWalkOnWater(state)
        end
    })

    modes:Toggle({
        Title = "Infinite Zoom",
        Default = false,
        Callback = function(state)
            SettingsAPI:SetInfiniteZoom(state)
        end
    })

    -- =====================================================
    -- VISUAL
    -- =====================================================
    local visual = tab:Section({
        Title = "Visual"
    })

    visual:Toggle({
        Title = "Disable Rendering",
        Default = false,
        Callback = function(state)
            SettingsAPI:SetDisableRendering(state)
        end
    })

    visual:Toggle({
        Title = "ESP Player",
        Default = false,
        Callback = function(state)
            SettingsAPI:SetESP(state)
        end
    })

    visual:Button({
        Title = "Reset Player (In Place)",
        Icon = "refresh-cw",
        Callback = function()
            SettingsAPI:ResetCharacterInPlace()
            WindUI:Notify({
                Title = "Reset",
                Content = "Player reset in place",
                Duration = 2,
                Icon = "check",
            })
        end
    })

    -- =====================================================
    -- EXTERNAL
    -- =====================================================
    local external = tab:Section({
        Title = "External"
    })

    external:Button({
        Title = "Fly GUI (External)",
        Icon = "bird",
        Callback = function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"
            ))()
        end
    })

    -- =====================================================
    -- MASTER RESET
    -- =====================================================
    local reset = tab:Section({
        Title = "Reset"
    })

    reset:Button({
        Title = "Reset All Settings",
        Icon = "rotate-ccw",
        Callback = function()
            SettingsAPI:ResetAll()
            WindUI:Notify({
                Title = "Reset",
                Content = "All settings restored",
                Duration = 2,
                Icon = "check",
            })
        end
    })
end
