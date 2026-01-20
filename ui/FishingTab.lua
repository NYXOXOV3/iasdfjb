-- =========================================================
-- FISHING TAB (ALL BLATANT MODES)
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

    -- ================= BLATANT V2 SECTION =================
    local blatantv2 = farm:Section({ Title = "⚡ BLATANT V2 (ULTRA)" })

    blatantv2:Input({
        Title = "Charge Delay",
        Default = "0.007",
        Callback = function(v) FishingAPI:SetBlatantSetting("BlatantV2", "ChargeDelay", v) end
    })

    blatantv2:Input({
        Title = "Complete Delay",
        Default = "0.001",
        Callback = function(v) FishingAPI:SetBlatantSetting("BlatantV2", "CompleteDelay", v) end
    })

    blatantv2:Input({
        Title = "Cancel Delay",
        Default = "0.001",
        Callback = function(v) FishingAPI:SetBlatantSetting("BlatantV2", "CancelDelay", v) end
    })
    
    blatantv2:Toggle({
        Title = "ACTIVATE BLATANT V2",
        Value = false,
        Callback = function(state)
            FishingAPI:SetBlatantMode("BlatantV2", state)
        end
    })

    -- ================= BLATANT V3 SECTION =================
    local blatantv3 = farm:Section({ Title = "🔥 BLATANT V3 (OPTIMIZED)" })

    blatantv3:Input({
        Title = "Complete Delay",
        Default = "0.73",
        Callback = function(v) FishingAPI:SetBlatantSetting("BlatantV3", "CompleteDelay", v) end
    })

    blatantv3:Input({
        Title = "Cancel Delay",
        Default = "0.3",
        Callback = function(v) FishingAPI:SetBlatantSetting("BlatantV3", "CancelDelay", v) end
    })

    blatantv3:Input({
        Title = "ReCast Delay",
        Default = "0.001",
        Callback = function(v) FishingAPI:SetBlatantSetting("BlatantV3", "ReCastDelay", v) end
    })
    
    blatantv3:Toggle({
        Title = "ACTIVATE BLATANT V3",
        Value = false,
        Callback = function(state)
            FishingAPI:SetBlatantMode("BlatantV3", state)
        end
    })

    -- ================= BLATANT V4 SECTION =================
    local blatantv4 = farm:Section({ Title = "🎯 BLATANT V4 (EVENT)" })

    blatantv4:Input({
        Title = "Fishing Delay",
        Default = "0.05",
        Callback = function(v) FishingAPI:SetBlatantSetting("BlatantV4", "FishingDelay", v) end
    })

    blatantv4:Input({
        Title = "Cancel Delay",
        Default = "0.01",
        Callback = function(v) FishingAPI:SetBlatantSetting("BlatantV4", "CancelDelay", v) end
    })

    blatantv4:Input({
        Title = "Timeout Delay",
        Default = "0.8",
        Callback = function(v) FishingAPI:SetBlatantSetting("BlatantV4", "TimeoutDelay", v) end
    })
    
    blatantv4:Toggle({
        Title = "ACTIVATE BLATANT V4",
        Value = false,
        Callback = function(state)
            FishingAPI:SetBlatantMode("BlatantV4", state)
        end
    })

    -- ================= BLATANT V5 SECTION =================
    local blatantv5 = farm:Section({ Title = "💎 BLATANT V5 (CLEAN)" })

    blatantv5:Input({
        Title = "Complete Delay",
        Default = "0.001",
        Callback = function(v) FishingAPI:SetBlatantSetting("BlatantV5", "CompleteDelay", v) end
    })

    blatantv5:Input({
        Title = "Cancel Delay",
        Default = "0.001",
        Callback = function(v) FishingAPI:SetBlatantSetting("BlatantV5", "CancelDelay", v) end
    })
    
    blatantv5:Toggle({
        Title = "ACTIVATE BLATANT V5",
        Value = false,
        Callback = function(state)
            FishingAPI:SetBlatantMode("BlatantV5", state)
        end
    })

    -- ================= FAST PERFECT SECTION =================
    local fastperfect = farm:Section({ Title = "🚀 FAST PERFECT" })

    fastperfect:Input({
        Title = "Fishing Delay",
        Default = "0.01",
        Callback = function(v) FishingAPI:SetBlatantSetting("FastPerfect", "FishingDelay", v) end
    })

    fastperfect:Input({
        Title = "Hook Detection Delay",
        Default = "0.01",
        Callback = function(v) FishingAPI:SetBlatantSetting("FastPerfect", "HookDetectionDelay", v) end
    })

    fastperfect:Input({
        Title = "Timeout Delay",
        Default = "0.5",
        Callback = function(v) FishingAPI:SetBlatantSetting("FastPerfect", "TimeoutDelay", v) end
    })
    
    fastperfect:Toggle({
        Title = "ACTIVATE FAST PERFECT",
        Value = false,
        Callback = function(state)
            FishingAPI:SetBlatantMode("FastPerfect", state)
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
        Title = "🛑 STOP ALL FISHING",
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

    cleanup:Paragraph({
        Title = "ℹ️ Mode Comparison",
        Content = "V2: Ultra Fast (7ms)\nV3: Optimized (730ms)\nV4: Event Based\nV5: Clean Fast\nPerfect: Hook Detection"
    })

    -- Auto stats update
    task.spawn(function()
        while task.wait(3) do
            local modes = {"BlatantV2", "BlatantV3", "BlatantV4", "BlatantV5", "FastPerfect"}
            for _, mode in ipairs(modes) do
                local stats = FishingAPI:GetBlatantStats(mode)
                if stats.Active then
                    print(string.format("[%s] Active | %s", mode, stats.Speed or ("Cycle: " .. stats.Cycle)))
                end
            end
        end
    end)
end
