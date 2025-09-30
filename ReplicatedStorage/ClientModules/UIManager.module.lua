-- Client UI Manager - OPTIMIZED
local CUI, RS, TS, Lighting, Players = {}, game:GetService("ReplicatedStorage"), game:GetService("TweenService"), game:GetService("Lighting"), game:GetService('Players')
local Player = Players.LocalPlayer
local ToolEvent = RS:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")
local c = require(RS:WaitForChild("GlobalConfig"))

-- HELPER
local countKeys = function(t) local n=0 for _ in pairs(t) do n+=1 end return n end


-- MAIN FUNCTIONS
-- == TopBar ==
function CUI:UpdateTime(t)
    if t == nil then
        t = {hour = Lighting:GetAttribute("Hour"), min = Lighting:GetAttribute("Minute")}
    end
    local nH = string.format("%02d", t.hour)
    local nM = string.format("%02d", t.min)    
    self.TopBarUI.Time.TimeText.Text = nH .. ":" .. nM
end
-- == Player Info ==
function CUI:UpdateXP(Level, CurrentXp, RequiredXp, GainedXp)
    self.LevelText.Text = "Level " .. Level
	self.GainedXpText.Text, self.GainedXpText.Position = "+" .. math.floor(GainedXp) .. " XP!", UDim2.new(0.5, 0, 0.3, 0)
	self.GainedXpText.TextTransparency, self.GainedXpText.Visible = 0, true
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
    self.MoneyUI.Label.Text = math.floor(Money)
end


-- SORT
-- == Inventory Rod ==
function CUI:SortRodInventoryUI()
    local RodList = {}
    for _, rd in pairs(self.RodInventoryTab:GetChildren()) do
        if rd.Name ~= "TemplateFishingRod" and rd:IsA("TextButton") then
            table.insert(RodList,{inst = rd,rarity = c.RARITY_ORDER[rd:GetAttribute("rarity")] or 0,id = tonumber(rd:GetAttribute("id")) or 0})
        end
    end
    table.sort(RodList, function(a, b)
        if a.rarity ~= b.rarity then return a.rarity > b.rarity end
        return a.id > b.id
    end)
    for i, fd in ipairs(RodList) do fd.inst.LayoutOrder = i end
end
-- == Inventory Fish ==
function CUI:SortFishInventoryUI()
	local fishList={} for _,f in pairs(self.FishInventoryTab:GetChildren()) do
		if f.Name~="TemplateFish"and f:IsA("TextButton")then
			table.insert(fishList,{inst=f,rarity=c.RARITY_ORDER[f:GetAttribute("rarity")] or 0,id=tonumber(f:GetAttribute("id")) or 0})
		end
	end
	table.sort(fishList,function(a,b)
        if a.rarity~=b.rarity then return a.rarity>b.rarity end
        return a.id>b.id
    end)
	for i,f in ipairs(fishList)do f.inst.LayoutOrder=i end self.FishTabBtn.Count.Text=#fishList
end
-- == Shop Fish ==
function CUI:SortFishShopUI()
    local FishList = {} for _, f in pairs(self.SellPage.ScrollingFrame:GetChildren()) do
        if f.Name ~= "TemplateItem" and f:IsA("TextButton") then
			table.insert(FishList, {inst=f,rarity = c.RARITY_ORDER[f:GetAttribute("rarity")] or 0,id = tonumber(f:GetAttribute("id")) or 0})
        end
    end
    table.sort(FishList,function(a,b)
        if a.rarity~=b.rarity then return a.rarity>b.rarity end
        return a.id>b.id
    end)
    for i,f in ipairs(FishList) do f.inst.LayoutOrder = i end
end
-- == Mising Boat


-- UI OPEN TOGGLE
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
    -- if Player:GetAttribute("InMinigame") then return end
    if Player:GetAttribute("ModalShown") and Player:GetAttribute("ModalShown") ~= "PlayerModal" then
        -- return -- could close other modal and then show this.
        self:ToggleInventory()
    end
    self._tempAttrs = attrs
    self:_UpdatePlayerModalData(attrs)
    local shown = self.PlayerModalUI.Visible
    if not shown then
        Player:SetAttribute("ModalShown", "PlayerModal")
        self.FishingUI.Enabled = false
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
        self.ShownHotbarTween.Completed:Connect(function()
            self.FishingUI.Enabled = true
        end)
    end
