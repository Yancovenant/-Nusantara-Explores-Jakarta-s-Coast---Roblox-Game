-- FishingRodClient.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishingRod = script.Parent
local Handle = FishingRod:WaitForChild("Handle")
local Rod = FishingRod:WaitForChild("Rod")
local RodTip = Rod:WaitForChild("RodTip")
local player = Players.LocalPlayer

local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local UIManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"):WaitForChild("UIManager"))
local ItemManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Item"):WaitForChild("ItemManager"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartCast = Remotes:WaitForChild("StartCast")
local CastApproved = Remotes:WaitForChild("CastApproved")
local BiteEvent = Remotes:WaitForChild("Bite")
local ReelComplete = Remotes:WaitForChild("ReelComplete")
local CatchResult = Remotes:WaitForChild("CatchResult")

local STARTCAST_ANIMATION_ID = "rbxassetid://105792660360866"
local RELEASECAST_ANIMATION_ID = "rbxassetid://130182011557705"
local IDLE_FISHING_ANIMATION_ID = "rbxassetid://107195172508437"
local REELING_ANIMATION_ID = "rbxassetid://99021540387411"
local CATCH_ANIMATION_ID = "rbxassetid://83953995969192"

local ORIGINAL_WALK_SPEED = 16
local FISHING_WALK_SPEED = 8

local function setAttr(key, value)
	player.Character:SetAttribute(key, value)
end
local function getAttr(key)
	return player.Character:GetAttribute(key)
end
local function isFishing()
	return getAttr("isFishing")
end
local function isCasting()
	return getAttr("isCasting")
end
local function canFish()
	return getAttr("canFish")
end

local fishingManager = {}

local power = 0
local bobber, bobConn, beam, bobberTween
local isAFK = false
local afkConnection = nil
local splashSound = script.Parent.Splash
local reelSound = script.Parent.Reel
local startCastSound = script.Parent.StartCast
local releaseCastSound = script.Parent.ReleaseCast
local chimeSound = script.Parent.Chime
local errorSound = script.Parent.Error

function fishingManager:setFishingWalkSpeed(enabled)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end
	if enabled then
		humanoid.WalkSpeed = FISHING_WALK_SPEED
	else
		humanoid.WalkSpeed = ORIGINAL_WALK_SPEED
	end
end
function fishingManager:loadAnimation(animID)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = animID
	local success, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not success or not track then return end
	track.Priority = Enum.AnimationPriority.Action
	return track
end
function fishingManager:cleanAnimations()
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	local tracks = animator:GetPlayingAnimationTracks()
	for _, track in tracks do
		for _, id in {
			STARTCAST_ANIMATION_ID,
			RELEASECAST_ANIMATION_ID,
			IDLE_FISHING_ANIMATION_ID,
			REELING_ANIMATION_ID,
			CATCH_ANIMATION_ID
			} do
			if track.Animation.AnimationId == id then
				track:Stop()
				break
			end
		end
	end
end
function fishingManager:releaseCast()
	if isFishing() or not canFish() then return end
	if not isCasting() then return end
	setAttr("isCasting", false)
	UIManager:showPowerCategoryUI(player, power)
	local releaseCastTrack = self:loadAnimation(RELEASECAST_ANIMATION_ID)
	releaseCastTrack.Looped = false
	releaseCastTrack:Play()
	local connection
	connection = releaseCastTrack:GetMarkerReachedSignal("ReleasePoint"):Connect(function(keyframe)
		connection:Disconnect()
		releaseCastSound:Play()
		local char = player.Character
		local rootPart = char:FindFirstChild("HumanoidRootPart")
		local charCFrame = rootPart.CFrame
		local forwardDirection = charCFrame.LookVector
		local target = rootPart.Position + (forwardDirection * (power * FishingConfig.Gameplay.BASE_RANGE))
		self:fishing(target)
	end)
