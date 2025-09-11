-- Main.lua
game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local toolEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")

local function setupPlayerAttributes()
	player.CameraMaxZoomDistance = 24
end

local function setupEventListener()
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

local function main()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.E then
			toolEvent:FireServer("toggleInventory")
		elseif input.KeyCode == Enum.KeyCode.One then
			toolEvent:FireServer("toggleRod")
		end
	end)
	setupPlayerAttributes()
	setupEventListener()
end

main()