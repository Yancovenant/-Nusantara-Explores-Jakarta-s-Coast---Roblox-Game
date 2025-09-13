-- Main.lua
local clientPlayer = {}

game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService: UserInputService = game:GetService("UserInputService")
local Players: Players = game:GetService("Players")
local Lighting: Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid: Humanoid = character:WaitForChild("Humanoid")
local camera: Camera = workspace.CurrentCamera
local playerGui: PlayerGui = player.PlayerGui

local defaultFov = camera.FieldOfView
local defaultWalkSpeed = humanoid.WalkSpeed

local toolEvent: RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")
local ClientAnimationEvent: RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClientAnimation")
local timeEvent: RemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GlobalEvents"):WaitForChild("TimeEvent")

local holdingFishAnimation: Animation = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("HoldingFish")

local DEFAULT_ATTRS = {
	CameraMaxZoomDistance = 24
}

-- KeyCode
local runKey: Enum.KeyCode = Enum.KeyCode.LeftShift
local invKey: Enum.KeyCode = Enum.KeyCode.E
local rodKey: Enum.KeyCode = Enum.KeyCode.One

-- ANIMATION HANDLER
function clientPlayer:loadAnimation(animation)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return nil end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return nil end
	local success, track = pcall(animator.LoadAnimation, animator, animation)
	if not success or not track then return nil end
	track.Priority = Enum.AnimationPriority.Action
	return track
end
function clientPlayer:cleanAnimations()
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	local tracks = animator:GetPlayingAnimationTracks()
	for _, track in tracks do
		for _, id in {
			holdingFishAnimation.AnimationId
			} do
			if track.Animation.AnimationId == id then
				track:Stop()
				break
			end
		end
	end
end


-- UI HANDLER
function clientPlayer:setTimeUI(t)
	if t == nil then
		t = {}
		t.hour = Lighting:GetAttribute("Hour")
		t.min = Lighting:GetAttribute("Minute")
	end
	local timeUI = player:WaitForChild("PlayerGui"):WaitForChild("TopBarUI"):WaitForChild("Time"):WaitForChild("TimeText")
	timeUI.Text = t.hour .. ":" .. t.min
end


-- SETUP EVENT LISTENER
function clientPlayer:setupPlayerAttributes()
	for key, value in pairs(DEFAULT_ATTRS) do
		player[key] = value
	end
end
function clientPlayer:setupUIClickEvent()
	local inventoryUI = player:WaitForChild("PlayerGui"):WaitForChild("InventoryUI")
	if not inventoryUI then return end
	local tabContainer = inventoryUI:WaitForChild("TabContainer")
	local fishTabBtn = tabContainer:WaitForChild("TabNavbar"):WaitForChild("FishTabButton")
	local rodTabBtn = tabContainer:WaitForChild("TabNavbar"):WaitForChild("RodTabButton")
	local pageLayout = tabContainer:WaitForChild("ContentArea"):FindFirstChildWhichIsA("UIPageLayout")
	local fishPageFrame = tabContainer:WaitForChild("ContentArea"):WaitForChild("Fish")
	local rodPageFrame = tabContainer:WaitForChild("ContentArea"):WaitForChild("Rod")
	fishTabBtn.MouseButton1Click:Connect(function()
		pageLayout:JumpTo(fishPageFrame)
	end)
	rodTabBtn.MouseButton1Click:Connect(function()
		pageLayout:JumpTo(rodPageFrame)
	end)
end
function clientPlayer:setupUserInputServiceEvent()
	if UserInputService.TouchEnabled and not UserInputService.GyroscopeEnabled then
		-- mobile
	else
		UserInputService.InputBegan:Connect(function(input: InputObject, gp: boolean)
			if gp then return end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == runKey then
					if player.Character:GetAttribute("isFishing") or player.Character:GetAttribute("isCasting") then return end
					self.isRunning = true
					humanoid.WalkSpeed = humanoid.WalkSpeed + 8
					self.sprintingTween:Play()
				elseif input.KeyCode == invKey then
					toolEvent:FireServer("toggleInventory")
				elseif input.KeyCode == rodKey then
					toolEvent:FireServer("toggleRod")
				end
			end
		end)
		UserInputService.InputEnded:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == runKey then
					if not self.isRunning then return end
					if player.Character:GetAttribute("isFishing") or player.Character:GetAttribute("isCasting") then return end
					self.isRunning = false
					humanoid.WalkSpeed = defaultWalkSpeed
					self.walkingTween:Play()
				end
			end
		end)
	end
end
function clientPlayer:setupEventListener()
	self.sprintingTween = TweenService:Create(
		camera,
		TweenInfo.new(0.3),
		{FieldOfView = defaultFov + (8/5)}
	)
	self.walkingTween = TweenService:Create(
		camera,
		TweenInfo.new(0.3),
		{FieldOfView = defaultFov}
	)
	self:setupUserInputServiceEvent()
	self:setupUIClickEvent()
	ClientAnimationEvent.OnClientEvent:Connect(function(animation)
		if animation == "holdFishAboveHead" then
			animation = holdingFishAnimation
		else
			animation = nil
		end
		if animation == nil then
			self:cleanAnimations()
			return
		end
		local animationTrack = self:loadAnimation(animation)
		animationTrack:Play()
	end)
	timeEvent.OnClientEvent:Connect(function(timeInfo)
		self:setTimeUI(timeInfo)
	end)
end

function clientPlayer:main()
	self:setupPlayerAttributes()
	self:setupEventListener()
	self:setTimeUI()
end

clientPlayer:main()