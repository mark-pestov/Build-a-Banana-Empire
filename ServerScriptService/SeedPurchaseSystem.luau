-- SeedPurchaseSystem.luau - Vendor Shop Integration for Seeds
-- Handles seed purchases from vendor NPCs and shops

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Wait for SeedSystem to load
repeat wait() until _G.SeedSystem

-- Get seed types from SeedSystem
local SEED_TYPES = _G.SeedSystem.getSeedTypes()

-- Wait for coin system (assuming you have one)
repeat wait() until _G.CoinSystem or _G.LeaderStats

-- Configuration
local VENDOR_NPCS = {
    "SeedVendor",
    "FarmShop", 
    "SeedMerchant"
}

-- Create RemoteEvents
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")

local purchaseSeedRemote = remoteEventsFolder:FindFirstChild("PurchaseSeed")
if not purchaseSeedRemote then
    purchaseSeedRemote = Instance.new("RemoteEvent")
    purchaseSeedRemote.Name = "PurchaseSeed"
    purchaseSeedRemote.Parent = remoteEventsFolder
end

local openSeedShopRemote = remoteEventsFolder:FindFirstChild("OpenSeedShop")
if not openSeedShopRemote then
    openSeedShopRemote = Instance.new("RemoteEvent")
    openSeedShopRemote.Name = "OpenSeedShop"
    openSeedShopRemote.Parent = remoteEventsFolder
end

-- Create seed shop GUI in ReplicatedStorage
local function createSeedShopGui()
    local gui = ReplicatedStorage:FindFirstChild("SeedShopGUI")
    if gui then gui:Destroy() end
    
    gui = Instance.new("ScreenGui")
    gui.Name = "SeedShopGUI"
    gui.ResetOnSpawn = false
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    mainFrame.Visible = false
    mainFrame.Parent = gui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "🌱 SEED SHOP"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = mainFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = mainFrame
    
    -- Coins display
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(0, 150, 0, 30)
    coinsLabel.Position = UDim2.new(0, 10, 0, 50)
    coinsLabel.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    coinsLabel.BorderSizePixel = 1
    coinsLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
    coinsLabel.Text = "💰 Coins: 0"
    coinsLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    coinsLabel.TextScaled = true
    coinsLabel.Font = Enum.Font.SourceSansBold
    coinsLabel.Parent = mainFrame
    
    -- Scroll frame for seeds
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "SeedScrollFrame" 
    scrollFrame.Size = UDim2.new(1, -20, 1, -100)
    scrollFrame.Position = UDim2.new(0, 10, 0, 90)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    scrollFrame.BorderSizePixel = 1
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = mainFrame
    
    -- Grid layout for seeds
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 120, 0, 150)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.Parent = scrollFrame
    
    -- Create seed items
    local ySize = 0
    for seedType, seedInfo in pairs(SEED_TYPES) do
        local seedFrame = Instance.new("Frame")
        seedFrame.Name = seedType .. "Frame"
        seedFrame.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        seedFrame.BorderSizePixel = 2
        
        -- Set border color based on rarity
        if seedInfo.rarity == "Common" then
            seedFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
        elseif seedInfo.rarity == "Rare" then
            seedFrame.BorderColor3 = Color3.fromRGB(0, 0, 255)
        elseif seedInfo.rarity == "Epic" then
            seedFrame.BorderColor3 = Color3.fromRGB(128, 0, 128)
        elseif seedInfo.rarity == "Mythical" then
            seedFrame.BorderColor3 = Color3.fromRGB(255, 165, 0)
        end
        
        seedFrame.Parent = scrollFrame
        
        -- Seed icon
        local seedIcon = Instance.new("Frame")
        seedIcon.Size = UDim2.new(0, 40, 0, 40)
        seedIcon.Position = UDim2.new(0.5, -20, 0, 10)
        seedIcon.BackgroundColor3 = seedFrame.BorderColor3
        seedIcon.Parent = seedFrame
        
        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 20)
        iconCorner.Parent = seedIcon
        
        -- Seed name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -10, 0, 25)
        nameLabel.Position = UDim2.new(0, 5, 0, 55)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = seedInfo.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSans
        nameLabel.Parent = seedFrame
        
        -- Price label
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(1, -10, 0, 20)
        priceLabel.Position = UDim2.new(0, 5, 0, 80)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = "💰 " .. seedInfo.price
        priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        priceLabel.TextScaled = true
        priceLabel.Font = Enum.Font.SourceSansBold
        priceLabel.Parent = seedFrame
        
        -- Purchase button
        local purchaseButton = Instance.new("TextButton")
        purchaseButton.Name = "PurchaseButton"
        purchaseButton.Size = UDim2.new(1, -10, 0, 25)
        purchaseButton.Position = UDim2.new(0, 5, 1, -30)
        purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        purchaseButton.Text = "BUY 1"
        purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        purchaseButton.TextScaled = true
        purchaseButton.Font = Enum.Font.SourceSansBold
        purchaseButton.Parent = seedFrame
        
        -- Store seed type in button for reference
        local seedTypeValue = Instance.new("StringValue")
        seedTypeValue.Name = "SeedType"
        seedTypeValue.Value = seedType
        seedTypeValue.Parent = purchaseButton
        
        ySize = ySize + 160
    end
    
    -- Update scroll frame canvas size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, ySize)
    
    gui.Parent = ReplicatedStorage
    return gui
