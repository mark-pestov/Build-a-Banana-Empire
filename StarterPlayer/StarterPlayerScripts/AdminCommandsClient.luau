-- AdminCommandsClient.luau
-- Client-side handler for admin command effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)

-- Wait for remote events
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteEventsFolder then
    warn("RemoteEvents folder not found")
    return
end

local adminCommandRemote = remoteEventsFolder:WaitForChild("AdminCommand", 10)
local rouletteUpdateRemote = remoteEventsFolder:WaitForChild("RouletteUpdate", 10)

local AdminCommandsClient = {}

-- Create notification GUI
local function createNotification(title, message, duration, color)
    duration = duration or 5
    color = color or Color3.fromRGB(255, 255, 255)
    
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "AdminNotification"
    notificationGui.ResetOnSpawn = false
    notificationGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 100)
    frame.Position = UDim2.new(0.5, -200, 0, -110)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.Parent = notificationGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 2
    stroke.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = color
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 0, 50)
    messageLabel.Position = UDim2.new(0, 10, 0, 40)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextWrapped = true
    messageLabel.Parent = frame
    
    -- Animate in
    local slideIn = TweenService:Create(frame, 
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {Position = UDim2.new(0.5, -200, 0, 20)}
    )
    slideIn:Play()
    
    -- Auto-dismiss after duration
    task.wait(duration)
    
    local slideOut = TweenService:Create(frame, 
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
        {Position = UDim2.new(0.5, -200, 0, -110)}
    )
    slideOut:Play()
    
    slideOut.Completed:Connect(function()
        notificationGui:Destroy()
    end)
end

-- Handle Banana Inversion effects
local function handleInvertStart(data)
    spawn(function()
        createNotification(
            "🔄 BANANA INVERSION ACTIVATED!",
            "Admin " .. data.admin .. " has inverted the banana economy for " .. data.duration .. " seconds!",
            5,
            Color3.fromRGB(255, 100, 100)
        )
    end)
    
    -- Screen flash effect
    local flashGui = Instance.new("ScreenGui")
    flashGui.Name = "InversionFlash"
    flashGui.Parent = playerGui
    
    local flashFrame = Instance.new("Frame")
    flashFrame.Size = UDim2.new(1, 0, 1, 0)
    flashFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    flashFrame.BackgroundTransparency = 1
    flashFrame.Parent = flashGui
    
    -- Flash animation
    local flashTween = TweenService:Create(flashFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true),
        {BackgroundTransparency = 0.7}
    )
    flashTween:Play()
    
    flashTween.Completed:Connect(function()
        flashGui:Destroy()
    end)
    
    -- Screen distortion effect (color inversion)
    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "InversionEffect"
    colorCorrection.Brightness = 0
    colorCorrection.Contrast = 0
    colorCorrection.Saturation = -1 -- Inverted colors
    colorCorrection.TintColor = Color3.fromRGB(255, 100, 100)
    colorCorrection.Parent = game.Lighting
    
    -- Gradually apply the effect
    local distortionTween = TweenService:Create(colorCorrection,
        TweenInfo.new(2, Enum.EasingStyle.Sine),
        {
            Saturation = -0.5,
            Brightness = -0.3,
            Contrast = 0.2
        }
    )
    distortionTween:Play()
end

local function handleInvertEnd()
    spawn(function()
        createNotification(
            "✅ BANANA INVERSION ENDED",
            "The banana economy has returned to normal!",
            3,
            Color3.fromRGB(100, 255, 100)
        )
    end)
    
    -- Remove screen effects
    local inversionEffect = game.Lighting:FindFirstChild("InversionEffect")
    if inversionEffect then
        local revertTween = TweenService:Create(inversionEffect,
            TweenInfo.new(2, Enum.EasingStyle.Sine),
            {
                Saturation = 0,
                Brightness = 0,
                Contrast = 0,
                TintColor = Color3.fromRGB(255, 255, 255)
            }
        )
        revertTween:Play()
        revertTween.Completed:Connect(function()
            inversionEffect:Destroy()
        end)
    end
end

-- Handle Banana Roulette effects
local rouletteGui = nil

local function createRouletteGUI()
    if rouletteGui then
        rouletteGui:Destroy()
    end
    
    rouletteGui = Instance.new("ScreenGui")
    rouletteGui.Name = "BananaRouletteGUI"
    rouletteGui.ResetOnSpawn = false
    rouletteGui.Parent = playerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = rouletteGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 215, 0)
    stroke.Thickness = 3
    stroke.Parent = mainFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 60)
    titleLabel.Position = UDim2.new(0, 0, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🎰 BANANA ROULETTE 🎰"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = mainFrame
    
    -- Content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -80)
    contentFrame.Position = UDim2.new(0, 10, 0, 70)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    return rouletteGui, contentFrame
end

