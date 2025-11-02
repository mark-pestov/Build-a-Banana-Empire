-- MainGameInterface.lua  
-- Consolidated main game interface combining all GUI systems
-- Place in StarterPlayer/StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MainGameInterface = {}

-- Wait for RemoteEvents
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Configuration
local Config = {
	ToggleKey = Enum.KeyCode.G,
	QuickActionsKey = Enum.KeyCode.Q,
	AnimationTime = 0.3,
	MainFrameSize = UDim2.new(0, 600, 0, 500),
	QuickPanelSize = UDim2.new(0, 200, 0, 250)
}

-- GUI Components
local mainGui = nil
local mainFrame = nil
local quickActionsPanel = nil
local currentTab = "Status"
local isVisible = false
local isQuickPanelVisible = false

-- Tab system
local tabs = {"Status", "Workers", "Sprinklers", "Selling", "AFK", "Rebirth", "Quests", "Events", "Battle Pass"}

-- Create main interface
function MainGameInterface.CreateMainGUI()
	if mainGui then
		mainGui:Destroy()
	end

	-- Main ScreenGui
	mainGui = Instance.new("ScreenGui")
	mainGui.Name = "MainGameInterface"
	mainGui.ResetOnSpawn = false
	mainGui.Parent = playerGui

	-- Main frame
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = Config.MainFrameSize
	mainFrame.Position = UDim2.new(1, -620, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = mainGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar

	-- Fix title bar bottom corners
	local titleFix = Instance.new("Frame")
	titleFix.Size = UDim2.new(1, 0, 0, 12)
	titleFix.Position = UDim2.new(0, 0, 1, -12)
	titleFix.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	titleFix.BorderSizePixel = 0
	titleFix.Parent = titleBar

	-- Title text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -100, 1, 0)
	titleLabel.Position = UDim2.new(0, 15, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🍌 Banana Farm Management Center"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
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
		MainGameInterface.ToggleMainGUI()
	end)

	-- Tab container
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, -20, 0, 40)
	tabContainer.Position = UDim2.new(0, 10, 0, 60)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = mainFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabContainer

	-- Create tab buttons
	for i, tabName in ipairs(tabs) do
		local tabButton = Instance.new("TextButton")
		tabButton.Name = tabName .. "Tab"
		tabButton.Size = UDim2.new(0, 70, 1, 0)
		tabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		tabButton.Text = tabName
		tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
		tabButton.TextScaled = true
		tabButton.Font = Enum.Font.SourceSans
		tabButton.BorderSizePixel = 0
		tabButton.LayoutOrder = i
		tabButton.Parent = tabContainer

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 6)
		tabCorner.Parent = tabButton

		tabButton.MouseButton1Click:Connect(function()
			MainGameInterface.SwitchTab(tabName)
		end)
	end

	-- Content area
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -20, 1, -120)
	contentFrame.Position = UDim2.new(0, 10, 0, 110)
	contentFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 8
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentFrame.Parent = mainFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 8)
	contentCorner.Parent = contentFrame

	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -20, 1, 0)
	contentArea.Position = UDim2.new(0, 10, 0, 0)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = contentFrame

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 10)
	contentLayout.Parent = contentArea

	-- Load initial tab
	MainGameInterface.SwitchTab(currentTab)
end

