-- GildrainSeed.luau - Special Gildrain Seed System
-- Creates legendary+ tier plants with 90% gold / 10% rainbow variants
-- Only produces legendary, mythical, celestial, ascended, godly, or transcendent fruits

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- Wait for required systems
repeat task.wait() until _G.PlotSystem
repeat task.wait() until _G.SeedSystem

-- Configuration
local GILDRAIN_SEED_CONFIG = {
    id = "gildrain_seed",
    name = "Gildrain Seed",
    rarity = "Gamepass",
    growthTime = 600, -- 10 minutes
    modelName = "GildrainTree",
    gamepassId = nil -- You'll set this to your actual gamepass ID
}

-- Rarity tiers for Gildrain fruits (legendary and above only)
local GILDRAIN_RARITIES = {
    {name = "Legendary", weight = 40, value = 5000},
    {name = "Mythical", weight = 30, value = 15000},
    {name = "Celestial", weight = 15, value = 50000},
    {name = "Ascended", weight = 10, value = 150000},
    {name = "Godly", weight = 4, value = 500000},
    {name = "Transcendent", weight = 1, value = 2000000}
}

-- Color variants (90% gold, 10% rainbow)
local COLOR_VARIANTS = {
    {name = "Gold", chance = 90, colorValue = Color3.fromRGB(255, 215, 0)},
    {name = "Rainbow", chance = 10, colorValue = nil} -- Rainbow handled separately
}

-- Active Gildrain trees
local activeGildrainTrees = {}

-- Rainbow color cycling
local rainbowColors = {
    Color3.fromRGB(255, 0, 0),   -- Red
    Color3.fromRGB(255, 165, 0), -- Orange
    Color3.fromRGB(255, 255, 0), -- Yellow
    Color3.fromRGB(0, 255, 0),   -- Green
    Color3.fromRGB(0, 255, 255), -- Cyan
    Color3.fromRGB(0, 0, 255),   -- Blue
    Color3.fromRGB(128, 0, 128)  -- Purple
}

-- Get player's plot
local function getPlayerPlot(player)
    if _G.PlotSystem and _G.PlotSystem.getPlayerPlot then
        return _G.PlotSystem.getPlayerPlot(player)
    end
    return nil
end

-- Determine color variant (90% gold, 10% rainbow)
local function determineColorVariant()
    local roll = math.random(1, 100)
    if roll <= 90 then
        return "Gold"
    else
        return "Rainbow"
    end
end

-- Select rarity based on weighted system
local function selectGildrainRarity()
    local totalWeight = 0
    for _, rarity in ipairs(GILDRAIN_RARITIES) do
        totalWeight = totalWeight + rarity.weight
    end
    
    local roll = math.random(1, totalWeight)
    local currentWeight = 0
    
    for _, rarity in ipairs(GILDRAIN_RARITIES) do
        currentWeight = currentWeight + rarity.weight
        if roll <= currentWeight then
            return rarity
        end
    end
    
    return GILDRAIN_RARITIES[1] -- Fallback to legendary
end

-- Apply gold color to all parts of a model
local function applyGoldColor(model)
    local goldColor = Color3.fromRGB(255, 215, 0)
    local goldMaterial = Enum.Material.Neon
    
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Color = goldColor
            descendant.Material = goldMaterial
            
            -- Add golden glow effect
            local pointLight = Instance.new("PointLight")
            pointLight.Color = goldColor
            pointLight.Brightness = 1
            pointLight.Range = 10
            pointLight.Parent = descendant
        end
    end
end

-- Apply rainbow color cycling to all parts of a model
local function applyRainbowColor(model)
    local rainbowParts = {}
    
    -- Collect all parts
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Material = Enum.Material.ForceField
            table.insert(rainbowParts, descendant)
            
            -- Add rainbow glow effect
            local pointLight = Instance.new("PointLight")
            pointLight.Brightness = 1.5
            pointLight.Range = 12
            pointLight.Parent = descendant
        end
    end
    
    -- Start rainbow cycling
    local colorIndex = 1
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not model.Parent then
            connection:Disconnect()
            return
        end
        
        local currentColor = rainbowColors[colorIndex]
        for _, part in ipairs(rainbowParts) do
            if part.Parent then
                part.Color = currentColor
                local light = part:FindFirstChild("PointLight")
                if light then
                    light.Color = currentColor
                end
            end
        end
        
        -- Cycle through colors every 0.1 seconds
        colorIndex = colorIndex % #rainbowColors + 1
    end)
    
    return connection
end

