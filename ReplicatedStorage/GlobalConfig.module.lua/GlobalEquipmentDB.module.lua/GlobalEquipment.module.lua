-- Global Equipment DB

local GED = {}
local RS = game:GetService("ReplicatedStorage")

GED.RODS = {
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

function GED:GetRod(id): (table, Model) -- return table + model
    local FinalRodData
    for _, rod in pairs(self.RODS) do
        if rod.id == id then
            FinalRodData = rod
            break
        end
    end
    local RodModel = RS:WaitForChild("ToolItem"):WaitForChild("RodTemplate"):FindFirstChild(string.gsub(FinalRodData.name, "%s+", ""))
    if not RodModel then
        RodModel = RS:WaitForChild("ToolItem"):WaitForChild("RodTemplate"):FindFirstChild("TemplateRod") -- fallback to use template
    end
    return FinalRodData, RodModel
end

return GED