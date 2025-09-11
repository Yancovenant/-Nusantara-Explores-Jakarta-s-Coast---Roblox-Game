-- ServerFishing.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartCast = Remotes:WaitForChild("FishingEvents"):WaitForChild("StartCast")
local CastApproved = Remotes:WaitForChild("FishingEvents"):WaitForChild("CastApproved")
local BiteEvent = Remotes:WaitForChild("FishingEvents"):WaitForChild("Bite")
local CatchResult = Remotes:WaitForChild("FishingEvents"):WaitForChild("CatchResult")
local ReelComplete = Remotes:WaitForChild("FishingEvents"):WaitForChild("ReelComplete")
local GlobalFishingUI = Remotes:WaitForChild("FishingEvents"):WaitForChild("GlobalFishingUI")
local ToolEvent = Remotes:WaitForChild("Inventory"):WaitForChild("Tool")

local DataStorage = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Storage"):WaitForChild("DataStorage"))

local GlobalFishingManager = require(script.GlobalManager)

local state = {}
local playerData = {}

local function calculateFishWeight(fishData, roll, cumulative, chance)
	local minWeight = fishData.minWeight
	local maxWeight = fishData.maxWeight
	local rangeStart = cumulative - chance
	local totalRange = cumulative - rangeStart
	local rollPosition = roll - rangeStart
	local percentage = rollPosition / totalRange
	local weight = minWeight + (percentage * (maxWeight - minWeight))
	return math.floor(weight * 100) / 100
end
local function finalFishPool(player, power, fishDB)
	local percentWeight = 0
	local fishPool = {}
	local playerLevel = 1 -- temp
	local playerLuck = 1 -- temp

	local levelMultiplier = 1 + (math.log(playerLevel) * 0.11)
	local equipmentMultiplier = 1
	local environmentalMultiplier = 1
	local luckMultiplier = 1 + (math.log(playerLuck) * 0.2)
	local powerMultiplier = 1 + (power * 0.3)
	local totalMultiplier = powerMultiplier * levelMultiplier * equipmentMultiplier * environmentalMultiplier * luckMultiplier

	for fishName, fishData in pairs(fishDB.Fish) do
		local chance = fishData.baseChance
		fishPool[fishName] = chance
		percentWeight = percentWeight + chance
	end
	local normalizePool = {}
	for fishName, chance in pairs(fishPool) do
		table.insert(normalizePool, {
			fishName = fishName,
			chance = chance
		})
	end
	table.sort(normalizePool, function(a,b)
		return a.chance < b.chance
	end)
	return normalizePool, percentWeight, totalMultiplier
end
local function calculateReward(player, power)
	local fishDB = require(player.Character.FishingRod:WaitForChild("FishDB"))
	local fishPool, percentWeight, totalMultiplier = finalFishPool(player, power, fishDB)
	local roll = math.random() * percentWeight
	local cumulative = 0
	for i, fishData in ipairs(fishPool) do
		cumulative = cumulative + fishData.chance
		local adjustedCumulative = cumulative * totalMultiplier
		if roll <= adjustedCumulative then
			local selectedFish = fishDB.Fish[fishData.fishName]
			local weight = calculateFishWeight(selectedFish, roll, cumulative, fishData.chance)
			return fishData.fishName, selectedFish, weight
		end
	end
end

StartCast.OnServerEvent:Connect(function(player, targetPos, isWater, power)
	local st = state[player] or {}
	state[player] = st
	local sendMessage = function(success, message)
		CastApproved:FireClient(player, success, message)
		st.isFishing = success
	end

	if st.isFishing then
		sendMessage(false, "Already fishing")
		return
	end

	if not isWater then
		sendMessage(false, "Aim at water")
		return
	end

	st.biteReady = false
	st.power = power
	sendMessage(true, "Cast approved")

	local biteDelay = math.random(FishingConfig.Gameplay.BITE_DELAY_MIN, FishingConfig.Gameplay.BITE_DELAY_MAX)
	task.delay(biteDelay, function()
		if not st.isFishing then return end

		st.biteReady = true
		st.biteExpires = tick() + FishingConfig.Gameplay.REACTION_WINDOW

		BiteEvent:FireClient(player)
	end)
end)
ReelComplete.OnServerEvent:Connect(function(player, success)
	local st = state[player]
	if not st or not st.isFishing then return end
	if success and st.biteReady and tick() <= (st.biteExpires or 0) then
		local pData = playerData[player]
		local fishName, fishData, weight = calculateReward(player, st.power)

		CatchResult:FireClient(player, {
			success = true,
			-- name = fishData.fishName,
			-- rarity = fishData.rarity,
			fishName = fishName,
			fishData = fishData,
			weight = weight,
			-- reward = reward
		})

		if pData.totalCatch ~= nil then
			pData.totalCatch.Value = pData.totalCatch.Value + 1
		end

		DataStorage:addFish(player, fishData.id, weight)
	else
		CatchResult:FireClient(player, {success = false})
	end
	state[player] = nil
end)

-- GLOBAL MANAGER
GlobalFishingUI.OnServerEvent:Connect(function(player, method, params)
    GlobalFishingManager[method](GlobalFishingManager, player, params)
end)
ToolEvent.OnServerEvent:Connect(function(player, method, params)
    GlobalFishingManager[method](GlobalFishingManager, player, params)
end)

Players.PlayerAdded:Connect(function(player)
	if not player:FindFirstChild("leaderstats") then
		local folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		folder.Parent = player

		local pData = playerData[player]
		if pData == nil then
			pData = {
				money = 0,
				totalCatch = 0,
				rarestCatch = 0,
			}
		end
		local money, totalCatch, rarestCatch

		DataStorage:onDataReady(player, function(player, data)
			money = Instance.new("IntValue")
			money.Name = "Money"
			money.Value = data.money
			money.Parent = folder
			pData.money = money

			totalCatch = Instance.new("IntValue")
			totalCatch.Name = "Caught"
			totalCatch.Value = data.totalCatch
			totalCatch.Parent = folder
			pData.totalCatch = totalCatch

			rarestCatch = Instance.new("IntValue")
			rarestCatch.Name = "Rarest Caught"
			rarestCatch.Value = data.rarestCatch
			rarestCatch.Parent = folder
			pData.rarestCatch = rarestCatch

			pData.totalCatch:GetPropertyChangedSignal("Value"):Connect(function()
				DataStorage:updateTotalCatch(player, pData.totalCatch.Value)
			end)
			pData.money:GetPropertyChangedSignal("Value"):Connect(function()
				DataStorage:updateMoney(player, pData.money.Value)
			end)
			pData.rarestCatch:GetPropertyChangedSignal("Value"):Connect(function()
				DataStorage:updateRarestCatch(player, pData.rarestCatch.Value)
			end)
		end)
		playerData[player] = pData
	end
    GlobalFishingManager:playerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
	state[player] = nil
    GlobalFishingManager:playerRemoved(player)
end)

-- CLEANUP
game:BindToClose(function()
    state = {}
    playerData = {}
end)


