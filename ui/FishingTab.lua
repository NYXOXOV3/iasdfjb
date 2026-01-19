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
        Icon = "fish"
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
        Title = "🚀 BLATANT V2 (BRUTAL)"
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

    

    -- Emergency Stop Button
    blatantv2:Button({
        Title = "🛑 EMERGENCY STOP",
        Callback = function()
            FishingAPI:SetBlatantV2(false)
            if WindUI then
                WindUI:Notify({
                    Title = "Blatant V2 Stopped",
                    Content = "Brutal mode deactivated",
                    Duration = 3,
                    Icon = "alert-octagon"
                })
            end
        end
    })

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
                        Icon = "save"
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
    local cleanup = farm:Section({ Title = "System" })
    
    cleanup:Button({
        Title = "🛑 STOP ALL FISHING",
        Callback = function()
            FishingAPI:Cleanup()
            if WindUI then
                WindUI:Notify({
                    Title = "All Fishing Stopped",
                    Content = "Legit, Normal, Blatant, and V2 modes disabled",
                    Duration = 3,
                    Icon = "check"
                })
            end
        end
    })

    -- Performance Info
    cleanup:Paragraph({
        Title = "ℹ️ Performance Info",
        Content = "Legit: Safe but slow\nNormal: Medium speed\nBlatant: Fast, detectable\nV2: Extreme, high risk"
    })

    -- Console logging for debugging
    task.spawn(function()
        while task.wait(5) do
            local stats = FishingAPI:GetBlatantV2Stats()
            if stats.Active then
                print(string.format("[FishingAPI] BlatantV2 Active | %s | %s", 
                    stats.Mode, stats.Speed))
            end
        end
    end)
end
