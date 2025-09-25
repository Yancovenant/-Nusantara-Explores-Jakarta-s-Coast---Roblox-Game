-- Player UI Module

local PUI = {}
PUI.__index = PUI
local DBM = require(script.Parent.Parent.Parent.GlobalStorage)

local TS:TweenService = game:GetService("TweenService")
local RS:ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientUIEvent:RemoteEvent = RS:WaitForChild("Remotes"):WaitForChild("ClientEvents"):WaitForChild("UIEvent")

local c = require(RS:WaitForChild("GlobalConfig"))

-- MAIN FUNCTIONS
--- Proximity
function PUI:ToggleFishShopUI(bool:boolean, part:Part)
    self.FishShopTab.Visible = bool
    task.spawn(function()
        while self.FishShopTab.Visible do
            if not self.player or not self.player.Character or not self.player.Character:FindFirstChild("HumanoidRootPart") then
                break
            end
            local dist = (self.player.Character.HumanoidRootPart.Position - part.Position).Magnitude
            if dist > 10 then
                self.FishShopTab.Visible = false
                for _, UI in pairs(self.player.PlayerGui:GetChildren()) do
                    if UI.Name == "BackdropUI" then
                        UI.Enabled = false
                    else
                        UI.Enabled = true
                    end
                end
                break
            end
            task.wait(0.5)
        end
    end)
    if self.FishShopTab.Visible then
        for _, UI in pairs(self.player.PlayerGui:GetChildren()) do
            if UI.Name == "Freecam" or UI.Name == "FishShopUI" or UI.Name == "BackdropUI" then
                UI.Enabled = true
            else
                UI.Enabled = false
            end
        end
    else
        for _, UI in pairs(self.player.PlayerGui:GetChildren()) do
            if UI.Name == "BackdropUI" then
                UI.Enabled = false
            else
                UI.Enabled = true
            end
        end
    end
end
function PUI:UpdateZoneUI(zoneName)
    self.ZoneUI.ZoneText.Text = zoneName
end
function PUI:ToggleInventory()
    ClientUIEvent:FireClient(self.player, "ToggleInventory")
end
function PUI:SortRodInventoryUI()
    for _, Rod in pairs(self.RodInventoryTab:GetChildren()) do
        if Rod.Name ~= "TemplateFishingRod" and Rod:IsA("TextButton") then
            if Rod:GetAttribute("id") == self.Data.Equipment.EquippedRod then
                Rod.SelectedFrame.Visible = true
            else
                Rod.SelectedFrame.Visible = false
            end
        end
    end
    ClientUIEvent:FireClient(self.player, "SortRodInventoryUI")
end
function PUI:SortFishInventoryUI()
    ClientUIEvent:FireClient(self.player, "SortFishInventoryUI")
end
function PUI:_UpdateHotBarSelected(toolName:string)
    if not self.InventoryUI then return end
    local HotbarSlot = self.InventoryUI:FindFirstChild("InventoryFrame"):FindFirstChild(toolName)
    if not HotbarSlot then return end
    local SelectedFrame = HotbarSlot:FindFirstChild("SelectedFrame")
    if not SelectedFrame then return end
    SelectedFrame.Visible = not SelectedFrame.Visible
    HotbarSlot.BackgroundTransparency = SelectedFrame.Visible and 1 or 0.5
end
function PUI:ShowFishBiteUI(visible:boolean)
    if not self.globalUI.BaitUI then return end
    self.globalUI.BaitUI.Frame.Visible = visible
    if not visible then
        if self.BaitPulseTween then
            self.BaitPulseTween:Cancel()
            self.BaitPulseTween = nil
        end
        return
    end
    self.BaitPulseTween = TS:Create(
        self.globalUI.BaitUI.Frame,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.5}
    )
    self.BaitPulseTween:Play()
end
function PUI:ShowPowerCategoryUI(power)
    if not self.globalUI.PowerCategoryUI then return end
	local percentage = math.clamp(power * 100, 0, 100)
	local category = nil
	for _, cat in pairs(c.FISHING.POWER_CATEGORIES) do
		if percentage >= cat.min and percentage <= cat.max then
			category = cat
			break
		end
	end
	if not category then return end
	self.globalUI.PowerCategoryUI.Frame.TextLabel.TextColor3 = category.color
	self.globalUI.PowerCategoryUI.Frame.TextLabel.Text = category.name
	self.globalUI.PowerCategoryUI.Frame.Visible = true
	
	-- FIXED: Store task reference for proper cleanup
	self.PowerCategoryTask = task.spawn(function()
		self.PowerCategShownTween = TS:Create(
			self.globalUI.PowerCategoryUI.Frame,
			TweenInfo.new(
				0.3,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			),
			{Size = UDim2.new(2, 0, 1, 0)}
		)
		self.PowerCategShownTween:Play()
		task.wait(0.6)
		self.PowerCategShownTween:Cancel()
        self.PowerCategShownTween = nil
		self.PowerCategHideTween = TS:Create(
			self.globalUI.PowerCategoryUI.Frame,
			TweenInfo.new(
				0.6,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			),
			{Size = UDim2.new(0,0,0,0)}
		)
		self.PowerCategHideTween:Play()
		self.PowerCategHideTween.Completed:Wait()
		self.globalUI.PowerCategoryUI.Frame.Visible = false
        self.PowerCategHideTween = nil
        self.PowerCategoryTask = nil
	end)
