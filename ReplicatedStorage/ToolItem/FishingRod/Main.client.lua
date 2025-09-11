-- FishingRod.client.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local fishingRod = script.Parent


local fishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))


-- HELPER FUNCTIONS
local function formatWeight(weight)
	if weight >= 1000 then
		local tons = weight / 1000
		if tons >= 1 and tons < 1000 then
			return string.format("%.1f Ton", tons)
		else
			return string.format("%.0f Tons", tons)
		end
	else
		return string.format("%.1f Kg", weight)
	end
end
local function formatChance(chance)
	-- Convert decimal back to fraction format
	local function gcd(a, b)
		while b ~= 0 do
			a, b = b, a % b
		end
		return a
	end

	local function decimalToFraction(decimal)
		local tolerance = 1e-6
		local h1, h2, k1, k2 = 1, 0, 0, 1
		local x = decimal

		while math.abs(x - math.floor(x + 0.5)) > tolerance do
			x = 1 / (x - math.floor(x))
			h1, h2 = h1 * math.floor(x) + h2, h1
			k1, k2 = k1 * math.floor(x) + k2, k1
		end

		return math.floor(x + 0.5) * h1 + h2, h1
	end

	local numerator, denominator = decimalToFraction(chance)
	local divisor = gcd(numerator, denominator)
	numerator = numerator / divisor
	denominator = denominator / divisor

	return string.format("1/%d", denominator)
end

-- LOCAL FISHING UI
local LocalFishingUI = {}

function LocalFishingUI:createFishingUI(player)
	local playerGUI = player:WaitForChild("PlayerGui")
	if not playerGUI then
		warn("[LocalFishingUI]: No playerGUI found")
		return nil
	end
	local ui = playerGUI:WaitForChild("FishingUI")
	if not ui then
		warn("[LocalFishingUI]: No FishingUI found")
		return nil
	end
	self.autoFishButton = ui:WaitForChild("AutoFishButton")
	self.powerBar = ui:WaitForChild("PowerBar")
	self.popupFrame = ui:WaitForChild("PopupFrame")
	self.popupFish = ui:WaitForChild("PopupFish")
	return ui
end
function LocalFishingUI:getRarityColor(rarity, transparency)
	transparency = transparency or 0.3
	local colors = {
		Common = Color3.fromRGB(180, 180, 180),        -- Light Gray - Clean, neutral
		Uncommon = Color3.fromRGB(100, 255, 100),      -- Bright Green - Fresh, nature
		Rare = Color3.fromRGB(100, 150, 255),          -- Bright Blue - Sky blue, calming
		Epic = Color3.fromRGB(200, 100, 255),         -- Purple - Royal, mysterious
		Legendary = Color3.fromRGB(255, 215, 0),      -- Gold - Classic legendary color
		Mythical = Color3.fromRGB(255, 100, 255),     -- Magenta - Mystical, otherworldly
		Classified = Color3.fromRGB(255, 255, 255)    -- White - Pure, secretive
	}
	return colors[rarity] or colors.Common
end

function LocalFishingUI:showPopup(message)
	print("[LocalFishingUI]: showing popup", message)
