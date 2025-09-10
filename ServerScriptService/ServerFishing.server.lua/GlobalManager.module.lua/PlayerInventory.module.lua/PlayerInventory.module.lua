-- PlayerInventory.module.lua

local POWER_CATEGORIES = {
	{min = 0, max = 30, name = "Weak", color = Color3.fromRGB(255, 100, 100)},      -- Red
	{min = 31, max = 50, name = "Not Bad", color = Color3.fromRGB(255, 165, 0)},   -- Orange
	{min = 51, max = 70, name = "OK", color = Color3.fromRGB(255, 255, 0)},        -- Yellow
	{min = 71, max = 90, name = "Regular", color = Color3.fromRGB(100, 255, 100)}, -- Green
	{min = 91, max = 100, name = "Professional", color = Color3.fromRGB(100, 100, 255)} -- Blue
}

local PlayerInventory = {}
PlayerInventory.__index = PlayerInventory

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FishingRodItem = ReplicatedStorage:WaitForChild("ToolItem"):WaitForChild("FishingRod")

-- UI FUNCTIONS
function PlayerInventory:createInventoryUI(player)
    local playerGUI = player:WaitForChild("PlayerGui")
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
    return ui
end
function PlayerInventory:createGlobalUI(player)
    local baitUI = ReplicatedStorage:WaitForChild("Template"):WaitForChild("FishingBaitUI"):Clone()
    baitUI.Parent = player.Character.Head
    local powerCategoryUI = ReplicatedStorage:WaitForChild("Template"):WaitForChild("PowerCategoryUI"):Clone()
    powerCategoryUI.Parent = player.Character.Head
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

-- INTERACTION FUNCTIONS
function PlayerInventory:toggleRod(player)
    print("toggleRod", player.Name, "self.player", self.player.Name)
end


-- INVENTORY FUNCTIONS
function PlayerInventory:createBackpack(player)
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


-- MAIN FUNCTIONS
function PlayerInventory:setupEventListener(player)
    local inventoryUI
    repeat
        inventoryUI = self.inventoryUI
    until inventoryUI
    local backpackBtn = inventoryUI:WaitForChild("InventoryFrame"):WaitForChild("Backpack")
    local backpackTooltip = backpackBtn:WaitForChild("Tooltip")
    local fishingRodBtn = inventoryUI:WaitForChild("InventoryFrame"):WaitForChild("FishingRod")
    local tabContainer = inventoryUI:WaitForChild("TabContainer")
    local fishTabBtn = tabContainer:WaitForChild("TabNavbar"):WaitForChild("FishTabButton")
    local rodTabBtn = tabContainer:WaitForChild("TabNavbar"):WaitForChild("RodTabButton")
    local pageContainer = tabContainer:WaitForChild("ContentArea")
    local fishPageFrame = pageContainer:WaitForChild("Fish")
    local rodPageFrame = pageContainer:WaitForChild("Rod")
    
    self.backpackBtnEnterConnection = backpackBtn.MouseEnter:Connect(function()
		backpackTooltip.Visible = true
	end)
	self.backpackBtnLeaveConnection = backpackBtn.MouseLeave:Connect(function()
		backpackTooltip.Visible = false
	end)
	self.backpackBtnClickConnection = backpackBtn.MouseButton1Click:Connect(function()
        tabContainer.Visible = not tabContainer.Visible
	end)

    self.fishingRodBtnClickConnection = fishingRodBtn.MouseButton1Click:Connect(function()
        self:toggleRod(player)
    end)

    -- INVENTORY TABS
    -- TODO : ADD Design on tab buttons when clicked/page change animations
    local pageLayout = pageContainer:FindFirstChildWhichIsA("UIPageLayout")
    self.fishTabBtnClickConnection = fishTabBtn.MouseButton1Click:Connect(function()
        pageLayout:JumpTo(fishPageFrame)
    end)
    self.rodTabBtnClickConnection = rodTabBtn.MouseButton1Click:Connect(function()
        pageLayout:JumpTo(rodPageFrame)
    end)

    
end
function PlayerInventory:new(player)
    local self = setmetatable({}, PlayerInventory)
    self.player = player
    self.inventoryUI = nil
    self.globalUI = nil

    self:createInventoryUI(player)
    self:createGlobalUI(player)
    self:setupEventListener(player)

    self:createBackpack()
    return self
end

-- CONNECT EVENTS
function PlayerInventory:cleanUp()
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
    self.player = nil
end

return PlayerInventory