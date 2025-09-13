-- PlayerInventory.module.lua

local POWER_CATEGORIES = {
	{min = 0, max = 30, name = "Weak", color = Color3.fromRGB(255, 100, 100)},      -- Red
	{min = 31, max = 50, name = "Not Bad", color = Color3.fromRGB(255, 165, 0)},   -- Orange
	{min = 51, max = 70, name = "OK", color = Color3.fromRGB(255, 255, 0)},        -- Yellow
	{min = 71, max = 90, name = "Regular", color = Color3.fromRGB(100, 255, 100)}, -- Green
	{min = 91, max = 100, name = "Professional", color = Color3.fromRGB(100, 100, 255)} -- Blue
}
local RARITY_ORDER = {
	["Classified"] = 7,
	["Mythical"] = 6,
	["Legendary"] = 5,
	["Epic"] = 4,
	["Rare"] = 3,
	["Uncommon"] = 2,
	["Common"] = 1
}
local AUTOSAVE_INTERVAL = 120 -- 2 minutes

local PlayerInventory = {}
PlayerInventory.__index = PlayerInventory

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local DataStorage = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Storage"):WaitForChild("DataStorage"))

local ToolEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")
local ClientAnimationEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClientAnimation")

local FishingRodItem = ReplicatedStorage:WaitForChild("ToolItem"):WaitForChild("FishingRod")
local FishDB = require(FishingRodItem:WaitForChild("FishDB"))
local EquipmentDB = require(FishingRodItem:WaitForChild("EquipmentDB"))


-- HELPER FUNCTIONS
local function scaleWeight(weight)
    local ratio = weight / 50 -- base weight is 50kg
    local factor = ratio^(1/3)
    return 1 * factor
end
local function formatWeight(weight)
	if weight >= 1000 then
		local tons = weight / 1000
		if tons >= 1 and tons < 1000 then
			return string.format("%.1f Ton", tons)
		else
			return string.format("%.0f Tons", tons)
		end
	else
		return string.format("%.1f Kg", weight)
	end
end
local function formatChance(chance)
	-- Convert decimal back to fraction format
	local function gcd(a, b)
		while b ~= 0 do
			a, b = b, a % b
		end
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

	local numerator, denominator = decimalToFraction(chance)
	local divisor = gcd(numerator, denominator)
	numerator = numerator / divisor
	denominator = denominator / divisor

	return string.format("1/%d", denominator)
end
function PlayerInventory:createLeaderstats()
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
    self.money = money

    totalCatch = Instance.new("IntValue")
    totalCatch.Name = "Caught"
    totalCatch.Value = 0
    totalCatch.Parent = leaderstats
    self.totalCatch = totalCatch

    rarestCatch = Instance.new("StringValue")
    rarestCatch.Name = "Rarest Caught"
    rarestCatch.Value = "0"
    rarestCatch.Parent = leaderstats
    self.rarestCatch = rarestCatch

    -- self.totalCatch:GetPropertyChangedSignal("Value"):Connect(function()
    --     DataStorage:updateTotalCatch(self.player, self.totalCatch.Value)
    -- end)
    -- self.money:GetPropertyChangedSignal("Value"):Connect(function()
    --     DataStorage:updateMoney(self.player, self.money.Value)
    -- end)
    -- self.rarestCatch:GetPropertyChangedSignal("Value"):Connect(function()
    --     DataStorage:updateRarestCatch(self.player, self.rarestCatch.Value)
    -- end)
    return leaderstats
end
function PlayerInventory:getRarityColor(rarity, transparency)
	transparency = transparency or 0.3
	local colors = {
		Common = Color3.fromRGB(180, 180, 180),        -- Light Gray - Clean, neutral
		Uncommon = Color3.fromRGB(100, 255, 100),      -- Bright Green - Fresh, nature
		Rare = Color3.fromRGB(100, 150, 255),          -- Bright Blue - Sky blue, calming
		Epic = Color3.fromRGB(200, 100, 255),         -- Purple - Royal, mysterious
		Legendary = Color3.fromRGB(255, 215, 0),      -- Gold - Classic legendary color
		Mythical = Color3.fromRGB(255, 100, 255),     -- Magenta - Mystical, otherworldly
		Classified = Color3.fromRGB(255, 255, 255)    -- White - Pure, secretive
	}
	return colors[rarity] or colors.Common
end


