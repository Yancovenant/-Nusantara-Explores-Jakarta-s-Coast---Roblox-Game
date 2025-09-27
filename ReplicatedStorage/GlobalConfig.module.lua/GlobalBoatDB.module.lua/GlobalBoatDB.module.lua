-- Global Boat DB

local GBD = {}

GBD.BOAT_LIST = {
    ["Coastal Skiff"] = {
        id = 1,
        seats = 1,
        price = 1500,
        icon = "rbxassetid:", -- TODO: replace with actual
        physics = { -- in studs
            maxSpeed = 20, --
            reverseMaxSpeed = 12, --
            acceleration = 12, --
            brakeDecel = 36, --
            -- rudderForce = 2000,
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
        icon = "rbxassetid:",
        physics = { -- in studs
            maxSpeed = 55,
            reverseMaxSpeed = 18,
            acceleration = 15,
            brakeDecel = 48,
            -- rudderForce = 2500,
            turnRate = math.rad(780),
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
        icon = "rbxassetid:",
        physics = { -- in studs
            maxSpeed = 60,
            reverseMaxSpeed = 14,
            acceleration = 17,
            brakeDecel = 40,
            -- rudderForce = 2800,
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
}

return GBD