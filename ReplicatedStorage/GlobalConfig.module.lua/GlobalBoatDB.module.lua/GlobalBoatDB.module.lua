-- Global Boat DB

local GBD = {}

GBD.BOAT_LIST = {
    ["Coastal Skiff"] = {
        id = 1,
        seats = 1,
        price = 1500,
        icon = "rbxassetid:",
        physics = { -- in studs
            maxSpeed = 60,
            reverseMaxSpeed = 12,
            acceleration = 28,
            brakeDecel = 36,
            turnRate = 65,
            turnAccel = 180,
            driftFactor = 0.8,
            buoyancyScaler = 1.05,
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
        icon = "rbxassetid:",
        physics = { -- in studs
            maxSpeed = 110,
            reverseMaxSpeed = 18,
            acceleration = 42,
            brakeDecel = 48,
            turnRate = 55,
            turnAccel = 220,
            driftFactor = 0.24,
            buoyancyScaler = 1.02,
            linearDamping = 0.4,
            angularDamping = 0.9,
        },
        control = {
            inputDeadzone = 0.06,
            throttleCurve = {0, 0.6, 1},
            steerCurve = {0, 0.7, 1},
        }
    },
}

return GBD