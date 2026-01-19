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
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

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
    AntiStaff = false,
    InfiniteZoom = false,
    LowGraphics = false,
    Disable3DRendering = false,
}

local connections = {}
local originalSettings = {}

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
-- ANTI STAFF SYSTEM
-- =========================================================
local knownStaffNames = {
    "Admin", "Moderator", "Staff", "Developer", "Dev",
    "Owner", "Founder", "Manager", "Support", "Helper",
    "Roblox", "Builder", "Scripter", "Mod", "Officer"
}

local staffPrefixes = {"[STAFF]", "[ADMIN]", "[MOD]", "[DEV]"}
local staffSuffixes = {"_STAFF", "_ADMIN", "_MOD", "_DEV", "_TEAM"}

local detectedStaff = {}
local staffWarnings = {}

local function IsLikelyStaff(player)
    if not player then return false, "Invalid player" end
    
    local displayName = player.DisplayName:lower()
    local userName = player.Name:lower()
    local userId = player.UserId
    
    -- Check known staff names in display name
    for _, staffName in ipairs(knownStaffNames) do
        if displayName:find(staffName:lower(), 1, true) then
            return true, "Staff name in display name: " .. staffName
        end
        if userName:find(staffName:lower(), 1, true) then
            return true, "Staff name in username: " .. staffName
        end
    end
    
    -- Check prefixes
    for _, prefix in ipairs(staffPrefixes) do
        if displayName:find(prefix:lower(), 1, true) then
            return true, "Staff prefix detected: " .. prefix
        end
    end
    
    -- Check suffixes
    for _, suffix in ipairs(staffSuffixes) do
        if displayName:find(suffix:lower(), 1, true) then
            return true, "Staff suffix detected: " .. suffix
        end
    end
    
    -- Check for special user IDs (often developers)
    if userId <= 1000 then
        return true, "Suspiciously low UserID: " .. userId
    end
    
    -- Check if player has friends in game (staff often play together)
    local friendCount = 0
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if player:IsFriendsWith(otherPlayer.UserId) and otherPlayer ~= player then
            friendCount = friendCount + 1
        end
    end
    
    if friendCount >= 3 then
        return true, "Multiple staff friends detected: " .. friendCount
    end
    
    return false, "No staff indicators found"
end

function PlayerAPI:ScanPlayer(player)
    if not state.AntiStaff or player == LocalPlayer then return false, "Disabled" end
    
    local isStaff, reason = IsLikelyStaff(player)
    
    if isStaff then
        detectedStaff[player] = true
        staffWarnings[player] = reason
        
        warn("[ANTI-STAFF] STAFF DETECTED: " .. player.Name)
        warn("[ANTI-STAFF] Reason: " .. reason)
        
        -- Update ESP jika ada
        if espCache[player] then
            espCache[player].label.TextColor3 = Color3.fromRGB(255, 0, 0)
            espCache[player].label.Text = "[STAFF] " .. (player.DisplayName or player.Name)
        end
    end
    
    return isStaff, reason
end

function PlayerAPI:SetAntiStaff(enabled)
    state.AntiStaff = enabled
    
    if enabled then
        -- Scan semua player yang ada
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                self:ScanPlayer(player)
            end
        end
        
        -- Setup player added event
        connections.AntiStaff = Players.PlayerAdded:Connect(function(player)
            task.wait(2)
            self:ScanPlayer(player)
            
            if detectedStaff[player] then
                -- Auto-disable ESP jika staff terdeteksi
                if state.AntiStaff then
                    task.wait(5)
                    if espEnabled then
                        self:SetESP(false)
                        warn("[ANTI-STAFF] Auto-disabled ESP due to staff detection")
                    end
                end
            end
        end)
        
        -- Setup player leaving event
        connections.AntiStaffRemove = Players.PlayerRemoving:Connect(function(player)
            if detectedStaff[player] then
                detectedStaff[player] = nil
                staffWarnings[player] = nil
            end
        end)
        
        warn("[ANTI-STAFF] System enabled")
    else
        -- Cleanup
        if connections.AntiStaff then
            connections.AntiStaff:Disconnect()
            connections.AntiStaff = nil
        end
        if connections.AntiStaffRemove then
            connections.AntiStaffRemove:Disconnect()
            connections.AntiStaffRemove = nil
        end
        
        detectedStaff = {}
        staffWarnings = {}
        
        warn("[ANTI-STAFF] System disabled")
    end
end

function PlayerAPI:HideFromStaff()
    if next(detectedStaff) ~= nil then
        local char = LocalPlayer.Character
        if not char then return end
        
        -- Transparansi sementara
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0.8
                part.CanCollide = false
            end
        end
        
        -- Auto reset setelah 30 detik
        task.delay(30, function()
            if char and char.Parent then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = 0
                        part.CanCollide = true
                    end
                end
            end
        end)
        
        return true
    end
    return false
