-- UIManager.lua

local UserInputService = game:GetService("UserInputService")
local FishingRodDB = require(script.Parent.Parent.Item.FishingRodDB)
local InventoryManager = require(script.Parent.Parent.Inventory.InventoryManager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIManager = {}
local InventoryUIManager = {}
local PlayerUIs = {}
local EquippedStates = {} -- Track equipped state for each player

function UIManager:setVisible(player, key, value, private)
	if private == nil then
		private = true
	end
	local ui = nil
	if private then
		ui = player:WaitForChild("PlayerGui"):WaitForChild("FishingUI"):FindFirstChild(key)
	else
		print("not implemented")
	end
	if not ui then return end
	ui.Visible = value
end
function UIManager:updateText(player, text, ui)
	if ui.Label then
		ui.Label.Text = text
	end
end
function UIManager:updatePowerBar(player, power, ui)
	if ui.Fill then
		ui.Fill.Size = UDim2.new(1, 0, power, 0)
	end
	UIManager:updateText(player, string.format("%d%%", math.floor(power * 100)), ui)
end
function UIManager:updateAttr(player, attr, data, key, private)
	if private == nil then
		private = true
	end
	local ui = nil
	if private then
		ui = player:WaitForChild("PlayerGui"):WaitForChild("FishingUI"):FindFirstChild(key)
	else
		print("not implemented")
	end
	if not ui then return end
	if attr == "power" then
		self:updatePowerBar(player, data, ui)
	elseif attr == "text" then
		self:updateText(player, data, ui)
	elseif attr == "background" then
		if ui.BackgroundColor3 then
			ui.BackgroundColor3 = data
		end
	else
		print("Unknown attribute:", attr)
	end
end
function UIManager:showPopup(player, text, duration)
	local ui = player:WaitForChild("PlayerGui"):WaitForChild("FishingUI")
	if not ui or not ui.popup then return end
	ui.popup.Text = text
	ui.popup.Visible = true
	task.delay(duration or 1.5, function()
		if ui and ui.popup then
			ui.popup.Visible = false
		end
	end)
end



-- function InventoryUIManager:updateSlotAppearance(player, slotName, isEquipped)
-- 	local InventoryUI = player:WaitForChild("PlayerGui"):WaitForChild("InventoryUI")
-- 	if not InventoryUI then return end
-- 	local inventoryFrame = InventoryUI:FindFirstChild("InventoryFrame")
-- 	if not inventoryFrame then return end
-- 	local slot = inventoryFrame:FindFirstChild(slotName)
-- 	if not slot then return end
-- 	local selectedFrame = slot:FindFirstChild("SelectedFrame")
-- 	if not selectedFrame then return end

-- 	if isEquipped then
-- 		slot.BackgroundTransparency = 1
-- 		selectedFrame.Visible = true
-- 	else
-- 		selectedFrame.Visible = false
-- 		slot.BackgroundTransparency = 0.5
-- 	end
-- end

-- function InventoryUIManager:setEquippedState(player, toolName, isEquipped)
-- 	if not EquippedStates[player] then
-- 		EquippedStates[player] = {}
-- 	end

-- 	EquippedStates[player][toolName] = isEquipped
-- 	self:updateSlotAppearance(player, toolName, isEquipped)
-- end

-- function InventoryUIManager:getEquippedState(player, toolName)
-- 	if not EquippedStates[player] then
-- 		EquippedStates[player] = {}
-- 	end
-- 	return EquippedStates[player][toolName] or false
-- end


-- function InventoryUIManager:getRarityColor(rarity, transparency)
-- 	transparency = transparency or 0.3
-- 	print("getting rarity color", rarity)
-- 	local colors = {
-- 		Common = Color3.fromRGB(180, 180, 180),        -- Light Gray - Clean, neutral
-- 		Uncommon = Color3.fromRGB(100, 255, 100),      -- Bright Green - Fresh, nature
-- 		Rare = Color3.fromRGB(100, 150, 255),          -- Bright Blue - Sky blue, calming
-- 		Epic = Color3.fromRGB(200, 100, 255),         -- Purple - Royal, mysterious
-- 		Legendary = Color3.fromRGB(255, 215, 0),      -- Gold - Classic legendary color
-- 		Mythical = Color3.fromRGB(255, 100, 255),     -- Magenta - Mystical, otherworldly
-- 		Classified = Color3.fromRGB(255, 255, 255)    -- White - Pure, secretive
-- 	}
-- 	return colors[rarity] or colors.Common
-- end
local RARITY_ORDER = {
	["Classified"] = 7,
	["Mythical"] = 6,
	["Legendary"] = 5,
	["Epic"] = 4,
	["Rare"] = 3,
	["Uncommon"] = 2,
	["Common"] = 1
}
function InventoryUIManager:sortFishInventory(fishTab)
	local fishList = {}
	for _, fish in pairs(fishTab:GetChildren()) do
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
function InventoryUIManager:addFishToInventory(player, fishData)
	-- local InventoryUI = player:WaitForChild("PlayerGui"):WaitForChild("InventoryUI")
	-- if not InventoryUI then return end
	-- local TabFrame = InventoryUI:WaitForChild("TabContainer"):WaitForChild("ContentArea")
	-- local fishTab = TabFrame:WaitForChild("Fish")
	-- local template = fishTab:WaitForChild("TemplateFish"):Clone()
	-- local rarityColor = self:getRarityColor(fishData.rarity)
	-- template.Name = fishData.name or "Fish"
	-- template.FishText.Text = fishData.name or "Fish"
	-- template.FishText.TextColor3 = rarityColor
	-- template.FishWeight.Text = string.format("%.1fKg", fishData.weight or 0)

	-- template.Visible = true
	-- template.Parent = fishTab
	-- if fishData.icon then
	-- 	template.Icon.Image = fishData.icon
	-- end

	template.MouseEnter:Connect(function()
		print("mouse enter")
		template.BackgroundColor3 = self:getRarityColor(fishData.rarity, 0.8)
	end)

	template.MouseLeave:Connect(function()
		template.BackgroundColor3 = self:getRarityColor(fishData.rarity)
	end)

	-- -- Store fish data
	-- local fishDataValue = Instance.new("StringValue")
	-- fishDataValue.Name = "FishData"
	-- fishDataValue.Value = string.format("%s|%s|%.1f|%d", 
	-- 	fishData.name or "Fish", 
	-- 	fishData.rarity or "Common", 
	-- 	fishData.weight or 0, 
	-- 	fishData.id or 0)
	-- fishDataValue.Parent = template
	-- task.spawn(function()
	-- 	self:sortFishInventory(fishTab)
	-- end)
end

-- function InventoryUIManager:toggleTab(name, container)
-- 	local contentArea = container:WaitForChild("ContentArea")
-- 	local tab = contentArea:WaitForChild(name)
-- 	if not tab then return end
-- 	local allTab = contentArea:GetChildren()
-- 	for _, key in pairs(allTab) do
-- 		key.Visible = false
-- 	end
-- 	tab.Visible = not tab.Visible
-- end
-- function InventoryUIManager:toggle(player)
-- 	local InventoryUI = player:WaitForChild("PlayerGui"):WaitForChild("InventoryUI")
-- 	if not InventoryUI then return end
-- 	local TabFrame = InventoryUI:WaitForChild("TabContainer")
-- 	TabFrame.Visible = not TabFrame.Visible
-- end
-- function InventoryUIManager:toggleRod(player)
-- 	local isCurrentlyEquipped = self:getEquippedState(player, "FishingRod")
-- 	local newState = not isCurrentlyEquipped

-- 	InventoryManager:equipTool("FishingRod", player)
-- 	self:setEquippedState(player, "FishingRod", newState)
-- end

function InventoryUIManager:setupEventListener(player)
	-- local InventoryUI = player:WaitForChild("PlayerGui"):WaitForChild("InventoryUI")
	-- if not InventoryUI then return end
	-- local Frame = InventoryUI:WaitForChild("InventoryFrame")
	-- local backpackBtn = Frame:WaitForChild("Backpack")
	-- local bpTooltip = backpackBtn:WaitForChild("Tooltip")
	-- local rodBtn = Frame:WaitForChild("FishingRod")
	-- -- ## HOTBAR ##
	-- -- backpack
	-- backpackBtn.MouseEnter:Connect(function()
	-- 	bpTooltip.Visible = true
	-- end)
	-- backpackBtn.MouseLeave:Connect(function()
	-- 	bpTooltip.Visible = false
	-- end)
	-- backpackBtn.MouseButton1Click:Connect(function()
	-- 	self:toggle(player)
	-- end)
	-- fishing rod
	-- rodBtn.MouseButton1Click:Connect(function()
	-- 	self:toggleRod(player)
	-- end)

	-- ## TABS ##
	-- local TabFrame = InventoryUI:WaitForChild("TabContainer")
	-- local navbar = TabFrame:WaitForChild("TabNavbar")
	-- local fishTabBtn = navbar:WaitForChild("FishTabButton")
	-- local rodTabBtn = navbar:WaitForChild("RodTabButton")
	-- -- fish tab
	-- fishTabBtn.MouseButton1Click:Connect(function()
	-- 	self:toggleTab("Fish", TabFrame)
	-- end)
	-- -- rod tab
	-- rodTabBtn.MouseButton1Click:Connect(function()
	-- 	self:toggleTab("Rod", TabFrame)
	-- end)

	-- self:setEquippedState(player, "FishingRod", false)
end

-- function UIManager:createFishingUI(player)
-- 	local playerGUI = player:WaitForChild("PlayerGui")
-- 	if not playerGUI then return end
-- 	if playerGUI:WaitForChild("FishingUI") then
-- 		return playerGUI:FindFirstChild("FishingUI")
-- 	end
-- 	warn("[UIManager]: No FishingUI found")
-- 	return nil
-- end

-- function InventoryUIManager:createInventoryUI(player)
-- 	local playerGUI = player:WaitForChild("PlayerGui")
-- 	if not playerGUI then return end
-- 	if playerGUI:WaitForChild("InventoryUI") then
-- 		return playerGUI:FindFirstChild("InventoryUI")
-- 	end
-- 	warn("[InventoryUIManager]: No InventoryUI found")
-- 	return nil
-- end

-- local TweenService = game:GetService("TweenService")
-- local baitPulseTween = nil
-- local powerCategoryPulseTween = nil
-- local POWER_CATEGORIES = {
-- 	{min = 0, max = 30, name = "Weak", color = Color3.fromRGB(255, 100, 100)},      -- Red
-- 	{min = 31, max = 50, name = "Not Bad", color = Color3.fromRGB(255, 165, 0)},   -- Orange
-- 	{min = 51, max = 70, name = "OK", color = Color3.fromRGB(255, 255, 0)},        -- Yellow
-- 	{min = 71, max = 90, name = "Regular", color = Color3.fromRGB(100, 255, 100)}, -- Green
-- 	{min = 91, max = 100, name = "Professional", color = Color3.fromRGB(100, 100, 255)} -- Blue
-- }
-- function UIManager:showBitUI(player, show)
-- 	if show == nil then
-- 		show = true
-- 	end
-- 	local baitUI = player.Character.Head:FindFirstChild("FishingBaitUI")
-- 	if not baitUI then return end
-- 	baitUI.Frame.Visible = show
-- 	if not show then
-- 		if baitPulseTween then
-- 			baitPulseTween:Cancel()
-- 			baitPulseTween = nil
-- 		end
-- 		return
-- 	end
-- 	baitPulseTween = TweenService:Create(
-- 		baitUI.Frame,
-- 		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
-- 		{BackgroundTransparency = 0.5}
-- 	)
-- 	baitPulseTween:Play()
-- end

-- function UIManager:createFishingEffectUI(player)
-- 	local baitUI = ReplicatedStorage:WaitForChild("Template"):WaitForChild("FishingBaitUI"):Clone()
-- 	baitUI.Parent = player.Character.Head
-- 	local powerCategoryUI = ReplicatedStorage:WaitForChild("Template"):WaitForChild("PowerCategoryUI"):Clone()
-- 	powerCategoryUI.Parent = player.Character.Head
-- end

function UIManager:populateFishInventory(player, data)
	local fishDB = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Item"):WaitForChild("FishingRod"):WaitForChild("FishDB"))
	task.spawn(function()
		for id, count in pairs(data.fishCounts) do
			local fishName, fishData = fishDB:findFish(id)
			if fishData then
				for i = 1, count do
					local data = {
						id = fishData.id,
						name = fishName,
						rarity = fishData.rarity,
						weight = data.fishWeights[id][i],
						icon = fishData.icon
					}
					InventoryUIManager:addFishToInventory(player, data)
				end
			end
		end
	end)
end
function UIManager:setupPlayer(player)
	self:createFishingUI(player)
	self:createFishingEffectUI(player)
	InventoryUIManager:createInventoryUI(player)
	InventoryUIManager:setupEventListener(player)
	if not game:GetService("RunService"):IsServer() then
		warn("skipping data setup on client")
		return
	end
	local DataStorage = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Storage"):WaitForChild("DataStorage"))
	DataStorage:onDataReady(player, function(player, data)
		self:populateFishInventory(player, data)
	end)
end

function UIManager:init()
	print("init UIManager")
end


UIManager.Inv = InventoryUIManager
return UIManager
