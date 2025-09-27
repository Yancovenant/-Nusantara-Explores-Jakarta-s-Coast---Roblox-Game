-- test only

--

-- local seat = script.Parent
-- local hull = seat.Parent.Hull
-- print(hull.Body:GetMass(), "from test")
-- local force = hull.Force
-- local tilt = hull.Tilt

-- local config = {
-- 	spd = 6,
-- 	turnspd = 0.9,
-- 	tiltpower = 4.5*(10^6)
-- }

-- local function exam(n)
-- 	if n ~= 1 or n ~= -1 then
-- 		return n
-- 	else
-- 		return 1
-- 	end
-- end

-- while task.wait() do
-- 	local x,y,z,xx,xy,xz,yx,yy,yz,zx,zy,zz = hull.CFrame:GetComponents()
-- 	local forward = hull.CFrame.LookVector
-- 	local Rotation_Tilt_Linear_Velocity = Vector3.new(xy,yy,zy)
-- 	force.Force = seat.Throttle * (forward * hull.Body:GetMass() * config.spd) --

-- 	local tiltpower = (config.tiltpower * math.rad(seat.AssemblyLinearVelocity.magnitude)) * exam(seat.Steer)
-- 	tilt.MaxTorque = Vector3.new(tiltpower, tiltpower, tiltpower)
-- 	hull.AssemblyAngularVelocity = seat.Steer * (Vector3.new(0, -1*config.turnspd/6, 0))
-- 	tilt.AngularVelocity = seat.Steer * Rotation_Tilt_Linear_Velocity
-- end


-- ref
-- Object variables
-- local Seat = script.Parent
-- local Thrust = Seat.Parent:WaitForChild("Thrust")
-- local MainPart = Seat.Parent:WaitForChild("Main")
-- local Force = Thrust:WaitForChild("Force")
-- local Tilt = Thrust:WaitForChild("Tilt")

-- -- Boat settings
-- local BoatSpeed = 6
-- local TurnSpeed = 0.9
-- local TiltPower = 4.5*(10^6)

-- function Examine(Number)
-- 	if Number == 1 then
-- 		return 1
-- 	elseif Number == -1 then
-- 		return 1
-- 	else return Number end
-- end

-- while wait() do
-- -- Boat lookvector

--      x,y,z
--      R00-R22
-- local p1,p2,p3,xx,xy,xz,yx,yy,yz,zx,zy,zz = Thrust.CFrame:components()
-- local FTLV = Thrust.CFrame.lookVector
-- local DNLV = -Vector3.new(xy,yy,zy)
-- local RTLV = Vector3.new(xz,yz,zz)
-- local SeatMagnitude = Seat.Velocity.magnitude
-- local FinalTiltPower = (TiltPower*math.rad(SeatMagnitude))*Examine(Seat.Steer)

-- 	-- ACCELERATING
-- 	Force.Force = Seat.Throttle * (FTLV*MainPart:GetMass()*BoatSpeed)
	
-- 	-- STEERING
-- 	Tilt.MaxTorque = Vector3.new(FinalTiltPower,FinalTiltPower,FinalTiltPower)
-- 	MainPart.RotVelocity = Seat.Steer * (Vector3.new(0,-1*TurnSpeed/6,0))
-- 	Tilt.AngularVelocity = Seat.Steer*(RTLV)
	
-- end



---- FINAL SCRIPT FOR BOAT DRIVING.

local Seat = script.Parent
local Hull = Seat.Parent.Hull
local MaxSpeed = 110
local RevMaxSpeed = 18
local BrakeDecel = 48
local Accel = 42
local curSpeed = 0
local turnRate = math.rad(55)
local turnAccel = math.rad(220)

local curYawRate = 0
local Torque = Hull.Torque
local Thrust = Hull.VectorForce

while task.wait() do
    local targetSpeed
    if Seat.Throttle > 0 then
        targetSpeed = MaxSpeed
    elseif Seat.Throttle < 0 then
        targetSpeed = -RevMaxSpeed
    else
        targetSpeed = 0
    end
    if targetSpeed == 0 then
        -- no input
        local s = math.abs(curSpeed)
        s = math.max(0, s - BrakeDecel)
        curSpeed = (curSpeed >= 0) and s or -s
    else
        -- is moving
        local toward = (targetSpeed > curSpeed) and Accel or BrakeDecel
        curSpeed = math.lerp(curSpeed, targetSpeed, math.clamp(toward / math.max(1, math.abs(targetSpeed - curSpeed)), 0, 1))
    end

    local forward = Hull.CFrame.LookVector
    -- lv.VectorVelocity = forward * curSpeed
    Thrust.Force = forward * curSpeed * Hull:GetMass()

    local targetYaw = -Seat.Steer * turnRate
    local dyaw = math.clamp(targetYaw - curYawRate, -turnAccel, turnAccel)
    curYawRate = curYawRate + dyaw
    Torque.Torque = Vector3.new(curYawRate * Hull:GetMass(), 0, 0)

    Hull.AssemblyAngularVelocity *= 1 - 0.9
end
