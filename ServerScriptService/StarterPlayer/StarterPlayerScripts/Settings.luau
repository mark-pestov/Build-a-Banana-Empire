-- Settings.luau - Comprehensive Game Settings System
-- Place in StarterPlayer/StarterPlayerScripts
-- Provides a complete settings GUI with all game options including codes

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameSettings = {}

-- Configuration
local Config = {
    SettingsKey = "GameSettings_" .. player.UserId,
    Version = "1.0.0",
    DefaultSettings = {
        -- Gameplay
        AutoEquipTools = true,
        AutoCollect = false,
        ShowPlayerUsernames = true,
        ShowPlayerTitles = true,
        ShowTutorialTips = true,
        LockCameraZoom = false,
        HideOtherPlayers = false,
        AFKMode = false,
        LowPerformanceMode = false,
        
        -- Audio
        BackgroundMusic = true,
        SoundEffects = true,
        MasterVolume = 0.5,
        MusicVolume = 0.5,
        SFXVolume = 0.5,
        
        -- Graphics
        Shadows = true,
        ParticleEffects = true,
        WeatherEffects = true,
        LightingEffects = true,
        SmoothCamera = true,
        OutlineEffects = true,
        
        -- Interface/Controls
        ClickToInteract = true,
        CameraSensitivity = 0.5,
        UIScale = "Medium",
        ShowMinimap = true,
        ChatVisibility = true,
        
        -- Planting System
        InteractivePlanting = true,
        PreviewEnabled = true,
        DragToMove = true,
        AutoConfirm = false,
        ShowAnimations = true,
        PlantingSounds = true,
        
        -- Titles & Customization
        SelectedTitle = "None",
        ShowOwnTitle = true,
        TitleColor = Color3.fromRGB(255, 255, 0),
        
        -- Other
        Language = "English"
    }
}

-- Current settings
local currentSettings = {}
local settingsGUI = nil
local settingsButton = nil
local currentTab = "Gameplay"
local unlockedTitles = {}

-- Create RemoteEvents for codes and settings
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local redeemCodeRemote = remoteEventsFolder:FindFirstChild("RedeemCode")
if not redeemCodeRemote then
    redeemCodeRemote = Instance.new("RemoteEvent")
    redeemCodeRemote.Name = "RedeemCode"
    redeemCodeRemote.Parent = remoteEventsFolder
end

-- Create RemoteEvents for title system
local setPlayerTitleRemote = remoteEventsFolder:FindFirstChild("SetPlayerTitle")
if not setPlayerTitleRemote then
    setPlayerTitleRemote = Instance.new("RemoteEvent")
    setPlayerTitleRemote.Name = "SetPlayerTitle"
    setPlayerTitleRemote.Parent = remoteEventsFolder
end

local getPlayerTitlesRemote = remoteEventsFolder:FindFirstChild("GetPlayerTitles")
if not getPlayerTitlesRemote then
    getPlayerTitlesRemote = Instance.new("RemoteEvent")
    getPlayerTitlesRemote.Name = "GetPlayerTitles"
    getPlayerTitlesRemote.Parent = remoteEventsFolder
end

local getTitlesRemote = remoteEventsFolder:FindFirstChild("GetPlayerTitles")
if not getTitlesRemote then
    getTitlesRemote = Instance.new("RemoteEvent")
    getTitlesRemote.Name = "GetPlayerTitles"
    getTitlesRemote.Parent = remoteEventsFolder
end

local updateTitleRemote = remoteEventsFolder:FindFirstChild("UpdatePlayerTitle")
if not updateTitleRemote then
    updateTitleRemote = Instance.new("RemoteEvent")
    updateTitleRemote.Name = "UpdatePlayerTitle"
    updateTitleRemote.Parent = remoteEventsFolder
end

-- Load settings from DataStore (simplified - you might want to integrate with your actual DataStore)
local function loadSettings()
    -- For now, use default settings
    -- In a real implementation, you'd load from DataStore
    currentSettings = {}
    for key, value in pairs(Config.DefaultSettings) do
        currentSettings[key] = value
    end
    
    print("🔧 Loaded game settings:", currentSettings)
end

-- Save settings to DataStore
local function saveSettings()
    -- For now, just print - in real implementation, save to DataStore
    print("💾 Saved game settings:", currentSettings)
end

