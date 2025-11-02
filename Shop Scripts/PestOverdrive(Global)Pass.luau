-- PestOverdrive(Global)Pass.luau - Pest Overdrive Global Gamepass System
-- Triggers a cutscene of pests marching in (global - affects all servers)

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local MessagingService = game:GetService("MessagingService")

-- Configuration
local PEST_OVERDRIVE_GLOBAL_GAMEPASS_ID = 5 -- Set your actual gamepass ID
local CUTSCENE_DURATION = 20 -- 20 seconds (longer than server version)

-- Wait for pest system
repeat wait() until _G.PestSystem

-- Players with pest overdrive global
local playersWithPestOverdriveGlobal = {}

-- Load player's pest overdrive status
local function loadPestOverdriveStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, PEST_OVERDRIVE_GLOBAL_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithPestOverdriveGlobal[player.UserId] = true
        player:SetAttribute("PestOverdriveGlobal", true)
        print("🌍 Pest Overdrive (Global) enabled for " .. player.Name)
    else
        playersWithPestOverdriveGlobal[player.UserId] = false
        player:SetAttribute("PestOverdriveGlobal", false)
    end
end

-- Create massive global pest cutscene
local function createGlobalPestCutscene(triggerPlayer)
    print("🌍 Starting GLOBAL Pest Overdrive cutscene triggered by " .. triggerPlayer.Name)
    
    -- Create dramatic sky effects
    local lighting = game:GetService("Lighting")
    local originalAmbient = lighting.Ambient
    local originalBrightness = lighting.Brightness
    
    -- Darken the sky
    lighting.Ambient = Color3.fromRGB(100, 0, 0)
    lighting.Brightness = 0.5
    
    -- Create global pest swarm effects
    local cutsceneFolder = Instance.new("Folder")
    cutsceneFolder.Name = "GlobalPestOverdrive"
    cutsceneFolder.Parent = workspace
    
    -- Create massive swarm of pests across the entire map
    local pestCount = 1000 -- 1000 pests per server
    
    for i = 1, pestCount do
        local pest = Instance.new("Part")
        pest.Name = "GlobalPest" .. i
        pest.Size = Vector3.new(0.5, 0.5, 0.5) -- Small like ants
        pest.Shape = Enum.PartType.Ball
        pest.Material = Enum.Material.Plastic
        pest.BrickColor = BrickColor.new("Really black") -- Black like ants
        pest.Anchored = true
        pest.CanCollide = false
        pest.Parent = cutsceneFolder
        
        -- Random positions across the entire map
        local startPosition = Vector3.new(
            math.random(-500, 500),
            math.random(50, 100),
            math.random(-500, 500)
        )
        local endPosition = Vector3.new(
            math.random(-500, 500),
            math.random(50, 100),
            math.random(-500, 500)
        )
        pest.Position = startPosition
        
        -- Add subtle glow to make them visible
        local pointLight = Instance.new("PointLight")
        pointLight.Color = Color3.fromRGB(50, 0, 0)
        pointLight.Brightness = 0.8
        pointLight.Range = 4
        pointLight.Parent = pest
        
        -- Create chaotic movement animation
        local moveTween = TweenService:Create(pest, 
            TweenInfo.new(CUTSCENE_DURATION, Enum.EasingStyle.Sine), 
            {Position = endPosition}
        )
        
        -- Add spinning effect
        local spinTween = TweenService:Create(pest, 
            TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), 
            {Rotation = Vector3.new(360, 360, 360)}
        )
        
        -- Start animations with random delays
        spawn(function()
            wait(math.random() * 3)
            moveTween:Play()
            spinTween:Play()
        end)
    end
    
    -- Add apocalyptic sound effect
    local globalSound = Instance.new("Sound")
    globalSound.SoundId = "rbxassetid://0" -- Add your apocalyptic sound ID
    globalSound.Volume = 0.8
    globalSound.Parent = workspace
    globalSound:Play()
    
    -- Send message to ALL servers via MessagingService
    pcall(function()
        MessagingService:PublishAsync("GlobalPestOverdrive", {
            triggerPlayer = triggerPlayer.Name,
            timestamp = tick()
        })
    end)
    
    -- Restore lighting after cutscene
    spawn(function()
        wait(CUTSCENE_DURATION)
        local restoreTween = TweenService:Create(lighting, 
            TweenInfo.new(3, Enum.EasingStyle.Quad), 
            {Ambient = originalAmbient, Brightness = originalBrightness}
        )
        restoreTween:Play()
    end)
    
    -- Clean up after cutscene
    Debris:AddItem(cutsceneFolder, CUTSCENE_DURATION + 5)
    Debris:AddItem(globalSound, CUTSCENE_DURATION)
    
    -- Send massive notification to all players
    for _, player in ipairs(Players:GetPlayers()) do
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "🌍 GLOBAL PEST APOCALYPSE!";
                Text = triggerPlayer.Name .. " triggered a GLOBAL pest invasion!";
                Duration = 8;
            })
        end)
    end
    
    -- Send dramatic chat announcement
    local chatMessage = "🌍🐛 " .. triggerPlayer.Name .. " triggered GLOBAL PEST OVERDRIVE! THE WORLD IS UNDER SIEGE! 🐛🌍"
    for _, p in ipairs(Players:GetPlayers()) do
        pcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = chatMessage;
                Color = Color3.fromRGB(255, 0, 0);
                Font = Enum.Font.GothamBold;
                FontSize = Enum.FontSize.Size24;
            })
        end)
    end
