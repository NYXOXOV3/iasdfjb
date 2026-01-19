-- =========================================================
-- FISHING API (UNIFIED VERSION)
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
            pcall(RE_Complete.FireServer, RE_Complete)
        end
    end)
end

local function FishingLoop()
    -- Equip thread
    blatantEquipThread = task.spawn(function()
        while Config.Active do
            pcall(RE_Equip.FireServer, RE_Equip, 1)
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
        
        pcall(RF_Cancel.InvokeServer, RF_Cancel)
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

-- =========================================================
-- BLATANT V2 - BRUTAL MODE (EXTREME OPTIMIZATION)
-- =========================================================

-- ================= CONFIGURATION =================
local BlatantV2 = {
    Active = false,
    Mode = "Extreme", -- "Extreme", "Ultra", "GodMode"
    
    -- Timing Config
    EquipDelay = 0.02,        -- SUPER FAST equip spam
    CompleteDelay = 0.08,     -- Almost instant complete
    CancelDelay = 0.05,       -- Minimal delay between cycles
    BatchSize = 5,            -- Send multiple requests at once
    
    -- Advanced Features
    UsePacketSpam = true,     -- Spam multiple packets
    BypassCooldown = true,    -- Try to bypass server cooldowns
    UseMultiTarget = true,    -- Send to multiple remote targets
    AntiKick = true,          -- Anti-kick protection
    
    -- Performance
    MaxThreads = 3,           -- Multi-threading
    RequestQueue = {},        -- Queue for batch processing
}

-- Thread Management
local V2Threads = {}
local V2MainThread = nil
local V2EquipThread = nil
local V2PacketThread = nil
local V2AntiKickThread = nil

-- Remote Targets (Multiple endpoints for redundancy)
local RemoteTargets = {}

-- ================= REMOTE DISCOVERY =================
local function DiscoverAllRemotes()
    local remotes = {}
    
    -- Main fishing remotes
    local mainRemotes = {
        "RF/ChargeFishingRod",
        "RF/RequestFishingMinigameStarted", 
        "RE/FishingCompleted",
        "RF/CancelFishingInputs",
        "RE/EquipToolFromHotbar",
        "RF/UpdateAutoFishingState"
    }
    
    -- Alternative remote names (if game uses different naming)
    local altNames = {
        "ChargeFishingRod",
        "StartFishingMinigame",
        "CompleteFishing",
        "CancelFishing",
        "EquipFishingRod",
        "SetAutoFishing"
    }
    
    -- Search in common paths
    local searchPaths = {
        {"Packages", "_Index", "sleitnick_net@0.2.0", "net"},
        {"Remotes", "Fishing"},
        {"Events", "Fishing"},
        {"Shared", "Remotes"},
        {"Client", "Remotes"}
    }
    
    for _, path in ipairs(searchPaths) do
        local success, folder = pcall(function()
            local obj = RepStorage
            for _, p in ipairs(path) do
                obj = obj:WaitForChild(p, 1)
            end
            return obj
        end)
        
        if success and folder then
            for _, remoteName in ipairs(mainRemotes) do
                local remote = folder:FindFirstChild(remoteName)
                if remote then
                    remotes[remoteName] = remote
                end
            end
            
            -- Also search for alternative names
            for _, altName in ipairs(altNames) do
                for _, child in ipairs(folder:GetChildren()) do
                    if string.find(child.Name:lower(), altName:lower()) then
                        remotes[altName] = child
                    end
                end
            end
        end
    end
    
    return remotes
end

-- ================= PACKET ENGINE =================
local PacketEngine = {
    Sequence = 0,
    LastSent = 0,
    CooldownBypass = false
}

function PacketEngine:SendBurst(remote, count, ...)
    local args = {...}
    local results = {}
    
    for i = 1, math.min(count, 10) do -- Max 10 per burst
        task.spawn(function()
            local success, result = pcall(function()
                if remote:IsA("RemoteEvent") then
                    return remote:FireServer(unpack(args))
                elseif remote:IsA("RemoteFunction") then
                    return remote:InvokeServer(unpack(args))
                end
            end)
            
            if success then
                table.insert(results, result)
            end
        end)
        
        -- Micro delay between packets
        if i % 3 == 0 then
            task.wait(0.001)
        end
    end
    
    return results
end

function PacketEngine:SendToAllRemotes(remotes, ...)
    local results = {}
    
    for name, remote in pairs(remotes) do
        if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
            task.spawn(function()
                pcall(function()
                    if remote:IsA("RemoteEvent") then
                        remote:FireServer(...)
                    else
                        remote:InvokeServer(...)
                    end
                end)
            end)
            
            results[name] = true
        end
    end
    
    return results
end

-- ================= BRUTAL FISHING ENGINE =================
local function ExtremeFishingLoop()
    local Remotes = DiscoverAllRemotes()
    
    -- Start equip spam thread
    V2EquipThread = task.spawn(function()
        local RE_Equip = Remotes["RE/EquipToolFromHotbar"] or Remotes["EquipFishingRod"]
        while BlatantV2.Active and RE_Equip do
            -- SUPER FAST equip spam
            for i = 1, 3 do -- Triple tap
                pcall(RE_Equip.FireServer, RE_Equip, 1)
                task.wait(0.01)
            end
            task.wait(BlatantV2.EquipDelay)
        end
    end)
    
    -- Start packet spam thread if enabled
    if BlatantV2.UsePacketSpam then
        V2PacketThread = task.spawn(function()
            while BlatantV2.Active do
                -- Spam update packets to prevent timeout
                local RF_Update = Remotes["RF/UpdateAutoFishingState"] or Remotes["SetAutoFishing"]
                if RF_Update then
                    PacketEngine:SendBurst(RF_Update, 2, true)
                end
                task.wait(0.5)
            end
        end)
    end
    
    -- Anti-kick thread
    if BlatantV2.AntiKick then
        V2AntiKickThread = task.spawn(function()
            local lastPosition = GetHRP().Position
            while BlatantV2.Active do
                task.wait(1)
                
                -- Check if player is stuck
                local hrp = GetHRP()
                if hrp then
                    local distance = (hrp.Position - lastPosition).Magnitude
                    if distance < 1 then
                        -- Slight movement to prevent AFK detection
                        hrp.CFrame = hrp.CFrame * CFrame.new(0, 0.1, 0)
                    end
                    lastPosition = hrp.Position
                end
            end
        end)
    end
    
    -- MAIN BRUTAL FISHING LOOP
    while BlatantV2.Active do
        local startTime = os.clock()
        
        -- 🔥 BATCH PROCESSING: Send multiple requests simultaneously
        local batchTasks = {}
        
        for i = 1, BlatantV2.BatchSize do
            table.insert(batchTasks, task.spawn(function()
                -- 1. CANCEL any existing state
                local RF_Cancel = Remotes["RF/CancelFishingInputs"] or Remotes["CancelFishing"]
                if RF_Cancel then
                    pcall(RF_Cancel.InvokeServer, RF_Cancel)
                end
                
                -- 2. CHARGE with extreme values
                local RF_Charge = Remotes["RF/ChargeFishingRod"] or Remotes["ChargeFishingRod"]
                if RF_Charge then
                    if BlatantV2.BypassCooldown then
                        -- Try different values to bypass cooldown
                        local values = {math.huge, 999999, os.time() * 1000, -math.huge}
                        for _, val in ipairs(values) do
                            pcall(RF_Charge.InvokeServer, RF_Charge, val)
                            task.wait(0.001)
                        end
                    else
                        pcall(RF_Charge.InvokeServer, RF_Charge, math.huge)
                    end
                end
                
                -- 3. START fishing with optimized values
                local RF_Start = Remotes["RF/RequestFishingMinigameStarted"]
                if RF_Start then
                    -- Try multiple angle combinations
                    local angles = {
                        {-139.6379699707, 0.99647927980797},  -- Original
                        {-139.63, 0.996},                     -- Rounded
                        {-140, 1.0},                          -- Extreme
                        {-139.5, 0.995},                      -- Slight variation
                    }
                    
                    for _, angle in ipairs(angles) do
                        pcall(RF_Start.InvokeServer, RF_Start, angle[1], angle[2])
                        task.wait(0.001)
                    end
                end
                
                -- 4. INSTANT COMPLETE
                task.wait(BlatantV2.CompleteDelay)
                
                local RE_Complete = Remotes["RE/FishingCompleted"] or Remotes["CompleteFishing"]
                if RE_Complete and BlatantV2.Active then
                    -- Send completion multiple times
                    for j = 1, 2 do
                        pcall(RE_Complete.FireServer, RE_Complete)
                        task.wait(0.001)
                    end
                end
                
                -- 5. MULTI-REMOTE ATTACK (if enabled)
                if BlatantV2.UseMultiTarget then
                    PacketEngine:SendToAllRemotes(Remotes, true)
                end
            end))
            
            -- Small delay between batch items
            if i % 2 == 0 then
                task.wait(0.005)
            end
        end
        
        -- Wait for batch completion
        for _, taskRef in ipairs(batchTasks) do
            if taskRef then
                pcall(task.cancel, taskRef)
            end
        end
        
        -- 🔥 MODE-SPECIFIC OPTIMIZATIONS
        if BlatantV2.Mode == "Ultra" then
            -- Ultra mode: Even faster cycles
            local elapsed = os.clock() - startTime
            local targetDelay = math.max(0.01, BlatantV2.CancelDelay - elapsed)
            task.wait(targetDelay)
            
        elseif BlatantV2.Mode == "GodMode" then
            -- GodMode: Continuous spam with zero delay
            task.wait(0.01) -- Minimal delay to prevent crash
            
            -- Additional spam cycle
            local RF_Update = Remotes["RF/UpdateAutoFishingState"]
            if RF_Update then
                for i = 1, 3 do
                    pcall(RF_Update.InvokeServer, RF_Update, true)
                    task.wait(0.001)
                end
            end
            
        else -- Extreme (default)
            task.wait(BlatantV2.CancelDelay)
        end
        
        -- 🔥 PERFORMANCE MONITORING
        local cycleTime = os.clock() - startTime
        if cycleTime > 0.5 then
            -- Auto-adjust if cycle is too slow
            BlatantV2.BatchSize = math.max(1, BlatantV2.BatchSize - 1)
        elseif cycleTime < 0.1 and BlatantV2.BatchSize < 10 then
            -- Increase batch size if cycle is fast
            BlatantV2.BatchSize = BlatantV2.BatchSize + 1
        end
    end
end

-- ================= PUBLIC API =================
function FishingAPI:SetBlatantV2(state)
    if state == BlatantV2.Active then return end
    
    BlatantV2.Active = state
    
    if state then
        -- Disable other modes
        FishingAPI:SetLegit(false)
        FishingAPI:SetNormal(false)
        FishingAPI:SetActive(false) -- Disable old blatant
        
        -- Start brutal mode
        V2MainThread = task.spawn(ExtremeFishingLoop)
        
        -- Notify
        if WindUI then
            WindUI:Notify({
                Title = "🚀 BLATANT V2 ACTIVATED",
                Content = "Mode: " .. BlatantV2.Mode .. " | Batch: " .. BlatantV2.BatchSize,
                Duration = 3,
                Icon = "zap"
            })
        end
    else
        -- Stop all threads
        if V2MainThread then task.cancel(V2MainThread) end
        if V2EquipThread then task.cancel(V2EquipThread) end
        if V2PacketThread then task.cancel(V2PacketThread) end
        if V2AntiKickThread then task.cancel(V2AntiKickThread) end
        
        V2MainThread = nil
        V2EquipThread = nil
        V2PacketThread = nil
        V2AntiKickThread = nil
        
        -- Send cleanup packets
        local Remotes = DiscoverAllRemotes()
        local RF_Cancel = Remotes["RF/CancelFishingInputs"]
        if RF_Cancel then
            pcall(RF_Cancel.InvokeServer, RF_Cancel)
        end
    end
end

function FishingAPI:SetBlatantV2Mode(mode)
    if mode == "Extreme" or mode == "Ultra" or mode == "GodMode" then
        BlatantV2.Mode = mode
        
        -- Adjust settings based on mode
        if mode == "Ultra" then
            BlatantV2.CompleteDelay = 0.05
            BlatantV2.CancelDelay = 0.03
            BlatantV2.BatchSize = 7
        elseif mode == "GodMode" then
            BlatantV2.CompleteDelay = 0.03
            BlatantV2.CancelDelay = 0.01
            BlatantV2.BatchSize = 10
            BlatantV2.UsePacketSpam = true
            BlatantV2.BypassCooldown = true
        end
    end
end

function FishingAPI:SetBlatantV2Setting(setting, value)
    if setting == "CompleteDelay" then
        BlatantV2.CompleteDelay = math.max(0.01, tonumber(value) or 0.08)
    elseif setting == "CancelDelay" then
        BlatantV2.CancelDelay = math.max(0.01, tonumber(value) or 0.05)
    elseif setting == "BatchSize" then
        BlatantV2.BatchSize = math.clamp(tonumber(value) or 5, 1, 15)
    elseif setting == "EquipDelay" then
        BlatantV2.EquipDelay = math.max(0.01, tonumber(value) or 0.02)
    end
end

function FishingAPI:GetBlatantV2Stats()
    return {
        Active = BlatantV2.Active,
        Mode = BlatantV2.Mode,
        Speed = math.floor(1 / (BlatantV2.CompleteDelay + BlatantV2.CancelDelay)) .. " fish/sec",
        BatchSize = BlatantV2.BatchSize,
        CycleTime = (BlatantV2.CompleteDelay + BlatantV2.CancelDelay) * 1000 .. "ms"
    }
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

-- ================= CLEANUP =================
function FishingAPI:Cleanup()
    -- Stop all modes
    FishingAPI:SetLegit(false)
    FishingAPI:SetNormal(false)
    FishingAPI:SetActive(false)
    
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