end
function CUI:ToggleInventory()
    -- if Player:GetAttribute("InMinigame") then return end
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

-- FISH INDEX
function CUI:_UpdateFishIndex(template:Instance, FishIndex:table)
    local id = template:GetAttribute("id")
    local name = template:GetAttribute("name")
    local rarity = template:GetAttribute("rarity")
    local habitat = template:GetAttribute("habitat")
    local FishIndexFish = FishIndex[tostring(id)]
    local IsDiscovered = FishIndexFish ~= nil

    template.BackgroundColor3 = IsDiscovered and Color3.fromRGB(40,40,40) or Color3.fromRGB(20,20,30)
    local frame = template.Frame
    frame.BackgroundColor3 = IsDiscovered and Color3.fromRGB(60,60,60) or Color3.fromRGB(40,40,40)
    frame.Icon.ImageColor3 = IsDiscovered and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0)
    frame.FishName.Text = IsDiscovered and name or "???"
    frame.FishName.TextColor3 = IsDiscovered and Color3.fromRGB(255,255,255) or Color3.fromRGB(100,100,100)
    frame.Rarity.Text = IsDiscovered and '"' .. rarity .. '"' or '"???"'
    frame.Rarity.TextColor3 = IsDiscovered and c:GetRarityColor(rarity) or Color3.fromRGB(100,100,100)
    frame.Habitat.Text = '"' .. habitat .. '"'
    frame.Habitat.TextColor3 = c:GetHabitatColor(habitat)
    frame.Stat.Text = IsDiscovered and string.format("Best: %.1fkg\nCaught: %d",
        FishIndexFish.bestWeight,
        FishIndexFish.totalCaught
    ) or "???"
    frame.Stat.TextColor3 = IsDiscovered and Color3.fromRGB(180,180,180) or Color3.fromRGB(100,100,100)
end
function CUI:UpdateFishIndex(FishIndex:table)
    local FishFrames = {}
    for _, template in ipairs(self.PMFishIndexFrame:GetChildren()) do
        if template:IsA("Frame") and template.Name ~= "TemplateItem" then
            table.insert(FishFrames, template)
            self:_UpdateFishIndex(template, FishIndex)
        end
    end
    local Discovered = countKeys(FishIndex)
    local Total = #FishFrames
    self.PMFishIndexDiscoveredBar.Label.Text = string.format("Discovered: %d/%d", Discovered, Total)
    self.PMFishIndexDiscoveredBar.Fill.Size = UDim2.new(Total > 0 and Discovered / Total or 0,0,1,0)
end
function CUI:PopulateFishIndex(FishIndex:table)
    local FishList = {}
    for FishName, FishData in pairs(c.FISHING.FISH_DATA.FISH) do
        table.insert(FishList,{
            id = FishData.id,
            name = FishName,
            rarity = FishData.rarity,
            rarityOrder = c.RARITY_ORDER[FishData.rarity] or 0,
            habitat = FishData.habitat,
            icon = FishData.icon
        })
    end
    table.sort(FishList, function(a,b)
        if a.rarityOrder ~= b.rarityOrder then
            return a.rarityOrder < b.rarityOrder
        end
        return a.id < b.id
    end)
    for i, FD in ipairs(FishList) do
        local template = self.PMFishIndexTemplate:Clone()
        template:SetAttribute("id", FD.id)
        template:SetAttribute("name", FD.name)
        template:SetAttribute("rarity", FD.rarity)
        template:SetAttribute("habitat", FD.habitat)
        template.Parent, template.Name = self.PMFishIndexFrame, FD.name
        template.Frame.Icon.Image = FD.icon
        template.LayoutOrder, template.Visible = i, true
        self:_UpdateFishIndex(template, FishIndex)
    end
    local Discovered = countKeys(FishIndex)
    local Total = #FishList
    self.PMFishIndexDiscoveredBar.Label.Text = string.format("Discovered: %d/%d", Discovered, Total)
    self.PMFishIndexDiscoveredBar.Fill.Size = UDim2.new(Total > 0 and Discovered / Total or 0,0,1,0)
