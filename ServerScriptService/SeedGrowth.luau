-- SeedGrowth.luau - Advanced Tree Growing System
-- Handles seed planting and realistic tree growth part by part

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Wait for required systems
repeat wait() until _G.PlotSystem
repeat wait() until _G.SeedSystem

-- Configuration
local TREE_MODELS = {
    ["Banapple"] = "BanappleTree",
    ["Golden Banapple"] = "GoldenBanappleTree",
    ["Diamond Banapple"] = "DiamondBanappleTree", 
    ["Mythical Banapple"] = "MythicalBanappleTree"
}

local GROWTH_STAGES = {
    {name = "Sprout", percentage = 0, parts = {"Stem"}},
    {name = "Sapling", percentage = 25, parts = {"Stem", "LowerTrunk"}},
    {name = "Young Tree", percentage = 50, parts = {"Stem", "LowerTrunk", "MiddleTrunk"}},
    {name = "Mature Tree", percentage = 75, parts = {"Stem", "LowerTrunk", "MiddleTrunk", "UpperTrunk"}},
    {name = "Full Tree", percentage = 100, parts = {"Stem", "LowerTrunk", "MiddleTrunk", "UpperTrunk", "Leaves", "Fruit"}}
}

-- Plant registry
local activeGrowthTrees = {}

-- Get RemoteEvents
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local plantSeedRemote = remoteEventsFolder:WaitForChild("PlantSeed")

-- Get player's plot
local function getPlayerPlot(player)
    if _G.PlotSystem and _G.PlotSystem.getPlayerPlot then
        return _G.PlotSystem.getPlayerPlot(player)
    end
    return nil
end

-- Check if position is valid for planting
local function isValidPlantingPosition(player, position)
    local plotId = getPlayerPlot(player)
    if not plotId then return false, "No plot assigned" end
    
    local plotsFolder = Workspace:FindFirstChild("Plots")
    if not plotsFolder then return false, "No plots folder found" end
    
    local plotModel = plotsFolder:FindFirstChild("Plot_" .. plotId)
    if not plotModel then return false, "Plot not found" end
    
    local dirtPatch = plotModel:FindFirstChild("DirtPatch")
    if not dirtPatch then return false, "No dirt patch found" end
    
    -- Check if position is within dirt patch
    local distance = (position - dirtPatch.Position).Magnitude
    local maxDistance = math.min(dirtPatch.Size.X, dirtPatch.Size.Z) / 2
    
    if distance > maxDistance then
        return false, "Must plant in dirt patch"
    end
    
    -- Check for existing trees nearby
    for _, child in pairs(plotModel:GetChildren()) do
        if child:FindFirstChild("IsTree") and child:FindFirstChild("HumanoidRootPart") then
            local treeDistance = (position - child.HumanoidRootPart.Position).Magnitude
            if treeDistance < 8 then
                return false, "Too close to existing tree"
            end
        end
    end
    
    return true, "Valid position"
end

