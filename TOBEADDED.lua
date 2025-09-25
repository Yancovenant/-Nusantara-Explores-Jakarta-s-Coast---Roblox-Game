-- ServerScriptService/BoatManager.server.lua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GC = require(RS:WaitForChild("GlobalConfig"))
local GBD = GC.BOATS -- your GlobalBoatDB
local BoatTemplates = RS:WaitForChild("Boats") -- folder with boat models

-- Remotes
local Remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder", RS)
Remotes.Name = "Remotes"
local BoatFolder = Remotes:FindFirstChild("Boat") or Instance.new("Folder", Remotes)
BoatFolder.Name = "Boat"
local RE_Spawn = BoatFolder:FindFirstChild("Spawn") or Instance.new("RemoteEvent", BoatFolder)
RE_Spawn.Name = "Spawn"
local RE_Despawn = BoatFolder:FindFirstChild("Despawn") or Instance.new("RemoteEvent", BoatFolder)
RE_Despawn.Name = "Despawn"

-- Active boats by player
local playerBoat = {}

local function getSpawnCF(player: Player): CFrame
	-- TODO: change to your path
	local spawnsFolder = workspace:FindFirstChild("BoatSpawns")
	if spawnsFolder and #spawnsFolder:GetChildren() > 0 then
		local pSpawn = spawnsFolder:FindFirstChild(player.Name)
		local anySpawn = pSpawn or spawnsFolder:GetChildren()[1]
		if anySpawn:IsA("BasePart") then
			return anySpawn.CFrame
		elseif anySpawn:IsA("Model") and anySpawn.PrimaryPart then
			return anySpawn.PrimaryPart.CFrame
		end
	end
	-- fallback to player root
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		return char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -12)
	end
	return CFrame.new(0, 5, 0)
end

local function setBuoyancy(hull: BasePart, rootAtt: Attachment, buoyancyScalar: number)
	local mass = hull:GetMass()
	local g = 196.2
	local vf = hull:FindFirstChild("BuoyancyForce")
	if not vf or not vf:IsA("VectorForce") then return end
	vf.Attachment0 = rootAtt
	vf.RelativeTo = Enum.ActuatorRelativeTo.World
	vf.Force = Vector3.new(0, mass * g * (buoyancyScalar or 1.0), 0)
end

local function configureHullDamping(hull: BasePart, linearDamping: number, angularDamping: number)
	-- Damping on BasePart is linear/angular damping properties
	hull.CustomPhysicalProperties = hull.CustomPhysicalProperties -- ensure not nil
	hull.LinearDamping = linearDamping or 0.5
	hull.AngularDamping = angularDamping or 1.0
end

local function lerp(a, b, t) return a + (b - a) * t end
local function clamp(x, a, b) return math.max(a, math.min(b, x)) end