end
function fishingManager:startCast(afkpower)
	if isFishing() or isCasting() or not canFish() then return end
	setAttr("isCasting", true)
	self:setFishingWalkSpeed(true)
	-- startCastSound:Play()
	power = afkpower or 0
	local direction = 1
	local startCastTrack = self:loadAnimation(STARTCAST_ANIMATION_ID)
	startCastTrack:Play()
	startCastTrack:AdjustSpeed(0) -- Stop automatic progression
	local animationProgress = 0

	while isCasting() do
		local dt = task.wait(0.03)
		local step = (dt / FishingConfig.Gameplay.CHARGE_TIME)
		power = math.clamp(power + (step * direction), 0, 1)
		if power >= 1 then
			direction = -1
		elseif power <= 0 then
			direction = 1
		end

		animationProgress = math.clamp(animationProgress + step, 0, 1)
		local percentage = math.clamp(animationProgress * 100, 0, 99.99)
		local targetTime = (percentage / 100) * startCastTrack.Length
		startCastTrack.TimePosition = targetTime

		UIManager:setVisible(player, "powerBar", true)
		UIManager:updateAttr(player, "power", power, "powerBar")
		if isAFK and not isFishing() then
			self:releaseCast()
			setAttr("isCasting", false)
		end
	end
	startCastTrack:AdjustSpeed(1)
	-- startCastTrack.TimePosition = (99.99/100) * startCastTrack.Length
	-- startCastTrack:Play()
	UIManager:setVisible(player, "powerBar", false)
end
function fishingManager:fishing(target)
	if isFishing() or not canFish() then return end
	setAttr("isFishing", true)
	-- TODO: finished animation, then send to server
	self:cleanBobber()
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

	beam = Instance.new("Beam")
	beam.Attachment0 = RodTip
	beam.Attachment1 = att
	beam.Width0 = 0.03
	beam.Width1 = 0.03
	beam.FaceCamera = true
	beam.Parent = Handle

	local sanitizePower = math.clamp(tonumber(power) or 0, 0, 1)
	local minRangePercent = 0.45
	local minRange = FishingConfig.Gameplay.BASE_RANGE * minRangePercent
	local powerRange = FishingConfig.Gameplay.BASE_RANGE * (0.5 + sanitizePower)
	local allowedRange = math.max(minRange, powerRange)

	local rootPos = player.Character.HumanoidRootPart.Position
	local dir = (target - rootPos)
	local distance = dir.Magnitude
	local finalPos
	if distance < minRange then
		finalPos = rootPos + (dir.Unit * minRange)
	else
		finalPos = distance > allowedRange
			and rootPos + (dir.Unit * allowedRange)
			or target
	end
	local origin = finalPos + Vector3.new(0, 20, 0)
	local direction = Vector3.new(0, -60, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {}
	local r = workspace:Raycast(origin, direction, params)
	local rInstance = r.Instance
	local isWater = function()
		return r.Material == Enum.Material.Water or CollectionService:HasTag(rInstance, "Water")
	end
	finalPos = r.Position

	local tween = TweenService:Create(bobber, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = finalPos})
	tween:Play()
	tween.Completed:Wait()

	local t0 = tick()
	local bobberY = finalPos.Y
	bobberTween = TweenService:Create(bobber, TweenInfo.new(FishingConfig.Gameplay.BOBBER_ANIMATION_SPEED, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = Vector3.new(finalPos.X, bobberY + FishingConfig.Gameplay.BOBBER_FLOAT_HEIGHT, finalPos.Z)
	})
	bobberTween:Play()

	bobConn = RunService.Heartbeat:Connect(function()
		if not bobber or not bobberTween then return end
		local currentPos = bobber.Position
		bobber.Position = Vector3.new(currentPos.X, bobberY + math.sin((tick() - t0) * 2) * FishingConfig.Gameplay.BOBBER_FLOAT_HEIGHT, currentPos.Z)
	end)

	local idleFishingAnimation = self:loadAnimation(IDLE_FISHING_ANIMATION_ID)
	idleFishingAnimation:Play()
	idleFishingAnimation:AdjustSpeed(1)
	-- SHOULD BE FINISHED ANIMATION. + boobber throwing animation.
	StartCast:FireServer(finalPos, isWater(), power)
end
function fishingManager:cleanUp()
	setAttr("isCasting", false)
	setAttr("isFishing", false)
	self:stopAfk()
	power = 0
	self:cleanBobber()
	self:cleanAnimations()
	self:setFishingWalkSpeed(false)
	UIManager:showBitUI(player, false)
