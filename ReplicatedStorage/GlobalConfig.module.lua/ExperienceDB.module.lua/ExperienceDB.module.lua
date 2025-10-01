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
    ["CATCH_100"] = {
        id = 2902369658954160,
        reward = {money=500},
        callback = "TotalCaught",
        params = {100},
    },
    ["CATCH_1000"] = {
        id = 2645160485301245,
        reward = {money=750},
        callback = "TotalCaught",
        params = {1000},
    },
    ["CATCH_RARE"] = {
        id = 262785031407481,
        reward = {money=1000},
        callback = "TotalCaught",
        params = {1, "Rare"},
    },
    ["CATCH_10_RARE"] = {
        id = 2191191598172237,
        reward = {money=1500},
        callback = "TotalCaught",
        params = {10, "Rare"},
    },
    ["OWN_BOAT"] = {
        id = 773338605722544,
        reward = {money=750},
        callback = "TotalBoat",
        params = {1},
    },
    ["OWN_3_RODS"] = {
        id = 1827954620928650,
        reward = {money=250},
        callback = "TotalRod",
        params = {1},
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