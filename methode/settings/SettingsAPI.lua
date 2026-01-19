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
-- STREAM
-- =========================================================

-- HIDE USERNAME / SOLACE DISGUISE
function PlayerAPI:SetHideUsername(state)
    _G.SolaceDisguise = state

    if not state then
        if getgenv().SolaceConfig then
            getgenv().SolaceConfig.Enabled = false
        end
        warn("[Solace] Disabled (rejoin required to fully revert)")
        return
    end

    -- =========================
    -- CONFIG
    -- =========================
    if not getgenv().SolaceConfig then
        getgenv().SolaceConfig = {
            Headless = false,
            FakeDisplayName = "Solace",
            FakeName = "Solace",
            FakeId = 13886182,
            Enabled = true
        }
    else
        local cfg = getgenv().SolaceConfig
        cfg.FakeDisplayName = "Solace"
        cfg.FakeName = "Solace"
        cfg.FakeId = 13886182
        cfg.Enabled = true
    end

    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer

    -- =========================
    -- SAVE ORIGINAL DATA
    -- =========================
    if not _G.OriginalPlayerData then
        _G.OriginalPlayerData = {
            UserId = tostring(lp.UserId),
            Name = lp.Name,
            DisplayName = lp.DisplayName
        }
    end

    -- =========================
    -- TEXT PROCESSOR
    -- =========================
    local function processtext(text)
        if not text or text == "" then return text end

        text = string.gsub(text, _G.OriginalPlayerData.Name, getgenv().SolaceConfig.FakeName)
        text = string.gsub(text, _G.OriginalPlayerData.UserId, tostring(getgenv().SolaceConfig.FakeId))
        text = string.gsub(text, _G.OriginalPlayerData.DisplayName, getgenv().SolaceConfig.FakeDisplayName)

        return text
    end

    local function processTextElement(el)
        if not (el:IsA("TextLabel") or el:IsA("TextButton") or el:IsA("TextBox")) then return end
        if el:GetAttribute("SolaceTextConnected") then return end

        el:SetAttribute("SolaceTextConnected", true)
        el.Text = processtext(el.Text)

        el:GetPropertyChangedSignal("Text"):Connect(function()
            el.Text = processtext(el.Text)
        end)
    end

    local function processAllText()
        for _, v in ipairs(game:GetDescendants()) do
            processTextElement(v)
        end
    end

    -- =========================
    -- CHARACTER DISGUISE
    -- =========================
    local function disguisechar(char, id)
        if not char then return end

        task.spawn(function()
            local hum = char:WaitForChild("Humanoid", 5)
            local head = char:WaitForChild("Head", 5)
            if not hum or not head then return end

            local desc
            repeat
                task.wait(1)
            until pcall(function()
                desc = Players:GetHumanoidDescriptionFromUserId(id)
            end)

            local originalDesc = hum:FindFirstChildOfClass("HumanoidDescription")
            if originalDesc then
                desc.HeightScale = originalDesc.HeightScale
            end

            char.Archivable = true
            local clone = char:Clone()
            clone.Parent = workspace

            for _, v in ipairs(clone:GetChildren()) do
                if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
                    v:Destroy()
                end
            end

            clone.Humanoid:ApplyDescriptionClientServer(desc)

            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
                    v.Parent = game
                end
            end

            if not _G.SolaceChildAddedConnection then
                _G.SolaceChildAddedConnection = char.ChildAdded:Connect(function(v)
                    if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") then
                        v.Parent = game
                    end
                end)
            end

            for _, v in ipairs(clone:GetChildren()) do
                if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
                    v.Parent = char
                end
            end

            clone:Destroy()
        end)
    end

    -- =========================
    -- APPLY
    -- =========================
    processAllText()

    if not _G.SolaceDescendantConnection then
        _G.SolaceDescendantConnection =
            game.DescendantAdded:Connect(processTextElement)
    end

    if lp.Character then
        task.delay(1, function()
            disguisechar(lp.Character, getgenv().SolaceConfig.FakeId)
        end)
    end

    if not _G.SolaceCharacterConnection then
        _G.SolaceCharacterConnection =
            lp.CharacterAdded:Connect(function(char)
                task.wait(2)
                processAllText()
                disguisechar(char, getgenv().SolaceConfig.FakeId)
            end)
    end

    print("[Solace] Hide Username enabled (persistent)")
