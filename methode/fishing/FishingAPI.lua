-- =========================================================
-- FISHING API (UNIFIED VERSION) - WITH CLEAN BLATANT V2-V5
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

-- ================= BLATANT V2 CLEAN =================
local BlatantV2 = {
    Active = false,
    Settings = {
        ChargeDelay = 0.007,
        CompleteDelay = 0.001,
        CancelDelay = 0.001,
        EquipDelay = 0.02
    },
    Thread = nil
}

-- ================= BLATANT V3 =================
local BlatantV3 = {
    Active = false,
    Settings = {
        CompleteDelay = 0.73,
        CancelDelay = 0.3,
        ReCastDelay = 0.001
    },
    Thread = nil,
    FishingState = {
        lastCompleteTime = 0,
        completeCooldown = 0.4
    },
    lastEventTime = 0
}

-- ================= BLATANT V4 =================
local BlatantV4 = {
    Running = false,
    WaitingHook = false,
    CurrentCycle = 0,
    TotalFish = 0,
    Settings = {
        FishingDelay = 0.05,
        CancelDelay = 0.01,
        HookWaitTime = 0.01,
        CastDelay = 0.25,
        TimeoutDelay = 0.8,
    }
}

-- ================= BLATANT V5 =================
local BlatantV5 = {
    Active = false,
    Settings = {
        ChargeDelay = 0.007,
        CompleteDelay = 0.001,
        CancelDelay = 0.001
    },
    Thread = nil
}

-- ================= FAST PERFECT =================
local FastPerfect = {
    Enabled = false,
    Settings = {
        FishingDelay = 0.01,
        CancelDelay = 0.01,
        HookDetectionDelay = 0.01,
        RequestMinigameDelay = 0.01,
        TimeoutDelay = 0.5,
    },
    WaitingHook = false,
    CurrentCycle = 0,
    TotalFish = 0,
    MinigameConnection = nil,
    FishCaughtConnection = nil
}

-- ================= FISHING AREAS =================
local FishingAreas = {
    ["Ancient Jungle"] = {Pos = Vector3.new(1482.753784, 4.772020, -335.656494), Look = Vector3.new(0.505, -0.000, 0.863)},
    ["Ancient Ruin"] = {Pos = Vector3.new(6031.981, -585.924, 4713.157), Look = Vector3.new(0.316, -0.000, -0.949)},
    ["Arrow Lever"] = {Pos = Vector3.new(898.296, 8.449, -361.856), Look = Vector3.new(0.023, -0.000, 1.000)},
    ["Coral Reef"] = {Pos = Vector3.new(-3207.538, 6.087, 2011.079), Look = Vector3.new(0.973, 0.000, 0.229)},
    ["Crater Island"] = {Pos = Vector3.new(1058.976, 2.330, 5032.878), Look = Vector3.new(-0.789, 0.000, 0.615)},
    ["Cresent Lever"] = {Pos = Vector3.new(1419.750, 31.199, 78.570), Look = Vector3.new(0.000, -0.000, -1.000)},
    ["Crystalline Passage"] = {Pos = Vector3.new(6051.567, -538.900, 4370.979), Look = Vector3.new(0.109, 0.000, 0.994)},
    ["Diamond Lever"] = {Pos = Vector3.new(1818.930, 8.449, -284.110), Look = Vector3.new(0.000, 0.000, -1.000)},
    ["Enchant Room"] = {Pos = Vector3.new(3255.670, -1301.530, 1371.790), Look = Vector3.new(-0.000, -0.000, -1.000)},
    ["Esoteric Depths"] = {Pos = Vector3.new(2164.470, 3.220, 1242.390), Look = Vector3.new(-0.000, -0.000, -1.000)},
    ["Fisherman Island"] = {Pos = Vector3.new(74.030, 9.530, 2705.230), Look = Vector3.new(-0.000, -0.000, -1.000)},
    ["Hourglass Diamond Lever"] = {Pos = Vector3.new(1484.610, 8.450, -861.010), Look = Vector3.new(-0.000, -0.000, -1.000)},
    ["Iron Cavern"] = {Pos = Vector3.new(-8792.546, -588.000, 230.642), Look = Vector3.new(0.718, 0.000, 0.696)},
    ["Kohana"] = {Pos = Vector3.new(-668.732, 3.000, 681.580), Look = Vector3.new(0.889, -0.000, 0.458)},
    ["Kohana Volcano"] = {Pos = Vector3.new(-605.121, 19.516, 160.010), Look = Vector3.new(0.854, 0.000, 0.520)},
    ["Lost Isle"] = {Pos = Vector3.new(-3804.105, 2.344, -904.653), Look = Vector3.new(-0.901, -0.000, 0.433)},
    ["Pirate Cove"] = {Pos = Vector3.new(3428.686, 4.193, 3432.854), Look = Vector3.new(0.2789, -0.3725, 0.8851)},
    ["Pirate Treasure Room"] = {Pos = Vector3.new(3301.503, -305.071, 3039.451), Look = Vector3.new(0.7264, -0.6726, 0.1413)},
    ["Sacred Temple"] = {Pos = Vector3.new(1461.815, -22.125, -670.234), Look = Vector3.new(-0.990, -0.000, 0.143)},
    ["Second Enchant Altar"] = {Pos = Vector3.new(1479.587, 128.295, -604.224), Look = Vector3.new(-0.298, 0.000, -0.955)},
    ["Sisyphus Statue"] = {Pos = Vector3.new(-3743.745, -135.074, -1007.554), Look = Vector3.new(0.310, 0.000, 0.951)},
    ["Treasure Room"] = {Pos = Vector3.new(-3598.440, -281.274, -1645.855), Look = Vector3.new(-0.065, 0.000, -0.998)},
    ["Tropical Grove"] = {Pos = Vector3.new(-2162.920, 2.825, 3638.445), Look = Vector3.new(0.381, -0.000, 0.925)},
    ["Underground Cellar"] = {Pos = Vector3.new(2118.417, -91.448, -733.800), Look = Vector3.new(0.854, 0.000, 0.521)},
    ["Weather Machine"] = {Pos = Vector3.new(-1518.550, 2.875, 1916.148), Look = Vector3.new(0.042, 0.000, 0.999)},
}

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
local RE_MinigameChanged = GetRemote(RPath, "RE/FishingMinigameChanged")
local RE_FishCaught = GetRemote(RPath, "RE/FishCaught")

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

