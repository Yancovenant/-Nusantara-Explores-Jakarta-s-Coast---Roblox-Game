-- Global Boat DB

local GBD = {}

GBD.BOAT_LIST = {
    ["Coastal Skiff"] = {
        id = 1,
        seats = 1,
        price = 1500,
        icon = "rbxassetid://106725620801819",
        physics = {
            maxSpeed = 20,
            reverseMaxSpeed = 12,
            acceleration = 12,
            brakeDecel = 36,
            turnRate = math.rad(560),
            linearDamping = 0.5,
            angularDamping = 1.2,
        },
        control = {
            inputDeadzone = 0.08,
            throttleCurve = {0, 0.5, 1},
            steerCurve = {0, 0.6, 1},
        }
    },
    ["Reef Runner"] = {
        id = 2,
        seats = 2,
        price = 6500,
        icon = "rbxassetid://77237751948121",
        physics = {
            maxSpeed = 32,
            reverseMaxSpeed = 12,
            acceleration = 7,
            brakeDecel = 48,
            turnRate = math.rad(780), -- 2000
            linearDamping = 0.4,
            angularDamping = 0.9,
        },
        control = {
            inputDeadzone = 0.06,
            throttleCurve = {0, 0.6, 1},
            steerCurve = {0, 0.7, 1},
        }
    },
    ["WaveCutter JetSki"] = {
        id = 3,
        seats = 1,
        price = 4800,
        icon = "rbxassetid://125036036729945",
        physics = { -- in studs
            maxSpeed = 60,
            reverseMaxSpeed = 14,
            acceleration = 17,
            brakeDecel = 40,
            turnRate = math.rad(1005),
            linearDamping = 0.45,
            angularDamping = 1.0,
        },
        control = {
            inputDeadzone = 0.06,
            throttleCurve = {0, 0.6, 1},
            steerCurve = {0, 0.7, 1},
        }
    },
    ["Marlin Cruiser"] = {
        id = 4,
        seats = 4,
        price = 12000,
        icon = "rbxassetid://128865558973112",
        physics = {
            maxSpeed = 24,
            reverseMaxSpeed = 8,
            acceleration = 12,
            brakeDecel = 44,
            turnRate = math.rad(780), -- 1000
            linearDamping = 0.55,
            angularDamping = 1.1,
        },
    },
    ["Barracuda Speedboat"] = {
        id = 5,
        seats = 3,
        price = 18500,
        icon = "rbxassetid://92471111392614",
        physics = {
            maxSpeed = 40,
            reverseMaxSpeed = 20,
            acceleration = 7,
            brakeDecel = 52,
            turnRate = math.rad(1200), -- 950 1200
            linearDamping = 0.35,
            angularDamping = 0.8,
        },
    },
}

return GBD