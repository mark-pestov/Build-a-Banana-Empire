-- PlayerTitleSystem.luau - Server-side title management
-- Place in ServerScriptService
-- Manages player titles and handles client requests

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Create RemoteEvents if they don't exist
local updateTitleRemote = ReplicatedStorage:FindFirstChild("UpdateTitleRemote")
if not updateTitleRemote then
    updateTitleRemote = Instance.new("RemoteEvent")
    updateTitleRemote.Name = "UpdateTitleRemote"
    updateTitleRemote.Parent = ReplicatedStorage
end

local getTitleDataRemote = ReplicatedStorage:FindFirstChild("GetTitleDataRemote")
if not getTitleDataRemote then
    getTitleDataRemote = Instance.new("RemoteFunction")
    getTitleDataRemote.Name = "GetTitleDataRemote"
    getTitleDataRemote.Parent = ReplicatedStorage
end

local settingsChangedRemote = ReplicatedStorage:FindFirstChild("SettingsChanged")
if not settingsChangedRemote then
    settingsChangedRemote = Instance.new("RemoteEvent")
    settingsChangedRemote.Name = "SettingsChanged"
    settingsChangedRemote.Parent = ReplicatedStorage
end

-- Data stores
local titleDataStore = DataStoreService:GetDataStore("PlayerTitles")
local settingsDataStore = DataStoreService:GetDataStore("PlayerSettings")

-- Player data storage
local playerTitleData = {}

-- Available titles (can be expanded based on achievements)
local AvailableTitles = {
    "None",
    "Banana Farmer",
    "Fruit Master",
    "Seed Collector",
    "Harvest King",
    "Banana Baron",
    "Fruit Tycoon",
    "Plantation Owner",
    "Banana Mogul",
    "Golden Farmer",
    "Legendary Grower",
    "Fruit Ninja",
    "Banana Warrior",
    "Pest Destroyer",
    "Weather Master",
    "Plot Perfect",
    "Speed Harvester",
    "Coin Collector",
    "VIP Player",
    "Beta Tester",
    "Community Member",
    "Banana Enthusiast"
}

-- Default title colors
local DefaultTitleColors = {
    ["None"] = Color3.fromRGB(255, 255, 255),
    ["Banana Farmer"] = Color3.fromRGB(255, 215, 0),
    ["Fruit Master"] = Color3.fromRGB(255, 165, 0),
    ["Seed Collector"] = Color3.fromRGB(50, 205, 50),
    ["Harvest King"] = Color3.fromRGB(255, 215, 0),
    ["Banana Baron"] = Color3.fromRGB(255, 215, 0),
    ["Fruit Tycoon"] = Color3.fromRGB(255, 165, 0),
    ["Plantation Owner"] = Color3.fromRGB(139, 69, 19),
    ["Banana Mogul"] = Color3.fromRGB(255, 215, 0),
    ["Golden Farmer"] = Color3.fromRGB(255, 215, 0),
    ["Legendary Grower"] = Color3.fromRGB(255, 0, 255),
    ["Fruit Ninja"] = Color3.fromRGB(255, 0, 0),
    ["Banana Warrior"] = Color3.fromRGB(255, 69, 0),
    ["Pest Destroyer"] = Color3.fromRGB(255, 0, 0),
    ["Weather Master"] = Color3.fromRGB(0, 191, 255),
    ["Plot Perfect"] = Color3.fromRGB(0, 255, 0),
    ["Speed Harvester"] = Color3.fromRGB(255, 255, 0),
    ["Coin Collector"] = Color3.fromRGB(255, 215, 0),
    ["VIP Player"] = Color3.fromRGB(255, 0, 255),
    ["Beta Tester"] = Color3.fromRGB(0, 255, 255),
    ["Community Member"] = Color3.fromRGB(50, 205, 50),
    ["Banana Enthusiast"] = Color3.fromRGB(255, 215, 0)
}

-- Load player title data
local function loadPlayerTitleData(player)
    local key = "TitleData_" .. player.UserId
    local success, data = pcall(function()
        return titleDataStore:GetAsync(key)
    end)
    
    if success and data then
        playerTitleData[player] = data
    else
        playerTitleData[player] = {
            selectedTitle = "None",
            showTitle = true,
            titleColor = DefaultTitleColors["None"],
            ownedTitles = {"None", "Banana Farmer"} -- Default titles
        }
    end
    
    return playerTitleData[player]
end

-- Save player title data
local function savePlayerTitleData(player)
    if not playerTitleData[player] then return end
    
    local key = "TitleData_" .. player.UserId
    local success, error = pcall(function()
        titleDataStore:SetAsync(key, playerTitleData[player])
    end)
    
    if not success then
        warn("Failed to save title data for " .. player.Name .. ": " .. tostring(error))
    end
end

