-- =========================================================
-- FISHING API (UNIFIED VERSION) - ALL BLATANT MODES
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

-- Threads
local normalLoopThread = nil
local normalEquipThread = nil
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
local AutoFishState = { IsActive = false, MinigameActive = false }

-- Original functions backup
local originalRodStarted = nil
local originalFishingStopped = nil
local originalClick = nil
local originalCharge = nil

-- ================= MODES STATE =================
local ActiveMode = nil  -- nil, "Legit", "Normal", "BlatantOld", "BlatantNew", "BlatantV2", "BlatantV3", "BlatantV4", "BlatantV5", "FastPerfect"
local ActiveThread = nil

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

local function safeFire(func)
    task.spawn(function()
        pcall(func)
    end)
end

-- ================= INITIALIZE CONTROLLERS =================
function FishingAPI:Initialize()
    task.wait(0.2)
    FishingController = require(RepStorage:WaitForChild("Controllers").FishingController)
    
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

-- ================= MODE MANAGEMENT =================
local function disableOtherModes()
    -- Stop current mode
    if ActiveThread then
        task.cancel(ActiveThread)
        ActiveThread = nil
    end
    
    -- Reset all states
    legitAutoState = false
    normalInstantState = false
    
    -- Cancel fishing
    safeFire(function()
        RF_Cancel:InvokeServer()
    end)
end

function FishingAPI:SetMode(mode)
    ActiveMode = mode
end

-- ================= LEGIT MODE =================
function FishingAPI:SetLegitSpeed(v)
    v = tonumber(v)
    if v and v >= 0.01 then 
        SPEED_LEGIT = v 
    end
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
        safeFire(function() RE_Equip:FireServer(1) end)
        
        -- 2. Force Server AutoFishing State
        safeFire(function() RF_Update:InvokeServer(true) end)
        
        -- 3. Sembunyikan UI Minigame
        if fishingGui then fishingGui.Visible = false end
        if chargeGui then chargeGui.Visible = false end
        
        -- Start equip thread
        legitEquipThread = task.spawn(function()
            while legitAutoState do
                safeFire(function() RE_Equip:FireServer(1) end)
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
    if state then
        disableOtherModes()
        FishingAPI:SetMode("Legit")
        legitAutoState = true
        ToggleAutoClick(true)
    else
        legitAutoState = false
        ToggleAutoClick(false)
        safeFire(function() RF_Update:InvokeServer(false) end)
        ActiveMode = nil
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
    safeFire(function() RF_Charge:InvokeServer(timestamp) end)
    safeFire(function() RF_Start:InvokeServer(-139.630452165, 0.99647927980797) end)
    
    task.wait(normalCompleteDelay)
    
    safeFire(function() RE_Complete:FireServer() end)
    task.wait(0.3)
    safeFire(function() RF_Cancel:InvokeServer() end)
end

function FishingAPI:SetNormal(state)
    if state then
        disableOtherModes()
        FishingAPI:SetMode("Normal")
        normalInstantState = true
        
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
                safeFire(function() RE_Equip:FireServer(1) end)
                task.wait(0.1)
            end
        end)
    else
        normalInstantState = false
        
        if normalLoopThread then 
            task.cancel(normalLoopThread) 
            normalLoopThread = nil 
        end
        if normalEquipThread then 
            task.cancel(normalEquipThread) 
            normalEquipThread = nil 
        end
        
        safeFire(function() RE_Equip:FireServer(0) end)
        ActiveMode = nil
    end
end

-- ================= BLATANT V2 (Ultra Fast) =================
local BlatantV2 = {
    Active = false,
    Settings = {
        ChargeDelay = 0.007,
        CompleteDelay = 0.001,
        CancelDelay = 0.001
    }
}

local function ultraSpamLoop()
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

-- Setup V2 event listener
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

-- ================= BLATANT V3 (Optimized) =================
local BlatantV3 = {
    Active = false,
    Settings = {
        CompleteDelay = 0.73,
        CancelDelay = 0.3,
        ReCastDelay = 0.001
    }
}

local FishingState = {
    lastCompleteTime = 0,
    completeCooldown = 0.4
}

local function protectedComplete()
    local now = tick()
    
    if now - FishingState.lastCompleteTime < FishingState.completeCooldown then
        return false
    end
    
    FishingState.lastCompleteTime = now
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

-- ================= BLATANT V4 (Event Based) =================
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
                    safeFire(function() RF_Cancel:InvokeServer() end)
                    
                    task.wait(BlatantV4.Settings.FishingDelay)
                    if BlatantV4.Running then CastV4() end
                end
            end)
        end)
    end)
end

