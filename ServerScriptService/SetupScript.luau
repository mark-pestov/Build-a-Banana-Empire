-- SetupScript.lua - Automated Setup for Fruit Farming Game
-- This script sets up all required components for the fruit farming game

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

print("🔧 FRUIT FARMING GAME SETUP STARTING...")
print("=====================================")

-- 1. Create BanappleTree template if it doesn't exist
local function setupBanappleTree()
	print("🌳 Setting up BanappleTree template...")

	local existingTree = Workspace:FindFirstChild("BanappleTree")
	if existingTree then
		print("✅ BanappleTree already exists")
		return existingTree
	end

	-- Create tree model
	local tree = Instance.new("Model")
	tree.Name = "BanappleTree"

	-- Create trunk
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(2, 10, 2)
	trunk.Color = Color3.fromRGB(101, 67, 33)
	trunk.Material = Enum.Material.Wood
	trunk.Shape = Enum.PartType.Cylinder
	trunk.TopSurface = Enum.SurfaceType.Smooth
	trunk.BottomSurface = Enum.SurfaceType.Smooth
	trunk.Anchored = true
	trunk.Parent = tree

	-- Create leaves
	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Size = Vector3.new(8, 8, 8)
	leaves.Color = Color3.fromRGB(75, 151, 75)
	leaves.Material = Enum.Material.Grass
	leaves.Shape = Enum.PartType.Ball
	leaves.TopSurface = Enum.SurfaceType.Smooth
	leaves.BottomSurface = Enum.SurfaceType.Smooth
	leaves.Anchored = true
	leaves.Parent = tree

	-- Position leaves on top of trunk
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = trunk
	weld.Part1 = leaves
	weld.Parent = trunk

	leaves.CFrame = trunk.CFrame * CFrame.new(0, 9, 0)

	-- Set PrimaryPart
	tree.PrimaryPart = trunk

	-- Add growth attribute (trees start not fully grown)
	tree:SetAttribute("IsFullyGrown", false)

	tree.Parent = Workspace
	print("✅ Created BanappleTree template")
	return tree
end

-- 2. Setup RemoteEvents folder
local function setupRemoteEvents()
	print("📡 Setting up RemoteEvents...")

	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "RemoteEvents"
		remoteEventsFolder.Parent = ReplicatedStorage
		print("✅ Created RemoteEvents folder")
	else
		print("✅ RemoteEvents folder already exists")
	end

	-- Create required RemoteEvents
	local requiredRemotes = {"PlantSeed", "UpdateSeedGUI"}

	for _, remoteName in ipairs(requiredRemotes) do
		local existing = remoteEventsFolder:FindFirstChild(remoteName)
		if not existing then
			local remote = Instance.new("RemoteEvent")
			remote.Name = remoteName
			remote.Parent = remoteEventsFolder
			print("✅ Created " .. remoteName .. " RemoteEvent")
		else
			print("✅ " .. remoteName .. " RemoteEvent already exists")
		end
	end
end

-- 3. Setup Plots folder
local function setupPlotsFolder()
	print("🏠 Setting up Plots folder...")

	local plotsFolder = Workspace:FindFirstChild("Plots")
	if not plotsFolder then
		plotsFolder = Instance.new("Folder")
		plotsFolder.Name = "Plots"
		plotsFolder.Parent = Workspace
		print("✅ Created Plots folder")
	else
		print("✅ Plots folder already exists")
	end
end

-- 4. Check script placement
local function checkScriptPlacement()
	print("📝 Checking script placement...")

	-- Server scripts
	local serverScripts = {
		"PlotFinder.lua",
		"SeedGrowth.lua", 
		"PlotBananaGrowth.lua",
		"HarvestFruitServer.lua"
	}

	for _, scriptName in ipairs(serverScripts) do
		local script = ServerScriptService:FindFirstChild(scriptName:gsub("%.lua", ""))
		if script then
			print("✅ Found " .. scriptName .. " in ServerScriptService")
		else
			print("❌ Missing " .. scriptName .. " in ServerScriptService")
		end
	end

	-- Client scripts
	local clientScripts = {
		"SeedPlantingClient.lua",
		"HarvestFruit.lua",
		"FruitMouseHoverGUI.lua"
	}

	for _, scriptName in ipairs(clientScripts) do
		local script = StarterPlayer.StarterPlayerScripts:FindFirstChild(scriptName:gsub("%.lua", ""))
		if script then
			print("✅ Found " .. scriptName .. " in StarterPlayerScripts")
		else
			print("❌ Missing " .. scriptName .. " in StarterPlayerScripts")
		end
	end
end

-- 5. Setup workspace lighting for better visibility
local function setupLighting()
	print("💡 Setting up lighting...")

	local lighting = game:GetService("Lighting")
	lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(70, 70, 70)
	lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
	lighting.ShadowSoftness = 0.2

	print("✅ Lighting configured for better visibility")
end

-- 6. Create test instructions
local function createTestInstructions()
	print("📋 Creating test instructions...")

	local instructions = Instance.new("ScreenGui")
	instructions.Name = "GameInstructions"
	instructions.Parent = game.StarterPlayer.StarterGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.3, 0, 0.4, 0)
	frame.Position = UDim2.new(0.02, 0, 0.3, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = instructions

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.15, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.Text = "🍌 FRUIT FARMING GAME"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.BackgroundTransparency = 1
	title.Parent = frame

	local instructionText = Instance.new("TextLabel")
	instructionText.Size = UDim2.new(0.95, 0, 0.8, 0)
	instructionText.Position = UDim2.new(0.025, 0, 0.15, 0)
	instructionText.Text = [[
HOW TO PLAY:

1. Join the game to get your own plot
2. You start with 3 Banapple Tree Seeds
3. Click on the brown dirt patch in your plot to plant a seed
4. Trees take 10 seconds to fully grow
5. Once grown, bananas will spawn automatically
6. Click bananas to harvest them
7. Check your seed inventory in the top-left corner

Have fun farming! 🌱]]
	instructionText.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionText.TextScaled = true
	instructionText.Font = Enum.Font.SourceSans
	instructionText.BackgroundTransparency = 1
	instructionText.TextXAlignment = Enum.TextXAlignment.Left
	instructionText.TextYAlignment = Enum.TextYAlignment.Top
	instructionText.Parent = frame

	print("✅ Created game instructions GUI")
end

-- Run setup
local function runSetup()
	setupBanappleTree()
	task.wait(0.5)
	setupRemoteEvents()
	task.wait(0.5)
	setupPlotsFolder()
	task.wait(0.5)
	setupLighting()
	task.wait(0.5)
	createTestInstructions()
	task.wait(0.5)
	checkScriptPlacement()

	print("\n🎉 SETUP COMPLETE!")
	print("================")
	print("The fruit farming game is ready to test!")
	print("Players can now join and start farming.")
	print("\nNext steps:")
	print("1. Make sure all scripts are in the correct locations")
	print("2. Test by having a player join the game")
	print("3. Check console for any error messages")
end

-- Start setup
task.wait(1)
runSetup()