-- ================= BLATANT V2 CLEAN IMPLEMENTATION =================
local function safeFire(func)
    task.spawn(function()
        pcall(func)
    end)
end

local function ultraSpamLoop()
    local equipThread = task.spawn(function()
        while BlatantV2.Active do
            safeFire(function()
                RE_Equip:FireServer(1)
            end)
            task.wait(BlatantV2.Settings.EquipDelay)
        end
    end)
    
    while BlatantV2.Active do
        local startTime = tick()
        
        safeFire(function()
            RF_Charge:InvokeServer({[1] = startTime})
        end)
        
        task.wait(BlatantV2.Settings.ChargeDelay)
        
        local releaseTime = tick()
        safeFire(function()
            RF_Start:InvokeServer(1, 0, releaseTime)
        end)
        
        task.wait(BlatantV2.Settings.CompleteDelay)
        
        safeFire(function()
            RE_Complete:FireServer()
        end)
        
        task.wait(BlatantV2.Settings.CancelDelay)
        safeFire(function()
            RF_Cancel:InvokeServer()
        end)
    end
end

-- Setup event listener
task.spawn(function()
    RE_MinigameChanged.OnClientEvent:Connect(function(state)
        if not BlatantV2.Active then return end
        
        task.spawn(function()
            task.wait(BlatantV2.Settings.CompleteDelay)
            
            safeFire(function()
                RE_Complete:FireServer()
            end)
            
            task.wait(BlatantV2.Settings.CancelDelay)
            safeFire(function()
                RF_Cancel:InvokeServer()
            end)
        end)
    end)
end)

function FishingAPI:SetBlatantV2(state)
    if state == BlatantV2.Active then return end
    
    if state then
        -- Disable other modes first
        FishingAPI:SetLegit(false)
        FishingAPI:SetNormal(false)
        FishingAPI:SetActive(false)
        FishingAPI:SetBlatantV3(false)
        FishingAPI:SetBlatantV4(false)
        FishingAPI:SetBlatantV5(false)
        FishingAPI:SetFastPerfect(false)
        
        BlatantV2.Active = true
        BlatantV2.Thread = task.spawn(ultraSpamLoop)
    else
        BlatantV2.Active = false
        
        if BlatantV2.Thread then
            task.cancel(BlatantV2.Thread)
            BlatantV2.Thread = nil
        end
        
        -- Cleanup
        safeFire(function()
            RF_Update:InvokeServer(true)
        end)
        
        task.wait(0.2)
        
        safeFire(function()
            RF_Cancel:InvokeServer()
        end)
    end
