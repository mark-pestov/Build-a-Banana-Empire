-- ScrewdriverTool.luau (formerly TrowelSeedRemoval.luau)
-- Used for advanced building adjustments in the city/empire game

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local StarterPack = game:GetService("StarterPack")

-- Configuration
local RARITY_HIERARCHY = {
    ["Common"] = 1,
    ["Uncommon"] = 2, 
    ["Rare"] = 3,
    ["Epic"] = 4,
    ["Legendary"] = 5,
    ["Mythical"] = 6,
    ["Divine"] = 7,
    ["Celestial"] = 8
}

local MYTHICAL_THRESHOLD = 6 -- Mythical and above require confirmation

-- Get RemoteEvents
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")

local removePlantRemote = remoteEventsFolder:FindFirstChild("RemovePlant")
if not removePlantRemote then
    removePlantRemote = Instance.new("RemoteEvent")
    removePlantRemote.Name = "RemovePlant"
    removePlantRemote.Parent = remoteEventsFolder
end

local confirmRemovalRemote = remoteEventsFolder:FindFirstChild("ConfirmRemoval")
if not confirmRemovalRemote then
    confirmRemovalRemote = Instance.new("RemoteEvent")
    confirmRemovalRemote.Name = "ConfirmRemoval"
    confirmRemovalRemote.Parent = remoteEventsFolder
end