-- Award title to player
local function awardTitle(player, titleName)
    if not playerTitleData[player] then
        loadPlayerTitleData(player)
    end
    
    if not table.find(playerTitleData[player].ownedTitles, titleName) then
        table.insert(playerTitleData[player].ownedTitles, titleName)
        savePlayerTitleData(player)
        
        -- Notify player
        local message = "You earned the title: " .. titleName .. "!"
        if player:FindFirstChild("PlayerGui") then
            -- You could create a notification GUI here
            print(player.Name .. " earned title: " .. titleName)
        end
    end
end

-- Get player title data
local function getPlayerTitleData(player)
    if not playerTitleData[player] then
        loadPlayerTitleData(player)
    end
    
    return {
        title = playerTitleData[player].selectedTitle,
        showTitle = playerTitleData[player].showTitle,
        color = playerTitleData[player].titleColor or DefaultTitleColors[playerTitleData[player].selectedTitle] or DefaultTitleColors["None"],
        ownedTitles = playerTitleData[player].ownedTitles
    }
end

-- Handle title update from client
local function onUpdateTitle(player, selectedTitle, showTitle, titleColor)
    if not playerTitleData[player] then
        loadPlayerTitleData(player)
    end
    
    -- Validate title
    if not table.find(playerTitleData[player].ownedTitles, selectedTitle) then
        warn("Player " .. player.Name .. " tried to select unowned title: " .. selectedTitle)
        return
    end
    
    -- Update data
    playerTitleData[player].selectedTitle = selectedTitle
    playerTitleData[player].showTitle = showTitle
    playerTitleData[player].titleColor = titleColor or DefaultTitleColors[selectedTitle] or DefaultTitleColors["None"]
    
    -- Save data
    savePlayerTitleData(player)
    
    -- Notify all clients about the update
    local titleData = getPlayerTitleData(player)
    updateTitleRemote:FireAllClients(player, titleData)
end

-- Handle title data request from client
local function onGetTitleData(player, targetPlayer)
    targetPlayer = targetPlayer or player
    return getPlayerTitleData(targetPlayer)
end

-- Handle player joining
local function onPlayerAdded(player)
    -- Load player data
    loadPlayerTitleData(player)
    
    -- Give default titles based on achievements/stats
    -- You can expand this based on your achievement system
    spawn(function()
        wait(5) -- Wait for player to load
        
        -- Check for various achievements and award titles
        -- This is where you'd integrate with your existing systems
        
        -- Example: Award titles based on coins, seeds, etc.
        -- You could check the player's stats from your CoinSystem, SeedSystem, etc.
        
        -- For now, just ensure they have the basic title
        if not table.find(playerTitleData[player].ownedTitles, "Banana Farmer") then
            awardTitle(player, "Banana Farmer")
        end
    end)
end

-- Handle player leaving
local function onPlayerRemoving(player)
    -- Save data before player leaves
    if playerTitleData[player] then
        savePlayerTitleData(player)
        playerTitleData[player] = nil
    end
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Connect remote events
updateTitleRemote.OnServerEvent:Connect(onUpdateTitle)
getTitleDataRemote.OnServerInvoke = onGetTitleData

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

-- Public functions for other scripts to use
local PlayerTitleSystem = {}

function PlayerTitleSystem:AwardTitle(player, titleName)
    if table.find(AvailableTitles, titleName) then
        awardTitle(player, titleName)
        return true
    end
    return false
end

function PlayerTitleSystem:GetPlayerTitles(player)
    return getPlayerTitleData(player)
end

function PlayerTitleSystem:GetAvailableTitles()
    return AvailableTitles
end

function PlayerTitleSystem:AddTitle(titleName, titleColor)
    if not table.find(AvailableTitles, titleName) then
        table.insert(AvailableTitles, titleName)
        DefaultTitleColors[titleName] = titleColor or Color3.fromRGB(255, 255, 255)
    end
end

-- Example function to award titles based on achievements
function PlayerTitleSystem:CheckAndAwardTitles(player)
    -- This function can be called by other systems when achievements are earned
    -- For example, from your CoinSystem, SeedSystem, etc.
    
    -- You could check player stats and award appropriate titles
    -- Example logic (you'd need to integrate with your existing systems):
    
    --[[
    local coinSystem = require(script.Parent.CoinSystem)
    local playerCoins = coinSystem:GetPlayerCoins(player)
    
    if playerCoins >= 1000 and not table.find(playerTitleData[player].ownedTitles, "Coin Collector") then
        awardTitle(player, "Coin Collector")
    end
    
    if playerCoins >= 10000 and not table.find(playerTitleData[player].ownedTitles, "Banana Baron") then
        awardTitle(player, "Banana Baron")
    end
    --]]
end

print("PlayerTitleSystem loaded")

return PlayerTitleSystem