-- Create tree growth system
local function createGrowingTree(player, seedType, position)
    local plotId = getPlayerPlot(player)
    if not plotId then return nil end
    
    local plotsFolder = Workspace:FindFirstChild("Plots")
    local plotModel = plotsFolder:FindFirstChild("Plot_" .. plotId)
    if not plotModel then return nil end
    
    -- Get tree template
    local templateName = TREE_MODELS[seedType]
    local template = Workspace:FindFirstChild(templateName)
    
    if not template then
        warn("Tree template not found: " .. templateName)
        return nil
    end
    
    -- Create growing tree
    local growingTree = Instance.new("Model")
    growingTree.Name = "GrowingTree_" .. seedType
    growingTree.Parent = plotModel
    
    -- Set attributes
    growingTree:SetAttribute("IsTree", true)
    growingTree:SetAttribute("SeedType", seedType)
    growingTree:SetAttribute("PlantedBy", player.UserId)
    growingTree:SetAttribute("PlantTime", tick())
    growingTree:SetAttribute("GrowthStage", 0)
    growingTree:SetAttribute("IsGrowing", true)
    growingTree:SetAttribute("IsFullyGrown", false)
    
    -- Create root part for positioning
    local rootPart = Instance.new("Part")
    rootPart.Name = "HumanoidRootPart"
    rootPart.Size = Vector3.new(0.1, 0.1, 0.1)
    rootPart.Position = position
    rootPart.Anchored = true
    rootPart.Transparency = 1
    rootPart.CanCollide = false
    rootPart.Parent = growingTree
    
    -- Create growth parts based on template
    local treeParts = {}
    for _, part in pairs(template:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local newPart = part:Clone()
            newPart.Parent = growingTree
            newPart.Anchored = true
            newPart.Transparency = 1 -- Start invisible
            newPart.CanCollide = false
            
            -- Position relative to root
            local offset = part.CFrame:ToObjectSpace(template.PrimaryPart and template.PrimaryPart.CFrame or template:GetBoundingBox())
            newPart.CFrame = rootPart.CFrame * offset
            
            treeParts[part.Name] = newPart
        end
    end
    
    -- Add to active growth registry
    activeGrowthTrees[growingTree] = {
        model = growingTree,
        parts = treeParts,
        startTime = tick(),
        seedType = seedType,
        player = player,
        currentStage = 0
    }
    
    return growingTree
end

-- Update tree growth
local function updateTreeGrowth(treeData)
    local growingTree = treeData.model
    if not growingTree or not growingTree.Parent then
        return false -- Tree was destroyed
    end
    
    local seedInfo = _G.SeedSystem.getSeedTypes()[treeData.seedType]
    if not seedInfo then return false end
    
    local elapsedTime = tick() - treeData.startTime
    local growthProgress = math.min(elapsedTime / seedInfo.growthTime, 1)
    
    -- Determine current stage
    local targetStage = 0
    for i, stage in ipairs(GROWTH_STAGES) do
        if growthProgress >= (stage.percentage / 100) then
            targetStage = i
        end
    end
    
    -- Grow new parts if we've advanced stages
    if targetStage > treeData.currentStage then
        for stage = treeData.currentStage + 1, targetStage do
            local stageInfo = GROWTH_STAGES[stage]
            
            for _, partName in ipairs(stageInfo.parts) do
                local part = treeData.parts[partName]
                if part then
                    -- Make part visible and grow it
                    part.Transparency = 0
                    part.CanCollide = true
                    
                    -- Growth animation
                    local originalSize = part.Size
                    part.Size = Vector3.new(0.1, 0.1, 0.1)
                    
                    local growTween = TweenService:Create(
                        part,
                        TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Size = originalSize}
                    )
                    growTween:Play()
                    
                    -- Growth particles
                    local attachment = Instance.new("Attachment")
                    attachment.Parent = part
                    
                    local particles = Instance.new("ParticleEmitter")
                    particles.Parent = attachment
                    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
                    particles.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
                    particles.Lifetime = NumberRange.new(0.5, 1.5)
                    particles.Rate = 50
                    particles.SpreadAngle = Vector2.new(45, 45)
                    particles.Speed = NumberRange.new(5, 10)
                    
                    -- Stop particles after 3 seconds
                    Debris:AddItem(particles, 3)
                    
                    print("Grew " .. partName .. " for " .. treeData.player.Name .. "'s " .. treeData.seedType .. " tree")
                end
            end
        end
        
        treeData.currentStage = targetStage
        growingTree:SetAttribute("GrowthStage", targetStage)
        
        -- Play stage-up sound
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
        sound.Volume = 0.5
        sound.Parent = growingTree:FindFirstChild("HumanoidRootPart")
        sound:Play()
        
        Debris:AddItem(sound, 2)
    end
    
    -- Check if fully grown
    if growthProgress >= 1 and not growingTree:GetAttribute("IsFullyGrown") then
        growingTree:SetAttribute("IsFullyGrown", true)
        growingTree:SetAttribute("IsGrowing", false)
        
        -- Add plant type for trowel system
        local plantType = Instance.new("StringValue")
        plantType.Name = "PlantType"
        plantType.Value = treeData.seedType
        plantType.Parent = growingTree
        
        -- Add rarity for trowel system
        local rarity = Instance.new("StringValue")
        rarity.Name = "Rarity"
        rarity.Value = seedInfo.rarity
        rarity.Parent = growingTree
        
        -- Completion effects
        local rootPart = growingTree:FindFirstChild("HumanoidRootPart")
        if rootPart then
            -- Completion particles
            local attachment = Instance.new("Attachment")
            attachment.Parent = rootPart
            
            local particles = Instance.new("ParticleEmitter")
            particles.Parent = attachment
            particles.Texture = "rbxasset://textures/particles/fire_main.dds"
            particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
            particles.Lifetime = NumberRange.new(1, 2)
            particles.Rate = 100
            particles.SpreadAngle = Vector2.new(360, 360)
            particles.Speed = NumberRange.new(10, 20)
            
            Debris:AddItem(particles, 5)
            
            -- Completion sound
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxasset://sounds/victory.wav"
            sound.Volume = 0.7
            sound.Parent = rootPart
            sound:Play()
            
            Debris:AddItem(sound, 3)
        end
        
        print("🌳 " .. treeData.player.Name .. "'s " .. treeData.seedType .. " tree is fully grown!")
        return false -- Remove from active growth
    end
    
    return true -- Continue growing
