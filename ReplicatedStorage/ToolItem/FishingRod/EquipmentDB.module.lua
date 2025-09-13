-- EquipmentDB.module.lua

local EquipmentDB = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[
    EQUIPMENT SYSTEM OVERVIEW
    
    Equipment Types:
    1. Fishing Rods - Base power, durability, fish attraction
    2. Bobbers - Bite detection, reaction time, special effects
    3. Bait - Fish attraction, rarity bonuses, habitat preferences
    4. Fishing Lines - Strength, invisibility, special properties
    
    Equipment Stats:
    - Power: Affects casting distance and fish catch rate
    - Durability: How long equipment lasts before breaking
    - Attraction: Increases chances of fish biting
    - Special: Unique effects (invisible line, magnetic bobber, etc.)
]]--

-- EQUIPMENT CATEGORIES
EquipmentDB.Rods = {
    -- ===== STARTER RODS =====
    ["Basic Rod"] = {
        id = 1,
        name = "Basic Rod",
        rarity = "Common",
        luck = 1.0, -- Replaces attraction, affects fish rarity chances
        price = 0,
        description = "A simple fishing rod for beginners",
        icon = "rbxassetid://115011593432581",
        largePreview = "",
        unlockLevel = 1
    },
    ["Wooden Rod"] = {
        id = 2,
        name = "Wooden Rod", 
        rarity = "Common",
        luck = 1.2,
        price = 100,
        description = "Sturdy wooden rod with better luck",
        icon = "rbxassetid://127772934799813",
        largePreview = "",
        unlockLevel = 3
    },
    
    -- ===== INTERMEDIATE RODS =====
    ["Bamboo Rod"] = {
        id = 3,
        name = "Bamboo Rod",
        rarity = "Uncommon", 
        luck = 1.5,
        price = 500,
        description = "Flexible bamboo rod, increases rare fish chances",
        icon = "rbxassetid://87203609835635",
        largePreview = "",
        unlockLevel = 8
    },
    ["Carbon Fiber Rod"] = {
        id = 4,
        name = "Carbon Fiber Rod",
        rarity = "Rare",
        luck = 2.0,
        price = 2000,
        description = "Lightweight and powerful, great for rare catches",
        icon = "rbxassetid://94535429687898",
        largePreview = "",
        unlockLevel = 15
    },
    
    -- ===== ADVANCED RODS =====
    ["Titanium Rod"] = {
        id = 5,
        name = "Titanium Rod",
        rarity = "Epic",
        luck = 2.5,
        price = 10000,
        description = "Ultra-strong titanium construction with high luck",
        icon = "rbxassetid://83297816950294",
        largePreview = "",
        unlockLevel = 25
    },
    ["Legendary Rod"] = {
        id = 6,
        name = "Legendary Rod",
        rarity = "Legendary",
        luck = 3.0,
        price = 50000,
        description = "Mythical rod with incredible luck for legendary fish",
        icon = "rbxassetid://109262823337916",
        largePreview = "",
        unlockLevel = 40
    }
}

