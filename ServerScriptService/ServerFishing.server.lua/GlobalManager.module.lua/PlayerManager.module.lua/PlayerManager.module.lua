-- PlayerManager.module.lua
local PM, RS, TS, RunService = {}, game:GetService("ReplicatedStorage"), game:GetService("TweenService"), game:GetService("RunService")
PM.__index = PM
local PINV, PUI, DBM = require(script.Inventory), require(script.UI), require(script.Parent.Parent.GlobalStorage)
local ClientUIEvent = RS:WaitForChild("Remotes"):WaitForChild("ClientEvents"):WaitForChild("UIEvent")
local c = require(RS:WaitForChild("GlobalConfig"))



function PM:_FormatChance(ch)
	local function gcd(a,b) while b~=0 do a,b=b,a%b end return a end
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
function PM:_CalculateXP(info) return (info.weight^.75)*c.RARITY_MULTIXP[info.fishData.rarity] end
function PM:_XPRequiredForLevel(level) return math.floor(c.PLAYER.XPGROWTH.BASE_XP*(level^c.PLAYER.XPGROWTH.GROWTH)) end
function PM:_GetLevelFromXP(xp)
	local level=1 while xp>=self:_XPRequiredForLevel(level) do xp -= self:_XPRequiredForLevel(level) level += 1 end
	return level,xp,self:_XPRequiredForLevel(level)
end
function PM:_UpdateXP(gxp)
	self.Data.PlayerXP += gxp local l,cx,rx = self:_GetLevelFromXP(self.Data.PlayerXP)
	if self.Data.PlayerLevel < l then self.Data.PlayerLevel = l self.PUI:UpdateLevel(l) end
	ClientUIEvent:FireClient(self.player,"UpdateXP",self.Data.PlayerLevel,cx,rx,gxp)
end
function PM:_UpdateMoney(val)
	val=val or 0 self.Data.Money += val self.Money.Value=self.Data.Money
	ClientUIEvent:FireClient(self.player,"UpdateMoney",self.Data.Money,val)
end
function PM:_RefreshBuyShop()
    self.SelectedBuy, self.SelectedFishSell = nil, nil
    self.PUI.BuySelectedTotalLabel.Visible, self.PUI.SellSelectedTotalLabel.Visible = false, false
    for _, frame in pairs(self.PUI.BuyFrame:GetChildren()) do
        if frame:IsA("TextButton") and frame.Name ~= "TemplateItem" and frame:GetAttribute("itemType") == "Rod" then
            frame:Destroy()
        end
    end
    local ownedRods = self.Data.Equipment.OwnedRods
    for rodName, rodData in pairs(c.EQUIPMENT.GED.RODS) do
         if not table.find(ownedRods, rodData.id) then
            local template = self.PUI.BuyTemplateItem:Clone()
            template.Name, template.Label.Text = rodName, rodName
            template.Label.TextColor3, template.Icon.Image = c:GetRarityColor(rodData.rarity), rodData.icon
            template.Price.Text, template.LayoutOrder = math.floor(rodData.price), rodData.id
            template.Visible, template.Parent = true, self.PUI.BuyFrame
            template:SetAttribute("itemType", "Rod")
            template:SetAttribute("price", rodData.price)
            template:SetAttribute("id", rodData.id)
            template.MouseButton1Click:Connect(function()
                if self.SelectedBuy == template then return end
                if self.SelectedBuy then self.SelectedBuy.Select.Visible = false end
                self.SelectedBuy = template
                template.Select.Visible = true
                self.PUI.BuySelectedTotalLabel.Text = "Total : " .. rodData.price
                self.PUI.BuySelectedTotalLabel.Visible = true
            end)
        end
    end
end

-- MAIN FUNCTIONS
--- Proximity
function PM:ToggleBoatShopUI(...)
    local isShown = self.PUI.BoatShopTab.Visible
    self.PUI:ToggleBoatShopUI(not isShown, ...)
    if isShown then
        -- update ui if needed
    end
end
function PM:_CleanUpBoat()
    if self.BoatHeartbeat then
        self.BoatHeartbeat:Disconnect()
        self.BoatHeartbeat = nil
    end
