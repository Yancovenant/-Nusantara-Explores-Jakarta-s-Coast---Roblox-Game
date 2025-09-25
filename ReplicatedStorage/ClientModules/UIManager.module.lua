-- Client UI Manager

local CUI = {}
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local TS:TweenService = game:GetService("TweenService")
local RS:ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local ToolEvent: RemoteEvent = RS:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")

local c = require(RS:WaitForChild("GlobalConfig"))


-- MAIN FUNCTIONS
function CUI:UpdateTime(t)
    if t == nil then
        t = {hour = Lighting:GetAttribute("Hour"), min = Lighting:GetAttribute("Minute")}
    end
    local nH = string.format("%02d", t.hour)
    local nM = string.format("%02d", t.min)    
    self.TopBarUI.Time.TimeText.Text = nH .. ":" .. nM
end

function CUI:UpdateXP(Level, CurrentXp, RequiredXp, GainedXp)
    local expText = math.floor(CurrentXp) .. " / " .. math.floor(RequiredXp)
	self.ExpUI.Text.Text = expText
    self.ExpUITooltip.Text = expText
	TS:Create(
		self.ExpUI.Fill,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(CurrentXp/RequiredXp,0,1,0)}
	):Play()
	self.GainedXpText.Text = "+" .. math.floor(GainedXp) .. " XP!"
	self.GainedXpText.TextTransparency = 0
	self.GainedXpText.Position = UDim2.new(0.5, 0, 0.3, 0)
    self.GainedXpText.Visible = true
	local tweenUp = TS:Create(self.GainedXpText, TweenInfo.new(1), {
        Position = UDim2.new(0.5, 0, -1, 0),
        TextTransparency = 1
    })
    tweenUp:Play()
    tweenUp.Completed:Connect(function()
        self.GainedXpText.Visible = false
    end)
end
function CUI:UpdateMoney(Money, GainedMoney)
    self.MoneyUI.Text.Text = math.floor(Money)
end


function CUI:SortRodInventoryUI()
    local RodList = {}
    for _, rod in pairs(self.RodInventoryTab:GetChildren()) do
        if rod.Name ~= "TemplateFishingRod" and rod:IsA("TextButton") then
            table.insert(RodList,{
                instance = rod,
                rarity = c.RARITY_ORDER[rod:GetAttribute("rarity")] or 0,
                id = tonumber(rod:GetAttribute("id")) or 0
            })
        end
    end
    table.sort(RodList, function(a, b)
        if a.rarity ~= b.rarity then
            return a.rarity > b.rarity
        end
        return a.id > b.id
    end)
    for i, FishData in ipairs(RodList) do
        FishData.instance.LayoutOrder = i
    end
end
function CUI:SortFishInventoryUI()
	local startTimeReparenting = tick()
	-- self.FishGridLayout.Parent = nil
	local durationReparenting = (tick() - startTimeReparenting) * 1000
    if durationReparenting > 1 then
        print(string.format("[PUI]: Removing Parent takes about %.2fms", durationReparenting))
    end
    local FishList = {}
    local startTimeFishList = tick()
    for _, fish in pairs(self.FishInventoryTab:GetChildren()) do
        if fish.Name ~= "TemplateFish" and fish:IsA("TextButton") then
			table.insert(FishList, {
				instance = fish,
				rarity = c.RARITY_ORDER[fish:GetAttribute("rarity")] or 0,
				id = tonumber(fish:GetAttribute("id")) or 0
			})
        end
    end
    local durationFishList = (tick() - startTimeFishList) * 1000
    if durationFishList > 1 then
        print(string.format("[PUI]: Creating FishList takes about %.2fms", durationFishList))
    end
    local startTimeSort = tick()
    table.sort(FishList, function(a, b)
        if a.rarity ~= b.rarity then
            return a.rarity > b.rarity
        end
        return a.id > b.id
    end)
    local durationSort = (tick() - startTimeSort) * 1000
    if durationSort > 1 then
        print(string.format("[PUI]: Sorting FishList takes about %.2fms", durationSort))
    end
    local startTimeOrdering = tick()
    for i, FishData in ipairs(FishList) do
        FishData.instance.LayoutOrder = i
    end
    local durationOrdering = (tick() - startTimeOrdering) * 1000
    if durationOrdering > 1 then
        print(string.format("[PUI]: Ordering FishList takes about %.2fms", durationOrdering))
    end
    local startTimeTextCount = tick()
    self.FishTabBtn.Count.Text = #FishList
    local durationTextCount = (tick() - startTimeTextCount) * 1000
    if durationTextCount > 1 then
        print(string.format("[PUI]: TextCount Update takes about %.2fms", durationTextCount))
    end
	local startTimeReparenting = tick()
    -- self.FishGridLayout.Parent = self.FishInventoryTab
	local durationReparenting = (tick() - startTimeReparenting) * 1000
    if durationReparenting > 1 then
        print(string.format("[PUI]: Reparenting Parent takes about %.2fms", durationReparenting))
    end