EquipmentDB.Bobbers = {
    -- ===== BASIC BOBBERS =====
    ["Cork Bobber"] = {
        id = 1,
        name = "Cork Bobber",
        rarity = "Common",
        luck = 1.0,
        specialEffect = "none",
        price = 0,
        description = "Simple cork bobber for basic fishing",
        icon = "rbxassetid://123456800",
        textureId = "rbxassetid://cork_bobber_texture",
        unlockLevel = 1
    },
    ["Plastic Bobber"] = {
        id = 2,
        name = "Plastic Bobber",
        rarity = "Common",
        luck = 1.1,
        specialEffect = "none",
        price = 50,
        description = "Lightweight plastic bobber",
        icon = "rbxassetid://123456801",
        textureId = "rbxassetid://plastic_bobber_texture",
        unlockLevel = 2
    },
    
    -- ===== SPECIALIZED BOBBERS =====
    ["Sensitive Bobber"] = {
        id = 3,
        name = "Sensitive Bobber",
        rarity = "Uncommon",
        luck = 1.3,
        specialEffect = "none",
        price = 200,
        description = "More sensitive to fish activity",
        icon = "rbxassetid://123456802",
        textureId = "rbxassetid://sensitive_bobber_texture",
        unlockLevel = 5
    },
    ["Magnetic Bobber"] = {
        id = 4,
        name = "Magnetic Bobber",
        rarity = "Rare",
        luck = 1.4,
        specialEffect = "attracts_metal_fish",
        price = 1000,
        description = "Attracts fish with metallic scales",
        icon = "rbxassetid://123456803",
        textureId = "rbxassetid://magnetic_bobber_texture",
        unlockLevel = 12
    },
    ["Glowing Bobber"] = {
        id = 5,
        name = "Glowing Bobber",
        rarity = "Epic",
        luck = 1.5,
        specialEffect = "night_fishing_bonus",
        price = 5000,
        description = "Glows in the dark, attracts nocturnal fish",
        icon = "rbxassetid://123456804",
        textureId = "rbxassetid://glowing_bobber_texture",
        unlockLevel = 20
    }
}

EquipmentDB.Bait = {
    -- ===== BASIC BAIT =====
    ["Worm"] = {
        id = 1,
        name = "Worm",
        rarity = "Common",
        luck = 1.0,
        habitatBonus = {
            Coastal = 1.2,
            Mangrove = 1.1
        },
        rarityBonus = {
            Common = 1.1,
            Uncommon = 1.0
        },
        price = 10,
        description = "Basic worm bait, attracts common fish",
        icon = "rbxassetid://123456810",
        textureId = "rbxassetid://worm_texture",
        unlockLevel = 1
    },
    ["Bread"] = {
        id = 2,
        name = "Bread",
        rarity = "Common",
        luck = 0.9,
        habitatBonus = {
            Coastal = 1.3,
            Mangrove = 1.2
        },
        rarityBonus = {
            Common = 1.2,
            Uncommon = 0.8
        },
        price = 5,
        description = "Simple bread bait for small fish",
        icon = "rbxassetid://123456811",
        textureId = "rbxassetid://bread_texture",
        unlockLevel = 1
    },
    
    -- ===== SPECIALIZED BAIT =====
    ["Shrimp"] = {
        id = 3,
        name = "Shrimp",
        rarity = "Uncommon",
        luck = 1.3,
        habitatBonus = {
            Reef = 1.4,
            Ocean = 1.2
        },
        rarityBonus = {
            Uncommon = 1.3,
            Rare = 1.1
        },
        price = 100,
        description = "Fresh shrimp, attracts reef fish",
        icon = "rbxassetid://123456812",
        textureId = "rbxassetid://shrimp_texture",
        unlockLevel = 6
    },
    ["Squid"] = {
        id = 4,
        name = "Squid",
        rarity = "Rare",
        luck = 1.5,
        habitatBonus = {
            Ocean = 1.5,
            DeepSea = 1.3
        },
        rarityBonus = {
            Rare = 1.4,
            Epic = 1.2
        },
        price = 500,
        description = "Premium squid bait for big ocean fish",
        icon = "rbxassetid://123456813",
        textureId = "rbxassetid://squid_texture",
        unlockLevel = 12
    },
    ["Golden Bait"] = {
        id = 5,
        name = "Golden Bait",
        rarity = "Epic",
        luck = 2.0,
        habitatBonus = {
            Ocean = 1.3,
            DeepSea = 1.5,
            Reef = 1.2
        },
        rarityBonus = {
            Epic = 1.5,
            Legendary = 1.3,
            Mythical = 1.1
        },
        price = 2000,
        description = "Magical golden bait, attracts rare fish",
        icon = "rbxassetid://123456814",
        textureId = "rbxassetid://golden_bait_texture",
        unlockLevel = 25
    }
}

