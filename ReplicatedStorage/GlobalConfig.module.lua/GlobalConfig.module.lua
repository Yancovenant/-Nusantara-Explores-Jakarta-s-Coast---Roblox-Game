-- Global Config

local GC = {}

-- FISH --
GC.FISHING = {
    BOBBER_ANIMATION_SPEED = 2,
    BOBBER_FLOAT_HEIGHT = 0.22,
    BITE_DELAY_MIN = 3,
    BITE_DELAY_MAX = 6,
    CHARGE_TIME = 1.0,
    BASE_RANGE = 19,
    WalkSpeed = 8,
    FISH_DATA = require(script.GlobalFishDB),
    POWER_CATEGORIES = {
        {min = 0, max = 30, name = "Weak", color = Color3.fromRGB(255, 100, 100)},      -- Red
        {min = 31, max = 50, name = "Not Bad", color = Color3.fromRGB(255, 165, 0)},   -- Orange
        {min = 51, max = 70, name = "OK", color = Color3.fromRGB(255, 255, 0)},        -- Yellow
        {min = 71, max = 90, name = "Regular", color = Color3.fromRGB(100, 255, 100)}, -- Green
        {min = 91, max = 100, name = "Professional", color = Color3.fromRGB(100, 100, 255)} -- Blue
    },
    MULTI = {
        LUCK = 0.1,
        LVL = 0.3,
        POWER = 0.3,
    }
}

-- EQUIPMENT --
GC.EQUIPMENT = {
    GED = require(script.GlobalEquipmentDB)
}

-- PLAYER --
GC.PLAYER = {
    DEFAULT_ATTRS = {
        CameraMaxZoomDistance = 24
    },
    HUMANOID_DEFAULT_ATTRS = {
        WalkSpeed = 16,
        MaxHealth = 100,
        Health = 100
    },
    RUN_SPEED = 24,
    AUTOSAVE_INTERVAL = 120, -- 2 minutes
    XPGROWTH = {
        BASE_XP = 50,
        GROWTH = 1.5
    }
}

-- RARITY --
GC.RARITY_COLORS = {
    Common = Color3.fromRGB(180, 180, 180),        -- Light Gray - Clean, neutral
    Uncommon = Color3.fromRGB(100, 255, 100),      -- Bright Green - Fresh, nature
    Rare = Color3.fromRGB(100, 150, 255),          -- Bright Blue - Sky blue, calming
    Epic = Color3.fromRGB(200, 100, 255),         -- Purple - Royal, mysterious
    Legendary = Color3.fromRGB(255, 215, 0),      -- Gold - Classic legendary color
    Mythical = Color3.fromRGB(255, 100, 255),     -- Magenta - Mystical, otherworldly
    Classified = Color3.fromRGB(255, 255, 255)    -- White - Pure, secretive
}
GC.RARITY_ORDER = {
    ["Classified"] = 7,
    ["Mythical"] = 6,
    ["Legendary"] = 5,
    ["Epic"] = 4,
    ["Rare"] = 3,
    ["Uncommon"] = 2,
    ["Common"] = 1
}
GC.RARITY_MULTIXP = {
    ["Classified"] = 7,
	["Mythical"] = 5.5,
	["Legendary"] = 5,
	["Epic"] = 3.5,
	["Rare"] = 2,
	["Uncommon"] = 1.25,
	["Common"] = 1
}

-- STATIC FUNCTIONS
function GC:GetRarityColor(rarity)
    return self.RARITY_COLORS[rarity] or self.RARITY_COLORS.Common
end

--- 
local ZONEVIBES_CONFIG = {
    ["Default"] = {
        ColorCorrection = {
            Enabled = false
        },
        Bloom = {
            Intensity = 1,
            Size = 24
        },
        Atmosphere = {
            Density = 0.3,
            Offset = 0.25,
            Color = Color3.fromRGB(199,199,199)
        }
    },
    ["Coast"] = {
        ColorCorrection = {
            Contrast = 0.06,
            Saturation = -0.06,
            TintColor = Color3.fromRGB(200, 220, 230),
            Enabled = true
        },
        Bloom = {
            Intensity = 0.25,
            Size = 12
        },
        Atmosphere = {
            Density = 0.22,
            Offset = 0.05,
            Color = Color3.fromRGB(200,210,220)
        }
    }
}


return GC