end
function PUI:UpdateLevel(Level)
    self.globalUI.LevelUI.Frame.Text.Text = "Lv. " .. tostring(Level)
end
function PUI:TogglePlayerModal(...)
    ClientUIEvent:FireClient(self.player, "TogglePlayerModal", ...)
end

-- SETUP
function PUI:_SetupTweenAndConnection()
    self.FishShopCloseBtn.MouseButton1Click:Connect(function()
        self:ToggleFishShopUI()
    end)

    self.IsLocking = false
    self.LockBtnClickConnection = self.LockBtn.MouseButton1Click:Connect(function()
        self.IsLocking = not self.IsLocking
        if self.IsLocking then
            self.LockBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 60)
            self.LockBtn.Frame.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
        else
            self.LockBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
            self.LockBtn.Frame.BackgroundColor3 = Color3.fromRGB(195, 0, 0)
        end
    end)
end
function PUI:_CreatePlayerUI()
    local PlayerGui = self.player:WaitForChild("PlayerGui")
    self.TopBarUI = PlayerGui:WaitForChild("TopBarUI")
    self.ZoneUI = self.TopBarUI:WaitForChild("Zone")
    self.InventoryUI = PlayerGui:WaitForChild("InventoryUI")
    self.HotBar = self.InventoryUI:WaitForChild("InventoryFrame")
    self.PlayerInfoUI = self.InventoryUI:WaitForChild("PlayerInfo")
    self.TabContainer = self.InventoryUI:WaitForChild("TabContainer")
    self.RodInventoryTab = self.TabContainer:WaitForChild("ContentArea"):FindFirstChild('Rod')

    self.StatBarBtn = self.HotBar.Player

    self.FishShopUI = PlayerGui:WaitForChild("FishShopUI")
    self.FishShopTab = self.FishShopUI:WaitForChild("ShopTabContainer")
    self.FishShopCloseBtn = self.FishShopTab:WaitForChild("CloseButton")
    self.SellAllBtn = self.FishShopTab.RightPanel.ContentArea.Sell.ActionButton.SellAll
    self.ActionButton = self.InventoryUI.ActionButton
    self.LockBtn = self.ActionButton.LockBtn
    self.BuyPage = self.FishShopTab.RightPanel.ContentArea.Buy
    self.BuyFrame = self.BuyPage.ScrollingFrame
    self.BuyTemplateItem = self.BuyFrame.TemplateItem
    self.BuySelectedButton = self.BuyPage.ActionButton.BuySelected
    self.BuySelectedTotalLabel = self.BuyPage.ActionButton.Total.Label
    self.SellPage = self.FishShopTab.RightPanel.ContentArea.Sell
    self.SellFrame = self.SellPage.ScrollingFrame
    self.SellSelectedButton = self.SellPage.ActionButton.SellSelected
    self.SellSelectedTotalLabel = self.SellPage.ActionButton.Total.Label

    self:_SetupTweenAndConnection()

    local BaitUI = RS:WaitForChild("Template"):WaitForChild("FishingBaitUI"):Clone()
    BaitUI.Parent = self.player.Character.Head
    local PowerCategoryUI = RS:WaitForChild("Template"):WaitForChild("PowerCategoryUI"):Clone()
    PowerCategoryUI.Parent = self.player.Character.Head
    local LevelUI = RS:WaitForChild("Template"):WaitForChild("LevelUI"):Clone()
    LevelUI.Parent = self.player.Character.Head
    self.globalUI = {
        BaitUI = BaitUI,
        PowerCategoryUI = PowerCategoryUI,
        LevelUI = LevelUI
    }

    self.FishTabBtn = self.TabContainer:WaitForChild("TabNavbar"):WaitForChild("FishTabButton")
    self.FishInventoryTab = self.TabContainer:WaitForChild("ContentArea"):WaitForChild("Fish")
    self.FishGridLayout = self.FishInventoryTab:FindFirstChildWhichIsA("UIGridLayout")
    self.RodHotBar = self.HotBar:WaitForChild("FishingRod")
end

-- ENTRY POINTS
function PUI:new(player)
    local self = setmetatable({}, PUI)
    self.player = player
    self.Data = DBM:LoadDataPlayer(self.player)
    self:_CreatePlayerUI()
    return self
end

-- CLEANING
function PUI:CleanUp()
    if self.InventoryUI then
        self.InventoryUI:Destroy()
        self.InventoryUI = nil
    end
    if self.globalUI then
        self.globalUI.BaitUI:Destroy()
        self.globalUI.PowerCategoryUI:Destroy()
        self.globalUI = nil
    end

    if self.BaitPulseTween then
        self.BaitPulseTween:Cancel()
        self.BaitPulseTween = nil
    end
    if self.PowerCategShownTween then
        self.PowerCategShownTween:Cancel()
        self.PowerCategShownTween = nil
    end
    if self.PowerCategHideTween then
        self.PowerCategHideTween:Cancel()
        self.PowerCategHideTween = nil
    end
    -- FIXED: Clean up power category task
    if self.PowerCategoryTask then
        task.cancel(self.PowerCategoryTask)
        self.PowerCategoryTask = nil
    end

    if self.LockBtnClickConnection then
        self.LockBtnClickConnection:Disconnect()
        self.LockBtnClickConnection = nil
    end
    self.player = nil
end


-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:WrapModule(PUI, "PlayerUI")


return PUI