EquipmentDB.FishingLines = {
    -- ===== BASIC LINES =====
    ["Cotton Line"] = {
        id = 1,
        name = "Cotton Line",
        rarity = "Common",
        strength = 1.0,
        invisibility = 0.0,
        specialEffect = "none",
        price = 0,
        description = "Basic cotton fishing line",
        icon = "rbxassetid://123456820",
        textureId = "rbxassetid://cotton_line_texture",
        unlockLevel = 1
    },
    ["Nylon Line"] = {
        id = 2,
        name = "Nylon Line",
        rarity = "Common",
        strength = 1.2,
        invisibility = 0.1,
        specialEffect = "none",
        price = 25,
        description = "Stronger nylon line",
        icon = "rbxassetid://123456821",
        textureId = "rbxassetid://nylon_line_texture",
        unlockLevel = 3
    },
    
    -- ===== ADVANCED LINES =====
    ["Fluorocarbon Line"] = {
        id = 3,
        name = "Fluorocarbon Line",
        rarity = "Uncommon",
        strength = 1.3,
        invisibility = 0.5,
        specialEffect = "invisible_to_fish",
        price = 150,
        description = "Nearly invisible underwater",
        icon = "rbxassetid://123456822",
        textureId = "rbxassetid://fluorocarbon_line_texture",
        unlockLevel = 8
    },
    ["Braided Line"] = {
        id = 4,
        name = "Braided Line",
        rarity = "Rare",
        strength = 2.0,
        invisibility = 0.2,
        specialEffect = "extra_strong",
        price = 800,
        description = "Ultra-strong braided line for big fish",
        icon = "rbxassetid://123456823",
        textureId = "rbxassetid://braided_line_texture",
        unlockLevel = 15
    },
    ["Mystic Line"] = {
        id = 5,
        name = "Mystic Line",
        rarity = "Legendary",
        strength = 1.8,
        invisibility = 0.8,
        specialEffect = "luck_boost",
        price = 5000,
        description = "Mystical line that boosts luck",
        icon = "rbxassetid://123456824",
        textureId = "rbxassetid://mystic_line_texture",
        unlockLevel = 30
    }
}

-- HELPER FUNCTIONS
function EquipmentDB:getRod(id)
    local finalRod
    for name, rod in pairs(self.Rods) do
        if rod.id == id then
            finalRod = rod
            break
        end
    end
    local rodTemplateModel = ReplicatedStorage:WaitForChild("ToolItem"):WaitForChild("RodTemplate"):FindFirstChild(string.gsub(finalRod.name, "%s+", ""))
    if not rodTemplateModel then
        rodTemplateModel = ReplicatedStorage:WaitForChild("ToolItem"):WaitForChild("RodTemplate"):FindFirstChild("TemplateRod")
    end
    return finalRod, rodTemplateModel
end

-- function EquipmentDB:getBobber(id)
--     for name, bobber in pairs(self.Bobbers) do
--         if bobber.id == id then
--             return bobber
--         end
--     end
--     return nil
-- end

-- function EquipmentDB:getBait(id)
--     for name, bait in pairs(self.Bait) do
--         if bait.id == id then
--             return bait
--         end
--     end
--     return nil
-- end

-- function EquipmentDB:getFishingLine(id)
--     for name, line in pairs(self.FishingLines) do
--         if line.id == id then
--             return line
--         end
--     end
--     return nil
-- end

-- function EquipmentDB:getEquipmentByRarity(rarity)
--     local equipment = {}
    
--     for name, rod in pairs(self.Rods) do
--         if rod.rarity == rarity then
--             table.insert(equipment, {type = "rod", data = rod})
--         end
--     end
    
--     for name, bobber in pairs(self.Bobbers) do
--         if bobber.rarity == rarity then
--             table.insert(equipment, {type = "bobber", data = bobber})
--         end
--     end
    
--     for name, bait in pairs(self.Bait) do
--         if bait.rarity == rarity then
--             table.insert(equipment, {type = "bait", data = bait})
--         end
--     end
    
--     for name, line in pairs(self.FishingLines) do
--         if line.rarity == rarity then
--             table.insert(equipment, {type = "line", data = line})
--         end
--     end
    
--     return equipment
-- end

return EquipmentDB
