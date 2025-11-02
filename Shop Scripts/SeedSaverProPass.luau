-- SeedSaverProPass.luau - Seed Saver Pro Gamepass System
-- A good chance planted seed does not get consumed

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local SEED_SAVER_PRO_GAMEPASS_ID = 10 -- Set your actual gamepass ID
local SEED_SAVE_CHANCE = 0.75 -- 75% chance to save seed

-- Players with seed saver pro
local playersWithSeedSaverPro = {}

-- Load player's seed saver pro status
local function loadSeedSaverProStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, SEED_SAVER_PRO_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithSeedSaverPro[player.UserId] = true
        player:SetAttribute("SeedSaverProActive", true)
        print("🌱 Seed Saver Pro enabled for " .. player.Name)
    else
        playersWithSeedSaverPro[player.UserId] = false
        player:SetAttribute("SeedSaverProActive", false)
    end
end

-- Check if seed should be saved
local function shouldSaveSeed(player)
    if not playersWithSeedSaverPro[player.UserId] then
        return false
    end
    
    return math.random() < SEED_SAVE_CHANCE
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == SEED_SAVER_PRO_GAMEPASS_ID and wasPurchased then
        playersWithSeedSaverPro[player.UserId] = true
        player:SetAttribute("SeedSaverProActive", true)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "🌱 Seed Saver Pro Activated!";
            Text = "Your seeds have a " .. (SEED_SAVE_CHANCE * 100) .. "% chance to not be consumed!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "🌱 " .. player.Name .. " bought Seed Saver Pro! Their seeds might not get consumed! 🌱"
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
        
        print("🎉 " .. player.Name .. " purchased Seed Saver Pro gamepass!")
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2)
    loadSeedSaverProStatus(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playersWithSeedSaverPro[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadSeedSaverProStatus(player)
    end)
end

-- Global access
_G.SeedSaverProPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, SEED_SAVER_PRO_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithSeedSaverPro[player.UserId] or false
    end,
    shouldSaveSeed = shouldSaveSeed,
    SAVE_CHANCE = SEED_SAVE_CHANCE,
    GAMEPASS_ID = SEED_SAVER_PRO_GAMEPASS_ID
}

print("🌱 Seed Saver Pro Gamepass System initialized!")
print("💰 Gamepass ID: " .. SEED_SAVER_PRO_GAMEPASS_ID .. " (remember to set the actual ID)")
print("💾 Save Chance: " .. (SEED_SAVE_CHANCE * 100) .. "%")