end

function FishingAPI:SetBlatantV2Setting(setting, value)
    local num = tonumber(value)
    if not num then return end
    
    if setting == "CompleteDelay" then
        BlatantV2.Settings.CompleteDelay = math.max(0.001, num)
    elseif setting == "CancelDelay" then
        BlatantV2.Settings.CancelDelay = math.max(0.001, num)
    elseif setting == "ChargeDelay" then
        BlatantV2.Settings.ChargeDelay = math.max(0.001, num)
    elseif setting == "EquipDelay" then
        BlatantV2.Settings.EquipDelay = math.max(0.01, num)
    end
end

function FishingAPI:GetBlatantV2Stats()
    local cycleTime = BlatantV2.Settings.ChargeDelay + BlatantV2.Settings.CompleteDelay + BlatantV2.Settings.CancelDelay
    local speedPerSec = 0
    if cycleTime > 0 then
        speedPerSec = 1 / cycleTime
    end
    
    return {
        Active = BlatantV2.Active,
        Mode = "Ultra",
        Speed = string.format("%.0f fish/sec", speedPerSec),
        CycleTime = string.format("%.0fms", cycleTime * 1000),
        Settings = {
            ChargeDelay = BlatantV2.Settings.ChargeDelay,
            CompleteDelay = BlatantV2.Settings.CompleteDelay,
            CancelDelay = BlatantV2.Settings.CancelDelay,
            EquipDelay = BlatantV2.Settings.EquipDelay
        }
    }
end

-- ================= BLATANT V3 IMPLEMENTATION =================
local function protectedComplete()
    local now = tick()
    
    if now - BlatantV3.FishingState.lastCompleteTime < BlatantV3.FishingState.completeCooldown then
        return false
    end
    
    BlatantV3.FishingState.lastCompleteTime = now
    safeFire(function()
        RE_Complete:FireServer()
    end)
    
    return true
end

local function performCast()
    local now = tick()
    
    safeFire(function()
        RF_Charge:InvokeServer({[1] = now})
    end)
    safeFire(function()
        RF_Start:InvokeServer(1, 0, now)
    end)
end

local function fishingLoopV3()
    while BlatantV3.Active do
        performCast()
        
        task.wait(BlatantV3.Settings.CompleteDelay)
        
        if BlatantV3.Active then
            protectedComplete()
        end
        
        task.wait(BlatantV3.Settings.CancelDelay)
        
        if BlatantV3.Active then
            safeFire(function()
                RF_Cancel:InvokeServer()
            end)
        end
        
        task.wait(BlatantV3.Settings.ReCastDelay)
    end
end

-- Backup listener for V3
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not BlatantV3.Active then return end
    
    local now = tick()
    
    if now - BlatantV3.lastEventTime < 0.2 then
        return
    end
    BlatantV3.lastEventTime = now
    
    if now - BlatantV3.FishingState.lastCompleteTime < 0.3 then
        return
    end
    
    task.spawn(function()
        task.wait(BlatantV3.Settings.CompleteDelay)
        
        if protectedComplete() then
            task.wait(BlatantV3.Settings.CancelDelay)
            safeFire(function()
                RF_Cancel:InvokeServer()
            end)
        end
    end)
end)

function FishingAPI:SetBlatantV3(state)
    if state == BlatantV3.Active then return end
    
    if state then
        -- Disable other modes first
        FishingAPI:SetLegit(false)
        FishingAPI:SetNormal(false)
        FishingAPI:SetActive(false)
        FishingAPI:SetBlatantV2(false)
        FishingAPI:SetBlatantV4(false)
        FishingAPI:SetBlatantV5(false)
        FishingAPI:SetFastPerfect(false)
        
        BlatantV3.Active = true
        BlatantV3.FishingState.lastCompleteTime = 0
        
        safeFire(function()
            RF_Update:InvokeServer(true)
        end)
        
        task.wait(0.2)
        BlatantV3.Thread = task.spawn(fishingLoopV3)
    else
        BlatantV3.Active = false
        
        if BlatantV3.Thread then
            task.cancel(BlatantV3.Thread)
            BlatantV3.Thread = nil
        end
        
        safeFire(function()
            RF_Update:InvokeServer(true)
        end)
        
        task.wait(0.2)
        
        safeFire(function()
            RF_Cancel:InvokeServer()
        end)
    end
