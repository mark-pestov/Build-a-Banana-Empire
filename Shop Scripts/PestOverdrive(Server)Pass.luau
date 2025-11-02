-- PestOverdrive(Server)Pass.luau - Pest Overdrive Server Gamepass System
-- Triggers a cutscene of pests marching in (server only)

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local PEST_OVERDRIVE_SERVER_GAMEPASS_ID = 4 -- Set your actual gamepass ID
local CUTSCENE_DURATION = 15 -- 15 seconds

-- Wait for pest system
repeat wait() until _G.PestSystem

-- Players with pest overdrive server
local playersWithPestOverdriveServer = {}

-- Load player's pest overdrive status
local function loadPestOverdriveStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, PEST_OVERDRIVE_SERVER_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithPestOverdriveServer[player.UserId] = true
        player:SetAttribute("PestOverdriveServer", true)
        print("🐛 Pest Overdrive (Server) enabled for " .. player.Name)
    else
        playersWithPestOverdriveServer[player.UserId] = false
        player:SetAttribute("PestOverdriveServer", false)
    end
end

-- Create marching pest cutscene
local function createPestCutscene(triggerPlayer)
    print("🐛 Starting Pest Overdrive cutscene triggered by " .. triggerPlayer.Name)
    
    -- Get player's plot
    local plotId = _G.PlotSystem.getPlayerPlot and _G.PlotSystem.getPlayerPlot(triggerPlayer)
    if not plotId then return end
    
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return end
    
    local plotModel = plotsFolder:FindFirstChild("Plot_" .. plotId)
    if not plotModel then return end
    
    -- Create cutscene effects
    local cutsceneFolder = Instance.new("Folder")
    cutsceneFolder.Name = "PestOverdriveCutscene"
    cutsceneFolder.Parent = plotModel
    
    -- Create multiple marching pests
    local pestCount = 1000 -- 1000 pests per server
    
    for i = 1, pestCount do
        local pest = Instance.new("Part")
        pest.Name = "MarchingPest" .. i
        pest.Size = Vector3.new(0.5, 0.5, 0.5) -- Small like ants
        pest.Shape = Enum.PartType.Ball
        pest.Material = Enum.Material.Plastic
        pest.BrickColor = BrickColor.new("Really black") -- Black like ants
        pest.Anchored = true
        pest.CanCollide = false
        pest.Parent = cutsceneFolder
        
        -- Position pests in multiple lines across the map
        local row = math.floor(i / 50)
        local col = i % 50
        local startPosition = Vector3.new(-200 + (col * 2), 2, -100 + (row * 3))
        local endPosition = Vector3.new(200 + (col * 2), 2, -100 + (row * 3))
        pest.Position = startPosition
        
        -- Add subtle glow to make them visible
        local pointLight = Instance.new("PointLight")
        pointLight.Color = Color3.fromRGB(50, 0, 0)
        pointLight.Brightness = 0.5
        pointLight.Range = 3
        pointLight.Parent = pest
        
        -- Create marching animation
        local marchTween = TweenService:Create(pest, 
            TweenInfo.new(CUTSCENE_DURATION, Enum.EasingStyle.Linear), 
            {Position = endPosition}
        )
        
        -- Start march with delay
        spawn(function()
            wait(i * 0.5) -- Stagger the start times
            marchTween:Play()
        end)
    end
    
    -- Add dramatic music/sound effect (you can add sound here)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://0" -- Add your dramatic sound ID
    sound.Volume = 0.5
    sound.Parent = plotModel
    sound:Play()
    
    -- Clean up after cutscene
    Debris:AddItem(cutsceneFolder, CUTSCENE_DURATION + 5)
    Debris:AddItem(sound, CUTSCENE_DURATION)
    
    -- Send notification to all players in server
    for _, player in ipairs(Players:GetPlayers()) do
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "🐛 PEST OVERDRIVE!";
                Text = triggerPlayer.Name .. " triggered a pest invasion!";
                Duration = 5;
            })
        end)
    end
    
    -- Send chat announcement
    local chatMessage = "🐛 " .. triggerPlayer.Name .. " triggered PEST OVERDRIVE! Pests are marching! 🐛"
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
end

-- Trigger pest overdrive
local function triggerPestOverdrive(player)
    if not playersWithPestOverdriveServer[player.UserId] then
        return false, "You don't own Pest Overdrive (Server)!"
    end
    
    -- Create the cutscene
    createPestCutscene(player)
    
    -- Spawn extra pests on player's plot
    if _G.PestSystem and _G.PestSystem.spawnPest then
        spawn(function()
            for i = 1, 10 do
                _G.PestSystem.spawnPest(player, "Pest")
                wait(1)
            end
        end)
    end
    
    print("🐛 " .. player.Name .. " triggered Pest Overdrive (Server)")
    return true, "Pest Overdrive cutscene started!"
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == PEST_OVERDRIVE_SERVER_GAMEPASS_ID and wasPurchased then
        playersWithPestOverdriveServer[player.UserId] = true
        player:SetAttribute("PestOverdriveServer", true)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "🐛 Pest Overdrive (Server) Activated!";
            Text = "You can now trigger epic pest cutscenes!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "🐛 " .. player.Name .. " bought Pest Overdrive (Server)! They can trigger pest invasions! 🐛"
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
        
        print("🎉 " .. player.Name .. " purchased Pest Overdrive (Server) gamepass!")
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
    playersWithPestOverdriveServer[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadPestOverdriveStatus(player)
    end)
end

-- Global access
_G.PestOverdriveServerPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, PEST_OVERDRIVE_SERVER_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithPestOverdriveServer[player.UserId] or false
    end,
    triggerOverdrive = triggerPestOverdrive,
    GAMEPASS_ID = PEST_OVERDRIVE_SERVER_GAMEPASS_ID
}

print("🐛 Pest Overdrive (Server) Gamepass System initialized!")
print("💰 Gamepass ID: " .. PEST_OVERDRIVE_SERVER_GAMEPASS_ID .. " (remember to set the actual ID)")
print("🎬 Cutscene Duration: " .. CUTSCENE_DURATION .. " seconds")
