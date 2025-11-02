-- AdminCommands.luau
-- Server-side admin commands system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Admin user IDs (REPLACE WITH ACTUAL ADMIN USER IDs)
local ADMIN_IDS = {
    -- Add admin user IDs here, for example:
    -- 12345678,  -- Admin1 username
    -- 87654321,  -- Admin2 username
    -- To find user ID: https://www.roblox.com/users/USERNAME/profile (look at URL number)
}

-- Owner ID (REPLACE WITH ACTUAL OWNER USER ID)
local OWNER_ID = 3389224707 -- Replace with actual owner user ID

-- Create RemoteEvents folder if it doesn't exist
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
    remoteEventsFolder = Instance.new("Folder")
    remoteEventsFolder.Name = "RemoteEvents"
    remoteEventsFolder.Parent = ReplicatedStorage
end

-- Create remote events for admin commands
local adminCommandRemote = remoteEventsFolder:FindFirstChild("AdminCommand")
if not adminCommandRemote then
    adminCommandRemote = Instance.new("RemoteEvent")
    adminCommandRemote.Name = "AdminCommand"
    adminCommandRemote.Parent = remoteEventsFolder
end

local rouletteUpdateRemote = remoteEventsFolder:FindFirstChild("RouletteUpdate")
if not rouletteUpdateRemote then
    rouletteUpdateRemote = Instance.new("RemoteEvent")
    rouletteUpdateRemote.Name = "RouletteUpdate"
    rouletteUpdateRemote.Parent = remoteEventsFolder
end

local AdminCommands = {}

-- Check if player is admin
local function isAdmin(player)
    return table.find(ADMIN_IDS, player.UserId) ~= nil
end

-- Check if player is owner
local function isOwner(player)
    return player.UserId == OWNER_ID
end

-- State tracking
local inversionActive = false
local inversionStartTime = 0
local rouletteActive = false
local rouletteData = {}

-- BANANA INVERSION COMMAND (/invert)
local function executeInvert(adminPlayer)
    if inversionActive then
        return "❌ Banana Inversion is already active!"
    end
    
    inversionActive = true
    inversionStartTime = tick()
    
    -- Notify all players
    for _, player in pairs(Players:GetPlayers()) do
        adminCommandRemote:FireClient(player, "invert_start", {
            admin = adminPlayer.Name,
            duration = 60
        })
    end
    
    -- Apply inversion effects
    
    -- 1. Flip all seed prices (make expensive seeds cheap and vice versa)
    if _G.SeedSystem then
        _G.SeedSystem.invertPrices()
    end
    
    -- 2. Reverse selling values (bananas now cost money to sell)
    if _G.SellingSystem then
        _G.SellingSystem.invertValues()
    end
    
    -- 3. Make sprinklers drain money instead of providing benefits
    if _G.SprinklerSystem then
        _G.SprinklerSystem.invertEffects()
    end
    
    -- 4. Reverse coin rewards (quests now cost money)
    if _G.CoinSystem then
        _G.CoinSystem.invertRewards()
    end
    
    -- 5. Visual effects - invert colors gradually
    local originalBrightness = Lighting.Brightness
    local originalColorShift = Lighting.ColorShift_Top
    
    local inversionTween = TweenService:Create(Lighting, 
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
        {
            Brightness = -originalBrightness,
            ColorShift_Top = Color3.fromRGB(255 - originalColorShift.R * 255, 
                                          255 - originalColorShift.G * 255, 
                                          255 - originalColorShift.B * 255)
        }
    )
    inversionTween:Play()
    
    -- 6. Create dramatic sound effect
    local inversionSound = Instance.new("Sound")
    inversionSound.SoundId = "rbxassetid://131961136" -- Dramatic sound
    inversionSound.Volume = 0.5
    inversionSound.Parent = workspace
    inversionSound:Play()
    
    -- Auto-revert after 60 seconds
    wait(60)
    
    -- Revert all effects
    inversionActive = false
    
    -- Revert game systems
    if _G.SeedSystem then
        _G.SeedSystem.revertPrices()
    end
    if _G.SellingSystem then
        _G.SellingSystem.revertValues()
    end
    if _G.SprinklerSystem then
        _G.SprinklerSystem.revertEffects()
    end
    if _G.CoinSystem then
        _G.CoinSystem.revertRewards()
    end
    
    -- Revert lighting
    local revertTween = TweenService:Create(Lighting, 
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
        {
            Brightness = originalBrightness,
            ColorShift_Top = originalColorShift
        }
    )
    revertTween:Play()
    
    -- Notify players that inversion ended
    for _, player in pairs(Players:GetPlayers()) do
        adminCommandRemote:FireClient(player, "invert_end", {})
    end
    
    -- Clean up sound
    inversionSound:Destroy()
    
    return "✅ Banana Inversion completed!"
