-- =========================================================
-- PLAYER API - NYXHUB (FULL FINAL)
-- =========================================================

local PlayerAPI = {}

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local STUD_TO_M = 0.28

-- =========================================================
-- INTERNAL STATE
-- =========================================================
local state = {
    WalkSpeed = 16,
    JumpPower = 50,
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
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHum()
    return getChar():FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    return getChar():WaitForChild("HumanoidRootPart")
end

-- =========================================================
-- MOVEMENT
-- =========================================================
function PlayerAPI:SetWalkSpeed(v)
    local h = getHum()
    if h then h.WalkSpeed = v end
    state.WalkSpeed = v
end

function PlayerAPI:SetJumpPower(v)
    local h = getHum()
    if h then h.JumpPower = v end
    state.JumpPower = v
end

function PlayerAPI:ResetMovement()
    self:SetWalkSpeed(16)
    self:SetJumpPower(50)
end

-- =========================================================
-- FREEZE
-- =========================================================
function PlayerAPI:SetFreeze(v)
    local hrp = getHRP()
    hrp.Anchored = v
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.Velocity = Vector3.zero
    state.Frozen = v
end

-- =========================================================
-- INFINITE JUMP
-- =========================================================
function PlayerAPI:SetInfiniteJump(v)
    state.InfiniteJump = v
    if v then
        connections.InfJump = UserInputService.JumpRequest:Connect(function()
            local h = getHum()
            if h and h.Health > 0 then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    elseif connections.InfJump then
        connections.InfJump:Disconnect()
        connections.InfJump = nil
    end
end

-- =========================================================
-- NO CLIP
-- =========================================================
function PlayerAPI:SetNoClip(v)
    state.NoClip = v
    if v then
        connections.NoClip = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
            if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    elseif connections.NoClip then
        connections.NoClip:Disconnect()
        connections.NoClip = nil
    end
end

-- =========================================================
-- FLY
-- =========================================================
function PlayerAPI:SetFly(v, speed)
    speed = speed or 60
    state.Fly = v

    local hrp, hum = getHRP(), getHum()
    if not hrp or not hum then return end

    if v then
        local bg = Instance.new("BodyGyro", hrp)
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9,9e9,9e9)

        local bv = Instance.new("BodyVelocity", hrp)
        bv.MaxForce = Vector3.new(9e9,9e9,9e9)

        connections.Fly = RunService.RenderStepped:Connect(function()
            bg.CFrame = workspace.CurrentCamera.CFrame
            local move = hum.MoveDirection
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                move += Vector3.new(0,1,0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                move -= Vector3.new(0,1,0)
            end
            bv.Velocity = move.Magnitude > 0 and move.Unit * speed or Vector3.zero
        end)

        connections.FlyBG = bg
        connections.FlyBV = bv
    else
        for _, k in ipairs({"Fly","FlyBG","FlyBV"}) do
            if connections[k] then
                if typeof(connections[k])=="RBXScriptConnection" then
                    connections[k]:Disconnect()
                else
                    connections[k]:Destroy()
                end
                connections[k]=nil
            end
        end
    end
end

-- =========================================================
-- WALK ON WATER
-- =========================================================
local waterConn, waterPart

function PlayerAPI:SetWalkOnWater(v)
    state.WalkOnWater = v

    if v then
        waterPart = Instance.new("Part")
        waterPart.Anchored = true
        waterPart.CanCollide = true
        waterPart.Transparency = 1
        waterPart.Size = Vector3.new(18,1,18)
        waterPart.Parent = workspace

        waterConn = RunService.RenderStepped:Connect(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {workspace.Terrain}
            params.FilterType = Enum.RaycastFilterType.Include
            params.IgnoreWater = false

            local res = workspace:Raycast(hrp.Position+Vector3.new(0,5,0),Vector3.new(0,-500,0),params)
            if res and res.Material == Enum.Material.Water then
                waterPart.Position = Vector3.new(hrp.Position.X,res.Position.Y,hrp.Position.Z)
                if hrp.Position.Y < res.Position.Y+2 then
                    hrp.CFrame = CFrame.new(hrp.Position.X,res.Position.Y+3.2,hrp.Position.Z)
                end
            else
                waterPart.Position = Vector3.new(0,-500,0)
            end
        end)
    else
        if waterConn then waterConn:Disconnect() waterConn=nil end
        if waterPart then waterPart:Destroy() waterPart=nil end
    end
end

-- =========================================================
-- STREAMER MODE (SELF / SELECTED / ALL)
-- =========================================================
local hideState = {
    Enabled=false,
    Mode="SELF",
    Targets={},
    Name=".gg/NYXHUB",
    Level="Lvl. 969"
}

local hideConn

local function isTarget(plr)
    if hideState.Mode=="ALL" then return true end
    if hideState.Mode=="SELF" then return plr==LocalPlayer end
    if hideState.Mode=="SELECTED" then return hideState.Targets[plr] end
end

function PlayerAPI:SetFakeName(v) hideState.Name=v end
function PlayerAPI:SetFakeLevel(v) hideState.Level=v end
function PlayerAPI:SetHideMode(v) hideState.Mode=v end
function PlayerAPI:AddHideTarget(p) hideState.Targets[p]=true end
function PlayerAPI:RemoveHideTarget(p) hideState.Targets[p]=nil end
function PlayerAPI:ClearHideTargets() hideState.Targets={} end

function PlayerAPI:SetHideUsernames(v)
    hideState.Enabled=v
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,not v)
    end)

    if v then
        hideConn = RunService.RenderStepped:Connect(function()
            for _,plr in ipairs(Players:GetPlayers()) do
                if not isTarget(plr) then continue end
                local c=plr.Character
                local h=c and c:FindFirstChildOfClass("Humanoid")
                if h then h.DisplayName=hideState.Name end
            end
        end)
    else
        if hideConn then hideConn:Disconnect() hideConn=nil end
        for _,plr in ipairs(Players:GetPlayers()) do
            local h=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            if h then h.DisplayName=plr.DisplayName end
        end
    end