end
function LocalFishingUI:showFishPopup(fishInfo)
	self.popupFish.ImageLabel.Image = fishInfo.icon
	self.popupFish.FishInfo.TextColor3 = self:getRarityColor(fishInfo.rarity)
	self.popupFish.FishInfo.Text = fishInfo.fishName .. " (" .. formatWeight(fishInfo.weight) .. ")"
	self.popupFish.Chance.Text = formatChance(fishInfo.chance)

	self.popupFish.Visible = true
	self.fishPopupTween = TweenService:Create(
		self.popupFish,
		TweenInfo.new(.3, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
		{
			Position = self.popupFish.Position + UDim2.new(0, 0.1, 0, 0),
			Size = UDim2.new(0.8, 0, 0.5, 0)
		}
	)
	self.fishPopupTween:Play()
	self.fishPopupTween.Completed:Wait()
	task.wait(1.5)
	self.fishPopupTweenEnd = TweenService:Create(
		self.popupFish,
		TweenInfo.new(.3, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
		{
			Position = self.popupFish.Position - UDim2.new(0, 0.1, 0, 0),
			Size = UDim2.new(0, 0, 0, 0)
		}
	)
	self.fishPopupTweenEnd:Play()
	self.fishPopupTweenEnd.Completed:Wait()
	self.popupFish.Visible = false
end
function LocalFishingUI:cleanUp()
	if self.fishPopupTween then
		self.fishPopupTween:Cancel()
		self.fishPopupTween = nil
	end
	if self.fishPopupTweenEnd then
		self.fishPopupTweenEnd:Cancel()
		self.fishPopupTweenEnd = nil
	end
end

-- MAIN FISHING MANAGER

fishingManager = {}

-- remotes
local FishingRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FishingEvents")
local StartCast = FishingRemotes:WaitForChild("StartCast")
local CastApproved = FishingRemotes:WaitForChild("CastApproved")
local BiteEvent = FishingRemotes:WaitForChild("Bite")
local ReelComplete = FishingRemotes:WaitForChild("ReelComplete")
local CatchResult = FishingRemotes:WaitForChild("CatchResult")
local GlobalFishingUI = FishingRemotes:WaitForChild("GlobalFishingUI")
local CatchTweenFinish = FishingRemotes:WaitForChild("CatchTweenFinish")

local ToolEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")

-- config
local isAFK = false
local afkConnection
local power = 0

local StartCastAnimation = fishingRod:WaitForChild("Animations"):WaitForChild("StartCast")
local ReleaseCastAnimation = fishingRod:WaitForChild("Animations"):WaitForChild("ReleaseCast")
local IdleFishingAnimation = fishingRod:WaitForChild("Animations"):WaitForChild("IdleFishing")
local ReelingAnimation = fishingRod:WaitForChild("Animations"):WaitForChild("Reeling")
local CatchAnimation = fishingRod:WaitForChild("Animations"):WaitForChild("Catch")

local ORIGINAL_WALK_SPEED = 16
local FISHING_WALK_SPEED = 8

-- HELPER FUNCTIONS
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
function fishingManager:setFishingWalkSpeed(enabled)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end
	if enabled then
		humanoid.WalkSpeed = FISHING_WALK_SPEED
	else
		humanoid.WalkSpeed = ORIGINAL_WALK_SPEED
	end
end

-- CLEANUP FUNCTIONS
function fishingManager:cleanupConnections()
    if self.fishingInputBeganConnection then
        self.fishingInputBeganConnection:Disconnect()
        self.fishingInputBeganConnection = nil
    end
    if self.fishingInputEndedConnection then
        self.fishingInputEndedConnection:Disconnect()
        self.fishingInputEndedConnection = nil
    end
	if self.toolConnection then
        self.toolConnection:Disconnect()
        self.toolConnection = nil
    end
    if self.castApprovedConnection then
        self.castApprovedConnection:Disconnect()
        self.castApprovedConnection = nil
    end
    if self.biteEventConnection then
        self.biteEventConnection:Disconnect()
        self.biteEventConnection = nil
    end
    if self.catchResultConnection then
        self.catchResultConnection:Disconnect()
        self.catchResultConnection = nil
    end
    if self.catchTweenFinishConnection then
        self.catchTweenFinishConnection:Disconnect()
        self.catchTweenFinishConnection = nil
    end
    if self.autoFishButtonConnection then
        self.autoFishButtonConnection:Disconnect()
        self.autoFishButtonConnection = nil
    end
	LocalFishingUI:cleanUp()
end
function fishingManager:cleanUp()
	setAttr("isCasting", false)
	setAttr("isFishing", false)
	self:stopAfk()
	power = 0
	self:cleanBobber()
	self:cleanAnimations()
	self:setFishingWalkSpeed(false)
	GlobalFishingUI:FireServer("showBitUI", false)
end
function fishingManager:cleanBobber()
	GlobalFishingUI:FireServer("cleanBobber")
end
function fishingManager:cleanAnimations()
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	local tracks = animator:GetPlayingAnimationTracks()
	for _, track in tracks do
		for _, id in {
			StartCastAnimation.AnimationId,
			ReleaseCastAnimation.AnimationId,
			IdleFishingAnimation.AnimationId,
			ReelingAnimation.AnimationId,
			CatchAnimation.AnimationId
			} do
			if track.Animation.AnimationId == id then
				track:Stop()
				break
			end
		end
	end
end

-- ANIMATION FUNCTIONS
function fishingManager:loadAnimation(animation)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return nil end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return nil end
	local success, track = pcall(animator.LoadAnimation, animator, animation)
	if not success or not track then return nil end
	track.Priority = Enum.AnimationPriority.Action
	return track
end

-- INTERACTION FUNCTIONS
function fishingManager:fishing(target)
	if isFishing() or not canFish() then return end
	setAttr("isFishing", true)
	self:cleanBobber()
    local sanitizePower = math.clamp(tonumber(power) or 0, 0, 1)
	local minRangePercent = 0.45
	local minRange = fishingConfig.Gameplay.BASE_RANGE * minRangePercent
	local powerRange = fishingConfig.Gameplay.BASE_RANGE * (0.5 + sanitizePower)
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
    GlobalFishingUI:FireServer("createBobber", {finalPos, fishingRod})
    fishingRod:WaitForChild("Handle"):WaitForChild("Beam")
    local idleFishingAnimation = self:loadAnimation(IdleFishingAnimation)
	idleFishingAnimation:Play()
	idleFishingAnimation:AdjustSpeed(1)
	StartCast:FireServer(finalPos, isWater(), power)
end
function fishingManager:releaseCast()
	if isFishing() or not canFish() then return end
	if not isCasting() then return end
	setAttr("isCasting", false)
	GlobalFishingUI:FireServer("showPowerCategoryUI", power)
	local releaseCastTrack = self:loadAnimation(ReleaseCastAnimation)
	releaseCastTrack:Play()
	local connection
	connection = releaseCastTrack:GetMarkerReachedSignal("ReleasePoint"):Connect(function(keyframe)
		connection:Disconnect()
		GlobalFishingUI:FireServer("playSound", "ReleaseCastSound")
		local char = player.Character
		local rootPart = char:FindFirstChild("HumanoidRootPart")
		local charCFrame = rootPart.CFrame
		local forwardDirection = charCFrame.LookVector
		local target = rootPart.Position + (forwardDirection * (power * fishingConfig.Gameplay.BASE_RANGE))
		self:fishing(target)
	end)
end
function fishingManager:startCast(afkPower)
	if isFishing() or isCasting() or not canFish() then return end
	setAttr("isCasting", true)
	self:setFishingWalkSpeed(true)
	power = afkPower or 0
	local direction = 1
	local startCastTrack = self:loadAnimation(StartCastAnimation)
	startCastTrack:Play()
	startCastTrack:AdjustSpeed(0) -- Stop automatic progression
	local animationProgress = 0
	while isCasting() do
		local dt = task.wait(0.03)
		local step = (dt / fishingConfig.Gameplay.CHARGE_TIME)
		power = math.clamp(power + (step * direction), 0, 1)
		if power >= 1 then
			direction = -1
		elseif power <= 0 then
			direction = 1
		end
		animationProgress = math.clamp(animationProgress + step, 0, 1)
		local percentage = math.clamp(animationProgress * 100, 0, 99)
		local targetTime = (percentage / 100) * startCastTrack.Length
		startCastTrack.TimePosition = targetTime
		LocalFishingUI.powerBar.Visible = true
		LocalFishingUI.powerBar.Fill.Size = UDim2.new(1, 0, power, 0)
		LocalFishingUI.powerBar.Label.Text = string.format("%d%%", math.floor(power * 100))
		if isAFK and not isFishing() then
			self:releaseCast()
			setAttr("isCasting", false)
		end
	end
	startCastTrack:AdjustSpeed(1)
	LocalFishingUI.powerBar.Visible = false
end

function fishingManager:stopAfk()
	isAFK = false
	if afkConnection then
		task.cancel(afkConnection)
		afkConnection = nil
	end
	LocalFishingUI.autoFishButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
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
	LocalFishingUI.autoFishButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	afkConnection = task.spawn(afkLoop)
end
function fishingManager:toggleAfk()
	if isAFK then
		self:stopAfk()
	else
		self:startAfk()
	end
end

function fishingManager:onUnequipped()
    self:cleanupConnections()
	self:cleanUp()
	setAttr("canFish", false)
	LocalFishingUI.autoFishButton.Visible = false
	self.ready = false
	ToolEvent:FireServer("setUnequippedReady", true)
end
function fishingManager:onEquipped()
    self:cleanupConnections()
	self:cleanUp()
	setAttr("canFish", true)
	local ui = LocalFishingUI:createFishingUI(player)
	if ui then
		LocalFishingUI.autoFishButton.Visible = true
		self.autoFishButtonConnection = LocalFishingUI.autoFishButton.MouseButton1Click:Connect(function()
			self:toggleAfk()
		end)
	end
	self.fishingInputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:startCast()
		end
	end)
	self.fishingInputEndedConnection = UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:releaseCast()
		end
	end)
	self:setupEventListener()