-- UI FUNCTIONS
function PlayerInventory:createInventoryUI()
    local playerGUI = self.player:WaitForChild("PlayerGui")
    if not playerGUI then 
        warn("[PlayerInventory]: No playerGUI found")
        return nil
    end
    local ui = playerGUI:WaitForChild("InventoryUI")
    if not ui then
        warn("[PlayerInventory]: No InventoryUI found")
        return nil
    end
    self.inventoryUI = ui
    self.rodHotBar = ui:WaitForChild("InventoryFrame"):WaitForChild("FishingRod")
    self.fishInventoryTab = ui:WaitForChild("TabContainer"):WaitForChild("ContentArea"):WaitForChild("Fish")
    self.fishTemplate = self.fishInventoryTab:WaitForChild("TemplateFish")
    self.rodInventoryTab = ui:WaitForChild("TabContainer"):WaitForChild("ContentArea"):WaitForChild("Rod")
    self.rodTemplate = self.rodInventoryTab:WaitForChild("TemplateFishingRod")
    return ui
end
function PlayerInventory:createGlobalUI()
    local baitUI = ReplicatedStorage:WaitForChild("Template"):WaitForChild("FishingBaitUI"):Clone()
    baitUI.Parent = self.player.Character.Head
    local powerCategoryUI = ReplicatedStorage:WaitForChild("Template"):WaitForChild("PowerCategoryUI"):Clone()
    powerCategoryUI.Parent = self.player.Character.Head
    self.globalUI = {
        baitUI = baitUI,
        powerCategoryUI = powerCategoryUI
    }
end

function PlayerInventory:showBitUI(visible)
    if not self.globalUI.baitUI then return end
    self.globalUI.baitUI.Frame.Visible = visible
    if not visible then
        if self.baitPulseTween then
            self.baitPulseTween:Cancel()
            self.baitPulseTween = nil
        end
        return
    end
    self.baitPulseTween = TweenService:Create(
        self.globalUI.baitUI.Frame,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.5}
    )
    self.baitPulseTween:Play()
end
function PlayerInventory:showPowerCategoryUI(power)
    if not self.globalUI.powerCategoryUI then return end
	local percentage = math.clamp(power * 100, 0, 100)
	local category = nil
	for _, c in pairs(POWER_CATEGORIES) do
		if percentage >= c.min and percentage <= c.max then
			category = c
			break
		end
	end
	if not category then return end
	self.globalUI.powerCategoryUI.Frame.TextLabel.TextColor3 = category.color
	self.globalUI.powerCategoryUI.Frame.TextLabel.Text = category.name
	self.globalUI.powerCategoryUI.Frame.Visible = true
	task.spawn(function()
		self.powerCategShownTween = TweenService:Create(
			self.globalUI.powerCategoryUI.Frame,
			TweenInfo.new(
				0.3,
				Enum.EasingStyle.Back, 
				Enum.EasingDirection.Out
			),
			{Size = UDim2.new(2, 0, 1, 0)}
		)
		self.powerCategShownTween:Play()
		task.wait(0.6)
		self.powerCategShownTween:Cancel()
        self.powerCategShownTween = nil
		self.powerCategHideTween = TweenService:Create(
			self.globalUI.powerCategoryUI.Frame,
			TweenInfo.new(
				0.6, 
				Enum.EasingStyle.Back, 
				Enum.EasingDirection.Out
			),
			{Size = UDim2.new(0,0,0,0)}
		)
		self.powerCategHideTween:Play()
		self.powerCategHideTween.Completed:Wait()
		self.globalUI.powerCategoryUI.Frame.Visible = false
        self.powerCategHideTween = nil
	end)
end
function PlayerInventory:updateHotBarSelected(toolName)
    if not self.inventoryUI then return end
    local hotbarSlot = self.inventoryUI:FindFirstChild("InventoryFrame"):FindFirstChild(toolName)
    if not hotbarSlot then return end
    local selectedFrame = hotbarSlot:FindFirstChild("SelectedFrame")
    if not selectedFrame then return end
    selectedFrame.Visible = not selectedFrame.Visible
    hotbarSlot.BackgroundTransparency = selectedFrame.Visible and 1 or 0.5
end


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

function PlayerInventory:getEquippedEquipment(type, data)
    return EquipmentDB[type](EquipmentDB, data)