-- Apply settings to various game systems
local function applySettings()
    -- Apply planting settings
    if _G.InteractivePlanting then
        _G.InteractivePlanting.togglePlanting(currentSettings.InteractivePlanting)
        
        if _G.InteractivePlanting.Config then
            _G.InteractivePlanting.Config.PreviewEnabled = currentSettings.PreviewEnabled
            _G.InteractivePlanting.Config.DragEnabled = currentSettings.DragToMove
            _G.InteractivePlanting.Config.AutoConfirm = currentSettings.AutoConfirm
            _G.InteractivePlanting.Config.ShowAnimations = currentSettings.ShowAnimations
            _G.InteractivePlanting.Config.PlaySounds = currentSettings.PlantingSounds
        end
    end
    
    -- Apply player display settings
    if _G.PlayerDisplaySystem then
        _G.PlayerDisplaySystem:UpdateSettings(currentSettings)
    end
    
    -- Apply audio settings
    SoundService.RespectFilteringEnabled = false
    if SoundService:FindFirstChild("BackgroundMusic") then
        SoundService.BackgroundMusic.Playing = currentSettings.BackgroundMusic
        SoundService.BackgroundMusic.Volume = currentSettings.MasterVolume * currentSettings.MusicVolume
    end
    
    -- Apply graphics settings
    if currentSettings.Shadows then
        Lighting.GlobalShadows = true
    else
        Lighting.GlobalShadows = false
    end
    
    -- Apply UI settings
    local scale = 1
    if currentSettings.UIScale == "Small" then scale = 0.8
    elseif currentSettings.UIScale == "Large" then scale = 1.2
    end
    
    -- Apply camera settings
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        local humanoid = player.Character.Humanoid
        humanoid.CameraOffset = Vector3.new(0, 0, 0)
    end
    
    -- Apply player visibility
    if currentSettings.HideOtherPlayers then
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                for _, part in pairs(otherPlayer.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Transparency = 1
                    end
                end
            end
        end
    else
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                for _, part in pairs(otherPlayer.Character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.Transparency = 0
                    end
                end
            end
        end
    end
    
    -- Apply chat visibility
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, currentSettings.ChatVisibility)
    
    -- Apply title and name display settings
    if _G.PlayerDisplaySystem then
        _G.PlayerDisplaySystem.updateDisplaySettings({
            showUsernames = currentSettings.ShowPlayerNames,
            showTitles = currentSettings.ShowPlayerTitles
        })
    end
    
    print("✅ Applied game settings")
end

-- Integrate with MainGameInterface if available
local function integrateWithMainInterface()
    -- Wait for MainGameInterface to load
    repeat task.wait(0.1) until _G.MainGameInterface
    
    local MainGameInterface = _G.MainGameInterface
    
    -- Add Settings tab to MainGameInterface if possible
    if MainGameInterface.AddCustomTab then
        MainGameInterface.AddCustomTab("Settings", "⚙️", function()
            GameSettings.openSettings()
        end)
    end
end

-- Create settings button (can be integrated into main UI or standalone)
local function createSettingsButton()
    if settingsButton then
        settingsButton:Destroy()
    end
    
    -- Check if we should integrate with MainGameInterface
    if _G.MainGameInterface then
        integrateWithMainInterface()
        return
    end
    
    -- Create standalone button in corner of screen
    settingsButton = Instance.new("ScreenGui")
    settingsButton.Name = "SettingsButtonGUI"
    settingsButton.ResetOnSpawn = false
    settingsButton.Parent = playerGui
    
    local button = Instance.new("TextButton")
    button.Name = "SettingsButton"
    button.Size = UDim2.new(0, 60, 0, 60)
    button.Position = UDim2.new(1, -80, 0, 20)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    button.Text = "⚙️"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.BorderSizePixel = 0
    button.Parent = settingsButton
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        GameSettings.openSettings()
    end)
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
    end)
end

-- Create toggle setting
local function createToggleSetting(parent, settingKey, title, description, order)
    local settingFrame = Instance.new("Frame")
    settingFrame.Name = settingKey .. "Frame"
    settingFrame.Size = UDim2.new(1, -20, 0, 80)
    settingFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    settingFrame.BorderSizePixel = 0
    settingFrame.LayoutOrder = order
    settingFrame.Parent = parent
    
    local settingCorner = Instance.new("UICorner")
    settingCorner.CornerRadius = UDim.new(0, 8)
    settingCorner.Parent = settingFrame
    
    -- Setting title
    local settingTitle = Instance.new("TextLabel")
    settingTitle.Size = UDim2.new(1, -100, 0, 30)
    settingTitle.Position = UDim2.new(0, 15, 0, 5)
    settingTitle.BackgroundTransparency = 1
    settingTitle.Text = title
    settingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingTitle.TextScaled = true
    settingTitle.Font = Enum.Font.SourceSansBold
    settingTitle.TextXAlignment = Enum.TextXAlignment.Left
    settingTitle.Parent = settingFrame
    
    -- Setting description
    local settingDesc = Instance.new("TextLabel")
    settingDesc.Size = UDim2.new(1, -100, 0, 40)
    settingDesc.Position = UDim2.new(0, 15, 0, 35)
    settingDesc.BackgroundTransparency = 1
    settingDesc.Text = description
    settingDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
    settingDesc.TextScaled = true
    settingDesc.Font = Enum.Font.SourceSans
    settingDesc.TextXAlignment = Enum.TextXAlignment.Left
    settingDesc.TextWrapped = true
    settingDesc.Parent = settingFrame
    
    -- Toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = settingKey .. "Toggle"
    toggleButton.Size = UDim2.new(0, 60, 0, 30)
    toggleButton.Position = UDim2.new(1, -75, 0, 25)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = ""
    toggleButton.Parent = settingFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 15)
    toggleCorner.Parent = toggleButton
    
    -- Toggle indicator
    local toggleIndicator = Instance.new("Frame")
    toggleIndicator.Name = "Indicator"
    toggleIndicator.Size = UDim2.new(0, 24, 0, 24)
    toggleIndicator.Position = UDim2.new(0, 3, 0, 3)
    toggleIndicator.BorderSizePixel = 0
    toggleIndicator.Parent = toggleButton
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 12)
    indicatorCorner.Parent = toggleIndicator
    
    -- Update toggle appearance
    local function updateToggle()
        local isEnabled = currentSettings[settingKey]
        
        if isEnabled then
            toggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            toggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TweenService:Create(toggleIndicator, TweenInfo.new(0.2), {Position = UDim2.new(1, -27, 0, 3)}):Play()
        else
            toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            toggleIndicator.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            TweenService:Create(toggleIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0, 3)}):Play()
        end
    end
    
    -- Toggle click handler
    toggleButton.MouseButton1Click:Connect(function()
        currentSettings[settingKey] = not currentSettings[settingKey]
        updateToggle()
        applySettings()
        saveSettings()
    end)
    
    -- Initial state
    updateToggle()
end