-- V4 Event Listeners
task.spawn(function()
    RE_MinigameChanged.OnClientEvent:Connect(function(state)
        if BlatantV4.WaitingHook and typeof(state) == "string" and string.find(string.lower(state), "hook") then
            BlatantV4.WaitingHook = false
            
            task.spawn(function()
                task.wait(BlatantV4.Settings.HookWaitTime)
                RE_Complete:FireServer()
                
                task.wait(BlatantV4.Settings.CancelDelay)
                safeFire(function() RF_Cancel:InvokeServer() end)
                
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
                safeFire(function() RF_Cancel:InvokeServer() end)
                
                task.wait(BlatantV4.Settings.FishingDelay)
                if BlatantV4.Running then CastV4() end
            end)
        end
    end)
end)

-- ================= BLATANT V5 (Clean Version) =================
local BlatantV5 = {
    Active = false,
    Settings = {
        ChargeDelay = 0.007,
        CompleteDelay = 0.001,
        CancelDelay = 0.001
    }
}

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

-- ================= FAST PERFECT MODE =================
local FastPerfect = {
    Enabled = false,
    WaitingHook = false,
    CurrentCycle = 0,
    TotalFish = 0,
    Settings = {
        FishingDelay = 0.01,
        CancelDelay = 0.01,
        HookDetectionDelay = 0.01,
        RequestMinigameDelay = 0.01,
        TimeoutDelay = 0.5,
    }
}

local MinigameConnection = nil
local FishCaughtConnection = nil

local function CastPerfect()
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
                safeFire(function() RF_Cancel:InvokeServer() end)
                
                task.wait(FastPerfect.Settings.FishingDelay)
                if FastPerfect.Enabled then CastPerfect() end
            end
        end)
    end)
end

-- Setup Perfect mode listeners
local function setupPerfectListeners()
    if MinigameConnection then MinigameConnection:Disconnect() end
    if FishCaughtConnection then FishCaughtConnection:Disconnect() end
    
    MinigameConnection = RE_MinigameChanged.OnClientEvent:Connect(function(state)
        if not FastPerfect.Enabled then return end
        if not FastPerfect.WaitingHook then return end
        
        if typeof(state) == "string" and string.find(string.lower(state), "hook") then
            FastPerfect.WaitingHook = false
            
            task.wait(FastPerfect.Settings.HookDetectionDelay)
            RE_Complete:FireServer()
            
            task.wait(FastPerfect.Settings.CancelDelay)
            safeFire(function() RF_Cancel:InvokeServer() end)
            
            task.wait(FastPerfect.Settings.FishingDelay)
            if FastPerfect.Enabled then CastPerfect() end
        end
    end)
    
    FishCaughtConnection = RE_FishCaught.OnClientEvent:Connect(function(fishName, data)
        if not FastPerfect.Enabled then return end
        
        FastPerfect.WaitingHook = false
        FastPerfect.TotalFish = FastPerfect.TotalFish + 1
        
        task.wait(FastPerfect.Settings.CancelDelay)
        safeFire(function() RF_Cancel:InvokeServer() end)
        
        task.wait(FastPerfect.Settings.FishingDelay)
        if FastPerfect.Enabled then CastPerfect() end
    end)
end

-- ================= BLATANT MODE PUBLIC API =================
function FishingAPI:SetBlatantMode(mode, state)
    if not state then
        -- Stop current mode
        disableOtherModes()
        ActiveMode = nil
        return
    end
    
    disableOtherModes()
    FishingAPI:SetMode(mode)
    
    if mode == "BlatantV2" then
        BlatantV2.Active = true
        ActiveThread = task.spawn(ultraSpamLoop)
        
    elseif mode == "BlatantV3" then
        BlatantV3.Active = true
        FishingState.lastCompleteTime = 0
        safeFire(function() RF_Update:InvokeServer(true) end)
        task.wait(0.2)
        ActiveThread = task.spawn(fishingLoopV3)
        
    elseif mode == "BlatantV4" then
        BlatantV4.Running = true
        BlantantV4.CurrentCycle = 0
        BlantantV4.TotalFish = 0
        task.wait(0.5)
        CastV4()
        
    elseif mode == "BlatantV5" then
        BlatantV5.Active = true
        ActiveThread = task.spawn(ultraSpamLoopV5)
        
    elseif mode == "FastPerfect" then
        FastPerfect.Enabled = true
        FastPerfect.WaitingHook = false
        FastPerfect.CurrentCycle = 0
        FastPerfect.TotalFish = 0
        setupPerfectListeners()
        task.wait(0.5)
        CastPerfect()
    end
end