end
function PlayerInventory:updateFishingRodModel()
    local equippedRod, equippedRodTemplate = self:getEquippedEquipment("getRod", self.data.equipment.equippedRod)
    if not equippedRod or not self.fishingRod then return end
    self.fishingRod:FindFirstChild("Handle"):Destroy()
    self.fishingRod:FindFirstChild("Rod"):Destroy()
    local rod = equippedRodTemplate:FindFirstChild("Rod"):Clone()
    local handle = equippedRodTemplate:FindFirstChild("Handle"):Clone()
    rod.Parent = self.fishingRod
    handle.Parent = self.fishingRod
    handle:FindFirstChild("Main").Part1 = rod

    self.rodHotBar.Icon.Image = equippedRod.icon
end

-- INTERACTION FUNCTIONS
function PlayerInventory:holdFishAboveHead(fishName, weight)
    if self.player.Character:FindFirstChildWhichIsA("Tool") then return end
    self:cleanHoldingFish()
    local fish = ReplicatedStorage:WaitForChild("Template"):WaitForChild("Fish"):FindFirstChild(fishName)
    if not fish then
        fish = ReplicatedStorage:WaitForChild("Template"):WaitForChild("Fish"):FindFirstChild("TestFish")
    end
    fish = fish:Clone()
    self.holdingFish = fish
    fish.Body.Anchored = false
    fish.Body.CanCollide = false
    fish.Body.Massless = true
    fish:ScaleTo(scaleWeight(weight))
    fish.Parent = self.player.Character.Head
    fish:SetPrimaryPartCFrame(self.player.Character.Head.CFrame * CFrame.new(0, 2, 0))
    local head2FishAttachment
    if not self.player.Character.Head:FindFirstChild("Head2FishAttachment") then
        head2FishAttachment = Instance.new("Attachment")
        head2FishAttachment.Name = "Head2FishAttachment"
        head2FishAttachment.Parent = self.player.Character.Head
    end
    local fish2HeadAttachment = Instance.new("Attachment")
    fish2HeadAttachment.Name = "Fish2HeadAttachment"
    fish2HeadAttachment.Parent = fish.Body
    local fish2HeadWeld = Instance.new("WeldConstraint")
    fish2HeadWeld.Part0 = fish.Body
    fish2HeadWeld.Part1 = self.player.Character.Head
    fish2HeadWeld.Parent = fish.Body
    ClientAnimationEvent:FireClient(self.player, "holdFishAboveHead")
    -- Fire client event to handle fish holding animation
    -- FishHoldingEvent:FireClient(self.player, {
    --     fishId = fishData.id,
    --     fishName = FishDB:findFish(fishData.id),
    --     weight = fishData.weight,
    --     duration = 3 -- Hold for 3 seconds
    -- })
end

function PlayerInventory:toggleRod()
    self:cleanHoldingFish()
    self:equipTool("FishingRod")
    self:updateHotBarSelected("FishingRod")
end
function PlayerInventory:toggleInventory()
    self.inventoryUI:WaitForChild("TabContainer").Visible = not self.inventoryUI:WaitForChild("TabContainer").Visible
end
function PlayerInventory:setUnequippedReady(bool)
    self.onUnequippedReady = bool
end


-- INVENTORY FUNCTIONS
function PlayerInventory:createBackpack()
    if not self.player:FindFirstChild("Custom Backpack") then
        self.backpack = Instance.new("Folder")
        self.backpack.Name = "Custom Backpack"
        self.backpack.Parent = self.player

        self.fishFolder = Instance.new("Folder")
        self.fishFolder.Name = "Fish"
        self.fishFolder.Parent = self.backpack

        self.toolFolder = Instance.new("Folder")
        self.toolFolder.Name = "Tool"
        self.toolFolder.Parent = self.backpack
    end
    if not self.toolFolder:FindFirstChild("FishingRod") then
        self.fishingRod = FishingRodItem:Clone()
        self.fishingRod.Parent = self.toolFolder
    end
end

function PlayerInventory:refreshTools()
    if not self.toolFolder then return end
    for _, tool in pairs(self.player.Backpack:GetChildren()) do
        tool.Parent = self.toolFolder
    end
