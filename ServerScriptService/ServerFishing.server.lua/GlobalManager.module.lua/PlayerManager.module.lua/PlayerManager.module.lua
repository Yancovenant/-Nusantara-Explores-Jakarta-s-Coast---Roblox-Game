-- PlayerManager.module.lua

local PM = {}
PM.__index = PM
local PINV = require(script.Inventory)
local PUI = require(script.UI)
local DBM = require(script.Parent.Parent.GlobalStorage)

local RS:ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientUIEvent:RemoteEvent = RS:WaitForChild("Remotes"):WaitForChild("ClientEvents"):WaitForChild("UIEvent")

local c = require(RS:WaitForChild("GlobalConfig"))


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


-- PLAYER PROGRESSION
function PM:_CalculateXP(info)
    local multi = c.RARITY_MULTIXP[info.fishData.rarity]
    local xp = (info.weight ^ 0.75) * multi
    return xp
end
--
function PM:_XPRequiredForLevel(level)
    return math.floor(c.PLAYER.XPGROWTH.BASE_XP * (level ^ c.PLAYER.XPGROWTH.GROWTH))
end
function PM:_GetLevelFromXP(xp)
    local level = 1
    while xp >= self:_XPRequiredForLevel(level) do
        xp -= self:_XPRequiredForLevel(level)
        level += 1
    end
    return level, xp, self:_XPRequiredForLevel(level)
end
function PM:_UpdateXP(GainedXp)
    self.Data.PlayerXP += GainedXp
    local Lvl, CurrentXP, RequiredXP = self:_GetLevelFromXP(self.Data.PlayerXP)
    if self.Data.PlayerLevel < Lvl then
        print("OnLevelUp")
        self.Data.PlayerLevel = Lvl
        self.PUI:UpdateLevel(self.Data.PlayerLevel)
        -- need to update data.playerlevel
    end
    ClientUIEvent:FireClient(self.player, "UpdateXP", self.Data.PlayerLevel, CurrentXP, RequiredXP, GainedXp)
end


-- MAIN FUNCTIONS
function PM:updatePlayerZone(zone)
    self.PUI:UpdateZoneUI(zone)
end
function PM:ToggleRod()
    self.PINV:_CleanHoldingFish()
    self.PINV:_EquipTool("FishingRod")
    self.PUI:_UpdateHotBarSelected("FishingRod")
end
function PM:ToggleInventory()
    self.PUI:ToggleInventory()
end
function PM:UnEquippedReady(bool)
    self.PINV:UnEquippedReady(bool)
end
function PM:ShowFishBiteUI(visible)
    self.PUI:ShowFishBiteUI(visible)
end
function PM:ShowPowerCategoryUI(power)
    self.PUI:ShowPowerCategoryUI(power)
end
function PM:CatchResultSuccess(info)
    self.PINV:AddFishToInventory({
        id = info.fishData.id,
        weight = info.weight,
    }, true)
    if self.Data.FishInventory[tostring(info.fishData.id)] == nil then
        self.Data.FishInventory[tostring(info.fishData.id)] = {}
    end
    table.insert(
        self.Data.FishInventory[tostring(info.fishData.id)],
        info.weight
    )
    -- loop wrapper leaderstats + data
    self.TotalCatch.Value = self.TotalCatch.Value + 1
    self.Data.TotalCatch = self.TotalCatch.Value

    if self.Data.RarestCatch > info.fishData.baseChance or self.Data.RarestCatch == 0 then
        self.RarestCatch.Value = self:_FormatChance(info.fishData.baseChance)
        self.Data.RarestCatch = info.fishData.baseChance
    end
    local GainedXp = self:_CalculateXP(info)
    self:_UpdateXP(GainedXp)
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
function PM:SaveData(locksession, force)
    DBM:SaveDataPlayer(self.player, self.Data, locksession, force)
end

-- SETUP FUNCTIONS
function PM:_SetupEventListener()
    self.FishingRodBtnClickConnection = self.PINV.FishingRodBtn.MouseButton1Click:Connect(function()
        self:ToggleRod()
    end)
end
function PM:_SetupPlayerAttributes()
    local GED = c.EQUIPMENT.GED
    local EquippedRod = self.Data.Equipment.EquippedRod
    local dataRod, modelRod = self.PINV:GetEquipmentData("GetRod", EquippedRod)
    self.Data.Attributes = {
        maxWeight = dataRod.maxWeight
    }
end
function PM:_PopulateData()
    self.Leaderstats = self:_CreateLeaderstats()
    self.Data = DBM:LoadDataPlayer(self.player)
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
    self:_SetupPlayerAttributes()
    self.PUI:UpdateLevel(self.Data.PlayerLevel)
    self.PUI:SortFishInventoryUI()
    for _, rod in pairs(self.Data.Equipment.OwnedRods) do -- FIX THIS/NAMING CONVENTION
        local RodData:table, RodModel:Model = self.PINV:GetEquipmentData("GetRod", rod)
        self.PINV:AddRodToInventory(RodData, false)
    end
    self._AutoSaveRunning = true
    task.spawn(function()
        while self._AutoSaveRunning do
            task.wait(c.PLAYER.AUTOSAVE_INTERVAL)
            if not self._AutoSaveRunning then break end
            self:SaveData(true)
        end
    end)
