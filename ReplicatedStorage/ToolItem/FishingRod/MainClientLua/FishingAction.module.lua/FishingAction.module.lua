-- Fishing Action Module

local FA = {}
local FUI = require(script.Parent.FishingUI)
local ROD = script.Parent.Parent


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Player:Player = game:GetService("Players").LocalPlayer
local Humanoid:Humanoid = Player.Character.Humanoid

local CAM = require(ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("AnimationManager"))

local ReelingAnimation = ROD:WaitForChild("Animations"):WaitForChild("Reeling")
local CatchAnimation = ROD:WaitForChild("Animations"):WaitForChild("Catch")
local StartCastAnimation = ROD:WaitForChild("Animations"):WaitForChild("StartCast")
local ReleaseCastAnimation = ROD:WaitForChild("Animations"):WaitForChild("ReleaseCast")
local IdleFishingAnimation = ROD:WaitForChild("Animations"):WaitForChild("IdleFishing")

local GlobalRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GlobalEvents")
local GlobalEvent = GlobalRemotes:WaitForChild("GlobalEvent")
local ToolEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")

local FishingRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FishingEvents")
local ReelComplete = FishingRemotes:WaitForChild("ReelComplete")
local StartCast = FishingRemotes:WaitForChild("StartCast")

local c = require(ReplicatedStorage:WaitForChild("GlobalConfig"))

local power = 0

-- HELPER
-- === player ===
function FA:_getAttr(key)
    return Player.Character:GetAttribute(key)
end
function FA:IsFishing() return self:_getAttr("IsFishing") end
function FA:IsCasting() return self:_getAttr("IsCasting") end
function FA:CanFish() return self:_getAttr("CanFish") end
function FA:_setAttr(key, value)
    Player.Character:SetAttribute(key, value)
end
function FA:SetFishingWalkSpeed(bool:boolean)
	if bool then
		Humanoid.WalkSpeed = c.FISHING.WalkSpeed
	else
		Humanoid.WalkSpeed = c.PLAYER.HUMANOID_DEFAULT_ATTRS.WalkSpeed
	end
end

-- FISHING EVENTS
function FA:_OnCatchTweenFinish()
    CAM:CleanAnimations()
    self:SetFishingWalkSpeed(false)
    self:_setAttr("IsFishing", false)
end
function FA:_OnCatchResult(CatchInfo:table)
    CAM:CleanAnimations()
    local CatchAnimTrack = CAM:LoadAnimation(CatchAnimation)
    CatchAnimTrack:Play()
    local connection
    connection = CatchAnimTrack:GetMarkerReachedSignal("CatchPoint"):Connect(function()
        connection:Disconnect()
        GlobalEvent:FireServer("PlayFishingSound", {"Splash", ROD})
        GlobalEvent:FireServer("PlayFishingSound", {"StartCast", ROD})
        if CatchInfo.success then
            GlobalEvent:FireServer("CatchResultSuccess", {CatchInfo, ROD})
            FUI:ShowFishPopup(CatchInfo)
			FUI:ShowPopup({
				Text = {
					Text = "Fish caught: ",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Visible = true,
				},
				Text2 = {
					Text = CatchInfo.fishName .. " ",
					TextColor3 = c:GetRarityColor(CatchInfo.fishData.rarity),
					Visible = true,
				},
				Icon = {
					Image = CatchInfo.fishData.icon,
					Visible = true,
				},
			})
        else
            FUI:ShowPopup({
                Text = {
                    Text = "Fish not caught",
                    TextColor3 = Color3.fromRGB(255, 0, 0),
                    Visible = true,
                },
            })
        end
    end)
end
function FA:_OnBite()
    GlobalEvent:FireServer("ShowFishBiteUI", true)
    GlobalEvent:FireServer("PlayFishingSound", {"Chime", ROD})
    local reelingAnimationTrack = CAM:LoadAnimation(ReelingAnimation)
    reelingAnimationTrack:Play()
    reelingAnimationTrack:AdjustSpeed(1)
    GlobalEvent:FireServer("PlayFishingSound", {"Reel", ROD})
    task.wait(0.8)
    GlobalEvent:FireServer("ShowFishBiteUI", false)
    ReelComplete:FireServer(true)
