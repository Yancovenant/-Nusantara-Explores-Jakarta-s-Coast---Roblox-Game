-- Client UI Manager

local CUI = {}
local Player = game:GetService("Players").LocalPlayer
local Lighting = game:GetService("Lighting")

function CUI:_CreateUI()
    local PlayerGui = Player:WaitForChild("PlayerGui")
	self.tabContainer = PlayerGui:WaitForChild("InventoryUI"):WaitForChild("TabContainer")
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
end

function CUI:UpdateTime(t)
    if t == nil then
        t = {hour = Lighting:GetAttribute("Hour"), min = Lighting:GetAttribute("Minute")}
    end
    local nH = string.format("%02d", t.hour)
    local nM = string.format("%02d", t.min)    
    self.TopBarUI.Time.TimeText.Text = nH .. ":" .. nM
end

-- ENTRY POINTS
function CUI:main()
    self:_CreateUI()
    self.UpdateTime()
end

return CUI