end
function fishingManager:cleanBobber()
	if bobConn then bobConn:Disconnect() bobConn = nil end
	if bobberTween then bobberTween:Cancel() bobberTween = nil end
	if beam then beam:Destroy() beam = nil end
	if bobber then bobber:Destroy() bobber = nil end
end
function fishingManager:startAfk()
	if isAFK or isFishing() or not canFish() then return end
	isAFK = true
	local afkLoop = function()
		while isAFK and canFish() do
			local afkpower = 0.5 + (math.random() * 0.5)
			self:startCast(afkpower)
			while isFishing() and isAFK do
				task.wait(0.1)
			end
			if isAFK then
				task.wait(1.0 + (math.random() * 1.0))
			end
		end
	end
	UIManager:updateAttr(
		player,
		"background",
		Color3.fromRGB(50, 150, 50),
		"autoFishButton"
	)
	afkConnection = task.spawn(afkLoop)
end
function fishingManager:stopAfk()
	isAFK = false
	if afkConnection then
		task.cancel(afkConnection)
		afkConnection = nil
	end
	UIManager:updateAttr(
		player,
		"background",
		Color3.fromRGB(150, 50, 50),
		"autoFishButton"
	)
end
function fishingManager:toggleAfk()
	if isAFK then
		self:stopAfk()
	else
		self:startAfk()
	end
end

function fishingManager:onUnequipped()
	self:cleanUp()
	setAttr("canFish", false)
	UIManager:setVisible(player, "autoFishButton", false)
end
function fishingManager:onEquipped()
	self:cleanUp()
	setAttr("canFish", true)
	local ui = UIManager:createFishingUI(player)
	if ui then
		UIManager:setVisible(player, "autoFishButton", true)
		ui.autoFishButton.MouseButton1Click:Connect(function()
			self:toggleAfk()
		end)
	end
	local mouseClick = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:startCast()
		end
	end)
	local mouseUp = UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:releaseCast()
		end
	end)
end


-- function fishingManager:createFishAnimation(fishType, rarity, position)
-- 	local fish = ReplicatedStorage:WaitForChild("Template"):WaitForChild("Fish"):FindFirstChild(fishType)
-- 	if not fish then
-- 		fish = ReplicatedStorage:WaitForChild("Template"):WaitForChild("Fish"):WaitForChild("TestFish")
-- 	end
-- 	fish = fish:Clone()
-- 	fish.Parent = workspace
-- 	fish:SetPrimaryPartCFrame(CFrame.new(position))
-- 	local tween = TweenService:Create(
-- 		fish.Body,
-- 		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
-- 		{Rotation = fish.Body.Rotation + Vector3.new(0, 0, 15)}
-- 	)
-- 	tween:Play()
-- 	local jumpTween = TweenService:Create(
-- 		fish.Body,
-- 		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
-- 		{Position = position + Vector3.new(0, 0.5, 0)}
-- 	)
-- 	jumpTween:Play()
-- 	return fish, tween, jumpTween
-- end
-- function fishingManager:createFishSlungAnimation(fish)
-- 	local rootPart = player.Character.HumanoidRootPart
-- 	local behindPlayer = rootPart.Position - (rootPart.CFrame.LookVector * 2)

-- 	local origin = behindPlayer + Vector3.new(0, 10, 0)
-- 	local direction = Vector3.new(0, -20, 0)
-- 	local params = RaycastParams.new()
-- 	params.FilterType = Enum.RaycastFilterType.Exclude
-- 	params.FilterDescendantsInstances = {fish}
-- 	local raycastResult = workspace:Raycast(origin, direction, params)
-- 	local groundPosition = raycastResult and raycastResult.Position or behindPlayer

-- 	fish.Body.Anchored = true
-- 	fish.Body.CanCollide = false

-- 	local slungTween = TweenService:Create(
-- 		fish.Body,
-- 		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
-- 		{Position = groundPosition}
-- 	)
-- 	slungTween:Play()

