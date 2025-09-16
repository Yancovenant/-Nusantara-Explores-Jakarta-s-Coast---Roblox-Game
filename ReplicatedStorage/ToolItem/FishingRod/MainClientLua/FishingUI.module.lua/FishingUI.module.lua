-- Fishing UI Client

local LUIC = {}

local TS = game:GetService("TweenService")

local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local c = require(ReplicatedStorage:WaitForChild("GlobalConfig"))


-- HELPERS
local function FormatWeight(w)
    if w >= 1000 then
		local tons = w / 1000
		if tons >= 1 and tons < 1000 then
			return string.format("%.1f Ton", tons)
		else
			return string.format("%.0f Tons", tons)
		end
	else
		return string.format("%.1f Kg", w)
	end
end
local function FormatChance(ch)
    -- Convert decimal back to fraction format
	local function gcd(a, b)
		while b ~= 0 do a, b = b, a % b end
		return a
	end
	local function decimalToFraction(decimal)
		local tolerance = 1e-6
		local h1, h2, k1, k2 = 1, 0, 0, 1
		local x = decimal
		while math.abs(x - math.floor(x + 0.5)) > tolerance do
			x = 1 / (x - math.floor(x))
			h1, h2 = h1 * math.floor(x) + h2, h1
			k1, k2 = k1 * math.floor(x) + k2, k1
		end
		return math.floor(x + 0.5) * h1 + h2, h1
	end
	local numerator, denominator = decimalToFraction(ch)
	local divisor = gcd(numerator, denominator)
	numerator = numerator / divisor
	denominator = denominator / divisor
	return string.format("1/%d", denominator)
end

-- STATIC FUNCTIONS
function LUIC:ShowPopup(params:table)
    task.spawn(function()
        local message = self.PopupFrame:FindFirstChild("PopupTemplate"):Clone()
		message.Parent = self.PopupFrame
		table.insert(self.messagePopup, message)
		for childNames, props in pairs(params) do
			local child = message:FindFirstChild(childNames)
			if child then
				for propName, propValue in pairs(props) do
					child[propName] = propValue
				end
			end
		end
		message.Visible = true
		task.wait(1.5)
		message:Destroy()
        for i, msg in ipairs(self.messagePopup) do
            if msg == message then table.remove(self.messagePopup, i) end
        end
    end)
end
function LUIC:ShowFishPopup(CatchInfo:table)
    self.PopupFish.ImageLabel.Image = CatchInfo.fishData.icon
	self.PopupFish.FishInfo.TextColor3 = c:GetRarityColor(CatchInfo.fishData.rarity)
	self.PopupFish.FishInfo.Text = CatchInfo.fishName .. " (" .. FormatWeight(CatchInfo.weight) .. ")"
	self.PopupFish.Chance.Text = FormatChance(CatchInfo.fishData.baseChance)

	self.PopupFish.Visible = true
	self.FishPopupTween = TS:Create(
		self.PopupFish,
		TweenInfo.new(.3, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
		{
			Position = self.PopupFish.Position + UDim2.new(0, 0.1, 0, 0),
			Size = UDim2.new(0.8, 0, 0.5, 0)
		}
	)
	self.FishPopupTween:Play()
	self.FishPopupTween.Completed:Wait()
	task.wait(1.5)
	self.FishPopupTweenEnd = TS:Create(
		self.PopupFish,
		TweenInfo.new(.3, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
		{
			Position = self.PopupFish.Position - UDim2.new(0, 0.1, 0, 0),
			Size = UDim2.new(0, 0, 0, 0)
		}
	)
	self.FishPopupTweenEnd:Play()
	self.FishPopupTweenEnd.Completed:Wait()
	self.PopupFish.Visible = false
end

-- CLEANUP
function LUIC:CleanUp()
    if self.FishPopupTween then
		self.FishPopupTween:Cancel()
		self.FishPopupTween = nil
	end
	if self.FishPopupTweenEnd then
		self.FishPopupTweenEnd:Cancel()
		self.FishPopupTweenEnd = nil
	end
	if self.messagePopup then
		for _, message in self.messagePopup do
			message:Destroy()
		end
	end
	self.messagePopup = {}
end

-- ENTRY POINTS
function LUIC:CreateFishingUI()
    local fishingUI = Player:WaitForChild("PlayerGui"):WaitForChild("FishingUI")
    self.AutoFishButton =  fishingUI:WaitForChild("AutoFishButton")
    self.PowerBar = fishingUI:WaitForChild("PowerBar")
	self.PopupFrame = fishingUI:WaitForChild("PopupFrame")
	self.PopupFish = fishingUI:WaitForChild("PopupFish")
	self.messagePopup = {}
end

return LUIC