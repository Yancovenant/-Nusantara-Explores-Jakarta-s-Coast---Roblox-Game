-- Player UI Module

local PUI = {}
PUI.__index = PUI
local DBM = require(script.Parent.Parent.Parent.GlobalStorage)

local TS:TweenService = game:GetService("TweenService")
local RS:ReplicatedStorage = game:GetService("ReplicatedStorage")
local c = require(RS:WaitForChild("GlobalConfig"))

-- MAIN FUNCTIONS
function PUI:UpdateZoneUI(zoneName)
    self.ZoneUI.ZoneText.Text = zoneName
end
function PUI:ToggleInventory()
    local isShown = self.TabContainer.Visible
    if isShown then
        self.TabContainer.Visible = not isShown
        self.ClosedInventoryTween:Play()
        self.ShownHotbarTween:Play()
        self.ShownPlayerInfoTween:Play()
        self.ClosedInventoryTween.Completed:Connect(function()
            self.MockTabContainer.Visible = not isShown
        end)
        self.ShownHotbarTween.Completed:Connect(function()
            self.FishingUI.Enabled = true
        end)
    else
        self.FishingUI.Enabled = false
        self.MockTabContainer.Size = UDim2.new(0,0,0,0)
        self.MockTabContainer.Visible = not isShown
        self.ShownInventoryTween:Play()
        self.ClosedHotbarTween:Play()
        self.ClosedPlayerInfoTween:Play()
        self.ShownInventoryTween.Completed:Connect(function()
            self.TabContainer.Visible = not isShown
        end)
    end
end
function PUI:SortFishInventoryUI()
    task.spawn(function()
        local FishList = {}
        for _, fish in pairs(self.FishInventoryTab:GetChildren()) do
            if fish.Name ~= "TemplateFish" then
                local data = fish:FindFirstChild("FishData")
                if data then
                    local parts = string.split(data.Value, "|")
                    local rarity = parts[2]
                    local id = tonumber(parts[4])
                    table.insert(FishList, {
                        instance = fish,
                        rarity = c.RARITY_ORDER[rarity] or 0,
                        id = id or 0,
                    })
                end
            end
        end
        table.sort(FishList, function(a, b)
            if a.rarity ~= b.rarity then
                return a.rarity > b.rarity
            end
            return a.id > b.id
        end)
        for i, FishData in ipairs(FishList) do
            FishData.instance.LayoutOrder = i
        end
        self.FishTabBtn.Count.Text = #FishList
    end)
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
	task.spawn(function()
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
	end)
end

-- SETUP
function PUI:_SetupTweenAndConnection()
    self.ShownInventoryTween = TS:Create(
        self.MockTabContainer,
        TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut),
        {Size = UDim2.new(0.8, 0, 0.8, 0)}
    )
    self.ClosedInventoryTween = TS:Create(
        self.MockTabContainer,
        TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut
        ),
        {Size = UDim2.new(0, 0, 0, 0)}
    )
    self.ShownHotbarTween = TS:Create(
        self.HotBar,
        TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut),
        {Position = UDim2.new(0.5, 0, 0.875, 0)}
    )
    self.ClosedHotbarTween = TS:Create(
        self.HotBar,
        TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut),
        {Position = UDim2.new(0.5, 0, 1.375, 0)}
    )
    self.ShownPlayerInfoTween = TS:Create(
        self.PlayerInfoUI,
        TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut),
        {Position = UDim2.new(0.25, 0, 1.375, 0)}
    )
    self.ClosedPlayerInfoTween = TS:Create(
        self.PlayerInfoUI,
        TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut),
        {Position = UDim2.new(0.25, 0, 1.375, 0)}
    )

    self.CloseButtonTween = TS:Create(
        self.CloseInvButton,
        TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, true, 0),
        {Size = UDim2.new(.9, 0, .9, 0)}
    )
    local isPressed
    self.CloseInvButton.MouseButton1Click:Connect(function()
        if isPressed then return end
        isPressed = true
        self.CloseButtonTween:Play()
        self:ToggleInventory()
        self.CloseButtonTween.Completed:Connect(function()
            isPressed = false
        end)
    end)

    self.BackpackBtnEnterConnection = self.BackpackBtn.MouseEnter:Connect(function()
		self.BackpackToolTip.Visible = true
	end)
	self.BackpackBtnLeaveConnection = self.BackpackBtn.MouseLeave:Connect(function()
		self.BackpackToolTip.Visible = false
	end)
	self.BackpackBtnClickConnection = self.BackpackBtn.MouseButton1Click:Connect(function()
        self:ToggleInventory()
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
    self.CloseInvButton = self.TabContainer:WaitForChild("CloseButton")
    self.MockTabContainer = self.InventoryUI:WaitForChild("MockTabContainer")
    self.BackpackBtn = self.HotBar:WaitForChild("Backpack")
    self.BackpackToolTip = self.BackpackBtn:WaitForChild("Tooltip")
    self.FishingUI = PlayerGui:WaitForChild("FishingUI")
    
    self:_SetupTweenAndConnection()

    local BaitUI = RS:WaitForChild("Template"):WaitForChild("FishingBaitUI"):Clone()
    BaitUI.Parent = self.player.Character.Head
    local PowerCategoryUI = RS:WaitForChild("Template"):WaitForChild("PowerCategoryUI"):Clone()
    PowerCategoryUI.Parent = self.player.Character.Head
    self.globalUI = {
        BaitUI = BaitUI,
        PowerCategoryUI = PowerCategoryUI
    }

    self.FishTabBtn = self.TabContainer:WaitForChild("TabNavbar"):WaitForChild("FishTabButton")
    self.FishInventoryTab = self.TabContainer:WaitForChild("ContentArea"):WaitForChild("Fish")
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

    if self.ShownInventoryTween then
        self.ShownInventoryTween:Cancel()
        self.ShownInventoryTween = nil
    end
    if self.ClosedInventoryTween then
        self.ClosedInventoryTween:Cancel()
        self.ClosedInventoryTween = nil
    end
    if self.ShownHotbarTween then
        self.ShownHotbarTween:Cancel()
        self.ShownHotbarTween = nil
    end
    if self.ClosedHotbarTween then
        self.ClosedHotbarTween:Cancel()
        self.ClosedHotbarTween = nil
    end
    if self.ShownPlayerInfoTween then
        self.ShownPlayerInfoTween:Cancel()
        self.ShownPlayerInfoTween = nil
    end
    if self.ClosedPlayerInfoTween then
        self.ClosedPlayerInfoTween:Cancel()
        self.ClosedPlayerInfoTween = nil
    end

    if self.CloseButtonTween then
        self.CloseButtonTween:Cancel()
        self.CloseButtonTween = nil
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

    if self.BackpackBtnEnterConnection then
        self.BackpackBtnEnterConnection:Disconnect()
        self.BackpackBtnEnterConnection = nil
    end
    if self.BackpackBtnLeaveConnection then
        self.BackpackBtnLeaveConnection:Disconnect()
        self.BackpackBtnLeaveConnection = nil
    end
    if self.BackpackBtnClickConnection then
        self.BackpackBtnClickConnection:Disconnect()
        self.BackpackBtnClickConnection = nil
    end
    self.player = nil
end

return PUI