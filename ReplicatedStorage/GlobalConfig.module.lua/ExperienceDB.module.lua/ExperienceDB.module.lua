-- Experience DB module
-- {Badges, Gamepasses, DevProducts}
local EDB = {}

EDB.Badges = {
    ["WELCOME"] = {
        id = 3961917810125745,
        reward = {},
        callback = "FirstJoin",
        params = {},
    },
    ["CATCH_10"] = {
        id = 4184774550951782,
        reward = {money=250},
        callback = "TotalCaught",
        params = {10},
    },
    ["CATCH_RARE"] = {
        id = 262785031407481,
        reward = {money=1000},
        callback = "TotalCaught",
        params = {1, "Rare"},
    },
    ["PLAY_30"] = {
        id = 2700461336030932,
        reward = {money=250},
        callback = "PlayMinutes",
        params = {30},
    },
    ["PLAY_120"] = {
        id = 1681055262700628,
        reward = {money=500},
        callback = "PlayMinutes",
        params = {120},
    },
}

return EDB