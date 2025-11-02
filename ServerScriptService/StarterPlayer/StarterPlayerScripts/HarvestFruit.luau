-- filepath: /Users/mark/Documents/Roblox/Scripts/HarvestFruit.lua
-- StarterPlayer/StarterPlayerScripts/HarvestFruit.lua (LocalScript)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Wait for manually created RemoteEvents
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestFruitRemote = remoteEventsFolder:WaitForChild("HarvestFruit")

-- Wait for manually created GUI elements
-- Note: These should be created manually in Roblox Studio:
-- 1. Create a BillboardGui in ReplicatedStorage named "HarvestBillboardGui"
-- 2. Add a Frame named "MainFrame" 
-- 3. Add a TextButton named "CollectButton"
-- 4. Add a TextLabel named "EKeyLabel"
local guiTemplate = ReplicatedStorage:WaitForChild("HarvestBillboardGui")
local billboardGui = guiTemplate:Clone()
local frame = billboardGui:WaitForChild("MainFrame")
local collectButton = frame:WaitForChild("CollectButton")
local eKeyLabel = frame:WaitForChild("EKeyLabel")

-- Configure BillboardGui properties (can be adjusted if needed)
billboardGui.Name = "HarvestGui"
billboardGui.AlwaysOnTop = true
billboardGui.Size = UDim2.new(0, 160, 0, 80)
billboardGui.StudsOffset = Vector3.new(0, 3, 0)
billboardGui.Enabled = false

-- Configure Frame properties
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)

-- Check for manually created corner element
local corner = frame:FindFirstChild("UICorner")
if not corner then
	warn("UICorner should be created manually in Studio for MainFrame in HarvestBillboardGui")
end

-- Configure Collect Button properties
collectButton.Size = UDim2.new(1, -10, 0.6, -5)
collectButton.Position = UDim2.new(0, 5, 0, 5)
collectButton.BackgroundColor3 = Color3.fromRGB(85, 170, 85)
collectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
collectButton.Font = Enum.Font.SourceSansBold
collectButton.TextSize = 16
collectButton.Text = "🍌 COLLECT"
collectButton.BorderSizePixel = 0

-- Check for manually created button corner
local buttonCorner = collectButton:FindFirstChild("UICorner")
if not buttonCorner then
	warn("UICorner should be created manually in Studio for CollectButton in HarvestBillboardGui")
end

-- Configure E Key Label properties
eKeyLabel.Size = UDim2.new(1, -10, 0.4, -5)
eKeyLabel.Position = UDim2.new(0, 5, 0.6, 0)
eKeyLabel.BackgroundTransparency = 1
eKeyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
eKeyLabel.Font = Enum.Font.SourceSans
eKeyLabel.TextSize = 12
eKeyLabel.Text = "or press E"
eKeyLabel.TextWrapped = true

-- Animation effects
local function animateButton(button, pressed)
	local tween = TweenService:Create(
		button,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad),
		{
			Size = pressed and UDim2.new(0.95, -10, 0.55, -5) or UDim2.new(1, -10, 0.6, -5),
			BackgroundColor3 = pressed and Color3.fromRGB(70, 140, 70) or Color3.fromRGB(85, 170, 85)
		}
	)
	tween:Play()
end

-- Hover effects
collectButton.MouseEnter:Connect(function()
	if collectButton.BackgroundColor3 == Color3.fromRGB(85, 170, 85) then
		TweenService:Create(
			collectButton,
			TweenInfo.new(0.1),
			{BackgroundColor3 = Color3.fromRGB(100, 190, 100)}
		):Play()
	end
end)

collectButton.MouseLeave:Connect(function()
	if collectButton.BackgroundColor3 == Color3.fromRGB(100, 190, 100) then
		TweenService:Create(
			collectButton,
			TweenInfo.new(0.1),
			{BackgroundColor3 = Color3.fromRGB(85, 170, 85)}
		):Play()
	end
end)

local currentTargetFruit = nil
local isHoldingE = false

-- Function to handle fruit collection
local function collectFruit(fruit)
	if not fruit or not fruit.Parent then return end

	-- Visual feedback
	animateButton(collectButton, true)

	-- Send harvest request to server
	harvestFruitRemote:FireServer(fruit)

	-- Hide GUI immediately
	billboardGui.Enabled = false
	billboardGui.Parent = nil
	currentTargetFruit = nil

	-- Reset button after short delay
	task.wait(0.1)
	if collectButton.Parent then
		animateButton(collectButton, false)
	end
end

-- Button click handler
collectButton.MouseButton1Click:Connect(function()
	if currentTargetFruit then
		collectFruit(currentTargetFruit)
	end
end)

-- Input handling for E key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E and currentTargetFruit then
		isHoldingE = true
		collectFruit(currentTargetFruit)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		isHoldingE = false
	end
end)

-- Main detection loop
RunService.RenderStepped:Connect(function()
	local target = mouse.Target
	local validFruit = nil

	-- Check if target is part of a grown fruit
	if target and target:IsA("BasePart") then
		local fruit = target.Parent

		-- Check if it's a fruit in the GrowingBananas folder
		if fruit and fruit.Parent and fruit.Parent.Name == "GrowingBananas" then
			local isGrown = fruit:GetAttribute("IsGrown")

			if isGrown == true then
				validFruit = fruit
			end
		end

		-- Also check if the target itself is a standalone fruit part
		if not validFruit and target.Parent and target.Parent.Name == "GrowingBananas" then
			local isGrown = target:GetAttribute("IsGrown")
			if isGrown == true then
				validFruit = target
			end
		end
	end

	-- Update GUI based on valid fruit
	if validFruit and validFruit ~= currentTargetFruit then
		-- Show harvest GUI for new fruit
		currentTargetFruit = validFruit
		billboardGui.Adornee = validFruit:IsA("Model") and validFruit.PrimaryPart or validFruit

		-- If no PrimaryPart, find the first part
		if validFruit:IsA("Model") and not billboardGui.Adornee then
			for _, child in ipairs(validFruit:GetChildren()) do
				if child:IsA("BasePart") then
					billboardGui.Adornee = child
					break
				end
			end
		end

		billboardGui.Parent = player.PlayerGui
		billboardGui.Enabled = true

		-- Update button text based on fruit type
		local fruitName = validFruit.Name
		if string.find(fruitName:lower(), "rainbow") then
			collectButton.Text = "🌈 COLLECT"
			collectButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
		elseif string.find(fruitName:lower(), "gold") then
			collectButton.Text = "⭐ COLLECT"
			collectButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		else
			collectButton.Text = "🍌 COLLECT"
			collectButton.BackgroundColor3 = Color3.fromRGB(85, 170, 85)
		end

	elseif not validFruit and currentTargetFruit then
		-- Hide GUI when no valid fruit
		billboardGui.Enabled = false
		billboardGui.Parent = nil
		currentTargetFruit = nil
	end
end)

print("Harvest Fruit LocalScript Loaded.")