-- Create quick actions panel
function MainGameInterface.CreateQuickActionsPanel()
	quickActionsPanel = Instance.new("Frame")
	quickActionsPanel.Name = "QuickActionsPanel"
	quickActionsPanel.Size = Config.QuickPanelSize
	quickActionsPanel.Position = UDim2.new(0, 20, 1, -270)
	quickActionsPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	quickActionsPanel.BorderSizePixel = 0
	quickActionsPanel.Visible = false
	quickActionsPanel.Parent = mainGui

	local quickCorner = Instance.new("UICorner")
	quickCorner.CornerRadius = UDim.new(0, 10)
	quickCorner.Parent = quickActionsPanel

	-- Quick actions title
	local quickTitle = Instance.new("TextLabel")
	quickTitle.Size = UDim2.new(1, 0, 0, 30)
	quickTitle.BackgroundTransparency = 1
	quickTitle.Text = "⚡ Quick Actions"
	quickTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	quickTitle.TextScaled = true
	quickTitle.Font = Enum.Font.SourceSansBold
	quickTitle.Parent = quickActionsPanel

	-- Quick action buttons
	local quickButtons = {
		{text = "💰 Quick Sell", action = "sell_all"},
		{text = "😴 Toggle AFK", action = "toggle_afk"},
		{text = "🐛 Clear Pests", action = "clear_pests"},
		{text = "💼 Hire Worker", action = "hire_worker"},
		{text = "💧 Buy Sprinkler", action = "buy_sprinkler"},
		{text = "🎫 Battle Pass", action = "view_battlepass"}
	}

	for i, buttonData in ipairs(quickButtons) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -20, 0, 30)
		button.Position = UDim2.new(0, 10, 0, 30 + (i * 35))
		button.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
		button.Text = buttonData.text
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = true
		button.Font = Enum.Font.SourceSans
		button.BorderSizePixel = 0
		button.Parent = quickActionsPanel

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = button

		button.MouseButton1Click:Connect(function()
			MainGameInterface.HandleQuickAction(buttonData.action)
		end)

		-- Button hover effects
		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 150, 200)}):Play()
		end)

		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 130, 180)}):Play()
		end)
	end
end

-- Switch tabs
function MainGameInterface.SwitchTab(tabName)
	currentTab = tabName

	-- Update tab button colors
	local tabContainer = mainFrame:FindFirstChild("TabContainer")
	if tabContainer then
		for _, tabButton in ipairs(tabContainer:GetChildren()) do
			if tabButton:IsA("TextButton") then
				if tabButton.Name == tabName .. "Tab" then
					tabButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
					tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					tabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
					tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
				end
			end
		end
	end

	-- Load tab content
	MainGameInterface.LoadTabContent(tabName)
end

-- Load tab content
function MainGameInterface.LoadTabContent(tabName)
	local contentArea = mainFrame.ContentFrame.ContentArea

	-- Clear existing content
	for _, child in ipairs(contentArea:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
			child:Destroy()
		end
	end

	-- Load specific tab content
	if tabName == "Status" then
		MainGameInterface.LoadStatusTab(contentArea)
	elseif tabName == "Workers" then
		MainGameInterface.LoadWorkersTab(contentArea)
	elseif tabName == "Sprinklers" then
		MainGameInterface.LoadSprinklersTab(contentArea)
	elseif tabName == "Selling" then
		MainGameInterface.LoadSellingTab(contentArea)
	elseif tabName == "AFK" then
		MainGameInterface.LoadAFKTab(contentArea)
	elseif tabName == "Rebirth" then
		MainGameInterface.LoadRebirthTab(contentArea)
	elseif tabName == "Quests" then
		MainGameInterface.LoadQuestsTab(contentArea)
	elseif tabName == "Events" then
		MainGameInterface.LoadEventsTab(contentArea)
	elseif tabName == "Battle Pass" then
		MainGameInterface.LoadBattlePassTab(contentArea)
	end

	-- Update content size
	local contentSize = contentArea.UIListLayout.AbsoluteContentSize
	contentArea.Parent.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 20)
end

-- Tab loading functions (simplified versions)
function MainGameInterface.LoadStatusTab(parent)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "📊 Farm Status Overview"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = parent

	-- Add status information
	local statusInfo = {
		"💰 Coins: Loading...",
		"🍌 Bananas: Loading...",
		"👷 Workers: Loading...",
		"💧 Sprinklers: Loading...",
		"🎯 Active Quests: Loading...",
		"⚡ AFK Status: Loading..."
	}

	for _, info in ipairs(statusInfo) do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 30)
		label.BackgroundTransparency = 1
		label.Text = info
		label.TextColor3 = Color3.fromRGB(200, 200, 200)
		label.TextScaled = true
		label.Font = Enum.Font.SourceSans
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = parent
	end
end

