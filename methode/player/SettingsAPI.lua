-- =========================================================
-- SETTINGS API
-- NYXHUB - Fish It (FIXED & STABLE)
-- =========================================================

local SettingsAPI = {}

-- =========================================================
-- SERVICES
-- =========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- =========================================================
-- STATE
-- =========================================================
local state = {
    WalkSpeed = 16,
    JumpPower = 50,

    InfiniteJump = false,
    NoClip = false,
    Fly = false,
    WalkOnWater = false,
    InfiniteZoom = false,
    Frozen = false,

    HideUsername = false,

    DisableRendering = false,
    VisualCache = {
        Parts = {},
        Effects = {},
        Clothes = {},
        Lighting = {}
    }
}

local connections = {}
local espCache = {}
local espEnabled = false
local waterConn, waterPlatform

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

local function clearConnection(name)
    if connections[name] then
        connections[name]:Disconnect()
        connections[name] = nil
    end
end

-- =========================================================
-- SECURITY
-- =========================================================
function SettingsAPI:SetHideUsername(enabled)
    state.HideUsername = enabled

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.DisplayDistanceType = enabled
                    and Enum.HumanoidDisplayDistanceType.None
                    or Enum.HumanoidDisplayDistanceType.Viewer
            end
        end
    end
end

-- =========================================================
-- MOVEMENT
-- =========================================================
function SettingsAPI:SetWalkSpeed(v)
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = v
        state.WalkSpeed = v
    end
end

function SettingsAPI:SetJumpPower(v)
    local hum = getHumanoid()
    if hum then
        hum.JumpPower = v
        state.JumpPower = v
    end
end

function SettingsAPI:ResetMovement()
    self:SetWalkSpeed(16)
    self:SetJumpPower(50)
end

-- =========================================================
-- MODES
-- =========================================================
function SettingsAPI:SetInfiniteJump(enabled)
    state.InfiniteJump = enabled
    clearConnection("InfJump")

    if enabled then
        connections.InfJump =
            UserInputService.JumpRequest:Connect(function()
                local hum = getHumanoid()
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
    end
end

function SettingsAPI:SetNoClip(enabled)
    state.NoClip = enabled
    clearConnection("NoClip")

    if enabled then
        connections.NoClip =
            RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end)
    else
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end
        end
    end
end

-- =========================================================
-- WALK ON WATER
-- =========================================================
function SettingsAPI:SetWalkOnWater(enabled)
    state.WalkOnWater = enabled

    if not enabled then
        if waterConn then waterConn:Disconnect() end
        if waterPlatform then waterPlatform:Destroy() end
        waterConn, waterPlatform = nil, nil
        return
    end

    waterPlatform = Instance.new("Part")
    waterPlatform.Anchored = true
    waterPlatform.CanCollide = true
    waterPlatform.Transparency = 1
    waterPlatform.Size = Vector3.new(12, 1, 12)
    waterPlatform.Parent = Workspace

    waterConn = RunService.RenderStepped:Connect(function()
        local hrp = getHRP()
        local ray = Workspace:Raycast(
            hrp.Position + Vector3.new(0, 5, 0),
            Vector3.new(0, -200, 0),
            RaycastParams.new()
        )

        if ray and ray.Material == Enum.Material.Water then
            waterPlatform.Position =
                Vector3.new(hrp.Position.X, ray.Position.Y, hrp.Position.Z)
        else
            waterPlatform.Position = Vector3.new(0, -500, 0)
        end
    end)
end

-- =========================================================
-- CAMERA
-- =========================================================
function SettingsAPI:SetInfiniteZoom(enabled)
    state.InfiniteZoom = enabled
    local cam = Workspace.CurrentCamera
    if cam then
        cam.CameraMaxZoomDistance = enabled and 200 or 32
        cam.CameraMinZoomDistance = 0.5
    end
end

-- =========================================================
-- VISUAL
-- =========================================================
function SettingsAPI:SetDisableRendering(enabled)
    state.DisableRendering = enabled

    if not enabled then
        local L = state.VisualCache.Lighting
        if L.Saved then
            Lighting.Ambient = L.Ambient
            Lighting.OutdoorAmbient = L.OutdoorAmbient
            Lighting.Brightness = L.Brightness
            Lighting.FogEnd = L.FogEnd
        end
        return
    end

    state.VisualCache.Lighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        FogEnd = Lighting.FogEnd,
        Saved = true
    }

    Lighting.FogEnd = 1e10
    Lighting.Brightness = 1
end

-- =========================================================
-- ESP
-- =========================================================
function SettingsAPI:SetESP(enabled)
    espEnabled = enabled

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            SettingsAPI:_UpdateESP(plr)
        end
    end
end

function SettingsAPI:_UpdateESP(plr)
    if not espEnabled then
        if espCache[plr] then
            espCache[plr]:Destroy()
            espCache[plr] = nil
        end
        return
    end

    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or espCache[plr] then return end

    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(140, 40)
    gui.Adornee = hrp
    gui.AlwaysOnTop = true
    gui.Parent = hrp

    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(255, 200, 200)
    label.Font = Enum.Font.GothamBold
    label.Text = plr.DisplayName or plr.Name

    espCache[plr] = gui
end

Players.PlayerRemoving:Connect(function(plr)
    if espCache[plr] then
        espCache[plr]:Destroy()
        espCache[plr] = nil
    end
end)

-- =========================================================
-- RESET
-- =========================================================
function SettingsAPI:ResetAll()
    self:ResetMovement()
    self:SetInfiniteJump(false)
    self:SetNoClip(false)
    self:SetWalkOnWater(false)
    self:SetInfiniteZoom(false)
    self:SetESP(false)
    self:SetDisableRendering(false)
    self:SetHideUsername(false)
end

return SettingsAPI
