-- Client UI Manager

local CUI = {}
local Player = game:GetService("Players").LocalPlayer
local TS:TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

function CUI:_CreateUI()
    local PlayerGui = Player:WaitForChild("PlayerGui")
	self.InventoryUI = PlayerGui:WaitForChild("InventoryUI")
	self.tabContainer = self.InventoryUI:WaitForChild("TabContainer")
	local fishTabBtn = self.tabContainer:WaitForChild("TabNavbar"):WaitForChild("FishTabButton")
	local rodTabBtn = self.tabContainer:WaitForChild("TabNavbar"):WaitForChild("RodTabButton")
	local pageLayout = self.tabContainer:WaitForChild("ContentArea"):FindFirstChildWhichIsA("UIPageLayout")
	local fishPageFrame = self.tabContainer:WaitForChild("ContentArea"):WaitForChild("Fish")
	local rodPageFrame = self.tabContainer:WaitForChild("ContentArea"):WaitForChild("Rod")
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

-- ENTRY POINTS
function CUI:main()
    self:_CreateUI()
	
    -- self.UpdateTime()
end

return CUI