end


-- ENTRY POINTS
function CUI:_CreateTweens()
    local TWInfo = TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut)
    self.ShownHotbarTween = TS:Create(self.HotBar,TWInfo,{Position = UDim2.new(0.5, 0, 0.875, 0)})
    self.ClosedHotbarTween = TS:Create(self.HotBar,TWInfo,{Position = UDim2.new(0.5, 0, 1.375, 0)})
	self.ShownPlayerInfoTween = TS:Create(self.PlayerInfoUI,TWInfo,{Position = UDim2.new(0.025, 0, 0.775, 0)})
    self.ClosedPlayerInfoTween = TS:Create(self.PlayerInfoUI,TWInfo,{Position = UDim2.new(0.025, 0, 1.375, 0)})

    self.ShownPlayerModalTween = TS:Create(self.PlayerModalUI,TWInfo,{Size = UDim2.new(0.8, 0, 0.75, 0)}) -- stat
    self.ClosedPlayerModalTween = TS:Create(self.PlayerModalUI,TWInfo,{Size = UDim2.new(0, 0, 0, 0)})
    self.ShownInventoryTween = TS:Create(self.MockTabContainer,TWInfo,{Size = UDim2.new(0.8, 0, 0.75, 0)}) -- inv
    self.ClosedInventoryTween = TS:Create(self.MockTabContainer,TWInfo,{Size = UDim2.new(0, 0, 0, 0)})
end
function CUI:_SetupEventListener()
    -- Page Layout
    -- == Shop ==
    self.BuyPageBtn.MouseButton1Click:Connect(function()
        self.FishShopPageLayout:JumpTo(self.BuyPage)
        self.FishShopTitle.Text = "Buy"
    end)
    self.SellPageBtn.MouseButton1Click:Connect(function()
        self.FishShopPageLayout:JumpTo(self.SellPage)
        self.FishShopTitle.Text = "Sell"
    end)
    -- == Inventory ==
    self.FishTabBtn.MouseButton1Click:Connect(function()
		self.InvPageLayout:JumpTo(self.FishInventoryTab)
	end)
	self.RodTabBtn.MouseButton1Click:Connect(function()
		self.InvPageLayout:JumpTo(self.RodInventoryTab)
	end)
    -- == Player Modal ==
    self.PMPageStatBtn.MouseButton1Click:Connect(function()
        self.PMPageLayout:JumpTo(self.PMPageStat)
    end)
    self.PMPageFishIndexBtn.MouseButton1Click:Connect(function()
        self.PMPageLayout:JumpTo(self.PMFishIndex)
    end)

    -- Close
    self.PMCloseButton.MouseButton1Click:Connect(function()
        ToolEvent:FireServer("TogglePlayerModal")
    end)
    self.CloseInvButton.MouseButton1Click:Connect(function()
        ToolEvent:FireServer("ToggleInventory")
    end)
    -- == Missing shop ==

    -- Backpack HotBar
    self.BackpackBtn.MouseEnter:Connect(function()
		self.BackpackToolTip.Visible = true
	end)
	self.BackpackBtn.MouseLeave:Connect(function()
		self.BackpackToolTip.Visible = false
	end)
	self.BackpackBtn.MouseButton1Click:Connect(function()
        ToolEvent:FireServer("ToggleInventory")
	end)