end

-- Listen for global pest overdrive messages from other servers
pcall(function()
    MessagingService:SubscribeAsync("GlobalPestOverdrive", function(message)
        local data = message.Data
        local chatMessage = "🌍 GLOBAL ALERT: " .. data.triggerPlayer .. " triggered pest overdrive in another server! 🌍"
        
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function()
                StarterGui:SetCore("ChatMakeSystemMessage", {
                    Text = chatMessage;
                    Color = Color3.fromRGB(255, 100, 0);
                    Font = Enum.Font.GothamBold;
                    FontSize = Enum.FontSize.Size18;
                })
            end)
        end
    end)
end)

-- Trigger global pest overdrive
local function triggerGlobalPestOverdrive(player)
    if not playersWithPestOverdriveGlobal[player.UserId] then
        return false, "You don't own Pest Overdrive (Global)!"
    end
    
    -- Create the massive global cutscene
    createGlobalPestCutscene(player)
    
    -- Spawn massive pest invasion on ALL plots
    if _G.PestSystem and _G.PestSystem.spawnPest then
        spawn(function()
            for _, p in ipairs(Players:GetPlayers()) do
                for i = 1, 15 do -- 15 pests per player for global version
                    _G.PestSystem.spawnPest(p, "Pest")
                    wait(0.3)
                end
            end
        end)
    end
    
    print("🌍 " .. player.Name .. " triggered GLOBAL Pest Overdrive!")
    return true, "GLOBAL Pest Overdrive activated! The world trembles!"
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == PEST_OVERDRIVE_GLOBAL_GAMEPASS_ID and wasPurchased then
        playersWithPestOverdriveGlobal[player.UserId] = true
        player:SetAttribute("PestOverdriveGlobal", true)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "🌍 GLOBAL Pest Overdrive Activated!";
            Text = "You can now trigger GLOBAL pest apocalypse!";
            Duration = 6;
        })
        
        -- Send chat message
        local chatMessage = "🌍 " .. player.Name .. " bought GLOBAL Pest Overdrive! They can trigger worldwide pest invasions! 🌍"
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                StarterGui:SetCore("ChatMakeSystemMessage", {
                    Text = chatMessage;
                    Color = Color3.fromRGB(255, 0, 0);
                    Font = Enum.Font.GothamBold;
                    FontSize = Enum.FontSize.Size20;
                })
            end)
        end
        
        print("🎉 " .. player.Name .. " purchased GLOBAL Pest Overdrive gamepass!")
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2)
    loadPestOverdriveStatus(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playersWithPestOverdriveGlobal[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadPestOverdriveStatus(player)
    end)
end

-- Global access
_G.PestOverdriveGlobalPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, PEST_OVERDRIVE_GLOBAL_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithPestOverdriveGlobal[player.UserId] or false
    end,
    triggerGlobalOverdrive = triggerGlobalPestOverdrive,
    GAMEPASS_ID = PEST_OVERDRIVE_GLOBAL_GAMEPASS_ID
}

print("🌍 GLOBAL Pest Overdrive Gamepass System initialized!")
print("💰 Gamepass ID: " .. PEST_OVERDRIVE_GLOBAL_GAMEPASS_ID .. " (remember to set the actual ID)")
print("🎬 Cutscene Duration: " .. CUTSCENE_DURATION .. " seconds")
print("⚠️ This affects ALL servers via MessagingService!")
