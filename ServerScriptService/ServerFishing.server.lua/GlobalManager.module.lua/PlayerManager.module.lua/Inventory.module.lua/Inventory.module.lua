-- Inventory.module.lua - OPTIMIZED  
local PINV, RS, TS = {}, game:GetService("ReplicatedStorage"), game:GetService("TweenService")
PINV.__index = PINV
local DBM = require(script.Parent.Parent.Parent.GlobalStorage)
local ClientAnimationEvent = RS:WaitForChild("Remotes"):WaitForChild("ClientAnimation")
local ToolEvent = RS:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")
local ROD = RS:WaitForChild("ToolItem"):WaitForChild("FishingRod")
local c = require(RS:WaitForChild("GlobalConfig"))


-- HELPER
function PINV:_CleanHoldingFish()
    if self.HoldingFish then self.HoldingFish:Destroy() self.HoldingFish = nil end
    ClientAnimationEvent:FireClient(self.player, "Clean")
end
function PINV:_ScaleWeight(w) return 1 * (w / 50)^(1/3) end
function PINV:_HoldFishAboveHead(fishName, Weight)
    if self.player.Character:FindFirstChildWhichIsA("Tool") then return end
    self:_CleanHoldingFish()
    local template = RS:WaitForChild("Template"):WaitForChild("Fish"):FindFirstChild(fishName)
    if not template then template = RS:WaitForChild("Template"):WaitForChild("Fish"):FindFirstChild("TestFish") end
    local fish = template:Clone()
    local originalOrientation = template.Body.Orientation
    self.HoldingFish = fish
    fish.Body.Anchored, fish.Body.CanCollide, fish.Body.Massless = false, false, true
    fish:ScaleTo(self:_ScaleWeight(Weight))
    fish.Parent = self.player.Character.Head
    fish:SetPrimaryPartCFrame(
        self.player.Character.Head.CFrame * CFrame.new(0, 2, 0) * CFrame.Angles(
            math.rad(originalOrientation.X),
            math.rad(originalOrientation.Y),
            math.rad(originalOrientation.Z)
        )
    )
    local head2FishAttachment
    if not self.player.Character.Head:FindFirstChild("Head2FishAttachment") then
        head2FishAttachment = Instance.new("Attachment", self.player.Character.Head)
        head2FishAttachment.Name = "Head2FishAttachment"
    end
    local fish2HeadAttachment = Instance.new("Attachment")
    fish2HeadAttachment.Name = "Fish2HeadAttachment"
    fish2HeadAttachment.Parent = fish.Body
    local fish2HeadWeld = Instance.new("WeldConstraint", fish.Body)
    fish2HeadWeld.Part0, fish2HeadWeld.Part1 = fish.Body, self.player.Character.Head
    ClientAnimationEvent:FireClient(self.player, "HoldFishAboveHead")
end


-- MAIN FUNCTIONS
function PINV:GetEquipmentData(type:string, params) return c.EQUIPMENT.GED[type](c.EQUIPMENT.GED, params) end
function PINV:ToggleHolsterRod()
    local hum = self.player.Character:WaitForChild("Humanoid")
    if not self.IsHolsterEquip then
        self.HolsterRod = self.RodAccessory:Clone()
        hum:AddAccessory(self.HolsterRod)
        self.IsHolsterEquip = true
    else
        self.HolsterRod:Destroy()
        self.HolsterRod = nil
        self.IsHolsterEquip = false
    end
end
-- == Add Rod To Inv ==
function PINV:AddRodToInventory(RodData,sort)
	local template = self.PUI.RodInventoryTemplateItem:Clone()
	template.Name, template.Label.Text = RodData.name, RodData.name
	template.Label.TextColor3, template.Icon.Image = c:GetRarityColor(RodData.rarity), RodData.icon
	template.Visible, template.Parent = true, self.PUI.RodInventoryTab

	local container = template.Container
	if RodData.maxWeight>1 then container.MaxWeight.Text,container.MaxWeight.Visible="🔩"..RodData.maxWeight.."Kg",true end
	if RodData.luck>1 then container.Luck.Text,container.Luck.Visible="☘️"..RodData.luck.."%",true end
	if RodData.attraction>1 then container.Attractive.Text,container.Attractive.Visible="💕"..RodData.attraction.."%",true end
	if RodData.strength>1 then container.Strength.Text,container.Strength.Visible="💪🏻"..RodData.strength,true end
	template:SetAttribute("id",RodData.id) template:SetAttribute("rarity",RodData.rarity)
	if sort then self.PUI:SortRodInventoryUI() end
	return template
