-- BananaJackpotPass.luau - Banana Jackpot Gamepass System
-- Chance to earn bonus coins when selling, like a hidden lottery

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local BANANA_JACKPOT_GAMEPASS_ID = 12 -- Set your actual gamepass ID
local JACKPOT_CHANCE = 0.15 -- 15% chance for jackpot
local JACKPOT_MULTIPLIER_MIN = 2 -- Minimum 2x multiplier
local JACKPOT_MULTIPLIER_MAX = 10 -- Maximum 10x multiplier

-- Players with banana jackpot
local playersWithBananaJackpot = {}

-- Load player's banana jackpot status
local function loadBananaJackpotStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, BANANA_JACKPOT_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithBananaJackpot[player.UserId] = true
        player:SetAttribute("BananaJackpotActive", true)
        print("🎰 Banana Jackpot enabled for " .. player.Name)
    else
        playersWithBananaJackpot[player.UserId] = false
        player:SetAttribute("BananaJackpotActive", false)
    end
end

-- Check for jackpot when selling
local function checkJackpot(player, sellAmount)
    if not playersWithBananaJackpot[player.UserId] then
        return sellAmount, false
    end
    
    if math.random() < JACKPOT_CHANCE then
        -- JACKPOT!
        local multiplier = math.random(JACKPOT_MULTIPLIER_MIN, JACKPOT_MULTIPLIER_MAX)
        local bonusAmount = sellAmount * (multiplier - 1)
        
        -- Send dramatic jackpot notification
        StarterGui:SetCore("SendNotification", {
            Title = "🎰 JACKPOT! 🎰";
            Text = "You won " .. multiplier .. "x bonus! +" .. bonusAmount .. " extra coins!";
            Duration = 6;
        })
        
        -- Send chat announcement
        local chatMessage = "🎰 " .. player.Name .. " hit the JACKPOT! " .. multiplier .. "x bonus coins! 🎰"
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                StarterGui:SetCore("ChatMakeSystemMessage", {
                    Text = chatMessage;
                    Color = Color3.fromRGB(255, 215, 0);
                    Font = Enum.Font.GothamBold;
                    FontSize = Enum.FontSize.Size20;
                })
            end)
        end
        
        print("🎰 " .. player.Name .. " hit jackpot! " .. multiplier .. "x multiplier")
        return sellAmount * multiplier, true
    end
    
    return sellAmount, false
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == BANANA_JACKPOT_GAMEPASS_ID and wasPurchased then
        playersWithBananaJackpot[player.UserId] = true
        player:SetAttribute("BananaJackpotActive", true)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "🎰 Banana Jackpot Activated!";
            Text = "You have a " .. (JACKPOT_CHANCE * 100) .. "% chance for bonus coins when selling!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "🎰 " .. player.Name .. " bought Banana Jackpot! They can win bonus coins! 🎰"
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
        
        print("🎉 " .. player.Name .. " purchased Banana Jackpot gamepass!")
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2)
    loadBananaJackpotStatus(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playersWithBananaJackpot[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadBananaJackpotStatus(player)
    end)
end

-- Global access
_G.BananaJackpotPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, BANANA_JACKPOT_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithBananaJackpot[player.UserId] or false
    end,
    checkJackpot = checkJackpot,
    JACKPOT_CHANCE = JACKPOT_CHANCE,
    MULTIPLIER_RANGE = {JACKPOT_MULTIPLIER_MIN, JACKPOT_MULTIPLIER_MAX},
    GAMEPASS_ID = BANANA_JACKPOT_GAMEPASS_ID
}

print("🎰 Banana Jackpot Gamepass System initialized!")
print("💰 Gamepass ID: " .. BANANA_JACKPOT_GAMEPASS_ID .. " (remember to set the actual ID)")
print("🎲 Jackpot Chance: " .. (JACKPOT_CHANCE * 100) .. "%")
print("💥 Multiplier Range: " .. JACKPOT_MULTIPLIER_MIN .. "x - " .. JACKPOT_MULTIPLIER_MAX .. "x")