-- Create slider setting
local function createSliderSetting(parent, settingKey, title, description, order, min, max)
    local settingFrame = Instance.new("Frame")
    settingFrame.Name = settingKey .. "Frame"
    settingFrame.Size = UDim2.new(1, -20, 0, 100)
    settingFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    settingFrame.BorderSizePixel = 0
    settingFrame.LayoutOrder = order
    settingFrame.Parent = parent
    
    local settingCorner = Instance.new("UICorner")
    settingCorner.CornerRadius = UDim.new(0, 8)
    settingCorner.Parent = settingFrame
    
    -- Setting title
    local settingTitle = Instance.new("TextLabel")
    settingTitle.Size = UDim2.new(1, -20, 0, 25)
    settingTitle.Position = UDim2.new(0, 15, 0, 5)
    settingTitle.BackgroundTransparency = 1
    settingTitle.Text = title
    settingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingTitle.TextScaled = true
    settingTitle.Font = Enum.Font.SourceSansBold
    settingTitle.TextXAlignment = Enum.TextXAlignment.Left
    settingTitle.Parent = settingFrame
    
    -- Setting description
    local settingDesc = Instance.new("TextLabel")
    settingDesc.Size = UDim2.new(1, -20, 0, 25)
    settingDesc.Position = UDim2.new(0, 15, 0, 30)
    settingDesc.BackgroundTransparency = 1
    settingDesc.Text = description
    settingDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
    settingDesc.TextScaled = true
    settingDesc.Font = Enum.Font.SourceSans
    settingDesc.TextXAlignment = Enum.TextXAlignment.Left
    settingDesc.TextWrapped = true
    settingDesc.Parent = settingFrame
    
    -- Slider background
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -30, 0, 20)
    sliderBg.Position = UDim2.new(0, 15, 0, 65)
    sliderBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = settingFrame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 10)
    sliderCorner.Parent = sliderBg
    
    -- Slider fill
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new(currentSettings[settingKey] or 0.5, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 10)
    fillCorner.Parent = sliderFill
    
    -- Value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 1, 0)
    valueLabel.Position = UDim2.new(1, -55, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(math.floor((currentSettings[settingKey] or 0.5) * 100)) .. "%"
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.TextScaled = true
    valueLabel.Font = Enum.Font.SourceSans
    valueLabel.Parent = sliderBg
    
    -- Slider button
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(1, 0, 1, 0)
    sliderButton.BackgroundTransparency = 1
    sliderButton.Text = ""
    sliderButton.Parent = sliderBg
    
    -- Slider functionality
    local function updateSlider(input)
        local relativeX = (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
        relativeX = math.clamp(relativeX, 0, 1)
        
        currentSettings[settingKey] = relativeX
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        valueLabel.Text = tostring(math.floor(relativeX * 100)) .. "%"
        
        applySettings()
        saveSettings()
    end
    
    sliderButton.MouseButton1Down:Connect(function()
        local connection
        connection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input)
            end
        end)
        
        local releaseConnection
        releaseConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                connection:Disconnect()
                releaseConnection:Disconnect()
            end
        end)
    end)
    
    sliderButton.MouseButton1Click:Connect(function()
        updateSlider(UserInputService:GetMouseLocation())
    end)
end

-- Create dropdown setting
local function createDropdownSetting(parent, settingKey, title, description, order, options)
    local settingFrame = Instance.new("Frame")
    settingFrame.Name = settingKey .. "Frame"
    settingFrame.Size = UDim2.new(1, -20, 0, 80)
    settingFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    settingFrame.BorderSizePixel = 0
    settingFrame.LayoutOrder = order
    settingFrame.Parent = parent
    
    local settingCorner = Instance.new("UICorner")
    settingCorner.CornerRadius = UDim.new(0, 8)
    settingCorner.Parent = settingFrame
    
    -- Setting title
    local settingTitle = Instance.new("TextLabel")
    settingTitle.Size = UDim2.new(1, -150, 0, 30)
    settingTitle.Position = UDim2.new(0, 15, 0, 5)
    settingTitle.BackgroundTransparency = 1
    settingTitle.Text = title
    settingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingTitle.TextScaled = true
    settingTitle.Font = Enum.Font.SourceSansBold
    settingTitle.TextXAlignment = Enum.TextXAlignment.Left
    settingTitle.Parent = settingFrame
    
    -- Setting description
    local settingDesc = Instance.new("TextLabel")
    settingDesc.Size = UDim2.new(1, -150, 0, 40)
    settingDesc.Position = UDim2.new(0, 15, 0, 35)
    settingDesc.BackgroundTransparency = 1
    settingDesc.Text = description
    settingDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
    settingDesc.TextScaled = true
    settingDesc.Font = Enum.Font.SourceSans
    settingDesc.TextXAlignment = Enum.TextXAlignment.Left
    settingDesc.TextWrapped = true
    settingDesc.Parent = settingFrame
    
    -- Dropdown button
    local dropdown = Instance.new("TextButton")
    dropdown.Size = UDim2.new(0, 120, 0, 40)
    dropdown.Position = UDim2.new(1, -135, 0, 20)
    dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    dropdown.Text = currentSettings[settingKey] or options[1]
    dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.TextScaled = true
    dropdown.Font = Enum.Font.SourceSans
    dropdown.BorderSizePixel = 0
    dropdown.Parent = settingFrame
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 8)
    dropdownCorner.Parent = dropdown
    
    -- Dropdown functionality (simplified - you'd want a proper dropdown)
    local currentIndex = 1
    for i, option in ipairs(options) do
        if option == currentSettings[settingKey] then
            currentIndex = i
            break
        end
    end
    
    dropdown.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #options then
            currentIndex = 1
        end
        
        currentSettings[settingKey] = options[currentIndex]
        dropdown.Text = options[currentIndex]
        applySettings()
        saveSettings()
    end)
end

