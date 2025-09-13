-- Main.lua
local clientPlayer = {}

game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local toolEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")
local ClientAnimationEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClientAnimation")

local holdingFishAnimation = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("HoldingFish")

local DEFAULT_ATTRS = {
	CameraMaxZoomDistance = 24
}


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
function clientPlayer:setupEventListener()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.E then
			toolEvent:FireServer("toggleInventory")
		elseif input.KeyCode == Enum.KeyCode.One then
			toolEvent:FireServer("toggleRod")
		end
	end)
	self:setupUIClickEvent()
	ClientAnimationEvent.OnClientEvent:Connect(function(animation)
		if animation == "holdFishAboveHead" then
			animation = holdingFishAnimation
		else
			animation = nil
		end
		if animation == nil then
			self:cleanAnimations()
		end
		local animationTrack = self:loadAnimation(animation)
		animationTrack:Play()
	end)
end

function clientPlayer:main()
	self:setupPlayerAttributes()
	self:setupEventListener()
end

clientPlayer:main()