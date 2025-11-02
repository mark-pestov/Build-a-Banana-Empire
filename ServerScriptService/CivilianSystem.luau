-- CivilianSystem.luau
-- Handles spawning and roaming of civilians on sidewalks for each player's plot

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CIVILIAN_TEMPLATE = ReplicatedStorage:FindFirstChild("CivilianTemplate")
if not CIVILIAN_TEMPLATE then
    CIVILIAN_TEMPLATE = Instance.new("Model")
    CIVILIAN_TEMPLATE.Name = "CivilianTemplate"
    local part = Instance.new("Part")
    part.Name = "HumanoidRootPart"
    part.Size = Vector3.new(2, 3, 1)
    part.Anchored = false
    part.Parent = CIVILIAN_TEMPLATE
    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = CIVILIAN_TEMPLATE
    CIVILIAN_TEMPLATE.Parent = ReplicatedStorage
end

-- Utility: Find all sidewalk parts connected to a given part
local function getConnectedSidewalks(startPart, visited)
    visited = visited or {}
    if visited[startPart] then return {} end
    visited[startPart] = true
    local group = {startPart}
    for _, other in ipairs(Workspace:GetDescendants()) do
        if other:IsA("BasePart") and other ~= startPart and other.Name:lower() == "sidewalk" then
            if (startPart.Position - other.Position).Magnitude < (startPart.Size.Magnitude + other.Size.Magnitude) / 2 + 0.1 then
                for _, p in ipairs(getConnectedSidewalks(other, visited)) do
                    table.insert(group, p)
                end
            end
        end
    end
    return group
end

-- Utility: Get all sidewalk parts for a building
local function getBuildingSidewalks(building)
    local sidewalks = {}
    for _, d in ipairs(building:GetDescendants()) do
        if d:IsA("BasePart") and d.Name:lower() == "sidewalk" then
            table.insert(sidewalks, d)
        end
    end
    return sidewalks
end

-- Spawn a civilian for a building
local function spawnCivilianForBuilding(building)
    local sidewalks = getBuildingSidewalks(building)
    if #sidewalks == 0 then return end
    local civilian = CIVILIAN_TEMPLATE:Clone()
    civilian.Name = "Civilian"
    civilian.Parent = Workspace
    civilian:SetPrimaryPartCFrame(sidewalks[1].CFrame + Vector3.new(0, 2, 0))
    civilian.PrimaryPart.Anchored = false
    -- Attach sidewalk network info
    local network = getConnectedSidewalks(sidewalks[1])
    civilian:SetAttribute("SidewalkNetworkId", sidewalks[1].GetDebugId and sidewalks[1]:GetDebugId() or sidewalks[1].Name)
    civilian:SetAttribute("OwnerBuilding", building.Name)
    civilian:SetAttribute("RoamNetworkSize", #network)
    -- Simple AI loop
    spawn(function()
        while civilian.Parent do
            local target = network[math.random(1, #network)]
            local pos = target.Position + Vector3.new(math.random(-2,2), 2, math.random(-2,2))
            civilian.Humanoid:MoveTo(pos)
            civilian.Humanoid.MoveToFinished:Wait()
            wait(math.random(1,3))
        end
    end)
end

-- Listen for new buildings being placed
if Workspace:FindFirstChild("Buildings") then
    Workspace.Buildings.ChildAdded:Connect(function(building)
        spawnCivilianForBuilding(building)
    end)
end