-- Create different tab content
local function createGameplaySettings(parent)
    createToggleSetting(parent, "AutoEquipTools", "🔧 Auto Equip Tools", "Automatically equip tools when needed", 1)
    createToggleSetting(parent, "AutoCollect", "🏃 Auto Collect", "Automatically collect items (if unlocked)", 2)
    createToggleSetting(parent, "ShowPlayerNames", "👤 Show Player Names", "Display other players' names above their characters", 3)
    createToggleSetting(parent, "ShowTutorialTips", "💡 Show Tutorial Tips", "Display helpful tips and tutorials", 4)
    createToggleSetting(parent, "LockCameraZoom", "📹 Lock Camera Zoom", "Prevent camera zoom changes", 5)
    createToggleSetting(parent, "HideOtherPlayers", "👻 Hide Other Players", "Make other players invisible", 6)
    createToggleSetting(parent, "AFKMode", "😴 AFK Mode", "Disable input/movement while idle", 7)
    createToggleSetting(parent, "LowPerformanceMode", "⚡ Low Performance Mode", "Simplify effects and assets for better performance", 8)
end

local function createAudioSettings(parent)
    createToggleSetting(parent, "BackgroundMusic", "🎵 Background Music", "Play background music", 1)
    createToggleSetting(parent, "SoundEffects", "🔊 Sound Effects", "Play sound effects", 2)
    createSliderSetting(parent, "MasterVolume", "🔊 Master Volume", "Overall volume control", 3, 0, 1)
    createSliderSetting(parent, "MusicVolume", "🎵 Music Volume", "Background music volume", 4, 0, 1)
    createSliderSetting(parent, "SFXVolume", "🔊 SFX Volume", "Sound effects volume", 5, 0, 1)
end

local function createGraphicsSettings(parent)
    createToggleSetting(parent, "Shadows", "🌑 Shadows", "Enable shadow rendering", 1)
    createToggleSetting(parent, "ParticleEffects", "✨ Particle Effects", "Enable particle effects", 2)
    createToggleSetting(parent, "WeatherEffects", "🌦️ Weather Effects", "Enable weather effects", 3)
    createToggleSetting(parent, "LightingEffects", "💡 Lighting Effects", "Enable advanced lighting", 4)
    createToggleSetting(parent, "SmoothCamera", "📹 Smooth Camera", "Enable smooth camera movement", 5)
    createToggleSetting(parent, "OutlineEffects", "⭕ Outline/Glow Effects", "Enable outlines for plants and pickups", 6)
end

local function createInterfaceSettings(parent)
    createToggleSetting(parent, "ClickToInteract", "🖱️ Click to Interact", "Enable click interactions", 1)
    createSliderSetting(parent, "CameraSensitivity", "📹 Camera Sensitivity", "Mouse camera sensitivity", 2, 0, 1)
    createDropdownSetting(parent, "UIScale", "📏 UI Scale", "Interface size", 3, {"Small", "Medium", "Large"})
    createToggleSetting(parent, "ShowMinimap", "🗺️ Show Minimap", "Display minimap (if available)", 4)
    createToggleSetting(parent, "ChatVisibility", "💬 Chat Visibility", "Show/hide chat window", 5)
end

local function createPlantingSettings(parent)
    createToggleSetting(parent, "InteractivePlanting", "🌱 Interactive Planting", "Enable interactive seed planting system", 1)
    createToggleSetting(parent, "PreviewEnabled", "👁️ Seed Preview", "Show seed placement preview", 2)
    createToggleSetting(parent, "DragToMove", "↔️ Drag to Reposition", "Allow dragging seeds to reposition", 3)
    createToggleSetting(parent, "AutoConfirm", "⚡ Auto-Confirm", "Skip confirmation dialog", 4)
    createToggleSetting(parent, "ShowAnimations", "🎭 Planting Animations", "Play character animations when planting", 5)
    createToggleSetting(parent, "PlantingSounds", "🔊 Planting Sounds", "Play sound effects during planting", 6)
end

