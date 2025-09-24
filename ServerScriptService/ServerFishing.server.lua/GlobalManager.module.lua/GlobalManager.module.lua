-- GlobalManager.module.lua

local GM = {}
local GSM = require(script.Parent.GlobalStorage)
local PM = require(script.PlayerManager)
local PlayerManagers = {}

local TS:TweenService = game:GetService("TweenService")
local RS:ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local FTEMPLATE = RS:WaitForChild("Template"):WaitForChild("Fish")

local CatchTweenFinishEvent = RS:WaitForChild("Remotes"):WaitForChild("FishingEvents"):WaitForChild("CatchTweenFinish")

local c = require(RS:WaitForChild("GlobalConfig"))

-- HELPER
-- === zone ====
function GM:_isStillInside(player:Player, zone: Part)
    if player and zone then
        local localPos = zone.CFrame:PointToObjectSpace(player.Character.HumanoidRootPart.Position)
        local insideHeight = math.abs(localPos.X) <= (zone.Size.X / 2)
        local insideEllipse = (
            ((localPos.Y ^ 2) / ((zone.Size.Y / 2) ^ 2)) +
            ((localPos.Z ^ 2) / ((zone.Size.Z / 2) ^ 2))
        ) <= 1
        return insideHeight and insideEllipse
    else
        return false
    end
end
-- === fishing ===
function GM:_ScaleWeight(w)
    local ratio = w / 50 -- base weight is 50kg
    local factor = ratio^(1/3)
    return 1 * factor
end
function GM:_CreateFishAnimation(fishName, weight, pos)
    local fish = FTEMPLATE:FindFirstChild(fishName)
    if not fish then fish = FTEMPLATE:FindFirstChild("TestFish") end
    fish = fish:Clone()
    fish.Body.Anchored = true
	fish.Body.CanCollide = false
    fish:ScaleTo(self:_ScaleWeight(weight))
    fish.Parent = workspace
    fish:SetPrimaryPartCFrame(CFrame.new(pos))
    local struggleTween = TS:Create(
        fish.Body,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Rotation = fish.Body.Rotation + Vector3.new(0, 0, 15)}
    )
    struggleTween:Play()
    local jumpTween = TS:Create(
        fish.Body,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
        {Position = pos + Vector3.new(0, 0.5, 0)}
    )
    jumpTween:Play()
    return fish, struggleTween, jumpTween
end
function GM:_CreateFishSlungTween(player:Player, fish)
    local rootPart = player.Character.HumanoidRootPart
	local behindPlayer = rootPart.Position - (rootPart.CFrame.LookVector * 2)

	local origin = behindPlayer + Vector3.new(0, 10, 0)
	local direction = Vector3.new(0, -20, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {fish}
	local raycastResult = workspace:Raycast(origin, direction, params)
	local groundPosition = raycastResult and raycastResult.Position or behindPlayer

	local slungTween = TS:Create(
		fish.Body,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = groundPosition}
	)
	slungTween:Play()

	local bounceTween = TS:Create(
		fish.Body,
		TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, -1, true),
		{Position = groundPosition + Vector3.new(0, 0.3, 0)}
	)
	local rotateTween = TS:Create(
		fish.Body,
		TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Rotation = fish.Body.Rotation + Vector3.new(0, 15, 0)}
	)
	local fadeTween = TS:Create(
		fish.Body,
		TweenInfo.new(2.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Transparency = 1}
	)
	task.spawn(function()
		slungTween.Completed:Connect(function()
			bounceTween:Play()
			rotateTween:Play()
			task.wait(1.5)
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				fish:Destroy()
			end)
		end)
	end)
end
function GM:CleanBobber(player)
    if self.PlayerData[player].bobConn then 
        self.PlayerData[player].bobConn:Disconnect() 
        self.PlayerData[player].bobConn = nil 
    end
    if self.PlayerData[player].bobberTween then 
        self.PlayerData[player].bobberTween:Cancel() 
        self.PlayerData[player].bobberTween = nil 
    end
    if self.PlayerData[player].beam then 
        self.PlayerData[player].beam:Destroy() 
        self.PlayerData[player].beam = nil 
    end
    if self.PlayerData[player].bobber then 
        self.PlayerData[player].bobber:Destroy() 
        self.PlayerData[player].bobber = nil 
    end
