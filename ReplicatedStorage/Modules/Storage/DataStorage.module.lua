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

local DataStorage = {}

local DEFAULT_PLAYER_DATA = {
	-- money = 0,
	-- totalCatch = 0,
	-- rarestCatch = 0,
	-- fishInventory = {},
	-- playerLevel = 1,
	-- playerXP = 0,
	-- equipment = {
	-- 	ownedRods = {1}, -- Start with Basic Rod
	-- 	ownedBobbers = {1}, -- Start with Cork Bobber
	-- 	ownedBait = {1}, -- Start with Worm
	-- 	ownedLines = {1}, -- Start with Cotton Line
	-- 	equippedRod = 1,
	-- 	equippedBobber = 1,
	-- 	equippedBait = 1,
	-- 	equippedLine = 1
	-- }
}

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local pDB = DataStoreService:GetDataStore("pDB_v1")

-- HELPER FUNCTIONS
-- local function waitForRequestBudget(requestType)
-- 	local cur = DataStoreService:GetRequestBudgetForRequestType(requestType)
-- 	while cur < 1 do
-- 		cur = DataStoreService:GetRequestBudgetForRequestType(requestType)
-- 		task.wait(5)
-- 	end
-- end
-- local function key(player)
--     return "Player_" .. player.UserId .. "_" .. player.Name .. "_v1"
-- end
local function migrateFishData(data)
    -- Check if data has old structure (fishCounts + fishWeights)
    -- if data.fishCounts and data.fishWeights and not data.fishInventory then
    --     data.fishInventory = {}
    --     for fishId, weights in pairs(data.fishWeights) do
    --         if type(weights) == "table" then
    --             data.fishInventory[tostring(fishId)] = weights
    --         end
    --     end
    --     data.fishCounts = nil
    --     data.fishWeights = nil
    -- end
    -- return data
end
-- local function migrateData(player, data)
--     local saveSuccess
--     repeat
--         waitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync)
--         saveSuccess = pcall(pDB.SetAsync, pDB, key(player), data)
--     until saveSuccess
--     if saveSuccess then
--         repeat
--             waitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync)
--             saveSuccess = pcall(pDB.RemoveAsync, pDB, player.UserId)
--         until saveSuccess
--     end
-- end
local function validateData(data)
    -- local validated = {}
	-- for k, v in pairs(DEFAULT_PLAYER_DATA) do
	-- 	validated[k] = v
	-- end
	-- if data then
    --     data = migrateFishData(data)
	-- 	for k, v in pairs(data) do
	-- 		if DEFAULT_PLAYER_DATA[k] ~= nil then
	-- 			validated[k] = v
	-- 		end
	-- 	end
	-- end
	-- return validated
end
local function normalizeData(data)
    local normalized = {}
    for k, v in pairs(data) do
        normalized[k] = v
    end
    for k, v in pairs(normalized) do
        if k == "fishInventory" and type(v) == "table" then
            normalized[k] = {}
            for fishId, weights in pairs(v) do
                normalized[k][tostring(fishId)] = weights
            end
        end
    end
    return normalized
end
function loadData(player)
    -- local success, data
    -- repeat
    --     waitForRequestBudget(Enum.DataStoreRequestType.GetAsync)
    --     success, data = pcall(pDB.GetAsync, pDB, key(player))
    -- until success or not Players:FindFirstChild(player)
    -- if success and data then
    --     migrateData(player, data)
    --     return data
    -- end
    -- repeat
    --     waitForRequestBudget(Enum.DataStoreRequestType.GetAsync)
    --     success, data = pcall(pDB.GetAsync, pDB, player.UserId)
    -- until success or not Players:FindFirstChild(player)
    -- if success and data then
    --     migrateData(player, data)
    --     return data
    -- end
    -- return DEFAULT_PLAYER_DATA
end
function saveData(player, data)
    -- local success, ret
    -- local normalizedData = normalizeData(data)
    -- repeat
    --     waitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync)
    --     success, ret = pcall(pDB.UpdateAsync, pDB, key(player), function(oldData)
    --         if oldData then
    --             if oldData.totalCatch > normalizedData.totalCatch then
    --                 return oldData
    --             end
    --         end
    --         return normalizedData
    --     end)
    -- until success
end

-- MAIN FUNCTIONS
function DataStorage:loadPlayerData(player)
    local data = loadData(player)
    local validatedData = validateData(data)
    return validatedData
end
function DataStorage:savePlayerData(player, data)
    saveData(player, data)
end

return DataStorage