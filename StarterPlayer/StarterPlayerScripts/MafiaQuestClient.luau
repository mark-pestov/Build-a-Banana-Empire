-- MafiaQuestClient.lua
-- Place this script in StarterPlayer > StarterPlayerScripts
-- Handles Mafia Quest GUI interactions and communication with server

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local getMafiaQuestsRemote = remotes:WaitForChild("GetMafiaQuests", 10)
local acceptMafiaQuestRemote = remotes:WaitForChild("AcceptMafiaQuest", 10)

if not getMafiaQuestsRemote then
	warn("GetMafiaQuests RemoteEvent not found!")
	return
end

if not acceptMafiaQuestRemote then
	warn("AcceptMafiaQuest RemoteEvent not found!")
	return
end

print("Mafia Quest RemoteEvents found successfully!")

-- GUI Variables
local mafiaQuestGUI = nil
local questFrame = nil
local questList = nil
local currentQuests = {}

-- Accept a quest (define early so button handlers can use it)
local function acceptMafiaQuest(questIndex)
	if currentQuests[questIndex] then
		acceptMafiaQuestRemote:FireServer(questIndex, currentQuests[questIndex])
		closeMafiaQuestGUI()
	end
end

-- Create the Mafia Quest GUI
local function createMafiaQuestGUI()
	if mafiaQuestGUI then return end

	mafiaQuestGUI = Instance.new("ScreenGui")
	mafiaQuestGUI.Name = "MafiaQuestGUI"
	mafiaQuestGUI.Enabled = false
	mafiaQuestGUI.ResetOnSpawn = false
	mafiaQuestGUI.Parent = playerGui

	-- Main Frame
	questFrame = Instance.new("Frame")
	questFrame.Name = "QuestFrame"
	questFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
	questFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
	questFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	questFrame.BorderSizePixel = 2
	questFrame.BorderColor3 = Color3.new(1, 0.8, 0)
	questFrame.Parent = mafiaQuestGUI

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = questFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.15, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🐵 MONKEY MAFIA BOSS 🐵"
	title.TextColor3 = Color3.new(1, 0.8, 0)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = questFrame

	-- Quest List (ScrollingFrame)
	questList = Instance.new("ScrollingFrame")
	questList.Name = "QuestList"
	questList.Size = UDim2.new(0.9, 0, 0.7, 0)
	questList.Position = UDim2.new(0.05, 0, 0.2, 0)
	questList.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
	questList.BorderSizePixel = 1
	questList.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
	questList.ScrollBarImageColor3 = Color3.new(1, 0.8, 0)
	questList.Parent = questFrame

	-- Quest List Layout
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = questList

	-- Close Button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.2, 0, 0.1, 0)
	closeButton.Position = UDim2.new(0.75, 0, 0.92, 0)
	closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
	closeButton.Text = "CLOSE"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = questFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 5)
	closeCorner.Parent = closeButton

	-- Close button functionality
	closeButton.MouseButton1Click:Connect(function()
		closeMafiaQuestGUI()
	end)
end

-- Create a quest item in the list
local function createQuestItem(questData, index)
	local questItem = Instance.new("Frame")
	questItem.Name = "QuestItem" .. index
	questItem.Size = UDim2.new(1, -10, 0, 80)
	questItem.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	questItem.BorderSizePixel = 1
	questItem.BorderColor3 = Color3.new(0.4, 0.4, 0.4)
	questItem.LayoutOrder = index
	questItem.Parent = questList

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 5)
	itemCorner.Parent = questItem

	-- Quest Name
	local questName = Instance.new("TextLabel")
	questName.Name = "QuestName"
	questName.Size = UDim2.new(0.65, 0, 0.6, 0)
	questName.Position = UDim2.new(0.05, 0, 0.05, 0)
	questName.BackgroundTransparency = 1
	questName.Text = questData.Name
	questName.TextColor3 = Color3.new(1, 1, 1)
	questName.TextScaled = true
	questName.TextWrapped = true
	questName.Font = Enum.Font.Gotham
	questName.TextXAlignment = Enum.TextXAlignment.Left
	questName.Parent = questItem

	-- Quest Reward (assuming coin reward for display)
	local questReward = Instance.new("TextLabel")
	questReward.Name = "QuestReward"
	questReward.Size = UDim2.new(0.65, 0, 0.3, 0)
	questReward.Position = UDim2.new(0.05, 0, 0.65, 0)
	questReward.BackgroundTransparency = 1
	questReward.Text = "💰 Reward: Coins + Special Effects"
	questReward.TextColor3 = Color3.new(0.8, 1, 0.8)
	questReward.TextScaled = true
	questReward.Font = Enum.Font.Gotham
	questReward.TextXAlignment = Enum.TextXAlignment.Left
	questReward.Parent = questItem

	-- Accept Button
	local acceptButton = Instance.new("TextButton")
	acceptButton.Name = "AcceptButton"
	acceptButton.Size = UDim2.new(0.25, 0, 0.6, 0)
	acceptButton.Position = UDim2.new(0.7, 0, 0.2, 0)
	acceptButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
	acceptButton.Text = "ACCEPT"
	acceptButton.TextColor3 = Color3.new(1, 1, 1)
	acceptButton.TextScaled = true
	acceptButton.Font = Enum.Font.GothamBold
	acceptButton.Parent = questItem

	local acceptCorner = Instance.new("UICorner")
	acceptCorner.CornerRadius = UDim.new(0, 3)
	acceptCorner.Parent = acceptButton

	-- Accept button functionality
	acceptButton.MouseButton1Click:Connect(function()
		acceptMafiaQuest(index)
	end)

	-- Hover effects
	acceptButton.MouseEnter:Connect(function()
		TweenService:Create(acceptButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0.3, 0.9, 0.3)}):Play()
	end)

	acceptButton.MouseLeave:Connect(function()
		TweenService:Create(acceptButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)}):Play()
	end)
