-- Banana Tax Troll Pass
-- Triggers a banana-themed tax event in the city/empire game

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local BANANA_TAX_TROLL_GAMEPASS_ID = 3 -- Set your actual gamepass ID
local TAX_TROLL_DURATION = 3600 -- 1 hour in seconds

-- Players with tax troll active
local playersWithTaxTroll = {}

-- Load player's tax troll status
local function loadTaxTrollStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, BANANA_TAX_TROLL_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithTaxTroll[player.UserId] = true
        print("💰 Banana Tax Troll available for " .. player.Name)
    else
        playersWithTaxTroll[player.UserId] = false
    end
end

-- Activate tax troll
local function activateTaxTroll(player)
    if not playersWithTaxTroll[player.UserId] then
        return false, "You don't own Banana Tax Troll!"
    end
    
    if player:GetAttribute("BananaTaxTrollActive") then
        return false, "Tax Troll is already active!"
    end
    
    -- Activate tax troll
    player:SetAttribute("BananaTaxTrollActive", true)
    
    -- Set timer to deactivate
    spawn(function()
        wait(TAX_TROLL_DURATION)
        player:SetAttribute("BananaTaxTrollActive", false)
        
        -- Send deactivation notification
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "💰 Tax Troll Expired";
                Text = "Your tax troll effect has ended!";
                Duration = 3;
            })
        end)
        
        print("💰 Tax Troll expired for " .. player.Name)
    end)
    
    -- Send activation notification
    StarterGui:SetCore("SendNotification", {
        Title = "💰 Tax Troll Activated!";
        Text = "All players pay double, you pay half! (1 hour)";
        Duration = 5;
    })
    
    -- Send chat announcement
    local chatMessage = "💰 " .. player.Name .. " activated Banana Tax Troll! All players pay double prices for 1 hour! 💰"
    for _, p in ipairs(Players:GetPlayers()) do
        pcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = chatMessage;
                Color = Color3.fromRGB(255, 215, 0);
                Font = Enum.Font.GothamBold;
                FontSize = Enum.FontSize.Size18;
            })
        end)
    end
    
    print("💰 " .. player.Name .. " activated Tax Troll for 1 hour")
    return true, "Tax Troll activated for 1 hour!"
end

-- Get price multiplier for player
local function getPriceMultiplier(player)
    -- Check if any player has tax troll active
    local taxTrollPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p:GetAttribute("BananaTaxTrollActive") then
            taxTrollPlayer = p
            break
        end
    end
    
    if not taxTrollPlayer then
        return 1 -- Normal prices
    end
    
    if player == taxTrollPlayer then
        return 0.5 -- Tax troll owner pays half
    else
        return 2 -- Everyone else pays double
    end
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == BANANA_TAX_TROLL_GAMEPASS_ID and wasPurchased then
        playersWithTaxTroll[player.UserId] = true
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "💰 Banana Tax Troll Purchased!";
            Text = "You can now troll other players with double prices!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "💰 " .. player.Name .. " bought Banana Tax Troll! They can make everyone pay double! 💰"
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                StarterGui:SetCore("ChatMakeSystemMessage", {
                    Text = chatMessage;
                    Color = Color3.fromRGB(255, 215, 0);
                    Font = Enum.Font.GothamBold;
                    FontSize = Enum.FontSize.Size18;
                })
            end)
        end
        
        print("🎉 " .. player.Name .. " purchased Banana Tax Troll gamepass!")
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2)
    loadTaxTrollStatus(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playersWithTaxTroll[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadTaxTrollStatus(player)
    end)
end

-- Global access
_G.BananaTaxTrollPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, BANANA_TAX_TROLL_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithTaxTroll[player.UserId] or false
    end,
    activateTroll = activateTaxTroll,
    getPriceMultiplier = getPriceMultiplier,
    isActive = function(player)
        return player:GetAttribute("BananaTaxTrollActive") or false
    end,
    GAMEPASS_ID = BANANA_TAX_TROLL_GAMEPASS_ID
}

print("💰 Banana Tax Troll Gamepass System initialized!")
print("💰 Gamepass ID: " .. BANANA_TAX_TROLL_GAMEPASS_ID .. " (remember to set the actual ID)")
print("⏱️ Duration: " .. TAX_TROLL_DURATION .. " seconds (1 hour)")