end


function PlayerAPI:ResetCharacterInPlace()
    local player = LocalPlayer
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local cam = workspace.CurrentCamera

    if not hrp or not hum or not cam then return end

    -- Simpan transform & kamera
    local savedCFrame = hrp.CFrame
    local camCFrame = cam.CFrame

    -- =========================
    -- PRE-EMPTIVE RESPAWN HANDLER
    -- =========================
    local conn
    conn = player.CharacterAdded:Connect(function(newChar)
        conn:Disconnect()

        -- Tunggu Humanoid & HRP
        local newHum = newChar:WaitForChild("Humanoid", 5)
        local newHRP = newChar:WaitForChild("HumanoidRootPart", 5)
        if not newHum or not newHRP then return end

        -- 🔑 CAMERA DULU
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = newHum
        cam.CFrame = camCFrame

        task.wait() -- 1 frame

        -- 🔑 TELEPORT CEPAT (ANTI SNAP)
        newHRP.CFrame = savedCFrame
    end)

    -- =========================
    -- TRIGGER RESPAWN
    -- =========================
    hum.Health = 0
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

-- =========================================================
-- DISABLE 3D RENDERING (ULTRA LOW MODE)
-- =========================================================

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local UltraData = {
    Parts = {},
    Effects = {},
    Clothes = {},
    Lighting = {},
    Enabled = false
}

function PlayerAPI:SetDisable3DRendering(state)
    if UltraData.Enabled == state then return end
    UltraData.Enabled = state

    if state then
        --------------------
        -- SAVE LIGHTING
        --------------------
        if not UltraData.Lighting.Saved then
            UltraData.Lighting = {
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                Brightness = Lighting.Brightness,
                FogEnd = Lighting.FogEnd,
                Saved = true
            }
        end

        Lighting.Ambient = Color3.fromRGB(180,180,180)
        Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)
        Lighting.Brightness = 1
        Lighting.FogEnd = 1e10

        --------------------
        -- FLATTEN WORLD
        --------------------
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                if not UltraData.Parts[obj] then
                    UltraData.Parts[obj] = {
                        Color = obj.Color,
                        Material = obj.Material
                    }
                end
                obj.Color = Color3.fromRGB(200,200,200)
                obj.Material = Enum.Material.SmoothPlastic
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                if not UltraData.Parts[obj] then
                    UltraData.Parts[obj] = {Texture = obj.Texture}
                end
                obj.Texture = ""
            end
        end

        --------------------
        -- DISABLE EFFECTS
        --------------------
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                if not UltraData.Effects[obj] then
                    UltraData.Effects[obj] = {Enabled = obj.Enabled}
                end
                obj.Enabled = false
            end
        end

        --------------------
        -- STRIP CLOTHES (LOCAL)
        --------------------
        local char = LocalPlayer.Character
        if char then
            UltraData.Clothes[char] = {}
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("Accessory") then
                    table.insert(UltraData.Clothes[char], item)
                    item.Parent = nil
                end
            end
        end

    else
        --------------------
        -- RESTORE LIGHTING
        --------------------
        local L = UltraData.Lighting
        if L.Saved then
            Lighting.Ambient = L.Ambient
            Lighting.OutdoorAmbient = L.OutdoorAmbient
            Lighting.Brightness = L.Brightness
            Lighting.FogEnd = L.FogEnd
        end

        --------------------
        -- RESTORE WORLD
        --------------------
        for obj, data in pairs(UltraData.Parts) do
            if obj and obj.Parent then
                if data.Color then obj.Color = data.Color end
                if data.Material then obj.Material = data.Material end
                if data.Texture then obj.Texture = data.Texture end
            end
        end

        --------------------
        -- RESTORE EFFECTS
        --------------------
        for obj, eff in pairs(UltraData.Effects) do
            if obj and obj.Parent then
                obj.Enabled = eff.Enabled
            end
        end

        --------------------
        -- RESTORE CLOTHES
        --------------------
        local char = LocalPlayer.Character
        if char and UltraData.Clothes[char] then
            for _, item in ipairs(UltraData.Clothes[char]) do
                item.Parent = char
            end
        end
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
