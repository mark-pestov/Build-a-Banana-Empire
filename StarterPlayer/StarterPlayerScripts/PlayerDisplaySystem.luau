-- PlayerDisplaySystem.luau - System for displaying usernames and titles above player heads
-- Place in StarterPlayer/StarterPlayerScripts
-- Handles BillboardGui creation and updates based on settings

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Wait for RemoteEvents
local updateTitleRemote = ReplicatedStorage:WaitForChild("UpdateTitleRemote", 10)
local getTitleDataRemote = ReplicatedStorage:WaitForChild("GetTitleDataRemote", 10)

local PlayerDisplaySystem = {}

-- Configuration
local Config = {
    SettingsKey = "GameSettings_" .. player.UserId,
    DisplayOffset = Vector3.new(0, 5, 0), -- Offset above player head
    UsernameColor = Color3.fromRGB(255, 255, 255),
    TitleColorDefault = Color3.fromRGB(255, 215, 0), -- Gold color for titles
    FontSize = 18,
    UsernameFont = Enum.Font.GothamBold,
    TitleFont = Enum.Font.GothamSemibold,
    FadeDistance = 100, -- Distance at which displays start to fade
    MaxDistance = 150, -- Distance at which displays become invisible
}

-- Storage for player displays
local playerDisplays = {}
local currentSettings = {}

-- Load settings
local function loadSettings()
    local success, data = pcall(function()
        return game:GetService("DataStoreService"):GetDataStore("PlayerSettings"):GetAsync(Config.SettingsKey)
    end)
    
    if success and data then
        currentSettings = data
    else
        -- Use defaults if no saved settings
        currentSettings = {
            ShowPlayerUsernames = true,
            ShowPlayerTitles = true,
            SelectedTitle = "None",
            ShowTitle = true,
            TitleColor = Config.TitleColorDefault
        }
    end
end

-- Create BillboardGui for a player
local function createPlayerDisplay(targetPlayer)
    if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then
        return nil
    end
    
    local head = targetPlayer.Character.Head
    
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PlayerDisplay"
    billboardGui.Adornee = head
    billboardGui.Size = UDim2.new(0, 200, 0, 100)
    billboardGui.StudsOffset = Config.DisplayOffset
    billboardGui.AlwaysOnTop = true
    billboardGui.LightInfluence = 0
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = billboardGui
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    -- Create username label
    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Name = "UsernameLabel"
    usernameLabel.Parent = mainFrame
    usernameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    usernameLabel.Position = UDim2.new(0, 0, 0.3, 0)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.Text = targetPlayer.Name -- Use Name (username) not DisplayName
    usernameLabel.TextColor3 = Config.UsernameColor
    usernameLabel.TextScaled = true
    usernameLabel.Font = Config.UsernameFont
    usernameLabel.TextStrokeTransparency = 0
    usernameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    
    -- Create title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = ""
    titleLabel.TextColor3 = Config.TitleColorDefault
    titleLabel.TextScaled = true
    titleLabel.Font = Config.TitleFont
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    
    billboardGui.Parent = workspace
    
    return {
        gui = billboardGui,
        usernameLabel = usernameLabel,
        titleLabel = titleLabel,
        player = targetPlayer
    }
end

-- Update player title display
local function updatePlayerTitle(targetPlayer, titleData)
    local display = playerDisplays[targetPlayer]
    if not display or not display.titleLabel then
        return
    end
    
    if titleData and titleData.title and titleData.title ~= "None" and titleData.showTitle then
        display.titleLabel.Text = titleData.title
        display.titleLabel.TextColor3 = titleData.color or Config.TitleColorDefault
        display.titleLabel.Visible = currentSettings.ShowPlayerTitles
    else
        display.titleLabel.Text = ""
        display.titleLabel.Visible = false
    end
end

-- Update visibility based on settings
local function updateDisplayVisibility()
    for targetPlayer, display in pairs(playerDisplays) do
        if display and display.gui and display.gui.Parent then
            -- Update username visibility
            if display.usernameLabel then
                display.usernameLabel.Visible = currentSettings.ShowPlayerUsernames
            end
            
            -- Title visibility is handled in updatePlayerTitle
            -- Request current title data for this player
            if getTitleDataRemote then
                getTitleDataRemote:InvokeServer(targetPlayer)
            end
        end
    end
