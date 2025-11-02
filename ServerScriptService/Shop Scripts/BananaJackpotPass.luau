-- BananaBuildingJackpotPass.luau - Banana Building Jackpot Gamepass System
-- Win rare buildings or Blox in the city/empire game

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local BUILDING_JACKPOT_GAMEPASS_ID = 12 -- Set your actual gamepass ID
local JACKPOT_CHANCE = 0.15 -- 15% chance for jackpot
local JACKPOT_MULTIPLIER_MIN = 2 -- Minimum 2x multiplier
local JACKPOT_MULTIPLIER_MAX = 10 -- Maximum 10x multiplier

-- Players with building jackpot
local playersWithBuildingJackpot = {}

-- Load player's building jackpot status
local function loadBuildingJackpotStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, BUILDING_JACKPOT_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithBuildingJackpot[player.UserId] = true
        player:SetAttribute("BuildingJackpotActive", true)
        print("🎰 Building Jackpot enabled for " .. player.Name)
    else
        playersWithBuildingJackpot[player.UserId] = false
        player:SetAttribute("BuildingJackpotActive", false)
    end
end

-- Check for jackpot when selling
local function checkJackpot(player, sellAmount)
    if not playersWithBuildingJackpot[player.UserId] then
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
    if gamepassId == BUILDING_JACKPOT_GAMEPASS_ID and wasPurchased then
        playersWithBuildingJackpot[player.UserId] = true
        player:SetAttribute("BuildingJackpotActive", true)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "🎰 Building Jackpot Activated!";
            Text = "You have a " .. (JACKPOT_CHANCE * 100) .. "% chance for bonus coins when selling!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "🎰 " .. player.Name .. " bought Building Jackpot! They can win bonus coins! 🎰"
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
        
        print("🎉 " .. player.Name .. " purchased Building Jackpot gamepass!")
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2)
    loadBuildingJackpotStatus(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playersWithBuildingJackpot[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadBuildingJackpotStatus(player)
    end)
end

-- Global access
_G.BananaBuildingJackpotPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, BUILDING_JACKPOT_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithBuildingJackpot[player.UserId] or false
    end,
    checkJackpot = checkJackpot,
    JACKPOT_CHANCE = JACKPOT_CHANCE,
    MULTIPLIER_RANGE = {JACKPOT_MULTIPLIER_MIN, JACKPOT_MULTIPLIER_MAX},
    GAMEPASS_ID = BUILDING_JACKPOT_GAMEPASS_ID
}

print("🎰 Building Jackpot Gamepass System initialized!")
print("💰 Gamepass ID: " .. BUILDING_JACKPOT_GAMEPASS_ID .. " (remember to set the actual ID)")
print("🎲 Jackpot Chance: " .. (JACKPOT_CHANCE * 100) .. "%")
print("💥 Multiplier Range: " .. JACKPOT_MULTIPLIER_MIN .. "x - " .. JACKPOT_MULTIPLIER_MAX .. "x")