end
function PlayerInventory:equipTool(toolName)
    self:refreshTools()
    local tool = self.toolFolder:FindFirstChild(toolName)
    if self.player.Character:FindFirstChildWhichIsA("Tool") then
        ToolEvent:FireClient(self.player, "onUnequipped")
        task.spawn(function()
            while self.onUnequippedReady ~= true do
                task.wait()
            end
            self.player.Character.Humanoid:UnequipTools()
            task.wait()
            self.player.Character.Humanoid:EquipTool(tool)
            while self.player and self.player.Character and not self.player.Character:FindFirstChildWhichIsA("Tool") do
                task.wait()
            end
            ToolEvent:FireClient(self.player, "onEquipped")
            self:setUnequippedReady(false)
        end)
        return
    end
    task.wait()
    self.player.Character.Humanoid:UnequipTools()
    task.wait()
    self.player.Character.Humanoid:EquipTool(tool)
    while not self.player.Character:FindFirstChildWhichIsA("Tool") do
        task.wait()
    end
    ToolEvent:FireClient(self.player, "onEquipped")
end
function PlayerInventory:sortFishInventory()
    local fishList = {}
    for _, fish in pairs(self.fishInventoryTab:GetChildren()) do
        if fish.Name ~= "TemplateFish" and fish:FindFirstChild("FishData") then
            table.insert(fishList, fish)
        end
    end
    table.sort(fishList, function(a, b)
        local aData = a:FindFirstChild("FishData")
		local bData = b:FindFirstChild("FishData")
		if not aData or not bData then return end
		local rarityA = aData.Value:split("|")[2]
		local rarityB = bData.Value:split("|")[2]
		if rarityA ~= rarityB then
			return RARITY_ORDER[rarityA] > RARITY_ORDER[rarityB]
		end
		local idA = tonumber(aData.Value:split("|")[4])
		local idB = tonumber(bData.Value:split("|")[4])
		return idA > idB
    end)
    for i, fish in ipairs(fishList) do
        fish.LayoutOrder = i
    end
end
function PlayerInventory:addFishToInventory(fishDataDB, sort)
    task.spawn(function()
        local fishName, fishData = FishDB:findFish(fishDataDB.id)
        local template = self.fishTemplate:Clone()
        template.Name = fishName
        template.Container.FishText.Text = fishName
        template.Container.FishText.TextColor3 = self:getRarityColor(fishData.rarity)
        template.Container.FishWeight.Text = formatWeight(fishDataDB.weight)
        if fishData.icon then
            template.Container.Icon.Image = fishData.icon
        end
        template.Visible = true
        template.Parent = self.fishInventoryTab

        if self.inventoryFishTween == nil then self.inventoryFishTween = {} end
        local isPressed = false
        local isActive = false
        template.MouseButton1Click:Connect(function()
            if isPressed then return end
            isPressed = true
            local tween = TweenService:Create(
                template.Container,
                TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, true, 0),
                {Size = UDim2.new(.9, 0, .9, 0)}
            )
            tween:Play()
            table.insert(self.inventoryFishTween, tween)
            tween.Completed:Connect(function()
                for i, t in ipairs(self.inventoryFishTween) do
                    if t == tween then
                        table.remove(self.inventoryFishTween, i)
                        break
                    end
                end
                isPressed = false
                tween:Destroy()
            end)
            if isActive and self.holdingFish then
                self:cleanHoldingFish()
            else
                self:holdFishAboveHead(fishName, fishDataDB.weight)
                isActive = true
            end
        end)

        local fishDataValue = Instance.new("StringValue")
        fishDataValue.Name = "FishData"
        fishDataValue.Value = string.format("%s|%s|%.1f|%d",
            fishName,
            fishData.rarity,
            fishDataDB.weight,
            fishDataDB.id)
        fishDataValue.Parent = template
        if sort == nil then
            sort = true
        end
        if sort then
            self:sortFishInventory()
        end
    end)
end
function PlayerInventory:addRodToInventory(rodDataDB, sort)
    task.spawn(function()
        local template = self.rodTemplate:Clone()
        template.Name = rodDataDB.name
        -- template.UIGradient.Transparency = 1 -- add gradient later TODO
        template.Icon.Image = rodDataDB.icon
        template.Visible = true
        template.Parent = self.rodInventoryTab
    end)
end