-- Create confirmation GUI
local function createConfirmationGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "PlantRemovalConfirmation"
    gui.ResetOnSpawn = false
    
    -- Background blur
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.BorderSizePixel = 0
    background.Visible = false
    background.Parent = gui
    
    -- Main confirmation frame
    local confirmFrame = Instance.new("Frame")
    confirmFrame.Name = "ConfirmFrame"
    confirmFrame.Size = UDim2.new(0, 400, 0, 200)
    confirmFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
    confirmFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    confirmFrame.BorderSizePixel = 3
    confirmFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    confirmFrame.Parent = background
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = confirmFrame
    
    -- Warning icon
    local warningIcon = Instance.new("TextLabel")
    warningIcon.Name = "WarningIcon"
    warningIcon.Size = UDim2.new(0, 40, 0, 40)
    warningIcon.Position = UDim2.new(0, 20, 0, 20)
    warningIcon.BackgroundTransparency = 1
    warningIcon.Text = "⚠️"
    warningIcon.TextColor3 = Color3.fromRGB(255, 255, 0)
    warningIcon.TextScaled = true
    warningIcon.Font = Enum.Font.SourceSansBold
    warningIcon.Parent = confirmFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -80, 0, 30)
    title.Position = UDim2.new(0, 70, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "CONFIRM PLANT REMOVAL"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = confirmFrame
    
    -- Plant info
    local plantInfo = Instance.new("TextLabel")
    plantInfo.Name = "PlantInfo"
    plantInfo.Size = UDim2.new(1, -40, 0, 60)
    plantInfo.Position = UDim2.new(0, 20, 0, 60)
    plantInfo.BackgroundTransparency = 1
    plantInfo.Text = "Are you sure you want to remove this plant?\n\nThis plant is MYTHICAL rarity!"
    plantInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    plantInfo.TextScaled = true
    plantInfo.Font = Enum.Font.SourceSans
    plantInfo.TextWrapped = true
    plantInfo.Parent = confirmFrame
    
    -- Button frame
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "ButtonFrame"
    buttonFrame.Size = UDim2.new(1, -40, 0, 40)
    buttonFrame.Position = UDim2.new(0, 20, 1, -60)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = confirmFrame
    
    -- Yes button
    local yesButton = Instance.new("TextButton")
    yesButton.Name = "YesButton"
    yesButton.Size = UDim2.new(0, 80, 1, 0)
    yesButton.Position = UDim2.new(0, 0, 0, 0)
    yesButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    yesButton.BorderSizePixel = 2
    yesButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    yesButton.Text = "YES"
    yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    yesButton.TextScaled = true
    yesButton.Font = Enum.Font.SourceSansBold
    yesButton.Parent = buttonFrame
    
    local yesCorner = Instance.new("UICorner")
    yesCorner.CornerRadius = UDim.new(0, 5)
    yesCorner.Parent = yesButton
    
    -- No button
    local noButton = Instance.new("TextButton")
    noButton.Name = "NoButton"
    noButton.Size = UDim2.new(0, 80, 1, 0)
    noButton.Position = UDim2.new(1, -80, 0, 0)
    noButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    noButton.BorderSizePixel = 2
    noButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    noButton.Text = "NO"
    noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    noButton.TextScaled = true
    noButton.Font = Enum.Font.SourceSansBold
    noButton.Parent = buttonFrame
    
    local noCorner = Instance.new("UICorner")
    noCorner.CornerRadius = UDim.new(0, 5)
    noCorner.Parent = noButton
    
    gui.Parent = ReplicatedStorage
    return gui
end

-- Create enhanced trowel tool
local function createTrowelTool()
    local trowel = Instance.new("Tool")
    trowel.Name = "Trowel"
    trowel.RequiresHandle = true
    trowel.CanBeDropped = false
    
    -- Create handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.3, 2, 0.3)
    handle.Material = Enum.Material.Wood
    handle.BrickColor = BrickColor.new("Brown")
    handle.Parent = trowel
    
    -- Add metal blade
    local blade = Instance.new("Part")
    blade.Name = "Blade"
    blade.Size = Vector3.new(0.8, 0.1, 0.4)
    blade.Material = Enum.Material.Metal
    blade.BrickColor = BrickColor.new("Medium stone grey")
    blade.Parent = trowel
    
    -- Weld blade to handle
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = blade
    weld.Parent = handle
    
    -- Position blade at bottom of handle
    blade.CFrame = handle.CFrame * CFrame.new(0, -1.1, 0)
    
    -- Add LocalScript for trowel functionality
    local trowelScript = Instance.new("LocalScript")
    trowelScript.Name = "TrowelScript"
    trowelScript.Source = [[
        local tool = script.Parent
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local TweenService = game:GetService("TweenService")
        
        local player = Players.LocalPlayer
        local mouse = player:GetMouse()
        
        -- Get RemoteEvents
        local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
        local removePlantRemote = remoteEvents:WaitForChild("RemovePlant")
        
        -- Visual indicator
        local indicator = nil
        local indicatorConnection = nil
        
        -- Create removal indicator
        local function createIndicator()
            if indicator then return end
            
            indicator = Instance.new("Part")
            indicator.Name = "RemovalIndicator"
            indicator.Size = Vector3.new(3, 0.2, 3)
            indicator.Material = Enum.Material.Neon
            indicator.Anchored = true
            indicator.CanCollide = false
            indicator.Shape = Enum.PartType.Cylinder
            indicator.Transparency = 0.5
            indicator.Parent = workspace
            
            -- Spinning animation
            local spinConnection
            spinConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if indicator and indicator.Parent then
                    indicator.CFrame = indicator.CFrame * CFrame.Angles(0, math.rad(2), 0)
                else
                    spinConnection:Disconnect()
                end
            end)
        end
        
        -- Update indicator
        local function updateIndicator()
            if not indicator then return end
            
            local target = mouse.Target
            if target and target.Parent and target.Parent:FindFirstChild("PlantType") then
                local plantModel = target.Parent
                local rarity = plantModel:FindFirstChild("Rarity")
                
                if rarity then
                    local rarityValue = rarity.Value
                    -- Color based on rarity
                    if rarityValue == "Common" then
                        indicator.Color = Color3.fromRGB(0, 255, 0)
                    elseif rarityValue == "Rare" then
                        indicator.Color = Color3.fromRGB(0, 0, 255)
                    elseif rarityValue == "Epic" then
                        indicator.Color = Color3.fromRGB(128, 0, 128)
                    elseif rarityValue == "Mythical" then
                        indicator.Color = Color3.fromRGB(255, 165, 0)
                    else
                        indicator.Color = Color3.fromRGB(255, 255, 255)
                    end
                else
                    indicator.Color = Color3.fromRGB(255, 255, 255)
                end
                
                -- Position indicator
                local rootPart = plantModel:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    indicator.Position = rootPart.Position + Vector3.new(0, 2, 0)
                else
                    indicator.Position = target.Position + Vector3.new(0, 2, 0)
                end
                
                indicator.Transparency = 0.3
            else
                indicator.Position = mouse.Hit.Position + Vector3.new(0, 1, 0)
                indicator.Color = Color3.fromRGB(100, 100, 100)
                indicator.Transparency = 0.8
            end
        end
        
        -- Tool equipped
        tool.Equipped:Connect(function()
            createIndicator()
            indicatorConnection = game:GetService("RunService").Heartbeat:Connect(updateIndicator)
            mouse.Icon = "rbxasset://textures/ArrowCursor.png"
        end)
        
        -- Tool unequipped
        tool.Unequipped:Connect(function()
            if indicator then
                indicator:Destroy()
                indicator = nil
            end
            if indicatorConnection then
                indicatorConnection:Disconnect()
                indicatorConnection = nil
            end
            mouse.Icon = ""
        end)
        
        -- Tool activated
        tool.Activated:Connect(function()
            local target = mouse.Target
            
            if target and target.Parent and target.Parent:FindFirstChild("PlantType") then
                local plantModel = target.Parent
                
                -- Visual effect
                local effect = Instance.new("Part")
                effect.Name = "RemovalEffect"
                effect.Size = Vector3.new(1, 1, 1)
                effect.Material = Enum.Material.Neon
                effect.Color = Color3.fromRGB(255, 255, 0)
                effect.Shape = Enum.PartType.Ball
                effect.Anchored = true
                effect.CanCollide = false
                effect.Parent = workspace
                
                local rootPart = plantModel:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    effect.Position = rootPart.Position
                else
                    effect.Position = target.Position
                end
                
                -- Animate effect
                local tween = TweenService:Create(
                    effect,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Size = Vector3.new(4, 4, 4),
                        Transparency = 1
                    }
                )
                tween:Play()
                
                tween.Completed:Connect(function()
                    effect:Destroy()
                end)
                
                -- Send removal request
                removePlantRemote:FireServer(plantModel)
                
                -- Play digging sound
                local sound = Instance.new("Sound")
                sound.SoundId = "rbxasset://sounds/impact_generic.mp3"
                sound.Volume = 0.6
                sound.Pitch = 1.2
                sound.Parent = player.Character and player.Character:FindFirstChild("Head") or workspace
                sound:Play()
                
                game:GetService("Debris"):AddItem(sound, 2)
            end
        end)
    ]]
    trowelScript.Parent = trowel
    
    return trowel
