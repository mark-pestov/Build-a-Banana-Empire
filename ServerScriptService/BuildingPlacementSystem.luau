-- BuildingPlacementSystem.luau
-- Handles placement of buildings (formerly seeds) with outline preview and overlap prevention

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlacementSystem = {}

-- RemoteEvent for placement requests
local PlaceBuildingEvent = ReplicatedStorage:FindFirstChild("PlaceBuildingEvent")
if not PlaceBuildingEvent then
    PlaceBuildingEvent = Instance.new("RemoteEvent")
    PlaceBuildingEvent.Name = "PlaceBuildingEvent"
    PlaceBuildingEvent.Parent = ReplicatedStorage
end

-- Utility: Check for overlap with existing buildings
local function isAreaClear(position, size)
    for _, building in ipairs(Workspace.Buildings:GetChildren()) do
        if (building.Position - position).magnitude < (building.Size.Magnitude + size.Magnitude) / 2 then
            return false
        end
    end
    return true
end

-- Place a building for a player
function PlacementSystem.PlaceBuilding(player, buildingType, position, size)
    if not isAreaClear(position, size) then
        return false, "Cannot place: Overlaps another building."
    end
    local newBuilding = Instance.new("Part")
    newBuilding.Name = buildingType
    newBuilding.Size = size
    newBuilding.Position = position
    newBuilding.Anchored = true
    newBuilding.Parent = Workspace.Buildings
    newBuilding:SetAttribute("OwnerUserId", player.UserId)
    newBuilding:SetAttribute("Type", buildingType)
    return true, newBuilding
end

-- Listen for placement requests
PlaceBuildingEvent.OnServerEvent:Connect(function(player, buildingType, position, size)
    local success, result = PlacementSystem.PlaceBuilding(player, buildingType, position, size)
    PlaceBuildingEvent:FireClient(player, success, result)
end)

return PlacementSystem
