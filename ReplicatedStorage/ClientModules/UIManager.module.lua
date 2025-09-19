-- Client UI Manager

local CUI = {}
local Player = game:GetService("Players").LocalPlayer
local TS:TweenService = game:GetService("TweenService")
local RS:ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local c = require(RS:WaitForChild("GlobalConfig"))

function CUI:_CreateUI()
    local PlayerGui = Player:WaitForChild("PlayerGui")
	self.InventoryUI = PlayerGui:WaitForChild("InventoryUI")
	self.TabContainer = self.InventoryUI:WaitForChild("TabContainer")
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
    self.TopBarUI = PlayerGui:WaitForChild("TopBarUI")
	self.PlayerInfoUI = self.InventoryUI:WaitForChild("PlayerInfo")
	self.LevelUI = self.PlayerInfoUI:WaitForChild("Level")
	self.ExpUI = self.LevelUI:WaitForChild("LevelContainer"):WaitForChild("Exp")
	self.GainedXpText = self.LevelUI:WaitForChild("GainedXP")

	self.FishTabBtn = self.TabContainer:WaitForChild("TabNavbar"):WaitForChild("FishTabButton")
	self.FishInventoryTab = self.TabContainer:WaitForChild("ContentArea"):FindFirstChild('Fish')
	self.FishGridLayout = self.FishInventoryTab:FindFirstChildWhichIsA("UIGridLayout")
end

function CUI:UpdateTime(t)
    if t == nil then
        t = {hour = Lighting:GetAttribute("Hour"), min = Lighting:GetAttribute("Minute")}
    end
    local nH = string.format("%02d", t.hour)
    local nM = string.format("%02d", t.min)    
    self.TopBarUI.Time.TimeText.Text = nH .. ":" .. nM
end

function CUI:UpdateXP(Level, CurrentXp, RequiredXp, GainedXp)
	self.ExpUI.Text.Text = math.floor(CurrentXp) .. " / " .. math.floor(RequiredXp)
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

-- ENTRY POINTS
function CUI:main()
    self:_CreateUI()
	
    -- self.UpdateTime()
end


-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:WrapModule(CUI, "Client_UIManager")


return CUI