end
-- == Add Fish To Inv ==
function PINV:_FishInventoryEventListener(template, FishName, FishData)
    local isPressed = false
    local isActive = false
    self.FishInventoryClickConnection = template.MouseButton1Click:Connect(function()
        if isPressed then return end
        isPressed = true
        local tween = TS:Create(
            template.Container,
            TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, true, 0),
            {Size = UDim2.new(.9, 0, .9, 0)}
        )
        tween:Play()
        table.insert(self.InventoryFishTween, tween)
        tween.Completed:Connect(function()
            for i, t in ipairs(self.InventoryFishTween) do if t == tween then table.remove(self.InventoryFishTween, i) break end end
            isPressed = false
            tween:Destroy()
        end)
        if self.PUI.IsLocking then
            template.Locked.Visible = not template.Locked.Visible
            if self.Data.FishInventory[tostring(FishData.id)] then
                for _, weight in self.Data.FishInventory[tostring(FishData.id)] do
                    if type(weight) == "table" then
                        weight.locked = weight.uniqueId == template:GetAttribute("uniqueId") and template.Locked.Visible or template.Locked.Visible
                    end
                end
            end
        else
            if isActive and self.HoldingFish then
                self:_CleanHoldingFish()
            else
                self:_HoldFishAboveHead(FishName, FishData.weight)
                isActive = true
            end
        end
    end)
end
function PINV:_FormatWeight(w)
    return w >= 1000
           and (w < 1e6 and ("%.1f Ton"):format(w/1000) or ("%.0f Tons"):format(w/1000))
           or ("%.1f Kg"):format(w)
end
function PINV:_AddFishToInventoryTab(FishData, FishName, FishInfo, sort)
    local template = self.PUI.FishInventoryTemplateItem:Clone()
    template.Name, template.Container.FishText.Text = FishName, FishName
    template.Container.FishText.TextColor3 = c:GetRarityColor(FishInfo.rarity)
    template.Container.FishWeight.Text = self:_FormatWeight(FishData.weight)
    if FishInfo.icon then template.Container.Icon.Image = FishInfo.icon end
    if FishData.locked then template.Locked.Visible = FishData.locked end
    template.Parent, template.Visible = self.PUI.FishInventoryTab, true

    template:SetAttribute("rarity", FishInfo.rarity)
    template:SetAttribute("weight", FishData.weight)
    template:SetAttribute("id", FishData.id)
    template:SetAttribute("uniqueId", self.FishCounter)
    if sort == nil then sort = true end
    if sort then self.PUI:SortFishInventoryUI() end
    self:_FishInventoryEventListener(template, FishName, FishData)
    return template
end
function PINV:_AddFishToFishShopTab(FishData, FishName, FishInfo)
    local template = self.PUI.SellTemplateItem:Clone()
    template.Name, template.Label.Text = FishName, FishName
    template.Label.TextColor3, template.Weight.Text = c:GetRarityColor(FishInfo.rarity), self:_FormatWeight(FishData.weight)
    if FishInfo.icon then template.Icon.Image = FishInfo.icon end
    if FishData.locked then template.Locked.Visible = FishData.locked end
    template.Price.Text, template.Visible, template.Parent = FishData.price or 0, true, self.PUI.SellFrame
    template:SetAttribute("rarity", FishInfo.rarity)
    template:SetAttribute("weight", FishData.weight)
    template:SetAttribute("price", FishData.price or 0)
    template:SetAttribute("id", FishData.id)
    template:SetAttribute("uniqueId", self.FishCounter)
    template:SetAttribute("locked", FishData.locked)
    return template
end
function PINV:AddFishToInventory(FishData:table, sort:boolean)
    self.FishCounter += 1
    local FishName:string, FishInfo:table = c.FISHING.FISH_DATA:FindFish(FishData.id)
    local FishInvFrame = self:_AddFishToInventoryTab(FishData, FishName, FishInfo, sort)
    local FishShopFrame = self:_AddFishToFishShopTab(FishData, FishName, FishInfo)
    return FishInvFrame, FishShopFrame
end


-- ROD/TOOL TOGGLING
function PINV:_RefreshTools()
    if not self.ToolFolder then return end
    for _, tool in pairs(self.player.Backpack:GetChildren()) do tool.Parent = self.ToolFolder end
