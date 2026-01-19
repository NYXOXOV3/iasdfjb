-- =========================================================
-- FISHING API (FULL, NO CUT, NO REWRITE)
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
local blatantInstantState = false

local normalLoopThread = nil
local blatantLoopThread = nil

local normalEquipThread = nil
local blatantEquipThread = nil
local legitEquipThread = nil
local legitClickThread = nil

local SPEED_LEGIT = 0.05
local normalCompleteDelay = 1.50

local isTeleportFreezeActive = false
local selectedArea = nil
local savedPosition = nil

-- ================= HELPERS =================
function FishingAPI:GetHRP()
    local Character = LocalPlayer.Character
    if not Character then
        Character = LocalPlayer.CharacterAdded:Wait()
    end
    return Character:WaitForChild("HumanoidRootPart", 5)
end

function FishingAPI:TeleportToLookAt(position, lookVector)
    local hrp = self:GetHRP()
    if not hrp then return false end

    local targetCFrame = CFrame.new(position, position + lookVector)
    hrp.CFrame = targetCFrame * CFrame.new(0, 0.5, 0)
    return true
end

-- ================= REMOTES =================
local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
local function GetRemote(path, name)
    local obj = RepStorage
    for _, p in ipairs(path) do
        obj = obj:WaitForChild(p)
    end
    return obj:WaitForChild(name)
end

local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod")
local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted")
local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState")

-- ================= LEGIT AUTO FISH =================
local FishingController = require(RepStorage:WaitForChild("Controllers").FishingController)
local AutoFishingController = require(RepStorage:WaitForChild("Controllers").AutoFishingController)

local AutoFishState = {
    IsActive = false,
    MinigameActive = false
}

local function performClick()
    FishingController:RequestFishingMinigameClick()
    task.wait(SPEED_LEGIT)
end

local originalRodStarted = FishingController.FishingRodStarted
FishingController.FishingRodStarted = function(self, a, b)
    originalRodStarted(self, a, b)

    if AutoFishState.IsActive and not AutoFishState.MinigameActive then
        AutoFishState.MinigameActive = true

        if legitClickThread then task.cancel(legitClickThread) end
        legitClickThread = task.spawn(function()
            while AutoFishState.IsActive and AutoFishState.MinigameActive do
                performClick()
            end
        end)
    end
end

local originalFishingStopped = FishingController.FishingStopped
FishingController.FishingStopped = function(self, arg)
    originalFishingStopped(self, arg)
    AutoFishState.MinigameActive = false
end

local function ensureServerAutoFishingOn()
    pcall(function()
        RF_UpdateAutoFishingState:InvokeServer(true)
    end)
end

function FishingAPI:SetLegitSpeed(v)
    local n = tonumber(v)
    if n and n >= 0.01 then SPEED_LEGIT = n end
end

function FishingAPI:SetLegit(state)
    legitAutoState = state
    AutoFishState.IsActive = state

    if state then
        RE_EquipToolFromHotbar:FireServer(1)
        ensureServerAutoFishingOn()

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
    if not normalInstantState then return end

    local timestamp = os.time() + os.clock()
    RF_ChargeFishingRod:InvokeServer(timestamp)
    RF_RequestFishingMinigameStarted:InvokeServer(-139.630452165, 0.99647927980797)

    task.wait(normalCompleteDelay)
    RE_FishingCompleted:FireServer()
    task.wait(0.3)
    RF_CancelFishingInputs:InvokeServer()
end

function FishingAPI:SetNormalDelay(v)
    local n = tonumber(v)
    if n then normalCompleteDelay = n end
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

local RF_Charge   = Net["RF/ChargeFishingRod"]
local RF_Start    = Net["RF/RequestFishingMinigameStarted"]
local RE_Complete = Net["RE/FishingCompleted"]
local RE_Equip    = Net["RE/EquipToolFromHotbar"]
local RF_Cancel   = Net["RF/CancelFishingInputs"]
local RF_Update   = Net["RF/UpdateAutoFishingState"]

local originalClick  = FC.RequestFishingMinigameClick
local originalCharge = FC.RequestChargeFishingRod

local BlatantConfig = {
    Active = false,
    Mode = "Old",
    CancelDelay = 1.75,
    CompleteDelay = 1.33,
    AutoPerfect = false
}

local function SyncAutoPerfect()
    if BlatantConfig.Active and BlatantConfig.Mode == "New" then
        FC.RequestFishingMinigameClick = function() end
        FC.RequestChargeFishingRod = function() end
        BlatantConfig.AutoPerfect = true
    else
        FC.RequestFishingMinigameClick = originalClick
        FC.RequestChargeFishingRod = originalCharge
        BlatantConfig.AutoPerfect = false
    end
end

function FishingAPI:SetBlatant(state)
    BlatantConfig.Active = state
    SyncAutoPerfect()

    if state then
        blatantLoopThread = task.spawn(function()
            while BlatantConfig.Active do
                RF_Cancel:InvokeServer()
                RF_Charge:InvokeServer(math.huge)
                RF_Start:InvokeServer(-139.6379699707, 0.99647927980797)
                task.wait(BlatantConfig.CompleteDelay)
                RE_Complete:FireServer()
                task.wait(BlatantConfig.CancelDelay)
            end
        end)
    else
        if blatantLoopThread then task.cancel(blatantLoopThread) end
        pcall(function() RF_Cancel:InvokeServer() end)
    end
end

function FishingAPI:SetBlatantMode(m)
    BlatantConfig.Mode = m
    SyncAutoPerfect()
end

function FishingAPI:SetBlatantDelays(cancel, complete)
    if cancel then BlatantConfig.CancelDelay = cancel end
    if complete then BlatantConfig.CompleteDelay = complete end
end

-- ================= AREA / SAVE / FREEZE =================
function FishingAPI:SetSelectedArea(area)
    selectedArea = area
end

function FishingAPI:SaveCurrentPosition()
    local hrp = self:GetHRP()
    savedPosition = {
        Pos = hrp.Position,
        Look = hrp.CFrame.LookVector
    }
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

    local startTime = os.clock()
    while (os.clock() - startTime) < 1.5 and isTeleportFreezeActive do
        hrp.Velocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame =
            CFrame.new(areaData.Pos, areaData.Pos + areaData.Look)
            * CFrame.new(0, 0.5, 0)

        RunService.Heartbeat:Wait()
    end

    if isTeleportFreezeActive then
        hrp.Anchored = true
    end

    return true
end

function FishingAPI:TeleportToArea(FishingAreas)
    if not selectedArea then return false end

    local areaData =
        (selectedArea == "Custom: Saved" and savedPosition)
        or FishingAreas[selectedArea]

    if not areaData then return false end

    if isTeleportFreezeActive then
        isTeleportFreezeActive = false
        task.wait(0.1)
    end

    return self:TeleportToLookAt(areaData.Pos, areaData.Look)
end

return FishingAPI