-- Create a Gildrain tree
local function createGildrainTree(player, position)
    local plotId = getPlayerPlot(player)
    if not plotId then return nil end
    
    local plotsFolder = Workspace:FindFirstChild("Plots")
    local plotModel = plotsFolder:FindFirstChild("Plot_" .. plotId)
    if not plotModel then return nil end
    
    -- Create the tree model
    local tree = Instance.new("Model")
    tree.Name = "GildrainTree"
    tree.Parent = plotModel
    
    -- Create tree trunk
    local trunk = Instance.new("Part")
    trunk.Name = "Trunk"
    trunk.Size = Vector3.new(3, 8, 3)
    trunk.Position = position
    trunk.Anchored = true
    trunk.Material = Enum.Material.Wood
    trunk.BrickColor = BrickColor.new("Brown")
    trunk.Parent = tree
    
    -- Create leaves
    local leaves = Instance.new("Part")
    leaves.Name = "Leaves"
    leaves.Size = Vector3.new(12, 8, 12)
    leaves.Position = position + Vector3.new(0, 8, 0)
    leaves.Anchored = true
    leaves.Material = Enum.Material.Grass
    leaves.BrickColor = BrickColor.new("Bright green")
    leaves.Shape = Enum.PartType.Ball
    leaves.Parent = tree
    
    -- Mark as tree
    local treeMarker = Instance.new("BoolValue")
    treeMarker.Name = "IsGildrainTree"
    treeMarker.Parent = tree
    
    -- Determine tree's color variant
    local colorVariant = determineColorVariant()
    
    -- Store tree data
    local treeData = {
        model = tree,
        player = player,
        colorVariant = colorVariant,
        lastFruitSpawn = tick(),
        fruitCount = 0,
        maxFruits = 15,
        spawnInterval = 30 -- 30 seconds between fruits
    }
    
    table.insert(activeGildrainTrees, treeData)
    
    -- Apply color variant to tree
    if colorVariant == "Gold" then
        applyGoldColor(tree)
        print("🌟 Created GOLD Gildrain Tree for " .. player.Name)
    else
        local rainbowConnection = applyRainbowColor(tree)
        treeData.rainbowConnection = rainbowConnection
        print("🌈 Created RAINBOW Gildrain Tree for " .. player.Name)
    end
    
    return tree
end

-- Create a Gildrain fruit
local function createGildrainFruit(treeData, position)
    local rarity = selectGildrainRarity()
    
    -- Create fruit model
    local fruit = Instance.new("Model")
    fruit.Name = "GildrainFruit_" .. rarity.name
    fruit.Parent = treeData.model
    
    -- Create fruit part
    local fruitPart = Instance.new("Part")
    fruitPart.Name = "FruitPart"
    fruitPart.Size = Vector3.new(1.5, 2, 1.5)
    fruitPart.Position = position
    fruitPart.Anchored = true
    fruitPart.Shape = Enum.PartType.Ball
    fruitPart.Parent = fruit
    
    -- Apply tree's color variant
    if treeData.colorVariant == "Gold" then
        fruitPart.Color = Color3.fromRGB(255, 215, 0)
        fruitPart.Material = Enum.Material.Neon
        
        -- Add golden glow
        local pointLight = Instance.new("PointLight")
        pointLight.Color = Color3.fromRGB(255, 215, 0)
        pointLight.Brightness = 1.5
        pointLight.Range = 8
        pointLight.Parent = fruitPart
    else
        -- Rainbow fruit
        fruitPart.Material = Enum.Material.ForceField
        
        -- Add rainbow glow
        local pointLight = Instance.new("PointLight")
        pointLight.Brightness = 2
        pointLight.Range = 10
        pointLight.Parent = fruitPart
        
        -- Start rainbow cycling for this fruit
        local colorIndex = math.random(1, #rainbowColors)
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not fruitPart.Parent then
                connection:Disconnect()
                return
            end
            
            local currentColor = rainbowColors[colorIndex]
            fruitPart.Color = currentColor
            local light = fruitPart:FindFirstChild("PointLight")
            if light then
                light.Color = currentColor
            end
            
            colorIndex = colorIndex % #rainbowColors + 1
        end)
    end
    
    -- Add rarity and value data
    local rarityValue = Instance.new("StringValue")
    rarityValue.Name = "Rarity"
    rarityValue.Value = rarity.name
    rarityValue.Parent = fruit
    
    local valueAmount = Instance.new("NumberValue")
    valueAmount.Name = "Value"
    valueAmount.Value = rarity.value
    valueAmount.Parent = fruit
    
    local colorVariantValue = Instance.new("StringValue")
    colorVariantValue.Name = "ColorVariant"
    colorVariantValue.Value = treeData.colorVariant
    colorVariantValue.Parent = fruit
    
    -- Add harvest detection
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 50
    clickDetector.Parent = fruitPart
    
    clickDetector.MouseClick:Connect(function(player)
        if player == treeData.player then
            harvestGildrainFruit(fruit, player, rarity, treeData.colorVariant)
        end
    end)
    
    -- Auto-despawn after 5 minutes if not harvested
    game:GetService("Debris"):AddItem(fruit, 300)
    
    return fruit