end
function PM:OnBoatDrive(Seat:Part)
    local hum = self.player.Character.Humanoid
    local isSitting = hum.Sit == true and hum.SeatPart == Seat
    Seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        local SeatHum = Seat.Occupant
        if not SeatHum then
            self:_CleanUpBoat()
        end
    end)
    if isSitting then
        hum.Sit = false
    else
        Seat:Sit(hum)
        -- do boat movement
        Seat:FindFirstChildWhichIsA("ProximityPrompt").Enabled = false
        self:_CleanUpBoat()
        local BoatCFG = {}
        if Seat:FindFirstChild("TAccel") then
            BoatCFG.physics = {
                maxSpeed = Seat.TMaxSpeed.Value,
                reverseMaxSpeed = Seat.TReverseMaxSpeed.Value,
                acceleration = Seat.TAccel.Value,
                brakeDecel = Seat.TDecel.Value,
                turnRate = math.rad(Seat.TTurnRate.Value),
                linearDamping = c.BOATS.BOAT_LIST[Seat.Parent.Name].physics.linearDamping,
                angularDamping = c.BOATS.BOAT_LIST[Seat.Parent.Name].physics.angularDamping,
            }
        else
            BoatCFG = c.BOATS.BOAT_LIST[Seat.Parent.Name]
        end
        local Hull = Seat.Parent.Hull
        local Thrust = Hull.VectorForce
        local Rudder = Hull.Torque
        local CurrentForce = 0
        self.BoatHeartbeat = RunService.Heartbeat:Connect(function(dt)
            if not Seat or not Hull then self.BoatHeartbeat:Disconnect() end
            
            local Forward = Hull.CFrame.LookVector
            local V = Hull.AssemblyLinearVelocity
            local Speed = V:Dot(Forward)

            -- THRUST
            local TargetForce = 0
            local Steer
            if Seat.Throttle > 0 then
                TargetForce = BoatCFG.physics.maxSpeed
            elseif Seat.Throttle < 0 then 
                TargetForce = -BoatCFG.physics.reverseMaxSpeed
            else 
                TargetForce = 0
            end
            if TargetForce == 0 then
                local s = math.abs(CurrentForce)
                local Decel = BoatCFG.physics.brakeDecel * dt
                s = math.max(0, s - Decel)
                CurrentForce = (CurrentForce >= 0) and s or -s
            else
                local Towards = (TargetForce > CurrentForce) and BoatCFG.physics.acceleration or BoatCFG.physics.brakeDecel
                CurrentForce = math.lerp(CurrentForce, TargetForce, math.clamp((Towards * dt) / math.max(1, math.abs(TargetForce - CurrentForce)), 0, 1))
            end
            Thrust.Force = Forward * CurrentForce * Hull:GetMass()
            if Speed > 0 then
                Steer = -Seat.Steer
            elseif Speed < 0 then
                Steer = Seat.Steer
            else
                Steer = -Seat.Steer
            end
            local SpeedFactor
            if math.abs(TargetForce) > 0 then
                SpeedFactor = math.clamp(math.abs(Speed) / math.abs(TargetForce), 0, 1)
            else
                SpeedFactor = 0
            end
            local RudderForce = Hull:GetMass() * BoatCFG.physics.turnRate * (math.min(Hull.Size.X, Hull.Size.Z) / 2)
            local RudderPush = Steer * RudderForce * SpeedFactor
            Rudder.Torque = Vector3.new(RudderPush, 0, 0)

            Hull.AssemblyLinearVelocity *= (1 - BoatCFG.physics.linearDamping * 0.01)
            Hull.AssemblyAngularVelocity *= (1 - BoatCFG.physics.angularDamping * 0.01)
        end)
    end
end

function PM:updatePlayerZone(zone)
    self.PUI:UpdateZoneUI(zone)
end
function PM:ToggleRod()
    self.PINV:_CleanHoldingFish()
    self.PINV:_EquipTool("FishingRod")
    self.PINV:ToggleHolsterRod()
    self.PUI:_UpdateHotBarSelected("FishingRod")
end
function PM:ToggleInventory()
    self.PUI:ToggleInventory()
end
function PM:UnEquippedReady(bool)
    self.PINV:UnEquippedReady(bool)
    self.player:SetAttribute("IsFishingServer", not bool)
    self.player:SetAttribute("PowerServer", 0)
end
function PM:TogglePlayerModal()
    self.PUI:TogglePlayerModal(self.Data.Attributes)
end
function PM:ShowFishBiteUI(visible)
    self.PUI:ShowFishBiteUI(visible)
end
function PM:ShowPowerCategoryUI(power)
    self.PUI:ShowPowerCategoryUI(power)
