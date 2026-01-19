-- =========================================================
-- FISHING API (UNIFIED VERSION) - FIXED
-- =========================================================

local FishingAPI = {}

-- ================= SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RepStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- ================= STATE =================
local legitAutoState = false
local normalInstantState = false
local blatantInstantState = false

-- Threads
local normalLoopThread = nil
local blatantLoopThread = nil
local normalEquipThread = nil
local blatantEquipThread = nil
local legitEquipThread = nil
local legitClickThread = nil

-- Configuration
local SPEED_LEGIT = 0.05
local normalCompleteDelay = 1.5

-- Area Management
local isTeleportFreezeActive = false
local selectedArea = nil
local savedPosition = nil

-- Fishing Controllers
local FishingController = nil
local AutoFishingController = nil
local AutoFishState = { IsActive = false, MinigameActive = false }

-- Blatant Config
local Config = {
    Active = false,
    Mode = "Old",
    CancelDelay = 1.75,
    CompleteDelay = 1.33,
    AutoPerfect = false
}

-- Original functions backup
local originalRodStarted = nil
local originalFishingStopped = nil
local originalClick = nil
local originalCharge = nil

-- ================= HELPERS =================
local function GetHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 5)
end

local function TeleportToLookAt(position, lookVector)
    local hrp = GetHRP()
    if not hrp then return false end
    hrp.CFrame = CFrame.new(position, position + lookVector) * CFrame.new(0, 0.5, 0)
    return true
end

-- ================= REMOTES =================
local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
local function GetRemote(path, name)
    local obj = RepStorage
    for _, p in ipairs(path) do obj = obj:WaitForChild(p) end
    return obj:WaitForChild(name)
end

local RE_Equip = GetRemote(RPath, "RE/EquipToolFromHotbar")
local RF_Charge = GetRemote(RPath, "RF/ChargeFishingRod")
local RF_Start = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
local RE_Complete = GetRemote(RPath, "RE/FishingCompleted")
local RF_Cancel = GetRemote(RPath, "RF/CancelFishingInputs")
local RF_Update = GetRemote(RPath, "RF/UpdateAutoFishingState")

-- ================= INITIALIZE CONTROLLERS =================
function FishingAPI:Initialize()
    task.wait(0.2)
    FishingController = require(RepStorage:WaitForChild("Controllers").FishingController)
    AutoFishingController = require(RepStorage:WaitForChild("Controllers").AutoFishingController)
    
    -- Backup original functions
    originalRodStarted = FishingController.FishingRodStarted
    originalFishingStopped = FishingController.FishingStopped
    originalClick = FishingController.RequestFishingMinigameClick
    originalCharge = FishingController.RequestChargeFishingRod
    
    -- Hook functions
    FishingController.FishingRodStarted = function(self, arg1, arg2)
        originalRodStarted(self, arg1, arg2)
        
        if AutoFishState.IsActive and not AutoFishState.MinigameActive then
            AutoFishState.MinigameActive = true
            
            if legitClickThread then
                task.cancel(legitClickThread)
            end
            
            legitClickThread = task.spawn(function()
                while AutoFishState.IsActive and AutoFishState.MinigameActive do
                    FishingController:RequestFishingMinigameClick()
                    task.wait(SPEED_LEGIT)
                end
            end)
        end
    end
    
    FishingController.FishingStopped = function(self, arg1)
        originalFishingStopped(self, arg1)
        
        if AutoFishState.MinigameActive then
            AutoFishState.MinigameActive = false
        end
    end
end

-- ================= LEGIT MODE =================
function FishingAPI:SetLegitSpeed(v)
    v = tonumber(v)
    if v and v >= 0.01 then 
        SPEED_LEGIT = v 
    end
end

local function ensureServerAutoFishingOn()
    pcall(function()
        RF_Update:InvokeServer(true)
    end)
end