-- Settings for each mode
function FishingAPI:SetBlatantSetting(mode, setting, value)
    local num = tonumber(value)
    if not num then return end
    
    if mode == "BlatantV2" then
        if setting == "CompleteDelay" then
            BlatantV2.Settings.CompleteDelay = math.max(0.001, num)
        elseif setting == "CancelDelay" then
            BlatantV2.Settings.CancelDelay = math.max(0.001, num)
        elseif setting == "ChargeDelay" then
            BlatantV2.Settings.ChargeDelay = math.max(0.001, num)
        end
        
    elseif mode == "BlatantV3" then
        if setting == "CompleteDelay" then
            BlatantV3.Settings.CompleteDelay = num
        elseif setting == "CancelDelay" then
            BlatantV3.Settings.CancelDelay = num
        elseif setting == "ReCastDelay" then
            BlatantV3.Settings.ReCastDelay = num
        end
        
    elseif mode == "BlatantV4" then
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
        
    elseif mode == "BlatantV5" then
        if setting == "CompleteDelay" then
            BlatantV5.Settings.CompleteDelay = math.max(0.001, num)
        elseif setting == "CancelDelay" then
            BlatantV5.Settings.CancelDelay = math.max(0.001, num)
        elseif setting == "ChargeDelay" then
            BlatantV5.Settings.ChargeDelay = math.max(0.001, num)
        end
        
    elseif mode == "FastPerfect" then
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
end

function FishingAPI:GetBlatantStats(mode)
    if mode == "BlatantV2" then
        local cycleTime = BlatantV2.Settings.ChargeDelay + BlatantV2.Settings.CompleteDelay + BlatantV2.Settings.CancelDelay
        local speed = cycleTime > 0 and (1 / cycleTime) or 0
        return {
            Active = BlatantV2.Active,
            Speed = string.format("%.0f fish/sec", speed),
            CycleTime = string.format("%.0fms", cycleTime * 1000)
        }
        
    elseif mode == "BlatantV3" then
        local cycleTime = BlatantV3.Settings.CompleteDelay + BlatantV3.Settings.CancelDelay + BlatantV3.Settings.ReCastDelay
        local speed = cycleTime > 0 and (1 / cycleTime) or 0
        return {
            Active = BlatantV3.Active,
            Speed = string.format("%.0f fish/sec", speed),
            CycleTime = string.format("%.0fms", cycleTime * 1000)
        }
        
    elseif mode == "BlatantV4" then
        return {
            Active = BlatantV4.Running,
            Cycle = BlatantV4.CurrentCycle,
            TotalFish = BlatantV4.TotalFish
        }
        
    elseif mode == "BlatantV5" then
        local cycleTime = BlatantV5.Settings.ChargeDelay + BlatantV5.Settings.CompleteDelay + BlatantV5.Settings.CancelDelay
        local speed = cycleTime > 0 and (1 / cycleTime) or 0
        return {
            Active = BlatantV5.Active,
            Speed = string.format("%.0f fish/sec", speed),
            CycleTime = string.format("%.0fms", cycleTime * 1000)
        }
        
    elseif mode == "FastPerfect" then
        return {
            Active = FastPerfect.Enabled,
            Cycle = FastPerfect.CurrentCycle,
            TotalFish = FastPerfect.TotalFish
        }
    end
    
    return {Active = false}
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
    
    hrp.Anchored = false
    TeleportToLookAt(area.Pos, area.Look)
    
    local startTime = os.clock()
    while (os.clock() - startTime) < 1.5 and isTeleportFreezeActive do
        if hrp then
            hrp.Velocity = Vector3.new(0,0,0)
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
            hrp.CFrame = CFrame.new(area.Pos, area.Pos + area.Look) * CFrame.new(0, 0.5, 0)
        end
        RunService.Heartbeat:Wait()
    end
    
    if isTeleportFreezeActive and hrp then
        hrp.Anchored = true
    end
    
    return true
end

function FishingAPI:TeleportToArea(FishingAreas)
    local area = (selectedArea == "Custom: Saved" and savedPosition) or FishingAreas[selectedArea]
    if not area then return false end
    
    if isTeleportFreezeActive then
        local hrp = GetHRP()
        if hrp then hrp.Anchored = false end
        isTeleportFreezeActive = false
    end
    
    return TeleportToLookAt(area.Pos, area.Look)
end

-- ================= CLEANUP =================
function FishingAPI:Cleanup()
    -- Stop all modes
    FishingAPI:SetLegit(false)
    FishingAPI:SetNormal(false)
    FishingAPI:SetBlatantMode("BlatantV2", false)
    FishingAPI:SetBlatantMode("BlatantV3", false)
    FishingAPI:SetBlatantMode("BlatantV4", false)
    FishingAPI:SetBlatantMode("BlatantV5", false)
    FishingAPI:SetBlatantMode("FastPerfect", false)
    
    -- Reset states
    BlatantV4.Running = false
    FastPerfect.Enabled = false
    
    -- Disconnect listeners
    if MinigameConnection then
        MinigameConnection:Disconnect()
        MinigameConnection = nil
    end
    
    if FishCaughtConnection then
        FishCaughtConnection:Disconnect()
        FishCaughtConnection = nil
    end
    
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
    
    ActiveMode = nil
end

-- Initialize controllers
task.spawn(function()
    FishingAPI:Initialize()
end)

return FishingAPI
