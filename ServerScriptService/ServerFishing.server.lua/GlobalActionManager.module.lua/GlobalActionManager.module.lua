-- Global Action Manager

local GAM = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local c = require(ReplicatedStorage:WaitForChild("GlobalConfig"))
local GRM = require(script.Parent.GlobalRewardManager)
local GM = require(script.Parent.GlobalManager)

-- FISHING LISTENER
local StartCast = Remotes:WaitForChild("FishingEvents"):WaitForChild("StartCast")
local CastApproved = Remotes:WaitForChild("FishingEvents"):WaitForChild("CastApproved")
local BiteEvent = Remotes:WaitForChild("FishingEvents"):WaitForChild("Bite")
local CatchResult = Remotes:WaitForChild("FishingEvents"):WaitForChild("CatchResult")
local ReelComplete = Remotes:WaitForChild("FishingEvents"):WaitForChild("ReelComplete")

function GAM:OnFishingCastEvent()
    StartCast.OnServerEvent:Connect(function(player:Player, isWater:boolean, power)
        local s = self.state[player] or {}
        self.state[player] = s
        local function sendClientEvt(sc:boolean, msg:string)
            CastApproved:FireClient(player, sc, msg)
            s.isFishing = sc
        end
        if s.isFishing then return sendClientEvt(false, "Already Fishing") end
        if not isWater then return sendClientEvt(false, "Aim at Water") end
        s.power = power
        sendClientEvt(true, "CastApproved") --
        local biteDelay = math.random(c.FISHING.BITE_DELAY_MIN, c.FISHING.BITE_DELAY_MAX)
        task.delay(biteDelay, function()
            if not s.isFishing then return end
            BiteEvent:FireClient(player)
        end)
    end)
end
function GAM:OnReelingCompleteEvent()
    ReelComplete.OnServerEvent:Connect(function(player:Player, sc:boolean)
        local s = self.state[player]
        if not s or not s.isFishing then return end
        if sc then
            local fn, fd, w = GRM:fishReward(player, s.power)
            CatchResult:FireClient(player, {
                success = true,
                fishName = fn,
                fishData = fd,
                weight = w
            })
        else
            CatchResult:FireClient(player, {success = false})
        end
        self.state[player] = nil
    end)
end


-- GLOBAL LISTENER
local ToolEvent = Remotes:WaitForChild("Inventory"):WaitForChild("Tool")
local GlobalEvent = Remotes:WaitForChild("GlobalEvents"):WaitForChild("GlobalEvent")

function GAM:OnToolEvent()
    ToolEvent.OnServerEvent:Connect(function(player, method, params)
        if not table.find(GM.ALLOWED_METHOD, method) then
            warn("[ToolEvent] Invalid method: " .. method)
            return
        end
        GM[method](GM, player, params)
    end)
end
function GAM:OnGlobalEvent()
    GlobalEvent.OnServerEvent:Connect(function(player, method, params)
        if not table.find(GM.ALLOWED_METHOD, method) then
            warn("[GlobalEvent] Invalid method: " .. method)
            return
        end
        GM[method](GM, player, params)
    end)
end

-- ENTRY POINT
function GAM:SetupRemoteListener()
    self:OnFishingCastEvent()
    self:OnReelingCompleteEvent()
    self.OnToolEvent()
    self.OnGlobalEvent()
end
function GAM:SetupServer()
    self.state = {}
    self:SetupRemoteListener()
end

return GAM