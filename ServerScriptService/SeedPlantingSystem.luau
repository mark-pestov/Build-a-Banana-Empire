-- SeedPlantingSystem.luau - Handle Seed Planting Mechanics
-- Manages seed tool usage and planting validation

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Wait for required systems
repeat wait() until _G.SeedSystem

-- Get RemoteEvents
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local plantSeedRemote = remoteEventsFolder:WaitForChild("PlantSeed")

-- Create planting indicator remote
local plantingIndicatorRemote = remoteEventsFolder:FindFirstChild("PlantingIndicator")
if not plantingIndicatorRemote then
    plantingIndicatorRemote = Instance.new("RemoteEvent")
    plantingIndicatorRemote.Name = "PlantingIndicator"
    plantingIndicatorRemote.Parent = remoteEventsFolder
end

-- Client-side planting script (will be inserted into seed tools)
local clientPlantingScript = [[
local tool = script.Parent
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Get RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local plantSeedRemote = remoteEvents:WaitForChild("PlantSeed")
local plantingIndicatorRemote = remoteEvents:WaitForChild("PlantingIndicator")

-- Get seed type
local seedType = tool:WaitForChild("SeedType").Value

-- Visual indicator
local indicator = nil
local indicatorConnection = nil

-- Create planting indicator
local function createIndicator()
    if indicator then return end
    
    indicator = Instance.new("Part")
    indicator.Name = "PlantingIndicator"
    indicator.Size = Vector3.new(2, 0.1, 2)
    indicator.Material = Enum.Material.Neon
    indicator.Anchored = true
    indicator.CanCollide = false
    indicator.Shape = Enum.PartType.Cylinder
    indicator.Parent = workspace
    
    -- Make it glow
    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.fromRGB(0, 255, 0)
    pointLight.Brightness = 1
    pointLight.Range = 10
    pointLight.Parent = indicator
end

-- Update indicator position
local function updateIndicator()
    if not indicator then return end
    
    local target = mouse.Target
    if target and target.Name == "DirtPatch" then
        indicator.Position = mouse.Hit.Position + Vector3.new(0, 0.5, 0)
        indicator.Color = Color3.fromRGB(0, 255, 0) -- Green for valid
        indicator.Transparency = 0.3
    else
        indicator.Position = mouse.Hit.Position + Vector3.new(0, 0.5, 0)
        indicator.Color = Color3.fromRGB(255, 0, 0) -- Red for invalid
        indicator.Transparency = 0.7
    end
end

-- Tool equipped
tool.Equipped:Connect(function()
    createIndicator()
    
    -- Update indicator position
    indicatorConnection = RunService.Heartbeat:Connect(updateIndicator)
    
    -- Change mouse icon
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
    
    -- Reset mouse icon
    mouse.Icon = ""
end)

-- Tool activated (clicked)
tool.Activated:Connect(function()
    local target = mouse.Target
    
    if target and target.Name == "DirtPatch" then
        local position = mouse.Hit.Position
        
        -- Visual planting effect
        local effect = Instance.new("Part")
        effect.Name = "PlantingEffect"
        effect.Size = Vector3.new(1, 1, 1)
        effect.Position = position + Vector3.new(0, 1, 0)
        effect.Material = Enum.Material.Neon
        effect.Color = Color3.fromRGB(0, 255, 0)
        effect.Shape = Enum.PartType.Ball
        effect.Anchored = true
        effect.CanCollide = false
        effect.Parent = workspace
        
        -- Animate effect
        local tween = game:GetService("TweenService"):Create(
            effect,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = Vector3.new(3, 3, 3),
                Transparency = 1
            }
        )
        tween:Play()
        
        tween.Completed:Connect(function()
            effect:Destroy()
        end)
        
        -- Send planting request to server
        plantSeedRemote:FireServer(seedType, position)
        
        -- Play planting sound
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxasset://sounds/impact_generic.mp3"
        sound.Volume = 0.5
        sound.Parent = player.Character and player.Character:FindFirstChild("Head") or workspace
        sound:Play()
        
        game:GetService("Debris"):AddItem(sound, 2)
    else
        -- Invalid target - show error effect
        local errorEffect = Instance.new("Part")
        errorEffect.Size = Vector3.new(2, 0.1, 2)
        errorEffect.Position = mouse.Hit.Position + Vector3.new(0, 0.5, 0)
        errorEffect.Material = Enum.Material.Neon
        errorEffect.Color = Color3.fromRGB(255, 0, 0)
        errorEffect.Shape = Enum.PartType.Cylinder
        errorEffect.Anchored = true
        errorEffect.CanCollide = false
        errorEffect.Parent = workspace
        
        -- Flash effect
        for i = 1, 3 do
            errorEffect.Transparency = 0
            wait(0.1)
            errorEffect.Transparency = 1
            wait(0.1)
        end
        
        errorEffect:Destroy()
        
        -- Play error sound
        local errorSound = Instance.new("Sound")
        errorSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
        errorSound.Volume = 0.3
        errorSound.Pitch = 0.5
        errorSound.Parent = player.Character and player.Character:FindFirstChild("Head") or workspace
        errorSound:Play()
        
        game:GetService("Debris"):AddItem(errorSound, 2)
    end
end)
]]

