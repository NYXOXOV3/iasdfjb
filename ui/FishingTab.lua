-- =========================================================
-- FISHING TAB (UI ONLY)
-- =========================================================
return function(Window, FishingAPI, WindUI)

    if not FishingAPI then
        warn("[SETTING TAB] FishingAPI missing, skipped")
        return
    end

task.wait(0.5)

local farm = Window:Tab({
    Title = "Fishing",
    Icon = "fish",
})

local autofish = farm:Section({ Title = "Auto Fishing" })

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

local blatant = farm:Section({ Title = "Blatant Mode" })

blatant:Toggle({
    Title = "Instant Fishing (Blatant)",
    Callback = function(v)
        FishingAPI:SetBlatant(v)
    end
})

blatant:Dropdown({
    Title = "Blatant Mode",
    Values = { "Old", "New" },
    Callback = function(v)
        FishingAPI:SetBlatantMode(v)
    end
})

blatant:Input({
    Title = "Cancel Delay",
    Default = "1.75",
    Callback = function(v)
        FishingAPI:SetBlatantDelays(tonumber(v), nil)
    end
})

blatant:Input({
    Title = "Complete Delay",
    Default = "1.33",
    Callback = function(v)
        FishingAPI:SetBlatantDelays(nil, tonumber(v))
    end
})

farm:Divider()

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
        FishingAreas["Custom: Saved"] = pos
    end
})

areafish:Button({
    Title = "Teleport to SAVED Pos",
    Callback = function()
        FishingAPI:SetSelectedArea("Custom: Saved")
        FishingAPI:TeleportToArea(FishingAreas)
    end
})
end