end
function FA:_OnCastApproved(success:boolean, result)
    if success then
        self:_setAttr("IsFishing", true)
        GlobalEvent:FireServer("PlayFishingSound", {"Splash", ROD})
    else
        FUI:ShowPopup({
            Text = {
				Text = result,
				TextColor3 = Color3.fromRGB(255, 0, 0),
				Visible = true,
			},
        })
        GlobalEvent:FireServer("CleanFishingSounds")
        GlobalEvent:FireServer("PlayFishingSound", {"Error", ROD})
        GlobalEvent:FireServer("CleanBobber")
        CAM:CleanAnimations()
        self:SetFishingWalkSpeed(false)
        self:_setAttr("IsFishing", false)
    end
end

-- TOOLS EVENTS STATIC METHODS
function FA:Fishing(target)
    if self:IsFishing() or not self:CanFish() then return end
	self:_setAttr("IsFishing", true)
	GlobalEvent:FireServer("CleanBobber")
    local sanitizePower = math.clamp(tonumber(power) or 0, 0, 1)
	local minRangePercent = 0.45
	local minRange = c.FISHING.BASE_RANGE * minRangePercent
	local powerRange = c.FISHING.BASE_RANGE * (0.5 + sanitizePower)
	local allowedRange = math.max(minRange, powerRange)

	local rootPos = Player.Character.HumanoidRootPart.Position
	local dir = (target - rootPos)
	local distance = dir.Magnitude
	local finalPos
	if distance < minRange then
		finalPos = rootPos + (dir.Unit * minRange)
	else
		finalPos = distance > allowedRange
			and rootPos + (dir.Unit * allowedRange)
			or target
	end
	local origin = finalPos + Vector3.new(0, 20, 0)
	local direction = Vector3.new(0, -60, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {}
	local r = workspace:Raycast(origin, direction, params)
	local rInstance = r.Instance
	local function isWater()
		return r.Material == Enum.Material.Water or CollectionService:HasTag(rInstance, "Water")
	end
	finalPos = r.Position
    GlobalEvent:FireServer("CreateBobber", {finalPos, ROD})
    ROD:WaitForChild("Handle"):WaitForChild("Beam")
    local idleFishingAnimation = CAM:LoadAnimation(IdleFishingAnimation)
	idleFishingAnimation:Play()
	idleFishingAnimation:AdjustSpeed(1)
	StartCast:FireServer(isWater(), power)
end
function FA:ReleaseCast()
    if self:IsFishing() or not self:CanFish() then return end
	if not self:IsCasting() then return end
	self:_setAttr("IsCasting", false)
	GlobalEvent:FireServer("ShowPowerCategoryUI", power)
	local releaseCastTrack = CAM:LoadAnimation(ReleaseCastAnimation)
	releaseCastTrack:Play()
	local connection
	connection = releaseCastTrack:GetMarkerReachedSignal("ReleasePoint"):Connect(function(keyframe)
		connection:Disconnect()
		GlobalEvent:FireServer("PlayFishingSound", {"ReleaseCast", ROD})
		local rootPart = Player.Character.HumanoidRootPart
		local charCFrame = rootPart.CFrame
		local forwardDirection = charCFrame.LookVector
		local target = rootPart.Position + (forwardDirection * (power * c.FISHING.BASE_RANGE))
		self:Fishing(target)
	end)
end
function FA:StartCast(AFKPOWER)
    if self:IsFishing() or self:IsCasting() or not self:CanFish() then return end
	self:_setAttr("IsCasting", true)
	self:SetFishingWalkSpeed(true)
	power = AFKPOWER or 0
	local direction = 1
	local startCastTrack = CAM:LoadAnimation(StartCastAnimation)
	startCastTrack:Play()
	startCastTrack:AdjustSpeed(0) -- Stop automatic progression
	local animationProgress = 0
	while self:IsCasting() do
		local dt = task.wait(0.03)
		local step = (dt / c.FISHING.CHARGE_TIME)
		power = math.clamp(power + (step * direction), 0, 1)
		if power >= 1 then
			direction = -1
		elseif power <= 0 then
			direction = 1
		end
		animationProgress = math.clamp(animationProgress + step, 0, 1)
		local percentage = math.clamp(animationProgress * 100, 0, 99)
		local targetTime = (percentage / 100) * startCastTrack.Length
		startCastTrack.TimePosition = targetTime
		FUI.PowerBar.Visible = true
		FUI.PowerBar.Fill.Size = UDim2.new(1, 0, power, 0)
		FUI.PowerBar.Label.Text = string.format("%d%%", math.floor(power * 100))
		if self.IsAFK and not self:IsFishing() then
			self:ReleaseCast()
			self:_setAttr("IsCasting", false)
		end
	end
	startCastTrack:AdjustSpeed(1)
	FUI.PowerBar.Visible = false
end
function FA:StopAfk()
    self.IsAFK = false
    if self.AfkConnection then
		task.cancel(self.AfkConnection)
		self.AfkConnection = nil
	end
	FUI.AutoFishButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
end
function FA:StartAfk()
    if self.IsAFK or self:IsFishing() or not self:CanFish() then return end
	self.IsAFK = true
	local afkLoop = function()
		while self.IsAFK and self:CanFish() do
			local afkpower = 0.5 + (math.random() * 0.5)
			self:StartCast(afkpower)
			while self:IsFishing() and self.IsAFK do
				task.wait(0.1)
			end
			if self.IsAFK then
				task.wait(1.0 + (math.random() * 1.0))
			end
		end
	end
	FUI.AutoFishButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	FUI:ShowPopup({
		Text = {
			Text = "Auto fishing enabled",
			TextColor3 = Color3.fromRGB(50, 150, 50),
			Visible = true,
		},
	})
	self.AfkConnection = task.spawn(afkLoop)
end
-- === MOST Interaction Entry Points
function FA:ToggleAfk()
    if self.IsAFK then
		self:StopAfk()
		FUI:ShowPopup({
			Text = {
				Text = "Auto fishing disabled",
				TextColor3 = Color3.fromRGB(150, 50, 50),
				Visible = true,
			},
		})
	else
		self:StartAfk()
	end
end
function FA:OnUnequipped()
    self:CleanConnections()
    self:CleanUp()
    self:_setAttr("CanFish", false)
    FUI.AutoFishButton.Visible = false
	ToolEvent:FireServer("UnEquippedReady", true)
end
function FA:OnEquipped()
    self:CleanConnections()
    self:CleanUp()
    self:_setAttr("CanFish", true)
    FUI.AutoFishButton.Visible = true
    self.AFBConnection = FUI.AutoFishButton.MouseButton1Click:Connect(function()
        self:ToggleAfk()
    end)
	self.FishingIBConnection = UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then self:StartCast() end
	end)
	self.FishingIEConnection = UIS.InputEnded:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then self:ReleaseCast() end
	end)
	self:SetupEventListener()
