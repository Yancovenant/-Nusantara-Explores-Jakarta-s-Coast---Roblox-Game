-- Fishing Action Module

local FA = {}
local FUI = require(script.Parent.FishingUI)
local ROD = script.Parent.Parent


local RS, UIS = game:GetService("ReplicatedStorage"), game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Player:Player = game:GetService("Players").LocalPlayer
local Humanoid:Humanoid = Player.Character.Humanoid

local CAM = require(RS:WaitForChild("ClientModules"):WaitForChild("AnimationManager"))

local ReelingAnimation = ROD:WaitForChild("Animations"):WaitForChild("Reeling")
local CatchAnimation = ROD:WaitForChild("Animations"):WaitForChild("Catch")
local StartCastAnimation = ROD:WaitForChild("Animations"):WaitForChild("StartCast")
local ReleaseCastAnimation = ROD:WaitForChild("Animations"):WaitForChild("ReleaseCast")
local IdleFishingAnimation = ROD:WaitForChild("Animations"):WaitForChild("IdleFishing")

local GlobalRemotes = RS:WaitForChild("Remotes"):WaitForChild("GlobalEvents")
local GlobalEvent = GlobalRemotes:WaitForChild("GlobalEvent")
local ToolEvent = RS:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")

local FishingRemotes = RS:WaitForChild("Remotes"):WaitForChild("FishingEvents")
local ReelComplete = FishingRemotes:WaitForChild("ReelComplete")
local StartCast = FishingRemotes:WaitForChild("StartCast")

local FishBaitSound:Sound = ROD:WaitForChild("Sounds"):WaitForChild("FishBait")

local c = require(RS:WaitForChild("GlobalConfig"))

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
	if bool then Humanoid.WalkSpeed = c.FISHING.WalkSpeed else Humanoid.WalkSpeed = c.PLAYER.HUMANOID_DEFAULT_ATTRS.WalkSpeed end
end


-- MINIGAME
function FA:_RunReelMinigame(str)
	self._inMinigame = true
	local s = 0.3 * math.log(1 + str)
	local config = {
		maxDuration = 5.0,
		fillRate = math.clamp(0.15 * (1 + 0.25 * s), 0.05, 0.60), -- 25% fill boost/ 1s
		decayRate = math.clamp(0.02 * (1 - 0.20 * s), 0.0025, 0.02), -- 20% decay reduction / 1s
		greenZoneWidth = math.clamp(0.2 + (0.10 * s), 0.15, 0.85), -- +10% bar width / 1s
	}
	FUI.ReelZone.Size = UDim2.new(config.greenZoneWidth, 0, 1, 0)
	local progress = 0
	local clickCount = 0
	local startTime = tick()

	-- afk section
	local autoAccumulator = 0
	local autoMultiplier = 0.275
	local autoFill = config.fillRate * autoMultiplier
	local T_target = config.maxDuration * 0.85
	local I = (T_target * autoFill) / (1 + T_target * config.decayRate)
	local I_stall = autoFill / math.max(1e-6, config.decayRate)
	local autoClickInterval = math.min(I, I_stall - 0.05)

	FUI:SetMinigameProgress(progress, config.greenZoneWidth)
	FUI:ToggleMinigameUI(true)
	local resultEvent = Instance.new("BindableEvent")

	local clickConnection
	clickConnection = UIS.InputBegan:Connect(function(input, gp)
		if gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		progress = math.min(1.0, progress + config.fillRate)
		FUI:SetMinigameProgress(progress, config.greenZoneWidth)
		clickCount += 1 -- currently not being used
	end)
	local heartbeatConnection
	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		local elapsed = tick() - startTime
		FUI:UpdateMinigameTimeProgress(elapsed, config.maxDuration)

		if self.IsAFK then
			autoAccumulator += dt
			if autoAccumulator >= autoClickInterval then
				autoAccumulator = 0
				progress = math.min(1.0, progress + autoFill)
				FUI:SetMinigameProgress(progress, config.greenZoneWidth)
			end
		end

		if progress >= 1.0 then
			clickConnection:Disconnect()
			heartbeatConnection:Disconnect()
			FUI:ToggleMinigameUI(false)
			resultEvent:Fire(true)
		elseif elapsed >= config.maxDuration then
			clickConnection:Disconnect()
			heartbeatConnection:Disconnect()
			FUI:ToggleMinigameUI(false)
			resultEvent:Fire(self.IsAFK == true)
		end

		progress = math.max(0, progress - (config.decayRate * dt))
		FUI:SetMinigameProgress(progress, config.greenZoneWidth)
	end)
	task.spawn(function()
		task.wait(config.maxDuration + 1)
		if clickConnection then clickConnection:Disconnect() end
		if heartbeatConnection then heartbeatConnection:Disconnect() end
	end)
	local result = resultEvent.Event:Wait()
	self._inMinigame = false
	return result
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
        GlobalEvent:FireServer("PlayFishingSound", "Splash", ROD)
        GlobalEvent:FireServer("PlayFishingSound", "StartCast", ROD)
        if CatchInfo.success then
            GlobalEvent:FireServer("CatchResultSuccess", true, ROD, CatchInfo)
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
			GlobalEvent:FireServer('CatchResultSuccess', false, ROD)
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
function FA:_OnBite(strengthAttribute:number)
    GlobalEvent:FireServer("ShowFishBiteUI", true)
    GlobalEvent:FireServer("PlayFishingSound", "Chime", ROD)
    local reelingAnimationTrack = CAM:LoadAnimation(ReelingAnimation)
    reelingAnimationTrack:Play()
    reelingAnimationTrack:AdjustSpeed(1)
	FishBaitSound:Play()
	FishBaitSound.Ended:Wait()
    GlobalEvent:FireServer("PlayFishingSound", "Reel", ROD, true, true)

	local success = self:_RunReelMinigame(strengthAttribute)

	GlobalEvent:FireServer("CleanFishingSounds")
    GlobalEvent:FireServer("ShowFishBiteUI", false)
    ReelComplete:FireServer(success)