end

function PlayerAPI:GetDetectedStaff()
    return detectedStaff
end

-- =========================================================
-- INFINITE ZOOM
-- =========================================================
function PlayerAPI:SetInfiniteZoom(enabled)
    state.InfiniteZoom = enabled
    
    if enabled then
        -- Simpan setting original
        originalSettings.CameraMaxZoomDistance = Workspace.CurrentCamera.CameraMaxZoomDistance
        
        -- Setup infinite zoom
        connections.InfiniteZoom = RunService.RenderStepped:Connect(function()
            local camera = Workspace.CurrentCamera
            if camera then
                camera.CameraMaxZoomDistance = math.huge
                camera.CameraMinZoomDistance = 0
            end
        end)
        
        -- Apply immediately
        Workspace.CurrentCamera.CameraMaxZoomDistance = math.huge
        Workspace.CurrentCamera.CameraMinZoomDistance = 0
        
        warn("[INFINITE ZOOM] Enabled")
    else
        -- Restore original settings
        if connections.InfiniteZoom then
            connections.InfiniteZoom:Disconnect()
            connections.InfiniteZoom = nil
        end
        
        if originalSettings.CameraMaxZoomDistance then
            Workspace.CurrentCamera.CameraMaxZoomDistance = originalSettings.CameraMaxZoomDistance
            Workspace.CurrentCamera.CameraMinZoomDistance = 0.5 -- Default value
        end
        
        warn("[INFINITE ZOOM] Disabled")
    end
end

-- =========================================================
-- FPS BOOST / LOW GRAPHICS (POTATO MODE)
-- =========================================================
function PlayerAPI:SetLowGraphics(enabled)
    state.LowGraphics = enabled
    
    if enabled then
        -- Simpan original settings
        originalSettings.GraphicsQualityLevel = settings().Rendering.QualityLevel
        originalSettings.ShadowMap = Lighting.GlobalShadows
        originalSettings.Shadows = Lighting.ShadowSoftness
        originalSettings.TerrainDetail = Workspace.Terrain.Decoration
        originalSettings.TextureQuality = settings().Rendering.MeshPartDetailLevel
        
        -- Apply potato settings
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
        Workspace.Terrain.Decoration = false
        Workspace.Terrain.WaterReflection = false
        Workspace.Terrain.WaterTransparency = 0.9
        
        -- Disable post-processing effects
        if Lighting:FindFirstChildOfClass("BloomEffect") then
            Lighting:FindFirstChildOfClass("BloomEffect").Enabled = false
        end
        if Lighting:FindFirstChildOfClass("BlurEffect") then
            Lighting:FindFirstChildOfClass("BlurEffect").Enabled = false
        end
        if Lighting:FindFirstChildOfClass("ColorCorrectionEffect") then
            Lighting:FindFirstChildOfClass("ColorCorrectionEffect").Enabled = false
        end
        if Lighting:FindFirstChildOfClass("SunRaysEffect") then
            Lighting:FindFirstChildOfClass("SunRaysEffect").Enabled = false
        end
        
        -- Reduce particle count
        for _, emitter in ipairs(Workspace:GetDescendants()) do
            if emitter:IsA("ParticleEmitter") then
                emitter.Rate = math.min(emitter.Rate, 10)
            end
        end
        
        warn("[LOW GRAPHICS] Enabled - Maximum FPS boost")
    else
        -- Restore original settings
        if originalSettings.GraphicsQualityLevel then
            settings().Rendering.QualityLevel = originalSettings.GraphicsQualityLevel
        end
        if originalSettings.ShadowMap then
            Lighting.GlobalShadows = originalSettings.ShadowMap
        end
        if originalSettings.Shadows then
            Lighting.ShadowSoftness = originalSettings.Shadows
        end
        if originalSettings.TerrainDetail then
            Workspace.Terrain.Decoration = originalSettings.TerrainDetail
        end
        if originalSettings.TextureQuality then
            settings().Rendering.MeshPartDetailLevel = originalSettings.TextureQuality
        end
        
        Workspace.Terrain.WaterReflection = true
        Workspace.Terrain.WaterTransparency = 0.3
        
        warn("[LOW GRAPHICS] Disabled")
    end
end