end

function FishingAPI:SetBlatantV3Setting(setting, value)
    local num = tonumber(value)
    if not num then return end
    
    if setting == "CompleteDelay" then
        BlatantV3.Settings.CompleteDelay = num
    elseif setting == "CancelDelay" then
        BlatantV3.Settings.CancelDelay = num
    elseif setting == "ReCastDelay" then
        BlatantV3.Settings.ReCastDelay = num
    end
end

-- ================= BLATANT V4 IMPLEMENTATION =================
local function CastV4()
    if not BlatantV4.Running or BlatantV4.WaitingHook then return end
    
    BlatantV4.CurrentCycle = BlatantV4.CurrentCycle + 1
    
    task.spawn(function()
        pcall(function()
            RF_Charge:InvokeServer({[10] = tick()})
            task.wait(BlatantV4.Settings.CastDelay)
            RF_Start:InvokeServer(10, 0, tick())
            
            BlatantV4.WaitingHook = true
            
            task.delay(BlatantV4.Settings.TimeoutDelay, function()
                if BlatantV4.WaitingHook and BlatantV4.Running then
                    BlatantV4.WaitingHook = false
                    RE_Complete:FireServer()
                    
                    task.wait(BlatantV4.Settings.CancelDelay)
                    pcall(function() RF_Cancel:InvokeServer() end)
                    
                    task.wait(BlatantV4.Settings.FishingDelay)
                    if BlatantV4.Running then CastV4() end
                end
            end)
        end)
    end)
end

-- Event handler for V4
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if BlatantV4.WaitingHook and typeof(state) == "string" and string.find(string.lower(state), "hook") then
        BlatantV4.WaitingHook = false
        
        task.spawn(function()
            task.wait(BlatantV4.Settings.HookWaitTime)
            RE_Complete:FireServer()
            
            task.wait(BlatantV4.Settings.CancelDelay)
            pcall(function() RF_Cancel:InvokeServer() end)
            
            task.wait(BlatantV4.Settings.FishingDelay)
            if BlatantV4.Running then CastV4() end
        end)
    end
end)

RE_FishCaught.OnClientEvent:Connect(function(name, data)
    if BlatantV4.Running then
        BlatantV4.WaitingHook = false
        BlatantV4.TotalFish = BlatantV4.TotalFish + 1
        
        task.spawn(function()
            task.wait(BlatantV4.Settings.CancelDelay)
            pcall(function() RF_Cancel:InvokeServer() end)
            
            task.wait(BlatantV4.Settings.FishingDelay)
            if BlatantV4.Running then CastV4() end
        end)
    end
end)

function FishingAPI:SetBlatantV4(state)
    if state == BlatantV4.Running then return end
    
    if state then
        -- Disable other modes first
        FishingAPI:SetLegit(false)
        FishingAPI:SetNormal(false)
        FishingAPI:SetActive(false)
        FishingAPI:SetBlatantV2(false)
        FishingAPI:SetBlatantV3(false)
        FishingAPI:SetBlatantV5(false)
        FishingAPI:SetFastPerfect(false)
        
        BlatantV4.Running = true
        BlatantV4.CurrentCycle = 0
        BlatantV4.TotalFish = 0
        CastV4()
    else
        BlatantV4.Running = false
        BlatantV4.WaitingHook = false
    end
end

function FishingAPI:SetBlatantV4Setting(setting, value)
    local num = tonumber(value)
    if not num then return end
    
    if setting == "FishingDelay" then
        BlatantV4.Settings.FishingDelay = num
    elseif setting == "CancelDelay" then
        BlatantV4.Settings.CancelDelay = num
    elseif setting == "HookWaitTime" then
        BlatantV4.Settings.HookWaitTime = num
    elseif setting == "CastDelay" then
        BlatantV4.Settings.CastDelay = num
    elseif setting == "TimeoutDelay" then
        BlatantV4.Settings.TimeoutDelay = num
    end