end

-- Get plant rarity level
local function getRarityLevel(rarity)
    return RARITY_HIERARCHY[rarity] or 1
end

-- Check if plant needs confirmation
local function needsConfirmation(plantModel)
    local rarity = plantModel:FindFirstChild("Rarity")
    if not rarity then return false end
    
    local rarityLevel = getRarityLevel(rarity.Value)
    return rarityLevel >= MYTHICAL_THRESHOLD
end

-- Remove plant
local function removePlant(plantModel)
    if not plantModel or not plantModel.Parent then return false end
    
    -- Create removal particles
    local rootPart = plantModel:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local attachment = Instance.new("Attachment")
        attachment.Parent = rootPart
        
        local particles = Instance.new("ParticleEmitter")
        particles.Parent = attachment
        particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
        particles.Color = ColorSequence.new(Color3.fromRGB(139, 69, 19))
        particles.Lifetime = NumberRange.new(0.5, 1.5)
        particles.Rate = 100
        particles.SpreadAngle = Vector2.new(45, 45)
        particles.Speed = NumberRange.new(5, 15)
        
        -- Let particles emit for a bit
        wait(0.5)
        particles.Enabled = false
        Debris:AddItem(particles, 2)
    end
    
    -- Destroy plant
    plantModel:Destroy()
    return true
end

-- Handle plant removal request
removePlantRemote.OnServerEvent:Connect(function(player, plantModel)
    if not plantModel or not plantModel.Parent then return end
    
    print(player.Name .. " wants to remove plant: " .. plantModel.Name)
    
    -- Check if player owns the plot (basic validation)
    local plotModel = plantModel.Parent
    if not plotModel or not plotModel.Name:find("Plot_") then
        print("Plant not in a plot")
        return
    end
    
    -- Check if plant needs confirmation
    if needsConfirmation(plantModel) then
        local rarity = plantModel:FindFirstChild("Rarity")
        local rarityValue = rarity and rarity.Value or "Unknown"
        
        -- Send confirmation request to client
        confirmRemovalRemote:FireClient(player, plantModel, rarityValue)
    else
        -- Remove immediately for non-mythical plants
        if removePlant(plantModel) then
            print("Removed " .. plantModel.Name .. " for " .. player.Name)
        end
    end
end)