-- =========================================================
-- DISABLE 3D RENDERING (EXTREME FPS BOOST)
-- =========================================================
function PlayerAPI:SetDisable3DRendering(enabled)
    state.Disable3DRendering = enabled
    
    if enabled then
        -- Simpan original settings
        originalSettings.RenderingEnabled = settings().Rendering.Enabled
        originalSettings.RenderCSG = Workspace.RenderCSG
        
        -- Disable 3D rendering
        settings().Rendering.Enabled = false
        Workspace.RenderCSG = false
        
        -- Hide semua BasePart
        local function hideParts(parent)
            for _, obj in ipairs(parent:GetChildren()) do
                if obj:IsA("BasePart") then
                    obj.LocalTransparencyModifier = 1
                end
                hideParts(obj)
            end
        end
        
        connections.Disable3D = Workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("BasePart") then
                obj.LocalTransparencyModifier = 1
            end
        end)
        
        hideParts(Workspace)
        
        warn("[DISABLE 3D RENDERING] Enabled - Extreme FPS mode")
    else
        -- Restore original settings
        if originalSettings.RenderingEnabled ~= nil then
            settings().Rendering.Enabled = originalSettings.RenderingEnabled
        end
        if originalSettings.RenderCSG ~= nil then
            Workspace.RenderCSG = originalSettings.RenderCSG
        end
        
        -- Restore visibility
        if connections.Disable3D then
            connections.Disable3D:Disconnect()
            connections.Disable3D = nil
        end
        
        local function restoreParts(parent)
            for _, obj in ipairs(parent:GetChildren()) do
                if obj:IsA("BasePart") then
                    obj.LocalTransparencyModifier = 0
                end
                restoreParts(obj)
            end
        end
        
        restoreParts(Workspace)
        
        warn("[DISABLE 3D RENDERING] Disabled")
    end
end

-- =========================================================
-- COMBINED FPS BOOST FUNCTION
-- =========================================================
function PlayerAPI:SetMaxFPSBoost(enabled)
    if enabled then
        self:SetLowGraphics(true)
        self:SetDisable3DRendering(true)
        warn("[MAX FPS BOOST] All optimizations enabled")
    else
        self:SetLowGraphics(false)
        self:SetDisable3DRendering(false)
        warn("[MAX FPS BOOST] All optimizations disabled")
    end
end

-- =========================================================
-- MOVEMENT FUNCTIONS (ORIGINAL - TIDAK DIUBAH)
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
-- PLAYER ESP (ORIGINAL - TIDAK DIUBAH)
-- =========================
local espEnabled = false
local espCache = {}

-- Fungsi untuk menghitung jarak
local function CalculateDistance(position)
    local localChar = LocalPlayer.Character
    local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
    
    if not localHrp then return "N/A" end
    
    local distance = (localHrp.Position - position).Magnitude
    return math.floor(distance)
end

-- Fungsi update ESP dengan jarak
function PlayerAPI:_UpdateESP(plr)
    if not espEnabled then
        if espCache[plr] then
            espCache[plr].gui:Destroy()
            espCache[plr] = nil
        end
        return
    end

    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        if espCache[plr] then
            espCache[plr].gui:Destroy()
            espCache[plr] = nil
        end
        return 
    end

    -- Jika ESP sudah ada, update jarak saja
    if espCache[plr] then
        local distance = CalculateDistance(hrp.Position)
        espCache[plr].label.Text = string.format("%s [%dm]", 
            plr.DisplayName or plr.Name, 
            distance
        )
        return
    end

    -- Buat ESP baru
    local gui = Instance.new("BillboardGui")
    gui.Name = "NYXHUB_ESP"
    gui.Adornee = hrp
    gui.Size = UDim2.new(0, 200, 0, 50) -- Ukuran diperbesar untuk menampilkan jarak
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 500 -- Hanya tampilkan dalam jarak 500 studs
    gui.Parent = hrp

    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(255, 230, 230)
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    -- Warna berdasarkan jarak (opsional)
    local distance = CalculateDistance(hrp.Position)
    if distance <= 50 then
        label.TextColor3 = Color3.fromRGB(255, 50, 50)
    elseif distance <= 100 then
        label.TextColor3 = Color3.fromRGB(255, 150, 50)
    else
        label.TextColor3 = Color3.fromRGB(50, 200, 255)
    end

    label.Text = string.format("%s [%dm]", 
        plr.DisplayName or plr.Name, 
        distance
    )

    -- Simpan data ESP dengan reference ke karakter
    espCache[plr] = {
        gui = gui,
        label = label,
        connection = nil
    }

    -- Update jarak secara real-time
    espCache[plr].connection = RunService.Heartbeat:Connect(function()
        if not espEnabled or not espCache[plr] then
            espCache[plr].connection:Disconnect()
            return
        end

        if not plr or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            espCache[plr].gui:Destroy()
            espCache[plr].connection:Disconnect()
            espCache[plr] = nil
            return
        end

        local hrp = plr.Character.HumanoidRootPart
        local distance = CalculateDistance(hrp.Position)
        
        -- Update warna berdasarkan jarak
        if distance <= 50 then
            espCache[plr].label.TextColor3 = Color3.fromRGB(255, 50, 50)
        elseif distance <= 100 then
            espCache[plr].label.TextColor3 = Color3.fromRGB(255, 150, 50)
        else
            espCache[plr].label.TextColor3 = Color3.fromRGB(50, 200, 255)
        end

        espCache[plr].label.Text = string.format("%s [%dm]", 
            plr.DisplayName or plr.Name, 
            distance
        )
    end)
