-- Player UI Module

local PUI = {}
PUI.__index = PUI

local StarterPlayer = game:GetService("StarterPlayer")
local TS:TweenService = game:GetService("TweenService")
local RS:ReplicatedStorage = game:GetService("ReplicatedStorage")

-- MAIN FUNCTIONS
function PUI:UpdateZoneUI(zoneName)
    self.ZoneUI.ZoneText.Text = zoneName
end
function PUI:ToggleInventory()
    local isShown = self.tabContainer.Visible
    if isShown then
        self.tabContainer.Visible = not isShown
        self.closedInventoryTween:Play()
        self.ShownHotbarTween:Play()
        self.closedInventoryTween.Completed:Connect(function()
            self.mockTabContainer.Visible = not isShown
        end)
        self.ShownHotbarTween.Completed:Connect(function()
            self.FishingUI.Enabled = true
        end)
    else
        self.FishingUI.Enabled = false
        self.mockTabContainer.Size = UDim2.new(0,0,0,0)
        self.mockTabContainer.Visible = not isShown
        self.ShownInventoryTween:Play()
        self.closedHotbarTween:Play()
        self.ShownInventoryTween.Completed:Connect(function()
            self.tabContainer.Visible = not isShown
        end)
    end
end


-- SETUP
function PUI:_SetupTweenAndConnection()
    self.ShownInventoryTween = TS:Create(
        self.MockTabContainer,
        TweenInfo.new(
            0.3,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.InOut
        ),
        {Size = UDim2.new(0.8, 0, 0.8, 0)}
    )
    self.ClosedInventoryTween = TS:Create(
        self.MockTabContainer,
        TweenInfo.new(
            0.3,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.InOut
        ),
        {Size = UDim2.new(0, 0, 0, 0)}
    )
    self.ShownHotbarTween = TS:Create(
        self.HotBar,
        TweenInfo.new(
            0.3,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.InOut
        ),
        {Position = UDim2.new(0.5, 0, 0.875, 0)}
    )
    self.ClosedHotbarTween = TS:Create(
        self.HotBar,
        TweenInfo.new(
            0.3,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.InOut
        ),
        {Position = UDim2.new(0.5, 0, 1.375, 0)}
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
		self.BackpackTooltip.Visible = true
	end)
	self.BackpackBtnLeaveConnection = self.BackpackBtn.MouseLeave:Connect(function()
		self.BackpackTooltip.Visible = false
	end)
	self.BackpackBtnClickConnection = self.BackpackBtn.MouseButton1Click:Connect(function()
        self:ToggleInventory()
	end)

    self.FishingRodBtnClickConnection = self.FishingRodBtn.MouseButton1Click:Connect(function()
        self:ToggleRod()
    end)
end
function PUI:_CreatePlayerUI()
    local PlayerGui = self.player:WaitForChild("PlayerGui")
    self.TopBarUI = PlayerGui:WaitForChild("TopBarUI")
    self.ZoneUI = self.TopBarUI:WaitForChild("Zone")
    self.InventoryUI = PlayerGui:WaitForChild("InventoryUI")
    self.HotBar = self.InventoryUI:WaitForChild("InventoryFrame")
    self.TabContainer = self.InventoryUI:WaitForChild("TabContainer")
    self.CloseInvButton = self.TabContainer:WaitForChild("CloseButton")
    self.MockTabContainer = self.InventoryUI:WaitForChild("MockTabContainer")
    self.BackpackBtn = self.HotBar:WaitForChild("Backpack")
    self.BackpackToolTip = self.BackpackBtn:WaitForChild("Tooltip")
    self.FishingRodBtn = self.HotBar:WaitForChild("FishingRod")
    
    self:_SetupTweenAndConnection()

    local BaitUI = RS:WaitForChild("Template"):WaitForChild("FishingBaitUI"):Clone()
    BaitUI.Parent = self.player.Character.Head
    local PowerCategoryUI = RS:WaitForChild("Template"):WaitForChild("PowerCategoryUI"):Clone()
    PowerCategoryUI.Parent = self.player.Character.Head
    self.globalUI = {
        BaitUI = BaitUI,
        PowerCategoryUI = PowerCategoryUI
    }
end

-- ENTRY POINTS
function PUI:new(player)
    self.player = player
    self:_CreatePlayerUI()
end

return PUI