end
function PM:CatchResultSuccess(info)
    local FishInvFrame, FishShopFrame = self.PINV:AddFishToInventory({
        id = info.fishData.id,
        weight = info.weight,
    }, true)
    self:_SetupFishSellEventListener(FishShopFrame)
    if self.Data.FishInventory[tostring(info.fishData.id)] == nil then
        self.Data.FishInventory[tostring(info.fishData.id)] = {}
    end
    table.insert(self.Data.FishInventory[tostring(info.fishData.id)], {
        weight = info.weight,
        locked = false,
        uniqueId = self.PINV.FishCounter
    })
    if self.FishFrame[tostring(self.PINV.FishCounter)] == nil then
        self.FishFrame[tostring(self.PINV.FishCounter)] = {
            FishInvFrame = FishInvFrame,
            FishShopFrame = FishShopFrame
        }
    end
    -- loop wrapper leaderstats + data
    self.TotalCatch.Value = self.TotalCatch.Value + 1
    self.Data.TotalCatch = self.TotalCatch.Value

    if self.Data.RarestCatch > info.fishData.baseChance or self.Data.RarestCatch == 0 then
        self.RarestCatch.Value = self:_FormatChance(info.fishData.baseChance)
        self.Data.RarestCatch = info.fishData.baseChance
    end
    local GainedXp = self:_CalculateXP(info)
    self:_UpdateXP(GainedXp)

    if not self.Data.FishIndex[tostring(info.fishData.id)] then
        self.Data.FishIndex[tostring(info.fishData.id)] = {
            firstCaught = info.weight,
            bestWeight = info.weight,
            totalCaught = 1,
            lastCaught = os.time()
        }
    else
        local FishIndex = self.Data.FishIndex[tostring(info.fishData.id)]
        FishIndex.totalCaught += 1
        FishIndex.lastCaught = os.time()
        if info.weight > FishIndex.bestWeight then
            FishIndex.bestWeight = info.weight
        end
    end
    self.PUI:UpdateFishIndex(self.Data.FishIndex)
end

function PM:SaveData(locksession, force)
    DBM:SaveDataPlayer(self.player, self.Data, locksession, force)
end

-- SETUP FUNCTIONS
function PM:_SetupFishSellEventListener(template:Instance)
    template.MouseButton1Click:Connect(function()
        if self.SelectedFishSell == template then return end
        if template:GetAttribute("locked") then return end
        if self.SelectedFishSell and self.SelectedFishSell ~= template then
            self.SelectedFishSell.Select.Visible = false
        end
        self.SelectedFishSell = template
        template.Select.Visible = true
        self.PUI.SellSelectedTotalLabel.Text = "Total : " .. math.floor(template:GetAttribute("price"))
        self.PUI.SellSelectedTotalLabel.Visible = true
    end)
end
function PM:_SetupInvRodEventListener(template:Instance)
    template.MouseButton1Click:Connect(function()
        if template:GetAttribute("id") <= 0 then return end
        if self.player:GetAttribute("IsFishing") then return end
        if self.player.Character:FindFirstChildWhichIsA("Tool") then return end
        self.Data.Equipment.EquippedRod = template:GetAttribute("id")
        self:_UpdateFishingRodModel()
        if self.PINV.IsHolsterEquip then
            self.PINV.HolsterRod:Destroy()
            self.PINV.HolsterRod = self.PINV.RodAccessory:Clone()
            self.player.Character:WaitForChild("Humanoid"):AddAccessory(self.PINV.HolsterRod)
        end
        self.PUI:SortRodInventoryUI()
    end)
end
function PM:_SetupPlayerAttributes()
    local EquippedRod = self.Data.Equipment.EquippedRod
    local dataRod, modelRod = self.PINV:GetEquipmentData("GetRod", EquippedRod)
    self.Data.Attributes = {
        maxWeight = dataRod.maxWeight,
        strength = dataRod.strength + (self.Data.PlayerStrength or 0),
        luck = dataRod.luck + (self.Data.playerLuck or 0),
        attraction = dataRod.attraction + (self.Data.playerAttraction or 0)
    }
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
    self.PINV:CreateHolsterRodAccessory(RodModel)
    self:_SetupPlayerAttributes()
end

-- ENTRY POINTS
-- == Clean Tween Shop Page ==
function PM:_CleanUpFishingShopBuyPage()
    if self.FailedBuyTween then
        self.FailedBuyTween:Cancel()
        self.FailedBuyTween = nil
    end
    if self.FailedBuyTween2 then
        self.FailedBuyTween2:Cancel()
        self.FailedBuyTween2 = nil
    end
    self.PUI.BuySelectedButton.BackgroundColor3 = Color3.fromRGB(30, 120, 60)
    self.PUI.BuySelectedButton.Frame.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
    self.PUI.BuySelectedButton.Frame.TextLabel.Text = "Buy Selected"
