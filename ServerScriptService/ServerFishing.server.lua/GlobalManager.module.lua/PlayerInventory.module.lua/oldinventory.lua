-- InventoryManager.lua
game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local InventoryManager = {}

local FishingRodDB = require(script.Parent.Parent.Item.FishingRodDB)
local FishingRodItem = script.Parent.Parent.Item.FishingRod

function InventoryManager:setupPlayer(player)
	if not player:FindFirstChild("Custom Backpack") then
		print("creating custom backpack")
		local customBackpack = Instance.new("Folder")
		customBackpack.Name = "Custom Backpack"
		customBackpack.Parent = player
		
		local fishFolder = Instance.new("Folder")
		fishFolder.Name = "Fish"
		fishFolder.Parent = customBackpack
		
		local rodFolder = Instance.new("Folder")
		rodFolder.Name = "Tool"
		rodFolder.Parent = customBackpack
	end
	local bp = player:WaitForChild("Custom Backpack")
	if not bp:FindFirstChild("Tool"):FindFirstChild("FishingRod") then
		local rod = FishingRodItem:Clone()
		print("clonning", rod)
		rod.Parent = bp.Tool
	end
end

function InventoryManager:refreshTools(player)
	print(player)
	local customBackpack = player:FindFirstChild("Custom Backpack")
	if not customBackpack then return end
	local toolFolder = customBackpack:FindFirstChild("Tool")
	for _, tool in pairs(player.Backpack:GetChildren()) do
		tool.Parent = toolFolder
	end
end

function InventoryManager:equipTool(toolName, player)
	self:refreshTools(player)
	local customBackpack = player:FindFirstChild("Custom Backpack")
	local toolFolder = customBackpack:FindFirstChild("Tool")
	local character = player.Character
	local humanoid = character.Humanoid
	local tool = toolFolder:FindFirstChild(toolName)
	humanoid:UnequipTools()
	task.wait()
	humanoid:EquipTool(tool)
end

return InventoryManager
