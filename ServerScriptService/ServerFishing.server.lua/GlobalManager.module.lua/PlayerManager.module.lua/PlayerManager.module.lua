-- PlayerManager.module.lua

local PM = {}
PM.__index = PM
local PINV = require(script.Inventory)
local PUI = require(script.UI)
local DBM = require(script.Parent.Parent.GlobalStorage)

local RS:ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientUIEvent:RemoteEvent = RS:WaitForChild("Remotes"):WaitForChild("ClientEvents"):WaitForChild("UIEvent")

local c = require(RS:WaitForChild("GlobalConfig"))


-- HELPER
local function contains(tbl:table, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

function PM:_FormatChance(ch)
    -- Convert decimal back to fraction format
	local function gcd(a, b)
		while b ~= 0 do a, b = b, a % b end
		return a
	end
	local function decimalToFraction(decimal)
		local tolerance = 1e-6
		local h1, h2, k1, k2 = 1, 0, 0, 1
		local x = decimal
		while math.abs(x - math.floor(x + 0.5)) > tolerance do
			x = 1 / (x - math.floor(x))
			h1, h2 = h1 * math.floor(x) + h2, h1
			k1, k2 = k1 * math.floor(x) + k2, k1
		end
		return math.floor(x + 0.5) * h1 + h2, h1
	end
	local numerator, denominator = decimalToFraction(ch)
	local divisor = gcd(numerator, denominator)
	numerator = numerator / divisor
	denominator = denominator / divisor
	return string.format("1/%d", denominator)
end


-- PLAYER PROGRESSION
function PM:_CalculateXP(info)
    local multi = c.RARITY_MULTIXP[info.fishData.rarity]
    local xp = (info.weight ^ 0.75) * multi
    return xp
end
--
function PM:_XPRequiredForLevel(level)
    return math.floor(c.PLAYER.XPGROWTH.BASE_XP * (level ^ c.PLAYER.XPGROWTH.GROWTH))
end
function PM:_GetLevelFromXP(xp)
    local level = 1
    while xp >= self:_XPRequiredForLevel(level) do
        xp -= self:_XPRequiredForLevel(level)
        level += 1
    end
    return level, xp, self:_XPRequiredForLevel(level)
end
function PM:_UpdateXP(GainedXp)
    self.Data.PlayerXP += GainedXp
    local Lvl, CurrentXP, RequiredXP = self:_GetLevelFromXP(self.Data.PlayerXP)
    if self.Data.PlayerLevel < Lvl then
        print("OnLevelUp")
        self.Data.PlayerLevel = Lvl
        self.PUI:UpdateLevel(self.Data.PlayerLevel)
        -- need to update data.playerlevel
    end
    ClientUIEvent:FireClient(self.player, "UpdateXP", self.Data.PlayerLevel, CurrentXP, RequiredXP, GainedXp)
end
function PM:_UpdateMoney(value)
    value = value or 0
    self.Data.Money += value
    self.Money.Value = self.Data.Money
    ClientUIEvent:FireClient(self.player, "UpdateMoney", self.Data.Money, value)
end
function PM:_RefreshBuyShop()
    local AllRod = c.EQUIPMENT.GED.RODS
    for rodName, rodData in pairs(AllRod) do
        if not contains(self.Data.Equipment.OwnedRods, rodData.id) then
            local template = self.PUI.BuyTemplateItem:Clone()
            template.Name = rodName
            template.Label.Text = rodName
            template.Icon.Image = rodData.icon
            template.Price.Text = math.floor(rodData.price)
            template.Visible = true
            template.Parent = self.PUI.BuyFrame
        end
    end
end

-- MAIN FUNCTIONS
--- Proximity
function PM:ToggleFishShopUI(GRM, ...)
    local isShown = self.PUI.FishShopTab.Visible
    self.PUI:ToggleFishShopUI(not isShown, ...)
    if self.PUI.FishShopTab.Visible then
        -- populate buy tab
        self:_RefreshBuyShop()
        ClientUIEvent:FireClient(self.player, "SortFishShopUI")
        -- calculate price
        for _, fish in pairs(self.PUI.FishShopTab.RightPanel.ContentArea.Sell.ScrollingFrame:GetChildren()) do
            if fish.Name ~= "TemplateItem" and fish:IsA("Frame") then
                local finalPrice = GRM:FishValue(fish)
                fish:SetAttribute("price", finalPrice)
                fish.Price.Text = math.floor(finalPrice)
            end
        end
    end
end

function PM:updatePlayerZone(zone)
    self.PUI:UpdateZoneUI(zone)
end
function PM:ToggleRod()
    self.PINV:_CleanHoldingFish()
    self.PINV:_EquipTool("FishingRod")
    self.PINV:ToggleHolsterRod()
    self.PUI:_UpdateHotBarSelected("FishingRod")
end
function PM:ToggleInventory()
    self.PUI:ToggleInventory()
end
function PM:UnEquippedReady(bool)
    self.PINV:UnEquippedReady(bool)
end
function PM:ShowFishBiteUI(visible)
    self.PUI:ShowFishBiteUI(visible)
end
function PM:ShowPowerCategoryUI(power)
    self.PUI:ShowPowerCategoryUI(power)
end
function PM:CatchResultSuccess(info)
    local FishInvFrame, FishShopFrame = self.PINV:AddFishToInventory({
        id = info.fishData.id,
        weight = info.weight,
    }, true)
    if self.Data.FishInventory[tostring(info.fishData.id)] == nil then
        self.Data.FishInventory[tostring(info.fishData.id)] = {}
    end
    table.insert(self.Data.FishInventory[tostring(info.fishData.id)], {
        weight = info.weight,
        locked = false,
        uniqueId = self.PINV.FishCounter
    })
    if self.FishFrame[tostring(self.PINV.FishCounter)] == nil then
        self.FishFrame[tostring(self.PINV.FishCounter)] = {
            FishInvFrame = FishInvFrame,
            FishShopFrame = FishShopFrame
        }
    end
    -- loop wrapper leaderstats + data
    self.TotalCatch.Value = self.TotalCatch.Value + 1
    self.Data.TotalCatch = self.TotalCatch.Value

    if self.Data.RarestCatch > info.fishData.baseChance or self.Data.RarestCatch == 0 then
        self.RarestCatch.Value = self:_FormatChance(info.fishData.baseChance)
        self.Data.RarestCatch = info.fishData.baseChance
    end
    local GainedXp = self:_CalculateXP(info)
    self:_UpdateXP(GainedXp)
end

function PM:SaveData(locksession, force)
    DBM:SaveDataPlayer(self.player, self.Data, locksession, force)
end

-- SETUP FUNCTIONS
function PM:_SetupEventListener()
    self.FishingRodBtnClickConnection = self.PINV.FishingRodBtn.MouseButton1Click:Connect(function()
        self:ToggleRod()
    end)
    self.PUI.SellAllBtn.MouseButton1Click:Connect(function()
        local totalValue = 0
        for _, fish in pairs(self.PUI.FishShopTab.RightPanel.ContentArea.Sell.ScrollingFrame:GetChildren()) do
            if fish.Name ~= "TemplateItem" and fish:IsA("Frame") then
                local locked = fish:GetAttribute("locked")
                if not locked then
                    local price = fish:GetAttribute("price") or 0
                    local fishId = fish:GetAttribute("id")
                    local weight = fish:GetAttribute("weight")
                    local uniqueId = fish:GetAttribute("uniqueId")
                    totalValue += price
                    local FishInventoryTable = self.Data.FishInventory[tostring(fishId)]
                    if FishInventoryTable ~= nil then
                        for i, dWeight in ipairs(FishInventoryTable) do
                            if type(dWeight) == "table" then
                                if dWeight.uniqueId == uniqueId then
                                    table.remove(FishInventoryTable, i)
                                end
                            else
                                if dWeight == weight then
                                    table.remove(FishInventoryTable, i)
                                end
                            end
                        end
                        if #self.Data.FishInventory[tostring(fishId)] == 0 then
                            self.Data.FishInventory[tostring(fishId)] = nil
                        end
                    end
                    if self.FishFrame[tostring(uniqueId)] ~= nil then
                        for _, frame in pairs(self.FishFrame[tostring(uniqueId)]) do
                            frame:Destroy()
                        end
                    end
                end
            end
        end
        
        -- Update player money
        self:_UpdateMoney(totalValue)
        
        -- Update UI counts
        self.PUI:SortFishInventoryUI()
        
    end)
end
function PM:_CreateLeaderstats()
    local leaderstats
    if not self.player:FindFirstChild("leaderstats") then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = self.player
    else
        leaderstats = self.player:WaitForChild("leaderstats")
    end
    local money, totalCatch, rarestCatch
    money = Instance.new("IntValue")
    money.Name = "Money"
    money.Value = 0
    money.Parent = leaderstats
    self.Money = money

    totalCatch = Instance.new("IntValue")
    totalCatch.Name = "Caught"
    totalCatch.Value = 0
    totalCatch.Parent = leaderstats
    self.TotalCatch = totalCatch

    rarestCatch = Instance.new("StringValue")
    rarestCatch.Name = "Rarest Caught"
    rarestCatch.Value = "0"
    rarestCatch.Parent = leaderstats
    self.RarestCatch = rarestCatch
    -- end)
    return leaderstats