-- Handle confirmation response
confirmRemovalRemote.OnServerEvent:Connect(function(player, plantModel, confirmed)
    if not plantModel or not plantModel.Parent then return end
    
    if confirmed then
        if removePlant(plantModel) then
            print("Confirmed removal of " .. plantModel.Name .. " for " .. player.Name)
        end
    else
        print(player.Name .. " cancelled removal of " .. plantModel.Name)
    end
end)

-- Client-side confirmation GUI handler
confirmRemovalRemote.OnClientEvent:Connect(function(plantModel, rarity)
    local player = game.Players.LocalPlayer
    local playerGui = player.PlayerGui
    
    -- Get or create confirmation GUI
    local gui = playerGui:FindFirstChild("PlantRemovalConfirmation")
    if not gui then
        local template = game.ReplicatedStorage:FindFirstChild("PlantRemovalConfirmation")
        if template then
            gui = template:Clone()
            gui.Parent = playerGui
        else
            return
        end
    end
    
    local background = gui:FindFirstChild("Background")
    local confirmFrame = background:FindFirstChild("ConfirmFrame")
    local plantInfo = confirmFrame:FindFirstChild("PlantInfo")
    local yesButton = confirmFrame:FindFirstChild("ButtonFrame"):FindFirstChild("YesButton")
    local noButton = confirmFrame:FindFirstChild("ButtonFrame"):FindFirstChild("NoButton")
    
    -- Update plant info
    plantInfo.Text = "Are you sure you want to remove this plant?\n\nThis plant is " .. rarity:upper() .. " rarity!"
    
    -- Color the rarity text
    if rarity == "Mythical" then
        plantInfo.TextColor3 = Color3.fromRGB(255, 165, 0)
    elseif rarity == "Legendary" then
        plantInfo.TextColor3 = Color3.fromRGB(255, 215, 0)
    elseif rarity == "Divine" then
        plantInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        plantInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    
    -- Show GUI
    background.Visible = true
    
    -- Animate in
    confirmFrame.Position = UDim2.new(0.5, -200, 0.5, -300)
    local tween = game:GetService("TweenService"):Create(
        confirmFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -200, 0.5, -100)}
    )
    tween:Play()
    
    -- Button connections
    local connections = {}
    
    connections.yes = yesButton.MouseButton1Click:Connect(function()
        -- Animate out
        local outTween = game:GetService("TweenService"):Create(
            confirmFrame,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -200, 0.5, 300)}
        )
        outTween:Play()
        
        outTween.Completed:Connect(function()
            background.Visible = false
        end)
        
        -- Send confirmation
        game.ReplicatedStorage.RemoteEvents.ConfirmRemoval:FireServer(plantModel, true)
        
        -- Disconnect
        for _, connection in pairs(connections) do
            connection:Disconnect()
        end
    end)
    
    connections.no = noButton.MouseButton1Click:Connect(function()
        -- Animate out
        local outTween = game:GetService("TweenService"):Create(
            confirmFrame,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -200, 0.5, 300)}
        )
        outTween:Play()
        
        outTween.Completed:Connect(function()
            background.Visible = false
        end)
        
        -- Send cancellation
        game.ReplicatedStorage.RemoteEvents.ConfirmRemoval:FireServer(plantModel, false)
        
        -- Disconnect
        for _, connection in pairs(connections) do
            connection:Disconnect()
        end
    end)
end)

-- Give trowel to all players
local function giveTrowelToPlayer(player)
    local trowel = createTrowelTool()
    trowel.Parent = player.Backpack
    
    -- Also add to StarterPack so they get it on respawn
    local starterTrowel = trowel:Clone()
    starterTrowel.Parent = StarterPack
end

-- Handle players
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1) -- Wait for character to load
        giveTrowelToPlayer(player)
    end)
end)

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
        giveTrowelToPlayer(player)
    end
end

-- Create confirmation GUI template
createConfirmationGui()

print("🔨 Trowel Seed Removal System Loaded!")
print("   - Enhanced trowel tool with visual indicators")
print("   - Rarity-based confirmation system")
print("   - Instant removal for Common-Epic plants")
print("   - Confirmation required for Mythical+ plants")
print("   - Visual effects and animations")

-- DEPRECATED: Farming/seed logic removed for city/empire game.
return