end
-- == Toggle Fish Shop Page ==
function PM:ToggleFishShopUI(GRM, ...)
    local isShown = self.PUI.FishShopTab.Visible
    self.PUI:ToggleFishShopUI(not isShown, ...)
    if not isShown then
        self:_RefreshBuyShop()
        ClientUIEvent:FireClient(self.player, "SortFishShopUI")
        local sellFrame = self.PUI.FishShopTab.RightPanel.ContentArea.Sell.ScrollingFrame
        for _, fish in pairs(sellFrame:GetChildren()) do
            if fish.Name ~= "TemplateItem" and fish:IsA("TextButton") then
                local finalPrice, fishId = GRM:FishValue(fish), tostring(fish:GetAttribute("id"))
                fish:SetAttribute("price", finalPrice)
                fish.Select.Visible, fish.Price.Text = false, math.floor(finalPrice)
                local invList = self.Data.FishInventory[fishId]
                if invList then
                    local uniqueId = fish:GetAttribute("uniqueId")
                    for _, weight in ipairs(invList) do
                        print(weight)
                        if type(weight) == "table" and weight.uniqueId == uniqueId then
                            print("uniqueId", uniqueId)
                            fish:SetAttribute("locked", weight.locked == true)
                            fish.Locked.Visible = weight.locked == true
                            break
                        end
                    end
                end
            end
        end
        self:_CleanUpFishingShopBuyPage()
    end
end
-- == Populate Data Stored ==
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
    return leaderstats
end
function PM:_PopulateData()
    self.Leaderstats = self:_CreateLeaderstats()
    self.Data = DBM:LoadDataPlayer(self.player)
    
    self.TotalCatch.Value = self.Data.TotalCatch
    self.RarestCatch.Value = self:_FormatChance(self.Data.RarestCatch)
    
    -- LAZY LOAD FISH
    task.spawn(function()
        local fc=self.PINV.FishCounter for id,wList in pairs(self.Data.FishInventory) do
            for _,w in pairs(wList) do fc += 1 w.uniqueId=fc
                local fi,fs=self.PINV:AddFishToInventory({id=id,weight=type(w)=="table"and w.weight or w,locked=type(w)=="table"and w.locked},false)
                self.FishFrame[tostring(fc)]={FishInvFrame=fi,FishShopFrame=fs}
                self:_SetupFishSellEventListener(fs)
            end
        end
        self.PUI:SortFishInventoryUI()
    end)

    self.PUI:UpdateLevel(self.Data.PlayerLevel)
    self:_UpdateXP(0)
    self:_UpdateMoney(0)
    for _, rod in pairs(self.Data.Equipment.OwnedRods) do
        local RodData:table, RodModel:Model = self.PINV:GetEquipmentData("GetRod", rod)
        self:_SetupInvRodEventListener(self.PINV:AddRodToInventory(RodData, false))
    end
    self.PUI:SortRodInventoryUI()

    self.PUI:PopulateFishIndex(self.Data.FishIndex)
    self.PUI:PopulateBoatShop(self.Data.Equipment.OwnedBoats)

    self._AutoSaveRunning = true
    task.spawn(function()
        while self._AutoSaveRunning do
            task.wait(c.PLAYER.AUTOSAVE_INTERVAL)
            if not self._AutoSaveRunning then break end
            self:SaveData(true)
        end
    end)
