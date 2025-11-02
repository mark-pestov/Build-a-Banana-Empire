-- Building Saver Pro Pass (formerly SeedSaverProPass)
-- Lets you save and restore buildings in your banana city

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local BUILDING_SAVER_PRO_GAMEPASS_ID = 10 -- Set your actual gamepass ID
local BUILDING_SAVE_CHANCE = 0.75 -- 75% chance to save building

-- Players with building saver pro
local playersWithBuildingSaverPro = {}

-- Load player's building saver pro status
local function loadBuildingSaverProStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, BUILDING_SAVER_PRO_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithBuildingSaverPro[player.UserId] = true
        player:SetAttribute("BuildingSaverProActive", true)
        print("🏙️ Building Saver Pro enabled for " .. player.Name)
    else
        playersWithBuildingSaverPro[player.UserId] = false
        player:SetAttribute("BuildingSaverProActive", false)
    end
end

-- Check if building should be saved
local function shouldSaveBuilding(player)
    if not playersWithBuildingSaverPro[player.UserId] then
        return false
    end
    
    return math.random() < BUILDING_SAVE_CHANCE
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == BUILDING_SAVER_PRO_GAMEPASS_ID and wasPurchased then
        playersWithBuildingSaverPro[player.UserId] = true
        player:SetAttribute("BuildingSaverProActive", true)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "🏙️ Building Saver Pro Activated!";
            Text = "Your buildings have a " .. (BUILDING_SAVE_CHANCE * 100) .. "% chance to not be consumed!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "🏙️ " .. player.Name .. " bought Building Saver Pro! Their buildings might not get consumed! 🏙️"
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
        
        print("🎉 " .. player.Name .. " purchased Building Saver Pro gamepass!")
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2)
    loadBuildingSaverProStatus(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playersWithBuildingSaverPro[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadBuildingSaverProStatus(player)
    end)
end

-- Global access
_G.BuildingSaverProPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, BUILDING_SAVER_PRO_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithBuildingSaverPro[player.UserId] or false
    end,
    shouldSaveBuilding = shouldSaveBuilding,
    SAVE_CHANCE = BUILDING_SAVE_CHANCE,
    GAMEPASS_ID = BUILDING_SAVER_PRO_GAMEPASS_ID
}

print("🏙️ Building Saver Pro Gamepass System initialized!")
print("💰 Gamepass ID: " .. BUILDING_SAVER_PRO_GAMEPASS_ID .. " (remember to set the actual ID)")
print("💾 Save Chance: " .. (BUILDING_SAVE_CHANCE * 100) .. "%")