end

-- Fungsi toggle ESP
function PlayerAPI:SetESP(enabled)
    espEnabled = enabled

    if not enabled then
        -- Matikan semua ESP
        for _, data in pairs(espCache) do
            if data.connection then
                data.connection:Disconnect()
            end
            data.gui:Destroy()
        end
        espCache = {}
        return
    end

    -- Aktifkan ESP untuk semua pemain
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            PlayerAPI:_UpdateESP(plr)
        end
    end
end

-- Event handler untuk pemain baru
Players.PlayerAdded:Connect(function(plr)
    if plr == LocalPlayer then return end
    
    plr.CharacterAdded:Connect(function()
        wait(0.5)
        PlayerAPI:_UpdateESP(plr)
    end)
end)

-- Event handler untuk pemain yang keluar
Players.PlayerRemoving:Connect(function(plr)
    if espCache[plr] then
        if espCache[plr].connection then
            espCache[plr].connection:Disconnect()
        end
        espCache[plr].gui:Destroy()
        espCache[plr] = nil
    end
end)

-- Update ESP saat karakter local berganti
LocalPlayer.CharacterAdded:Connect(function()
    wait(0.5)
    if espEnabled then
        for plr, _ in pairs(espCache) do
            PlayerAPI:_UpdateESP(plr)
        end
    end
end)

-- =========================
-- RESET CHARACTER (ORIGINAL - TIDAK DIUBAH)
-- =========================
function PlayerAPI:ResetCharacterInPlace()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not hrp or not hum then 
        warn("Karakter atau Humanoid tidak ditemukan")
        return 
    end

    local camera = workspace.CurrentCamera
    local lastPos = hrp.Position
    local lastCFrame = hrp.CFrame
    
    local cameraLookVector
    if camera then
        cameraLookVector = camera.CFrame.LookVector
    else
        cameraLookVector = lastCFrame.LookVector
    end

    hum.Health = 0
    LocalPlayer.CharacterAdded:Wait()
    task.wait(0.5)

    local newChar = LocalPlayer.Character
    local newHRP = newChar:WaitForChild("HumanoidRootPart", 5)
    local newHum = newChar:WaitForChild("Humanoid", 5)
    
    if newHRP and newHum then
        newHum.Health = newHum.MaxHealth
        local targetPosition = lastPos + Vector3.new(0, 3, 0)
        local targetCFrame = CFrame.new(targetPosition, targetPosition + cameraLookVector)
        newHRP.CFrame = targetCFrame
        task.wait(0.1)
        newHRP.Velocity = Vector3.new(0, 0, 0)
        newHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        newHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end

-- =========================================================
-- CLEANUP (ANTI LEAK)
-- =========================================================
function PlayerAPI:Shutdown()
    -- Disable semua fitur
    self:SetAntiStaff(false)
    self:SetInfiniteZoom(false)
    self:SetLowGraphics(false)
    self:SetDisable3DRendering(false)
    self:SetESP(false)
    self:SetNoClip(false)
    self:SetFly(false)
    self:SetInfiniteJump(false)
    self:SetWalkOnWater(false)
    self:SetFreeze(false)
    
    -- Disconnect semua connections
    for name, conn in pairs(connections) do
        pcall(function()
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            elseif typeof(conn) == "Instance" then
                conn:Destroy()
            end
        end)
    end
    
    -- Cleanup water platform
    if waterPlatform then
        waterPlatform:Destroy()
        waterPlatform = nil
    end
    
    connections = {}
    originalSettings = {}
    detectedStaff = {}
    staffWarnings = {}
    espCache = {}
    
    warn("[PLAYER API] Shutdown complete")
end

-- =========================================================
-- STATUS GETTERS
-- =========================================================
function PlayerAPI:GetStatus()
    return {
        WalkSpeed = state.WalkSpeed,
        JumpPower = state.JumpPower,
        Frozen = state.Frozen,
        InfiniteJump = state.InfiniteJump,
        NoClip = state.NoClip,
        Fly = state.Fly,
        WalkOnWater = state.WalkOnWater,
        AntiStaff = state.AntiStaff,
        InfiniteZoom = state.InfiniteZoom,
        LowGraphics = state.LowGraphics,
        Disable3DRendering = state.Disable3DRendering,
        ESPEnabled = espEnabled
    }
end

return PlayerAPI
