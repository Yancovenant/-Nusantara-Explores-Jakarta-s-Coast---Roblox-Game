-- Main.server.lua
local RS, WS, CS = game:GetService("ReplicatedStorage"), game:GetService("Workspace"), game:GetService("CollectionService")
local remotesEvents = {"StartCast","CastApproved","Bite","ReelComplete","CatchResult"}
local function setupRemoteEvents()
	local f=RS:WaitForChild("Remotes") or Instance.new("Folder") f.Name="Remotes" f.Parent=RS
	for _,n in ipairs(remotesEvents) do if not f:FindFirstChild(n)then local e=Instance.new("RemoteEvent") e.Name=n e.Parent=f end end
end

local function setupWaterTags()
	local waterTag = "Water"
	local potentialWaterParts = {}

	for _, part in ipairs(WS:GetDescendants()) do
		if part:IsA("BasePart") then
			local name = part.Name:lower()
			if name:find("water") or name:find("lake") or name:find("ocean") or name:find("river") or name:find("pond") then
				table.insert(potentialWaterParts, part)
			end
		end
	end
	for _, part in ipairs(potentialWaterParts) do
		if not CS:HasTag(part, waterTag) then
			CS:AddTag(part, waterTag)
		end
	end
end

local function main()
	setupRemoteEvents()
	setupWaterTags()
	--GlobalManager:main()
end

main()