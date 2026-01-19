-- =========================================================
-- PLAYER TAB (UI ONLY)
-- =========================================================

return function(Window, PlayerAPI, WindUI)

    if not PlayerAPI then
        warn("[SETTING TAB] PlayerAPI missing, skipped")
        return
    end

    local tab = Window:Tab({
        Title = "Settings",
        Icon = "settings",
        Locked = false,
    })

    -- =========================
    -- STREAM
    -- =========================
    local stream = tab:Section({ Title = "Stream" })

    stream:Toggle({
        Title = "Hide Username",
        Desc = "Rejoin to disable",
        Default = false,
        Callback = function(state)
            PlayerAPI:SetHideUsername(state)
        end
    })

    stream:Button({
        Title = "Reset Player Inplace",
        Icon = "refresh-cw",
        Callback = function()
            PlayerAPI:ResetCharacterInPlace()
            WindUI:Notify({
                Title = "Reset",
                Content = "Player reset inplace",
                Duration = 2,
                Icon = "check",
            })
        end
    })
    -- =========================
    -- MOVEMENT
    -- =========================
    local movement = tab:Section({ Title = "Movement" })

    movement:Slider({
        Title = "WalkSpeed",
        Step = 1,
        Value = { Min = 16, Max = 200, Default = 16 },
        Callback = function(v)
            PlayerAPI:SetWalkSpeed(v)
        end
    })

    movement:Slider({
        Title = "JumpPower",
        Step = 1,
        Value = { Min = 50, Max = 200, Default = 50 },
        Callback = function(v)
            PlayerAPI:SetJumpPower(v)
        end
    })

    movement:Button({
        Title = "Reset Movement",
        Icon = "rotate-ccw",
        Callback = function()
            PlayerAPI:ResetMovement()
            WindUI:Notify({
                Title = "Reset",
                Content = "Movement reset to default",
                Duration = 2,
                Icon = "check",
            })
        end
    })
    
    --movement:Toggle({
    --    Title = "Freeze Player",
    --    Callback = function(state)
    --        PlayerAPI:SetFreeze(state)
    --    end
    --})
    movement:Divider()
    -- =========================
    -- MODES
    -- =========================
    local ability = tab:Section({ Title = "Modes" })

    ability:Toggle({
        Title = "Infinite Jump",
        Callback = function(state)
            PlayerAPI:SetInfiniteJump(state)
        end
    })

    ability:Toggle({
        Title = "NoClip",
        Callback = function(state)
            PlayerAPI:SetNoClip(state)
        end
    })

    ability:Toggle({
        Title = "Walk On Water",
        Callback = function(state)
            PlayerAPI:SetWalkOnWater(state)
        end
    })

    ability:Toggle({
        Title = "Infinite Zoom",
        Callback = function(state)
            PlayerAPI:SetInfiniteZoom(state)
        end
    })
    ability:Divider()
    -- =========================
    -- VISUAL
    -- =========================
    local other = tab:Section({ Title = "Visual" })

    other:Toggle({
        Title = "Esp Player",
        Callback = function(state)
            PlayerAPI:SetESP(state)
        end
    })

    other:Button({
        Title = "Reset All Player Settings",
        Icon = "rotate-ccw",
        Callback = function()
            PlayerAPI:ResetAll()
        end
    })
    other:Divider()
    -- =========================
    -- EXTERNAL
    -- =========================

    local external = tab:Section({ Title = "External" })
    external:Button({
        Title = "FLY GUI",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
        end
    })

    -- =========================
    -- MASTER RESET
    -- =========================
end
