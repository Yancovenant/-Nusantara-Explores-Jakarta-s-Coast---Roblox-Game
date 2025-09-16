-- Inventory.module.lua

local PINV = {}
PINV.__index = PINV

local PUI = require(script.Parent.UI)

local RS:ReplicatedStorage = game:GetService("ReplicatedStorage")
local TS:TweenService = game:GetService("TweenService")
local ClientAnimationEvent = RS:WaitForChild("Remotes"):WaitForChild("ClientAnimation")
local ToolEvent = RS:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")

local ROD = RS:WaitForChild("ToolItem"):WaitForChild("FishingRod")

local c = require(RS:WaitForChild("GlobalConfig"))


-- HELPER
function PINV:_CleanHoldingFish()
    if self.HoldingFish then
        self.HoldingFish:Destroy()
        self.HoldingFish = nil
    end
    ClientAnimationEvent:FireClient(self.player, "Clean")
end
function PINV:_RefreshTools()
    if not self.ToolFolder then return end
    for _, tool in pairs(self.player.Backpack:GetChildren()) do
        tool.Parent = self.ToolFolder
    end
end
function PINV:_EquipTool(toolName:string)
    self:_RefreshTools()
    local tool = self.ToolFolder:FindFirstChild(toolName)
    if self.player.Character:FindFirstChildWhichIsA("Tool") then
        ToolEvent:FireClient(self.player, "OnUnequipped")
        task.spawn(function()
            while self._OnUnequippedReady ~= true do
                task.wait()
            end
            self.player.Character.Humanoid:UnequipTools()
            task.wait()
            self.player.Character.Humanoid:EquipTool(tool)
            while self.player and self.player.Character and not self.player.Character:FindFirstChildWhichIsA("Tool") do
                task.wait()
            end
            ToolEvent:FireClient(self.player, "OnEquipped")
            self:UnEquippedReady(false)
        end)
        return -- return earaly here
    end
    task.wait()
    self.player.Character.Humanoid:UnequipTools()
    task.wait()
    self.player.Character.Humanoid:EquipTool(tool)
    while not self.player.Character:FindFirstChildWhichIsA("Tool") do
        task.wait()
    end
    ToolEvent:FireClient(self.player, "OnEquipped")
end
function PINV:_FormatWeight(weight)
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
function PINV:_ScaleWeight(weight)
    local ratio = weight / 50 -- base weight is 50kg
    local factor = ratio^(1/3)
    return 1 * factor
end
function PINV:_HoldFishAboveHead(fishName, Weight)
    if self.player.Character:FindFirstChildWhichIsA("Tool") then return end
    self:_CleanHoldingFish()
    local fish = RS:WaitForChild("Template"):WaitForChild("Fish"):FindFirstChild(fishName)
    if not fish then
        fish = RS:WaitForChild("Template"):WaitForChild("Fish"):FindFirstChild("TestFish")
    end
    fish = fish:Clone()
    self.HoldingFish = fish
    fish.Body.Anchored = false
    fish.Body.CanCollide = false
    fish.Body.Massless = true
    fish:ScaleTo(self:_ScaleWeight(Weight))
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
    ClientAnimationEvent:FireClient(self.player, "HoldFishAboveHead")
end

-- MAIN FUNCTIONS
function PINV:GetEquipmentData(type:string, params)
    return c.EQUIPMENT.GED[type](c.EQUIPMENT.GED, params)
end
function PINV:AddRodToInventory(RodData:table, sort:boolean)
    task.spawn(function()
        local template = self.RodTemplate:Clone()
        template.Name = RodData.name
        -- template.UIGradient.Transparency = 1 -- add gradient later TODO
        template.Icon.Image = RodData.icon
        template.Visible = true
        template.Parent = self.RodInventoryTab
        -- TODO: Add Sort
    end)
end
function PINV:AddFishToInventory(FishData:table, sort:boolean)
    task.spawn(function()
        local FishName:string, FishInfo:table = c.FISHING.FISH_DATA:FindFish(FishData.id)
        local template = self.FishTemplate:Clone()
        template.Name = FishName
        template.Container.FishText.Text = FishName
        template.Container.FishText.TextColor3 = c:GetRarityColor(FishInfo.rarity)
        template.Container.FishWeight.Text = self:_FormatWeight(FishData.weight)
        if FishInfo.icon then
            template.Container.Icon.Image = FishInfo.icon
        end
        template.Visible = true
        template.Parent = self.FishInventoryTab

        if self.InventoryFishTween == nil then self.InventoryFishTween = {} end
        local isPressed = false
        local isActive = false
        template.MouseButton1Click:Connect(function()
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
                for i, t in ipairs(self.InventoryFishTween) do
                    if t == tween then
                        table.remove(self.InventoryFishTween, i)
                        break
                    end
                end
                isPressed = false
                tween:Destroy()
            end)
            if isActive and self.HoldingFish then
                self:_CleanHoldingFish()
            else
                self:_HoldFishAboveHead(FishName, FishData.weight)
                isActive = true
            end
        end)

        local FishDataValue = Instance.new("StringValue")
        FishDataValue.Name = "FishData"
        FishDataValue.Value = string.format("%s|%s|%.1f|%d",
            FishName,
            FishInfo.rarity,
            FishData.weight,
            FishData.id)
            FishDataValue.Parent = template
        if sort == nil then
            sort = true
        end
        if sort then
            self.PUI:SortFishInventoryUI()
        end
    end)
end
function PINV:UnEquippedReady(bool:boolean)
    self._OnUnequippedReady = bool
end

-- SETUP
function PINV:_CreateInventory()
    local PlayerGui = self.player:WaitForChild("PlayerGui")
    self.InventoryUI = PlayerGui:WaitForChild("InventoryUI")
    self.TabContainer = self.InventoryUI:WaitForChild("TabContainer")
    self.HotBar = self.InventoryUI:WaitForChild("InventoryFrame")
    self.RodInventoryTab = self.TabContainer:WaitForChild("ContentArea"):WaitForChild("Rod")
    self.RodTemplate = self.RodInventoryTab:WaitForChild("TemplateFishingRod")
    self.FishingRodBtn = self.HotBar:WaitForChild("FishingRod")

    self.FishInventoryTab = self.TabContainer:WaitForChild("ContentArea"):WaitForChild("Fish")
    self.FishTemplate = self.FishInventoryTab:WaitForChild("TemplateFish")
end
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
    if not self.ToolFolder:FindFirstChild("FishingRod") then
        self.FishingRod = ROD:Clone()
        self.FishingRod.Parent = self.ToolFolder
    end
end

-- ENTRY POINTS
function PINV:new(player:Player, PUI:Instance)
    local self = setmetatable({}, PINV)
    self.player = player
    self.PUI = PUI
    self:_CreateInventory()
    self:_CreateBackpack()
    return self
end

-- CLEANING
function PINV:CleanUp()
    if self.FishingRod then
        self.FishingRod:Destroy()
        self.FishingRod = nil
    end
    if self.FishFolder then
        self.FishFolder:Destroy()
        self.FishFolder = nil
    end
    if self.ToolFolder then
        self.ToolFolder:Destroy()
        self.ToolFolder = nil
    end
    if self.Backpack then
        self.Backpack:Destroy()
        self.Backpack = nil
    end
    for _, tween in pairs(self.InventoryFishTween) do
        tween:Cancel()
        tween:Destroy()
    end
    self:_CleanHoldingFish()
    self.player = nil
end

return PINV