end

-- Handle distance-based fading
local function updateDisplayDistance()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local playerPosition = player.Character.HumanoidRootPart.Position
    
    for targetPlayer, display in pairs(playerDisplays) do
        if display and display.gui and display.gui.Parent and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (playerPosition - targetPlayer.Character.HumanoidRootPart.Position).Magnitude
            
            local transparency = 0
            if distance > Config.FadeDistance then
                transparency = math.min(1, (distance - Config.FadeDistance) / (Config.MaxDistance - Config.FadeDistance))
            end
            
            -- Apply transparency to all elements
            if display.usernameLabel then
                display.usernameLabel.TextTransparency = transparency
                display.usernameLabel.TextStrokeTransparency = transparency
            end
            if display.titleLabel then
                display.titleLabel.TextTransparency = transparency
                display.titleLabel.TextStrokeTransparency = transparency
            end
            
            -- Hide completely if too far
            display.gui.Enabled = distance <= Config.MaxDistance
        end
    end
end

-- Clean up display for a player
local function removePlayerDisplay(targetPlayer)
    local display = playerDisplays[targetPlayer]
    if display and display.gui then
        display.gui:Destroy()
    end
    playerDisplays[targetPlayer] = nil
end

-- Handle new player joining
local function onPlayerAdded(newPlayer)
    if newPlayer == player then
        return -- Don't show display for local player
    end
    
    -- Wait for character
    local function onCharacterAdded()
        wait(1) -- Small delay to ensure character is fully loaded
        local display = createPlayerDisplay(newPlayer)
        if display then
            playerDisplays[newPlayer] = display
            updateDisplayVisibility()
            
            -- Request title data for new player
            if getTitleDataRemote then
                spawn(function()
                    local titleData = getTitleDataRemote:InvokeServer(newPlayer)
                    updatePlayerTitle(newPlayer, titleData)
                end)
            end
        end
    end
    
    if newPlayer.Character then
        onCharacterAdded()
    end
    
    newPlayer.CharacterAdded:Connect(onCharacterAdded)
    newPlayer.CharacterRemoving:Connect(function()
        removePlayerDisplay(newPlayer)
    end)
end

-- Handle player leaving
local function onPlayerRemoving(leavingPlayer)
    removePlayerDisplay(leavingPlayer)
end

-- Handle settings changes
local function onSettingsChanged()
    -- Reload settings
    loadSettings()
    updateDisplayVisibility()
end

-- Handle title updates from server
local function onTitleUpdated(targetPlayer, titleData)
    updatePlayerTitle(targetPlayer, titleData)
end

-- Initialize the system
function PlayerDisplaySystem:Init()
    -- Load current settings
    loadSettings()
    
    -- Set up player connections
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
    
    -- Handle existing players
    for _, existingPlayer in pairs(Players:GetPlayers()) do
        if existingPlayer ~= player then
            onPlayerAdded(existingPlayer)
        end
    end
    
    -- Set up title update listener
    if updateTitleRemote then
        updateTitleRemote.OnClientEvent:Connect(onTitleUpdated)
    end
    
    -- Set up distance-based fading
    RunService.Heartbeat:Connect(updateDisplayDistance)
    
    -- Listen for settings changes (we'll need to connect this to the settings system)
    if ReplicatedStorage:FindFirstChild("SettingsChanged") then
        ReplicatedStorage.SettingsChanged.OnClientEvent:Connect(onSettingsChanged)
    end
    
    print("PlayerDisplaySystem initialized")
end

-- Public function to update settings (called from Settings.luau)
function PlayerDisplaySystem:UpdateSettings(newSettings)
    currentSettings = newSettings
    updateDisplayVisibility()
end

-- Public function to get current settings
function PlayerDisplaySystem:GetSettings()
    return currentSettings
end

-- Initialize the system
PlayerDisplaySystem:Init()

-- Make it globally accessible
_G.PlayerDisplaySystem = PlayerDisplaySystem

-- Return the module for external access
return PlayerDisplaySystem
