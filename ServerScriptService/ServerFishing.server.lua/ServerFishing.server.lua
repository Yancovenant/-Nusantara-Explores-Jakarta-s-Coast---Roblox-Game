-- ServerFishing.lua

local SF = {}
local GM = require(script.GlobalManager)
local GAM = require(script.GlobalActionManager)

local RunService = game:GetService("RunService")
local TS, RS = game:GetService("TweenService"), game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting: Lighting = game:GetService("Lighting")


local Remotes = RS:WaitForChild("Remotes")
local TimeEvent: RemoteEvent = Remotes:WaitForChild("GlobalEvents"):WaitForChild("TimeEvent")

local ZONE_LISTS = {
	"Coast"
}

-- SETUP SERVER
function SF:SetZonesListener()
	for _,v in pairs(ZONE_LISTS) do
		local zone = workspace:WaitForChild("Zones"):WaitForChild(v)
		if not zone then return end
		zone.Touched:Connect(function(hit)
			if hit.Name == "HumanoidRootPart" then
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then return end
				GM:playerEnteredZone(player, zone)
			end
		end)
		zone.TouchEnded:Connect(function(hit)
			if hit.Name == "HumanoidRootPart" then
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then return end
				GM:playerExitedZone(player, zone)
			end
		end)
	end
end
function SF:SetServerTime()
	local function applyLightningTween(preset)
		TS:Create(Lighting, TweenInfo.new(2), preset):Play()
	end
	local function applyLightningByTime(t)
		if t.hour >= 5 and t.hour < 7 then
			applyLightningTween({Brightness=2,ClockTime=t.hour + (t.min / 60),Ambient=Color3.fromRGB(200, 150, 100)})
		elseif t.hour >= 7 and t.hour < 17 then
			applyLightningTween({Brightness=3,ClockTime=t.hour + (t.min / 60),Ambient=Color3.fromRGB(255,255,255)})
		elseif t.hour >= 17 and t.hour < 19 then
			applyLightningTween({Brightness = 1.5,ClockTime = t.hour + (t.min / 60),Ambient=Color3.fromRGB(255,120,80)})
		else
			applyLightningTween({Brightness=0.5,ClockTime=t.hour + (t.min / 60),Ambient=Color3.fromRGB(100,100,200)})
		end
	end
	local SECONDS_PER_INGAME_MIN = 0.7
	local function GetTimeFromMinutes(MinutesInDay)
		local hour = math.floor(MinutesInDay / 60)
		local min = MinutesInDay % 60
		return { hour = hour, min = min}
	end
	local function getJakartaTime()
		local utc = os.time(os.date("!*t"))
		local jakartaSeconds = utc + (7 * 3600) -- in seconds
		-- Stardew Valley Scaled: 0.7s real = 1 in-game minute
		local timeElapsed = math.floor(jakartaSeconds/ SECONDS_PER_INGAME_MIN)
		return timeElapsed % 1440
	end
	self._InGameMinutes = getJakartaTime()
	task.spawn(function()
		local acc = 0
		local connection
		connection = RunService.Heartbeat:Connect(function(dt)
			if self.IsShutDown then connection:Disconnect() end
			acc += dt
			while acc >= SECONDS_PER_INGAME_MIN do
				acc -= SECONDS_PER_INGAME_MIN
				self._InGameMinutes = (self._InGameMinutes + 1) % 1440
				local t = GetTimeFromMinutes(self._InGameMinutes)
				applyLightningByTime(t)
				Lighting:SetAttribute("Hour", t.hour)
				Lighting:SetAttribute("Minute", t.min)
				TimeEvent:FireAllClients(t)
			end
		end)
	end)
end

-- ENTRY POINTS
function SF:main()
	self.IsShutDown = false
	self:SetServerTime()
	self:SetZonesListener()
	GM:SetupServer()
	GAM:SetupServer()
end
SF:main()


-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:WrapModule(SF, "ServerFishing")


Players.PlayerAdded:Connect(function(player)
	GAM:AwardBadge(player, "WELCOME")
    GM:playerAdded(player)
	player.CharacterAdded:Connect(function(char)
		local manager = GM.PlayerManagers[player]
		if not manager then return end
		local inventory = manager.PINV
		inventory.IsHolsterEquip = false
		inventory:ToggleHolsterRod()
		inventory:_CreateBackpack()
	end)
end)

Players.PlayerRemoving:Connect(function(player)
    GM:playerRemoved(player)
end)
game:BindToClose(function()
	SF.IsShutDown = true
	if RunService:IsStudio() then
		task.wait(5)
	else
		local finished = Instance.new("BindableEvent")
		local allPlayers = Players:GetPlayers()
		local leftPlayers = #allPlayers
		for _, player in ipairs(allPlayers) do
			task.spawn(function()
				print("[SERVER SHUTDOWNING] FOR player", _, player)
				GM:onShutdown(player)
				leftPlayers -= 1
				if leftPlayers == 0 then
					finished:Fire()
				end
			end)
		end
		finished.Event:Wait()
	end
end)
