-- Global Storage Module

local GSM = {}
GSM.DEFAULT_PLAYER_DATA = {
    SessionLock = false, -- important for handling locksession
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
        WaitForRequestBudget(Enum.DataStoreRequestType.UpdateAsync)
        saveSuccess = pcall(DB.UpdateAsync, DB, key(player), function(oldData)
            return data
        end) -- new key
    until saveSuccess
    if saveSuccess then
        repeat
            WaitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync)
            saveSuccess = pcall(DB.RemoveAsync, DB, player.UserId) -- old key
        until saveSuccess
    end
end
function GSM:_MigrateData2(data)
    if not data or type(data) ~= "table" then return data end
    if data.Money ~= nil or data.TotalCatch ~= nil or data.RarestCatch ~= nil then
        if data.Equipment and type(data.Equipment) == "table" then -- subpart
            local e = data.Equipment
            e.OwnedRods = e.OwnedRods or e.ownedRods
            e.OwnedBobbers = e.OwnedBobbers or e.ownedBobbers
            e.OwnedBait = e.OwnedBait or e.ownedBait
            e.OwnedLines = e.OwnedLines or e.ownedLines
            e.EquippedRod = e.EquippedRod or e.equippedRod
            e.EquippedBobber = e.EquippedBobber or e.equippedBobber
            e.EquippedBait = e.EquippedBait or e.equippedBait
            e.EquippedLine = e.EquippedLine or e.equippedLine
        end
        return data -- early return
    end
    local migrated = {}
    migrated.Money = data.money or 0
    migrated.TotalCatch = data.totalCatch or 0
    migrated.RarestCatch = data.rarestCatch or 0
    migrated.FishInventory = data.fishInventory or {}
    migrated.PlayerLevel = data.playerLevel or 1
    migrated.PlayerXP = data.playerXP or 0

    local oldE = data.equipment or {}
    migrated.Equipment = {
        OwnedRods = oldE.ownedRods or {1},
        OwnedBobbers = oldE.ownedBobbers or {1},
        OwnedBait = oldE.ownedBait or {1},
        OwnedLines = oldE.ownedLines or {1},
        EquippedRod = oldE.equippedRod or 1,
        EquippedBobber = oldE.equippedBobber or 1,
        EquippedBait = oldE.equippedBait or 1,
        EquippedLine = oldE.equippedLine or 1,
    }
    return migrated
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
    local success, data, shouldWait
    repeat
        WaitForRequestBudget(Enum.DataStoreRequestType.UpdateAsync)
        success, data = pcall(DB.UpdateAsync, DB, key(player), function(oldData)
            oldData = oldData or self.DEFAULT_PLAYER_DATA
            if oldData.SessionLock then
                warn("[GSM] Player", player.Name, "has active session lock:", oldData.SessionLock)
                if os.time() - oldData.SessionLock < 1800 then
                    shouldWait = true
                else
                    oldData.SessionLock = os.time()
					data = oldData
                    return data
                end
            else
                oldData.SessionLock = os.time()
				data = oldData
				return data
            end
        end) -- new key
        if shouldWait then
			task.wait(5)
			shouldWait = false
		end
    until (success and data) or not Players:FindFirstChild(player) -- or until leaves
    if success and data then
        return data
    end
    -- OLD KEY GET
    repeat
        WaitForRequestBudget(Enum.DataStoreRequestType.UpdateAsync)
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
function GSM:_SaveData(player, data, locksession, force)
    local success, ret
    local normalizedData = self:_NormalizeData(data)
    repeat
        if not force then
            WaitForRequestBudget(Enum.DataStoreRequestType.UpdateAsync)
        end
        success, ret = pcall(DB.UpdateAsync, DB, key(player), function(oldData)
            oldData = self:_MigrateData2(oldData or {})
            if oldData and (oldData.TotalCatch or 0) > (normalizedData.TotalCatch or 0) then
                return oldData
            end
            normalizedData.SessionLock = locksession and os.time() or nil
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
function GSM:SaveDataPlayer(player, data, locksession, force)
    if not data and not self.Data[player] then return end
    -- todo we can add some validation to check if the data is same...
    if data == nil then data = self.Data[player] end
    self:_SaveData(player, data, locksession, force)
end


return GSM