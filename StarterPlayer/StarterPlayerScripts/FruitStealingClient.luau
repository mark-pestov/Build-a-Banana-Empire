-- FruitStealingClient.lua - Client-side fruit stealing interface
-- Place in StarterPlayer/StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local stealFruitRemote = remoteEventsFolder:WaitForChild("StealFruit")
local purchaseStealRemote = remoteEventsFolder:WaitForChild("PurchaseSteal")

-- GUI Variables
local stealGUI = nil
local targetFruit = nil

-- Create stealing GUI
local function createStealGUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FruitStealingGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "StealFrame"
	mainFrame.Size = UDim2.new(0, 300, 0, 200)
	mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🥷 Steal Fruit"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = mainFrame

	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -20, 0, 60)
	description.Position = UDim2.new(0, 10, 0, 50)
	description.BackgroundTransparency = 1
	description.Text = "Steal this fruit from another player's plot?\n\nThis will consume one steal ability."
	description.TextColor3 = Color3.fromRGB(200, 200, 200)
	description.TextScaled = true
	description.Font = Enum.Font.SourceSans
	description.TextWrapped = true
	description.Parent = mainFrame

	-- Steal button
	local stealButton = Instance.new("TextButton")
	stealButton.Name = "StealButton"
	stealButton.Size = UDim2.new(0, 120, 0, 35)
	stealButton.Position = UDim2.new(0, 20, 1, -50)
	stealButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	stealButton.Text = "🥷 Steal Fruit"
	stealButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	stealButton.TextScaled = true
	stealButton.Font = Enum.Font.SourceSansBold
	stealButton.Parent = mainFrame

	local stealCorner = Instance.new("UICorner")
	stealCorner.CornerRadius = UDim.new(0, 8)
	stealCorner.Parent = stealButton

	-- Purchase button
	local purchaseButton = Instance.new("TextButton")
	purchaseButton.Name = "PurchaseButton"
	purchaseButton.Size = UDim2.new(0, 120, 0, 35)
	purchaseButton.Position = UDim2.new(1, -140, 1, -50)
	purchaseButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	purchaseButton.Text = "💰 Buy Steal"
	purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	purchaseButton.TextScaled = true
	purchaseButton.Font = Enum.Font.SourceSansBold
	purchaseButton.Parent = mainFrame

	local purchaseCorner = Instance.new("UICorner")
	purchaseCorner.CornerRadius = UDim.new(0, 8)
	purchaseCorner.Parent = purchaseButton

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 15)
	closeCorner.Parent = closeButton

	-- Button connections
	stealButton.MouseButton1Click:Connect(function()
		if targetFruit then
			stealFruitRemote:FireServer(targetFruit)
			hideStealGUI()
		end
	end)

	purchaseButton.MouseButton1Click:Connect(function()
		purchaseStealRemote:FireServer()
		hideStealGUI()
	end)

	closeButton.MouseButton1Click:Connect(function()
		hideStealGUI()
	end)

	-- Hover effects
	local function addHoverEffect(button, hoverColor, normalColor)
		button.MouseEnter:Connect(function()
			local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor})
			tween:Play()
		end)

		button.MouseLeave:Connect(function()
			local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = normalColor})
			tween:Play()
		end)
	end

	addHoverEffect(stealButton, Color3.fromRGB(255, 70, 70), Color3.fromRGB(220, 50, 50))
	addHoverEffect(purchaseButton, Color3.fromRGB(70, 170, 70), Color3.fromRGB(50, 150, 50))
	addHoverEffect(closeButton, Color3.fromRGB(220, 70, 70), Color3.fromRGB(200, 50, 50))

	stealGUI = screenGui
	return screenGui
end

-- Show stealing GUI
local function showStealGUI(fruit)
	if not stealGUI then
		createStealGUI()
	end

	targetFruit = fruit
	local mainFrame = stealGUI.StealFrame

	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	-- Animate in
	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 300, 0, 200),
		Position = UDim2.new(0.5, -150, 0.5, -100)
	})
	tween:Play()
end

-- Hide stealing GUI
function hideStealGUI()
	if not stealGUI then return end

	local mainFrame = stealGUI.StealFrame
	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})

	tween:Play()
	tween.Completed:Connect(function()
		mainFrame.Visible = false
		targetFruit = nil
	end)
end

-- Handle fruit clicking
local function onFruitClicked(fruit)
	-- Check if this fruit belongs to another player
	local fruitOwner = fruit:GetAttribute("OwnerUserId")
	if fruitOwner and fruitOwner ~= player.UserId then
		showStealGUI(fruit)
	end
end

-- Monitor for fruit objects and add click detection
local function setupFruitClickDetection()
	-- Monitor workspace for fruits
	local function monitorFruit(fruit)
		if not fruit:IsA("Model") and not fruit:IsA("Part") then return end
		if not fruit.Name:lower():find("banana") then return end

		local clickDetector = fruit:FindFirstChild("ClickDetector")
		if not clickDetector then
			clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 20
			clickDetector.Parent = fruit
		end

		clickDetector.MouseClick:Connect(function(clickingPlayer)
			if clickingPlayer == player then
				onFruitClicked(fruit)
			end
		end)
	end

	-- Check existing fruits
	local plotsFolder = workspace:FindFirstChild("Plots")
	if plotsFolder then
		for _, plot in ipairs(plotsFolder:GetChildren()) do
			local fruitsFolder = plot:FindFirstChild("GrowingBananas")
			if fruitsFolder then
				for _, fruit in ipairs(fruitsFolder:GetChildren()) do
					monitorFruit(fruit)
				end

				-- Monitor new fruits
				fruitsFolder.ChildAdded:Connect(monitorFruit)
			end
		end
	end
end

-- Close GUI when player moves away
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Escape then
		hideStealGUI()
	end
end)

-- Initialize
task.wait(2) -- Wait for plot system to load
setupFruitClickDetection()

print("🥷 Fruit Stealing Client Loaded!")
print("   - Click on other players' fruits to steal")
print("   - Purchase steal abilities via developer product")
print("   - Press ESC to close steal GUI")

-- DEPRECATED: Fruit/farming UI removed for city/empire game.
return