end
function PM:_UpdateFishingRodModel()
    local RodData, RodModel = self.PINV:GetEquipmentData("GetRod", self.Data.Equipment.EquippedRod)
    if not RodData or not self.PINV.FishingRod then return end
    self.PINV.FishingRod:FindFirstChild("Handle"):Destroy()
    self.PINV.FishingRod:FindFirstChild("Rod"):Destroy()
    local Rod = RodModel:FindFirstChild("Rod"):Clone()
    local handle = RodModel:FindFirstChild("Handle"):Clone()
    Rod.Parent = self.PINV.FishingRod
    handle.Parent = self.PINV.FishingRod
    handle:FindFirstChild("Main").Part1 = Rod

    self.PUI.RodHotBar.Icon.Image = RodData.icon

    --- ROD ACCSESSORY
    local hum = self.player.Character:WaitForChild("Humanoid")
    local rodAccessory = Instance.new("Accessory")
    rodAccessory.Name = "FishingRod"

    local rodHandle = RodModel:FindFirstChild("Handle"):Clone()
    rodHandle.Name = "Handle"
    rodHandle.Parent = rodAccessory
    
    -- Add attachment that matches character hand
    local gripAttachment = Instance.new("Attachment")
    gripAttachment.Name = "BodyBackAttachment"
    -- gripAttachment.CFrame = CFrame.new(0, 0, 0) -- offset from hand
    gripAttachment.Position = Vector3.new(0.7, 0.2, 0.7)
    gripAttachment.Orientation = Vector3.new(90, 90, 0)
    gripAttachment.Parent = rodHandle
    
    hum:AddAccessory(rodAccessory)

    -- local handle2 = Instance.new("Part")
    -- handle2.Name = "Handle"
    -- handle2.Size = Vector3.new(1, 1.6, 1)
    -- handle2.Parent = clockworksShades

    -- local mesh = Instance.new("SpecialMesh")
    -- mesh.Name = "Mesh"
    -- mesh.Scale = Vector3.new(1, 1.3, 1)
    -- mesh.MeshId = "rbxassetid://1577360"
    -- mesh.TextureId = "rbxassetid://1577349"
    -- mesh.Parent = handle2
    -- local torso = self.player.Character.UpperTorso or self.player.Character:FindFirstChild("Torso")
    -- self.HolsterFishingRod = Instance.new("Part")
    -- hrod.Parent = self.HolsterFishingRod
    -- self.HolsterFishingRod.Name = "HolsterAttach"
    -- self.HolsterFishingRod.Transparency = 1
    -- self.HolsterFishingRod.Size = Vector3.new(0.2, 0.2, 0.2)
    -- self.HolsterFishingRod.Anchored = false
    -- self.HolsterFishingRod.CanCollide = false
    -- self.HolsterFishingRod.Massless = true
    -- self.HolsterFishingRod.Parent = torso
    -- self.HolsterFishingRod.CFrame = torso.CFrame * CFrame.new(0, 0.1, 0.45)

    -- -- ensure non-colliding, non-anchored
    -- for _, inst in ipairs(self.HolsterFishingRod:GetDescendants()) do
    --     if inst:IsA("BasePart") then
    --         inst.Anchored = false
    --         inst.CanCollide = false
    --         inst.Massless = true
    --     end
    -- end

    -- -- Weld attach to torso
    -- local w0 = Instance.new("WeldConstraint")
    -- w0.Part0 = self.HolsterFishingRod
    -- w0.Part1 = torso
    -- w0.Parent = self.HolsterFishingRod
    
    -- local w2 = Instance.new("WeldConstraint")
    -- w2.Part0 = hrod:FindFirstChild("Handle")
    -- w2.Part1 = self.HolsterFishingRod
    -- w2.Parent = self.HolsterFishingRod
    
    -- -- rotate to look natural on back (tweak as needed)
    -- -- slight tilt, point tip upward-right
    -- hrod.Position = self.HolsterFishingRod.Position
    -- local pivot = self.HolsterFishingRod.CFrame
    -- self.HolsterFishingRod:PivotTo(pivot * CFrame.Angles(math.rad(15), math.rad(20), math.rad(10)))
end

-- ENTRY POINTS
function PM:new(player)
    local self = setmetatable({}, PM)
    self.player = player
    self.currentZone = nil
    self.PUI = PUI:new(player)
    self.PINV = PINV:new(player, self.PUI)
    self:_SetupEventListener()
    
    self:_PopulateData()
    self:_UpdateFishingRodModel()
    return self
end
function PM:CleanUp()
    self._autoSaveRunning = false
    self:SaveData(false, true)
    if self.FishingRodBtnClickConnection then
        self.FishingRodBtnClickConnection:Disconnect()
        self.FishingRodBtnClickConnection = nil
    end
    self.PUI:CleanUp()
    self.PINV:CleanUp()
    self.PUI = nil
    self.PINV = nil
    self.player = nil
end

-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:WrapModule(PM, "PlayerManagers")


return PM