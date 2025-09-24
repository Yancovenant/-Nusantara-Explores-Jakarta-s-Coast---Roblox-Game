-- Main.lua
game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
local CPM = {}

local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid: Humanoid = Character:WaitForChild("Humanoid")

local RS:ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolEvent: RemoteEvent = RS:WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("Tool")
local TimeEvent: RemoteEvent = RS:WaitForChild("Remotes"):WaitForChild("GlobalEvents"):WaitForChild("TimeEvent")
local AnimationEvent: RemoteEvent = RS:WaitForChild("Remotes"):WaitForChild("ClientAnimation")
local UIEvent: RemoteEvent = RS:WaitForChild("Remotes"):WaitForChild("ClientEvents"):WaitForChild("UIEvent")

local holdingFishAnimation: Animation = RS:WaitForChild("Animations"):WaitForChild("HoldingFish")

local CAM = require(RS:WaitForChild("ClientModules"):WaitForChild("AnimationManager"))
local CUI = require(RS:WaitForChild("ClientModules"):WaitForChild("UIManager"))
local c = require(RS:WaitForChild("GlobalConfig"))

local camera: Camera = workspace.CurrentCamera
local DEFAULT_CAMFOV = camera.FieldOfView

-- KeyCode
local runKey: Enum.KeyCode = Enum.KeyCode.LeftShift
local invKey: Enum.KeyCode = Enum.KeyCode.E
local rodKey: Enum.KeyCode = Enum.KeyCode.One


-- ENTRY POINTS
function CPM:_SetUIS()
	if UIS.TouchEnabled and not UIS.GyroscopeEnabled then
		-- mobile
	else
		UIS.InputBegan:Connect(function(input: InputObject, gp: boolean)
			local cantRun = Character:GetAttribute("IsFishing") or Character:GetAttribute("IsCasting")
			if gp then return end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == runKey then
					if cantRun then return end
					self.isRunning = true
					Humanoid.WalkSpeed = c.PLAYER.RUN_SPEED
					self.sprintingTween:Play()
				elseif input.KeyCode == invKey then
					ToolEvent:FireServer("ToggleInventory")
				elseif input.KeyCode == rodKey then
					ToolEvent:FireServer("ToggleRod")
				end
			end
		end)
		UIS.InputEnded:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local cantRun = Character:GetAttribute("IsFishing") or Character:GetAttribute("IsCasting")
				if input.KeyCode == runKey then
					if not self.isRunning then return end
					if cantRun then return end
					self.isRunning = false
					Humanoid.WalkSpeed = c.PLAYER.HUMANOID_DEFAULT_ATTRS.WalkSpeed
					self.walkingTween:Play()
				end
			end
		end)
	end
end
function CPM:_SetRemoteEventListener()
	AnimationEvent.OnClientEvent:Connect(function(animName:string)
		local animation: Animation
		if animName =="HoldFishAboveHead" then
			animation = holdingFishAnimation
		else
			return CAM:CleanAnimations()
		end
		local animationTrack:AnimationTrack = CAM:LoadAnimation(animation)
		animationTrack:Play()
	end)
	TimeEvent.OnClientEvent:Connect(function(timeInfo)
		CUI:UpdateTime(timeInfo)
	end)
	UIEvent.OnClientEvent:Connect(function(method, ...)
		CUI[method](CUI, ...)
	end)
end
function CPM:_SetEventListener()
	self:_SetUIS()
	self:_SetRemoteEventListener()
end
function CPM:_SetPlayerConfig()
	for k, v in pairs(c.PLAYER.DEFAULT_ATTRS) do
		Player[k] = v
	end
	for k, v in pairs(c.PLAYER.HUMANOID_DEFAULT_ATTRS) do
		Humanoid[k] = v
	end
end
function CPM:main()
	CUI:main()
	self.sprintingTween = TS:Create(camera,TweenInfo.new(0.3),{FieldOfView = DEFAULT_CAMFOV + ( c.PLAYER.RUN_SPEED / 5 )})
	self.walkingTween = TS:Create(camera,TweenInfo.new(0.3),{FieldOfView = DEFAULT_CAMFOV})
	self:_SetPlayerConfig()
	self:_SetEventListener()
end


-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:WrapModule(CPM, "Client_Main")


CPM:main()