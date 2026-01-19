-- =========================================================
-- FISHING API (FULL, FIXED, NO LOGIC CUT)
-- =========================================================

local FishingAPI = {}

-- ================= SERVICES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RepStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- ================= GLOBAL STATE =================
local legitAutoState = false
local normalInstantState = false

local normalLoopThread
local blatantLoopThread

local normalEquipThread
local blatantEquipThread
local legitEquipThread
local legitClickThread

local SPEED_LEGIT = 0.05
local normalCompleteDelay = 1.50

local isTeleportFreezeActive = false
local selectedArea = nil
local savedPosition = nil

-- ================= HELPERS =================
function FishingAPI:GetHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 5)
end

function FishingAPI:TeleportToLookAt(position, lookVector)
    local hrp = self:GetHRP()
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

local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod")
local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted")
local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState")

-- ================= LEGIT AUTO FISH =================
local FishingController = require(RepStorage.Controllers.FishingController)

local AutoFishState = { Active = false, Minigame = false }

local function performClick()
    FishingController:RequestFishingMinigameClick()
    task.wait(SPEED_LEGIT)
end

local originalRodStarted = FishingController.FishingRodStarted
FishingController.FishingRodStarted = function(self, ...)
    originalRodStarted(self, ...)
    if AutoFishState.Active and not AutoFishState.Minigame then
        AutoFishState.Minigame = true
        if legitClickThread then task.cancel(legitClickThread) end
        legitClickThread = task.spawn(function()
            while AutoFishState.Active and AutoFishState.Minigame do
                performClick()
            end
        end)
    end
end

local originalFishingStopped = FishingController.FishingStopped
FishingController.FishingStopped = function(self, ...)
    originalFishingStopped(self, ...)
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
        RF_UpdateAutoFishingState:InvokeServer(true)
        if legitEquipThread then task.cancel(legitEquipThread) end
        legitEquipThread = task.spawn(function()
            while legitAutoState do
                RE_EquipToolFromHotbar:FireServer(1)
                task.wait(0.1)
            end
        end)
    else
        if legitClickThread then task.cancel(legitClickThread) end
        if legitEquipThread then task.cancel(legitEquipThread) end
    end
end

-- ================= NORMAL INSTANT =================
local function runNormalInstant()
    RF_ChargeFishingRod:InvokeServer(os.clock())
    RF_RequestFishingMinigameStarted:InvokeServer(-139.63, 0.996)
    task.wait(normalCompleteDelay)
    RE_FishingCompleted:FireServer()
    RF_CancelFishingInputs:InvokeServer()
end

function FishingAPI:SetNormalDelay(v)
    v = tonumber(v)
    if v then normalCompleteDelay = v end
end

function FishingAPI:SetNormal(state)
    normalInstantState = state

    if state then
        normalLoopThread = task.spawn(function()
            while normalInstantState do
                runNormalInstant()
                task.wait(0.1)
            end
        end)

        normalEquipThread = task.spawn(function()
            while normalInstantState do
                RE_EquipToolFromHotbar:FireServer(1)
                task.wait(0.1)
            end
        end)
    else
        if normalLoopThread then task.cancel(normalLoopThread) end
        if normalEquipThread then task.cancel(normalEquipThread) end
    end
end

-- ================= BLATANT MODE =================
local RS = RepStorage
local Net = RS.Packages._Index["sleitnick_net@0.2.0"].net
local FC = FishingController

local RF_Charge = Net["RF/ChargeFishingRod"]
local RF_Start = Net["RF/RequestFishingMinigameStarted"]
local RE_Complete = Net["RE/FishingCompleted"]
local RE_Equip = Net["RE/EquipToolFromHotbar"]
local RF_Cancel = Net["RF/CancelFishingInputs"]
local RF_Update = Net["RF/UpdateAutoFishingState"]

local originalClick = FC.RequestFishingMinigameClick
local originalCharge = FC.RequestChargeFishingRod

local Blatant = {
    Active = false,
    Mode = "Old",
    CancelDelay = 1.75,
    CompleteDelay = 1.33,
    AutoPerfect = false
}

local function EnsureServerReady()
    RF_Update:InvokeServer(true)
end

