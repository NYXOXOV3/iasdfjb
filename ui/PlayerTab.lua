-- =========================================================
-- PLAYER TAB UI (FIXED WINDUI VERSION)
-- =========================================================

return function(Window, PlayerAPI, WindUI)

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local tab = Window:Tab({
        Title = "Player",
        Icon = "user",
        Locked = false,
    })

    -- =========================
    -- MOVEMENT
    -- =========================
    local move = tab:Section({ Title = "Movement" })

    move:Slider({
        Title = "WalkSpeed",
        Step = 1,
        Value = { Min = 16, Max = 200, Default = 16 },
        Callback = function(v)
            PlayerAPI:SetWalkSpeed(v)
        end
    })

    move:Slider({
        Title = "JumpPower",
        Step = 1,
        Value = { Min = 50, Max = 200, Default = 50 },
        Callback = function(v)
            PlayerAPI:SetJumpPower(v)
        end
    })

    move:Button({
        Title = "Reset Movement",
        Icon = "rotate-ccw",
        Callback = function()
            PlayerAPI:ResetMovement()
            WindUI:Notify({
                Title = "Reset",
                Content = "Movement reset",
                Duration = 2,
                Icon = "check",
            })
        end
    })

    move:Toggle({
        Title = "Freeze Player",
        Callback = function(v)
            PlayerAPI:SetFreeze(v)
        end
    })

    -- =========================
    -- ABILITIES
    -- =========================
    local ab = tab:Section({ Title = "Abilities" })

    ab:Toggle({
        Title = "Infinite Jump",
        Callback = function(v)
            PlayerAPI:SetInfiniteJump(v)
        end
    })

    ab:Toggle({
        Title = "No Clip",
        Callback = function(v)
            PlayerAPI:SetNoClip(v)
        end
    })

    ab:Toggle({
        Title = "Fly Mode",
        Callback = function(v)
            PlayerAPI:SetFly(v, 60)
        end
    })

    ab:Toggle({
        Title = "Walk On Water",
        Callback = function(v)
            PlayerAPI:SetWalkOnWater(v)
        end
    })

    -- =========================
    -- STREAMER MODE
    -- =========================
    local stream = tab:Section({ Title = "Streamer Mode" })

    stream:Input({
        Title = "Fake Name",
        Value = ".gg/NYXHUB",
        Placeholder = "Fake Name",
        Callback = function(v)
            PlayerAPI:SetFakeName(v)
        end
    })

    stream:Input({
        Title = "Fake Level",
        Value = "Lvl. 969",
        Placeholder = "Fake Level",
        Callback = function(v)
            PlayerAPI:SetFakeLevel(v)
        end
    })

    -- ⚠️ WINDUI DROPDOWN FIX
    stream:Dropdown({
        Title = "Hide Mode",
        Values = { "SELF", "SELECTED", "ALL" },
        Default = "SELF",
        Callback = function(v)
            PlayerAPI:SetHideMode(v)
        end
    })

    stream:Toggle({
        Title = "Hide Usernames (Streamer Mode)",
        Callback = function(v)
            PlayerAPI:SetHideUsernames(v)
        end
    })

    -- =========================
    -- PLAYER SELECTOR (SELECTED MODE)
    -- =========================
    local selector = tab:Section({
        Title = "Select Players",
        TextSize = 16,
    })

    local function refreshPlayers()
        selector:Clear()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                selector:Toggle({
                    Title = plr.Name,
                    Callback = function(state)
                        if state then
                            PlayerAPI:AddHideTarget(plr)
                        else
                            PlayerAPI:RemoveHideTarget(plr)
                        end
                    end
                })
            end
        end
    end

    refreshPlayers()
    Players.PlayerAdded:Connect(refreshPlayers)
    Players.PlayerRemoving:Connect(refreshPlayers)

    -- =========================
    -- OTHER
    -- =========================
    local other = tab:Section({ Title = "Other" })

    other:Toggle({
        Title = "Player ESP",
        Callback = function(v)
            PlayerAPI:SetESP(v)
        end
    })

    other:Button({
        Title = "Reset Player In Place",
        Icon = "refresh-cw",
        Callback = function()
            PlayerAPI:ResetCharacterInPlace()
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
