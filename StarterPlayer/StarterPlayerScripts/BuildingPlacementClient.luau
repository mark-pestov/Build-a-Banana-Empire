-- BuildingPlacementClient.luau
-- Client-side building placement with outline preview

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local PlaceBuildingEvent = ReplicatedStorage:WaitForChild("PlaceBuildingEvent")

local function showOutline(position, size)
    local outline = Instance.new("Part")
    outline.Name = "PlacementOutline"
    outline.Size = size
    outline.Position = position
    outline.Anchored = true
    outline.Transparency = 0.5
    outline.Color = Color3.fromRGB(0, 255, 0)
    outline.CanCollide = false
    outline.Parent = Workspace
    return outline
end

local function removeOutline()
    for _, part in ipairs(Workspace:GetChildren()) do
        if part.Name == "PlacementOutline" then
            part:Destroy()
        end
    end
end

-- Example: Call this when player selects a building to place
function StartPlacement(buildingType, size)
    local mouse = Players.LocalPlayer:GetMouse()
    local outline
    local placing = true
    
    local function updateOutline()
        if outline then outline:Destroy() end
        outline = showOutline(mouse.Hit.p, size)
    end

    mouse.Move:Connect(function()
        if placing then updateOutline() end
    end)

    mouse.Button1Down:Connect(function()
        if placing then
            PlaceBuildingEvent:FireServer(buildingType, mouse.Hit.p, size)
            placing = false
            removeOutline()
        end
    end)
end

-- Listen for placement result
PlaceBuildingEvent.OnClientEvent:Connect(function(success, result)
    if not success then
        warn(result)
    end
end)
