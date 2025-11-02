-- PathwaySystem.luau
-- Handles the main conveyor system that moves buildings through the map (the "pathway")
-- Buildings move from one end to the other, and players can buy or steal them as they pass

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Use the existing 'Pathway' part in Workspace for the conveyor system
local Pathway = Workspace:FindFirstChild("Pathway")
assert(Pathway, "Pathway part must exist in Workspace!")

local PathwayStart = Vector3.new(-49.462, 7.656, -347.7)
local PathwayEnd = Vector3.new(-49.462, 7.656, 78.933)
local PathwayDirection = (PathwayEnd - PathwayStart).Unit
local PathwayLength = (PathwayEnd - PathwayStart).Magnitude
local ConveyorSpeed = 10 -- studs per second (adjust as needed)

local BuildingTemplates = ReplicatedStorage:FindFirstChild("BuildingTemplates")
if not BuildingTemplates then
    BuildingTemplates = Instance.new("Folder")
    BuildingTemplates.Name = "BuildingTemplates"
    BuildingTemplates.Parent = ReplicatedStorage
end

local function setModelAnchored(model, anchored)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = anchored
        end
    end
end

local function setModelCanCollide(model, canCollide)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = canCollide
        end
    end
end

-- Spawns a building at the start of the pathway
local function spawnBuilding()
    local templates = BuildingTemplates:GetChildren()
    if #templates == 0 then return end
    local template = templates[math.random(1, #templates)]
    local building = template:Clone()
    building.Parent = Workspace
    if building:IsA("Model") then
        if not building.PrimaryPart then
            warn(building.Name .. " has no PrimaryPart set!")
            return
        end
        local yOffset = PathwayStart.Y + building.PrimaryPart.Size.Y/2
        local startPos = Vector3.new(PathwayStart.X, yOffset, PathwayStart.Z)
        building:SetPrimaryPartCFrame(CFrame.new(startPos))
        setModelAnchored(building, false)
        setModelCanCollide(building, false) -- Make all parts non-collidable
        building:SetAttribute("OnPathway", true)
    elseif building:IsA("BasePart") then
        local yOffset = PathwayStart.Y + building.Size.Y/2
        building.Position = Vector3.new(PathwayStart.X, yOffset, PathwayStart.Z)
        building.Anchored = false
        building.CanCollide = false -- Make part non-collidable
        building:SetAttribute("OnPathway", true)
    end
    return building
end

-- Moves all buildings along the pathway
local function moveBuildings(dt)
    for _, building in ipairs(Workspace:GetChildren()) do
        if building:GetAttribute("OnPathway") then
            if building:IsA("Model") and building.PrimaryPart then
                local newPos = building.PrimaryPart.Position + PathwayDirection * ConveyorSpeed * dt
                building:SetPrimaryPartCFrame(CFrame.new(newPos))
                -- Check if passed the end
                if (newPos - PathwayStart).Magnitude > PathwayLength then
                    building:Destroy()
                end
            elseif building:IsA("BasePart") then
                local newPos = building.Position + PathwayDirection * ConveyorSpeed * dt
                building.Position = newPos
                if (newPos - PathwayStart).Magnitude > PathwayLength then
                    building:Destroy()
                end
            end
        end
    end
end

-- Main loop
spawn(function()
    while true do
        spawnBuilding()
        wait(5) -- spawn interval
    end
end)

-- Heartbeat for movement
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    moveBuildings(dt)
end)

-- Player interaction (buy/steal)
local BuyOrStealEvent = ReplicatedStorage:FindFirstChild("BuyOrStealBuildingEvent")
if not BuyOrStealEvent then
    BuyOrStealEvent = Instance.new("RemoteEvent")
    BuyOrStealEvent.Name = "BuyOrStealBuildingEvent"
    BuyOrStealEvent.Parent = ReplicatedStorage
end

BuyOrStealEvent.OnServerEvent:Connect(function(player, building, action)
    if building and building:GetAttribute("OnPathway") then
        if action == "buy" then
            -- TODO: Deduct Blox, transfer building to player
            building:SetAttribute("OwnerUserId", player.UserId)
            building:SetAttribute("OnPathway", false)
            building.Anchored = true
        elseif action == "steal" then
            -- TODO: Implement stealing logic (risk, cooldown, etc.)
            building:SetAttribute("OwnerUserId", player.UserId)
            building:SetAttribute("OnPathway", false)
            building.Anchored = true
        end
    end
end)