local function createCodesSettings(parent)
    -- Codes input section
    local codesFrame = Instance.new("Frame")
    codesFrame.Name = "CodesFrame"
    codesFrame.Size = UDim2.new(1, -20, 0, 120)
    codesFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    codesFrame.BorderSizePixel = 0
    codesFrame.LayoutOrder = 1
    codesFrame.Parent = parent
    
    local codesCorner = Instance.new("UICorner")
    codesCorner.CornerRadius = UDim.new(0, 8)
    codesCorner.Parent = codesFrame
    
    -- Title
    local codesTitle = Instance.new("TextLabel")
    codesTitle.Size = UDim2.new(1, -20, 0, 30)
    codesTitle.Position = UDim2.new(0, 10, 0, 5)
    codesTitle.BackgroundTransparency = 1
    codesTitle.Text = "🎁 Redeem Codes"
    codesTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    codesTitle.TextScaled = true
    codesTitle.Font = Enum.Font.SourceSansBold
    codesTitle.TextXAlignment = Enum.TextXAlignment.Left
    codesTitle.Parent = codesFrame
    
    -- Description
    local codesDesc = Instance.new("TextLabel")
    codesDesc.Size = UDim2.new(1, -20, 0, 25)
    codesDesc.Position = UDim2.new(0, 10, 0, 30)
    codesDesc.BackgroundTransparency = 1
    codesDesc.Text = "Enter codes below to receive in-game rewards!"
    codesDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
    codesDesc.TextScaled = true
    codesDesc.Font = Enum.Font.SourceSans
    codesDesc.TextXAlignment = Enum.TextXAlignment.Left
    codesDesc.Parent = codesFrame
    
    -- Code input box
    local codeInput = Instance.new("TextBox")
    codeInput.Size = UDim2.new(1, -130, 0, 35)
    codeInput.Position = UDim2.new(0, 10, 0, 60)
    codeInput.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    codeInput.Text = ""
    codeInput.PlaceholderText = "Enter code here..."
    codeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    codeInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    codeInput.TextScaled = true
    codeInput.Font = Enum.Font.SourceSans
    codeInput.BorderSizePixel = 0
    codeInput.Parent = codesFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = codeInput
    
    -- Redeem button
    local redeemButton = Instance.new("TextButton")
    redeemButton.Size = UDim2.new(0, 100, 0, 35)
    redeemButton.Position = UDim2.new(1, -110, 0, 60)
    redeemButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    redeemButton.Text = "🎁 Redeem"
    redeemButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    redeemButton.TextScaled = true
    redeemButton.Font = Enum.Font.SourceSansBold
    redeemButton.BorderSizePixel = 0
    redeemButton.Parent = codesFrame
    
    local redeemCorner = Instance.new("UICorner")
    redeemCorner.CornerRadius = UDim.new(0, 8)
    redeemCorner.Parent = redeemButton
    
    -- Redeem functionality
    redeemButton.MouseButton1Click:Connect(function()
        local code = codeInput.Text:upper():gsub("%s+", "") -- Remove spaces and uppercase
        if code ~= "" then
            redeemCodeRemote:FireServer(code)
            codeInput.Text = ""
            
            -- Visual feedback
            redeemButton.Text = "✓ Sent!"
            redeemButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            task.wait(2)
            redeemButton.Text = "🎁 Redeem"
            redeemButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        end
    end)
    
    -- Enter key support
    codeInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            redeemButton.MouseButton1Click:Fire()
        end
    end)
    
    -- Popular codes section
    local popularCodesFrame = Instance.new("Frame")
    popularCodesFrame.Name = "PopularCodesFrame"
    popularCodesFrame.Size = UDim2.new(1, -20, 0, 200)
    popularCodesFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    popularCodesFrame.BorderSizePixel = 0
    popularCodesFrame.LayoutOrder = 2
    popularCodesFrame.Parent = parent
    
    local popularCorner = Instance.new("UICorner")
    popularCorner.CornerRadius = UDim.new(0, 8)
    popularCorner.Parent = popularCodesFrame
    
    -- Popular codes title
    local popularTitle = Instance.new("TextLabel")
    popularTitle.Size = UDim2.new(1, -20, 0, 30)
    popularTitle.Position = UDim2.new(0, 10, 0, 5)
    popularTitle.BackgroundTransparency = 1
    popularTitle.Text = "📋 Popular Codes"
    popularTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    popularTitle.TextScaled = true
    popularTitle.Font = Enum.Font.SourceSansBold
    popularTitle.TextXAlignment = Enum.TextXAlignment.Left
    popularTitle.Parent = popularCodesFrame
    
    -- Popular codes list
    local popularCodes = {"FREECASH", "WELCOME", "UPDATE1", "BANANA100", "NEWPLAYER"}
    local codesText = "Try these codes:\n\n"
    for _, code in ipairs(popularCodes) do
        codesText = codesText .. "• " .. code .. "\n"
    end
    codesText = codesText .. "\nFollow our social media for more codes!"
    
    local popularList = Instance.new("TextLabel")
    popularList.Size = UDim2.new(1, -20, 0, 160)
    popularList.Position = UDim2.new(0, 10, 0, 35)
    popularList.BackgroundTransparency = 1
    popularList.Text = codesText
    popularList.TextColor3 = Color3.fromRGB(200, 200, 200)
    popularList.TextSize = 16
    popularList.Font = Enum.Font.SourceSans
    popularList.TextXAlignment = Enum.TextXAlignment.Left
    popularList.TextYAlignment = Enum.TextYAlignment.Top
    popularList.TextWrapped = true
    popularList.Parent = popularCodesFrame
end

