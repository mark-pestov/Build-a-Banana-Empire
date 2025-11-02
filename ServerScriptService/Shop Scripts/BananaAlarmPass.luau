-- Banana Alarm Pass
-- Triggers banana-themed city alerts or events

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local BANANA_ALARM_GAMEPASS_ID = 8 -- Set your actual gamepass ID

-- Players with banana alarm
local playersWithBananaAlarm = {}

-- Load player's banana alarm status
local function loadBananaAlarmStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, BANANA_ALARM_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithBananaAlarm[player.UserId] = true
        player:SetAttribute("BananaAlarmActive", true)
        print("🚨 Banana Alarm enabled for " .. player.Name)
    else
        playersWithBananaAlarm[player.UserId] = false
        player:SetAttribute("BananaAlarmActive", false)
    end
end

-- Trigger alarm for events
local function triggerAlarm(player, eventType, message)
    if not playersWithBananaAlarm[player.UserId] then return end
    
    -- Play alarm sound
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local alarmSound = Instance.new("Sound")
        alarmSound.SoundId = "rbxassetid://131961136" -- Alarm sound
        alarmSound.Volume = 0.7
        alarmSound.Parent = playerGui
        alarmSound:Play()
        
        game:GetService("Debris"):AddItem(alarmSound, 3)
    end
    
    -- Send urgent notification
    StarterGui:SetCore("SendNotification", {
        Title = "🚨 BANANA ALARM! 🚨";
        Text = message;
        Duration = 6;
    })
    
    print("🚨 Alarm triggered for " .. player.Name .. ": " .. message)
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == BANANA_ALARM_GAMEPASS_ID and wasPurchased then
        playersWithBananaAlarm[player.UserId] = true
        player:SetAttribute("BananaAlarmActive", true)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "🚨 Banana Alarm Activated!";
            Text = "You'll be alerted to important events and pests!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "🚨 " .. player.Name .. " bought Banana Alarm! They'll be warned of danger! 🚨"
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                StarterGui:SetCore("ChatMakeSystemMessage", {
                    Text = chatMessage;
                    Color = Color3.fromRGB(255, 0, 0);
                    Font = Enum.Font.GothamBold;
                    FontSize = Enum.FontSize.Size18;
                })
            end)
        end
        
        print("🎉 " .. player.Name .. " purchased Banana Alarm gamepass!")
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2)
    loadBananaAlarmStatus(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playersWithBananaAlarm[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadBananaAlarmStatus(player)
    end)
end

-- Global access
_G.BananaAlarmPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, BANANA_ALARM_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithBananaAlarm[player.UserId] or false
    end,
    triggerAlarm = triggerAlarm,
    GAMEPASS_ID = BANANA_ALARM_GAMEPASS_ID
}

print("🚨 Banana Alarm Gamepass System initialized!")
print("💰 Gamepass ID: " .. BANANA_ALARM_GAMEPASS_ID .. " (remember to set the actual ID)")