end
function PM:_SetupEventListener()
    self.FishingRodBtnClickConnection = self.PINV.FishingRodBtn.MouseButton1Click:Connect(function()
        self:ToggleRod()
    end)
    self.SellAllButtonClickConnection = self.PUI.SellAllBtn.MouseButton1Click:Connect(function()
        local sellableFish = {}
        local totalValue = 0
        for _, fish in pairs(self.PUI.FishShopTab.RightPanel.ContentArea.Sell.ScrollingFrame:GetChildren()) do
            if fish.Name ~= "TemplateItem" and fish:IsA("TextButton") and not fish:GetAttribute("locked") then
                table.insert(sellableFish, {
                    price = fish:GetAttribute("price") or 0,
                    fishId = tostring(fish:GetAttribute("id")),
                    weight = fish:GetAttribute("weight"), 
                    uniqueId = fish:GetAttribute("uniqueId"),
                    fishFrame = self.FishFrame[tostring(fish:GetAttribute("uniqueId"))]
                })
                totalValue += fish:GetAttribute("price") or 0
            end
        end
        for _, fishData in ipairs(sellableFish) do
            local invTable = self.Data.FishInventory[fishData.fishId]
            if invTable then
                -- Reverse iteration prevents index shifting during removal
                for i = #invTable, 1, -1 do
                    local item = invTable[i]
                    if (type(item) == "table" and item.uniqueId == fishData.uniqueId) or item == fishData.weight then
                        table.remove(invTable, i)
                    end
                end
                -- Clean empty tables
                if #invTable == 0 then self.Data.FishInventory[fishData.fishId] = nil end
            end
            if fishData.fishFrame then
                fishData.fishFrame.FishInvFrame:Destroy()
                fishData.fishFrame.FishShopFrame:Destroy()
                self.FishFrame[tostring(fishData.uniqueId)] = nil
            end
        end

        self:_UpdateMoney(totalValue)
        self.PUI:SortFishInventoryUI()
    end)
    self.BuySelectedButtonClickConnection = self.PUI.BuySelectedButton.MouseButton1Click:Connect(function()
        if self._BuyProcessing then return end
        self._BuyProcessing = true
        if not self.SelectedBuy then
            self._BuyProcessing = false
            return
        end
        local price = self.SelectedBuy:GetAttribute("price")
        self:_CleanUpFishingShopBuyPage()
        if self.Data.Money < price then
            self.FailedBuyTween = TS:Create(self.PUI.BuySelectedButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(170, 0, 0)})
            self.FailedBuyTween2 = TS:Create(self.PUI.BuySelectedButton.Frame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(195, 0, 0)})
            self.FailedBuyTween:Play()
            self.FailedBuyTween2:Play()
            self.PUI.BuySelectedButton.Frame.TextLabel.Text = "Not Enough Money"
            self.FailedBuyTween2.Completed:Connect(function()
                self:_CleanUpFishingShopBuyPage()
                self._BuyProcessing = false
            end)
        else
            local id = self.SelectedBuy:GetAttribute("id")
            local RodData, RodModel = self.PINV:GetEquipmentData("GetRod", id)
            table.insert(self.Data.Equipment.OwnedRods, id)
            self:_SetupInvRodEventListener(self.PINV:AddRodToInventory(RodData, true))
            self:_UpdateMoney(-price)
            self:_RefreshBuyShop()
            self._BuyProcessing = false
        end
    end)
    self.SellSelectedButtonClickConnection = self.PUI.SellSelectedButton.MouseButton1Click:Connect(function()
        -- OPTIMIZED: Early returns + debouncing
        if self._SellProcessing or not self.SelectedFishSell then return end
        self._SellProcessing = true
        
        -- OPTIMIZED: Cache attributes in single pass
        local fishData = {
            price = self.SelectedFishSell:GetAttribute("price") or 0,
            fishId = tostring(self.SelectedFishSell:GetAttribute("id")),
            weight = self.SelectedFishSell:GetAttribute("weight"),
            uniqueId = self.SelectedFishSell:GetAttribute("uniqueId")
        }
        
        -- OPTIMIZED: Single loop with reverse iteration
        local invTable = self.Data.FishInventory[fishData.fishId]
        if invTable then
            for i = #invTable, 1, -1 do
                local item = invTable[i]
                if (type(item) == "table" and item.uniqueId == fishData.uniqueId) or item == fishData.weight then
                    table.remove(invTable, i)
                    break
                end
            end
            if #invTable == 0 then self.Data.FishInventory[fishData.fishId] = nil end
        end
        
        -- OPTIMIZED: Direct frame destruction
        local fishFrame = self.FishFrame[tostring(fishData.uniqueId)]
        if fishFrame then
            fishFrame.FishInvFrame:Destroy()
            fishFrame.FishShopFrame:Destroy()
            self.FishFrame[tostring(fishData.uniqueId)] = nil
        end
        self:_UpdateMoney(fishData.price)
        self.PUI:SortFishInventoryUI()
        self:_RefreshBuyShop()
        self._SellProcessing = false
    end)
    self.StatHotBarBtnClickConnection = self.PUI.StatBarBtn.MouseButton1Click:Connect(function()
        self:TogglePlayerModal()
    end)
end
function PM:new(player)
    local self = setmetatable({}, PM)
    self.player = player
    self.currentZone = nil
    self.PUI = PUI:new(player)
    self.PINV = PINV:new(player, self.PUI)
    self:_SetupEventListener()

    self.FishFrame = {}

    self:_PopulateData()
    self:_UpdateFishingRodModel()
    self.PINV:ToggleHolsterRod()
    return self
end
function PM:CleanUp()
	self._AutoSaveRunning=nil self:SaveData(false,true)
	for k,v in pairs(self) do if typeof(v)=="RBXScriptConnection" then v:Disconnect() elseif type(v)=="table"then if v.CleanUp then v:CleanUp()end end end
	self:_CleanUpBoat() self.PINV=nil self.PUI=nil self.player=nil
end

-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:WrapModule(PM, "PlayerManagers")


return PM