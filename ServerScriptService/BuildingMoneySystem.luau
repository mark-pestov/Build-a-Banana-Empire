-- BuildingMoneySystem.luau
-- Handles automatic money generation for player-owned buildings

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent for UI updates
local BuildingMoneyEvent = ReplicatedStorage:FindFirstChild("BuildingMoneyEvent")
if not BuildingMoneyEvent then
    BuildingMoneyEvent = Instance.new("RemoteEvent")
    BuildingMoneyEvent.Name = "BuildingMoneyEvent"
    BuildingMoneyEvent.Parent = ReplicatedStorage
end

-- Settings
local MONEY_PER_SECOND = 3

-- Utility: Get all buildings owned by a player
local function getPlayerBuildings(player)
    -- Replace this with your actual building tracking logic
    -- Example: return workspace.Buildings:GetChildren() filtered by owner
    local buildings = {}
    if workspace:FindFirstChild("Buildings") then
        for _, building in ipairs(workspace.Buildings:GetChildren()) do
            if building:GetAttribute("OwnerUserId") == player.UserId then
                table.insert(buildings, building)
            end
        end
    end
    return buildings
end

-- Main loop: generate money for each player's buildings
spawn(function()
    while true do
        for _, player in ipairs(Players:GetPlayers()) do
            local buildings = getPlayerBuildings(player)
            for _, building in ipairs(buildings) do
                if _G.CoinSystem and _G.CoinSystem.addCoins then
                    _G.CoinSystem.addCoins(player, MONEY_PER_SECOND)
                end
                -- Fire event to client for UI
                BuildingMoneyEvent:FireClient(player, building, MONEY_PER_SECOND)
            end
        end
        wait(1)
    end
end)