function MainGameInterface.LoadWorkersTab(parent)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "👷 Worker Management"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = parent

	local hireButton = Instance.new("TextButton")
	hireButton.Size = UDim2.new(1, 0, 0, 40)
	hireButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	hireButton.Text = "💼 Hire New Worker (500 coins)"
	hireButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	hireButton.TextScaled = true
	hireButton.Font = Enum.Font.SourceSans
	hireButton.BorderSizePixel = 0
	hireButton.Parent = parent

	local hireCorner = Instance.new("UICorner")
	hireCorner.CornerRadius = UDim.new(0, 6)
	hireCorner.Parent = hireButton

	hireButton.MouseButton1Click:Connect(function()
		local hireWorkerRemote = remoteEventsFolder:FindFirstChild("HireWorker")
		if hireWorkerRemote then
			hireWorkerRemote:FireServer()
		end
	end)
end

function MainGameInterface.LoadSprinklersTab(parent)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "💧 Sprinkler System"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = parent

	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(1, 0, 0, 40)
	buyButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	buyButton.Text = "💧 Buy Sprinkler (1000 coins)"
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.SourceSans
	buyButton.BorderSizePixel = 0
	buyButton.Parent = parent

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 6)
	buyCorner.Parent = buyButton

	buyButton.MouseButton1Click:Connect(function()
		local purchaseSprinklerRemote = remoteEventsFolder:FindFirstChild("PurchaseSprinkler")
		if purchaseSprinklerRemote then
			purchaseSprinklerRemote:FireServer()
		end
	end)
end

function MainGameInterface.LoadSellingTab(parent)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "💰 Selling Options"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = parent

	local sellButton = Instance.new("TextButton")
	sellButton.Size = UDim2.new(1, 0, 0, 40)
	sellButton.BackgroundColor3 = Color3.fromRGB(70, 180, 70)
	sellButton.Text = "💰 Sell All Bananas"
	sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	sellButton.TextScaled = true
	sellButton.Font = Enum.Font.SourceSans
	sellButton.BorderSizePixel = 0
	sellButton.Parent = parent

	local sellCorner = Instance.new("UICorner")
	sellCorner.CornerRadius = UDim.new(0, 6)
	sellCorner.Parent = sellButton

	sellButton.MouseButton1Click:Connect(function()
		local sellBananasRemote = remoteEventsFolder:FindFirstChild("SellBananas")
		if sellBananasRemote then
			sellBananasRemote:FireServer("all")
		end
	end)
end

function MainGameInterface.LoadAFKTab(parent)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "😴 AFK System"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = parent

	local afkButton = Instance.new("TextButton")
	afkButton.Size = UDim2.new(1, 0, 0, 40)
	afkButton.BackgroundColor3 = Color3.fromRGB(180, 130, 70)
	afkButton.Text = "😴 Toggle AFK Mode"
	afkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	afkButton.TextScaled = true
	afkButton.Font = Enum.Font.SourceSans
	afkButton.BorderSizePixel = 0
	afkButton.Parent = parent

	local afkCorner = Instance.new("UICorner")
	afkCorner.CornerRadius = UDim.new(0, 6)
	afkCorner.Parent = afkButton

	afkButton.MouseButton1Click:Connect(function()
		local toggleAFKRemote = remoteEventsFolder:FindFirstChild("ToggleAFK")
		if toggleAFKRemote then
			toggleAFKRemote:FireServer()
		end
	end)
end

function MainGameInterface.LoadRebirthTab(parent)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "🌟 Rebirth System"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = parent

	local rebirthButton = Instance.new("TextButton")
	rebirthButton.Size = UDim2.new(1, 0, 0, 40)
	rebirthButton.BackgroundColor3 = Color3.fromRGB(180, 70, 180)
	rebirthButton.Text = "🌟 Perform Rebirth"
	rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirthButton.TextScaled = true
	rebirthButton.Font = Enum.Font.SourceSans
	rebirthButton.BorderSizePixel = 0
	rebirthButton.Parent = parent

	local rebirthCorner = Instance.new("UICorner")
	rebirthCorner.CornerRadius = UDim.new(0, 6)
	rebirthCorner.Parent = rebirthButton

	rebirthButton.MouseButton1Click:Connect(function()
		local performRebirthRemote = remoteEventsFolder:FindFirstChild("PerformRebirth")
		if performRebirthRemote then
			performRebirthRemote:FireServer()
		end
	end)
end