end

-- Harvest a Gildrain fruit
function harvestGildrainFruit(fruit, player, rarity, colorVariant)
    -- Add coins to player
    if _G.CoinSystem and _G.CoinSystem.addCoins then
        local baseValue = fruit:FindFirstChild("Value")
        if baseValue then
            local bonusMultiplier = colorVariant == "Rainbow" and 2 or 1.5 -- Rainbow gets 2x, Gold gets 1.5x
            local finalValue = math.floor(baseValue.Value * bonusMultiplier)
            
            _G.CoinSystem.addCoins(player, finalValue)
            
            -- Create floating text effect
            local gui = Instance.new("BillboardGui")
            gui.Size = UDim2.new(0, 200, 0, 50)
            gui.StudsOffset = Vector3.new(0, 3, 0)
            gui.Parent = fruit:FindFirstChild("FruitPart")
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "+" .. finalValue .. " coins"
            label.TextColor3 = colorVariant == "Rainbow" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 215, 0)
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = gui
            
            -- Animate floating text
            local tween = TweenService:Create(gui, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                StudsOffset = Vector3.new(0, 8, 0)
            })
            local fadeTween = TweenService:Create(label, TweenInfo.new(2, Enum.EasingStyle.Quad), {
                TextTransparency = 1
            })
            
            tween:Play()
            fadeTween:Play()
            
            game:GetService("Debris"):AddItem(gui, 2)
        end
    end
    
    print("🌟 " .. player.Name .. " harvested " .. colorVariant .. " " .. rarity.name .. " Gildrain Fruit!")
    fruit:Destroy()
end

-- Spawn fruits on Gildrain trees
local function updateGildrainTrees()
    for i = #activeGildrainTrees, 1, -1 do
        local treeData = activeGildrainTrees[i]
        
        -- Check if tree still exists
        if not treeData.model.Parent then
            if treeData.rainbowConnection then
                treeData.rainbowConnection:Disconnect()
            end
            table.remove(activeGildrainTrees, i)
        else
            -- Check if it's time to spawn a fruit
            local currentTime = tick()
            if currentTime - treeData.lastFruitSpawn >= treeData.spawnInterval and treeData.fruitCount < treeData.maxFruits then
                -- Find a random position around the leaves
                local leaves = treeData.model:FindFirstChild("Leaves")
                if leaves then
                    local randomOffset = Vector3.new(
                        math.random(-4, 4),
                        math.random(-2, 2),
                        math.random(-4, 4)
                    )
                    local fruitPosition = leaves.Position + randomOffset
                    
                    createGildrainFruit(treeData, fruitPosition)
                    treeData.lastFruitSpawn = currentTime
                    treeData.fruitCount = treeData.fruitCount + 1
                end
            end
        end
    end
end

-- Plant Gildrain seed function
local function plantGildrainSeed(player, position)
    -- Validate planting position (you can implement this based on your plot system)
    local plotId = getPlayerPlot(player)
    if not plotId then
        return false, "No plot assigned"
    end
    
    -- Check if player has Gildrain seed (this will be implemented later)
    -- For now, we'll assume they do
    
    -- Create the tree
    local tree = createGildrainTree(player, position)
    if tree then
        print("🌱 " .. player.Name .. " planted a Gildrain Seed!")
        return true, "Gildrain seed planted successfully!"
    else
        return false, "Failed to plant Gildrain seed"
    end
end

-- Main update loop
RunService.Heartbeat:Connect(function()
    updateGildrainTrees()
end)

-- Global access
_G.GildrainSeed = {
    plantSeed = plantGildrainSeed,
    createTree = createGildrainTree,
    harvestFruit = harvestGildrainFruit,
    RARITIES = GILDRAIN_RARITIES,
    CONFIG = GILDRAIN_SEED_CONFIG
}

print("🌟 Gildrain Seed System initialized!")
print("🎮 Gamepass Item: Special seed available through gamepass purchase")
print("📊 Rarities: Legendary (40%), Mythical (30%), Celestial (15%), Ascended (10%), Godly (4%), Transcendent (1%)")
print("🎨 Colors: Gold (90%), Rainbow (10%)")

-- DEPRECATED: Farming/seed logic removed for city/empire game.
return