end

-- EVENTS FUNCTIONS
function fishingManager:onCastApproved(success, result)
    if success then
        setAttr("isFishing", true)
        GlobalFishingUI:FireServer("playSound", "SplashSound")
    else
		LocalFishingUI:showPopup(result)
        GlobalFishingUI:FireServer("cleanSounds")
        GlobalFishingUI:FireServer("playSound", "ErrorSound")
        self:cleanBobber()
        self:cleanAnimations()
        self:setFishingWalkSpeed(false)
        setAttr("isFishing", false)
    end
end

function fishingManager:onBite()
    GlobalFishingUI:FireServer("showBitUI", true)
    GlobalFishingUI:FireServer("playSound", "ChimeSound")
    local reelingAnimationTrack = self:loadAnimation(ReelingAnimation)
    reelingAnimationTrack:Play()
    reelingAnimationTrack:AdjustSpeed(1)
    GlobalFishingUI:FireServer("playSound", "ReelSound")
    task.wait(0.8)
    GlobalFishingUI:FireServer("showBitUI", false)
    ReelComplete:FireServer(true)
end

function fishingManager:onCatchResult(info)
    if not info then return end
    self:cleanAnimations()
    local catchAnimationTrack = self:loadAnimation(CatchAnimation)
    catchAnimationTrack:Play()
    local connection
    connection = catchAnimationTrack:GetMarkerReachedSignal("CatchPoint"):Connect(function()
        connection:Disconnect()
        GlobalFishingUI:FireServer("playSound", "SplashSound")
        GlobalFishingUI:FireServer("playSound", "StartCastSound")
        if info.success then
            GlobalFishingUI:FireServer("catchResultSuccess", {info, fishingRod})
            LocalFishingUI:showFishPopup(info)
        else
            LocalFishingUI:showPopup("Fish not caught", 2.5)
        end
    end)
end

function fishingManager:onCatchTweenFinish()
    self:cleanAnimations()
    self:setFishingWalkSpeed(false)
    setAttr("isFishing", false)
end


-- MAIN FUNCTIONS
function fishingManager:setupEventListener()
	self.toolConnection = ToolEvent.OnClientEvent:Connect(function(method, params)
		while not self.ready do
			task.wait()
		end
		self[method](self, params)
	end)
	self.castApprovedConnection = CastApproved.OnClientEvent:Connect(function(success, result)
		self:onCastApproved(success, result)
	end)
	self.biteEventConnection = BiteEvent.OnClientEvent:Connect(function()
		self:onBite()
	end)
	self.catchResultConnection = CatchResult.OnClientEvent:Connect(function(info)
		self:onCatchResult(info)
	end)
	self.catchTweenFinishConnection = CatchTweenFinish.OnClientEvent:Connect(function()
		self:onCatchTweenFinish()
	end)
end

function fishingManager:main()
	print("[FishingRod]: Now running")
	self:cleanupConnections()
	-- self:cleanUp()
	LocalFishingUI:createFishingUI(player)
	self:setupEventListener()
	self.ready = true
end
fishingManager:main()