-- Main.client.lua
-- FISHING ROD MANAGER

local FM = {}
local FUI = require(script.FishingUI)
local FA = require(script.FishingAction)

-- ENTRY POINTS
function FM:main()
	FA:CleanConnections()
	FUI:CreateFishingUI()
	FA:SetupEventListener()
end
FM:main()