function MainGameInterface.LoadQuestsTab(parent)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "🎯 Quest System"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = parent

	local questInfo = Instance.new("TextLabel")
	questInfo.Size = UDim2.new(1, 0, 0, 60)
	questInfo.BackgroundTransparency = 1
	questInfo.Text = "Daily quests and challenges\nComplete objectives to earn rewards!"
	questInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
	questInfo.TextScaled = true
	questInfo.Font = Enum.Font.SourceSans
	questInfo.TextWrapped = true
	questInfo.Parent = parent
end

function MainGameInterface.LoadEventsTab(parent)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "🎲 Random Events"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = parent

	local eventInfo = Instance.new("TextLabel")
	eventInfo.Size = UDim2.new(1, 0, 0, 60)
	eventInfo.BackgroundTransparency = 1
	eventInfo.Text = "Random events occur every 20-30 minutes\nWatch for special bonuses and challenges!"
	eventInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
	eventInfo.TextScaled = true
	eventInfo.Font = Enum.Font.SourceSans
	eventInfo.TextWrapped = true
	eventInfo.Parent = parent
end

function MainGameInterface.LoadBattlePassTab(parent)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "🎫 Battle Pass System"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = parent

	-- Battle Pass Progress
	local progressFrame = Instance.new("Frame")
	progressFrame.Size = UDim2.new(1, 0, 0, 80)
	progressFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	progressFrame.BorderSizePixel = 0
	progressFrame.Parent = parent

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 8)
	progressCorner.Parent = progressFrame

	-- Level Display
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(0.3, 0, 0.5, 0)
	levelLabel.Position = UDim2.new(0, 10, 0, 5)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Level: Loading..."
	levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	levelLabel.TextScaled = true
	levelLabel.Font = Enum.Font.SourceSansBold
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Parent = progressFrame

	-- XP Display
	local xpLabel = Instance.new("TextLabel")
	xpLabel.Size = UDim2.new(0.7, 0, 0.5, 0)
	xpLabel.Position = UDim2.new(0.3, 0, 0, 5)
	xpLabel.BackgroundTransparency = 1
	xpLabel.Text = "XP: Loading..."
	xpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	xpLabel.TextScaled = true
	xpLabel.Font = Enum.Font.SourceSans
	xpLabel.TextXAlignment = Enum.TextXAlignment.Left
	xpLabel.Parent = progressFrame

	-- XP Progress Bar
	local progressBg = Instance.new("Frame")
	progressBg.Size = UDim2.new(1, -20, 0, 20)
	progressBg.Position = UDim2.new(0, 10, 0.5, 5)
	progressBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = progressFrame

	local progressBgCorner = Instance.new("UICorner")
	progressBgCorner.CornerRadius = UDim.new(0, 4)
	progressBgCorner.Parent = progressBg

	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(0.5, 0, 1, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBg

	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0, 4)
	progressBarCorner.Parent = progressBar

	-- Premium Status
	local premiumLabel = Instance.new("TextLabel")
	premiumLabel.Size = UDim2.new(1, -20, 0, 20)
	premiumLabel.Position = UDim2.new(0, 10, 1, -25)
	premiumLabel.BackgroundTransparency = 1
	premiumLabel.Text = "Premium: Loading..."
	premiumLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	premiumLabel.TextScaled = true
	premiumLabel.Font = Enum.Font.SourceSans
	premiumLabel.TextXAlignment = Enum.TextXAlignment.Left
	premiumLabel.Parent = progressFrame

	-- Reward Tiers (showing next few levels)
	local tiersFrame = Instance.new("ScrollingFrame")
	tiersFrame.Size = UDim2.new(1, 0, 0, 200)
	tiersFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	tiersFrame.BorderSizePixel = 0
	tiersFrame.ScrollBarThickness = 6
	tiersFrame.CanvasSize = UDim2.new(0, 0, 0, 2000) -- Will be updated dynamically
	tiersFrame.Parent = parent

	local tiersCorner = Instance.new("UICorner")
	tiersCorner.CornerRadius = UDim.new(0, 8)
	tiersCorner.Parent = tiersFrame

	local tiersLayout = Instance.new("UIListLayout")
	tiersLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tiersLayout.Padding = UDim.new(0, 5)
	tiersLayout.Parent = tiersFrame

	-- Load Battle Pass data and populate tiers
	spawn(function()
		local battlePassData = nil

		-- Get Battle Pass data from server
		local getBattlePassDataRemote = remoteEventsFolder:FindFirstChild("GetBattlePassData")
		if getBattlePassDataRemote then
			local success, data = pcall(function()
				return getBattlePassDataRemote:InvokeServer()
			end)
			if success then
				battlePassData = data
			end
		end

		-- Update progress display
		if battlePassData then
			levelLabel.Text = "Level: " .. (battlePassData.level or 1)
			local xpForNext = battlePassData.level or 1
			local currentXP = battlePassData.xp or 0
			xpLabel.Text = "XP: " .. currentXP .. " / " .. xpForNext .. " (Total: " .. (battlePassData.totalXp or 0) .. ")"

			-- Update progress bar
			local progressPercent = math.min(currentXP / xpForNext, 1)
			progressBar.Size = UDim2.new(progressPercent, 0, 1, 0)

			-- Update premium status
			premiumLabel.Text = "Premium: " .. (battlePassData.hasPremium and "✓ Active" or "✗ Not Purchased")
			premiumLabel.TextColor3 = battlePassData.hasPremium and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(200, 100, 100)
		end

		-- Create tier displays for all 100 levels
		for i = 1, 100 do
			local tierFrame = Instance.new("Frame")
			tierFrame.Size = UDim2.new(1, -10, 0, 60)
			tierFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
			tierFrame.BorderSizePixel = 0
			tierFrame.LayoutOrder = i
			tierFrame.Parent = tiersFrame

			-- Highlight current level
			if battlePassData and i == battlePassData.level then
				tierFrame.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
			elseif battlePassData and i < battlePassData.level then
				tierFrame.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
			end

			local tierCorner = Instance.new("UICorner")
			tierCorner.CornerRadius = UDim.new(0, 6)
			tierCorner.Parent = tierFrame

			-- Level number
			local levelNum = Instance.new("TextLabel")
			levelNum.Size = UDim2.new(0, 50, 1, 0)
			levelNum.Position = UDim2.new(0, 5, 0, 0)
			levelNum.BackgroundTransparency = 1
			levelNum.Text = tostring(i)
			levelNum.TextColor3 = Color3.fromRGB(255, 255, 255)
			levelNum.TextScaled = true
			levelNum.Font = Enum.Font.SourceSansBold
			levelNum.Parent = tierFrame

			-- Get reward data from Battle Pass system
			local freeRewardName = "Loading..."
			local premiumRewardName = "Loading..."

			-- Try to get actual reward data from client
			if _G.BattlePassClient then
				local tierData = _G.BattlePassClient.getTierData(i)
				if tierData then
					freeRewardName = tierData.free_reward.name or ("Tier " .. i .. " Free Reward")
					premiumRewardName = tierData.premium_reward.name or ("Tier " .. i .. " Premium Reward")
				end
			else
				-- Fallback reward names based on tier ranges
				if i <= 10 then
					freeRewardName = "Basic Reward " .. i
					premiumRewardName = "Premium Basic " .. i
				elseif i <= 25 then
					freeRewardName = "Advanced Reward " .. i
					premiumRewardName = "Premium Advanced " .. i
				elseif i <= 50 then
					freeRewardName = "Elite Reward " .. i
					premiumRewardName = "Premium Elite " .. i
				elseif i <= 75 then
					freeRewardName = "Legendary Reward " .. i
					premiumRewardName = "Premium Legendary " .. i
				else
					freeRewardName = "Ultimate Reward " .. i
					premiumRewardName = "Premium Ultimate " .. i
				end
			end

			-- Free reward
			local freeReward = Instance.new("TextLabel")
			freeReward.Size = UDim2.new(0.4, -30, 1, 0)
			freeReward.Position = UDim2.new(0, 60, 0, 0)
			freeReward.BackgroundTransparency = 1
			freeReward.Text = "Free: " .. freeRewardName
			freeReward.TextColor3 = Color3.fromRGB(200, 200, 200)
			freeReward.TextScaled = true
			freeReward.Font = Enum.Font.SourceSans
			freeReward.TextXAlignment = Enum.TextXAlignment.Left
			freeReward.TextWrapped = true
			freeReward.Parent = tierFrame

			-- Premium reward
			local premiumReward = Instance.new("TextLabel")
			premiumReward.Size = UDim2.new(0.4, -30, 1, 0)
			premiumReward.Position = UDim2.new(0.5, 0, 0, 0)
			premiumReward.BackgroundTransparency = 1
			premiumReward.Text = "Premium: " .. premiumRewardName
			premiumReward.TextColor3 = Color3.fromRGB(255, 215, 0)
			premiumReward.TextScaled = true
			premiumReward.Font = Enum.Font.SourceSans
			premiumReward.TextXAlignment = Enum.TextXAlignment.Left
			premiumReward.TextWrapped = true
			premiumReward.Parent = tierFrame

			-- Claim buttons
			local claimFree = Instance.new("TextButton")
			claimFree.Size = UDim2.new(0, 80, 0, 25)
			claimFree.Position = UDim2.new(1, -170, 0.5, -12.5)
			claimFree.BackgroundColor3 = Color3.fromRGB(70, 180, 70)
			claimFree.Text = "Claim"
			claimFree.TextColor3 = Color3.fromRGB(255, 255, 255)
			claimFree.TextScaled = true
			claimFree.Font = Enum.Font.SourceSans
			claimFree.BorderSizePixel = 0
			claimFree.Parent = tierFrame

			local claimFreeCorner = Instance.new("UICorner")
			claimFreeCorner.CornerRadius = UDim.new(0, 4)
			claimFreeCorner.Parent = claimFree

			local claimPremium = Instance.new("TextButton")
			claimPremium.Size = UDim2.new(0, 80, 0, 25)
			claimPremium.Position = UDim2.new(1, -85, 0.5, -12.5)
			claimPremium.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			claimPremium.Text = "Claim+"
			claimPremium.TextColor3 = Color3.fromRGB(0, 0, 0)
			claimPremium.TextScaled = true
			claimPremium.Font = Enum.Font.SourceSans
			claimPremium.BorderSizePixel = 0
			claimPremium.Parent = tierFrame

			local claimPremiumCorner = Instance.new("UICorner")
			claimPremiumCorner.CornerRadius = UDim.new(0, 4)
			claimPremiumCorner.Parent = claimPremium

			-- Update button states based on data
			if battlePassData then
				local canClaimFree = i <= battlePassData.level and not (battlePassData.claimedRewards and battlePassData.claimedRewards.free and battlePassData.claimedRewards.free[i])
				local canClaimPremium = i <= battlePassData.level and battlePassData.hasPremium and not (battlePassData.claimedRewards and battlePassData.claimedRewards.premium and battlePassData.claimedRewards.premium[i])

				if not canClaimFree or (battlePassData.claimedRewards and battlePassData.claimedRewards.free and battlePassData.claimedRewards.free[i]) then
					claimFree.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					claimFree.Text = (battlePassData.claimedRewards and battlePassData.claimedRewards.free and battlePassData.claimedRewards.free[i]) and "Claimed" or "Locked"
				end

				if not canClaimPremium or (battlePassData.claimedRewards and battlePassData.claimedRewards.premium and battlePassData.claimedRewards.premium[i]) then
					claimPremium.BackgroundColor3 = Color3.fromRGB(150, 150, 100)
					claimPremium.Text = (battlePassData.claimedRewards and battlePassData.claimedRewards.premium and battlePassData.claimedRewards.premium[i]) and "Claimed" or "Locked"
				end
			end

			-- Button functionality
			claimFree.MouseButton1Click:Connect(function()
				local claimRewardRemote = remoteEventsFolder:FindFirstChild("ClaimBattlePassReward")
				if claimRewardRemote then
					claimRewardRemote:FireServer(i, "free")
				end
			end)

			claimPremium.MouseButton1Click:Connect(function()
				local claimRewardRemote = remoteEventsFolder:FindFirstChild("ClaimBattlePassReward")
				if claimRewardRemote then
					claimRewardRemote:FireServer(i, "premium")
				end
			end)
		end

		-- Update canvas size for scrolling
		tiersFrame.CanvasSize = UDim2.new(0, 0, 0, 100 * 65) -- 100 tiers * 65 pixels each
	end)

	-- XP Sources Info
	local xpInfo = Instance.new("TextLabel")
	xpInfo.Size = UDim2.new(1, 0, 0, 80)
	xpInfo.BackgroundTransparency = 1
	xpInfo.Text = "💡 Earn XP by:\n• Selling bananas (1 XP each)\n• Completing quests (50 XP)\n• Buying fruit (5-2500 XP based on rarity)\n• Participating in events (25 XP)"
	xpInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
	xpInfo.TextScaled = true
	xpInfo.Font = Enum.Font.SourceSans
	xpInfo.TextXAlignment = Enum.TextXAlignment.Left
	xpInfo.TextWrapped = true
	xpInfo.Parent = parent