end
function PINV:_EquipTool(toolName:string)
    self:_RefreshTools()
    local tool = self.ToolFolder:FindFirstChild(toolName)
    if self.player.Character:FindFirstChildWhichIsA("Tool") then
        ToolEvent:FireClient(self.player, "OnUnequipped")
        task.spawn(function()
            while self._OnUnequippedReady ~= true do task.wait() end
            self.player.Character.Humanoid:UnequipTools()
            task.wait()
            self.player.Character.Humanoid:EquipTool(tool)
            while self.player and self.player.Character and not self.player.Character:FindFirstChildWhichIsA("Tool") do task.wait() end
            ToolEvent:FireClient(self.player, "OnEquipped")
            self:UnEquippedReady(false)
        end)
        return -- return earaly here
    end
    self.player.Character.Humanoid:UnequipTools()
    task.wait()
    self.player.Character.Humanoid:EquipTool(tool)
    while not self.player.Character:FindFirstChildWhichIsA("Tool") do task.wait() end
    ToolEvent:FireClient(self.player, "OnEquipped")
end
function PINV:UnEquippedReady(bool:boolean)
    self._OnUnequippedReady = bool
end


-- SETUP
function PINV:CreateHolsterRodAccessory(RodModel:Model)
    if self.RodAccessory then self.RodAccessory:Destroy() self.RodAccessory = nil end
    local rodAccessory = Instance.new("Accessory")
    rodAccessory.Name = "FishingRod"
    local rodHandle = RodModel:FindFirstChild("Handle"):Clone()
    rodHandle.Name, rodHandle.Parent = "Handle", rodAccessory
    local gripAttachment = Instance.new("Attachment", rodHandle)
    gripAttachment.Name, gripAttachment.Position, gripAttachment.Orientation = "BodyBackAttachment", Vector3.new(0.7, 0.2, 0.7), Vector3.new(90, 90, 0)
    self.RodAccessory = rodAccessory
end


-- ENTRY POINTS
function PINV:_CreateBackpack()
    if not self.player:FindFirstChild("Custom Backpack") then
        self.Backpack = Instance.new("Folder")
        self.Backpack.Name = "Custom Backpack"
        self.Backpack.Parent = self.player

        self.FishFolder = Instance.new("Folder")
        self.FishFolder.Name = "Fish"
        self.FishFolder.Parent = self.Backpack

        self.ToolFolder = Instance.new("Folder")
        self.ToolFolder.Name = "Tool"
        self.ToolFolder.Parent = self.Backpack
    end
    if not self.ToolFolder:FindFirstChild("FishingRod") then self.FishingRod = ROD:Clone() self.FishingRod.Parent = self.ToolFolder end
end
function PINV:_CreateInventory()
    -- local PlayerGui = self.player:WaitForChild("PlayerGui")
    -- self.InventoryUI = PlayerGui:WaitForChild("InventoryUI")
    -- self.TabContainer = self.InventoryUI:WaitForChild("TabContainer")
    -- self.HotBar = self.InventoryUI:WaitForChild("InventoryFrame")
    self.RodInventoryTab = self.PUI.RodInventoryTab
    self.RodTemplate = self.PUI.RodInventoryTemplateItem
    -- self.FishingRodBtn = self.HotBar:WaitForChild("FishingRod")

    self.FishInventoryTab = self.PUI.FishInventoryTab
    self.FishTemplate = self.PUI.FishInventoryTemplateItem

    -- self.FishShopSellTab = PlayerGui:WaitForChild("FishShopUI").ShopTabContainer.RightPanel.ContentArea.Sell
    self.FishShopSellList = self.PUI.SellFrame
    self.FishShopTemplate = self.PUI.SellTemplateItem
end
function PINV:new(player:Player, PUI:Instance)
    local self = setmetatable({}, PINV)
    self.player = player
    self.Data = DBM:LoadDataPlayer(self.player)
    self.PUI = PUI
    self.FishCounter = 0
    self.InventoryFishTween = {}
    self:_CreateInventory()
    self:_CreateBackpack()
    return self
end

-- CLEANING
function PINV:CleanUp()
    for k,v in pairs(self) do if typeof(v)=="RBXScriptConnection" then v:Disconnect() end end
    if self.FishingRod then self.FishingRod:Destroy() self.FishingRod = nil end
    if self.FishFolder then self.FishFolder:Destroy() self.FishFolder = nil end
    if self.ToolFolder then self.ToolFolder:Destroy() self.ToolFolder = nil end
    if self.Backpack then self.Backpack:Destroy() self.Backpack = nil end
    if self.InventoryFishTween then
        for _, t in pairs(self.InventoryFishTween) do t:Cancel() t:Destroy() t=nil end
        self.InventoryFishTween = nil
    end
    self:_CleanHoldingFish()
    self.player = nil
end

-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:Skip(PINV.AddFishToInventory)
LOGGER:Skip(PINV._AddFishToInventoryTab)
LOGGER:Skip(PINV._AddFishToFishShopTab)
LOGGER:WrapModule(PINV, "PlayerInventory")


return PINV