end

-- BANANA ROULETTE COMMAND (/roulette)
local function executeRoulette(ownerPlayer)
    if not isOwner(ownerPlayer) then
        return "❌ Only the owner can start Banana Roulette!"
    end
    
    if rouletteActive then
        return "❌ Banana Roulette is already active!"
    end
    
    local activePlayers = Players:GetPlayers()
    if #activePlayers < 2 then
        return "❌ Need at least 2 players for Banana Roulette!"
    end
    
    rouletteActive = true
    rouletteData = {
        participants = {},
        bananas = {"🍌", "💥", "🍌", "🍌", "🍌", "🍌"}, -- 5 safe, 1 explosive
        currentRound = 1,
        eliminated = {},
        prizes = {
            winner = 50000,
            participation = 5000
        }
    }
    
    -- Add all players as participants
    for _, player in pairs(activePlayers) do
        table.insert(rouletteData.participants, player)
    end
    
    -- Notify all players that roulette is starting
    for _, player in pairs(Players:GetPlayers()) do
        adminCommandRemote:FireClient(player, "roulette_start", {
            participants = rouletteData.participants,
            host = ownerPlayer.Name
        })
    end
    
    -- Create dramatic atmosphere
    local rouletteMusic = Instance.new("Sound")
    rouletteMusic.SoundId = "rbxassetid://1841647093" -- Suspenseful music
    rouletteMusic.Volume = 0.3
    rouletteMusic.Looped = true
    rouletteMusic.Parent = workspace
    rouletteMusic:Play()
    
    -- Dim lighting for dramatic effect
    local originalBrightness = Lighting.Brightness
    local dimTween = TweenService:Create(Lighting, 
        TweenInfo.new(3, Enum.EasingStyle.Sine), 
        {Brightness = 0.5}
    )
    dimTween:Play()
    
    -- Teleport all players to a central location
    local centerPosition = Vector3.new(0, 100, 0) -- Adjust to your game's coordinates
    for i, player in ipairs(rouletteData.participants) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            -- Create seats in a circle
            local angle = (2 * math.pi / #rouletteData.participants) * (i - 1)
            local radius = 20
            local position = centerPosition + Vector3.new(
                math.cos(angle) * radius,
                0,
                math.sin(angle) * radius
            )
            
            player.Character.HumanoidRootPart.CFrame = CFrame.new(position)
            
            -- Create a seat for the player
            local seat = Instance.new("Seat")
            seat.Size = Vector3.new(4, 1, 4)
            seat.Position = position
            seat.Anchored = true
            seat.BrickColor = BrickColor.new("Bright yellow")
            seat.Parent = workspace
            
            -- Label the seat with player name
            local gui = Instance.new("SurfaceGui")
            gui.Parent = seat
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.Text = player.Name
            label.BackgroundTransparency = 1
            label.TextScaled = true
            label.Font = Enum.Font.SourceSansBold
            label.TextColor3 = Color3.new(0, 0, 0)
            label.Parent = gui
            
            -- Force player to sit
            if player.Character:FindFirstChild("Humanoid") then
                seat:Sit(player.Character.Humanoid)
            end
        end
    end
    
    wait(5) -- Let players get seated
    
    -- Start the elimination rounds
    while #rouletteData.participants > 1 and rouletteActive do
        -- Shuffle bananas
        local bananas = rouletteData.bananas
        for i = #bananas, 2, -1 do
            local j = math.random(i)
            bananas[i], bananas[j] = bananas[j], bananas[i]
        end
        
        -- Show round start
        for _, player in pairs(Players:GetPlayers()) do
            rouletteUpdateRemote:FireClient(player, "round_start", {
                round = rouletteData.currentRound,
                participants = rouletteData.participants
            })
        end
        
        wait(3)
        
        -- Each participant picks a banana
        local picks = {}
        for i, participant in ipairs(rouletteData.participants) do
            local bananaIndex = ((i - 1) % #bananas) + 1
            picks[participant] = {
                banana = bananas[bananaIndex],
                index = bananaIndex
            }
            
            -- Show dramatic selection
            for _, player in pairs(Players:GetPlayers()) do
                rouletteUpdateRemote:FireClient(player, "banana_select", {
                    participant = participant.Name,
                    banana = bananas[bananaIndex]
                })
            end
            
            wait(2) -- Dramatic pause between selections
        end
        
        -- Find who got the explosive banana
        local eliminated = nil
        for participant, pick in pairs(picks) do
            if pick.banana == "💥" then
                eliminated = participant
                break
            end
        end
        
        if eliminated then
            -- Dramatic elimination
            for _, player in pairs(Players:GetPlayers()) do
                rouletteUpdateRemote:FireClient(player, "elimination", {
                    eliminated = eliminated.Name
                })
            end
            
            -- Explosion effect at eliminated player's position
            if eliminated.Character and eliminated.Character:FindFirstChild("HumanoidRootPart") then
                local explosion = Instance.new("Explosion")
                explosion.Position = eliminated.Character.HumanoidRootPart.Position
                explosion.BlastRadius = 0 -- Visual only
                explosion.BlastPressure = 0
                explosion.Parent = workspace
                
                -- Dramatic sound
                local explosionSound = Instance.new("Sound")
                explosionSound.SoundId = "rbxassetid://131961136"
                explosionSound.Volume = 0.7
                explosionSound.Parent = workspace
                explosionSound:Play()
                Debris:AddItem(explosionSound, 3)
            end
            
            -- Remove from participants
            for i, participant in ipairs(rouletteData.participants) do
                if participant == eliminated then
                    table.remove(rouletteData.participants, i)
                    break
                end
            end
            
            table.insert(rouletteData.eliminated, eliminated)
            
            -- Award participation prize
            if _G.CoinSystem then
                _G.CoinSystem.addCoins(eliminated, rouletteData.prizes.participation)
            end
        else
            -- No one was eliminated this round (safety round)
            for _, player in pairs(Players:GetPlayers()) do
                rouletteUpdateRemote:FireClient(player, "safe_round", {})
            end
        end
        
        rouletteData.currentRound = rouletteData.currentRound + 1
        wait(5) -- Break between rounds
    end
    
    -- Declare winner
    local winner = rouletteData.participants[1]
    if winner then
        for _, player in pairs(Players:GetPlayers()) do
            rouletteUpdateRemote:FireClient(player, "winner", {
                winner = winner.Name,
                prize = rouletteData.prizes.winner
            })
        end
        
        -- Award winner prize
        if _G.CoinSystem then
            _G.CoinSystem.addCoins(winner, rouletteData.prizes.winner)
        end
        
        -- Award special title
        if _G.PlayerTitleSystem then
            _G.PlayerTitleSystem.awardTitle(winner, "Roulette Champion")
        end
        
        -- Victory effect
        if winner.Character and winner.Character:FindFirstChild("HumanoidRootPart") then
            -- Confetti effect
            for i = 1, 20 do
                local confetti = Instance.new("Part")
                confetti.Size = Vector3.new(0.2, 0.2, 0.2)
                confetti.Position = winner.Character.HumanoidRootPart.Position + Vector3.new(0, 10, 0)
                confetti.BrickColor = BrickColor.Random()
                confetti.Shape = Enum.PartType.Ball
                confetti.Parent = workspace
                
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                bodyVelocity.Velocity = Vector3.new(
                    math.random(-20, 20),
                    math.random(5, 15),
                    math.random(-20, 20)
                )
                bodyVelocity.Parent = confetti
                
                Debris:AddItem(confetti, 5)
            end
        end
    end
    
    -- Clean up
    wait(10)
    rouletteActive = false
    rouletteData = {}
    
    -- Restore lighting
    local restoreTween = TweenService:Create(Lighting, 
        TweenInfo.new(3, Enum.EasingStyle.Sine), 
        {Brightness = originalBrightness}
    )
    restoreTween:Play()
    
    -- Stop music
    rouletteMusic:Stop()
    rouletteMusic:Destroy()
    
    -- Clean up seats
    for _, seat in pairs(workspace:GetChildren()) do
        if seat:IsA("Seat") and seat.BrickColor == BrickColor.new("Bright yellow") then
            seat:Destroy()
        end
    end
    
    return "✅ Banana Roulette completed!"
end

-- Handle chat commands
local function onPlayerChatted(player, message)
    if not isAdmin(player) then return end
    
    local command = string.lower(string.split(message, " ")[1])
    
    if command == "/invert" then
        local result = executeInvert(player)
        -- Send result back to admin
        adminCommandRemote:FireClient(player, "command_result", {message = result})
        
    elseif command == "/roulette" then
        spawn(function()
            local result = executeRoulette(player)
            adminCommandRemote:FireClient(player, "command_result", {message = result})
        end)
    end
end

-- Connect to all current players
for _, player in pairs(Players:GetPlayers()) do
    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)
end

-- Connect to new players
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)
end)

-- Make globally accessible
_G.AdminCommands = AdminCommands

print("👑 AdminCommands system loaded")

return AdminCommands
