-- =========================================================
-- FISHING TAB (UI ONLY)
-- =========================================================

local FishingAPI = require(path.to.FishingAPI)

local farm = Window:Tab({
    Title = "Fishing",
    Icon = "fish",
})

local areafish = farm:Section({
    Title = "Fishing Area",
    TextSize = 18,
})

areafish:Dropdown({
    Title = "Choose Area",
    Values = AreaNames,
    AllowNone = true,
    Callback = function(option)
        FishingAPI:SetSelectedArea(option)
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
    Title = "Teleport to Chosen Area",
    Callback = function()
        FishingAPI:TeleportToArea(FishingAreas)
    end
})

areafish:Button({
    Title = "Save Current Position",
    Callback = function()
        FishingAPI:SaveCurrentPosition()
        FishingAreas["Custom: Saved"] = FishingAPI:GetSavedPosition()
    end
})

areafish:Button({
    Title = "Teleport to SAVED Pos",
    Callback = function()
        FishingAPI:SetSelectedArea("Custom: Saved")
        FishingAPI:TeleportToArea(FishingAreas)
    end
})