local function driveLoop(boatModel: Model, owner: Player, boatCfg: table)
	local hull = boatModel:WaitForChild("Hull") :: BasePart
	local driverSeat = boatModel:WaitForChild("DriverSeat")
	local rootAtt = hull:WaitForChild("RootAttachment") :: Attachment
	local thrustAtt = hull:WaitForChild("ThrustAttachment") :: Attachment
	local turnAtt = hull:WaitForChild("TurnAttachment") :: Attachment
	local lv = hull:WaitForChild("LinearVelocity")
	local av = hull:WaitForChild("AngularVelocity")

	-- Constraints setup
	if lv:IsA("LinearVelocity") then
		lv.Attachment0 = thrustAtt
		lv.VectorVelocity = Vector3.zero
		lv.MaxForce = math.huge
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	end
	if av:IsA("AngularVelocity") then
		av.Attachment0 = turnAtt
		av.AngularVelocity = Vector3.zero
		av.MaxTorque = math.huge
		av.RelativeTo = Enum.ActuatorRelativeTo.World
	end

	local phys = boatCfg.physics or {}
	configureHullDamping(hull, phys.linearDamping, phys.angularDamping)
	setBuoyancy(hull, rootAtt, phys.buoyancyScaler or phys.buoyancyScalar or 1.0)

	local maxSpeed = phys.maxSpeed or 60
	local revMaxSpeed = phys.reverseMaxSpeed or 12
	local accel = phys.acceleration or 30
	local brake = phys.brakeDecel or 40
	local turnRate = math.rad(phys.turnRate or 60) -- to rad/s
	local turnAccel = math.rad(phys.turnAccel or 180)
	local inputDeadzone = (boatCfg.control and boatCfg.control.inputDeadzone) or 0.08

	local currentSpeed = 0.0 -- signed (forward +, reverse -)
	local currentYawRate = 0.0 -- rad/s

	local heartbeatConn
	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		if not boatModel.Parent then heartbeatConn:Disconnect() return end

		-- Validate driver ownership
		local occupantHum = driverSeat.Occupant
		if not occupantHum or not occupantHum.Parent or Players:GetPlayerFromCharacter(occupantHum.Parent) ~= owner then
			-- no valid driver: naturally slow down
			local s = math.abs(currentSpeed)
			local dec = brake * dt
			s = math.max(0, s - dec)
			currentSpeed = (currentSpeed >= 0) and s or -s
			currentYawRate = lerp(currentYawRate, 0, clamp(dt * 4, 0, 1))
		else
			-- Read seat inputs (server-replicated)
			-- Throttle: -1, 0, 1 ; Steer: -1..1
			local throttle = driverSeat.Throttle
			local steer = driverSeat.Steer

			if math.abs(throttle) < inputDeadzone then throttle = 0 end
			if math.abs(steer) < inputDeadzone then steer = 0 end

			-- Target speed
			local targetSpeed
			if throttle > 0 then
				targetSpeed = maxSpeed
			elseif throttle < 0 then
				targetSpeed = -revMaxSpeed
			else
				targetSpeed = 0
			end

			-- Approach target speed with accel/brake
			if targetSpeed == 0 then
				local s = math.abs(currentSpeed)
				local dec = brake * dt
				s = math.max(0, s - dec)
				currentSpeed = (currentSpeed >= 0) and s or -s
			else
				local towards = (targetSpeed > currentSpeed) and accel or brake
				currentSpeed = lerp(currentSpeed, targetSpeed, clamp((towards * dt) / math.max(1, math.abs(targetSpeed - currentSpeed)), 0, 1))
			end

			-- Yaw control
			local targetYaw = steer * turnRate
			-- accelerate yaw
			local dyaw = clamp(targetYaw - currentYawRate, -turnAccel * dt, turnAccel * dt)
			currentYawRate = currentYawRate + dyaw
		end

		-- Apply constraints
		if lv:IsA("LinearVelocity") then
			local forward = hull.CFrame.LookVector
			lv.VectorVelocity = forward * currentSpeed
		end
		if av:IsA("AngularVelocity") then
			av.AngularVelocity = Vector3.new(0, currentYawRate, 0)
		end
	end)

	-- Tie loop lifecycle to model
	boatModel.AncestryChanged:Connect(function(_, parent)
		if not parent and heartbeatConn then
			heartbeatConn:Disconnect()
		end
	end)
end

local function spawnBoat(player: Player, boatName: string)
	-- despawn existing
	if playerBoat[player] and playerBoat[player].Model and playerBoat[player].Model.Parent then
		playerBoat[player].Model:Destroy()
	end

	local cfg = GBD.BOAT_LIST[boatName]
	if not cfg then return end
	local template = BoatTemplates:FindFirstChild(boatName)
	if not template then warn("Boat template missing: "..boatName) return end

	local clone = template:Clone()
	clone.Name = boatName
	clone:SetAttribute("OwnerUserId", player.UserId)
	if not clone.PrimaryPart and clone:FindFirstChild("Hull") then
		clone.PrimaryPart = clone.Hull
	end
	clone:PivotTo(getSpawnCF(player))
	clone.Parent = workspace

	playerBoat[player] = { Model = clone, Name = boatName }

	-- Ownership guard: non-owners can’t drive
	local seat = clone:WaitForChild("DriverSeat")
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local hum = seat.Occupant
		if hum then
			local p = Players:GetPlayerFromCharacter(hum.Parent)
			if not p or p.UserId ~= player.UserId then
				seat.Occupant = nil
			end
		end
	end)

	driveLoop(clone, player, cfg)
end

local function despawnBoat(player: Player)
	if playerBoat[player] and playerBoat[player].Model then
		playerBoat[player].Model:Destroy()
	end
	playerBoat[player] = nil
end

-- Remotes
RE_Spawn.OnServerEvent:Connect(function(player, boatName)
	-- owner must have this boat owned
	local data = require(script.Parent.ServerFishing.server.GlobalManager.GlobalStorage) -- not used; you already load data elsewhere
	-- TODO: enforce ownership when you wire to your PlayerManager data
	spawnBoat(player, boatName or "Coastal Skiff")
end)

RE_Despawn.OnServerEvent:Connect(function(player)
	despawnBoat(player)
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	despawnBoat(player)
end)