end
function FA:_OnCastApproved(success:boolean, result)
    if success then
        self:_setAttr("IsFishing", true)
        GlobalEvent:FireServer("PlayFishingSound", "Splash", ROD)
    else
        FUI:ShowPopup({
            Text = {
				Text = result,
				TextColor3 = Color3.fromRGB(255, 0, 0),
				Visible = true,
			},
        })
        GlobalEvent:FireServer("CleanFishingSounds")
        GlobalEvent:FireServer("PlayFishingSound", "Error", ROD)
        GlobalEvent:FireServer("CleanBobber")
        CAM:CleanAnimations()
        self:SetFishingWalkSpeed(false)
        self:_setAttr("IsFishing", false)
    end
end

-- == Fishing Process, Start Release, Fish (Loop) ==
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

	self._ClickReady = true
	self._IsMouseDown = false
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
		GlobalEvent:FireServer("PlayFishingSound", "ReleaseCast", ROD)
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
	GlobalEvent:FireServer("CleanFishingSounds")
	self:SetFishingWalkSpeed(true)
	power = AFKPOWER or 0
	local direction = 1
	local startCastTrack = CAM:LoadAnimation(StartCastAnimation)
	startCastTrack:Play(0)
	startCastTrack:AdjustSpeed(0) -- Stop automatic progression
	startCastTrack.TimePosition = 0
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
-- == AFK Toggle ==
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
-- == Fishing Rod Equip/Unequip ==
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
	self._isMouseDown = false
	self._ClickReady = true
	self.FishingIBConnection = UIS.InputBegan:Connect(function(input, gp)
		if gp or self._inMinigame then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not self._ClickReady then return end
		if self:IsFishing() or self:IsCasting() or not self:CanFish() then return end
		self._ClickReady = false
		if self._IsMouseDown then return end
		self._IsMouseDown = true
		self:StartCast()
	end)
	self.FishingIEConnection = UIS.InputEnded:Connect(function(input, gp)
		if gp or self._inMinigame then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not self._IsMouseDown then return end
		self:ReleaseCast()
	end)
	self:SetupEventListener()
	--- preload animation for first time.
	for _, anim in pairs({
		ReelingAnimation,
		CatchAnimation,
		StartCastAnimation,
		ReleaseCastAnimation,
		IdleFishingAnimation
	}) do
		local preload = CAM:LoadAnimation(anim)
		preload:Play()
		preload:Stop()
		preload:Destroy()
	end
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


-- ENTRY POINTS
function FA:CleanConnections()
	for k,v in pairs(self) do if typeof(v)=="RBXScriptConnection" then v:Disconnect() v=nil end end
	FUI:CleanUp()
end
function FA:SetupEventListener()
    -- === fishing events ===
    local CA = FishingRemotes:WaitForChild("CastApproved")
    local BE = FishingRemotes:WaitForChild("Bite")
    local CR = FishingRemotes:WaitForChild("CatchResult")
    local CTF = FishingRemotes:WaitForChild("CatchTweenFinish")
    self.CAConnection = CA.OnClientEvent:Connect(function(...) self:_OnCastApproved(...) end)
    self.BEConnection = BE.OnClientEvent:Connect(function(...) self:_OnBite(...) end)
    self.CRConnection = CR.OnClientEvent:Connect(function(...) self:_OnCatchResult(...) end)
    self.CTFConnection = CTF.OnClientEvent:Connect(function(...) self:_OnCatchTweenFinish(...) end)
    -- === tools events ===
    self.TEConnection = ToolEvent.OnClientEvent:Connect(function(method, ...) self[method](self, ...) end)
end


-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:WrapModule(FA, "Client_FishingAction")


return FA