local function ToggleAutoClick(shouldActivate)
    if not FishingController then
        warn("FishingController not initialized!")
        return
    end
    
    AutoFishState.IsActive = shouldActivate
    
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local fishingGui = playerGui:FindFirstChild("Fishing") and playerGui.Fishing:FindFirstChild("Main")
    local chargeGui = playerGui:FindFirstChild("Charge") and playerGui.Charge:FindFirstChild("Main")
    
    if shouldActivate then
        -- 1. Equip Rod Awal
        pcall(function() RE_Equip:FireServer(1) end)
        
        -- 2. Force Server AutoFishing State
        ensureServerAutoFishingOn()
        
        -- 3. Sembunyikan UI Minigame
        if fishingGui then fishingGui.Visible = false end
        if chargeGui then chargeGui.Visible = false end
        
        -- Start equip thread
        legitEquipThread = task.spawn(function()
            while legitAutoState do
                pcall(function() RE_Equip:FireServer(1) end)
                task.wait(0.1)
            end
        end)
    else
        if legitClickThread then
            task.cancel(legitClickThread)
            legitClickThread = nil
        end
        if legitEquipThread then
            task.cancel(legitEquipThread)
            legitEquipThread = nil
        end
        AutoFishState.MinigameActive = false
        
        -- Tampilkan kembali UI Minigame
        if fishingGui then fishingGui.Visible = true end
        if chargeGui then chargeGui.Visible = true end
    end
end

function FishingAPI:SetLegit(state)
    legitAutoState = state
    
    if state then
        ToggleAutoClick(state)
    else
        ToggleAutoClick(false)
        pcall(function() RF_Update:InvokeServer(false) end)
    end
end

-- ================= NORMAL MODE =================
function FishingAPI:SetNormalDelay(v)
    v = tonumber(v)
    if v then 
        normalCompleteDelay = v 
    end
end

local function runNormalInstant()
    if not normalInstantState then return end
    
    local timestamp = os.time() + os.clock()
    pcall(function() RF_Charge:InvokeServer(timestamp) end)
    pcall(function() RF_Start:InvokeServer(-139.630452165, 0.99647927980797) end)
    
    task.wait(normalCompleteDelay)
    
    pcall(function() RE_Complete:FireServer() end)
    task.wait(0.3)
    pcall(function() RF_Cancel:InvokeServer() end)
end

function FishingAPI:SetNormal(state)
    normalInstantState = state
    
    if state then
        -- Main fishing thread
        normalLoopThread = task.spawn(function()
            while normalInstantState do
                runNormalInstant()
                task.wait(0.1)
            end
        end)
        
        -- Auto equip thread
        normalEquipThread = task.spawn(function()
            while normalInstantState do
                pcall(function() RE_Equip:FireServer(1) end)
                task.wait(0.1)
            end
        end)
    else
        -- Stop threads
        if normalLoopThread then 
            task.cancel(normalLoopThread) 
            normalLoopThread = nil 
        end
        if normalEquipThread then 
            task.cancel(normalEquipThread) 
            normalEquipThread = nil 
        end
        
        pcall(function() RE_Equip:FireServer(0) end)
    end
end

-- ================= BLATANT MODE =================
local function SyncAutoPerfect()
    local shouldEnable = Config.Active and Config.Mode == "New"
    
    if shouldEnable and not Config.AutoPerfect then
        Config.AutoPerfect = true
        FishingController.RequestFishingMinigameClick = function() end
        FishingController.RequestChargeFishingRod = function() end
    elseif not shouldEnable and Config.AutoPerfect then
        Config.AutoPerfect = false
        FishingController.RequestFishingMinigameClick = originalClick
        FishingController.RequestChargeFishingRod = originalCharge
        
        pcall(function()
            RF_Update:InvokeServer(false)
        end)
    end
end

local function DoFish()
    task.spawn(function()
        pcall(function()
            RF_Cancel:InvokeServer()
            RF_Charge:InvokeServer(math.huge)
            RF_Start:InvokeServer(-139.6379699707, 0.99647927980797)
        end)
    end)
    
    task.spawn(function()
        task.wait(Config.CompleteDelay)
        if Config.Active then
            pcall(function() RE_Complete:FireServer() end)
        end
    end)
