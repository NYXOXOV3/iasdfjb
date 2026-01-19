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
        label.TextColor3 = Color3.fromRGB(255, 50, 50) -- Merah untuk jarak dekat
    elseif distance <= 100 then
        label.TextColor3 = Color3.fromRGB(255, 150, 50) -- Oranye untuk jarak sedang
    else
        label.TextColor3 = Color3.fromRGB(50, 200, 255) -- Biru untuk jarak jauh
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
        wait(0.5) -- Tunggu sedikit untuk memastikan karakter lengkap
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
-- RESET CHARACTER
-- =========================
function PlayerAPI:ResetCharacterInPlace()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not hrp or not hum then 
        warn("Karakter atau Humanoid tidak ditemukan")
        return 
    end

    -- Simpan posisi dan orientasi kamera saat ini
    local camera = workspace.CurrentCamera
    local lastPos = hrp.Position
    local lastCFrame = hrp.CFrame
    
    -- Dapatkan look vector dari kamera (arah pandang player)
    local cameraLookVector
    if camera then
        cameraLookVector = camera.CFrame.LookVector
    else
        -- Fallback: gunakan look vector dari HRP jika kamera tidak tersedia
        cameraLookVector = lastCFrame.LookVector
    end

    -- Reset karakter
    hum.Health = 0

    -- Tunggu karakter baru muncul
    LocalPlayer.CharacterAdded:Wait()
    
    -- Tunggu sedikit untuk memastikan karakter terload dengan benar
    task.wait(0.5)

    -- Dapatkan HRP baru
    local newChar = LocalPlayer.Character
    local newHRP = newChar:WaitForChild("HumanoidRootPart", 5)
    local newHum = newChar:WaitForChild("Humanoid", 5)
    
    if newHRP and newHum then
        -- Pastikan humanoid tidak mati
        newHum.Health = newHum.MaxHealth
        
        -- Buat CFrame baru dengan posisi dan orientasi yang dipertahankan
        -- Atur posisi sedikit lebih tinggi untuk menghindari terjebak di tanah
        local targetPosition = lastPos + Vector3.new(0, 3, 0)
        
        -- Buat CFrame yang menghadap ke arah yang sama dengan sebelumnya
        -- Gunakan LookVector dari kamera sebagai forward vector
        local targetCFrame = CFrame.new(targetPosition, targetPosition + cameraLookVector)
        
        -- Terapkan CFrame ke HRP baru
        newHRP.CFrame = targetCFrame
        
        -- Tunggu frame berikutnya untuk memastikan posisi diterapkan
        task.wait(0.1)
        
        -- Reset velocity untuk mencegah glitch
        newHRP.Velocity = Vector3.new(0, 0, 0)
        newHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        newHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        -- Optional: Beri feedback visual/suara
        warn(string.format("Karakter di-reset di posisi: %s dengan orientasi: %s", 
            tostring(targetPosition), 
            tostring(cameraLookVector)))
    else
        warn("Gagal mendapatkan HRP atau Humanoid baru")
    end
end

-- Versi alternatif dengan opsi untuk mempertahankan orientasi karakter (bukan kamera)
function PlayerAPI:ResetCharacterInPlaceWithCharOrientation()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not hrp or not hum then 
        warn("Karakter atau Humanoid tidak ditemukan")
        return 
    end

    -- Simpan posisi dan orientasi karakter
    local lastPos = hrp.Position
    local lastCFrame = hrp.CFrame
    
    -- Ekstrak rotasi dari CFrame (menghadap karakter)
    local _, rotY, _ = lastCFrame:ToEulerAnglesYXZ()
    
    -- Reset karakter
    hum.Health = 0

    -- Tunggu karakter baru
    LocalPlayer.CharacterAdded:Wait()
    task.wait(0.5)

    local newChar = LocalPlayer.Character
    local newHRP = newChar:WaitForChild("HumanoidRootPart", 5)
    local newHum = newChar:WaitForChild("Humanoid", 5)
    
    if newHRP and newHum then
        newHum.Health = newHum.MaxHealth
        
        -- Buat posisi baru
        local targetPosition = lastPos + Vector3.new(0, 3, 0)
        
        -- Buat CFrame dengan orientasi yang sama seperti sebelumnya
        -- Menggunakan rotasi Y (yaw) untuk menghadap ke arah yang sama
        local targetCFrame = CFrame.new(targetPosition) * CFrame.Angles(0, rotY, 0)
        
        newHRP.CFrame = targetCFrame
        
        task.wait(0.1)
        newHRP.Velocity = Vector3.new(0, 0, 0)
        newHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        newHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        warn("Karakter di-reset dengan orientasi karakter sebelumnya")
    end
end

-- Versi dengan input parameter untuk custom orientation
function PlayerAPI:ResetCharacterCustom(customLookVector)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not hrp or not hum then return end

    local lastPos = hrp.Position
    local targetLookVector = customLookVector or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.LookVector) or hrp.CFrame.LookVector
    
    hum.Health = 0
    LocalPlayer.CharacterAdded:Wait()
    task.wait(0.5)

    local newHRP = LocalPlayer.Character:WaitForChild("HumanoidRootPart", 5)
    if newHRP then
        local targetPosition = lastPos + Vector3.new(0, 3, 0)
        local targetCFrame = CFrame.new(targetPosition, targetPosition + targetLookVector)
        newHRP.CFrame = targetCFrame
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
