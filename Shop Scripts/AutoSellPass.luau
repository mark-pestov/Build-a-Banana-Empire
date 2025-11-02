-- AutoSellPass.luau - Auto-Sell Gamepass System
-- Automatically sells bananas when your crate is full

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local AUTO_SELL_GAMEPASS_ID = 1 -- Set your actual gamepass ID
local AUTO_SELL_CHECK_INTERVAL = 2 -- Check every 2 seconds

-- Wait for required systems
repeat wait() until _G.CoinSystem
repeat wait() until _G.PlotSystem

-- DataStore for tracking gamepass ownership
local autoSellDataStore = DataStoreService:GetDataStore("AutoSellGamepass")

-- Players with auto-sell enabled
local playersWithAutoSell = {}

-- Load player's auto-sell status
local function loadAutoSellStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, AUTO_SELL_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithAutoSell[player.UserId] = true
        player:SetAttribute("AutoSellEnabled", true)
        print("🔄 Auto-Sell enabled for " .. player.Name)
    else
        playersWithAutoSell[player.UserId] = false
        player:SetAttribute("AutoSellEnabled", false)
    end
end

-- Auto-sell function
local function autoSellBananas(player)
    if not playersWithAutoSell[player.UserId] then return end
    
    -- Get player's plot
    local plotId = _G.PlotSystem.getPlayerPlot and _G.PlotSystem.getPlayerPlot(player)
    if not plotId then return end
    
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return end
    
    local plotModel = plotsFolder:FindFirstChild("Plot_" .. plotId)
    if not plotModel then return end
    
    -- Find the crate/storage
    local crate = plotModel:FindFirstChild("BananaCrate") or plotModel:FindFirstChild("Storage")
    if not crate then return end
    
    -- Check if crate is full (you can adjust this logic based on your crate system)
    local bananas = {}
    for _, child in ipairs(crate:GetChildren()) do
        if child.Name:find("Banana") or child:FindFirstChild("IsFruit") then
            table.insert(bananas, child)
        end
    end
    
    -- If crate has items, sell them
    if #bananas > 0 then
        local totalValue = 0
        local itemCount = 0
        
        for _, banana in ipairs(bananas) do
            local value = banana:FindFirstChild("Value")
            if value and value.Value then
                totalValue = totalValue + value.Value
                itemCount = itemCount + 1
                banana:Destroy()
            end
        end
        
        if totalValue > 0 then
            -- Add coins to player
            if _G.CoinSystem.addCoins then
                _G.CoinSystem.addCoins(player, totalValue)
            end
            
            -- Send notification
            StarterGui:SetCore("SendNotification", {
                Title = "🔄 Auto-Sell";
                Text = "Sold " .. itemCount .. " items for " .. totalValue .. " coins!";
                Duration = 3;
            })
            
            print("🔄 Auto-sold " .. itemCount .. " items for " .. player.Name .. " (" .. totalValue .. " coins)")
        end
    end
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == AUTO_SELL_GAMEPASS_ID and wasPurchased then
        playersWithAutoSell[player.UserId] = true
        player:SetAttribute("AutoSellEnabled", true)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "🔄 Auto-Sell Activated!";
            Text = "Your bananas will now sell automatically when your crate is full!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "🔄 " .. player.Name .. " bought Auto-Sell! Their bananas will sell automatically! 🔄"
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
        
        print("🎉 " .. player.Name .. " purchased Auto-Sell gamepass!")
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Auto-sell loop
spawn(function()
    while true do
        wait(AUTO_SELL_CHECK_INTERVAL)
        for _, player in ipairs(Players:GetPlayers()) do
            if playersWithAutoSell[player.UserId] then
                pcall(function()
                    autoSellBananas(player)
                end)
            end
        end
    end
end)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2) -- Wait for player to load
    loadAutoSellStatus(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playersWithAutoSell[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadAutoSellStatus(player)
    end)
end

-- Global access
_G.AutoSellPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, AUTO_SELL_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithAutoSell[player.UserId] or false
    end,
    GAMEPASS_ID = AUTO_SELL_GAMEPASS_ID
}

print("🔄 Auto-Sell Gamepass System initialized!")
print("💰 Gamepass ID: " .. AUTO_SELL_GAMEPASS_ID .. " (remember to set the actual ID)")