end

-- Handle quick actions
function MainGameInterface.HandleQuickAction(action)
	if action == "sell_all" then
		local sellBananasRemote = remoteEventsFolder:FindFirstChild("SellBananas")
		if sellBananasRemote then
			sellBananasRemote:FireServer("all")
		end
	elseif action == "toggle_afk" then
		local toggleAFKRemote = remoteEventsFolder:FindFirstChild("ToggleAFK")
		if toggleAFKRemote then
			toggleAFKRemote:FireServer()
		end
	elseif action == "clear_pests" then
		local clearPestsRemote = remoteEventsFolder:FindFirstChild("ClearPests")
		if clearPestsRemote then
			clearPestsRemote:FireServer()
		end
	elseif action == "hire_worker" then
		local hireWorkerRemote = remoteEventsFolder:FindFirstChild("HireWorker")
		if hireWorkerRemote then
			hireWorkerRemote:FireServer()
		end
	elseif action == "buy_sprinkler" then
		local purchaseSprinklerRemote = remoteEventsFolder:FindFirstChild("PurchaseSprinkler")
		if purchaseSprinklerRemote then
			purchaseSprinklerRemote:FireServer()
		end
	elseif action == "view_quests" then
		MainGameInterface.SwitchTab("Quests")
		if not isVisible then
			MainGameInterface.ToggleMainGUI()
		end
	elseif action == "view_battlepass" then
		MainGameInterface.SwitchTab("Battle Pass")
		if not isVisible then
			MainGameInterface.ToggleMainGUI()
		end
	end
