-- SeedSystem.luau - Core Seed Management System
-- Handles seed inventories, player hotbars, and seed management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")

-- Configuration
local SEED_TYPES = {
    ["Banapple"] = {
        id = "banapple_seed",
        name = "Banapple Seed",
        rarity = "Common",
        price = 100,
        modelName = "BanappleTree",
        growthTime = 30
    },
    ["Golden Banapple"] = {
        id = "golden_banapple_seed",
        name = "Golden Banapple Seed",
        rarity = "Rare",
        price = 500,
        modelName = "GoldenBanappleTree",
        growthTime = 60
    },
    ["Diamond Banapple"] = {
        id = "diamond_banapple_seed",
        name = "Diamond Banapple Seed",
        rarity = "Epic",
        price = 2000,
        modelName = "DiamondBanappleTree",
        growthTime = 120
    },
    ["Mythical Banapple"] = {
        id = "mythical_banapple_seed",
        name = "Mythical Banapple Seed",
        rarity = "Mythical",
        price = 10000,
        modelName = "MythicalBanappleTree",
        growthTime = 300
    }
}

-- DataStore for player inventories
local seedDataStore = DataStoreService:GetDataStore("PlayerSeedInventory")

-- Player data storage
local playerSeedData = {}

-- Inversion state for admin commands
local inversionActive = false
local originalPrices = {}

-- Store original prices for inversion
for seedName, seedData in pairs(SEED_TYPES) do
	originalPrices[seedName] = seedData.price
end

-- Create RemoteEvents folder
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
    remoteEventsFolder = Instance.new("Folder")
    remoteEventsFolder.Name = "RemoteEvents"
    remoteEventsFolder.Parent = ReplicatedStorage
end

-- Create RemoteEvents
local remoteEvents = {}
local eventNames = {
    "UpdateHotbar",
    "PlantSeed", 
    "RemovePlant",
    "PurchaseSeed",
    "EquipSeed",
    "UnequipSeed"
}

for _, eventName in ipairs(eventNames) do
    local remoteEvent = remoteEventsFolder:FindFirstChild(eventName)
    if not remoteEvent then
        remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = remoteEventsFolder
    end
    remoteEvents[eventName] = remoteEvent
end

-- Create seed tools folder in ServerStorage
local seedToolsFolder = ServerStorage:FindFirstChild("SeedTools")
if not seedToolsFolder then
    seedToolsFolder = Instance.new("Folder")
    seedToolsFolder.Name = "SeedTools"
    seedToolsFolder.Parent = ServerStorage
end

-- Create trowel tool
local function createTrowelTool()
    local trowel = Instance.new("Tool")
    trowel.Name = "Trowel"
    trowel.RequiresHandle = true
    trowel.CanBeDropped = false
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.2, 3, 0.2)
    handle.Material = Enum.Material.Wood
    handle.BrickColor = BrickColor.new("Brown")
    handle.Parent = trowel
    
    -- Add mesh for better appearance
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxasset://fonts/sword.mesh"
    mesh.Scale = Vector3.new(0.5, 0.5, 0.5)
    mesh.Parent = handle
    
    local script = Instance.new("LocalScript")
    script.Name = "TrowelScript"
    script.Source = [[
        local tool = script.Parent
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        
        local player = Players.LocalPlayer
        local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
        local removePlantRemote = remoteEvents:WaitForChild("RemovePlant")
        
        tool.Activated:Connect(function()
            local mouse = player:GetMouse()
            local target = mouse.Target
            
            if target and target.Parent:FindFirstChild("PlantType") then
                removePlantRemote:FireServer(target.Parent)
            end
        end)
    ]]
    script.Parent = trowel
    
    return trowel
end

