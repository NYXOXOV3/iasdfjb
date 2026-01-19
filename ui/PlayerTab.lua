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
    WalkOnWater = false,
    InfiniteZoom = false,
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
-- INFINITE ZOOM
-- =========================================================
function PlayerAPI:SetInfiniteZoom(enabled)
    state.InfiniteZoom = enabled
    
    local function updateCameraZoom()
        local camera = workspace.CurrentCamera
        if camera then
            if enabled then
                camera.CameraMaxZoomDistance = 200  -- Zoom maksimal 200
                camera.CameraMinZoomDistance = 0.5  -- Zoom minimal 0.5
            else
                camera.CameraMaxZoomDistance = 32   -- Kembali ke normal (32)
                camera.CameraMinZoomDistance = 0.5  -- Tetap 0.5
            end
        end
    end

    if enabled then
        -- Update zoom settings
        updateCameraZoom()
        
        -- Connect untuk reset zoom saat kamera berubah
        if not connections.CameraChanged then
            connections.CameraChanged = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
                if state.InfiniteZoom then
                    updateCameraZoom()
                end
            end)
        end
    else
        -- Reset zoom ke normal
        updateCameraZoom()
        
        -- Cleanup connections
        if connections.CameraChanged then
            connections.CameraChanged:Disconnect()
            connections.CameraChanged = nil
        end
    end
end

-- Tambahkan juga fungsi untuk mengatur zoom distance secara manual jika diperlukan
function PlayerAPI:SetCustomZoomDistance(minDistance, maxDistance)
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraMinZoomDistance = math.max(0.1, minDistance or 0.5)
        camera.CameraMaxZoomDistance = math.min(1000, maxDistance or 200)  -- Batas atas 1000 untuk safety
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

-- =========================
-- WALK ON WATER
-- =========================
local waterConn
local waterPlatform

function PlayerAPI:SetWalkOnWater(enabled)
    state.WalkOnWater = enabled

    if enabled then
        if not waterPlatform then
            waterPlatform = Instance.new("Part")
            waterPlatform.Anchored = true
            waterPlatform.CanCollide = true
            waterPlatform.Transparency = 1
            waterPlatform.Size = Vector3.new(15, 1, 15)
            waterPlatform.Parent = workspace
        end

        waterConn = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = { workspace.Terrain }
            rayParams.FilterType = Enum.RaycastFilterType.Include
            rayParams.IgnoreWater = false

            local result = workspace:Raycast(
                hrp.Position + Vector3.new(0, 5, 0),
                Vector3.new(0, -500, 0),
                rayParams
            )

            if result and result.Material == Enum.Material.Water then
                waterPlatform.Position =
                    Vector3.new(hrp.Position.X, result.Position.Y, hrp.Position.Z)

                if hrp.Position.Y < result.Position.Y + 2 then
                    hrp.CFrame =
                        CFrame.new(hrp.Position.X, result.Position.Y + 3.2, hrp.Position.Z)
                end
            else
                waterPlatform.Position = Vector3.new(0, -500, 0)
            end
        end)
    else
        if waterConn then waterConn:Disconnect() waterConn = nil end
        if waterPlatform then waterPlatform:Destroy() waterPlatform = nil end
    end
end

-- =========================
-- PLAYER ESP
-- =========================
local espEnabled = false
local espCache = {}

function PlayerAPI:SetESP(enabled)
    espEnabled = enabled

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            PlayerAPI:_UpdateESP(plr)
        end
    end
end

function PlayerAPI:_UpdateESP(plr)
    if not espEnabled then
        if espCache[plr] then
            espCache[plr]:Destroy()
            espCache[plr] = nil
        end
        return
    end

    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if espCache[plr] then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "NYXHUB_ESP"
    gui.Adornee = hrp
    gui.Size = UDim2.new(0, 140, 0, 40)
    gui.StudsOffset = Vector3.new(0, 2.5, 0)
    gui.AlwaysOnTop = true
    gui.Parent = hrp

    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(255, 230, 230)
    label.Text = plr.DisplayName or plr.Name

    espCache[plr] = gui
end
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        wait(1)
        PlayerAPI:_UpdateESP(plr)
    end)
end)

-- =========================
-- RESET CHARACTER
-- =========================
function PlayerAPI:ResetCharacterInPlace()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local lastPos = hrp.Position
    hum.Health = 0

    LocalPlayer.CharacterAdded:Wait()
    task.wait(0.5)

    local newHRP =
        LocalPlayer.Character:WaitForChild("HumanoidRootPart", 5)
    if newHRP then
        newHRP.CFrame = CFrame.new(lastPos + Vector3.new(0, 3, 0))
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