end

-- Growth update loop
spawn(function()
    while true do
        wait(1) -- Update every second
        
        local toRemove = {}
        for tree, treeData in pairs(activeGrowthTrees) do
            if not updateTreeGrowth(treeData) then
                table.insert(toRemove, tree)
            end
        end
        
        -- Clean up completed/destroyed trees
        for _, tree in ipairs(toRemove) do
            activeGrowthTrees[tree] = nil
        end
    end
end)

-- Handle seed planting
plantSeedRemote.OnServerEvent:Connect(function(player, seedType, position)
    print("Plant seed request from " .. player.Name .. " - " .. seedType .. " at " .. tostring(position))
    
    -- Validate position
    local isValid, message = isValidPlantingPosition(player, position)
    if not isValid then
        -- Send error message to player
        local errorGui = Instance.new("ScreenGui")
        errorGui.Parent = player.PlayerGui
        
        local errorFrame = Instance.new("Frame")
        errorFrame.Size = UDim2.new(0, 300, 0, 50)
        errorFrame.Position = UDim2.new(0.5, -150, 0, 50)
        errorFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        errorFrame.Parent = errorGui
        
        local errorLabel = Instance.new("TextLabel")
        errorLabel.Size = UDim2.new(1, 0, 1, 0)
        errorLabel.BackgroundTransparency = 1
        errorLabel.Text = message
        errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        errorLabel.TextScaled = true
        errorLabel.Font = Enum.Font.SourceSansBold
        errorLabel.Parent = errorFrame
        
        Debris:AddItem(errorGui, 3)
        return
    end
    
    -- Check if player has seed
    local playerSeeds = _G.SeedSystem.getPlayerSeeds(player)
    if not playerSeeds[seedType] or playerSeeds[seedType] <= 0 then
        print("Player doesn't have " .. seedType .. " seeds")
        return
    end
    
    -- Remove seed from inventory
    if _G.SeedSystem.removeSeeds(player, seedType, 1) then
        -- Create growing tree
        local tree = createGrowingTree(player, seedType, position)
        if tree then
            print("🌱 Successfully planted " .. seedType .. " for " .. player.Name)
        else
            -- Refund seed if planting failed
            _G.SeedSystem.addSeeds(player, seedType, 1)
            print("Failed to plant tree, refunded seed")
        end
    end
end)

-- NOTE: Fruit growth (size, animation, reveal) is handled by PlotBananaGrowth.luau only.
-- This script only manages tree growth and triggers fruit spawning when trees are fully grown.
-- Do not add fruit growth logic here; keep all fruit animation in PlotBananaGrowth for consistency.

print("🌳 Seed Growth System Loaded!")
print("   - " .. #GROWTH_STAGES .. " growth stages")
print("   - " .. table.maxn(TREE_MODELS) .. " tree types supported")
print("   - Realistic part-by-part growth")
print("   - Growth particles and sounds")

-- DEPRECATED: Farming/seed logic removed for city/empire game.
return