-- Main.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local GlobalManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GlobalManager"))
local toolEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")

local function setupPlayerAttributes()
	player.CameraMaxZoomDistance = 12
end

local function main()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.E then
			toolEvent:FireServer("toggle")
		elseif input.KeyCode == Enum.KeyCode.One then
			toolEvent:FireServer("toggleRod")
		end
	end)
	setupPlayerAttributes()
end

main()