local function handleRouletteStart(data)
    spawn(function()
        createNotification(
            "🎰 BANANA ROULETTE STARTED!",
            "Hosted by " .. data.host .. " • " .. #data.participants .. " participants",
            5,
            Color3.fromRGB(255, 215, 0)
        )
    end)
    
    local gui, contentFrame = createRouletteGUI()
    
    -- Show participants
    local participantsList = Instance.new("TextLabel")
    participantsList.Size = UDim2.new(1, 0, 0.6, 0)
    participantsList.Position = UDim2.new(0, 0, 0, 0)
    participantsList.BackgroundTransparency = 1
    participantsList.Text = "Participants:\n"
    participantsList.TextColor3 = Color3.fromRGB(255, 255, 255)
    participantsList.TextScaled = true
    participantsList.Font = Enum.Font.SourceSans
    participantsList.TextYAlignment = Enum.TextYAlignment.Top
    participantsList.Parent = contentFrame
    
    for _, participant in ipairs(data.participants) do
        participantsList.Text = participantsList.Text .. "• " .. participant.Name .. "\n"
    end
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0.4, 0)
    statusLabel.Position = UDim2.new(0, 0, 0.6, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Game starting soon..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSansBold
    statusLabel.Parent = contentFrame
end

local function handleRouletteRoundStart(data)
    if not rouletteGui then return end
    
    local contentFrame = rouletteGui:FindFirstChild("BananaRouletteGUI"):FindFirstChild("ContentFrame")
    local statusLabel = contentFrame:FindFirstChild("StatusLabel")
    
    if statusLabel then
        statusLabel.Text = "🎯 ROUND " .. data.round .. "\nPick your banana..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

local function handleBananaSelect(data)
    if not rouletteGui then return end
    
    local contentFrame = rouletteGui:FindFirstChild("BananaRouletteGUI"):FindFirstChild("ContentFrame")
    local statusLabel = contentFrame:FindFirstChild("StatusLabel")
    
    if statusLabel then
        statusLabel.Text = data.participant .. " selected: " .. data.banana
        
        -- Flash effect for dramatic tension
        local flashTween = TweenService:Create(statusLabel,
            TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true),
            {TextColor3 = Color3.fromRGB(255, 255, 255)}
        )
        flashTween:Play()
    end
end

local function handleElimination(data)
    if not rouletteGui then return end
    
    local contentFrame = rouletteGui:FindFirstChild("BananaRouletteGUI"):FindFirstChild("ContentFrame")
    local statusLabel = contentFrame:FindFirstChild("StatusLabel")
    
    if statusLabel then
        statusLabel.Text = "💥 " .. data.eliminated .. " IS ELIMINATED! 💥"
        statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        
        -- Dramatic shake effect
        local originalPosition = statusLabel.Position
        for i = 1, 10 do
            local offset = UDim2.new(0, math.random(-5, 5), 0, math.random(-5, 5))
            statusLabel.Position = originalPosition + offset
            task.wait(0.1)
        end
        statusLabel.Position = originalPosition
    end
    
    -- Screen shake effect
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        local humanoid = player.Character.Humanoid
        local camera = workspace.CurrentCamera
        
        for i = 1, 20 do
            camera.CFrame = camera.CFrame * CFrame.new(
                math.random(-0.5, 0.5),
                math.random(-0.5, 0.5),
                math.random(-0.5, 0.5)
            )
            task.wait(0.05)
        end
    end
end

local function handleSafeRound()
    if not rouletteGui then return end
    
    local contentFrame = rouletteGui:FindFirstChild("BananaRouletteGUI"):FindFirstChild("ContentFrame")
    local statusLabel = contentFrame:FindFirstChild("StatusLabel")
    
    if statusLabel then
        statusLabel.Text = "😅 SAFE ROUND! Everyone survives!"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    end
end

local function handleRouletteWinner(data)
    if not rouletteGui then return end
    
    local contentFrame = rouletteGui:FindFirstChild("BananaRouletteGUI"):FindFirstChild("ContentFrame")
    local statusLabel = contentFrame:FindFirstChild("StatusLabel")
    
    if statusLabel then
        statusLabel.Text = "🏆 " .. data.winner .. " WINS!\nPrize: " .. data.prize .. " coins!"
        statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        
        -- Victory animation
        local victoryTween = TweenService:Create(statusLabel,
            TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 3),
            {TextSize = statusLabel.TextSize * 1.2}
        )
        victoryTween:Play()
    end
    
    -- Confetti effect on screen
    spawn(function()
        for i = 1, 50 do
            local confetti = Instance.new("Frame")
            confetti.Size = UDim2.new(0, 10, 0, 10)
            confetti.Position = UDim2.new(math.random(), 0, 0, -20)
            confetti.BackgroundColor3 = Color3.new(math.random(), math.random(), math.random())
            confetti.BorderSizePixel = 0
            confetti.Parent = rouletteGui
            
            local fallTween = TweenService:Create(confetti,
                TweenInfo.new(3, Enum.EasingStyle.Linear),
                {Position = UDim2.new(confetti.Position.X.Scale, 0, 1, 20)}
            )
            fallTween:Play()
            
            fallTween.Completed:Connect(function()
                confetti:Destroy()
            end)
            
            task.wait(0.1)
        end
    end)
    
    -- Auto-close after 10 seconds
    task.wait(10)
    if rouletteGui then
        rouletteGui:Destroy()
        rouletteGui = nil
    end
end

local function handleCommandResult(data)
    spawn(function()
        createNotification(
            "Admin Command",
            data.message,
            3,
            Color3.fromRGB(100, 200, 255)
        )
    end)
end

-- Connect to remote events
if adminCommandRemote then
    adminCommandRemote.OnClientEvent:Connect(function(eventType, data)
        if eventType == "invert_start" then
            handleInvertStart(data)
        elseif eventType == "invert_end" then
            handleInvertEnd()
        elseif eventType == "roulette_start" then
            handleRouletteStart(data)
        elseif eventType == "command_result" then
            handleCommandResult(data)
        end
    end)
end

if rouletteUpdateRemote then
    rouletteUpdateRemote.OnClientEvent:Connect(function(eventType, data)
        if eventType == "round_start" then
            handleRouletteRoundStart(data)
        elseif eventType == "banana_select" then
            handleBananaSelect(data)
        elseif eventType == "elimination" then
            handleElimination(data)
        elseif eventType == "safe_round" then
            handleSafeRound()
        elseif eventType == "winner" then
            handleRouletteWinner(data)
        end
    end)
end

-- Make globally accessible
_G.AdminCommandsClient = AdminCommandsClient

print("👑 AdminCommandsClient loaded")

return AdminCommandsClient