end

local function FishingLoop()
    -- Equip thread
    blatantEquipThread = task.spawn(function()
        while Config.Active do
            pcall(function() RE_Equip:FireServer(1) end)
            task.wait(0.1)
        end
    end)
    
    -- Main fishing loop
    while Config.Active do
        DoFish()
        task.wait(Config.CancelDelay)
    end
end

-- Auto Perfect heartbeat
task.spawn(function()
    while task.wait(0.6) do
        if Config.AutoPerfect then
            pcall(function()
                RF_Update:InvokeServer(true)
            end)
        end
    end
end)

function FishingAPI:SetActive(state)
    Config.Active = state
    SyncAutoPerfect()
    
    if state then
        if blatantLoopThread then task.cancel(blatantLoopThread) end
        blatantLoopThread = task.spawn(FishingLoop)
    else
        if blatantLoopThread then task.cancel(blatantLoopThread) end
        if blatantEquipThread then task.cancel(blatantEquipThread) end
        blatantLoopThread, blatantEquipThread = nil, nil
        
        pcall(function() RF_Cancel:InvokeServer() end)
    end
end

function FishingAPI:SetMode(mode)
    Config.Mode = mode
    SyncAutoPerfect()
end

function FishingAPI:SetCancelDelay(v)
    v = tonumber(v)
    if v and v > 0 then 
        Config.CancelDelay = v 
    end
end

function FishingAPI:SetCompleteDelay(v)
    v = tonumber(v)
    if v and v > 0 then 
        Config.CompleteDelay = v 
    end
end

-- ================= AREA MANAGEMENT =================
function FishingAPI:SetSelectedArea(v)
    selectedArea = v
end

function FishingAPI:SaveCurrentPosition()
    local hrp = GetHRP()
    if hrp then
        savedPosition = {
            Pos = hrp.Position,
            Look = hrp.CFrame.LookVector
        }
        return savedPosition
    end
    return nil
end

function FishingAPI:SetTeleportFreeze(state, FishingAreas)
    isTeleportFreezeActive = state
    local hrp = GetHRP()
    if not hrp then return false end
    
    if not state then
        hrp.Anchored = false
        return true
    end
    
    local area = (selectedArea == "Custom: Saved" and savedPosition) or FishingAreas[selectedArea]
    if not area then return false end
    
    -- Unanchor dulu
    hrp.Anchored = false
    
    -- Teleport ke posisi target
    TeleportToLookAt(area.Pos, area.Look)
    
    -- Tunggu server sync (1.5 detik)
    local startTime = os.clock()
    while (os.clock() - startTime) < 1.5 and isTeleportFreezeActive do
        if hrp then
            hrp.Velocity = Vector3.new(0,0,0)
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
            hrp.CFrame = CFrame.new(area.Pos, area.Pos + area.Look) * CFrame.new(0, 0.5, 0)
        end
        RunService.Heartbeat:Wait()
    end
    
    -- Freeze total setelah server sync
    if isTeleportFreezeActive and hrp then
        hrp.Anchored = true
    end
    
    return true
end

function FishingAPI:TeleportToArea(FishingAreas)
    local area = (selectedArea == "Custom: Saved" and savedPosition) or FishingAreas[selectedArea]
    if not area then return false end
    
    -- Jika sedang freeze, matikan dulu
    if isTeleportFreezeActive then
        local hrp = GetHRP()
        if hrp then hrp.Anchored = false end
        isTeleportFreezeActive = false
    end
    
    return TeleportToLookAt(area.Pos, area.Look)
end

-- ================= BLATANT V2 SIMPLIFIED =================
local BlatantV2 = {
    Active = false,
    Mode = "Extreme",
    CompleteDelay = 0.08,
    CancelDelay = 0.05,
    EquipDelay = 0.02,
    BatchSize = 3
}

local V2MainThread = nil
local V2EquipThread = nil