end

-- Get player's coin count
local function getPlayerCoins(player)
    -- Integration with your existing coin system
    if _G.CoinSystem and _G.CoinSystem.getCoins then
        return _G.CoinSystem.getCoins(player)
    elseif player.leaderstats and player.leaderstats:FindFirstChild("Coins") then
        return player.leaderstats.Coins.Value
    end
    return 0
end

-- Deduct coins from player
local function deductPlayerCoins(player, amount)
    if _G.CoinSystem and _G.CoinSystem.deductCoins then
        return _G.CoinSystem.deductCoins(player, amount)
    elseif player.leaderstats and player.leaderstats:FindFirstChild("Coins") then
        if player.leaderstats.Coins.Value >= amount then
            player.leaderstats.Coins.Value = player.leaderstats.Coins.Value - amount
            return true
        end
    end
    return false
end

-- Handle seed purchase
purchaseSeedRemote.OnServerEvent:Connect(function(player, seedType, quantity)
    quantity = quantity or 1
    local seedInfo = SEED_TYPES[seedType]
    
    if not seedInfo then
        warn("Invalid seed type: " .. tostring(seedType))
        return
    end
    
    local totalCost = seedInfo.price * quantity
    local playerCoins = getPlayerCoins(player)
    
    if playerCoins >= totalCost then
        -- Deduct coins
        if deductPlayerCoins(player, totalCost) then
            -- Add seeds to player inventory
            if _G.SeedSystem.addSeeds(player, seedType, quantity) then
                print(player.Name .. " purchased " .. quantity .. " " .. seedInfo.name .. "(s) for " .. totalCost .. " coins")
                
                -- Send success message to client
                openSeedShopRemote:FireClient(player, "purchase_success", {
                    seedType = seedType,
                    quantity = quantity,
                    cost = totalCost
                })
            else
                -- Refund if seed addition failed
                if _G.CoinSystem and _G.CoinSystem.addCoins then
                    _G.CoinSystem.addCoins(player, totalCost)
                elseif player.leaderstats and player.leaderstats:FindFirstChild("Coins") then
                    player.leaderstats.Coins.Value = player.leaderstats.Coins.Value + totalCost
                end
                
                openSeedShopRemote:FireClient(player, "purchase_failed", "Failed to add seeds to inventory")
            end
        else
            openSeedShopRemote:FireClient(player, "purchase_failed", "Failed to deduct coins")
        end
    else
        openSeedShopRemote:FireClient(player, "purchase_failed", "Not enough coins! Need " .. totalCost .. " coins.")
    end
end)

-- Handle shop opening
openSeedShopRemote.OnServerEvent:Connect(function(player, action, data)
    if action == "open_shop" then
        local playerCoins = getPlayerCoins(player)
        openSeedShopRemote:FireClient(player, "update_coins", playerCoins)
    end
end)

-- Set up vendor NPCs
local function setupVendorNPCs()
    for _, npcName in ipairs(VENDOR_NPCS) do
        local npc = workspace:FindFirstChild(npcName)
        if npc then
            -- Add ClickDetector if it doesn't exist
            local clickDetector = npc:FindFirstChild("ClickDetector")
            if not clickDetector then
                clickDetector = Instance.new("ClickDetector")
                clickDetector.MaxActivationDistance = 15
                clickDetector.Parent = npc
            end
            
            -- Connect click event
            clickDetector.MouseClick:Connect(function(player)
                openSeedShopRemote:FireClient(player, "open_shop")
            end)
            
            print("Set up seed vendor: " .. npcName)
        end
    end
end

-- Initialize system
local function initialize()
    createSeedShopGui()
    setupVendorNPCs()
    
    -- Set up existing players
    for _, player in pairs(Players:GetPlayers()) do
        -- Give them the shop GUI
        local gui = ReplicatedStorage:FindFirstChild("SeedShopGUI")
        if gui then
            local playerGui = gui:Clone()
            playerGui.Parent = player.PlayerGui
        end
    end
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
    -- Give them the shop GUI
    player.CharacterAdded:Connect(function()
        wait(1) -- Wait for character to fully load
        local gui = ReplicatedStorage:FindFirstChild("SeedShopGUI")
        if gui then
            local playerGui = gui:Clone()
            playerGui.Parent = player.PlayerGui
        end
    end)
end)

-- Initialize system
wait(2) -- Wait for other systems to load
initialize()

print("🛒 Seed Purchase System Loaded!")
print("   - Shop GUI created")
print("   - " .. #VENDOR_NPCS .. " vendor NPCs configured")
print("   - Integration with coin system ready")

-- DEPRECATED: Farming/seed logic removed for city/empire game.
return