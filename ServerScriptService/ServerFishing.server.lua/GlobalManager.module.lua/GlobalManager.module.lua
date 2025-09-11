-- GlobalManager.module.lua

local GlobalManager = {}

local PlayerData = {} -- {player = {bobber, beam, bobberTween}}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local fishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local RunService = game:GetService("RunService")

local CatchTweenFinishEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FishingEvents"):WaitForChild("CatchTweenFinish")

local InventoryModule = require(script.PlayerInventory)
local InventoryModules = {}

-- HELPER FUNCTIONS
function GlobalManager:createFishAnimation(fishName, weight, position)
    --[[
        TODO: add weight scaling
    ]]--
    local fish = ReplicatedStorage:WaitForChild("Template"):WaitForChild("Fish"):FindFirstChild(fishName)
    if not fish then
        fish = ReplicatedStorage:WaitForChild("Template"):WaitForChild("Fish"):FindFirstChild("TestFish")
    end
    fish = fish:Clone()
    fish.Parent = workspace
    fish:SetPrimaryPartCFrame(CFrame.new(position))
    local struggleTween = TweenService:Create(
        fish.Body,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Rotation = fish.Body.Rotation + Vector3.new(0, 0, 15)}
    )
    struggleTween:Play()
    local jumpTween = TweenService:Create(
        fish.Body,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
        {Position = position + Vector3.new(0, 0.5, 0)}
    )
    jumpTween:Play()
    return fish, struggleTween, jumpTween
end
function GlobalManager:createFishSlungTween(player, fish)
    local rootPart = player.Character.HumanoidRootPart
	local behindPlayer = rootPart.Position - (rootPart.CFrame.LookVector * 2)

	local origin = behindPlayer + Vector3.new(0, 10, 0)
	local direction = Vector3.new(0, -20, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {fish}
	local raycastResult = workspace:Raycast(origin, direction, params)
	local groundPosition = raycastResult and raycastResult.Position or behindPlayer

	fish.Body.Anchored = true
	fish.Body.CanCollide = false

	local slungTween = TweenService:Create(
		fish.Body,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = groundPosition}
	)
	slungTween:Play()

	local bounceTween = TweenService:Create(
		fish.Body,
		TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, -1, true),
		{Position = groundPosition + Vector3.new(0, 0.3, 0)}
	)
	local rotateTween = TweenService:Create(
		fish.Body,
		TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Rotation = fish.Body.Rotation + Vector3.new(0, 15, 0)}
	)
	local fadeTween = TweenService:Create(
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

-- GLOBAL SURFACE UI
function GlobalManager:showPowerCategoryUI(player, power)
    InventoryModules[player]:showPowerCategoryUI(power)
end
function GlobalManager:showBitUI(player, visible)
    InventoryModules[player]:showBitUI(visible)
end


-- GLOBAL INSTANCES
function GlobalManager:cleanBobber(player)
    if PlayerData[player].bobConn then PlayerData[player].bobConn:Disconnect() PlayerData[player].bobConn = nil end
    if PlayerData[player].bobberTween then PlayerData[player].bobberTween:Cancel() PlayerData[player].bobberTween = nil end
    if PlayerData[player].bobber then PlayerData[player].bobber:Destroy() PlayerData[player].bobber = nil end
    if PlayerData[player].beam then PlayerData[player].beam:Destroy() PlayerData[player].beam = nil end
end
function GlobalManager:createBobber(player, params)
    local finalPos = params[1]
    local fishingRod = params[2]
    
    local RodTip = fishingRod:WaitForChild("Rod"):WaitForChild("RodTip")
    local Handle = fishingRod:WaitForChild("Handle")
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
	local tween = TweenService:Create(
        bobber, 
        TweenInfo.new(
            0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out
        ), 
        {Position = finalPos})
	tween:Play()
	tween.Completed:Wait()

	local t0 = tick()
	local bobberY = finalPos.Y
	bobberTween = TweenService:Create(
        bobber, 
        TweenInfo.new(
            fishingConfig.Gameplay.BOBBER_ANIMATION_SPEED, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), 
            {Position = Vector3.new(finalPos.X, bobberY + fishingConfig.Gameplay.BOBBER_FLOAT_HEIGHT, finalPos.Z)
	})
	bobberTween:Play()

	bobConn = RunService.Heartbeat:Connect(function()
		if not bobber or not bobberTween then return end
		local currentPos = bobber.Position
		bobber.Position = Vector3.new(currentPos.X, bobberY + math.sin((tick() - t0) * 2) * fishingConfig.Gameplay.BOBBER_FLOAT_HEIGHT, currentPos.Z)
	end)
    PlayerData[player].bobber = bobber
    PlayerData[player].bobberTween = bobberTween
    PlayerData[player].bobConn = bobConn
    
	beam = Instance.new("Beam")
	beam.Attachment0 = RodTip
	beam.Attachment1 = att
	beam.Width0 = 0.03
	beam.Width1 = 0.03
	beam.FaceCamera = true
	beam.Parent = Handle
    
    PlayerData[player].beam = beam
end


-- GLOBAL SOUND
function GlobalManager:cleanSounds(player)
    print("cleanSounds", player.Name)
end
function GlobalManager:playSound(player, sound)
    print("playSound", player.Name, sound)
end


-- GLOBAL EVENTS
function GlobalManager:catchResultSuccess(player, params)
    local info = params[1]
    local fishingRod = params[2]

    local target = fishingRod:WaitForChild("Rod"):WaitForChild("RodTip").WorldPosition
    local tween = TweenService:Create( -- roll bobber from water to tip
        PlayerData[player].bobber,
        TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
        {Position = target}
    )
    tween:Play()
    local fish, struggleTween, jumpTween = self:createFishAnimation(info.fishName, info.weight, PlayerData[player].bobber.Position)
    local fishFollowConnection = RunService.Heartbeat:Connect(function()
        if fish and PlayerData[player].bobber then
            fish:SetPrimaryPartCFrame(CFrame.new(PlayerData[player].bobber.Position))
            jumpTween:Cancel()
            jumpTween = TweenService:Create(
                fish.Body,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
                {Position = PlayerData[player].bobber.Position + Vector3.new(0, 0.5, 0)}
            )
            jumpTween:Play()
        end
    end)
    tween.Completed:Wait()
    struggleTween:Cancel()
    jumpTween:Cancel()
    fishFollowConnection:Disconnect()
    self:createFishSlungTween(player, fish)

    -- todo add inv here

    --

    self:cleanBobber(player)
    CatchTweenFinishEvent:FireClient(player)
end
function GlobalManager:toggleRod(player)
    InventoryModules[player]:toggleRod()
end
function GlobalManager:toggleInventory(player)
    InventoryModules[player]:toggleInventory()
end
function GlobalManager:setUnequippedReady(player, bool)
    InventoryModules[player]:setUnequippedReady(bool)
end

-- CONNECT EVENTS
function GlobalManager:playerAdded(player)
    if PlayerData[player] == nil then
        PlayerData[player] = {
            bobber = nil,
            beam = nil,
            bobberTween = nil,
            bobConn = nil
        }
    end
    if InventoryModules[player] == nil then
        InventoryModules[player] = InventoryModule:new(player)
    end
end
function GlobalManager:playerRemoved(player)
    if PlayerData[player] then
        self:cleanBobber(player)
        PlayerData[player] = nil
    end
    if InventoryModules[player] then
        InventoryModules[player]:cleanUp()
        InventoryModules[player] = nil
    end
end

return GlobalManager