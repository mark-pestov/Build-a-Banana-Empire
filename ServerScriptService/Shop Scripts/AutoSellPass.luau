-- AutoCollect Pass (formerly AutoSellPass)
-- Automatically collects Blox from your buildings in the banana city

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local AUTO_COLLECT_GAMEPASS_ID = 1 -- Set your actual gamepass ID
local AUTO_COLLECT_CHECK_INTERVAL = 2 -- Check every 2 seconds

-- Wait for required systems
repeat wait() until _G.CoinSystem
repeat wait() until _G.PlotSystem

-- DataStore for tracking gamepass ownership
local autoCollectDataStore = DataStoreService:GetDataStore("AutoCollectGamepass")

-- Players with auto-collect enabled
local playersWithAutoCollect = {}

-- Load player's auto-collect status
local function loadAutoCollectStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, AUTO_COLLECT_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithAutoCollect[player.UserId] = true
        player:SetAttribute("AutoCollectEnabled", true)
        print("🔄 Auto-Collect enabled for " .. player.Name)
    else
        playersWithAutoCollect[player.UserId] = false
        player:SetAttribute("AutoCollectEnabled", false)
    end
end

-- Auto-collect function
local function autoCollectBlox(player)
    if not playersWithAutoCollect[player.UserId] then return end
    
    -- Get player's plot
    local plotId = _G.PlotSystem.getPlayerPlot and _G.PlotSystem.getPlayerPlot(player)
    if not plotId then return end
    
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return end
    
    local plotModel = plotsFolder:FindFirstChild("Plot_" .. plotId)
    if not plotModel then return end
    
    -- Find the buildings/collectibles
    local collectibles = {}
    for _, child in ipairs(plotModel:GetChildren()) do
        if child.Name:find("Building") or child:FindFirstChild("IsCollectible") then
            table.insert(collectibles, child)
        end
    end
    
    -- If plot has collectibles, collect them
    if #collectibles > 0 then
        local totalValue = 0
        local itemCount = 0
        
        for _, collectible in ipairs(collectibles) do
            local value = collectible:FindFirstChild("Value")
            if value and value.Value then
                totalValue = totalValue + value.Value
                itemCount = itemCount + 1
                collectible:Destroy()
            end
        end
        
        if totalValue > 0 then
            -- Add coins to player
            if _G.CoinSystem.addCoins then
                _G.CoinSystem.addCoins(player, totalValue)
            end
            
            -- Send notification
            StarterGui:SetCore("SendNotification", {
                Title = "🔄 Auto-Collect";
                Text = "Collected " .. itemCount .. " items for " .. totalValue .. " coins!";
                Duration = 3;
            })
            
            print("🔄 Auto-collected " .. itemCount .. " items for " .. player.Name .. " (" .. totalValue .. " coins)")
        end
    end
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == AUTO_COLLECT_GAMEPASS_ID and wasPurchased then
        playersWithAutoCollect[player.UserId] = true
        player:SetAttribute("AutoCollectEnabled", true)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "🔄 Auto-Collect Activated!";
            Text = "Your Blox will now collect automatically from your buildings!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "🔄 " .. player.Name .. " bought Auto-Collect! Their Blox will collect automatically! 🔄"
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                StarterGui:SetCore("ChatMakeSystemMessage", {
                    Text = chatMessage;
                    Color = Color3.fromRGB(0, 255, 0);
                    Font = Enum.Font.GothamBold;
                    FontSize = Enum.FontSize.Size18;
                })
            end)
        end
        
        print("🎉 " .. player.Name .. " purchased Auto-Collect gamepass!")
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Auto-collect loop
spawn(function()
    while true do
        wait(AUTO_COLLECT_CHECK_INTERVAL)
        for _, player in ipairs(Players:GetPlayers()) do
            if playersWithAutoCollect[player.UserId] then
                pcall(function()
                    autoCollectBlox(player)
                end)
            end
        end
    end
end)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2) -- Wait for player to load
    loadAutoCollectStatus(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playersWithAutoCollect[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadAutoCollectStatus(player)
    end)
end

-- Global access
_G.AutoCollectPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, AUTO_COLLECT_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithAutoCollect[player.UserId] or false
    end,
    GAMEPASS_ID = AUTO_COLLECT_GAMEPASS_ID
}

print("🔄 Auto-Collect Gamepass System initialized!")
print("💰 Gamepass ID: " .. AUTO_COLLECT_GAMEPASS_ID .. " (remember to set the actual ID)")
