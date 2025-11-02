-- WeatherDominatorPass.luau - Weather Dominator Gamepass System
-- Lets you force any weather event at will

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local WEATHER_DOMINATOR_GAMEPASS_ID = 2 -- Set your actual gamepass ID

-- Weather types available
local WEATHER_TYPES = {
    "Sunny", "Rainy", "Stormy", "Windy", "Cloudy", "Foggy"
}

-- Wait for weather system
repeat wait() until _G.WeatherSystem or _G.RandomEventSystem

-- Players with weather dominator
local playersWithWeatherDominator = {}

-- Load player's weather dominator status
local function loadWeatherDominatorStatus(player)
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, WEATHER_DOMINATOR_GAMEPASS_ID)
    end)
    
    if success and hasGamepass then
        playersWithWeatherDominator[player.UserId] = true
        player:SetAttribute("WeatherDominatorEnabled", true)
        print("🌦️ Weather Dominator enabled for " .. player.Name)
    else
        playersWithWeatherDominator[player.UserId] = false
        player:SetAttribute("WeatherDominatorEnabled", false)
    end
end

-- Force weather change
local function forceWeather(player, weatherType)
    if not playersWithWeatherDominator[player.UserId] then
        return false, "You don't own Weather Dominator!"
    end
    
    -- Try to change weather through existing systems
    if _G.WeatherSystem and _G.WeatherSystem.setWeather then
        _G.WeatherSystem.setWeather(weatherType)
    elseif _G.RandomEventSystem then
        -- Trigger weather through random event system
        local weatherEvent = {
            name = weatherType .. " Weather",
            type = "weather",
            weather = weatherType
        }
        if _G.RandomEventSystem.triggerEvent then
            _G.RandomEventSystem.triggerEvent(weatherEvent)
        end
    end
    
    -- Send notification
    StarterGui:SetCore("SendNotification", {
        Title = "🌦️ Weather Changed!";
        Text = player.Name .. " forced " .. weatherType .. " weather!";
        Duration = 4;
    })
    
    -- Send chat announcement
    local chatMessage = "🌦️ " .. player.Name .. " used Weather Dominator to force " .. weatherType .. " weather! 🌦️"
    for _, p in ipairs(Players:GetPlayers()) do
        pcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = chatMessage;
                Color = Color3.fromRGB(135, 206, 235); -- Sky blue
                Font = Enum.Font.GothamBold;
                FontSize = Enum.FontSize.Size18;
            })
        end)
    end
    
    print("🌦️ " .. player.Name .. " forced " .. weatherType .. " weather")
    return true, "Weather changed to " .. weatherType .. "!"
end

-- Create weather GUI for player
local function createWeatherGUI(player)
    if not playersWithWeatherDominator[player.UserId] then return end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Create weather control GUI
    local weatherGui = Instance.new("ScreenGui")
    weatherGui.Name = "WeatherDominatorGui"
    weatherGui.ResetOnSpawn = false
    weatherGui.Parent = playerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "WeatherFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(1, -320, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = weatherGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "🌦️ Weather Dominator"
    title.TextColor3 = Color3.fromRGB(135, 206, 235)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    -- Weather buttons
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -60)
    scrollFrame.Position = UDim2.new(0, 10, 0, 50)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #WEATHER_TYPES * 60)
    scrollFrame.Parent = mainFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = scrollFrame
    
    for i, weather in ipairs(WEATHER_TYPES) do
        local weatherButton = Instance.new("TextButton")
        weatherButton.Size = UDim2.new(1, -20, 0, 50)
        weatherButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        weatherButton.Text = "🌦️ " .. weather
        weatherButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        weatherButton.TextScaled = true
        weatherButton.Font = Enum.Font.Gotham
        weatherButton.Parent = scrollFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = weatherButton
        
        weatherButton.MouseButton1Click:Connect(function()
            forceWeather(player, weather)
        end)
    end
    
    return weatherGui
end

-- Handle gamepass purchase
local function onGamepassPurchased(player, gamepassId, wasPurchased)
    if gamepassId == WEATHER_DOMINATOR_GAMEPASS_ID and wasPurchased then
        playersWithWeatherDominator[player.UserId] = true
        player:SetAttribute("WeatherDominatorEnabled", true)
        
        -- Create weather GUI
        createWeatherGUI(player)
        
        -- Send notification
        StarterGui:SetCore("SendNotification", {
            Title = "🌦️ Weather Dominator Activated!";
            Text = "You can now control the weather! Check the GUI!";
            Duration = 5;
        })
        
        -- Send chat message
        local chatMessage = "🌦️ " .. player.Name .. " bought Weather Dominator! They can control the weather! 🌦️"
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function()
                StarterGui:SetCore("ChatMakeSystemMessage", {
                    Text = chatMessage;
                    Color = Color3.fromRGB(135, 206, 235);
                    Font = Enum.Font.GothamBold;
                    FontSize = Enum.FontSize.Size18;
                })
            end)
        end
        
        print("🎉 " .. player.Name .. " purchased Weather Dominator gamepass!")
    end
end

-- Connect gamepass purchase handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchased)

-- Player events
Players.PlayerAdded:Connect(function(player)
    wait(2)
    loadWeatherDominatorStatus(player)
    if playersWithWeatherDominator[player.UserId] then
        wait(1)
        createWeatherGUI(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    playersWithWeatherDominator[player.UserId] = nil
end)

-- Handle already connected players
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function()
        loadWeatherDominatorStatus(player)
        if playersWithWeatherDominator[player.UserId] then
            wait(1)
            createWeatherGUI(player)
        end
    end)
end

-- Global access
_G.WeatherDominatorPass = {
    promptPurchase = function(player)
        MarketplaceService:PromptGamePassPurchase(player, WEATHER_DOMINATOR_GAMEPASS_ID)
    end,
    hasGamepass = function(player)
        return playersWithWeatherDominator[player.UserId] or false
    end,
    forceWeather = forceWeather,
    createGUI = createWeatherGUI,
    GAMEPASS_ID = WEATHER_DOMINATOR_GAMEPASS_ID
}

print("🌦️ Weather Dominator Gamepass System initialized!")
print("💰 Gamepass ID: " .. WEATHER_DOMINATOR_GAMEPASS_ID .. " (remember to set the actual ID)")