-- Server-side planting validation
local function validatePlanting(player, seedType, position)
    -- Check if player has the seed
    local playerSeeds = _G.SeedSystem.getPlayerSeeds(player)
    if not playerSeeds[seedType] or playerSeeds[seedType] <= 0 then
        return false, "You don't have any " .. seedType .. " seeds!"
    end
    
    -- Check if player has a plot
    local plotId = nil
    if _G.PlotSystem and _G.PlotSystem.getPlayerPlot then
        plotId = _G.PlotSystem.getPlayerPlot(player)
    end
    
    if not plotId then
        return false, "You need to own a plot to plant seeds!"
    end
    
    -- Check if position is in dirt patch
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then
        return false, "No plots found!"
    end
    
    local plotModel = plotsFolder:FindFirstChild("Plot_" .. plotId)
    if not plotModel then
        return false, "Your plot doesn't exist!"
    end
    
    local dirtPatch = plotModel:FindFirstChild("DirtPatch")
    if not dirtPatch then
        return false, "No dirt patch found in your plot!"
    end
    
    -- Check distance to dirt patch
    local distance = (position - dirtPatch.Position).Magnitude
    local maxDistance = math.min(dirtPatch.Size.X, dirtPatch.Size.Z) / 2
    
    if distance > maxDistance then
        return false, "You must plant seeds in the dirt patch!"
    end
    
    return true, "Valid planting location"
end

-- Handle planting requests
plantSeedRemote.OnServerEvent:Connect(function(player, seedType, position)
    print("Planting request: " .. player.Name .. " wants to plant " .. seedType .. " at " .. tostring(position))
    
    local isValid, message = validatePlanting(player, seedType, position)
    
    if not isValid then
        -- Send error message to client
        plantingIndicatorRemote:FireClient(player, "error", message)
        return
    end
    
    -- Forward to growth system (which handles seed removal and tree creation)
    -- The growth system will validate again and handle the actual planting
end)

-- Client notification system
plantingIndicatorRemote.OnClientEvent:Connect(function(eventType, message)
    if eventType == "error" then
        -- Create error notification
        local gui = Instance.new("ScreenGui")
        gui.Parent = game.Players.LocalPlayer.PlayerGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 400, 0, 60)
        frame.Position = UDim2.new(0.5, -200, 0, 100)
        frame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
        frame.Parent = gui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, -10)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = "❌ " .. message
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.Font = Enum.Font.SourceSansBold
        label.Parent = frame
        
        -- Animate in
        frame.Position = UDim2.new(0.5, -200, 0, -70)
        local tween = game:GetService("TweenService"):Create(
            frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0.5, -200, 0, 100)}
        )
        tween:Play()
        
        -- Remove after 3 seconds
        game:GetService("Debris"):AddItem(gui, 3)
        
    elseif eventType == "success" then
        -- Create success notification
        local gui = Instance.new("ScreenGui")
        gui.Parent = game.Players.LocalPlayer.PlayerGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 50)
        frame.Position = UDim2.new(0.5, -150, 0, 50)
        frame.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
        frame.Parent = gui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, -10)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = "✅ " .. message
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.Font = Enum.Font.SourceSansBold
        label.Parent = frame
        
        game:GetService("Debris"):AddItem(gui, 2)
    end
end)

-- Update seed tools with planting script
local function updateSeedTools()
    local serverStorage = game:GetService("ServerStorage")
    local seedToolsFolder = serverStorage:FindFirstChild("SeedTools")
    
    if seedToolsFolder then
        for _, tool in pairs(seedToolsFolder:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("SeedType") then
                -- Remove old planting script
                local oldScript = tool:FindFirstChild("SeedPlantingScript")
                if oldScript then
                    oldScript:Destroy()
                end
                
                -- Add new planting script
                local newScript = Instance.new("LocalScript")
                newScript.Name = "SeedPlantingScript"
                newScript.Source = clientPlantingScript
                newScript.Parent = tool
                
                print("Updated planting script for " .. tool.Name)
            end
        end
    end
end

-- Initialize system
wait(2) -- Wait for SeedSystem to create tools
updateSeedTools()

-- Update existing players' tools
for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
        -- Update tools in backpack
        for _, tool in pairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("SeedType") then
                local oldScript = tool:FindFirstChild("SeedPlantingScript")
                if oldScript then
                    oldScript:Destroy()
                end
                
                local newScript = Instance.new("LocalScript")
                newScript.Name = "SeedPlantingScript"
                newScript.Source = clientPlantingScript
                newScript.Parent = tool
            end
        end
    end
end

print("🌱 Seed Planting System Loaded!")
print("   - Visual planting indicators")
print("   - Client-side validation and effects")
print("   - Server-side security validation")
print("   - Error and success notifications")

-- DEPRECATED: Farming/seed logic removed for city/empire game.
return