end

-- =========================================================
-- PLAYER ESP (DISTANCE)
-- =========================================================
local espEnabled=false
local espCache={}
local espConn

local function clearESP(p)
    if espCache[p] then espCache[p]:Destroy() espCache[p]=nil end
end

local function createESP(p)
    if p==LocalPlayer or espCache[p] then return end
    local hrp=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local gui=Instance.new("BillboardGui",hrp)
    gui.Size=UDim2.new(0,140,0,40)
    gui.StudsOffset=Vector3.new(0,2.6,0)
    gui.AlwaysOnTop=true

    local name=Instance.new("TextLabel",gui)
    name.Size=UDim2.new(1,0,0.6,0)
    name.BackgroundTransparency=1
    name.TextScaled=true
    name.Text= p.DisplayName or p.Name

    local dist=Instance.new("TextLabel",gui)
    dist.Position=UDim2.new(0,0,0.6,0)
    dist.Size=UDim2.new(1,0,0.4,0)
    dist.BackgroundTransparency=1
    dist.TextScaled=true

    espCache[p]={gui=gui,hrp=hrp,dist=dist}
end

function PlayerAPI:SetESP(v)
    espEnabled=v
    for p in pairs(espCache) do clearESP(p) end
    if not v then if espConn then espConn:Disconnect() end return end

    for _,p in ipairs(Players:GetPlayers()) do createESP(p) end
    espConn=RunService.RenderStepped:Connect(function()
        local lhrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not lhrp then return end
        for p,d in pairs(espCache) do
            if d.hrp and d.hrp.Parent then
                d.dist.Text=string.format("%.1f m",(lhrp.Position-d.hrp.Position).Magnitude*STUD_TO_M)
            else clearESP(p) end
        end
    end)
end

-- =========================================================
-- RESET
-- =========================================================
function PlayerAPI:ResetCharacterInPlace()
    local pos=getHRP().Position
    getHum().Health=0
    LocalPlayer.CharacterAdded:Wait()
    task.wait(0.5)
    getHRP().CFrame=CFrame.new(pos+Vector3.new(0,3,0))
end

function PlayerAPI:ResetAll()
    self:SetFreeze(false)
    self:SetInfiniteJump(false)
    self:SetNoClip(false)
    self:SetFly(false)
    self:SetWalkOnWater(false)
    self:SetESP(false)
    self:SetHideUsernames(false)
    self:ResetMovement()
end

return PlayerAPI
