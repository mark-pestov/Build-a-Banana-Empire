-- PickUpBuildingSystem.luau
-- Handles server-side logic for picking up buildings with the Hammer tool

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PickUpBuildingEvent = ReplicatedStorage:FindFirstChild("PickUpBuildingEvent")
if not PickUpBuildingEvent then
    PickUpBuildingEvent = Instance.new("RemoteEvent")
    PickUpBuildingEvent.Name = "PickUpBuildingEvent"
    PickUpBuildingEvent.Parent = ReplicatedStorage
end

PickUpBuildingEvent.OnServerEvent:Connect(function(player, building)
    if building and building.Parent == Workspace.Buildings and building:GetAttribute("OwnerUserId") == player.UserId then
        -- Remove building and add to player's inventory (implement inventory logic as needed)
        building:Destroy()
        -- TODO: Add building to player's inventory system
    end
end)
