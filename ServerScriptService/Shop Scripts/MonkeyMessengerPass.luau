-- Monkey Messenger Pass
-- Unlocks a banana-themed city messenger monkey

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local MONKEY_MESSENGER_GAMEPASS_ID = 11 -- Set your actual gamepass ID

-- Players with monkey messenger
local playersWithMonkeyMessenger = {}
local monkeyMessengers = {} -- Store monkey NPCs

-- Load player's monkey messenger status
local function loadMonkeyMessengerStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, MONKEY_MESSENGER_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithMonkeyMessenger[player.UserId] = true
        player:SetAttribute("MonkeyMessengerActive", true)
        print("🐒 Monkey Messenger enabled for " .. player.Name)
        createMonkeyMessenger(player)
    else
        playersWithMonkeyMessenger[player.UserId] = false
        player:SetAttribute("MonkeyMessengerActive", false)
    end
end

-- Create monkey messenger NPC
local function createMonkeyMessenger(player)
    if not playersWithMonkeyMessenger[player.UserId] then return end
    
    -- Get player's plot
    local plotId = _G.PlotSystem.getPlayerPlot and _G.PlotSystem.getPlayerPlot(player)
    if not plotId then return end
    
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return end
    
    local plotModel = plotsFolder:FindFirstChild("Plot_" .. plotId)
    if not plotModel then return end
    
    -- Remove existing monkey if any
    if monkeyMessengers[player.UserId] then
        monkeyMessengers[player.UserId]:Destroy()
    end
    
    -- Create monkey NPC
    local monkey = Instance.new("Part")
    monkey.Name = "MonkeyMessenger_" .. player.Name
    monkey.Size = Vector3.new(2, 3, 1)
    monkey.Shape = Enum.PartType.Block
    monkey.Material = Enum.Material.Fabric
    monkey.BrickColor = BrickColor.new("Brown")
    monkey.Position = plotModel.Position + Vector3.new(5, 2, 5)
    monkey.Anchored = true
    monkey.CanCollide = false
    monkey.Parent = plotModel
    
    -- Add monkey face
    local face = Instance.new("Decal")
    face.Texture = "rbxasset://textures/face.png"
    face.Face = Enum.NormalId.Front
    face.Parent = monkey
    
    -- Add chat bubble GUI
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 100)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = monkey
    
    local chatFrame = Instance.new("Frame")
    chatFrame.Size = UDim2.new(1, 0, 1, 0)
    chatFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    chatFrame.BorderSizePixel = 2
    chatFrame.Parent = billboardGui
    
    local chatLabel = Instance.new("TextLabel")
    chatLabel.Size = UDim2.new(1, -10, 1, -10)
    chatLabel.Position = UDim2.new(0, 5, 0, 5)
    chatLabel.BackgroundTransparency = 1
    chatLabel.Text = "🐒 Looking for deals..."
    chatLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    chatLabel.TextScaled = true
    chatLabel.Font = Enum.Font.Gotham
    chatLabel.TextWrapped = true
    chatLabel.Parent = chatFrame
    
    -- Store monkey reference
    monkeyMessengers[player.UserId] = monkey
    
    -- Update messages periodically
    spawn(function()
        local messages = {
            "🐒 Best deal: Premium Seeds are 20% off!",
            "🐒 Hot tip: Golden bananas selling high today!",
            "🐒 Pro tip: Check the rare seed vendor!",
            "🐒 Alert: Diamond fruits in high demand!",
            "🐒 Insider info: Special event starting soon!",
            "🐒 Market update: Mythical seeds restocked!",
            "🐒 Trade secret: Sell at sunset for bonus!"
        }
        
        while monkey.Parent and playersWithMonkeyMessenger[player.UserId] do
            wait(math.random(30, 60)) -- Update every 30-60 seconds
            
            if chatLabel and chatLabel.Parent then
                local randomMessage = messages[math.random(1, #messages)]
                chatLabel.Text = randomMessage
                
                -- Send notification to player
                StarterGui:SetCore("SendNotification", {
                    Title = "🐒 Monkey Messenger";
                    Text = randomMessage;
                    Duration = 4;
                })
            end
        end
    end)
    
    return monkey
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == MONKEY_MESSENGER_GAMEPASS_ID and wasPurchased then
        playersWithMonkeyMessenger[player.UserId] = true
        player:SetAttribute("MonkeyMessengerActive", true)
        
        -- Create monkey
        createMonkeyMessenger(player)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "🐒 Monkey Messenger Activated!";
            Text = "Your monkey friend will give you trading tips!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "🐒 " .. player.Name .. " got a Monkey Messenger! They have insider trading info! 🐒"
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                StarterGui:SetCore("ChatMakeSystemMessage", {
                    Text = chatMessage;
                    Color = Color3.fromRGB(139, 69, 19);
                    Font = Enum.Font.GothamBold;
                    FontSize = Enum.FontSize.Size18;
                })
            end)
        end
        
        print("🎉 " .. player.Name .. " purchased Monkey Messenger gamepass!")
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2)
    loadMonkeyMessengerStatus(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if monkeyMessengers[player.UserId] then
        monkeyMessengers[player.UserId]:Destroy()
        monkeyMessengers[player.UserId] = nil
    end
    playersWithMonkeyMessenger[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadMonkeyMessengerStatus(player)
    end)
end

-- Global access
_G.MonkeyMessengerPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, MONKEY_MESSENGER_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithMonkeyMessenger[player.UserId] or false
    end,
    createMessenger = createMonkeyMessenger,
    GAMEPASS_ID = MONKEY_MESSENGER_GAMEPASS_ID
}

print("🐒 Monkey Messenger Gamepass System initialized!")
print("💰 Gamepass ID: " .. MONKEY_MESSENGER_GAMEPASS_ID .. " (remember to set the actual ID)")
