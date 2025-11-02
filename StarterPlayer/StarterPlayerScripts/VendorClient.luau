-- VendorClient.lua
-- Consolidated client-side vendor system
-- Combines proximity detection and dialog GUI functionality

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local VendorClient = {}
local currentDialog = nil
local isDialogOpen = false

-- Configuration
local Config = {
	VendorName = "PokerproA4",
	InteractionDistance = 10,
	PromptText = "Talk to Vendor",
	HoldDuration = 0.5,
	MainFrameSize = UDim2.new(0, 600, 0, 400),
	AnimationTime = 0.5,
	TypewriterSpeed = 0.03
}

-- Vendor dialogs and options
local VendorDialogs = {
	welcome = {
		text = "Welcome to my fruit trading post! I buy all kinds of fruits at premium prices. What can I do for you today?",
		options = {
			{text = "Sell Fruits", action = "sell_fruits"},
			{text = "Check Prices", action = "check_prices"},
			{text = "Quest Information", action = "quest_info"},
			{text = "Goodbye", action = "close"}
		}
	},
	sell_fruits = {
		text = "Perfect! I'm buying all fruits today. Show me what you've got and I'll give you the best prices in town!",
		options = {
			{text = "Sell All Bananas", action = "sell_bananas"},
			{text = "Sell Golden Bananas", action = "sell_golden"},
			{text = "Sell Rainbow Bananas", action = "sell_rainbow"},
			{text = "Back to Main Menu", action = "welcome"}
		}
	},
	check_prices = {
		text = "Current fruit prices:\n🍌 Regular Banana: 10 coins\n🥇 Golden Banana: 100 coins\n🌈 Rainbow Banana: 1000 coins",
		options = {
			{text = "Sell Fruits", action = "sell_fruits"},
			{text = "Back to Main Menu", action = "welcome"}
		}
	},
	quest_info = {
		text = "I sometimes have special quests for dedicated farmers. Complete daily fruit collection goals to earn bonus rewards!",
		options = {
			{text = "Back to Main Menu", action = "welcome"}
		}
	}
}

-- Wait for RemoteEvents
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local vendorInteractionRemote = remoteEventsFolder:WaitForChild("VendorInteraction")

-- PROXIMITY DETECTION FUNCTIONS
function VendorClient.SetupVendorInteraction()
	-- Wait for vendor to exist in workspace
	local vendor = workspace:WaitForChild(Config.VendorName)

	-- Get the vendor's primary part
	local vendorPart = vendor:FindFirstChild("HumanoidRootPart") or vendor:FindFirstChild("Torso")
	if not vendorPart then
		warn("Could not find HumanoidRootPart or Torso in " .. Config.VendorName)
		return
	end

	-- Create proximity prompt
	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.Name = "VendorPrompt"
	proximityPrompt.ActionText = Config.PromptText
	proximityPrompt.ObjectText = "Fruit Vendor"
	proximityPrompt.HoldDuration = Config.HoldDuration
	proximityPrompt.MaxActivationDistance = Config.InteractionDistance
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.Parent = vendorPart

	-- Style the prompt
	proximityPrompt.Style = Enum.ProximityPromptStyle.Default
	proximityPrompt.ClickablePrompt = false

	-- Handle interaction
	proximityPrompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered == player and not isDialogOpen then
			VendorClient.OpenDialog("welcome")
		end
	end)

	print("✅ Vendor proximity interaction setup complete for " .. Config.VendorName)
end

-- DIALOG GUI FUNCTIONS
function VendorClient.CreateDialogGUI()
	-- Remove existing dialog
	local existingDialog = playerGui:FindFirstChild("VendorDialogGUI")
	if existingDialog then
		existingDialog:Destroy()
	end

	-- Create main screen GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VendorDialogGUI"
	screenGui.Parent = playerGui
	screenGui.ResetOnSpawn = false

	-- Create blur effect
	local blur = Instance.new("Frame")
	blur.Name = "BlurBackground"
	blur.Size = UDim2.new(1, 0, 1, 0)
	blur.Position = UDim2.new(0, 0, 0, 0)
	blur.BackgroundColor3 = Color3.new(0, 0, 0)
	blur.BackgroundTransparency = 0.5
	blur.Parent = screenGui
	blur.Visible = false

	-- Create main dialog frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = Config.MainFrameSize
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
	mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	mainFrame.Visible = false

	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar

	-- Title text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -50, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🍌 Fruit Vendor - " .. Config.VendorName
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Parent = titleBar

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		VendorClient.CloseDialog()
	end)

	-- Dialog text area
	local dialogFrame = Instance.new("Frame")
	dialogFrame.Name = "DialogFrame"
	dialogFrame.Size = UDim2.new(1, -20, 0, 150)
	dialogFrame.Position = UDim2.new(0, 10, 0, 60)
	dialogFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	dialogFrame.BorderSizePixel = 0
	dialogFrame.Parent = mainFrame

	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0, 8)
	dialogCorner.Parent = dialogFrame

	local dialogText = Instance.new("TextLabel")
	dialogText.Name = "DialogText"
	dialogText.Size = UDim2.new(1, -20, 1, -20)
	dialogText.Position = UDim2.new(0, 10, 0, 10)
	dialogText.BackgroundTransparency = 1
	dialogText.Text = ""
	dialogText.TextColor3 = Color3.fromRGB(255, 255, 255)
	dialogText.TextScaled = true
	dialogText.Font = Enum.Font.SourceSans
	dialogText.TextWrapped = true
	dialogText.TextXAlignment = Enum.TextXAlignment.Left
	dialogText.TextYAlignment = Enum.TextYAlignment.Top
	dialogText.Parent = dialogFrame

	-- Options container
	local optionsContainer = Instance.new("ScrollingFrame")
	optionsContainer.Name = "OptionsContainer"
	optionsContainer.Size = UDim2.new(1, -20, 0, 160)
	optionsContainer.Position = UDim2.new(0, 10, 0, 220)
	optionsContainer.BackgroundTransparency = 1
	optionsContainer.BorderSizePixel = 0
	optionsContainer.ScrollBarThickness = 8
	optionsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	optionsContainer.Parent = mainFrame

	local optionsLayout = Instance.new("UIListLayout")
	optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	optionsLayout.Padding = UDim.new(0, 10)
	optionsLayout.Parent = optionsContainer

	return screenGui