local function ExtremeFishingLoop()
    -- Equip spam thread
    V2EquipThread = task.spawn(function()
        while BlatantV2.Active do
            pcall(function() RE_Equip:FireServer(1) end)
            task.wait(BlatantV2.EquipDelay)
        end
    end)
    
    -- Main fishing loop
    while BlatantV2.Active do
        -- Cancel existing state
        pcall(function() RF_Cancel:InvokeServer() end)
        
        -- Charge with extreme value
        pcall(function() RF_Charge:InvokeServer(math.huge) end)
        
        -- Start fishing
        pcall(function() 
            RF_Start:InvokeServer(-139.6379699707, 0.99647927980797) 
        end)
        
        -- Instant complete
        task.wait(BlatantV2.CompleteDelay)
        
        if BlatantV2.Active then
            pcall(function() RE_Complete:FireServer() end)
        end
        
        -- Wait for next cycle
        task.wait(BlatantV2.CancelDelay)
    end
end

function FishingAPI:SetBlatantV2(state)
    if state == BlatantV2.Active then return end
    
    BlatantV2.Active = state
    
    if state then
        -- Disable other modes
        FishingAPI:SetLegit(false)
        FishingAPI:SetNormal(false)
        FishingAPI:SetActive(false)
        
        -- Start V2 mode
        V2MainThread = task.spawn(ExtremeFishingLoop)
    else
        -- Stop all threads
        if V2MainThread then task.cancel(V2MainThread) end
        if V2EquipThread then task.cancel(V2EquipThread) end
        
        V2MainThread = nil
        V2EquipThread = nil
        
        -- Send cleanup
        pcall(function() RF_Cancel:InvokeServer() end)
    end
end

function FishingAPI:SetBlatantV2Mode(mode)
    if mode == "Extreme" or mode == "Ultra" or mode == "GodMode" then
        BlatantV2.Mode = mode
        
        -- Adjust settings
        if mode == "Ultra" then
            BlatantV2.CompleteDelay = 0.05
            BlatantV2.CancelDelay = 0.03
        elseif mode == "GodMode" then
            BlatantV2.CompleteDelay = 0.03
            BlatantV2.CancelDelay = 0.01
        end
    end
end

function FishingAPI:SetBlatantV2Setting(setting, value)
    local num = tonumber(value)
    if not num then return end
    
    if setting == "CompleteDelay" then
        BlatantV2.CompleteDelay = math.max(0.01, num)
    elseif setting == "CancelDelay" then
        BlatantV2.CancelDelay = math.max(0.01, num)
    elseif setting == "EquipDelay" then
        BlatantV2.EquipDelay = math.max(0.01, num)
    elseif setting == "BatchSize" then
        BlatantV2.BatchSize = math.clamp(num, 1, 10)
    end
end

function FishingAPI:GetBlatantV2Stats()
    local cycleTime = BlatantV2.CompleteDelay + BlatantV2.CancelDelay
    local speedPerSec = 0
    if cycleTime > 0 then
        speedPerSec = 1 / cycleTime
    end
    
    return {
        Active = BlatantV2.Active,
        Mode = BlatantV2.Mode,
        Speed = string.format("%.1f fish/sec", speedPerSec),
        CycleTime = string.format("%.0fms", cycleTime * 1000)
    }
end

-- ================= CLEANUP =================
function FishingAPI:Cleanup()
    -- Stop all modes
    FishingAPI:SetLegit(false)
    FishingAPI:SetNormal(false)
    FishingAPI:SetActive(false)
    FishingAPI:SetBlatantV2(false)
    
    -- Restore original functions
    if FishingController then
        if originalRodStarted then
            FishingController.FishingRodStarted = originalRodStarted
        end
        if originalFishingStopped then
            FishingController.FishingStopped = originalFishingStopped
        end
        if originalClick then
            FishingController.RequestFishingMinigameClick = originalClick
        end
        if originalCharge then
            FishingController.RequestChargeFishingRod = originalCharge
        end
    end
    
    -- Unfreeze character
    local hrp = GetHRP()
    if hrp then hrp.Anchored = false end
end

-- Initialize controllers
task.spawn(function()
    FishingAPI:Initialize()
end)

return FishingAPI
