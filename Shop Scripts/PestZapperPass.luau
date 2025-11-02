-- PestZapperPass.luau - Pest Zapper Gamepass System
-- Instantly zaps pests on your plot whenever they appear

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local PEST_ZAPPER_GAMEPASS_ID = 7 -- Set your actual gamepass ID

-- Wait for pest system
repeat wait() until _G.PestSystem

-- Players with pest zapper
local playersWithPestZapper = {}

-- Load player's pest zapper status
local function loadPestZapperStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, PEST_ZAPPER_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithPestZapper[player.UserId] = true
        player:SetAttribute("PestZapperActive", true)
        print("⚡ Pest Zapper enabled for " .. player.Name)
    else
        playersWithPestZapper[player.UserId] = false
        player:SetAttribute("PestZapperActive", false)
    end
end

-- Auto-zap pests function
local function autoZapPests(player)
    if not playersWithPestZapper[player.UserId] then return end
    
    -- Get player's plot
    local plotId = _G.PlotSystem.getPlayerPlot and _G.PlotSystem.getPlayerPlot(player)
    if not plotId then return end
    
    -- Check if player has pests
    local pestStatus = _G.PestSystem.getPestStatus(player, plotId)
    if pestStatus and pestStatus.isInfected then
        -- Zap the pests!
        _G.PestSystem.clearPests(player, plotId)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "⚡ PEST ZAPPED!";
            Text = "Your Pest Zapper eliminated the pests!";
            Duration = 3;
        })
        
        print("⚡ Auto-zapped pests for " .. player.Name)
    end
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == PEST_ZAPPER_GAMEPASS_ID and wasPurchased then
        playersWithPestZapper[player.UserId] = true
        player:SetAttribute("PestZapperActive", true)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "⚡ Pest Zapper Activated!";
            Text = "Pests will be automatically zapped on your plot!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "⚡ " .. player.Name .. " bought Pest Zapper! Their pests get zapped automatically! ⚡"
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                StarterGui:SetCore("ChatMakeSystemMessage", {
                    Text = chatMessage;
                    Color = Color3.fromRGB(255, 255, 0);
                    Font = Enum.Font.GothamBold;
                    FontSize = Enum.FontSize.Size18;
                })
            end)
        end
        
        print("🎉 " .. player.Name .. " purchased Pest Zapper gamepass!")
    end
end

-- Auto-zap loop
spawn(function()
    while true do
        wait(5) -- Check every 5 seconds
        for _, player in ipairs(Players:GetPlayers()) do
            if playersWithPestZapper[player.UserId] then
                pcall(function()
                    autoZapPests(player)
                end)
            end
        end
    end
end)

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2)
    loadPestZapperStatus(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playersWithPestZapper[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadPestZapperStatus(player)
    end)
end

-- Global access
_G.PestZapperPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, PEST_ZAPPER_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithPestZapper[player.UserId] or false
    end,
    GAMEPASS_ID = PEST_ZAPPER_GAMEPASS_ID
}

print("⚡ Pest Zapper Gamepass System initialized!")
print("💰 Gamepass ID: " .. PEST_ZAPPER_GAMEPASS_ID .. " (remember to set the actual ID)")