end
function PM:_SetupPlayerAttributes()
    local GED = c.EQUIPMENT.GED
    local EquippedRod = self.Data.Equipment.EquippedRod
    local dataRod, modelRod = self.PINV:GetEquipmentData("GetRod", EquippedRod)
    self.Data.Attributes = {
        maxWeight = dataRod.maxWeight
    }
end
function PM:_PopulateData()
    self.Leaderstats = self:_CreateLeaderstats()
    self.Data = DBM:LoadDataPlayer(self.player)
    
    self.TotalCatch.Value = self.Data.TotalCatch
    self.RarestCatch.Value = self:_FormatChance(self.Data.RarestCatch)
    
    -- batching populate fish
    local fishArray = {}
    for id, weights in pairs(self.Data.FishInventory) do
        for _, weight in pairs(weights) do
            if type(weight) == "table" then
                table.insert(fishArray, {
                    id = id,
                    weight = weight.weight,
                    locked = weight.locked
                })
                weight.uniqueId = 0
            else
                table.insert(fishArray, {
                    id = id,
                    weight = weight,
                })
            end
        end
    end
    local batchSize = 50
    task.spawn(function()
        for i = 1, #fishArray, batchSize do
            for j = i, math.min(i + batchSize - 1, #fishArray) do
                local fishData = fishArray[j]
                local FishInvFrame, FishShopFrame = self.PINV:AddFishToInventory(fishData, false)
                if self.Data.FishInventory[tostring(fishData.id)] then
                    for _, weight in self.Data.FishInventory[tostring(fishData.id)] do
                        if type(weight) == "table" then
                            if fishData.weight == weight.weight and weight.uniqueId == 0 and weight.locked == fishData.locked then
                                weight.uniqueId = self.PINV.FishCounter
                            end
                        end
                    end
                end
                if self.FishFrame[tostring(self.PINV.FishCounter)] == nil then
                    self.FishFrame[tostring(self.PINV.FishCounter)] = {
                        FishInvFrame = FishInvFrame,
                        FishShopFrame = FishShopFrame
                    }
                end
            end
            task.wait()
        end
        self.PUI:SortFishInventoryUI()
    end)
    -- end fish batch populating

    self:_SetupPlayerAttributes()
    self.PUI:UpdateLevel(self.Data.PlayerLevel)
    self:_UpdateXP(0)
    self:_UpdateMoney(0)
    
    for _, rod in pairs(self.Data.Equipment.OwnedRods) do
        local RodData:table, RodModel:Model = self.PINV:GetEquipmentData("GetRod", rod)
        self.PINV:AddRodToInventory(RodData, false)
    end
    self._AutoSaveRunning = true
    task.spawn(function()
        while self._AutoSaveRunning do
            task.wait(c.PLAYER.AUTOSAVE_INTERVAL)
            if not self._AutoSaveRunning then break end
            self:SaveData(true)
        end
    end)
end
function PM:_UpdateFishingRodModel()
    local RodData, RodModel = self.PINV:GetEquipmentData("GetRod", self.Data.Equipment.EquippedRod)
    if not RodData or not self.PINV.FishingRod then return end
    self.PINV.FishingRod:FindFirstChild("Handle"):Destroy()
    self.PINV.FishingRod:FindFirstChild("Rod"):Destroy()
    local Rod = RodModel:FindFirstChild("Rod"):Clone()
    local handle = RodModel:FindFirstChild("Handle"):Clone()
    Rod.Parent = self.PINV.FishingRod
    handle.Parent = self.PINV.FishingRod
    handle:FindFirstChild("Main").Part1 = Rod

    self.PUI.RodHotBar.Icon.Image = RodData.icon
    self.PINV:CreateHolsterRodAccessory(RodModel)
end

-- ENTRY POINTS
function PM:new(player)
    local self = setmetatable({}, PM)
    self.player = player
    self.currentZone = nil
    self.PUI = PUI:new(player)
    self.PINV = PINV:new(player, self.PUI)
    self:_SetupEventListener()
    
    self.FishFrame = {
        -- EXAMPLE
        -- uniqueId = {
        --     FishInvFrame = nil,
        --     FishShopFrame = nil,
        --     fish = nil
        -- }
    }
    self:_PopulateData()
    self:_UpdateFishingRodModel()
    self.PINV:ToggleHolsterRod()
    return self
end
function PM:CleanUp()
    self._autoSaveRunning = false
    self:SaveData(false, true)
    if self.FishingRodBtnClickConnection then
        self.FishingRodBtnClickConnection:Disconnect()
        self.FishingRodBtnClickConnection = nil
    end
    self.PUI:CleanUp()
    self.PINV:CleanUp()
    self.PUI = nil
    self.PINV = nil
    self.player = nil
end

-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:WrapModule(PM, "PlayerManagers")


return PM