end


-- CLEANUP
function FA:CleanUp()
    self:_setAttr("IsCasting", false)
	self:_setAttr("IsFishing", false)
	self:StopAfk()
	power = 0
	GlobalEvent:FireServer("CleanBobber")
	CAM:CleanAnimations()
	self:SetFishingWalkSpeed(false)
	GlobalEvent:FireServer("ShowFishBiteUI", false)
end
function FA:CleanConnections()
    -- === uis ===
    if self.FishingIBConnection then
        self.FishingIBConnection:Disconnect()
        self.FishingIBConnection = nil
    end
    if self.FishingIEConnection then
        self.FishingIEConnection:Disconnect()
        self.FishingIEConnection = nil
    end
    if self.AFBConnection then
        self.AFBConnection:Disconnect()
        self.AFBConnection = nil
    end
    -- === remote ===
    if self.CAConnection then
        self.CAConnection:Disconnect()
        self.CAConnection = nil
    end
    if self.BEConnection then
        self.BEConnection:Disconnect()
        self.BEConnection = nil
    end
    if self.CRConnection then
        self.CRConnection:Disconnect()
        self.CRConnection = nil
    end
    if self.CTFConnection then
        self.CTFConnection:Disconnect()
        self.CTFConnection = nil
    end
    if self.TEConnection then
        self.TEConnection:Disconnect()
        self.TEConnection = nil
    end
	FUI:CleanUp()
end

-- ENTRY POINTS
function FA:SetupEventListener()
    -- === fishing events ===
    local CastApproved = FishingRemotes:WaitForChild("CastApproved")
    local BiteEvent = FishingRemotes:WaitForChild("Bite")
    local CatchResult = FishingRemotes:WaitForChild("CatchResult")
    local CatchTweenFinish = FishingRemotes:WaitForChild("CatchTweenFinish")
    self.CAConnection = CastApproved.OnClientEvent:Connect(function(success: boolean, result)
        self:_OnCastApproved(success, result)
    end)
    self.BEConnection = BiteEvent.OnClientEvent:Connect(function()
        self:_OnBite()
    end)
    self.CRConnection = CatchResult.OnClientEvent:Connect(function(fishInfo:table)
        self:_OnCatchResult(fishInfo)
    end)
    self.CTFConnection = CatchTweenFinish.OnClientEvent:Connect(function()
        self:_OnCatchTweenFinish()
    end)
    -- === tools events ===
    self.TEConnection = ToolEvent.OnClientEvent:Connect(function(method, params)
        self[method](self, params)
    end)
end

return FA