end
function CUI:SortFishShopUI()
    local FishList = {}
    for _, fish in pairs(self.FishShopSellPageFrame.ScrollingFrame:GetChildren()) do
        if fish.Name ~= "TemplateItem" and fish:IsA("Frame") then
			table.insert(FishList, {
				instance = fish,
				rarity = c.RARITY_ORDER[fish:GetAttribute("rarity")] or 0,
				id = tonumber(fish:GetAttribute("id")) or 0
			})
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
end
function CUI:_UpdatePlayerModalData(data)
    self.PMDisplayName.Text = Player.DisplayName
    local success, content, isReady = pcall(function()
        return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
    end)
    if success and isReady then
        self.PMAvatar.Image = content
    end
    self.PMStrengthUI.Value.Text = data.strength
    self.PMLuckUI.Value.Text = data.luck .. "%"
    self.PMAttractiveUI.Value.Text = data.attraction
end
function CUI:TogglePlayerModal(attrs:table)
    if Player:GetAttribute("InMinigame") then return end
    if Player:GetAttribute("ModalShown") and Player:GetAttribute("ModalShown") ~= "PlayerModal" then
        -- return -- could close other modal and then show this.
        self:ToggleInventory()
    end
    self._tempAttrs = attrs
    self:_UpdatePlayerModalData(attrs)
    local shown = self.PlayerModalUI.Visible
    if not shown then
        Player:SetAttribute("ModalShown", "PlayerModal")
        self.PlayerModalUI.Size = UDim2.new(0,0,0,0)
		self.PlayerModalUI.Visible = true
        self.ShownPlayerModalTween:Play()
        self.ClosedHotbarTween:Play()
        self.ClosedPlayerInfoTween:Play()
    else
        Player:SetAttribute("ModalShown", nil)
        self.ClosedPlayerModalTween:Play()
        self.ShownHotbarTween:Play()
        self.ShownPlayerInfoTween:Play()
        self.ClosedPlayerModalTween.Completed:Connect(function()
            self.PlayerModalUI.Visible = false
            
        end)
    end
end
function CUI:ToggleInventory()
    if Player:GetAttribute("InMinigame") then return end
    if Player:GetAttribute("ModalShown") and Player:GetAttribute("ModalShown") ~= "Inventory" then
        -- return -- could close other modal and then show this.
        self:TogglePlayerModal(self._tempAttrs)
    end
    local isShown = self.TabContainer.Visible
    if isShown then
        Player:SetAttribute("ModalShown", nil)
        self.TabContainer.Visible = not isShown
        self.ActionButton.Visible = self.TabContainer.Visible
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
        Player:SetAttribute("ModalShown", "Inventory")
        self.FishingUI.Enabled = false
        self.MockTabContainer.Size = UDim2.new(0,0,0,0)
        self.MockTabContainer.Visible = not isShown
        self.ShownInventoryTween:Play()
        self.ClosedHotbarTween:Play()
        self.ClosedPlayerInfoTween:Play()
        self.ShownInventoryTween.Completed:Connect(function()
            self.TabContainer.Visible = not isShown
            self.ActionButton.Visible = self.TabContainer.Visible
        end)
    end
