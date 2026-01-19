-- =========================================================
-- PLAYER TAB UI (FULL FINAL)
-- =========================================================

return function(Window, PlayerAPI, WindUI)

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local tab = Window:Tab({ Title="Player", Icon="user" })

    local move = tab:Section({ Title="Movement" })
    move:Slider({ Title="WalkSpeed", Value={Min=16,Max=200,Default=16},
        Callback=function(v) PlayerAPI:SetWalkSpeed(v) end })
    move:Slider({ Title="JumpPower", Value={Min=50,Max=200,Default=50},
        Callback=function(v) PlayerAPI:SetJumpPower(v) end })
    move:Button({ Title="Reset Movement", Callback=function() PlayerAPI:ResetMovement() end })
    move:Toggle({ Title="Freeze Player", Callback=function(v) PlayerAPI:SetFreeze(v) end })

    local ab = tab:Section({ Title="Abilities" })
    ab:Toggle({ Title="Infinite Jump", Callback=function(v) PlayerAPI:SetInfiniteJump(v) end })
    ab:Toggle({ Title="No Clip", Callback=function(v) PlayerAPI:SetNoClip(v) end })
    ab:Toggle({ Title="Fly Mode", Callback=function(v) PlayerAPI:SetFly(v,60) end })
    ab:Toggle({ Title="Walk On Water", Callback=function(v) PlayerAPI:SetWalkOnWater(v) end })

    local stream = tab:Section({ Title="Streamer Mode" })
    stream:Input({ Title="Fake Name", Value=".gg/NYXHUB", Callback=function(v) PlayerAPI:SetFakeName(v) end })
    stream:Input({ Title="Fake Level", Value="Lvl. 969", Callback=function(v) PlayerAPI:SetFakeLevel(v) end })
    stream:Dropdown({
        Title="Mode",
        Values={{Name="Self",Value="SELF"},{Name="Selected",Value="SELECTED"},{Name="All",Value="ALL"}},
        Default="SELF",
        Callback=function(v) PlayerAPI:SetHideMode(v) end
    })
    stream:Toggle({ Title="Hide Usernames", Callback=function(v) PlayerAPI:SetHideUsernames(v) end })

    local sel = tab:Section({ Title="Select Players" })
    local function refresh()
        sel:Clear()
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer then
                sel:Toggle({ Title=p.Name, Callback=function(v)
                    if v then PlayerAPI:AddHideTarget(p) else PlayerAPI:RemoveHideTarget(p) end
                end })
            end
        end
    end
    refresh()
    Players.PlayerAdded:Connect(refresh)
    Players.PlayerRemoving:Connect(refresh)

    local other = tab:Section({ Title="Other" })
    other:Toggle({ Title="Player ESP", Callback=function(v) PlayerAPI:SetESP(v) end })
    other:Button({ Title="Reset Player Inplace", Callback=function() PlayerAPI:ResetCharacterInPlace() end })
    other:Button({ Title="Reset All", Callback=function() PlayerAPI:ResetAll() end })

end