-- 	local bounceTween = TweenService:Create(
-- 		fish.Body,
-- 		TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, -1, true),
-- 		{Position = groundPosition + Vector3.new(0, 0.3, 0)}
-- 	)
-- 	local rotateTween = TweenService:Create(
-- 		fish.Body,
-- 		TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
-- 		{Rotation = fish.Body.Rotation + Vector3.new(0, 15, 0)}
-- 	)
-- 	local fadeTween = TweenService:Create(
-- 		fish.Body,
-- 		TweenInfo.new(2.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
-- 		{Transparency = 1}
-- 	)
-- 	task.spawn(function()
-- 		slungTween.Completed:Connect(function()
-- 			bounceTween:Play()
-- 			rotateTween:Play()
-- 			task.wait(1.5)
-- 			fadeTween:Play()
-- 			fadeTween.Completed:Connect(function()
-- 				fish:Destroy()
-- 			end)
-- 		end)
-- 	end)
-- end
function fishingManager:setupEventListener()
	FishingRod.Equipped:Connect(function()
		self:onEquipped()
	end)
	FishingRod.Unequipped:Connect(function()
		self:onUnequipped()
	end)
	CastApproved.OnClientEvent:Connect(function(success, result)
		if success then
			setAttr("isFishing", true)
			splashSound:Play()
		else
			errorSound:Play()
			self:cleanBobber()
			self:cleanAnimations()
			self:setFishingWalkSpeed(false)
			setAttr("isFishing", false)
		end
	end)
	BiteEvent.OnClientEvent:Connect(function()
		UIManager:showBitUI(player)
		chimeSound:Play()

		local reelingAnimation = self:loadAnimation(REELING_ANIMATION_ID)
		reelingAnimation:Play()
		reelingAnimation:AdjustSpeed(1)
		local ui = UIManager:createFishingUI(player)
		reelSound:Play()
		UIManager:showPopup(player, "Fish! Reeling...", 2.5)

		task.wait(0.8)

		UIManager:showBitUI(player, false)
		ReelComplete:FireServer(true)
	end)
	CatchResult.OnClientEvent:Connect(function(info)
		if not info then return end
		self:cleanAnimations()
		local catchAnimation = self:loadAnimation(CATCH_ANIMATION_ID)
		catchAnimation:Play()
		local connection
		connection = catchAnimation:GetMarkerReachedSignal("CatchPoint"):Connect(function()
			connection:Disconnect()
			splashSound:Play()
			startCastSound:Play()
			local fishModel
			if bobber then
				if info.success then
					local fishData = info.fishData
					local weight = info.weight
					local name = info.fishName
					local rarity = fishData.rarity

					local target = RodTip.WorldPosition
					local tween = TweenService:Create(bobber, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {Position = target})
					tween:Play()

					local fish, struggleTween, jumpTween = self:createFishAnimation(name, rarity, bobber.Position)
					local currentFish = fish
					fishModel = fish:Clone()

					local fishFollowConnection = RunService.Heartbeat:Connect(function()
						if currentFish and bobber then
							-- Update fish position to follow bobber
							currentFish:SetPrimaryPartCFrame(CFrame.new(bobber.Position))

							-- Update jump animation to work with new position
							jumpTween:Cancel()
							jumpTween = TweenService:Create(
								currentFish.Body,
								TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
								{Position = bobber.Position + Vector3.new(0, 0.5, 0)}
							)
							jumpTween:Play()
						end
					end)

					tween.Completed:Wait()

					struggleTween:Cancel()
					jumpTween:Cancel()
					fishFollowConnection:Disconnect()

					self:createFishSlungAnimation(currentFish)
					--
					UIManager:showPopup(
						player, 
						"Caught: "..(name or "Fish").." ("..(rarity or "Common")..")\nWeight: "..tostring(weight).."kg", 2.5)
					--	local item = ItemManager:createFishItem(info.name, info.rarity, info.weight, info.reward)
					--	if item then
					--	local backpack = player:FindFirstChild("Backpack")
					--	if backpack then
					--		item.Parent = backpack
					--	end
					--end
					UIManager.Inv:addFishToInventory(player, {
						name = name,
						rarity = rarity,
						weight = weight,
						id = fishData.id,
						-- reward = reward,
						icon = fishData.icon
					})
				else
					UIManager:showPopup(player, "Fish not caught", 2.5)
				end
			end
			self:cleanBobber()
			self:cleanAnimations()
			self:setFishingWalkSpeed(false)
			setAttr("isFishing", false)
		end)
		-- catchAnimation:AdjustSpeed(1)
	end)
end

function fishingManager:main()
	self:setupEventListener()
end
fishingManager:main()