end
function CUI:PopulateFishIndex(FishIndex:table)
    local FishList = {}
    for FishName, FishData in pairs(c.FISHING.FISH_DATA.FISH) do
        table.insert(FishList,{
            id = FishData.id,
            name = FishName,
            rarity = FishData.rarity,
            habitat = FishData.habitat,
            icon = FishData.icon
        })
    end
    table.sort(FishList, function(a,b)
        if a.rarity ~= b.rarity then
            return a.rarity < b.rarity
        end
        return a.id < b.id
    end)
    for i, FD in ipairs(FishList) do
        local FishIndexFish = FishIndex[tostring(FD.id)]
        local IsDiscovered = FishIndexFish ~= nil
        local template = self.PMFishIndexTemplate:Clone()
        template.Parent = self.PMFishIndexFrame
        template.Name = FD.name
        template.BackgroundColor3 = IsDiscovered and Color3.fromRGB(40,40,40) or Color3.fromRGB(20,20,30)
        local frame = template.Frame
        frame.BackgroundColor3 = IsDiscovered and Color3.fromRGB(60,60,60) or Color3.fromRGB(40,40,40)
        frame.Icon.Image = FD.icon
        frame.Icon.ImageColor3 = IsDiscovered and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0)
        frame.FishName.Text = IsDiscovered and FD.name or "???"
        frame.FishName.TextColor3 = IsDiscovered and Color3.fromRGB(255,255,255) or Color3.fromRGB(100,100,100)
        frame.Rarity.Text = IsDiscovered and '"' .. FD.rarity .. '"' or '"???"'
        frame.Rarity.TextColor3 = IsDiscovered and c:GetRarityColor(FD.rarity) or Color3.fromRGB(100,100,100)
        frame.Habitat.Text = '"' .. FD.habitat .. '"'
        frame.Stat.Text = IsDiscovered and string.format("Best: %.1fkg\nCaught: %d",
            FishIndexFish.bestWeight,
            FishIndexFish.totalCaught
        ) or "???"
        frame.Stat.TextColor3 = IsDiscovered and Color3.fromRGB(180,180,180) or Color3.fromRGB(100,100,100)
        template.Visible = true
    end
    self.PMFishIndexDiscoveredBar.Label.Text = "Discovered: " .. #FishIndex .. "/" .. #FishList
    self.PMFishIndexDiscoveredBar.Fill.Size = UDim2.new(#FishIndex/#FishList,0,1,0)
end



-- SETUP
function CUI:_CreateTweens()
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
        {Position = UDim2.new(0.025, 0, 0.775, 0)}
    )
    self.ClosedPlayerInfoTween = TS:Create(
        self.PlayerInfoUI,
        TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut),
        {Position = UDim2.new(0.025, 0, 1.375, 0)}
    )
    self.ShownPlayerModalTween = TS:Create(
        self.PlayerModalUI,
        TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut),
        {Size = UDim2.new(0.8, 0, 0.75, 0)}
    )
    self.ClosedPlayerModalTween = TS:Create(
        self.PlayerModalUI,
        TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut
        ),
        {Size = UDim2.new(0, 0, 0, 0)}
    )

    self.ShownInventoryTween = TS:Create(
        self.MockTabContainer,
        TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut),
        {Size = UDim2.new(0.8, 0, 0.75, 0)}
    )
    self.ClosedInventoryTween = TS:Create(
        self.MockTabContainer,
        TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut
        ),
        {Size = UDim2.new(0, 0, 0, 0)}
    )
end
function CUI:_SetupEventListener()
    self.FishShopBuyBtn.MouseButton1Click:Connect(function()
        self.FishShopPageLayout:JumpTo(self.FishShopBuyPageFrame)
        self.FishPagePageTitle.Text = "Buy"
    end)
    self.FishShopSellBtn.MouseButton1Click:Connect(function()
        self.FishShopPageLayout:JumpTo(self.FishShopSellPageFrame)
        self.FishPagePageTitle.Text = "Sell"
    end)
    self.PMCloseButton.MouseButton1Click:Connect(function()
        ToolEvent:FireServer("TogglePlayerModal")
    end)

    self.BackpackBtn.MouseEnter:Connect(function()
		self.BackpackToolTip.Visible = true
	end)
	self.BackpackBtn.MouseLeave:Connect(function()
		self.BackpackToolTip.Visible = false
	end)
	self.BackpackBtn.MouseButton1Click:Connect(function()
        ToolEvent:FireServer("ToggleInventory")
	end)

    self.CloseInvButton.MouseButton1Click:Connect(function()
        ToolEvent:FireServer("ToggleInventory")
    end)
