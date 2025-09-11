-- DataStorage.module.lua

--[[
    Data To Save:
    - money = 0
    - totalCatch = 0
    - rarestCatch = 0

    - fishCounts = {} // id + int count
    - fishWeights = {} // id + float weight

    - playerLevel = 1
    - playerXP = 0
    
    /// tools etc later
]]--



local DEFAULT_PLAYER_DATA = {
	money = 0,
	totalCatch = 0,
	rarestCatch = 0,
	fishCounts = {},
	fishWeights = {},
	playerLevel = 1,
	playerXP = 0,
}

local DataStorage = {}
DataStorage.__index = DataStorage
DataStorage.data = {}

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local pDB
local cache = {}

local saveQueue = {} -- Array of save requests: {userId, data, timestamp, force}
local SAVE_DELAY = 2
local queueLock = false

local function waitForRequestBudget(requestType)
	local cur = DataStoreService:GetRequestBudgetForRequestType(requestType)
	while cur < 1 do
		cur = DataStoreService:GetRequestBudgetForRequestType(requestType)
		wait(5)
	end
end


function DataStorage:saveDataDB(player, data)
	local success, err
	repeat
		print("saving data repeating")
		waitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync)
		success, err = pcall(pDB.UpdateAsync, pDB, player.UserId, function(oldData)
			return data
		end)
	until success
	if not success then
		warn("Error saving player data:", err)
	else
		cache[player.UserId] = data
		self.data[player.UserId] = data
	end
end

function DataStorage:processQueue()
	if queueLock then return end
	queueLock = true

	task.spawn(function()
		while #saveQueue > 0 do
			local currentTime = tick()
			local itemsToProcess = {}

			-- Find items ready to save
			for i = #saveQueue, 1, -1 do
				local item = saveQueue[i]
				local timeSinceQueue = currentTime - item.timestamp

				if timeSinceQueue >= SAVE_DELAY or item.force then
					table.insert(itemsToProcess, item)
					table.remove(saveQueue, i) -- Remove from queue
				end
			end

			-- Process ready items
			for _, item in ipairs(itemsToProcess) do
				local player = Players:GetPlayerByUserId(item.userId)
				if player then
					self:saveDataDB(player, item.data)
				end
			end
			task.wait(0.1)
		end
		queueLock = false
	end)
end

function DataStorage:queueSave(player, data, force)
	local userId = player.UserId
	table.insert(saveQueue, {
		userId = userId,
		data = data,
		timestamp = tick(),
		force = force or false
	})
	if not queueLock then
		self:processQueue()
	end
end

function DataStorage:savePlayerData(player, data, force)
	if not game:GetService("RunService"):IsServer() then
		warn("DataStorage:savePlayerData can only be called from server!")
		return
	end
	self:queueSave(player, data, force)
end

function DataStorage:addFish(player, fishId, weight)
	local data = self.data[player.UserId]
	local fishIdStr = tostring(fishId)
	data.fishCounts[fishIdStr] = (data.fishCounts[fishIdStr] or 0) + 1
	if not data.fishWeights[fishIdStr] then
		data.fishWeights[fishIdStr] = {}
	end
	table.insert(data.fishWeights[fishIdStr], weight)
	self:savePlayerData(player, data)
end
function DataStorage:updateTotalCatch(player, totalCatch)
	local data = self.data[player.UserId]
	data.totalCatch = totalCatch
	self:savePlayerData(player, data)
end
function DataStorage:updateMoney(player, money)
	local data = self.data[player.UserId]
	data.money = money
	self:savePlayerData(player, data)
end
function DataStorage:updateRarestCatch(player, rarestCatch)
	local data = self.data[player.UserId]
	data.rarestCatch = rarestCatch
	self:savePlayerData(player, data)
end


function DataStorage:onDataReady(player, callback)
	if not game:GetService("RunService"):IsServer() then
		warn("DataStorage:onDataReady can only be called from server!")
		return
	end
	print(self.data[player.UserId], "self.data[player.UserId]")
	if self.data[player.UserId] ~= nil then
		callback(player, self.data[player.UserId])
	else
		task.spawn(function()
			while self.data[player.UserId] == nil do
				task.wait(0.1)
			end
			print(self.data[player.UserId], "self.data[player.UserId] after waiting")
			callback(player, self.data[player.UserId])
		end)
	end
end

-- function DataStorage:ValidateAndMergeData(data)
-- 	local validated = {}
-- 	for k, v in pairs(DEFAULT_PLAYER_DATA) do
-- 		validated[k] = v
-- 	end
-- 	if data then
-- 		for k, v in pairs(data) do
-- 			if DEFAULT_PLAYER_DATA[k] ~= nil then
-- 				validated[k] = v
-- 			end
-- 		end
-- 	end
-- 	return validated
-- end
function DataStorage:setupPlayer(player)
	if not game:GetService("RunService"):IsServer() then
		warn("DataStorage:main can only be called from server!")
		return
	end
	pDB = DataStoreService:GetDataStore("pDB_v1")
	-- pDB:RemoveAsync(player.UserId)
	local success, data
	repeat
		waitForRequestBudget(Enum.DataStoreRequestType.GetAsync)
		success, data = pcall(pDB.GetAsync, pDB, player.UserId)
	until success or not Players:FindFirstChild(player)
	if not success or not data then
		cache[player.UserId] = DEFAULT_PLAYER_DATA
		self.data[player.UserId] = DEFAULT_PLAYER_DATA
		return
	end
	local safeData = self:ValidateAndMergeData(data)
	cache[player.UserId] = safeData
	self.data[player.UserId] = safeData
end

Players.PlayerRemoving:Connect(function(player)
	print("player removing", player)
	local data = DataStorage.data[player.UserId]
	if data then
		DataStorage:savePlayerData(player, data, true)
		task.wait(0.5)
	end
end)

return DataStorage