end

function VendorClient.OpenDialog(dialogKey)
	if isDialogOpen then return end

	isDialogOpen = true
	currentDialog = VendorClient.CreateDialogGUI()

	local blur = currentDialog:FindFirstChild("BlurBackground")
	local mainFrame = currentDialog:FindFirstChild("MainFrame")

	-- Show with animation
	blur.Visible = true
	mainFrame.Visible = true

	-- Animate blur
	TweenService:Create(blur, TweenInfo.new(Config.AnimationTime), {BackgroundTransparency = 0.3}):Play()

	-- Animate main frame
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	TweenService:Create(mainFrame, TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Back), {
		Size = Config.MainFrameSize,
		Position = UDim2.new(0.5, -300, 0.5, -200)
	}):Play()

	-- Load dialog content
	VendorClient.LoadDialog(dialogKey)
end

function VendorClient.LoadDialog(dialogKey)
	local dialog = VendorDialogs[dialogKey]
	if not dialog then
		warn("Dialog not found: " .. tostring(dialogKey))
		return
	end

	local dialogText = currentDialog.MainFrame.DialogFrame.DialogText
	local optionsContainer = currentDialog.MainFrame.OptionsContainer

	-- Clear existing options
	for _, child in ipairs(optionsContainer:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	-- Typewriter effect for dialog text
	VendorClient.TypewriterText(dialogText, dialog.text)

	-- Create option buttons
	for i, option in ipairs(dialog.options) do
		local optionButton = Instance.new("TextButton")
		optionButton.Name = "Option" .. i
		optionButton.Size = UDim2.new(1, 0, 0, 40)
		optionButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
		optionButton.Text = option.text
		optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		optionButton.TextScaled = true
		optionButton.Font = Enum.Font.SourceSans
		optionButton.LayoutOrder = i
		optionButton.Parent = optionsContainer

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = optionButton

		-- Button animations
		optionButton.MouseEnter:Connect(function()
			TweenService:Create(optionButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 150, 200)}):Play()
		end)

		optionButton.MouseLeave:Connect(function()
			TweenService:Create(optionButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 130, 180)}):Play()
		end)

		optionButton.MouseButton1Click:Connect(function()
			VendorClient.HandleOptionClick(option.action)
		end)
	end

	-- Update canvas size
	local contentSize = optionsContainer.UIListLayout.AbsoluteContentSize
	optionsContainer.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y)
end

function VendorClient.TypewriterText(textLabel, fullText)
	textLabel.Text = ""
	local currentText = ""

	for i = 1, #fullText do
		currentText = fullText:sub(1, i)
		textLabel.Text = currentText
		wait(Config.TypewriterSpeed)
	end
end

function VendorClient.HandleOptionClick(action)
	if action == "close" then
		VendorClient.CloseDialog()
	elseif VendorDialogs[action] then
		VendorClient.LoadDialog(action)
	else
		-- Handle server-side actions
		vendorInteractionRemote:FireServer(action)
		VendorClient.CloseDialog()
	end
end

function VendorClient.CloseDialog()
	if not isDialogOpen or not currentDialog then return end

	local blur = currentDialog:FindFirstChild("BlurBackground")
	local mainFrame = currentDialog:FindFirstChild("MainFrame")

	-- Animate out
	TweenService:Create(blur, TweenInfo.new(Config.AnimationTime), {BackgroundTransparency = 1}):Play()
	TweenService:Create(mainFrame, TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()

	-- Clean up after animation
	task.wait(Config.AnimationTime)
	currentDialog:Destroy()
	currentDialog = nil
	isDialogOpen = false
end

-- Handle ESC key to close dialog
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Escape and isDialogOpen then
		VendorClient.CloseDialog()
	end
end)

-- Initialize on spawn
local function onCharacterAdded(character)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	VendorClient.SetupVendorInteraction()
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Global functions
_G.VendorClient = VendorClient

print("🏪 Vendor Client System Loaded!")
print("   - Proximity detection for " .. Config.VendorName)
print("   - Dialog GUI system")
print("   - Typewriter effects")
print("   - Interactive options")

return VendorClient