end
function GM:CreateBobber(player, params)
    local finalPos = params[1]
    local ROD = params[2]
    
    local RodTip = ROD:WaitForChild("Rod"):WaitForChild("RodTip")
    local Handle = ROD:WaitForChild("Handle")
    local bobber, beam, bobberTween, bobConn
    bobber = Instance.new("Part")
	bobber.Name = "Bobber"
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.new(0.35, 0.35, 0.35)
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.Position = RodTip.WorldPosition
	bobber.Parent = workspace
	local att = Instance.new("Attachment")
	att.Parent = bobber

    -- tween
	local tween = TS:Create(
        bobber,
        TweenInfo.new(
            0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out
        ),
        {Position = finalPos})
    table.insert(self.PlayerData[player].CleanableTweens, tween)
	tween:Play()
	tween.Completed:Connect(function()
        local t0 = tick()
        local bobberY = finalPos.Y
        bobberTween = TS:Create(
            bobber,
            TweenInfo.new(
                c.FISHING.BOBBER_ANIMATION_SPEED, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), 
                {Position = Vector3.new(finalPos.X, bobberY + c.FISHING.BOBBER_FLOAT_HEIGHT, finalPos.Z)
        })
        bobberTween:Play()

        bobConn = RunService.Heartbeat:Connect(function()
            if not bobber or not bobberTween then return end
            local currentPos = bobber.Position
            bobber.Position = Vector3.new(currentPos.X, bobberY + math.sin((tick() - t0) * 2) * c.FISHING.BOBBER_FLOAT_HEIGHT, currentPos.Z)
        end)
        self.PlayerData[player].bobber = bobber
        self.PlayerData[player].bobberTween = bobberTween
        self.PlayerData[player].bobConn = bobConn
        
        beam = Instance.new("Beam")
        beam.Attachment0 = RodTip
        beam.Attachment1 = att
        beam.Width0 = 0.03
        beam.Width1 = 0.03
        beam.FaceCamera = true
        beam.Parent = Handle
        
        self.PlayerData[player].beam = beam
    end)
end

-- PLAYER MANAGER (PM) CONNECTION
-- === zone ===
function GM:_onUpdatePlayerZones(player:Player, zoneName:string)
    while self.PlayerManagers[player] == nil do
        task.wait(0.5)
    end
    self.PlayerManagers[player]:updatePlayerZone(zoneName)
end


-- PLAYER SETUP FUNCTIONS
-- === zone ===
function GM:_setupPlayerZones(player)
    if self.PlayerZones[player] == nil then
        self.PlayerZones[player] = {
            currentZone = nil
        }
    end
end
-- === manager ===
function GM:_setupPlayerManager(player)
    if self.PlayerManagers[player] == nil then
        self.PlayerManagers[player] = PM:new(player)
    end
end


-- STATIC METHOD
function GM:PlaySound(player, sound:Sound, cleanable:boolean, looped:boolean)
    if cleanable then
        table.insert(self.PlayerData[player].CleanableSounds, sound)
    end
    sound:Play()
    if cleanable then
        if not looped then
            sound.Ended:Connect(function()
                for i,strack in ipairs(self.PlayerData[player].CleanableSounds) do
                    if sound == strack then
                        table.remove(self.PlayerData[player].CleanableSounds, i)
                        break
                    end
                end
            end)
        end
    end
end
function GM:CleanSounds(player)
    for i,sound in ipairs(self.PlayerData[player].CleanableSounds) do
        sound:Stop()
        table.remove(self.PlayerData[player].CleanableSounds, i)
    end
end


-- CLEANUP
function GM:CleanUp(player:Player)
    self:CleanBobber(player)
    self:CleanSounds(player)
end


-- ENTRY POINTS
-- === interaction ===
-- PROXOMITY
function GM:ToggleFishShopUI(player, ...)
    self.PlayerManagers[player]:ToggleFishShopUI(...)
end
-- ToolEvent
function GM:ToggleInventory(player)
   self.PlayerManagers[player]:ToggleInventory()
end
function GM:ToggleRod(player)
   self.PlayerManagers[player]:ToggleRod()
end
function GM:UnEquippedReady(player, bool)
    self.PlayerManagers[player]:UnEquippedReady(bool)
end
function GM:TogglePlayerModal(player)
    self.PlayerManagers[player]:TogglePlayerModal()
end
-- FishingEvent
function GM:PlayFishingSound(player, sound, tool, cleanable, looped)
    local strack = tool:WaitForChild("Sounds"):FindFirstChild(sound)
    self:PlaySound(player, strack, cleanable or true, looped or false)