-- Create seed tool template
local function createSeedTool(seedType)
    local seedInfo = SEED_TYPES[seedType]
    if not seedInfo then return nil end
    
    local tool = Instance.new("Tool")
    tool.Name = seedInfo.name
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    
    -- Create handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.5, 0.5, 0.5)
    handle.Material = Enum.Material.Neon
    handle.Shape = Enum.PartType.Ball
    
    -- Set color based on rarity
    if seedInfo.rarity == "Common" then
        handle.BrickColor = BrickColor.new("Bright green")
    elseif seedInfo.rarity == "Rare" then
        handle.BrickColor = BrickColor.new("Bright blue")
    elseif seedInfo.rarity == "Epic" then
        handle.BrickColor = BrickColor.new("Bright violet")
    elseif seedInfo.rarity == "Mythical" then
        handle.BrickColor = BrickColor.new("Bright orange")
    end
    
    handle.Parent = tool
    
    -- Add StringValue to identify seed type
    local seedTypeValue = Instance.new("StringValue")
    seedTypeValue.Name = "SeedType"
    seedTypeValue.Value = seedType
    seedTypeValue.Parent = tool
    
    -- Add LocalScript for planting
    local script = Instance.new("LocalScript")
    script.Name = "SeedPlantingScript"
    script.Source = [[
        local tool = script.Parent
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        
        local player = Players.LocalPlayer
        local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
        local plantSeedRemote = remoteEvents:WaitForChild("PlantSeed")
        
        local seedType = tool:WaitForChild("SeedType").Value
        
        tool.Activated:Connect(function()
            local mouse = player:GetMouse()
            local target = mouse.Target
            
            if target and target.Name == "DirtPatch" then
                local position = mouse.Hit.Position
                plantSeedRemote:FireServer(seedType, position)
            end
        end)
    ]]
    script.Parent = tool
    
    return tool
end

-- Create all seed tools
local function createAllSeedTools()
    for seedType, _ in pairs(SEED_TYPES) do
        local tool = createSeedTool(seedType)
        if tool then
            tool.Parent = seedToolsFolder
        end
    end
    
    -- Create trowel
    local trowel = createTrowelTool()
    trowel.Parent = seedToolsFolder
end

-- Initialize player data
local function initializePlayerData(player)
    local success, data = pcall(function()
        return seedDataStore:GetAsync(player.UserId)
    end)
    
    if success and data then
        playerSeedData[player.UserId] = data
    else
        playerSeedData[player.UserId] = {
            seeds = {},
            equippedSeed = nil
        }
    end
    
    -- Give player trowel
    local trowel = seedToolsFolder:FindFirstChild("Trowel")
    if trowel then
        local playerTrowel = trowel:Clone()
        playerTrowel.Parent = player.Backpack
    end
    
    -- Update player's hotbar
    updatePlayerHotbar(player)
end

-- Save player data
local function savePlayerData(player)
    local success, errorMessage = pcall(function()
        seedDataStore:SetAsync(player.UserId, playerSeedData[player.UserId])
    end)
    
    if not success then
        warn("Failed to save data for " .. player.Name .. ": " .. errorMessage)
    end
end

-- Update player's hotbar with seeds
function updatePlayerHotbar(player)
    local data = playerSeedData[player.UserId]
    if not data then return end
    
    -- Remove existing seed tools
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("SeedType") then
            tool:Destroy()
        end
    end
    
    -- Add seed tools for seeds player owns
    for seedType, count in pairs(data.seeds) do
        if count > 0 then
            local tool = seedToolsFolder:FindFirstChild(SEED_TYPES[seedType].name)
            if tool then
                local playerTool = tool:Clone()
                
                -- Add count display
                local countGui = Instance.new("ScreenGui")
                countGui.Name = "SeedCount"
                
                local countLabel = Instance.new("TextLabel")
                countLabel.Size = UDim2.new(0, 50, 0, 20)
                countLabel.Position = UDim2.new(1, -55, 1, -25)
                countLabel.BackgroundTransparency = 1
                countLabel.Text = tostring(count)
                countLabel.TextColor3 = Color3.new(1, 1, 1)
                countLabel.TextStrokeTransparency = 0
                countLabel.TextScaled = true
                countLabel.Font = Enum.Font.SourceSansBold
                countLabel.Parent = countGui
                
                countGui.Parent = playerTool
                playerTool.Parent = player.Backpack
            end
        end
    end
    
    -- Fire remote to update client
    remoteEvents.UpdateHotbar:FireClient(player, data.seeds)
