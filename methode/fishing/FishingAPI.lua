-- =========================================================
-- FISHING API (FULL, NO CUT)
-- =========================================================

local FishingAPI = {}

-- =========================
-- SERVICES
-- =========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RepStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- =========================
-- STATE
-- =========================
local State = {
    SelectedArea = nil,
    FreezeActive = false,
    SavedPosition = nil,
}

-- =========================
-- HELPERS
-- =========================
function FishingAPI:GetHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 5)
end

function FishingAPI:TeleportToLookAt(position, lookVector)
    local hrp = self:GetHRP()
    if not hrp then return false end

    local cf = CFrame.new(position, position + lookVector)
    hrp.CFrame = cf * CFrame.new(0, 0.5, 0)
    return true
end

-- =========================
-- AREA MANAGEMENT
-- =========================
function FishingAPI:SetSelectedArea(areaName)
    State.SelectedArea = areaName
end

function FishingAPI:SaveCurrentPosition()
    local hrp = self:GetHRP()
    if not hrp then return end

    State.SavedPosition = {
        Pos = hrp.Position,
        Look = hrp.CFrame.LookVector
    }
end

function FishingAPI:GetSavedPosition()
    return State.SavedPosition
end

-- =========================
-- TELEPORT & FREEZE LOGIC
-- =========================
function FishingAPI:SetTeleportFreeze(state, FishingAreas)
    State.FreezeActive = state

    local hrp = self:GetHRP()
    if not hrp then return false end

    if not state then
        hrp.Anchored = false
        return true
    end

    local areaData =
        (State.SelectedArea == "Custom: Saved" and State.SavedPosition)
        or FishingAreas[State.SelectedArea]

    if not areaData or not areaData.Pos or not areaData.Look then
        return false
    end

    hrp.Anchored = false
    self:TeleportToLookAt(areaData.Pos, areaData.Look)

    -- server sync 1.5s
    local start = os.clock()
    while os.clock() - start < 1.5 and State.FreezeActive do
        hrp.Velocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame =
            CFrame.new(areaData.Pos, areaData.Pos + areaData.Look)
            * CFrame.new(0, 0.5, 0)

        RunService.Heartbeat:Wait()
    end

    if State.FreezeActive then
        hrp.Anchored = true
    end

    return true
end

function FishingAPI:TeleportToArea(FishingAreas)
    if not State.SelectedArea then return false end

    local areaData =
        (State.SelectedArea == "Custom: Saved" and State.SavedPosition)
        or FishingAreas[State.SelectedArea]

    if not areaData then return false end

    if State.FreezeActive then
        State.FreezeActive = false
        task.wait(0.1)
    end

    return self:TeleportToLookAt(areaData.Pos, areaData.Look)
end

return FishingAPI