end
function GM:CleanFishingSounds(player)
    self:CleanSounds(player)
end

function GM:CatchResultSuccess(player:Player, success, ROD, info)
    local target = ROD:FindFirstChild("Rod"):FindFirstChild("RodTip").WorldPosition
    local tween = TS:Create( -- roll bobber from water to tip
        self.PlayerData[player].bobber,
        TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
        {Position = target}
    )
    tween:Play()
    local fish, struggleTween, jumpTween
    local FFConnection
    if success then
        fish, struggleTween, jumpTween = self:_CreateFishAnimation(info.fishName, info.weight, self.PlayerData[player].bobber.Position)
        FFConnection = RunService.Heartbeat:Connect(function()
            if fish and self.PlayerData[player].bobber then
                fish:SetPrimaryPartCFrame(CFrame.new(self.PlayerData[player].bobber.Position))
                jumpTween:Cancel()
                jumpTween = TS:Create(
                    fish.Body,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
                    {Position = self.PlayerData[player].bobber.Position + Vector3.new(0, 0.5, 0)}
                )
                jumpTween:Play()
            end
        end)
    end
    tween.Completed:Connect(function()
        if struggleTween then struggleTween:Cancel() end
        if jumpTween then jumpTween:Cancel() end
        if FFConnection then FFConnection:Disconnect() end
        if success then
            self:_CreateFishSlungTween(player, fish)
            self.PlayerManagers[player]:CatchResultSuccess(info)
        end
        
        self:CleanBobber(player)
        CatchTweenFinishEvent:FireClient(player)
    end)
end
function GM:ShowFishBiteUI(player, visible)
    self.PlayerManagers[player]:ShowFishBiteUI(visible)
end
function GM:ShowPowerCategoryUI(player, power)
    self.PlayerManagers[player]:ShowPowerCategoryUI(power)
end
-- === zone ===
function GM:playerEnteredZone(player:Player, zone: Part)
    if not self.PlayerZones[player] then self:_setupPlayerZones(player) end
    local pz = self.PlayerZones[player]
    if pz and pz.currentZone == zone.Name then return end
    pz.currentZone = zone.Name
    self.PlayerZones[player].currentZone = pz.currentZone
    self:_onUpdatePlayerZones(player, pz.currentZone)
end
function GM:playerExitedZone(player:Player, zone: Part)
    if not self.PlayerZones[player] then self:_setupPlayerZones(player) end
    local pz = self.PlayerZones[player]
    if pz and pz.currentZone ~= zone.Name then return end
    if self:_isStillInside(player, zone) then return end
    pz.currentZone = "Ocean"
    self.PlayerZones[player].currentZone = pz.currentZone
    self:_onUpdatePlayerZones(player, pz.currentZone)
end
-- === player ===
function GM:playerAdded(player:Player)
    if not self.PlayerZones[player] then self:_setupPlayerZones(player) end
    if not self.PlayerManagers[player] then self:_setupPlayerManager(player) end
    GSM:LoadDataPlayer(player)
    if self.PlayerData[player] == nil then
        self.PlayerData[player] = {
            bobber = nil,
            beam = nil,
            bobberTween = nil,
            bobConn = nil,
            CleanableTweens = {},
            CleanableSounds = {}
        }
    end
end
function GM:playerRemoved(player:Player)
    if self.PlayerData[player] then
        self:CleanUp(player)
        self.PlayerData[player] = nil
    end
    if self.PlayerManagers[player] then
        self.PlayerManagers[player]:CleanUp()
        self.PlayerManagers[player] = nil
    end
end


GM.ALLOWED_METHOD = {
    "ToggleRod",
    "ToggleInventory",
    "TogglePlayerModal",

    "UnEquippedReady",

    "PlayFishingSound",
    "CatchResultSuccess",
    "ShowFishBiteUI",
    "CleanFishingSounds",
    "CleanBobber",
    "CreateBobber",
    "ShowPowerCategoryUI"
}
GM.PlayerZones = {}
GM.PlayerManagers = {}
GM.PlayerData = {}
function GM:SetupServer()
    -- self.CleanableSounds = {}
end

-- EXIT POINT
function GM:onShutdown(player)
    if self.PlayerManagers[player] then
        self.PlayerManagers[player]:saveData(false, true)
    end
end


-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:WrapModule(GM, "GlobalManager")


return GM