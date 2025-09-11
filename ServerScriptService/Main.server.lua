-- Main.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local remoteEvents = {
	"StartCast",
	"CastApproved",
	"Bite",
	"ReelComplete",
	"CatchResult"
}
local function setupRemoteEvents()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end
	for _, remoteEvent in ipairs(remoteEvents) do
		local existingEvent = remotesFolder:FindFirstChild(remoteEvent)
		if not existingEvent then
			local newEvent = Instance.new("RemoteEvent")
			newEvent.Name = remoteEvent
			newEvent.Parent = remotesFolder
		end
	end
end

local function setupWaterTags()
	local waterTag = "Water"
	local potentialWaterParts = {}

	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:IsA("BasePart") then
			local name = part.Name:lower()
			if name:find("water") or name:find("lake") or name:find("ocean") or name:find("river") or name:find("pond") then
				table.insert(potentialWaterParts, part)
			end
		end
	end
	for _, part in ipairs(potentialWaterParts) do
		if not CollectionService:HasTag(part, waterTag) then
			CollectionService:AddTag(part, waterTag)
		end
	end

	-- local terrain = Workspace:WaitForChild("Terrain")
	-- print(terrain)
	-- if not terrain then return end
	-- local isWater = terrain:GetMaterial() == Enum.Material.Water
	-- print(isWater)
	-- if isWater then
	-- 	print("Terrain is water")
	-- end
end

-- local GlobalManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GlobalManager"))


local function main()
	setupRemoteEvents()
	setupWaterTags()
	--GlobalManager:main()
end

main()