end

-- ================= BLATANT V5 IMPLEMENTATION =================
local function ultraSpamLoopV5()
    while BlatantV5.Active do
        local startTime = tick()
        
        safeFire(function()
            RF_Charge:InvokeServer({[1] = startTime})
        end)
        
        task.wait(BlatantV5.Settings.ChargeDelay)
        
        local releaseTime = tick()
        safeFire(function()
            RF_Start:InvokeServer(1, 0, releaseTime)
        end)
        
        task.wait(BlatantV5.Settings.CompleteDelay)
        
        safeFire(function()
            RE_Complete:FireServer()
        end)
        
        task.wait(BlatantV5.Settings.CancelDelay)
        safeFire(function()
            RF_Cancel:InvokeServer()
        end)
    end
end

RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not BlatantV5.Active then return end
    
    task.spawn(function()
        task.wait(BlatantV5.Settings.CompleteDelay)
        
        safeFire(function()
            RE_Complete:FireServer()
        end)
        
        task.wait(BlatantV5.Settings.CancelDelay)
        safeFire(function()
            RF_Cancel:InvokeServer()
        end)
    end)
end)

function FishingAPI:SetBlatantV5(state)
    if state == BlatantV5.Active then return end
    
    if state then
        -- Disable other modes first
        FishingAPI:SetLegit(false)
        FishingAPI:SetNormal(false)
        FishingAPI:SetActive(false)
        FishingAPI:SetBlatantV2(false)
        FishingAPI:SetBlatantV3(false)
        FishingAPI:SetBlatantV4(false)
        FishingAPI:SetFastPerfect(false)
        
        BlatantV5.Active = true
        BlatantV5.Thread = task.spawn(ultraSpamLoopV5)
    else
        BlatantV5.Active = false
        
        if BlatantV5.Thread then
            task.cancel(BlatantV5.Thread)
            BlatantV5.Thread = nil
        end
        
        safeFire(function()
            RF_Update:InvokeServer(true)
        end)
        
        task.wait(0.2)
        
        safeFire(function()
            RF_Cancel:InvokeServer()
        end)
    end
end

function FishingAPI:SetBlatantV5Setting(setting, value)
    local num = tonumber(value)
    if not num then return end
    
    if setting == "CompleteDelay" then
        BlatantV5.Settings.CompleteDelay = num
    elseif setting == "CancelDelay" then
        BlatantV5.Settings.CancelDelay = num
    elseif setting == "ChargeDelay" then
        BlatantV5.Settings.ChargeDelay = num
    end
end

-- ================= FAST PERFECT IMPLEMENTATION =================
local function CastFastPerfect()
    if not FastPerfect.Enabled or FastPerfect.WaitingHook then return end
    
    FastPerfect.CurrentCycle = FastPerfect.CurrentCycle + 1
    
    pcall(function()
        RF_Charge:InvokeServer({[22] = tick()})
        
        task.wait(FastPerfect.Settings.RequestMinigameDelay)
        RF_Start:InvokeServer(9, 0, tick())
        
        FastPerfect.WaitingHook = true
        
        task.delay(FastPerfect.Settings.TimeoutDelay, function()
            if FastPerfect.WaitingHook and FastPerfect.Enabled then
                FastPerfect.WaitingHook = false
                RE_Complete:FireServer()
                
                task.wait(FastPerfect.Settings.CancelDelay)
                pcall(function() RF_Cancel:InvokeServer() end)
                
                task.wait(FastPerfect.Settings.FishingDelay)
                if FastPerfect.Enabled then CastFastPerfect() end
            end
        end)
    end)
end

