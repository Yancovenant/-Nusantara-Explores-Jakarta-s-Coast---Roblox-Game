-- PlayerInventory.module.lua

local PlayerInventory = {}


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

return PlayerInventory