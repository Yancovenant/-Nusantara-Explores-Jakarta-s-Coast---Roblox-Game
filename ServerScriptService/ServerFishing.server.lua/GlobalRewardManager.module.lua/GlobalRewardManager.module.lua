-- Global Reward Manager
-- STATIC module

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local c = require(ReplicatedStorage:WaitForChild("GlobalConfig"))
local fd = c.FISHING.FISH_DATA
local pdb = require(script.Parent.GlobalStorage)

local GRM = {}


-- FISHING
function GRM:_getPlayerMultiplier(player, power)
    local plvl = pdb.PlayerDatas[player].Level or 1
    local plc = pdb.PlayerDatas[player].Luck or 1
    local lc = 1 + (math.log(plc) * c.MULTI.LUCK)
    local env = 1 -- NOT IMPLEMENTED YET
    local eq = 1 -- NOT IMPLEMENTED YET
    local lv = 1 + (math.log(plvl) * c.MULTI.LVL)
    local pw = 1 + (power * c.MULTI.POWER)
    return pw * lv * eq * env * lc
end
function GRM:_getFishTable()
    local ft = {}
    local totalPercentageWeight = 0
    for fn, d in pairs(fd.FISH) do
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
function GRM:fishWeightReward(player, data, r, cm, ch)
    local minW = data.minW
    local maxW = data.maxW
    if maxW >= pdb.PlayerDatas[player].maxW then
        maxW = pdb.PlayerDatas[player].maxW
    end
    local rp = r - (cm - ch)
    local p = rp / (cm - (cm - ch))
    local w = minW + (p * (maxW - minW))
    return math.floor(w * 100) / 100
end
-- PUBLIC FUNCTION
function GRM:fishReward(player, power)
    local ft:table, tpw = self:_getFishTable()
    local multi = self:_getPlayerMultiplier(player, power)
    local cm = 0
    local r = math.random() * tpw
    for i, d in ipairs(ft) do
        cm = cm + d.chance
        local cm2 = cm * multi
        if r <= cm2 then
            return d.Name, fd[d.Name], self:fishWeightReward(player, fd[d.Name], r, cm, d.chance)
        end
    end
end


return GRM