local function SyncAutoPerfect()
    local enable = Blatant.Active and Blatant.Mode == "New"
    if enable and not Blatant.AutoPerfect then
        Blatant.AutoPerfect = true
        FC.RequestFishingMinigameClick = function() end
        FC.RequestChargeFishingRod = function() end
    elseif not enable and Blatant.AutoPerfect then
        Blatant.AutoPerfect = false
        FC.RequestFishingMinigameClick = originalClick
        FC.RequestChargeFishingRod = originalCharge
    end
end

local function DoBlatantFish()
    EnsureServerReady()
    RE_Equip:FireServer(1)
    task.wait(0.15)
    RF_Charge:InvokeServer(math.huge)
    RF_Start:InvokeServer(-139.6379, 0.9964)

    task.delay(Blatant.CompleteDelay, function()
        if Blatant.Active then
            RE_Complete:FireServer()
        end
    end)
end

local function BlatantLoop()
    blatantEquipThread = task.spawn(function()
        while Blatant.Active do
            RE_Equip:FireServer(1)
            task.wait(0.1)
        end
    end)

    while Blatant.Active do
        DoBlatantFish()
        task.wait(Blatant.CancelDelay)
        RF_Cancel:InvokeServer()
    end
end

function FishingAPI:SetBlatant(state)
    Blatant.Active = state
    SyncAutoPerfect()

    if state then
        if blatantLoopThread then task.cancel(blatantLoopThread) end
        blatantLoopThread = task.spawn(BlatantLoop)
    else
        if blatantLoopThread then task.cancel(blatantLoopThread) end
        if blatantEquipThread then task.cancel(blatantEquipThread) end
        RF_Cancel:InvokeServer()
    end
end

function FishingAPI:SetBlatantMode(mode)
    Blatant.Mode = mode
    SyncAutoPerfect()
end

function FishingAPI:SetBlatantCancelDelay(v)
    v = tonumber(v)
    if v then Blatant.CancelDelay = v end
end

function FishingAPI:SetBlatantCompleteDelay(v)
    v = tonumber(v)
    if v then Blatant.CompleteDelay = v end
end

-- Blatant toggle
function FishingAPI:SetActive(state)
    self:SetBlatant(state)
end

-- Blatant mode dropdown
function FishingAPI:SetMode(mode)
    self:SetBlatantMode(mode)
end

-- Blatant cancel delay input
function FishingAPI:SetCancelDelay(v)
    self:SetBlatantCancelDelay(v)
end

-- Blatant complete delay input
function FishingAPI:SetCompleteDelay(v)
    self:SetBlatantCompleteDelay(v)
end

-- ================= AREA / SAVE / FREEZE =================
function FishingAPI:SetSelectedArea(area)
    selectedArea = area
end

function FishingAPI:SaveCurrentPosition()
    local hrp = self:GetHRP()
    savedPosition = { Pos = hrp.Position, Look = hrp.CFrame.LookVector }
    return savedPosition
end

function FishingAPI:GetSavedPosition()
    return savedPosition
end

function FishingAPI:SetTeleportFreeze(state, FishingAreas)
    isTeleportFreezeActive = state
    local hrp = self:GetHRP()
    if not hrp then return false end

    if not state then
        hrp.Anchored = false
        return true
    end

    local areaData =
        (selectedArea == "Custom: Saved" and savedPosition)
        or FishingAreas[selectedArea]

    if not areaData then return false end

    hrp.Anchored = false
    self:TeleportToLookAt(areaData.Pos, areaData.Look)

    local start = os.clock()
    while os.clock() - start < 1.5 and isTeleportFreezeActive do
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(areaData.Pos, areaData.Pos + areaData.Look) * CFrame.new(0,0.5,0)
        RunService.Heartbeat:Wait()
    end

    if isTeleportFreezeActive then hrp.Anchored = true end
    return true
end

function FishingAPI:TeleportToArea(FishingAreas)
    if not selectedArea then return false end
    local areaData =
        (selectedArea == "Custom: Saved" and savedPosition)
        or FishingAreas[selectedArea]

    if not areaData then return false end
    return self:TeleportToLookAt(areaData.Pos, areaData.Look)
end

return FishingAPI
