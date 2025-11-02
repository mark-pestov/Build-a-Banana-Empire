-- Banana Buddy Pass
-- Unlocks a banana-themed city helper or mascot

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local BANANA_BUDDY_GAMEPASS_ID = 6 -- Set your actual gamepass ID
local BUDDY_DROP_INTERVAL = 30 -- Drop bonus banana every 30 seconds
local SPEED_BOOST = 1.5 -- 50% speed boost
local JUMP_BOOST = 1.5 -- 50% jump boost

-- Players with banana buddy
local playersWithBananaBuddy = {}
local bananaBuddies = {} -- Store buddy NPCs

-- Load player's banana buddy status
local function loadBananaBuddyStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, BANANA_BUDDY_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithBananaBuddy[player.UserId] = true
        player:SetAttribute("BananaBuddyActive", true)
        print("🍌 Banana Buddy enabled for " .. player.Name)
        createBananaBuddy(player)
    else
        playersWithBananaBuddy[player.UserId] = false
        player:SetAttribute("BananaBuddyActive", false)
    end
end

-- Create floating banana buddy NPC
local function createBananaBuddy(player)
    if not playersWithBananaBuddy[player.UserId] then return end
    
    -- Remove existing buddy if any
    if bananaBuddies[player.UserId] then
        bananaBuddies[player.UserId]:Destroy()
    end
    
    -- Create buddy NPC
    local buddy = Instance.new("Part")
    buddy.Name = "BananaBuddy_" .. player.Name
    buddy.Size = Vector3.new(2, 3, 1)
    buddy.Shape = Enum.PartType.Block
    buddy.Material = Enum.Material.Neon
    buddy.BrickColor = BrickColor.new("Bright yellow")
    buddy.Anchored = true
    buddy.CanCollide = false
    buddy.Parent = workspace
    
    -- Add face/features
    local face = Instance.new("Decal")
    face.Texture = "rbxasset://textures/face.png"
    face.Face = Enum.NormalId.Front
    face.Parent = buddy
    
    -- Add glowing effect
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.fromRGB(255, 255, 0)
    pointLight.Brightness = 1
    pointLight.Range = 10
    pointLight.Parent = buddy
    
    -- Store buddy reference
    bananaBuddies[player.UserId] = buddy
    
    -- Apply speed and jump boosts to player
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = humanoid.WalkSpeed * SPEED_BOOST
            humanoid.JumpPower = humanoid.JumpPower * JUMP_BOOST
        end
    end
    
    -- Floating animation
    spawn(function()
        local startTime = tick()
        while buddy.Parent do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local playerPos = player.Character.HumanoidRootPart.Position
                local floatHeight = 8 + math.sin((tick() - startTime) * 2) * 2
                local targetPos = playerPos + Vector3.new(3, floatHeight, 0)
                
                -- Smooth follow
                local currentPos = buddy.Position
                local newPos = currentPos:Lerp(targetPos, 0.1)
                buddy.Position = newPos
                
                -- Gentle rotation
                buddy.Rotation = Vector3.new(0, (tick() - startTime) * 50, 0)
            end
            wait(0.1)
        end
    end)
    
    -- Drop bonus bananas
    spawn(function()
        while buddy.Parent and playersWithBananaBuddy[player.UserId] do
            wait(BUDDY_DROP_INTERVAL)
            
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                -- Create bonus banana
                local bonusBanana = Instance.new("Part")
                bonusBanana.Name = "BonusBanana"
                bonusBanana.Size = Vector3.new(1, 2, 1)
                bonusBanana.Shape = Enum.PartType.Ball
                bonusBanana.Material = Enum.Material.Neon
                bonusBanana.BrickColor = BrickColor.new("Bright yellow")
                bonusBanana.Position = buddy.Position + Vector3.new(0, -2, 0)
                bonusBanana.Parent = workspace
                
                -- Add value
                local valueObj = Instance.new("NumberValue")
                valueObj.Name = "Value"
                valueObj.Value = math.random(100, 500) -- Random bonus value
                valueObj.Parent = bonusBanana
                
                -- Add collection detection
                local clickDetector = Instance.new("ClickDetector")
                clickDetector.MaxActivationDistance = 20
                clickDetector.Parent = bonusBanana
                
                clickDetector.MouseClick:Connect(function(clickPlayer)
                    if clickPlayer == player then
                        -- Give coins
                        if _G.CoinSystem and _G.CoinSystem.addCoins then
                            _G.CoinSystem.addCoins(player, valueObj.Value)
                        end
                        
                        -- Notification
                        StarterGui:SetCore("SendNotification", {
                            Title = "🍌 Buddy Bonus!";
                            Text = "+" .. valueObj.Value .. " coins from Banana Buddy!";
                            Duration = 3;
                        })
                        
                        bonusBanana:Destroy()
                    end
                end)
                
                -- Auto cleanup
                game:GetService("Debris"):AddItem(bonusBanana, 60)
            end
        end
    end)
    
    return buddy
end

-- Handle character respawn
local function onCharacterAdded(character, player)
    if playersWithBananaBuddy[player.UserId] then
        wait(2) -- Wait for character to load
        -- Reapply boosts
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = humanoid.WalkSpeed * SPEED_BOOST
            humanoid.JumpPower = humanoid.JumpPower * JUMP_BOOST
        end
    end
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == BANANA_BUDDY_GAMEPASS_ID and wasPurchased then
        playersWithBananaBuddy[player.UserId] = true
        player:SetAttribute("BananaBuddyActive", true)
        
        -- Create buddy
        createBananaBuddy(player)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "🍌 Banana Buddy Activated!";
            Text = "Your floating banana friend will help you!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "🍌 " .. player.Name .. " got a Banana Buddy! They have a floating banana friend! 🍌"
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
        
        print("🎉 " .. player.Name .. " purchased Banana Buddy gamepass!")
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2)
    loadBananaBuddyStatus(player)
    
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(character, player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if bananaBuddies[player.UserId] then
        bananaBuddies[player.UserId]:Destroy()
        bananaBuddies[player.UserId] = nil
    end
    playersWithBananaBuddy[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadBananaBuddyStatus(player)
        
        player.CharacterAdded:Connect(function(character)
            onCharacterAdded(character, player)
        end)
        
        if player.Character then
            onCharacterAdded(player.Character, player)
        end
    end)
end

-- Global access
_G.BananaBuddyPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, BANANA_BUDDY_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithBananaBuddy[player.UserId] or false
    end,
    createBuddy = createBananaBuddy,
    GAMEPASS_ID = BANANA_BUDDY_GAMEPASS_ID
}

print("🍌 Banana Buddy Gamepass System initialized!")
print("💰 Gamepass ID: " .. BANANA_BUDDY_GAMEPASS_ID .. " (remember to set the actual ID)")
print("⚡ Speed Boost: " .. (SPEED_BOOST * 100) .. "%")
print("🦘 Jump Boost: " .. (JUMP_BOOST * 100) .. "%")