local function setupFastPerfectListeners()
    if FastPerfect.MinigameConnection then FastPerfect.MinigameConnection:Disconnect() end
    if FastPerfect.FishCaughtConnection then FastPerfect.FishCaughtConnection:Disconnect() end
    
    FastPerfect.MinigameConnection = RE_MinigameChanged.OnClientEvent:Connect(function(state)
        if not FastPerfect.Enabled then return end
        if not FastPerfect.WaitingHook then return end
        
        if typeof(state) == "string" and string.find(string.lower(state), "hook") then
            FastPerfect.WaitingHook = false
            
            task.wait(FastPerfect.Settings.HookDetectionDelay)
            RE_Complete:FireServer()
            
            task.wait(FastPerfect.Settings.CancelDelay)
            pcall(function() RF_Cancel:InvokeServer() end)
            
            task.wait(FastPerfect.Settings.FishingDelay)
            if FastPerfect.Enabled then CastFastPerfect() end
        end
    end)
    
    FastPerfect.FishCaughtConnection = RE_FishCaught.OnClientEvent:Connect(function(fishName, data)
        if not FastPerfect.Enabled then return end
        
        FastPerfect.WaitingHook = false
        FastPerfect.TotalFish = FastPerfect.TotalFish + 1
        
        task.wait(FastPerfect.Settings.CancelDelay)
        pcall(function() RF_Cancel:InvokeServer() end)
        
        task.wait(FastPerfect.Settings.FishingDelay)
        if FastPerfect.Enabled then CastFastPerfect() end
    end)
end

function FishingAPI:SetFastPerfect(state)
    if state == FastPerfect.Enabled then return end
    
    if state then
        -- Disable other modes first
        FishingAPI:SetLegit(false)
        FishingAPI:SetNormal(false)
        FishingAPI:SetActive(false)
        FishingAPI:SetBlatantV2(false)
        FishingAPI:SetBlatantV3(false)
        FishingAPI:SetBlatantV4(false)
        FishingAPI:SetBlatantV5(false)
        
        FastPerfect.Enabled = true
        FastPerfect.WaitingHook = false
        FastPerfect.CurrentCycle = 0
        FastPerfect.TotalFish = 0
        
        setupFastPerfectListeners()
        
        task.wait(0.5)
        CastFastPerfect()
    else
        FastPerfect.Enabled = false
        FastPerfect.WaitingHook = false
        
        if FastPerfect.MinigameConnection then
            FastPerfect.MinigameConnection:Disconnect()
            FastPerfect.MinigameConnection = nil
        end
        
        if FastPerfect.FishCaughtConnection then
            FastPerfect.FishCaughtConnection:Disconnect()
            FastPerfect.FishCaughtConnection = nil
        end
        
        pcall(function() RF_Cancel:InvokeServer() end)
    end
end

function FishingAPI:SetFastPerfectSetting(setting, value)
    local num = tonumber(value)
    if not num then return end
    
    if setting == "FishingDelay" then
        FastPerfect.Settings.FishingDelay = num
    elseif setting == "CancelDelay" then
        FastPerfect.Settings.CancelDelay = num
    elseif setting == "HookDetectionDelay" then
        FastPerfect.Settings.HookDetectionDelay = num
    elseif setting == "RequestMinigameDelay" then
        FastPerfect.Settings.RequestMinigameDelay = num
    elseif setting == "TimeoutDelay" then
        FastPerfect.Settings.TimeoutDelay = num
    end
end

-- Handle respawn for Fast Perfect
Players.LocalPlayer.CharacterAdded:Connect(function()
    if FastPerfect.Enabled then
        task.wait(2)
        
        FastPerfect.WaitingHook = false
        
        if FastPerfect.MinigameConnection then FastPerfect.MinigameConnection:Disconnect() end
        if FastPerfect.FishCaughtConnection then FastPerfect.FishCaughtConnection:Disconnect() end
        
        setupFastPerfectListeners()
        
        task.wait(1)
        CastFastPerfect()
    end
end)

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

function FishingAPI:SetTeleportFreeze(state)
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

function FishingAPI:TeleportToArea()
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

-- Function to get all area names
function FishingAPI:GetAreaNames()
    local names = {}
    for name, _ in pairs(FishingAreas) do
        table.insert(names, name)
    end
    table.insert(names, "Custom: Saved")
    return names
end

-- ================= CLEANUP =================
function FishingAPI:Cleanup()
    -- Stop all modes
    FishingAPI:SetLegit(false)
    FishingAPI:SetNormal(false)
    FishingAPI:SetActive(false)
    FishingAPI:SetBlatantV2(false)
    FishingAPI:SetBlatantV3(false)
    FishingAPI:SetBlatantV4(false)
    FishingAPI:SetBlatantV5(false)
    FishingAPI:SetFastPerfect(false)
    
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