end

-- Populate quest list
local function populateQuestList(quests)
	-- Clear existing quest items
	for _, child in pairs(questList:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("QuestItem") then
			child:Destroy()
		end
	end

	currentQuests = quests

	-- Create quest items
	for i, quest in ipairs(quests) do
		createQuestItem(quest, i)
	end

	-- Update canvas size
	questList.CanvasSize = UDim2.new(0, 0, 0, #quests * 85)
end

-- Open Mafia Quest GUI
local function openMafiaQuestGUI()
	print("openMafiaQuestGUI called")

	if not mafiaQuestGUI then
		print("Creating MafiaQuestGUI...")
		createMafiaQuestGUI()
	end

	-- Request quests from server
	print("Requesting quests from server...")
	getMafiaQuestsRemote:FireServer()

	print("Enabling GUI...")
	mafiaQuestGUI.Enabled = true

	-- Animate opening
	questFrame.Size = UDim2.new(0, 0, 0, 0)
	questFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local openTween = TweenService:Create(questFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0.4, 0, 0.6, 0),
		Position = UDim2.new(0.3, 0, 0.2, 0)
	})
	openTween:Play()
end

-- Close Mafia Quest GUI
function closeMafiaQuestGUI()
	if not mafiaQuestGUI then return end

	local closeTween = TweenService:Create(questFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})

	closeTween.Completed:Connect(function()
		mafiaQuestGUI.Enabled = false
	end)

	closeTween:Play()
end

-- Handle server responses
getMafiaQuestsRemote.OnClientEvent:Connect(function(quests)
	populateQuestList(quests)
end)

-- Handle clicking on MafiaBoss
local function onMafiaBossClicked()
	print("onMafiaBossClicked called")
	openMafiaQuestGUI()
end

-- Wait for workspace and find MafiaBoss
local function setupMafiaBossInteraction()
	local workspace = game:GetService("Workspace")

	print("=== MAFIA CLIENT DEBUG ===")
	print("Looking for MafiaBoss model...")

	-- Wait for MafiaBoss model
	local mafiaBoss = workspace:WaitForChild("MafiaBoss", 10)
	if not mafiaBoss then
		warn("MafiaBoss model not found in workspace!")
		print("Available models in workspace:")
		for _, child in pairs(workspace:GetChildren()) do
			if child:IsA("Model") then
				print("- " .. child.Name)
			end
		end
		return
	end

	print("✅ Found MafiaBoss model!")

	-- Find ClickDetector or create one
	local clickDetector = mafiaBoss:FindFirstChildOfClass("ClickDetector")
	if not clickDetector then
		print("Creating ClickDetector...")
		clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 20
		local targetPart = mafiaBoss:FindFirstChild("HumanoidRootPart") or mafiaBoss:FindFirstChildWhichIsA("BasePart")
		if targetPart then
			clickDetector.Parent = targetPart
			print("ClickDetector created and parented to:", targetPart.Name)
		else
			warn("No suitable part found for ClickDetector!")
			return
		end
	else
		print("Found existing ClickDetector")
	end

	-- Connect click event
	clickDetector.MouseClick:Connect(function(clickingPlayer)
		print("MafiaBoss clicked by:", clickingPlayer.Name)
		if clickingPlayer == player then
			print("Opening Mafia Quest GUI...")
			onMafiaBossClicked()
		end
	end)

	print("Mafia Quest system initialized!")
end

-- Initialize when player spawns
print("=== MAFIA CLIENT INITIALIZING ===")
print("Player:", player.Name)
print("Checking RemoteEvents...")

if not getMafiaQuestsRemote then
	warn("❌ GetMafiaQuests RemoteEvent not found!")
	return
end

if not acceptMafiaQuestRemote then
	warn("❌ AcceptMafiaQuest RemoteEvent not found!")
	return
end

print("✅ RemoteEvents found successfully!")

if player.Character then
	setupMafiaBossInteraction()
else
	player.CharacterAdded:Connect(setupMafiaBossInteraction)
end

-- DEBUG: Test GUI with keybind (remove this later)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Press M to test open GUI
	if input.KeyCode == Enum.KeyCode.M then
		print("DEBUG: M key pressed - opening GUI")
		onMafiaBossClicked()
	end

	if input.KeyCode == Enum.KeyCode.Escape and mafiaQuestGUI and mafiaQuestGUI.Enabled then
		closeMafiaQuestGUI()
	end
end)