-- Title selection functions
local function createTitleSelection(parent)
    local titleFrame = Instance.new("Frame")
    titleFrame.Name = "TitleFrame"
    titleFrame.Size = UDim2.new(1, -20, 0, 200)
    titleFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    titleFrame.BorderSizePixel = 0
    titleFrame.LayoutOrder = 1
    titleFrame.Parent = parent
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleFrame
    
    local titleLayout = Instance.new("UIListLayout")
    titleLayout.SortOrder = Enum.SortOrder.LayoutOrder
    titleLayout.Padding = UDim.new(0, 8)
    titleLayout.Parent = titleFrame
    
    local titlePadding = Instance.new("UIPadding")
    titlePadding.PaddingTop = UDim.new(0, 10)
    titlePadding.PaddingBottom = UDim.new(0, 10)
    titlePadding.PaddingLeft = UDim.new(0, 15)
    titlePadding.PaddingRight = UDim.new(0, 15)
    titlePadding.Parent = titleFrame
    
    -- Title section header
    local titleHeader = Instance.new("TextLabel")
    titleHeader.Size = UDim2.new(1, 0, 0, 25)
    titleHeader.BackgroundTransparency = 1
    titleHeader.Text = "👑 Player Title"
    titleHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleHeader.TextScaled = true
    titleHeader.Font = Enum.Font.SourceSansBold
    titleHeader.TextXAlignment = Enum.TextXAlignment.Left
    titleHeader.LayoutOrder = 1
    titleHeader.Parent = titleFrame
    
    -- Show title toggle
    local showTitleFrame = Instance.new("Frame")
    showTitleFrame.Size = UDim2.new(1, 0, 0, 30)
    showTitleFrame.BackgroundTransparency = 1
    showTitleFrame.LayoutOrder = 2
    showTitleFrame.Parent = titleFrame
    
    local showTitleLabel = Instance.new("TextLabel")
    showTitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    showTitleLabel.BackgroundTransparency = 1
    showTitleLabel.Text = "Display Title"
    showTitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    showTitleLabel.TextSize = 16
    showTitleLabel.Font = Enum.Font.SourceSans
    showTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    showTitleLabel.Parent = showTitleFrame
    
    local showTitleToggle = Instance.new("TextButton")
    showTitleToggle.Size = UDim2.new(0, 50, 0, 25)
    showTitleToggle.Position = UDim2.new(1, -55, 0, 2.5)
    showTitleToggle.BackgroundColor3 = currentSettings.ShowTitle and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(100, 100, 100)
    showTitleToggle.Text = currentSettings.ShowTitle and "ON" or "OFF"
    showTitleToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    showTitleToggle.TextScaled = true
    showTitleToggle.Font = Enum.Font.SourceSansBold
    showTitleToggle.BorderSizePixel = 0
    showTitleToggle.Parent = showTitleFrame
    
    local showTitleCorner = Instance.new("UICorner")
    showTitleCorner.CornerRadius = UDim.new(0, 12)
    showTitleCorner.Parent = showTitleToggle
    
    -- Title selection dropdown
    local titleSelectionFrame = Instance.new("Frame")
    titleSelectionFrame.Size = UDim2.new(1, 0, 0, 35)
    titleSelectionFrame.BackgroundTransparency = 1
    titleSelectionFrame.LayoutOrder = 3
    titleSelectionFrame.Parent = titleFrame
    
    local titleSelectionLabel = Instance.new("TextLabel")
    titleSelectionLabel.Size = UDim2.new(0.3, 0, 1, 0)
    titleSelectionLabel.BackgroundTransparency = 1
    titleSelectionLabel.Text = "Select Title:"
    titleSelectionLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    titleSelectionLabel.TextSize = 16
    titleSelectionLabel.Font = Enum.Font.SourceSans
    titleSelectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleSelectionLabel.Parent = titleSelectionFrame
    
    local titleDropdown = Instance.new("TextButton")
    titleDropdown.Size = UDim2.new(0.65, 0, 0, 30)
    titleDropdown.Position = UDim2.new(0.35, 0, 0, 2.5)
    titleDropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    titleDropdown.Text = currentSettings.SelectedTitle or "None"
    titleDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleDropdown.TextSize = 14
    titleDropdown.Font = Enum.Font.SourceSans
    titleDropdown.BorderSizePixel = 0
    titleDropdown.Parent = titleSelectionFrame
    
    local titleDropdownCorner = Instance.new("UICorner")
    titleDropdownCorner.CornerRadius = UDim.new(0, 6)
    titleDropdownCorner.Parent = titleDropdown
    
    -- Title color selection
    local colorFrame = Instance.new("Frame")
    colorFrame.Size = UDim2.new(1, 0, 0, 35)
    colorFrame.BackgroundTransparency = 1
    colorFrame.LayoutOrder = 4
    colorFrame.Parent = titleFrame
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Size = UDim2.new(0.3, 0, 1, 0)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = "Title Color:"
    colorLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    colorLabel.TextSize = 16
    colorLabel.Font = Enum.Font.SourceSans
    colorLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorLabel.Parent = colorFrame
    
    -- Color preset buttons
    local colorButtonsFrame = Instance.new("Frame")
    colorButtonsFrame.Size = UDim2.new(0.65, 0, 0, 30)
    colorButtonsFrame.Position = UDim2.new(0.35, 0, 0, 2.5)
    colorButtonsFrame.BackgroundTransparency = 1
    colorButtonsFrame.Parent = colorFrame
    
    local colorButtonLayout = Instance.new("UIListLayout")
    colorButtonLayout.FillDirection = Enum.FillDirection.Horizontal
    colorButtonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    colorButtonLayout.Padding = UDim.new(0, 5)
    colorButtonLayout.Parent = colorButtonsFrame
    
    local colorPresets = {
        {Color3.fromRGB(255, 255, 0), "Gold"},
        {Color3.fromRGB(255, 100, 100), "Red"},
        {Color3.fromRGB(100, 255, 100), "Green"},
        {Color3.fromRGB(100, 150, 255), "Blue"},
        {Color3.fromRGB(255, 150, 255), "Pink"},
        {Color3.fromRGB(255, 200, 100), "Orange"}
    }
    
    for i, colorData in ipairs(colorPresets) do
        local colorButton = Instance.new("TextButton")
        colorButton.Size = UDim2.new(0, 25, 0, 25)
        colorButton.BackgroundColor3 = colorData[1]
        colorButton.Text = ""
        colorButton.BorderSizePixel = currentSettings.TitleColor == colorData[1] and 3 or 0
        colorButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
        colorButton.LayoutOrder = i
        colorButton.Parent = colorButtonsFrame
        
        local colorButtonCorner = Instance.new("UICorner")
        colorButtonCorner.CornerRadius = UDim.new(0, 4)
        colorButtonCorner.Parent = colorButton
        
        colorButton.MouseButton1Click:Connect(function()
            currentSettings.TitleColor = colorData[1]
            applySettings()
            saveSettings()
            
            -- Update all color button borders
            for _, button in pairs(colorButtonsFrame:GetChildren()) do
                if button:IsA("TextButton") then
                    button.BorderSizePixel = 0
                end
            end
            colorButton.BorderSizePixel = 3
            
            updateTitleRemote:FireServer(currentSettings.SelectedTitle, currentSettings.ShowTitle, currentSettings.TitleColor)
        end)
    end
    
    -- Update functions
    local function updateTitleDropdown()
        local availableTitles = {"None"}
        for _, title in pairs(unlockedTitles) do
            table.insert(availableTitles, title)
        end
        
        titleDropdown.Text = currentSettings.SelectedTitle or "None"
    end
    
    -- Show title toggle functionality
    showTitleToggle.MouseButton1Click:Connect(function()
        currentSettings.ShowTitle = not currentSettings.ShowTitle
        showTitleToggle.BackgroundColor3 = currentSettings.ShowTitle and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(100, 100, 100)
        showTitleToggle.Text = currentSettings.ShowTitle and "ON" or "OFF"
        applySettings()
        saveSettings()
        updateTitleRemote:FireServer(currentSettings.SelectedTitle, currentSettings.ShowTitle, currentSettings.TitleColor)
    end)
    
    -- Title dropdown functionality
    titleDropdown.MouseButton1Click:Connect(function()
        local availableTitles = {"None"}
        for _, title in pairs(unlockedTitles) do
            table.insert(availableTitles, title)
        end
        
        -- Create dropdown menu
        local dropdownMenu = Instance.new("Frame")
        dropdownMenu.Size = UDim2.new(0, titleDropdown.AbsoluteSize.X, 0, math.min(#availableTitles * 30, 150))
        dropdownMenu.Position = UDim2.new(0, titleDropdown.AbsolutePosition.X - titleSelectionFrame.AbsolutePosition.X, 0, 35)
        dropdownMenu.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        dropdownMenu.BorderSizePixel = 1
        dropdownMenu.BorderColor3 = Color3.fromRGB(100, 100, 100)
        dropdownMenu.ZIndex = 10
        dropdownMenu.Parent = titleSelectionFrame
        
        local dropdownCorner = Instance.new("UICorner")
        dropdownCorner.CornerRadius = UDim.new(0, 6)
        dropdownCorner.Parent = dropdownMenu
        
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, 0, 1, 0)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.ScrollBarThickness = 6
        scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
        scrollFrame.Parent = dropdownMenu
        
        local menuLayout = Instance.new("UIListLayout")
        menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
        menuLayout.Parent = scrollFrame
        
        for i, title in ipairs(availableTitles) do
            local option = Instance.new("TextButton")
            option.Size = UDim2.new(1, 0, 0, 30)
            option.BackgroundColor3 = (title == currentSettings.SelectedTitle) and Color3.fromRGB(100, 100, 120) or Color3.fromRGB(60, 60, 70)
            option.Text = title
            option.TextColor3 = Color3.fromRGB(255, 255, 255)
            option.TextSize = 14
            option.Font = Enum.Font.SourceSans
            option.BorderSizePixel = 0
            option.LayoutOrder = i
            option.Parent = scrollFrame
            
            option.MouseEnter:Connect(function()
                if title ~= currentSettings.SelectedTitle then
                    option.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
                end
            end)
            
            option.MouseLeave:Connect(function()
                if title ~= currentSettings.SelectedTitle then
                    option.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                end
            end)
            
            option.MouseButton1Click:Connect(function()
                currentSettings.SelectedTitle = title
                titleDropdown.Text = title
                applySettings()
                saveSettings()
                dropdownMenu:Destroy()
                updateTitleRemote:FireServer(currentSettings.SelectedTitle, currentSettings.ShowTitle, currentSettings.TitleColor)
            end)
        end
        
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, menuLayout.AbsoluteContentSize.Y)
        
        -- Close dropdown when clicking elsewhere
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = UserInputService:GetMouseLocation()
                local guiPos = dropdownMenu.AbsolutePosition
                local guiSize = dropdownMenu.AbsoluteSize
                
                if mousePos.X < guiPos.X or mousePos.X > guiPos.X + guiSize.X or
                   mousePos.Y < guiPos.Y or mousePos.Y > guiPos.Y + guiSize.Y then
                    dropdownMenu:Destroy()
                    connection:Disconnect()
                end
            end
        end)
    end)
    
    updateTitleDropdown()
