-- =========================================================
-- FISHING TAB (COMPLETE WITH ALL MODES)
-- =========================================================
return function(Window, FishingAPI, WindUI)
    if not FishingAPI then
        warn("[FISHING TAB] FishingAPI missing, skipped")
        return
    end

    local farm = Window:Tab({
        Title = "Farm",
        Icon = "fish"
    })

    -- ================= AUTO FISHING SECTION =================
    local autofish = farm:Section({ Title = "Auto Fishing" })

    autofish:Slider({
        Title = "Legit Click Speed",
        Step = 0.01,
        Value = { Min = 0.01, Max = 0.5, Default = 0.05 },
        Callback = function(v) FishingAPI:SetLegitSpeed(v) end
    })

    autofish:Toggle({
        Title = "Auto Fish (Legit)",
        Callback = function(v) FishingAPI:SetLegit(v) end
    })

    autofish:Slider({
        Title = "Normal Complete Delay",
        Step = 0.05,
        Value = { Min = 0.5, Max = 5.0, Default = 1.5 },
        Callback = function(v) FishingAPI:SetNormalDelay(v) end
    })

    autofish:Toggle({
        Title = "Normal Instant Fish",
        Callback = function(v) FishingAPI:SetNormal(v) end
    })

    farm:Divider()

    -- ================= BLATANT OLD/NEW SECTION =================
    local blatant = farm:Section({ Title = "BLATANT OLD/NEW" })

    blatant:Dropdown({
        Title = "Blatant Mode",
        Values = { "Old", "New" },
        Callback = function(mode) FishingAPI:SetMode(mode) end
    })

    blatant:Input({
        Title = "Cancel Delay",
        Default = "1.75",
        Callback = function(v) FishingAPI:SetCancelDelay(v) end
    })

    blatant:Input({
        Title = "Complete Delay",
        Default = "1.33",
        Callback = function(v) FishingAPI:SetCompleteDelay(v) end
    })
    
    blatant:Toggle({
        Title = "Activate Blatant",
        Value = false,
        Callback = function(state) FishingAPI:SetActive(state) end
    })

    farm:Divider()

    -- ================= BLATANT V2 SECTION =================
    local blatantv2 = farm:Section({ Title = "BLATANT V2" })

    blatantv2:Input({
        Title = "Charge Delay",
        Default = "0.007",
        Callback = function(v) FishingAPI:SetBlatantV2Setting("ChargeDelay", v) end
    })

    blatantv2:Input({
        Title = "Complete Delay",
        Default = "0.001",
        Callback = function(v) FishingAPI:SetBlatantV2Setting("CompleteDelay", v) end
    })

    blatantv2:Input({
        Title = "Cancel Delay",
        Default = "0.001",
        Callback = function(v) FishingAPI:SetBlatantV2Setting("CancelDelay", v) end
    })

    blatantv2:Input({
        Title = "Equip Delay",
        Default = "0.02",
        Callback = function(v) FishingAPI:SetBlatantV2Setting("EquipDelay", v) end
    })
    
    local v2Toggle = blatantv2:Toggle({
        Title = "ACTIVATE V2",
        Value = false,
        Callback = function(state)
            FishingAPI:SetBlatantV2(state)
            if state then
                v2Toggle:SetTitle("ACTIVATE V2 ✓")
            else
                v2Toggle:SetTitle("ACTIVATE V2")
            end
        end
    })

    -- ================= BLATANT V3 SECTION =================
    local blatantv3 = farm:Section({ Title = "BLATANT V3" })

    blatantv3:Input({
        Title = "Complete Delay",
        Default = "0.73",
        Callback = function(v) FishingAPI:SetBlatantV3Setting("CompleteDelay", v) end
    })

    blatantv3:Input({
        Title = "Cancel Delay",
        Default = "0.3",
        Callback = function(v) FishingAPI:SetBlatantV3Setting("CancelDelay", v) end
    })

    blatantv3:Input({
        Title = "ReCast Delay",
        Default = "0.001",
        Callback = function(v) FishingAPI:SetBlatantV3Setting("ReCastDelay", v) end
    })
    
    local v3Toggle = blatantv3:Toggle({
        Title = "ACTIVATE V3",
        Value = false,
        Callback = function(state)
            FishingAPI:SetBlatantV3(state)
            if state then
                v3Toggle:SetTitle("ACTIVATE V3 ✓")
            else
                v3Toggle:SetTitle("ACTIVATE V3")
            end
        end
    })

    -- ================= BLATANT V4 SECTION =================
    local blatantv4 = farm:Section({ Title = "BLATANT V4" })

    blatantv4:Input({
        Title = "Fishing Delay",
        Default = "0.05",
        Callback = function(v) FishingAPI:SetBlatantV4Setting("FishingDelay", v) end
    })

    blatantv4:Input({
        Title = "Cancel Delay",
        Default = "0.01",
        Callback = function(v) FishingAPI:SetBlatantV4Setting("CancelDelay", v) end
    })

    blatantv4:Input({
        Title = "Hook Wait Time",
        Default = "0.01",
        Callback = function(v) FishingAPI:SetBlatantV4Setting("HookWaitTime", v) end
    })

    blatantv4:Input({
        Title = "Timeout Delay",
        Default = "0.8",
        Callback = function(v) FishingAPI:SetBlatantV4Setting("TimeoutDelay", v) end
    })
    
    local v4Toggle = blatantv4:Toggle({
        Title = "ACTIVATE V4",
        Value = false,
        Callback = function(state)
            FishingAPI:SetBlatantV4(state)
            if state then
                v4Toggle:SetTitle("ACTIVATE V4 ✓")
            else
                v4Toggle:SetTitle("ACTIVATE V4")
            end
        end
    })

    -- ================= BLATANT V5 SECTION =================
    local blatantv5 = farm:Section({ Title = "BLATANT V5" })

    blatantv5:Input({
        Title = "Complete Delay",
        Default = "0.001",
        Callback = function(v) FishingAPI:SetBlatantV5Setting("CompleteDelay", v) end
    })

    blatantv5:Input({
        Title = "Cancel Delay",
        Default = "0.001",
        Callback = function(v) FishingAPI:SetBlatantV5Setting("CancelDelay", v) end
    })

    blatantv5:Input({
        Title = "Charge Delay",
        Default = "0.007",
        Callback = function(v) FishingAPI:SetBlatantV5Setting("ChargeDelay", v) end
    })
    
    local v5Toggle = blatantv5:Toggle({
        Title = "ACTIVATE V5",
        Value = false,
        Callback = function(state)
            FishingAPI:SetBlatantV5(state)
            if state then
                v5Toggle:SetTitle("ACTIVATE V5 ✓")
            else
                v5Toggle:SetTitle("ACTIVATE V5")
            end
        end
    })

    -- ================= FAST PERFECT SECTION =================
    local fastperfect = farm:Section({ Title = "FAST PERFECT" })

    fastperfect:Input({
        Title = "Fishing Delay",
        Default = "0.01",
        Callback = function(v) FishingAPI:SetFastPerfectSetting("FishingDelay", v) end
    })

    fastperfect:Input({
        Title = "Hook Detection Delay",
        Default = "0.01",
        Callback = function(v) FishingAPI:SetFastPerfectSetting("HookDetectionDelay", v) end
    })

    fastperfect:Input({
        Title = "Request Minigame Delay",
        Default = "0.01",
        Callback = function(v) FishingAPI:SetFastPerfectSetting("RequestMinigameDelay", v) end
    })

    fastperfect:Input({
        Title = "Timeout Delay",
        Default = "0.5",
        Callback = function(v) FishingAPI:SetFastPerfectSetting("TimeoutDelay", v) end
    })
    
    local fpToggle = fastperfect:Toggle({
        Title = "ACTIVATE FAST PERFECT",
        Value = false,
        Callback = function(state)
            FishingAPI:SetFastPerfect(state)
            if state then
                fpToggle:SetTitle("ACTIVATE FAST PERFECT ✓")
            else
                fpToggle:SetTitle("ACTIVATE FAST PERFECT")
            end
        end
    })

    farm:Divider()

    -- ================= FISHING AREA SECTION =================
    local areafish = farm:Section({ Title = "Fishing Area" })

    local areaNames = FishingAPI:GetAreaNames() or {}
    areafish:Dropdown({
        Title = "Choose Area",
        Values = areaNames,
        AllowNone = true,
        Callback = function(v) FishingAPI:SetSelectedArea(v) end
    })

    local freezeToggle = areafish:Toggle({
        Title = "Teleport & Freeze at Area",
        Callback = function(state)
            local ok = FishingAPI:SetTeleportFreeze(state)
            if not ok then
                freezeToggle:Set(false)
                if WindUI then
                    WindUI:Notify({
                        Title = "Error",
                        Content = "Failed to teleport/freeze",
                        Duration = 2,
                        Icon = "error"
                    })
                end
            end
        end
    })

    areafish:Button({
        Title = "Teleport to Area",
        Callback = function() 
            local success = FishingAPI:TeleportToArea()
            if WindUI then
                if success then
                    WindUI:Notify({
                        Title = "Teleport Success",
                        Duration = 2,
                        Icon = "check"
                    })
                else
                    WindUI:Notify({
                        Title = "Teleport Failed",
                        Content = "Select an area first",
                        Duration = 2,
                        Icon = "error"
                    })
                end
            end
        end
    })

    areafish:Button({
        Title = "Save Current Position",
        Callback = function()
            local pos = FishingAPI:SaveCurrentPosition()
            if pos then
                if WindUI then
                    WindUI:Notify({
                        Title = "Position Saved",
                        Content = "Saved as Custom: Saved",
                        Duration = 2,
                        Icon = "save"
                    })
                end
            end
        end
    })

    farm:Divider()
    
    -- ================= STATS DISPLAY SECTION =================
    local statsSection = farm:Section({ Title = "Stats & Info" })
    
    local statsLabel = statsSection:Label({
        Title = "Current Mode: None",
        Content = "Waiting for activation..."
    })
    
    -- Update stats periodically
    task.spawn(function()
        while task.wait(2) do
            -- Check which mode is active
            local activeMode = "None"
            local statsText = "Idle"
            
            if FishingAPI.GetBlatantV2Stats then
                local stats = FishingAPI:GetBlatantV2Stats()
                if stats and stats.Active then
                    activeMode = "Blatant V2"
                    statsText = string.format("%s | Cycle: %s", stats.Speed, stats.CycleTime)
                end
            end
            
            statsLabel:Set({
                Title = string.format("Current Mode: %s", activeMode),
                Content = statsText
            })
        end
    end)
    
    -- ================= CLEANUP SECTION =================
    local cleanup = farm:Section({ Title = "System" })
    
    cleanup:Button({
        Title = "🛑 STOP ALL FISHING",
        Callback = function()
            FishingAPI:Cleanup()
            
            -- Reset all toggle titles
            v2Toggle:SetTitle("ACTIVATE V2")
            v3Toggle:SetTitle("ACTIVATE V3")
            v4Toggle:SetTitle("ACTIVATE V4")
            v5Toggle:SetTitle("ACTIVATE V5")
            fpToggle:SetTitle("ACTIVATE FAST PERFECT")
            freezeToggle:Set(false)
            
            if WindUI then
                WindUI:Notify({
                    Title = "All Fishing Stopped",
                    Duration = 2,
                    Icon = "check"
                })
            end
        end
    })

    cleanup:Paragraph({
        Title = "ℹ️ Mode Comparison",
        Content = "Old/New: Original Blatant\nV2: Ultra Fast (up to 1000 fish/sec)\nV3: Optimized with cooldown\nV4: Event Based with hook detection\nV5: Clean Fast mode\nFast Perfect: Advanced hook detection"
    })
    
    cleanup:Paragraph({
        Title = "⚠️ Warning",
        Content = "Blatant modes have HIGH ban risk! Use at your own risk. Legit mode is safest."
    })
end
