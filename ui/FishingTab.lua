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

    -- ================= BLATANT MODE SECTION =================
    local blatant = farm:Section({ Title = "Blatant Mode" })

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
        Title = "Instant Fishing (Blatant)",
        Callback = function(state) FishingAPI:SetActive(state) end
    })

    farm:Divider()

    -- ================= BLATANT V2 SECTION =================
    local blatantv2 = farm:Section({ Title = "🚀 BLATANT V2 (ULTRA)" })

    -- Settings
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
    
    -- Toggle
    blatantv2:Toggle({
        Title = "ACTIVATE BLATANT V2",
        Value = false,
        Callback = function(state) FishingAPI:SetBlatantV2(state) end
    })

    -- Stats Display
    local statsParagraph = blatantv2:Paragraph({
        Title = "📊 Current Stats",
        Content = "Status: Inactive\nSpeed: 0 fish/sec\nCycle: 0ms"
    })

    -- Update stats automatically
    task.spawn(function()
        while task.wait(1) do
            local stats = FishingAPI:GetBlatantV2Stats()
            if stats.Active then
                statsParagraph:Set({
                    Content = string.format(
                        "Status: ACTIVE\nSpeed: %s\nCycle: %s",
                        stats.Speed, stats.CycleTime
                    )
                })
            else
                statsParagraph:Set({
                    Content = "Status: INACTIVE\nSpeed: 0 fish/sec\nCycle: 0ms"
                })
            end
        end
    end)

    -- Emergency Stop
    blatantv2:Button({
        Title = "🛑 EMERGENCY STOP",
        Callback = function()
            FishingAPI:SetBlatantV2(false)
            if WindUI then
                WindUI:Notify({
                    Title = "Blatant V2 Stopped",
                    Content = "Ultra mode deactivated",
                    Duration = 2,
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
        Callback = function(v) FishingAPI:SetSelectedArea(v) end
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
        Title = "Teleport to Area",
        Callback = function() FishingAPI:TeleportToArea(FishingAreas) end
    })

    areafish:Button({
        Title = "Save Position",
        Callback = function()
            local pos = FishingAPI:SaveCurrentPosition()
            if pos then
                FishingAreas["Custom: Saved"] = pos
                if WindUI then
                    WindUI:Notify({
                        Title = "Position Saved",
                        Duration = 2,
                        Icon = "save"
                    })
                end
            end
        end
    })

    farm:Divider()
    
    -- ================= CLEANUP SECTION =================
    local cleanup = farm:Section({ Title = "System" })
    
    cleanup:Button({
        Title = "STOP ALL FISHING",
        Callback = function()
            FishingAPI:Cleanup()
            if WindUI then
                WindUI:Notify({
                    Title = "All Fishing Stopped",
                    Duration = 2,
                    Icon = "check"
                })
            end
        end
    })
end