-- STORAGE FUNCTIONS
function PlayerInventory:populateData()
    self.leaderstats = self:createLeaderstats()
    self.data = DataStorage:loadPlayerData(self.player)
    self.money.Value = self.data.money
    self.totalCatch.Value = self.data.totalCatch
    self.rarestCatch.Value = formatChance(self.data.rarestCatch)
    for id, fish in pairs(self.data.fishInventory) do
        for _, weight in pairs(fish) do
            self:addFishToInventory({
                id = id,
                weight = weight
            }, false)
        end
    end
    self:sortFishInventory()
    for _, rod in pairs(self.data.equipment.ownedRods) do
        local equippedRod, equippedRodTemplate = self:getEquippedEquipment("getRod", rod)
        self:addRodToInventory(equippedRod, false)
    end
    self._autoSaveRunning = true
    task.spawn(function()
        while self._autoSaveRunning do
            task.wait(AUTOSAVE_INTERVAL)
            if not self._autoSaveRunning then break end
            self:saveData()
        end
    end)
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
end
function PlayerInventory:setupEventListener()
    local inventoryUI
    repeat
        inventoryUI = self.inventoryUI
    until inventoryUI
    local backpackBtn = inventoryUI:WaitForChild("InventoryFrame"):WaitForChild("Backpack")
    local backpackTooltip = backpackBtn:WaitForChild("Tooltip")
    local fishingRodBtn = inventoryUI:WaitForChild("InventoryFrame"):WaitForChild("FishingRod")
    
    self.backpackBtnEnterConnection = backpackBtn.MouseEnter:Connect(function()
		backpackTooltip.Visible = true
	end)
	self.backpackBtnLeaveConnection = backpackBtn.MouseLeave:Connect(function()
		backpackTooltip.Visible = false
	end)
	self.backpackBtnClickConnection = backpackBtn.MouseButton1Click:Connect(function()
        self:toggleInventory()
	end)

    self.fishingRodBtnClickConnection = fishingRodBtn.MouseButton1Click:Connect(function()
        self:toggleRod()
    end)
end
function PlayerInventory:new(player)
    local self = setmetatable({}, PlayerInventory)
    self.player = player
    self.inventoryUI = nil
    self.globalUI = nil

    self:createInventoryUI()
    self:createGlobalUI()
    self:setupEventListener()

    self:createBackpack()

    self:populateData()
    self:updateFishingRodModel()
    return self
end


-- CLEANUP FUNCTIONS
function PlayerInventory:cleanHoldingFish()
    if self.holdingFish then
        self.holdingFish:Destroy()
        self.holdingFish = nil
    end
    ClientAnimationEvent:FireClient(self.player, "clean")
end


-- CONNECT EVENTS
function PlayerInventory:saveData()
    DataStorage:savePlayerData(self.player, self.data)
end
function PlayerInventory:cleanUp()
    self:saveData()
    if self.inventoryUI then
        self.inventoryUI:Destroy()
        self.inventoryUI = nil
    end
    if self.globalUI then
        self.globalUI.baitUI:Destroy()
        self.globalUI.powerCategoryUI:Destroy()
        self.globalUI = nil
    end
    if self.backpackBtnEnterConnection then
        self.backpackBtnEnterConnection:Disconnect()
        self.backpackBtnEnterConnection = nil
    end
    if self.backpackBtnLeaveConnection then
        self.backpackBtnLeaveConnection:Disconnect()
        self.backpackBtnLeaveConnection = nil
    end
    if self.backpackBtnClickConnection then
        self.backpackBtnClickConnection:Disconnect()
        self.backpackBtnClickConnection = nil
    end
    if self.fishingRodBtnClickConnection then
        self.fishingRodBtnClickConnection:Disconnect()
        self.fishingRodBtnClickConnection = nil
    end
    if self.baitPulseTween then
        self.baitPulseTween:Cancel()
        self.baitPulseTween = nil
    end
    if self.powerCategShownTween then
        self.powerCategShownTween:Cancel()
        self.powerCategShownTween = nil
    end
    if self.powerCategHideTween then
        self.powerCategHideTween:Cancel()
        self.powerCategHideTween = nil
    end
    if self.fishingRod then
        self.fishingRod:Destroy()
        self.fishingRod = nil
    end
    if self.fishFolder then
        self.fishFolder:Destroy()
        self.fishFolder = nil
    end
    if self.toolFolder then
        self.toolFolder:Destroy()
        self.toolFolder = nil
    end
    if self.backpack then
        self.backpack:Destroy()
        self.backpack = nil
    end
    for _, tween in pairs(self.inventoryFishTween) do
        tween:Cancel()
        tween:Destroy()
    end
    self:cleanHoldingFish()
    self._autoSaveRunning = false
    self.player = nil
end

return PlayerInventory