end

-- Add seeds to player inventory
local function addSeedsToPlayer(player, seedType, amount)
    local data = playerSeedData[player.UserId]
    if not data then return false end
    
    data.seeds[seedType] = (data.seeds[seedType] or 0) + amount
    updatePlayerHotbar(player)
    savePlayerData(player)
    
    return true
end

-- Remove seeds from player inventory
local function removeSeedsFromPlayer(player, seedType, amount)
    local data = playerSeedData[player.UserId]
    if not data then return false end
    
    local currentAmount = data.seeds[seedType] or 0
    if currentAmount < amount then return false end
    
    data.seeds[seedType] = currentAmount - amount
    updatePlayerHotbar(player)
    savePlayerData(player)
    
    return true
end

-- Handle seed purchase
remoteEvents.PurchaseSeed.OnServerEvent:Connect(function(player, seedType, amount)
    local seedInfo = SEED_TYPES[seedType]
    if not seedInfo then return end
    
    local totalCost = seedInfo.price * amount
    
    -- Check if player has enough coins (assuming you have a coin system)
    -- You'll need to integrate this with your existing coin system
    local hasEnoughCoins = true -- Replace with actual coin check
    
    if hasEnoughCoins then
        -- Deduct coins (implement your coin deduction here)
        -- DeductCoins(player, totalCost)
        
        -- Add seeds to inventory
        addSeedsToPlayer(player, seedType, amount)
        
        print(player.Name .. " purchased " .. amount .. " " .. seedInfo.name .. "(s)")
    end
end)

-- Player joined
Players.PlayerAdded:Connect(function(player)
    initializePlayerData(player)
end)

-- Player leaving
Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    playerSeedData[player.UserId] = nil
end)

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
    initializePlayerData(player)
end

-- Create seed tools on startup
createAllSeedTools()

-- Auto-save every 5 minutes
spawn(function()
    while true do
        wait(300) -- 5 minutes
        for userId, data in pairs(playerSeedData) do
            local player = Players:GetPlayerByUserId(userId)
            if player then
                savePlayerData(player)
            end
        end
    end
end)

-- Add inversion functions for admin commands
function SeedSystem.invertPrices()
	inversionActive = true
	
	-- Expensive seeds become cheap, cheap seeds become expensive
	local priceValues = {}
	for _, seedData in pairs(SEED_TYPES) do
		table.insert(priceValues, seedData.price)
	end
	table.sort(priceValues)
	
	local i = 1
	for seedName, seedData in pairs(SEED_TYPES) do
		-- Reverse the price order
		seedData.price = -priceValues[#priceValues - i + 1] -- Negative to give money
		i = i + 1
	end
	
	print("🔄 SeedSystem: Prices inverted - buying seeds now gives money!")
end

function SeedSystem.revertPrices()
	inversionActive = false
	
	-- Restore original prices
	for seedName, seedData in pairs(SEED_TYPES) do
		seedData.price = originalPrices[seedName]
	end
	
	print("✅ SeedSystem: Prices restored to normal")
end

-- Global functions for other scripts
_G.SeedSystem = {
    addSeeds = addSeedsToPlayer,
    removeSeeds = removeSeedsFromPlayer,
    getPlayerSeeds = function(player)
        return playerSeedData[player.UserId] and playerSeedData[player.UserId].seeds or {}
    end,
    getSeedTypes = function()
        return SEED_TYPES
    end
}

print("🌱 Seed System Loaded Successfully!")
print("   - Hotbar inventory system")
print("   - " .. #eventNames .. " remote events created")
print("   - " .. (table.maxn(SEED_TYPES) + 1) .. " tools created") -- +1 for trowel

-- DEPRECATED: Farming/seed logic removed for city/empire game.
return