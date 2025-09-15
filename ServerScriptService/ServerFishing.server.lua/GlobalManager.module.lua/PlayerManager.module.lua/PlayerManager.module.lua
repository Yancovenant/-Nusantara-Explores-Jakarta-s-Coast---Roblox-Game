-- PlayerManager.module.lua

local PM = {}
PM.__index = PM
local PINV = require(script.Inventory)
local PUI = require(script.UI)
local DBM = require(script.Parent.Parent.GlobalStorage)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local c = require(ReplicatedStorage:WaitForChild("GlobalConfig"))

local ROD = ReplicatedStorage:WaitForChild("ToolItem"):WaitForChild("FishingRod")


-- HELPER
function PM:_FormatChance(ch)
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


-- MAIN FUNCTIONS
function PM:updatePlayerZone(zone)
    self.PUI:UpdateZoneUI(zone)
end
function PM:ToggleRod()
    self:_CleanHoldingFish()
    self:_EquipTool("FishingRod")
    self:_UpdateHotBarSelected("FishingRod")
end
function PM:ToggleInventory()
    self.PUI:ToggleInventory()
end
function PM:UnEquippedReady(bool)
    self.onUnequippedReady = bool
end
function PM:_CreateLeaderstats()
    local leaderstats
    if not self.player:FindFirstChild("leaderstats") then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = self.player
    else
        leaderstats = self.player:WaitForChild("leaderstats")
    end
    local money, totalCatch, rarestCatch
    money = Instance.new("IntValue")
    money.Name = "Money"
    money.Value = 0
    money.Parent = leaderstats
    self.Money = money

    totalCatch = Instance.new("IntValue")
    totalCatch.Name = "Caught"
    totalCatch.Value = 0
    totalCatch.Parent = leaderstats
    self.TotalCatch = totalCatch

    rarestCatch = Instance.new("StringValue")
    rarestCatch.Name = "Rarest Caught"
    rarestCatch.Value = "0"
    rarestCatch.Parent = leaderstats
    self.RarestCatch = rarestCatch
    -- end)
    return leaderstats
end

-- SETUP FUNCTIONS
function PM:_SetupEventListener()
    -- nothing
end
function PM:_CreateBackpack()
    if not self.player:FindFirstChild("Custom Backpack") then
        self.Backpack = Instance.new("Folder")
        self.Backpack.Name = "Custom Backpack"
        self.Backpack.Parent = self.player

        self.FishFolder = Instance.new("Folder")
        self.FishFolder.Name = "Fish"
        self.FishFolder.Parent = self.backpack

        self.ToolFolder = Instance.new("Folder")
        self.ToolFolder.Name = "Tool"
        self.ToolFolder.Parent = self.backpack
    end
    if not self.ToolFolder:FindFirstChild("FishingRod") then
        self.FishingRod = ROD:Clone()
        self.FishingRod.Parent = self.ToolFolder
    end
end
function PM:_PopulateData()
    self.Leaderstats = self:_CreateLeaderstats()
    self.Data = DBM:LoadPlayerData(self.player)
    self.Money.Value = self.Data.Money
    self.TotalCatch.Value = self.Data.TotalCatch
    self.RarestCatch.Value = self:_FormatChance(self.Data.RarestCatch)
    for id, fish in pairs(self.Data.FishInventory) do
        for _, weight in pairs(fish) do
            self.PINV:AddFishToInventory({
                id = id,
                weight = weight
            }, false)
        end
    end
    self.PUI:SortFishInventoryUI()
    for _, rod in pairs(self.Data.Eequipment.OwnedRods) do -- fix this
        local equippedRod, equippedRodTemplate = self.PINV:GetEquippedEquipment("getRod", rod)
        self.PINV:AddRodToInventory(equippedRod, false)
    end
    self._AutoSaveRunning = true
    task.spawn(function()
        while self._AutoSaveRunning do
            task.wait(c.PLAYER.AUTOSAVE_INTERVAL)
            if not self._AutoSaveRunning then break end
            self:SaveData()
        end
    end)
end

-- ENTRY POINTS
function PM:new(player)
    local self = setmetatable({}, PM)
    self.player = player
    self.currentZone = nil
    self.PUI = PUI:new(player)
    self.PINV = PINV:new(player)
    self:_SetupEventListener()
    self:_CreateBackpack()
    self:_PopulateData()
    return self
end
function PM:CleanUp()
    print("[PlayerManager]: Cleaning up")
end

return PM