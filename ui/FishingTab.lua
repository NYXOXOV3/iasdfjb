-- =========================================================
-- FISHING TAB (UI ONLY - USING FISHINGAPI)
-- =========================================================
return function(Window, FishingAPI, WindUI, FishingAreas, AreaNames)
    if not FishingAPI then
        warn("[FISHING TAB] FishingAPI missing, skipped")
        return
    end

    local farm = Window:Tab({
        Title = "Fishing",
        Icon = "fish",
    })

    -- ================= AUTO FISHING SECTION =================
    local autofish = farm:Section({ Title = "Auto Fishing" })

    -- Legit Mode Controls
    autofish:Slider({
        Title = "Legit Click Speed (Delay)",
        Step = 0.01,
        Value = { Min = 0.01, Max = 0.5, Default = 0.05 },
        Callback = function(v)
            FishingAPI:SetLegitSpeed(v)
        end
    })

    autofish:Toggle({
        Title = "Auto Fish (Legit)",
        Callback = function(v)
            FishingAPI:SetLegit(v)
        end
    })

    -- Normal Mode Controls
    autofish:Slider({
        Title = "Normal Complete Delay",
        Step = 0.05,
        Value = { Min = 0.5, Max = 5.0, Default = 1.5 },
        Callback = function(v)
            FishingAPI:SetNormalDelay(v)
        end
    })

    autofish:Toggle({
        Title = "Normal Instant Fish",
        Callback = function(v)
            FishingAPI:SetNormal(v)
        end
    })

    farm:Divider()

    -- ================= BLATANT MODE SECTION =================
    local blatant = farm:Section({ Title = "Blatant Mode" })

    blatant:Dropdown({
        Title = "Blatant Mode",
        Values = { "Old", "New" },
        Callback = function(mode)
            FishingAPI:SetMode(mode)
        end
    })

    blatant:Input({
        Title = "Cancel Delay",
        Default = "1.75",
        Callback = function(v)
            FishingAPI:SetCancelDelay(v)
        end
    })

    blatant:Input({
        Title = "Complete Delay",
        Default = "1.33",
        Callback = function(v)
            FishingAPI:SetCompleteDelay(v)
        end
    })
    
    blatant:Toggle({
        Title = "Instant Fishing (Blatant)",
        Callback = function(state)
            FishingAPI:SetActive(state)
        end
    })

    farm:Divider()

    -- ================= BLATANT V2 SECTION =================
    local blatantv2 = farm:Section({ 
        Title = "🚀 BLATANT V2 (BRUTAL)",
        TextSize = 16
    })

    -- Mode Selection
    blatantv2:Dropdown({
        Title = "Brutal Mode",
        Values = { "Extreme", "Ultra", "GodMode" },
        Default = "Extreme",
        Callback = function(mode)
            FishingAPI:SetBlatantV2Mode(mode)
        end
    })

    -- Settings
    blatantv2:Input({
        Title = "Complete Delay",
        Default = "0.08",
        Callback = function(v)
            FishingAPI:SetBlatantV2Setting("CompleteDelay", v)
        end
    })

    blatantv2:Input({
        Title = "Cancel Delay",
        Default = "0.05",
        Callback = function(v)
            FishingAPI:SetBlatantV2Setting("CancelDelay", v)
        end
    })

    blatantv2:Input({
        Title = "Equip Delay",
        Default = "0.02",
        Callback = function(v)
            FishingAPI:SetBlatantV2Setting("EquipDelay", v)
        end
    })
    
    -- Toggle
    blatantv2:Toggle({
        Title = "ACTIVATE BLATANT V2",
        Value = false,
        Callback = function(state)
            FishingAPI:SetBlatantV2(state)
        end
    })

    -- Stats Display
    local statsLabel = blatantv2:Label({
        Title = "Current Stats",
        Content = "Inactive"
    })

    -- Update stats
    task.spawn(function()
        while task.wait(1) do
            local stats = FishingAPI:GetBlatantV2Stats()
            if stats.Active then
                statsLabel:Set({
                    Content = string.format("%s | %s | %s", 
                        stats.Mode, stats.Speed, stats.CycleTime)
                })
            else
                statsLabel:Set({Content = "Inactive"})
            end
        end
    end)

    farm:Divider()

    -- ================= FISHING AREA SECTION =================
    local areafish = farm:Section({ Title = "Fishing Area" })

    areafish:Dropdown({
        Title = "Choose Area",
        Values = AreaNames,
        AllowNone = true,
        Callback = function(v)
            FishingAPI:SetSelectedArea(v)
        end
    })

    local freezeToggle
    freezeToggle = areafish:Toggle({
        Title = "Teleport & Freeze at Area",
        Callback = function(state)
            local ok = FishingAPI:SetTeleportFreeze(state, FishingAreas)
            if not ok and freezeToggle then
                freezeToggle:Set(false)
            end
        end
    })

    areafish:Button({
        Title = "Teleport to Choosen Area",
        Callback = function()
            FishingAPI:TeleportToArea(FishingAreas)
        end
    })

    areafish:Button({
        Title = "Save Current Position",
        Callback = function()
            local pos = FishingAPI:SaveCurrentPosition()
            if pos then
                FishingAreas["Custom: Saved"] = pos
                if WindUI then
                    WindUI:Notify({
                        Title = "Posisi Disimpan!",
                        Duration = 3,
                        Icon = "save",
                    })
                end
            end
        end
    })

    areafish:Button({
        Title = "Teleport to SAVED Pos",
        Callback = function()
            FishingAPI:SetSelectedArea("Custom: Saved")
            FishingAPI:TeleportToArea(FishingAreas)
        end
    })

    farm:Divider()
    
    -- ================= CLEANUP SECTION =================
    local cleanup = farm:Section({ Title = "Cleanup" })
    
    cleanup:Button({
        Title = "Stop All & Cleanup",
        Callback = function()
            FishingAPI:Cleanup()
            if WindUI then
                WindUI:Notify({
                    Title = "Cleanup Complete",
                    Content = "All fishing modes stopped",
                    Duration = 3,
                    Icon = "check"
                })
            end
        end
    })
end
