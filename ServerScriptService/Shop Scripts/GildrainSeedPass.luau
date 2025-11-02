-- Gildrain Building Pass (formerly GildrainSeedPass)
-- Unlocks a rare gilded building for your banana city

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- DataStore for player Gildrain seed inventories
local gildrainSeedDataStore = DataStoreService:GetDataStore("PlayerGildrainSeeds")

-- Gamepass Configuration
local GILDRAIN_GAMEPASSES = {
    {
        id = nil, -- Set your actual gamepass ID here (1 seed)
        seeds = 1
    },
    {
        id = nil, -- Set your actual gamepass ID here (3 seeds)
        seeds = 3
    },
    {
        id = nil, -- Set your actual gamepass ID here (10 seeds)
        seeds = 10
    }
}

-- Player data cache
local playerGildrainSeeds = {}

-- Load player's Gildrain seed count
local function loadPlayerSeeds(player)
    local success, data = pcall(function()
        return gildrainSeedDataStore:GetAsync(player.UserId)
    end)
    
    if success and data then
        playerGildrainSeeds[player.UserId] = data.seeds or 0
    else
        playerGildrainSeeds[player.UserId] = 0
    end
    
    print("🌱 Loaded", playerGildrainSeeds[player.UserId], "Gildrain Seeds for", player.Name)
end

-- Save player's Gildrain seed count
local function savePlayerSeeds(player)
    if not playerGildrainSeeds[player.UserId] then return end
    
    local success, error = pcall(function()
        gildrainSeedDataStore:SetAsync(player.UserId, {
            seeds = playerGildrainSeeds[player.UserId]
        })
    end)
    
    if not success then
        warn("Failed to save Gildrain seeds for " .. player.Name .. ": " .. tostring(error))
    end
end

-- Add seeds to player's inventory
local function addGildrainSeeds(player, amount)
    if not playerGildrainSeeds[player.UserId] then
        playerGildrainSeeds[player.UserId] = 0
    end
    
    playerGildrainSeeds[player.UserId] = playerGildrainSeeds[player.UserId] + amount
    savePlayerSeeds(player)
    
    print("🌟 Added", amount, "Gildrain Seeds to", player.Name, "- Total:", playerGildrainSeeds[player.UserId])
    
    -- Update GUI if it exists
    updatePlayerGUI(player)
end

-- Remove seeds from player's inventory (when planting)
local function removeGildrainSeeds(player, amount)
    if not playerGildrainSeeds[player.UserId] then
        return false
    end
    
    if playerGildrainSeeds[player.UserId] >= amount then
        playerGildrainSeeds[player.UserId] = playerGildrainSeeds[player.UserId] - amount
        savePlayerSeeds(player)
        updatePlayerGUI(player)
        return true
    end
    
    return false
end

-- Get player's seed count
local function getPlayerSeedCount(player)
    return playerGildrainSeeds[player.UserId] or 0
end

-- Update player's GUI with current seed count
local function updatePlayerGUI(player)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Update seed count in existing ShopGui
    local shopGui = playerGui:FindFirstChild("ShopGui")
    if shopGui then
        -- You can customize this to match your existing GUI structure
        local seedCountLabel = shopGui:FindFirstDescendant("GildrainSeedCount")
        if seedCountLabel and seedCountLabel:IsA("TextLabel") then
            seedCountLabel.Text = "Gildrain Seeds: " .. getPlayerSeedCount(player)
        end
    end
end

-- Handle gamepass purchases
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if not wasPurchased then return end
    
    -- Simple gamepass ID to seeds mapping
    local seedsToGive = 0
    local seedText = ""
    
    -- Check which gamepass was purchased
    for i, gamepassData in ipairs(GILDRAIN_GAMEPASSES) do
        if gamepassData.id == gamepassId then
            seedsToGive = gamepassData.seeds
            if seedsToGive == 1 then
                seedText = "1 Gildrain Seed"
            else
                seedText = seedsToGive .. " Gildrain Seeds"
            end
            break
        end
    end
    
    if seedsToGive > 0 then
        -- Give seeds to player
        addGildrainSeeds(player, seedsToGive)
        
        -- Send notification to player
        StarterGui:SetCore("SendNotification", {
            Title = "🌟 Purchase Successful!";
            Text = "You received " .. seedText .. "!";
            Duration = 5;
        })
        
        -- Announce in chat to all players
        local chatMessage = player.Name .. " bought " .. seedText .. "! Congrats! 🌟"
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            local chatGui = otherPlayer:FindFirstChild("PlayerGui")
            if chatGui then
                -- Send system message to chat
                game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                    Text = chatMessage;
                    Color = Color3.fromRGB(255, 215, 0); -- Gold color
                    Font = Enum.Font.GothamBold;
                    FontSize = Enum.FontSize.Size18;
                })
            end
        end
        
        print("🎉 " .. player.Name .. " purchased " .. seedText)
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Player joining
local function onPlayerAdded(player)
    wait(2) -- Wait for player to load
    loadPlayerSeeds(player)
end

-- Player leaving
local function onPlayerRemoving(player)
    savePlayerSeeds(player)
    playerGildrainSeeds[player.UserId] = nil
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        onPlayerAdded(player)
    end)
end

-- Global access
_G.GildrainSeedShop = {
    -- Simple functions
    addSeeds = addGildrainSeeds,
    removeSeeds = removeGildrainSeeds,
    getSeedCount = getPlayerSeedCount,
    updateGUI = updatePlayerGUI,
    
    -- Easy purchase function - just pass the gamepass ID
    promptPurchase = function(player, gamepassId)
        MarketplaceService:PromptGamePassPurchase(player, gamepassId)
    end,
    
    -- Manual seed giving (for testing or admin commands)
    giveSeeds = function(player, amount)
        addGildrainSeeds(player, amount)
        local seedText = amount == 1 and "1 Gildrain Seed" or amount .. " Gildrain Seeds"
        
        -- Announce in chat
        local chatMessage = player.Name .. " received " .. seedText .. "! 🌟"
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = chatMessage;
            Color = Color3.fromRGB(255, 215, 0);
            Font = Enum.Font.GothamBold;
            FontSize = Enum.FontSize.Size18;
        })
    end,
    
    GAMEPASSES = GILDRAIN_GAMEPASSES
}

print("🛒 Gildrain Seed Shop System initialized!")
print("💰 Available gamepasses: 1 seed, 3 seeds, 10 seeds")
print("� Remember to set the actual gamepass IDs in GILDRAIN_GAMEPASSES!")