end

-- Toggle main GUI
function MainGameInterface.ToggleMainGUI()
	if not mainFrame then return end

	isVisible = not isVisible

	if isVisible then
		mainFrame.Visible = true
		TweenService:Create(mainFrame, TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Back), {
			Position = UDim2.new(1, -620, 0.5, -250)
		}):Play()
	else
		TweenService:Create(mainFrame, TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Back), {
			Position = UDim2.new(1, 20, 0.5, -250)
		}):Play()

		task.wait(Config.AnimationTime)
		mainFrame.Visible = false
	end
end

-- Toggle quick actions panel
function MainGameInterface.ToggleQuickActions()
	if not quickActionsPanel then return end

	isQuickPanelVisible = not isQuickPanelVisible

	if isQuickPanelVisible then
		quickActionsPanel.Visible = true
		TweenService:Create(quickActionsPanel, TweenInfo.new(Config.AnimationTime), {
			Position = UDim2.new(0, 20, 1, -270)
		}):Play()
	else
		TweenService:Create(quickActionsPanel, TweenInfo.new(Config.AnimationTime), {
			Position = UDim2.new(0, -220, 1, -270)
		}):Play()

		task.wait(Config.AnimationTime)
		quickActionsPanel.Visible = false
	end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Config.ToggleKey then
		MainGameInterface.ToggleMainGUI()
	elseif input.KeyCode == Config.QuickActionsKey then
		MainGameInterface.ToggleQuickActions()
	end
end)

-- Initialize
MainGameInterface.CreateMainGUI()
MainGameInterface.CreateQuickActionsPanel()

-- Global access
_G.MainGameInterface = MainGameInterface

print("🎮 Main Game Interface Loaded!")
print("   - Press G to toggle main interface")
print("   - Press Q to toggle quick actions")
print("   - 8 tabs: Status, Workers, Sprinklers, Selling, AFK, Rebirth, Quests, Events")

return MainGameInterface