end
function CUI:_CreateUI()
    local PlayerGui = Player:WaitForChild("PlayerGui")
	self.InventoryUI = PlayerGui:WaitForChild("InventoryUI")
	self.TabContainer = self.InventoryUI:WaitForChild("TabContainer")
    self.MockTabContainer = self.InventoryUI:WaitForChild("MockTabContainer")
    self.FishingUI = PlayerGui:WaitForChild("FishingUI")
    self.ActionButton = self.InventoryUI.ActionButton
    self.CloseInvButton = self.TabContainer:WaitForChild("CloseButton")

	local fishTabBtn = self.TabContainer:WaitForChild("TabNavbar"):WaitForChild("FishTabButton")
	local rodTabBtn = self.TabContainer:WaitForChild("TabNavbar"):WaitForChild("RodTabButton")
	local pageLayout = self.TabContainer:WaitForChild("ContentArea"):FindFirstChildWhichIsA("UIPageLayout")
	local fishPageFrame = self.TabContainer:WaitForChild("ContentArea"):WaitForChild("Fish")
	local rodPageFrame = self.TabContainer:WaitForChild("ContentArea"):WaitForChild("Rod")
	fishTabBtn.MouseButton1Click:Connect(function()
		pageLayout:JumpTo(fishPageFrame)
	end)
	rodTabBtn.MouseButton1Click:Connect(function()
		pageLayout:JumpTo(rodPageFrame)
	end)
    self.HotBar = self.InventoryUI:WaitForChild("InventoryFrame")
    self.TopBarUI = PlayerGui:WaitForChild("TopBarUI")
	self.PlayerInfoUI = self.InventoryUI:WaitForChild("PlayerInfo")
	self.LevelUI = self.PlayerInfoUI:WaitForChild("Level")
	self.ExpUI = self.LevelUI:WaitForChild("LevelContainer"):WaitForChild("Exp")
    self.ExpUITooltip = self.LevelUI:WaitForChild("LevelContainer").Tooltip
    self.ExpUI.MouseEnter:Connect(function()
        self.ExpUITooltip.Visible = true
    end)
    self.ExpUI.MouseLeave:Connect(function()
        self.ExpUITooltip.Visible = false
    end)
	self.GainedXpText = self.LevelUI:WaitForChild("GainedXP")
    self.MoneyUI = self.PlayerInfoUI.Money

	self.FishTabBtn = self.TabContainer:WaitForChild("TabNavbar"):WaitForChild("FishTabButton")
	self.FishInventoryTab = self.TabContainer:WaitForChild("ContentArea"):FindFirstChild('Fish')
    self.RodInventoryTab = self.TabContainer:WaitForChild("ContentArea"):FindFirstChild('Rod')
	self.FishGridLayout = self.FishInventoryTab:FindFirstChildWhichIsA("UIGridLayout")


    self.FishShopUI = PlayerGui:WaitForChild("FishShopUI")
    self.FishShopTab = self.FishShopUI:WaitForChild("ShopTabContainer")
    self.FishShopNavbar = self.FishShopTab.RightPanel.Navbar
    self.FishShopBuyBtn = self.FishShopNavbar.Buy
    self.FishShopSellBtn = self.FishShopNavbar.Sell
    self.FishPagePageTitle = self.FishShopNavbar.PageTitle
    self.FishShopContentArea = self.FishShopTab.RightPanel.ContentArea
    self.FishShopPageLayout = self.FishShopContentArea:FindFirstChildWhichIsA("UIPageLayout")
    self.FishShopBuyPageFrame = self.FishShopContentArea.Buy
    self.FishShopSellPageFrame = self.FishShopContentArea.Sell

    -- PLAYER MODAL
    self.PlayerModalUI = self.InventoryUI.PlayerModal
    self.PMPage = self.PlayerModalUI.Page
    self.PMPageLayout = self.PMPage:FindFirstChildWhichIsA("UIPageLayout")

    self.PMPageStat = self.PMPage.PageStat -- page stat
    self.PMDisplayName = self.PMPageStat.LeftPanel.PlayerName
    self.PMAvatar = self.PMPageStat.LeftPanel.Avatar.ImageLabel
    self.PMAttractiveUI = self.PMPageStat.RightPanel.ATTRACTIVE
    self.PMStrengthUI = self.PMPageStat.RightPanel.STR
    self.PMLuckUI = self.PMPageStat.RightPanel.LUCK
    self.PMCloseButton = self.PlayerModalUI.CloseButton

    self.PMFishIndex = self.PMPage.PageFishIndex
    self.PMFishIndexFrame = self.PMFishIndex.FishIndexFrame
    self.PMFishIndexTemplate = self.PMFishIndexFrame.TemplateItem
    self.PMFishIndexDiscoveredBar = self.PMFishIndex.StatBar

    
    self.BackpackBtn = self.HotBar:WaitForChild("Backpack")
    self.BackpackToolTip = self.BackpackBtn:WaitForChild("Tooltip")
end


-- ENTRY POINTS
function CUI:main()
    self:_CreateUI()
	self:_SetupEventListener()
    self:_CreateTweens()
    -- self.UpdateTime()
end


-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:WrapModule(CUI, "Client_UIManager")


return CUI