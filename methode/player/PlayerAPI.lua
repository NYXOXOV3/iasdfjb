-- =========================================================
-- PLAYER API
-- NYXHUB - Fish It
-- =========================================================

local PlayerAPI = {}

-- =========================================================
-- SERVICES
-- =========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- =========================================================
-- INTERNAL STATE
-- =========================================================
local state = {
    WalkSpeed = nil,
    JumpPower = nil,

    Frozen = false,
    InfiniteJump = false,
    NoClip = false,
    Fly = false,
}

local connections = {}

-- =========================================================
-- HELPERS
-- =========================================================
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
    local char = getCharacter()
    return char:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    local char = getCharacter()
    return char:WaitForChild("HumanoidRootPart")
end

-- =========================================================
-- MOVEMENT
-- =========================================================
function PlayerAPI:SetWalkSpeed(value)
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = value
        state.WalkSpeed = value
    end
end

function PlayerAPI:SetJumpPower(value)
    local hum = getHumanoid()
    if hum then
        hum.JumpPower = value
        state.JumpPower = value
    end
end

function PlayerAPI:ResetMovement()
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        state.WalkSpeed = 16
        state.JumpPower = 50
    end
end

-- =========================================================
-- FREEZE
-- =========================================================
function PlayerAPI:SetFreeze(enabled)
    local hrp = getHRP()
    if not hrp then return end

    hrp.Anchored = enabled
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.Velocity = Vector3.zero

    state.Frozen = enabled
end

-- =========================================================
-- INFINITE JUMP
-- =========================================================
function PlayerAPI:SetInfiniteJump(enabled)
    state.InfiniteJump = enabled

    if enabled then
        connections.InfJump = UserInputService.JumpRequest:Connect(function()
            local hum = getHumanoid()
            if hum and hum.Health > 0 then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if connections.InfJump then
            connections.InfJump:Disconnect()
            connections.InfJump = nil
        end
    end
end

-- =========================================================
-- NO CLIP
-- =========================================================
function PlayerAPI:SetNoClip(enabled)
    state.NoClip = enabled

    if enabled then
        connections.NoClip = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end

            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if connections.NoClip then
            connections.NoClip:Disconnect()
            connections.NoClip = nil
        end

        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- =========================================================
-- FLY (SIMPLE & STABLE)
-- =========================================================
function PlayerAPI:SetFly(enabled, speed)
    speed = speed or 60
    state.Fly = enabled

    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return end

    if enabled then
        local bg = Instance.new("BodyGyro")
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp

        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = hrp

        connections.Fly = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            bg.CFrame = cam.CFrame

            local move = hum.MoveDirection
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                move += Vector3.new(0, 1, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                move -= Vector3.new(0, 1, 0)
            end

            bv.Velocity = move.Magnitude > 0 and move.Unit * speed or Vector3.zero
        end)

        connections.FlyBG = bg
        connections.FlyBV = bv
    else
        if connections.Fly then connections.Fly:Disconnect() end
        if connections.FlyBG then connections.FlyBG:Destroy() end
        if connections.FlyBV then connections.FlyBV:Destroy() end

        connections.Fly = nil
        connections.FlyBG = nil
        connections.FlyBV = nil
    end
end

-- =========================================================
-- CLEANUP (ANTI LEAK)
-- =========================================================
function PlayerAPI:Shutdown()
    for _, conn in pairs(connections) do
        pcall(function()
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            elseif typeof(conn) == "Instance" then
                conn:Destroy()
            end
        end)
    end
    connections = {}
end

return PlayerAPI
