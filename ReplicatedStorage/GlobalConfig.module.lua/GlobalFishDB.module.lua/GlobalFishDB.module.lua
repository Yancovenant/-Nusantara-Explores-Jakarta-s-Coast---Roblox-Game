-- Global Fish DB

local GFD = {}


GFD.FISH = {
    -- ===== COMMON FISH =====
	["Euthynnus affinis"] = {
		id = 1,
		rarity = "Common",
		habitat = "Ocean",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://123625993045895",
		baseChance = 1/50 -- 0.02%
	},
	["Kerapu Legend"] = {
		id = 2,
		rarity = "Common",
		habitat = "Reef",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://124141177788555",
		baseChance = 1/55 -- 0.01818181818181818%
	},
	["Lutjanus campechanus"] = {
		id = 3,
		rarity = "Common",
		habitat = "Coastal",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://139389458318053",
		baseChance = 1/60 -- 0.016666666666666666%
	},
	["Milkfish"] = {
		id = 4,
		rarity = "Common",
		habitat = "Mangrove",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://130683257339205",
		baseChance = 1/85 -- 0.011764705882352941%
	},
	["Mullet"] = {
		id = 5,
		rarity = "Common",
		habitat = "Coastal",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://132064291206318",
		baseChance = 1/100 -- 0.01%
	},
	-- ===== UNCOMMON FISH =====
	["Parrotfish"] = {
		id = 6,
		rarity = "Uncommon",
		habitat = "Reef",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://115225809705688",
		baseChance = 1/200 -- 0.005%
	},
	["Butterfish"] = {
		id = 7,
		rarity = "Uncommon",
		habitat = "Coastal",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://99172709912291",
		baseChance = 1/300 -- 0.0033333%
	},
	["Striped Mackerel"] = {
		id = 8,
		rarity = "Uncommon",
		habitat = "Ocean",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://84713285230199",
		baseChance = 1/500 -- 0.002%
	},
	-- ===== RARE FISH =====
	["Remora"] = {
		id = 9,
		rarity = "Rare",
		habitat = "Ocean",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://126282853926629",
		baseChance = 1/1000 -- 0.001%
	},
	["Blue Tang"] = {
		id = 10,
		rarity = "Rare",
		habitat = "Reef",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://82932779922755",
		baseChance = 1/5000 -- 0.0002%
	},
	-- ===== EPIC FISH =====
	["Blue Marlin"] = {
		id = 11,
		rarity = "Epic",
		habitat = "Ocean",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://126091718047687",
		baseChance = 1/8000 -- 0.000125%
	},
	-- ===== LEGENDARY FISH =====
	["Shark"] = {
		id = 12,
		rarity = "Legendary",
		habitat = "Ocean",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://99220617200779",
		baseChance = 1/10000 -- 0.0001%
	},
	-- ===== MYTHICAL FISH =====
	["Ceolocanth"] = {
		id = 13,
		rarity = "Mythical",
		habitat = "AncientZone",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://74746064929886",
		baseChance = 1/50000 -- 0.00002%
	},
	-- ===== CLASSIFIED FISH =====
	["SunnyCat"] = {
		id = 14,
		rarity = "Classified",
		habitat = "EventZone",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://124429493982335",
		baseChance = 1/100000 -- 0.00001%
	},

	--- ==== VERSION 2 =====
	-- ===== COMMON FISH =====
	["Blenny"] = {
		id = 15,
		rarity = "Common",
		habitat = "Reef",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://xxxxxx",
		baseChance = 1/110 -- 0.%
	},
	["Clarkii Clownfish"] = {
		id = 16,
		rarity = "Common",
		habitat = "Reef",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://xxxxxx",
		baseChance = 1/290 -- 0.%
	},
	["Mangrove Snapper"] = {
		id = 17,
		rarity = "Common",
		habitat = "Mangrove",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://xxxxxx",
		baseChance = 1/800 -- 0.%
	},
	-- ===== UNCOMMON FISH =====
	["Boxfish"] = {
		id = 18,
		rarity = "Uncommon",
		habitat = "Reef",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://xxxxxx",
		baseChance = 1/1100 -- 0.%
	},
	["Atlantic Cod"] = {
		id = 19,
		rarity = "Uncommon",
		habitat = "DeepSea",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://xxxxxx",
		baseChance = 1/1500 -- 0.%
	},
	["Jakarta Grouper"] = {
		id = 20,
		rarity = "Uncommon",
		habitat = "Reef",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://xxxxxx",
		baseChance = 1/1800 -- 0.%
	},
	-- ===== RARE FISH =====
	["Yellowtail Amberjack"] = {
		id = 21,
		rarity = "Rare",
		habitat = "Ocean",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://xxxxxx",
		baseChance = 1/2000 -- 0.%
	},
	["Cobia"] = {
		id = 22,
		rarity = "Rare",
		habitat = "Ocean",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://xxxxxx",
		baseChance = 1/2500 -- 0.%
	},
	["Sailfish"] = {
		id = 23,
		rarity = "Rare",
		habitat = "Ocean",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://xxxxxx",
		baseChance = 1/2500 -- 0.%
	},
	-- ===== EPIC FISH =====
	["Sphyraena Barracuda"] = {
		id = 24,
		rarity = "Epic",
		habitat = "Ocean",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://xxxxxx",
		baseChance = 1/2500 -- 0.%
	},
	["Ikan Napoleon"] = {
		id = 25,
		rarity = "Epic",
		habitat = "Reef",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://xxxxxx",
		baseChance = 1/2500 -- 0.%
	},
	-- ===== LEGENDARY FISH =====
	["Indo-Pacific Sailfish"] = {
		id = 26,
		rarity = "Legendary",
		habitat = "Ocean",
		minWeight = 0.1,
		maxWeight = 100000, -- in kg
		icon = "rbxassetid://xxxxxx",
		baseChance = 1/2500 -- 0.%
	},
	-- ===== MYTHICAL FISH =====
	-- ===== CLASSIFIED FISH =====
}


return GFD