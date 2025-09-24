-- Global Action Manager

local GAM = {}

local RS:ReplicatedStorage = game:GetService("ReplicatedStorage")
local PSS:ProximityPromptService = game:GetService("ProximityPromptService")

local Remotes = RS:WaitForChild("Remotes")

local c = require(RS:WaitForChild("GlobalConfig"))
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
        local function sendClientEvt(sc:boolean, msg:string)
            CastApproved:FireClient(player, sc, msg)
            player:SetAttribute("IsFishingServer", sc)
        end
        if player:GetAttribute("IsFishingServer") then return sendClientEvt(false, "Already Fishing") end
        if not isWater then return sendClientEvt(false, "Aim at Water") end
        player:SetAttribute("PowerServer", power)
        sendClientEvt(true, "CastApproved") --
        local biteDelay = math.random(c.FISHING.BITE_DELAY_MIN, c.FISHING.BITE_DELAY_MAX)
        task.delay(biteDelay, function()
            if not player:GetAttribute("IsFishingServer") then return end
            -- minigame data.
            local attr = GM.PlayerManagers[player] and GM.PlayerManagers[player].Data.Attributes
            BiteEvent:FireClient(player, attr and attr.strength or 0)
        end)
    end)
end
function GAM:OnReelingCompleteEvent()
    ReelComplete.OnServerEvent:Connect(function(player:Player, sc:boolean)
        if not player:GetAttribute("IsFishingServer") then return end
        if sc then
            local fn, fd, w = GRM:FishReward(player, player:GetAttribute("PowerServer"))
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
        player:SetAttribute("IsFishingServer", false)
        player:SetAttribute("PowerServer", 0)
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
    GlobalEvent.OnServerEvent:Connect(function(player, method, ...)
        if not table.find(GM.ALLOWED_METHOD, method) then
            warn("[GlobalEvent] Invalid method: " .. method)
            return
        end
        GM[method](GM, player, ...)
    end)
end

-- PROXIMITY EVENT
function GAM:OnFishShop(player:Player, ...)
    GM:ToggleFishShopUI(player, GRM, ...)
end

-- ENTRY POINT
function GAM:SetupProximityListener()
    PSS.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
        local method = "On" .. prompt.Name
        if not GAM[method] then
            warn("[GlobalActionManager] Invalid method: " .. method)
            return
        end
        GAM[method](GAM, playerWhoTriggered, prompt.Parent)
    end)
end
function GAM:SetupRemoteListener()
    self:OnFishingCastEvent()
    self:OnReelingCompleteEvent()
    self.OnToolEvent()
    self.OnGlobalEvent()
end
function GAM:SetupServer()
    self.state = {}
    self:SetupRemoteListener()
    self:SetupProximityListener()
end


-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:WrapModule(GAM, "GlobalActionManager")


return GAM