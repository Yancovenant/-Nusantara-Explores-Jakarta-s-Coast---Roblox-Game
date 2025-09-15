-- PlayerInventory.module.lua


local RARITY_MULTIXP = {
    ["Classified"] = 7,
	["Mythical"] = 5.5,
	["Legendary"] = 5,
	["Epic"] = 3.5,
	["Rare"] = 2,
	["Uncommon"] = 1.25,
	["Common"] = 1
}
local AUTOSAVE_INTERVAL = 120 -- 2 minutes

local PlayerInventory = {}
PlayerInventory.__index = PlayerInventory

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local DataStorage = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Storage"):WaitForChild("DataStorage"))


local FishDB = require(FishingRodItem:WaitForChild("FishDB"))
local EquipmentDB = require(FishingRodItem:WaitForChild("EquipmentDB"))



-- -- EQUIPMENT FUNCTIONS

-- function PlayerInventory:getEquippedBobber()
--     local bobberId = self.data.equipment.equippedBobber
--     return EquipmentDB:getBobber(bobberId)
-- end

-- function PlayerInventory:getEquippedBait()
--     local baitId = self.data.equipment.equippedBait
--     return EquipmentDB:getBait(baitId)
-- end

-- function PlayerInventory:getEquippedLine()
--     local lineId = self.data.equipment.equippedLine
--     return EquipmentDB:getFishingLine(lineId)
-- end

-- function PlayerInventory:equipRod(rodId)
--     if not table.find(self.data.equipment.ownedRods, rodId) then
--         return false, "You don't own this rod"
--     end
--     self.data.equipment.equippedRod = rodId
--     self:updateFishingRodModel()
--     return true, "Rod equipped successfully"
-- end

-- function PlayerInventory:equipBobber(bobberId)
--     if not table.find(self.data.equipment.ownedBobbers, bobberId) then
--         return false, "You don't own this bobber"
--     end
--     self.data.equipment.equippedBobber = bobberId
--     return true, "Bobber equipped successfully"
-- end

-- function PlayerInventory:equipBait(baitId)
--     if not table.find(self.data.equipment.ownedBait, baitId) then
--         return false, "You don't own this bait"
--     end
--     self.data.equipment.equippedBait = baitId
--     return true, "Bait equipped successfully"
-- end

-- function PlayerInventory:equipLine(lineId)
--     if not table.find(self.data.equipment.ownedLines, lineId) then
--         return false, "You don't own this fishing line"
--     end
--     self.data.equipment.equippedLine = lineId
--     return true, "Fishing line equipped successfully"
-- end

-- function PlayerInventory:buyEquipment(equipmentType, equipmentId)
--     local equipment = nil
--     local price = 0
    
--     if equipmentType == "rod" then
--         equipment = EquipmentDB:getRod(equipmentId)
--     elseif equipmentType == "bobber" then
--         equipment = EquipmentDB:getBobber(equipmentId)
--     elseif equipmentType == "bait" then
--         equipment = EquipmentDB:getBait(equipmentId)
--     elseif equipmentType == "line" then
--         equipment = EquipmentDB:getFishingLine(equipmentId)
--     end
    
--     if not equipment then
--         return false, "Equipment not found"
--     end
    
--     price = equipment.price
    
--     if self.money.Value < price then
--         return false, "Not enough money"
--     end
    
--     -- Check if already owned
--     local ownedList = self.data.equipment["owned" .. equipmentType:gsub("^%l", string.upper) .. "s"]
--     if table.find(ownedList, equipmentId) then
--         return false, "You already own this equipment"
--     end
    
--     -- Purchase equipment
--     self.money.Value = self.money.Value - price
--     self.data.money = self.money.Value
--     table.insert(ownedList, equipmentId)
    
--     return true, "Equipment purchased successfully"
-- end









-- ZONES FUNCTIONS
function PlayerInventory:updateUIPlayerZone(zone: string)
    print(zone, "player is moving to zone")
end


-- PLAYER FUNCTIONS
function PlayerInventory:calculateXP(info)
    local multi = RARITY_MULTIXP[info.fishData.rarity]
    local xp = (info.weight ^ 0.75) * multi
    print("get xp is", xp)
end

-- MAIN FUNCTIONS
function PlayerInventory:catchResultSuccess(info)
    self:addFishToInventory({
        id = info.fishData.id,
        weight = info.weight,
    }, true)
    if self.data.fishInventory[tostring(info.fishData.id)] == nil then
        self.data.fishInventory[tostring(info.fishData.id)] = {}
    end
    table.insert(
        self.data.fishInventory[tostring(info.fishData.id)],
        info.weight
    )
    self.totalCatch.Value = self.totalCatch.Value + 1
    self.data.totalCatch = self.totalCatch.Value

    if self.data.rarestCatch > info.fishData.baseChance or self.data.rarestCatch == 0 then
        self.rarestCatch.Value = formatChance(info.fishData.baseChance)
        self.data.rarestCatch = info.fishData.baseChance
    end
    self:calculateXP(info)
end
function PlayerInventory:setupEventListener()
    -- local inventoryUI
    -- repeat
    --     inventoryUI = self.inventoryUI
    -- until inventoryUI
    -- local backpackBtn = inventoryUI:WaitForChild("InventoryFrame"):WaitForChild("Backpack")
    -- local backpackTooltip = backpackBtn:WaitForChild("Tooltip")
    -- local fishingRodBtn = inventoryUI:WaitForChild("InventoryFrame"):WaitForChild("FishingRod")
    
    -- self.backpackBtnEnterConnection = backpackBtn.MouseEnter:Connect(function()
	-- 	backpackTooltip.Visible = true
	-- end)
	-- self.backpackBtnLeaveConnection = backpackBtn.MouseLeave:Connect(function()
	-- 	backpackTooltip.Visible = false
	-- end)
	-- self.backpackBtnClickConnection = backpackBtn.MouseButton1Click:Connect(function()
    --     self:toggleInventory()
	-- end)

    -- self.fishingRodBtnClickConnection = fishingRodBtn.MouseButton1Click:Connect(function()
    --     self:toggleRod()
    -- end)
end
function PlayerInventory:new(player)
    local self = setmetatable({}, PlayerInventory)
    self.player = player
    self.inventoryUI = nil
    self.globalUI = nil

    -- self:createInventoryUI()
    -- self:createGlobalUI()
    -- self:setupEventListener()

    -- self:createBackpack()

    self:populateData()
    self:updateFishingRodModel()
    return self
end


-- CLEANUP FUNCTIONS
-- function PlayerInventory:cleanHoldingFish()
--     if self.holdingFish then
--         self.holdingFish:Destroy()
--         self.holdingFish = nil
--     end
--     ClientAnimationEvent:FireClient(self.player, "clean")
-- end


-- CONNECT EVENTS
-- function PlayerInventory:saveData()
--     DataStorage:savePlayerData(self.player, self.data)
-- end
function PlayerInventory:cleanUp()
    -- self:saveData()
    
    
    
    
    -- self.player = nil
end

return PlayerInventory