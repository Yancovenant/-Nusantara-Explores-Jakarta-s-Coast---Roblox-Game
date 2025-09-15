-- Global Storage Module

local GSM = {}
GSM.DEFAULT_PLAYER_DATA = {
    Money = 0,
	TotalCatch = 0,
	RarestCatch = 0,
	FishInventory = {},
	PlayerLevel = 1,
	PlayerXP = 0,
	Equipment = {
		OwnedRods = {1}, -- Start with Basic Rod
		OwnedBobbers = {1}, -- Start with Cork Bobber
		OwnedBait = {1}, -- Start with Worm
		OwnedLines = {1}, -- Start with Cotton Line
		EquippedRod = 1,
		EquippedBobber = 1,
		EquippedBait = 1,
		EquippedLine = 1
	}
}
GSM.Data = {}

local Players = game:GetService("Players")
local DSS:DataStoreService = game:GetService("DataStoreService")
local DB:DataStore = DSS:GetDataStore("pDB_v1")

-- HELPER
local function WaitForRequestBudget(requestType:Enum.DataStoreRequestType)
	local cur = DSS:GetRequestBudgetForRequestType(requestType)
	while cur < 1 do
		cur = DSS:GetRequestBudgetForRequestType(requestType)
		task.wait(5)
	end
end
local function key(player)
    return "Player_" .. player.UserId .. "_" .. player.Name .. "_v1"
end


-- STATIC FUNCTIONS
function GSM:_MigrateKey(player, data)
    local saveSuccess
    repeat
        WaitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync)
        saveSuccess = pcall(DB.SetAsync, DB, key(player), data) -- new key
    until saveSuccess
    if saveSuccess then
        repeat
            WaitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync)
            saveSuccess = pcall(DB.RemoveAsync, DB, player.UserId) -- old key
        until saveSuccess
    end
end
function GSM:_MigrateData2(data)
    
end
function GSM:_MigrateFishData(data)
    if data.FishCounts and data.FishWeights and not data.FishInventory then
        data.FishInventory = {}
        for FishId, Weights in pairs(data.FishWeights) do
            if type(Weights) == "table" then
                data.FishInventory[tostring(FishId)] = Weights
            end
        end
        data.FishCounts = nil
        data.FishWeights = nil
    end
    return data
end
function GSM:_Validate(data)
    local validated = {}
    for k, v in pairs(self.DEFAULT_PLAYER_DATA) do
        validated[k] = v
    end
    if data then
        data = self:_MigrateFishData(data) -- old data deprecated...
        data = self:_MigrateData2(data)
        for k, v in pairs(data) do
            if self.DEFAULT_PLAYER_DATA[k] ~= nil then -- return only data exists in default data.
                validated[k] = v
            end
        end
    end
    return validated
end
function GSM:_LoadData(player)
    local success, data
    repeat
        WaitForRequestBudget(Enum.DataStoreRequestType.GetAsync)
        success, data = pcall(DB.GetAsync, DB, key(player)) -- new key
    until success or not Players:FindFirstChild(player) -- or until leaves
    if success and data then
        self:_MigrateKey(player, data)
        return data
    end
    repeat
        WaitForRequestBudget(Enum.DataStoreRequestType.GetAsync)
        success, data = pcall(DB.GetAsync, DB, player.UserId) -- old key
    until success or not Players:FindFirstChild(player)
    if success and data then
        self:_MigrateKey(player, data)
        return data
    end
    return self.DEFAULT_PLAYER_DATA
end
function GSM:_NormalizeData(data)
    local normalized = {}
    for k, v in pairs(data) do
        normalized[k] = v
    end
    for k, v in pairs(normalized) do
        if k == "FishInventory" and type(v) == "table" then
            normalized[k] = {}
            for FishId, Weights in pairs(v) do
                normalized[k][tostring(FishId)] = Weights -- MAKE THE ID NUMBER INTO A STRING, AVOID LUA MARKING IT AS INDEX
            end
        end
    end
    return normalized
end
function GSM:_SaveData(player, data)
    local success, ret
    local normalizedData = self:_NormalizeData(data)
    repeat
        WaitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync)
        success, ret = pcall(DB.UpdateAsync, DB, key(player), function(oldData)
            if oldData then
                if oldData.totalCatch > normalizedData.totalCatch then
                    return oldData
                end
            end
            return normalizedData
        end)
    until success
end


-- ENTRY POINTS
function GSM:LoadDataPlayer(player)
    if self.Data[player] then return self.Data[player] end
    self.Data[player] = self:_Validate(self:_LoadData(player))
    return self.Data[player]
end
function GSM:SaveDataPlayer(player, data)
    if not data and not self.Data[player] then return end
    -- todo we can add some validation to check if the data is same...
    print("[GSM]: Trying to Save, with self.Data[player]", self.Data[player], "and new data passed", data)
    if data == nil then data = self.Data[player] end
    self:_SaveData(player, data)
end


return GSM