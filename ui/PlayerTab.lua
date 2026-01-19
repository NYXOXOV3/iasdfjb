-- =========================================================
-- PLAYER TAB (UI ONLY)
-- =========================================================

return function(Window, PlayerAPI, WindUI)

    if not PlayerAPI then
        warn("[PLAYER TAB] PlayerAPI missing, skipped")
        return
    end

    local tab = Window:Tab({
        Title = "Player",
        Icon = "user",
        Locked = false,
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

    movement:Toggle({
        Title = "Freeze Player",
        Callback = function(state)
            PlayerAPI:SetFreeze(state)
        end
    })

    -- =========================
    -- ABILITIES
    -- =========================
    local ability = tab:Section({ Title = "Abilities" })

    ability:Toggle({
        Title = "Infinite Jump",
        Callback = function(state)
            PlayerAPI:SetInfiniteJump(state)
        end
    })

    ability:Toggle({
        Title = "No Clip",
        Callback = function(state)
            PlayerAPI:SetNoClip(state)
        end
    })

    ability:Toggle({
        Title = "Fly Mode",
        Callback = function(state)
            PlayerAPI:SetFly(state, 60)
        end
    })
    ability:Toggle({
        Title = "Walk On Water",
        Callback = function(state)
            PlayerAPI:SetWalkOnWater(state)
        end
    })

    -- =========================
    -- OTHERS
    -- =========================
    local other = tab:Section({ Title = "Others" })

    other:Toggle({
        Title = "Esp Player",
        Callback = function(state)
            PlayerAPI:SetESP(state)
        end
    })

    other:Button({
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

    other:Button({
        Title = "Reset All Player Settings",
        Icon = "rotate-ccw",
        Callback = function()
            PlayerAPI:ResetAll()
        end
    })
end
