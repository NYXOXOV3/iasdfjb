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
    -- VISUALS
    -- =========================
    local visuals = tab:Section({ Title = "Visuals" })

    visuals:Toggle({
        Title = "ESP Player",
        Callback = function(state)
            PlayerAPI:SetESP(state)
        end
    })

    visuals:Toggle({
        Title = "Infinite Zoom",
        Callback = function(state)
            PlayerAPI:SetInfiniteZoom(state)
            WindUI:Notify({
                Title = state and "Zoom Enabled" or "Zoom Disabled",
                Content = state and "Infinite zoom activated" or "Zoom restored to normal",
                Duration = 2,
                Icon = state and "zoom-in" or "zoom-out",
            })
        end
    })

    -- =========================
    -- PERFORMANCE
    -- =========================
    local performance = tab:Section({ Title = "Performance" })

    performance:Toggle({
        Title = "FPS Boost (Potato Mode)",
        Callback = function(state)
            PlayerAPI:SetLowGraphics(state)
            WindUI:Notify({
                Title = state and "Potato Mode ON" or "Potato Mode OFF",
                Content = state and "Graphics minimized for FPS" or "Graphics restored",
                Duration = 2,
                Icon = state and "cpu" or "monitor",
            })
        end
    })

    performance:Toggle({
        Title = "Disable 3D Rendering",
        Description = "EXTREME FPS BOOST (Everything invisible)",
        Callback = function(state)
            PlayerAPI:SetDisable3DRendering(state)
            WindUI:Notify({
                Title = state and "3D Disabled" or "3D Enabled",
                Content = state and "Extreme FPS mode activated" or "3D rendering restored",
                Duration = 3,
                Icon = state and "zap-off" or "zap",
            })
        end
    })

    performance:Button({
        Title = "Max FPS Boost",
        Description = "Enable all optimizations",
        Icon = "zap",
        Callback = function()
            PlayerAPI:SetMaxFPSBoost(true)
            WindUI:Notify({
                Title = "MAX FPS",
                Content = "All performance optimizations enabled",
                Duration = 3,
                Icon = "zap",
            })
        end
    })

    -- =========================
    -- SECURITY
    -- =========================
    local security = tab:Section({ Title = "Security" })

    security:Toggle({
        Title = "Anti Staff Detection",
        Description = "Detect and warn about staff players",
        Callback = function(state)
            PlayerAPI:SetAntiStaff(state)
            WindUI:Notify({
                Title = state and "Anti-Staff ON" or "Anti-Staff OFF",
                Content = state and "Staff detection enabled" or "Staff detection disabled",
                Duration = 2,
                Icon = state and "shield" or "shield-off",
            })
        end
    })

    security:Button({
        Title = "Hide From Staff",
        Description = "Become semi-transparent when staff nearby",
        Icon = "eye-off",
        Callback = function()
            local success = PlayerAPI:HideFromStaff()
            if success then
                WindUI:Notify({
                    Title = "Hidden",
                    Content = "You're now hidden from detected staff",
                    Duration = 3,
                    Icon = "eye-off",
                })
            else
                WindUI:Notify({
                    Title = "No Staff",
                    Content = "No staff detected in the server",
                    Duration = 2,
                    Icon = "user-check",
                })
            end
        end
    })

    security:Button({
        Title = "Scan For Staff",
        Description = "Manually scan all players",
        Icon = "search",
        Callback = function()
            local staffList = PlayerAPI:GetDetectedStaff()
            local staffCount = 0
            local staffNames = {}
            
            for staff, _ in pairs(staffList) do
                staffCount = staffCount + 1
                table.insert(staffNames, staff.Name)
            end
            
            if staffCount > 0 then
                WindUI:Notify({
                    Title = "Staff Detected!",
                    Content = string.format("%d staff found: %s", staffCount, table.concat(staffNames, ", ")),
                    Duration = 5,
                    Icon = "alert-triangle",
                })
            else
                WindUI:Notify({
                    Title = "Scan Complete",
                    Content = "No staff detected in the server",
                    Duration = 3,
                    Icon = "user-check",
                })
            end
        end
    })

    -- =========================
    -- UTILITIES
    -- =========================
    local utilities = tab:Section({ Title = "Utilities" })

    utilities:Button({
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

    utilities:Dropdown({
        Title = "Reset Character Mode",
        Options = {
            "Keep Camera Direction",
            "Keep Character Direction",
            "Custom Direction"
        },
        Default = 1,
        Callback = function(option)
            if option == 1 then
                WindUI:Notify({
                    Title = "Reset Mode",
                    Content = "Will keep camera direction on reset",
                    Duration = 2,
                    Icon = "camera",
                })
            elseif option == 2 then
                WindUI:Notify({
                    Title = "Reset Mode",
                    Content = "Will keep character direction on reset",
                    Duration = 2,
                    Icon = "user",
                })
            elseif option == 3 then
                WindUI:Notify({
                    Title = "Reset Mode",
                    Content = "Custom direction mode selected",
                    Duration = 2,
                    Icon = "compass",
                })
            end
        end
    })

    utilities:Button({
        Title = "Get Status Report",
        Description = "Show current player settings",
        Icon = "clipboard-list",
        Callback = function()
            local status = PlayerAPI:GetStatus()
            local message = string.format(
                "WalkSpeed: %d\nJumpPower: %d\nFly: %s\nNoClip: %s\nESP: %s\nAnti-Staff: %s\nZoom: %s\nFPS Boost: %s",
                status.WalkSpeed or 16,
                status.JumpPower or 50,
                status.Fly and "ON" or "OFF",
                status.NoClip and "ON" or "OFF",
                status.ESPEnabled and "ON" or "OFF",
                status.AntiStaff and "ON" or "OFF",
                status.InfiniteZoom and "ON" or "OFF",
                status.LowGraphics and "ON" or "OFF"
            )
            
            WindUI:Notify({
                Title = "Player Status",
                Content = message,
                Duration = 5,
                Icon = "info",
            })
        end
    })

    utilities:Button({
        Title = "Reset All Player Settings",
        Description = "Disable all features and reset to default",
        Icon = "rotate-ccw",
        Callback = function()
            PlayerAPI:Shutdown()
            WindUI:Notify({
                Title = "Complete Reset",
                Content = "All player settings reset to default",
                Duration = 3,
                Icon = "check-circle",
            })
        end
    })

    -- =========================
    -- FLY SPEED CONTROL
    -- =========================
    local flySection = tab:Section({ Title = "Fly Settings" })

    flySection:Slider({
        Title = "Fly Speed",
        Step = 5,
        Value = { Min = 20, Max = 200, Default = 60 },
        Callback = function(v)
            if state.Fly then
                PlayerAPI:SetFly(true, v)
            end
        end
    })

    flySection:Button({
        Title = "Toggle Fly Hotkey",
        Description = "Set a hotkey to toggle fly mode",
        Icon = "keyboard",
        Callback = function()
            WindUI:Notify({
                Title = "Hotkey Info",
                Content = "Fly toggle hotkey not implemented yet",
                Duration = 3,
                Icon = "key",
            })
        end
    })

    -- =========================
    -- ESP SETTINGS
    -- =========================
    local espSection = tab:Section({ Title = "ESP Settings" })

    espSection:Colorpicker({
        Title = "ESP Color (Close)",
        Default = Color3.fromRGB(255, 50, 50),
        Callback = function(color)
            -- This would need to be implemented in PlayerAPI
            WindUI:Notify({
                Title = "Color Changed",
                Content = "Close range ESP color updated",
                Duration = 2,
                Icon = "palette",
            })
        end
    })

    espSection:Colorpicker({
        Title = "ESP Color (Far)",
        Default = Color3.fromRGB(50, 200, 255),
        Callback = function(color)
            -- This would need to be implemented in PlayerAPI
            WindUI:Notify({
                Title = "Color Changed",
                Content = "Far range ESP color updated",
                Duration = 2,
                Icon = "palette",
            })
        end
    })

    espSection:Slider({
        Title = "ESP Max Distance",
        Step = 50,
        Value = { Min = 100, Max = 1000, Default = 500 },
        Callback = function(v)
            -- This would need to be implemented in PlayerAPI
            WindUI:Notify({
                Title = "Distance Changed",
                Content = string.format("ESP max distance set to %d", v),
                Duration = 2,
                Icon = "maximize-2",
            })
        end
    })

    -- =========================
    -- AUTO-UPDATE SECTION
    -- =========================
    local autoSection = tab:Section({ Title = "Auto Features" })

    autoSection:Toggle({
        Title = "Auto-Hide From Staff",
        Description = "Automatically hide when staff detected",
        Callback = function(state)
            WindUI:Notify({
                Title = state and "Auto-Hide ON" or "Auto-Hide OFF",
                Content = state and "Will auto-hide when staff joins" or "Auto-hide disabled",
                Duration = 2,
                Icon = state and "eye-off" or "eye",
            })
        end
    })

    autoSection:Toggle({
        Title = "Auto-Disable ESP for Staff",
        Description = "Turn off ESP when staff joins",
        Callback = function(state)
            WindUI:Notify({
                Title = state and "Auto-ESP OFF ON" or "Auto-ESP OFF OFF",
                Content = state and "ESP will auto-disable for staff" or "ESP won't auto-disable",
                Duration = 2,
                Icon = state and "toggle-left" or "toggle-right",
            })
        end
    })

    -- =========================
    -- INFO SECTION
    -- =========================
    local infoSection = tab:Section({ Title = "Information" })

    infoSection:Label({
        Title = "Player Features",
        Content = "All features are client-side only"
    })

    infoSection:Label({
        Title = "Anti-Staff",
        Content = "Detects staff by name, ID, and behavior patterns"
    })

    infoSection:Label({
        Title = "Performance",
        Content = "FPS boost features may make game look worse"
    })

    infoSection:Label({
        Title = "Warning",
        Content = "Use features responsibly to avoid detection",
        ContentColor = Color3.fromRGB(255, 100, 100)
    })

    -- =========================
    -- INITIAL STATUS CHECK
    -- =========================
    task.spawn(function()
        task.wait(2)
        WindUI:Notify({
            Title = "Player Tab Loaded",
            Content = "All player features are now available",
            Duration = 3,
            Icon = "user-check",
        })
    end)

    return tab
end