end

local function createOtherSettings(parent)
    createTitleSelection(parent)
    createDropdownSetting(parent, "Language", "🌍 Language", "Select your preferred language", 2, {"English", "Spanish", "French", "German"})
    
    -- Reset button
    local resetFrame = Instance.new("Frame")
    resetFrame.Name = "ResetFrame"
    resetFrame.Size = UDim2.new(1, -20, 0, 80)
    resetFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    resetFrame.BorderSizePixel = 0
    resetFrame.LayoutOrder = 3
    resetFrame.Parent = parent
    
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 8)
    resetCorner.Parent = resetFrame
    
    local resetButton = Instance.new("TextButton")
    resetButton.Size = UDim2.new(0, 200, 0, 40)
    resetButton.Position = UDim2.new(0, 15, 0, 20)
    resetButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    resetButton.Text = "🔄 Reset All Settings"
    resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetButton.TextScaled = true
    resetButton.Font = Enum.Font.SourceSansBold
    resetButton.BorderSizePixel = 0
    resetButton.Parent = resetFrame
    
    local resetButtonCorner = Instance.new("UICorner")
    resetButtonCorner.CornerRadius = UDim.new(0, 8)
    resetButtonCorner.Parent = resetButton
    
    resetButton.MouseButton1Click:Connect(function()
        currentSettings = {}
        for key, value in pairs(Config.DefaultSettings) do
            currentSettings[key] = value
        end
        applySettings()
        saveSettings()
        
        -- Reload current tab
        loadTabContent(currentTab, parent.Parent)
        
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "✅ Settings reset to default!";
            Color = Color3.fromRGB(100, 255, 100);
        })
    end)
    
    -- Credits section
    local creditsFrame = Instance.new("Frame")
    creditsFrame.Name = "CreditsFrame"
    creditsFrame.Size = UDim2.new(1, -20, 0, 120)
    creditsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    creditsFrame.BorderSizePixel = 0
    creditsFrame.LayoutOrder = 4
    creditsFrame.Parent = parent
    
    local creditsCorner = Instance.new("UICorner")
    creditsCorner.CornerRadius = UDim.new(0, 8)
    creditsCorner.Parent = creditsFrame
    
    local creditsTitle = Instance.new("TextLabel")
    creditsTitle.Size = UDim2.new(1, -20, 0, 30)
    creditsTitle.Position = UDim2.new(0, 10, 0, 5)
    creditsTitle.BackgroundTransparency = 1
    creditsTitle.Text = "ℹ️ Credits & Version"
    creditsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    creditsTitle.TextScaled = true
    creditsTitle.Font = Enum.Font.SourceSansBold
    creditsTitle.TextXAlignment = Enum.TextXAlignment.Left
    creditsTitle.Parent = creditsFrame
    
    local creditsText = Instance.new("TextLabel")
    creditsText.Size = UDim2.new(1, -20, 0, 80)
    creditsText.Position = UDim2.new(0, 10, 0, 35)
    creditsText.BackgroundTransparency = 1
    creditsText.Text = "Banana Farm Game v" .. Config.Version .. "\n\nCreated with ❤️ for the community\nThanks for playing!"
    creditsText.TextColor3 = Color3.fromRGB(200, 200, 200)
    creditsText.TextSize = 16
    creditsText.Font = Enum.Font.SourceSans
    creditsText.TextXAlignment = Enum.TextXAlignment.Left
    creditsText.TextYAlignment = Enum.TextYAlignment.Top
    creditsText.TextWrapped = true
    creditsText.Parent = creditsFrame
