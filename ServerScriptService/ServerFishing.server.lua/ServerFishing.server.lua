-- ServerFishing.lua

local SF = {}
local GM = require(script.GlobalManager)
local GAM = require(script.GlobalActionManager)

local TS:TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting: Lighting = game:GetService("Lighting")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
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
	local function getJakartaTime()
		local utc = os.time(os.date("!*t"))
		local jakartaTime = utc + (7 * 3600)
		return os.date("!*t", jakartaTime)
	end
	local function applyLightningTween(preset)
		TS:Create(Lighting, TweenInfo.new(2), preset):Play()
	end
	local function applyLightningByTime(t)
		if t.hour >= 5 and t.hour < 7 then
			applyLightningTween({
				Brightness = 2,
				ClockTime = t.hour + (t.min / 60),
				Ambient = Color3.fromRGB(200, 150, 100)
			})
		elseif t.hour >= 7 and t.hour < 17 then
			applyLightningTween({
				Brightness = 3,
				ClockTime = t.hour + (t.min / 60),
				Ambient = Color3.fromRGB(255,255,255)
			})
		elseif t.hour >= 17 and t.hour < 19 then
			applyLightningTween({
				Brightness = 1.5,
				ClockTime = t.hour + (t.min / 60),
				Ambient = Color3.fromRGB(255,120,80)
			})
		else
			applyLightningTween({
				Brightness = 0.5,
				ClockTime = t.hour + (t.min / 60),
				Ambient = Color3.fromRGB(100,100,200)
			})
		end
	end
	task.spawn(function()
		while not self.IsShutDown do
			local t = getJakartaTime()
			applyLightningByTime(t)
			Lighting:SetAttribute("Hour", t.hour)
			Lighting:SetAttribute("Minute", t.min)
			TimeEvent:FireAllClients(t)
			task.wait(60)
		end
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

Players.PlayerAdded:Connect(function(player)
    GM:playerAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
    GM:playerRemoved(player)
end)
game:BindToClose(function()
	SF.IsShutDown = true
    GM:onShutdown()
end)
