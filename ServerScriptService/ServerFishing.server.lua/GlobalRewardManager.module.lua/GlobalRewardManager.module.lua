-- Global Reward Manager
-- STATIC module

local RS = game:GetService("ReplicatedStorage")

local c = require(RS:WaitForChild("GlobalConfig"))
local GM = require(script.Parent.GlobalManager)
local GSM = require(script.Parent.GlobalStorage)

local GRM = {}


-- FISHING
function GRM:_GetPlayerMultiplier(player, power)
    local plvl = GSM.Data[player].Level or 1
    local plc = GSM.Data[player].Luck or 1
    local lc = 1 + (math.log(plc) * c.FISHING.MULTI.LUCK)
    local env = 1 -- NOT IMPLEMENTED YET
    local eq = 1 -- NOT IMPLEMENTED YET
    local lv = 1 + (math.log(plvl) * c.FISHING.MULTI.LVL)
    local pw = 1 + (power * c.FISHING.MULTI.POWER)
    return pw * lv * eq * env * lc
end
function GRM:_GetFishTable()
    local ft = {}
    local totalPercentageWeight = 0
    for fn, d in pairs(c.FISHING.FISH_DATA.FISH) do
        ft[fn] = d.baseChance
        totalPercentageWeight = totalPercentageWeight + d.baseChance
    end
    local norm = {}
    for fn, ch in pairs(ft) do
        table.insert(norm, {
            name = fn,
            chance = ch
        })
    end
    table.sort(norm, function(a,b)
        return a.chance < b.chance
    end)
    return norm, totalPercentageWeight
end
function GRM:_FishWeightReward(player, data, roll, cum, chance, multi)
    local minW = data.minWeight
    local maxW = data.maxWeight
    local attr = GM.PlayerManagers[player] and GM.PlayerManagers[player].Data.Attributes
    if attr and attr.maxWeight then
        maxW = math.min(maxW, attr.maxWeight)
    end
    multi = multi or 1
    local scaledStart = (cum - chance) * multi
    local scaledSegment = chance * multi
    local prob = 0
    if scaledSegment > 0 then
        prob = (roll - scaledStart) / scaledSegment
    end
    local w = minW + (prob * (maxW - minW))
    return math.floor(w * 100) / 100
end

-- PUBLIC FUNCTION
function GRM:FishReward(player, power)
    local ft:table, tpw = self:_GetFishTable()
    local multi = self:_GetPlayerMultiplier(player, power)
    local cumulative = 0
    local roll = math.random() * tpw
    for i, d in ipairs(ft) do
        cumulative = cumulative + d.chance
        local cm2 = cumulative * multi
        if roll <= cm2 then
            return d.name, c.FISHING.FISH_DATA.FISH[d.name], self:_FishWeightReward(player, c.FISHING.FISH_DATA.FISH[d.name], roll, cumulative, d.chance, multi)
        end
    end
end
function GRM:FishValue(weight, FishData:table)
    --
    -- we can calculate it by
    -- 1. fishdata.rarity, fishdata.chance multiplier
    -- 2. weight.
    --
    print("[GRM] Received", weight, FishData)
end


-- DEBUG
local LOGGER = require(RS:WaitForChild("GlobalModules"):WaitForChild("Logger"))
LOGGER:WrapModule(GRM, "GlobalRewardManager")


return GRM