end

-- Load tab content
local function loadTabContent(tabName, container)
    -- Clear existing content
    for _, child in pairs(container:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    if tabName == "Gameplay" then
        createGameplaySettings(container)
    elseif tabName == "Audio" then
        createAudioSettings(container)
    elseif tabName == "Graphics" then
        createGraphicsSettings(container)
    elseif tabName == "Interface" then
        createInterfaceSettings(container)
    elseif tabName == "Planting" then
        createPlantingSettings(container)
    elseif tabName == "Codes" then
        createCodesSettings(container)
    elseif tabName == "Other" then
        createOtherSettings(container)
    end
    
    -- Update canvas size after adding content
    task.wait(0.1)
    local contentSize = container.UIListLayout.AbsoluteContentSize
    container.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 20)
end

-- Create comprehensive settings GUI
local function createSettingsGUI()
    if settingsGUI then
        settingsGUI:Destroy()
    end
    
    -- Create screen GUI
    settingsGUI = Instance.new("ScreenGui")
    settingsGUI.Name = "GameSettingsGUI"
    settingsGUI.ResetOnSpawn = false
    settingsGUI.Parent = playerGui
    
    -- Background blur
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.Parent = settingsGUI
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 900, 0, 700)
    mainFrame.Position = UDim2.new(0.5, -450, 0.5, -350)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = settingsGUI
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 15)
    titleCorner.Parent = titleBar
    
    -- Title text
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚙️ Game Settings"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -45, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        GameSettings.closeSettings()
    end)
    
    -- Tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0, 180, 1, -70)
    tabContainer.Position = UDim2.new(0, 10, 0, 70)
    tabContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 10)
    tabCorner.Parent = tabContainer
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabContainer
    
    -- Content container
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Size = UDim2.new(1, -210, 1, -80)
    contentContainer.Position = UDim2.new(0, 200, 0, 70)
    contentContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    contentContainer.BorderSizePixel = 0
    contentContainer.ScrollBarThickness = 8
    contentContainer.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 10)
    contentCorner.Parent = contentContainer
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 15)
    contentLayout.Parent = contentContainer
    
    -- Tabs data
    local tabs = {
        {name = "Gameplay", icon = "🎮", order = 1},
        {name = "Audio", icon = "🔊", order = 2},
        {name = "Graphics", icon = "🖥️", order = 3},
        {name = "Interface", icon = "🖱️", order = 4},
        {name = "Planting", icon = "🌱", order = 5},
        {name = "Codes", icon = "🎁", order = 6},
        {name = "Other", icon = "🔧", order = 7}
    }
    
    -- Create tab buttons
    for _, tab in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tab.name .. "Tab"
        tabButton.Size = UDim2.new(1, -10, 0, 50)
        tabButton.Position = UDim2.new(0, 5, 0, 0)
        tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        tabButton.Text = tab.icon .. " " .. tab.name
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.TextScaled = true
        tabButton.Font = Enum.Font.SourceSans
        tabButton.BorderSizePixel = 0
        tabButton.LayoutOrder = tab.order
        tabButton.Parent = tabContainer
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = tabButton
        
        tabButton.MouseButton1Click:Connect(function()
            currentTab = tab.name
            loadTabContent(tab.name, contentContainer)
            
            -- Update tab appearance
            for _, child in pairs(tabContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                end
            end
            tabButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        end)
    end
    
    -- Load initial tab
    loadTabContent(currentTab, contentContainer)
    
    -- Show with animation
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local showTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back),
        {
            Size = UDim2.new(0, 900, 0, 700),
            Position = UDim2.new(0.5, -450, 0.5, -350)
        }
    )
    showTween:Play()
end

-- Open settings
function GameSettings.openSettings()
    createSettingsGUI()
end

-- Close settings
function GameSettings.closeSettings()
    if not settingsGUI then return end
    
    local mainFrame = settingsGUI:FindFirstChild("MainFrame")
    if mainFrame then
        local hideTween = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }
        )
        hideTween:Play()
        
        hideTween.Completed:Connect(function()
            settingsGUI:Destroy()
            settingsGUI = nil
        end)
    else
        settingsGUI:Destroy()
        settingsGUI = nil
    end
end

-- Get current settings
function GameSettings.getSettings()
    return currentSettings
end

-- Update a specific setting
function GameSettings.updateSetting(settingName, value)
    if currentSettings[settingName] ~= nil then
        currentSettings[settingName] = value
        applySettings()
        saveSettings()
    end
end

-- Handle code redemption responses
redeemCodeRemote.OnClientEvent:Connect(function(success, message, rewards)
    if success then
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "✅ Code redeemed! " .. (message or "");
            Color = Color3.fromRGB(100, 255, 100);
        })
        
        if rewards then
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = "🎁 Rewards: " .. rewards;
                Color = Color3.fromRGB(255, 255, 100);
            })
        end
    else
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "❌ " .. (message or "Invalid code!");
            Color = Color3.fromRGB(255, 100, 100);
        })
    end
end)

-- Initialize
loadSettings()
applySettings()
createSettingsButton()

-- Global access
_G.GameSettings = GameSettings

print("⚙️ Comprehensive Game Settings System Loaded!")
print("   - Click the ⚙️ button to open settings")
print("   - 7 categories: Gameplay, Audio, Graphics, Interface, Planting, Codes, Other")
print("   - Code redemption system included")
print("   - Settings automatically saved and applied")

return GameSettings