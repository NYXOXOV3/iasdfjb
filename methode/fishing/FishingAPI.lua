-- =========================================================
-- FISHING API (BASED ON ORIGINAL FARM LOGIC)
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

local normalLoopThread
local blatantLoopThread
local normalEquipThread
local blatantEquipThread
local legitEquipThread
local legitClickThread

local SPEED_LEGIT = 0.05
local normalCompleteDelay = 1.5

local isTeleportFreezeActive = false
local selectedArea = nil
local savedPosition = nil

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

-- ================= LEGIT =================
local FishingController = require(RepStorage.Controllers.FishingController)

local AutoFishState = {Active = false, Minigame = false}

local function performClick()
    FishingController:RequestFishingMinigameClick()
    task.wait(SPEED_LEGIT)
end

local origRod = FishingController.FishingRodStarted
FishingController.FishingRodStarted = function(self, ...)
    origRod(self, ...)
    if AutoFishState.Active and not AutoFishState.Minigame then
        AutoFishState.Minigame = true
        legitClickThread = task.spawn(function()
            while AutoFishState.Active and AutoFishState.Minigame do
                performClick()
            end
        end)
    end
end

local origStop = FishingController.FishingStopped
FishingController.FishingStopped = function(self, ...)
    origStop(self, ...)
    AutoFishState.Minigame = false
end

function FishingAPI:SetLegitSpeed(v)
    v = tonumber(v)
    if v and v >= 0.01 then SPEED_LEGIT = v end
end

function FishingAPI:SetLegit(state)
    legitAutoState = state
    AutoFishState.Active = state

    if state then
        RF_Update:InvokeServer(true)
        legitEquipThread = task.spawn(function()
            while legitAutoState do
                RE_Equip:FireServer(1)
                task.wait(0.1)
            end
        end)
    else
        if legitClickThread then task.cancel(legitClickThread) end
        if legitEquipThread then task.cancel(legitEquipThread) end
    end
end

-- ================= NORMAL =================
function FishingAPI:SetNormalDelay(v)
    v = tonumber(v)
    if v then normalCompleteDelay = v end
end

function FishingAPI:SetNormal(state)
    normalInstantState = state

    if state then
        normalLoopThread = task.spawn(function()
            while normalInstantState do
                RF_Charge:InvokeServer(os.clock())
                RF_Start:InvokeServer(-139.63, 0.996)
                task.wait(normalCompleteDelay)
                RE_Complete:FireServer()
                RF_Cancel:InvokeServer()
                task.wait(0.1)
            end
        end)

        normalEquipThread = task.spawn(function()
            while normalInstantState do
                RE_Equip:FireServer(1)
                task.wait(0.1)
            end
        end)
    else
        if normalLoopThread then task.cancel(normalLoopThread) end
        if normalEquipThread then task.cancel(normalEquipThread) end
    end
end

-- ================= BLATANT =================
local FC = FishingController
local origClick = FC.RequestFishingMinigameClick
local origCharge = FC.RequestChargeFishingRod

local Blatant = {
    Active = false,
    Mode = "Old",
    CancelDelay = 1.75,
    CompleteDelay = 1.33,
    AutoPerfect = false
}

local function SyncAutoPerfect()
    local enable = Blatant.Active and Blatant.Mode == "New"
    if enable and not Blatant.AutoPerfect then
        Blatant.AutoPerfect = true
        FC.RequestFishingMinigameClick = function() end
        FC.RequestChargeFishingRod = function() end
    elseif not enable and Blatant.AutoPerfect then
        Blatant.AutoPerfect = false
        FC.RequestFishingMinigameClick = origClick
        FC.RequestChargeFishingRod = origCharge
    end
end

local function BlatantLoop()
    blatantEquipThread = task.spawn(function()
        while Blatant.Active do
            RE_Equip:FireServer(1)
            task.wait(0.05) -- LEBIH CEPAT
        end
    end)

    while Blatant.Active do
        -- 🔥 RESET STATE (KUNCI SPEED)
        RF_Cancel:InvokeServer()

        -- 🔥 INSTANT CHARGE + START
        RF_Charge:InvokeServer(math.huge)
        RF_Start:InvokeServer(-139.6379699707, 0.99647927980797)

        -- 🔥 COMPLETE TANPA DELAY ASYNC
        task.wait(Blatant.CompleteDelay)
        if Blatant.Active then
            RE_Complete:FireServer()
        end

        -- 🔥 LOOP CEPAT
        task.wait(Blatant.CancelDelay)
    end
end

function FishingAPI:SetActive(state)
    Blatant.Active = state
    SyncAutoPerfect()

    if state then
        RF_Update:InvokeServer(true) -- PANGGIL SEKALI
        if blatantLoopThread then task.cancel(blatantLoopThread) end
        blatantLoopThread = task.spawn(BlatantLoop)
    else
        if blatantLoopThread then task.cancel(blatantLoopThread) end
        if blatantEquipThread then task.cancel(blatantEquipThread) end
        RF_Cancel:InvokeServer()
    end
end

function FishingAPI:SetMode(mode)
    Blatant.Mode = mode
    SyncAutoPerfect()
end

function FishingAPI:SetCancelDelay(v)
    v = tonumber(v)
    if v then Blatant.CancelDelay = v end
end

function FishingAPI:SetCompleteDelay(v)
    v = tonumber(v)
    if v then Blatant.CompleteDelay = v end
end

-- ================= AREA =================
function FishingAPI:SetSelectedArea(v)
    selectedArea = v
end

function FishingAPI:SaveCurrentPosition()
    local hrp = GetHRP()
    savedPosition = {Pos = hrp.Position, Look = hrp.CFrame.LookVector}
    return savedPosition
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

    TeleportToLookAt(area.Pos, area.Look)

    local start = os.clock()
    while os.clock() - start < 1.5 and isTeleportFreezeActive do
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(area.Pos, area.Pos + area.Look) * CFrame.new(0,0.5,0)
        RunService.Heartbeat:Wait()
    end

    if isTeleportFreezeActive then hrp.Anchored = true end
    return true
end

function FishingAPI:TeleportToArea(FishingAreas)
    local area = (selectedArea == "Custom: Saved" and savedPosition) or FishingAreas[selectedArea]
    if not area then return false end
    return TeleportToLookAt(area.Pos, area.Look)
end

return FishingAPI