end
function CUI:_CreateUI()
    local PlayerGui = Player:WaitForChild("PlayerGui")

	self.InventoryUI = PlayerGui:WaitForChild("InventoryUI")
    self.FishingUI = PlayerGui:WaitForChild("FishingUI")
    self.TopBarUI = PlayerGui:WaitForChild("TopBarUI")
    self.FishShopUI = PlayerGui:WaitForChild("FishShopUI")
    self.BoatUI = PlayerGui:WaitForChild("BoatUI")

    -- Inventory
	self.TabContainer = self.InventoryUI.TabContainer
    self.MockTabContainer = self.InventoryUI.MockTabContainer
    self.ActionButton = self.InventoryUI.ActionButton
    self.HotBar = self.InventoryUI.InventoryFrame
    self.PlayerInfoUI = self.InventoryUI.PlayerInfo

    self.BackpackBtn = self.HotBar.Backpack
    self.BackpackToolTip = self.BackpackBtn.Tooltip

    self.CloseInvButton = self.TabContainer:WaitForChild("CloseButton")

    self.RodTabBtn = self.TabContainer:WaitForChild("TabNavbar"):WaitForChild("RodTabButton")
    self.FishTabBtn = self.TabContainer:WaitForChild("TabNavbar"):WaitForChild("FishTabButton")
    self.InvPageLayout = self.TabContainer:WaitForChild("ContentArea"):FindFirstChildWhichIsA("UIPageLayout")
	self.FishInventoryTab = self.TabContainer:WaitForChild("ContentArea"):FindFirstChild('Fish')
    self.FishGridLayout = self.FishInventoryTab:FindFirstChildWhichIsA("UIGridLayout")
    self.RodInventoryTab = self.TabContainer:WaitForChild("ContentArea"):FindFirstChild('Rod')

    -- == Player Stat Modal ==
    self.PlayerModalUI = self.InventoryUI.PlayerModal
    self.PMPage = self.PlayerModalUI.Page
    self.PMPageLayout = self.PMPage:FindFirstChildWhichIsA("UIPageLayout")
    self.PMPageStatBtn = self.PlayerModalUI.TopBar.Stat
    self.PMPageFishIndexBtn = self.PlayerModalUI.TopBar.FishIndex

    self.PMPageStat = self.PMPage.PageStat -- page stat
    self.PMDisplayName = self.PMPageStat.LeftPanel.PlayerName
    self.PMAvatar = self.PMPageStat.LeftPanel.Avatar.ImageLabel
    self.PMAttractiveUI = self.PMPageStat.RightPanel.ATTRACTIVE
    self.PMStrengthUI = self.PMPageStat.RightPanel.STR
    self.PMLuckUI = self.PMPageStat.RightPanel.LUCK
    self.PMCloseButton = self.PlayerModalUI.CloseButton

    self.PMFishIndex = self.PMPage.PageFishIndex -- page fish index
    self.PMFishIndexFrame = self.PMFishIndex.FishIndexFrame
    self.PMFishIndexDiscoveredBar = self.PMFishIndex.StatBar
    self.PMFishIndexTemplate = self.PMFishIndexFrame.TemplateItem


    -- Player Info
	self.LevelUI = self.PlayerInfoUI.Level
    self.MoneyUI = self.PlayerInfoUI.Money

	self.LevelText = self.LevelUI:WaitForChild("Label")
	self.GainedXpText = self.LevelUI:WaitForChild("GainedXP")

    -- Shop
    self.FishShopTab = self.FishShopUI:WaitForChild("ShopTabContainer")

    self.BuyPageBtn = self.FishShopTab.RightPanel.Navbar.Buy
    self.SellPageBtn = self.FishShopTab.RightPanel.Navbar.Sell
    self.FishShopTitle = self.FishShopTab.RightPanel.Navbar.PageTitle
    self.FishShopPageLayout = self.FishShopTab.RightPanel.ContentArea:FindFirstChildWhichIsA("UIPageLayout")
    self.BuyPage = self.FishShopTab.RightPanel.ContentArea.Buy -- BUY PAGE
    self.SellPage = self.FishShopTab.RightPanel.ContentArea.Sell -- SELL PAGE



    -- self.FishShopNavbar = self.FishShopTab.RightPanel.Navbar
    -- self.FishShopBuyBtn = self.FishShopNavbar.Buy
    -- self.FishShopSellBtn = self.FishShopNavbar.Sell
    -- self.FishPagePageTitle = self.FishShopNavbar.PageTitle
    -- self.FishShopContentArea = self.FishShopTab.RightPanel.ContentArea
    -- self.FishShopPageLayout = self.FishShopContentArea:FindFirstChildWhichIsA("UIPageLayout")
    -- self.FishShopBuyPageFrame = self.FishShopContentArea.Buy
    -- self.FishShopSellPageFrame = self.FishShopContentArea.Sell
end
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