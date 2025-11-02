-- SystemTest.lua - Comprehensive Test Script for Fruit Farming Game
-- Run this script to test the entire fruit farming system

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("🚀 FRUIT FARMING GAME SYSTEM TEST STARTING...")
print("================================================")

-- Test 1: Check if BanappleTree template exists
local function testBanappleTreeTemplate()
	print("\n🌳 TEST 1: BanappleTree Template Check")
	print("-------------------------------------")

	local treeTemplate = Workspace:FindFirstChild("BanappleTree")
	if treeTemplate then
		print("✅ BanappleTree found in Workspace")
		if treeTemplate:IsA("Model") then
			print("✅ BanappleTree is a Model")
			print("   PrimaryPart:", treeTemplate.PrimaryPart and treeTemplate.PrimaryPart.Name or "None")

			local parts = {}
			for _, child in ipairs(treeTemplate:GetChildren()) do
				if child:IsA("BasePart") then
					table.insert(parts, child.Name)
				end
			end
			print("   Parts:", table.concat(parts, ", "))

			if #parts > 0 then
				print("✅ BanappleTree has BaseParts for positioning")
			else
				print("❌ BanappleTree has no BaseParts - this will cause positioning issues")
			end
		else
			print("❌ BanappleTree is not a Model")
		end
	else
		print("❌ BanappleTree template NOT found in Workspace")
		print("🔧 Creating a basic BanappleTree template...")

		-- Create a basic tree template
		local tree = Instance.new("Model")
		tree.Name = "BanappleTree"

		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Size = Vector3.new(2, 10, 2)
		trunk.Color = Color3.fromRGB(101, 67, 33)
		trunk.Material = Enum.Material.Wood
		trunk.Shape = Enum.PartType.Cylinder
		trunk.TopSurface = Enum.SurfaceType.Smooth
		trunk.BottomSurface = Enum.SurfaceType.Smooth
		trunk.Parent = tree

		local leaves = Instance.new("Part")
		leaves.Name = "Leaves"
		leaves.Size = Vector3.new(8, 8, 8)
		leaves.Color = Color3.fromRGB(75, 151, 75)
		leaves.Material = Enum.Material.Grass
		leaves.Shape = Enum.PartType.Ball
		leaves.TopSurface = Enum.SurfaceType.Smooth
		leaves.BottomSurface = Enum.SurfaceType.Smooth
		leaves.Position = trunk.Position + Vector3.new(0, 9, 0)
		leaves.Parent = tree

		tree.PrimaryPart = trunk
		tree.Parent = Workspace

		print("✅ Created basic BanappleTree template")
	end
end

-- Test 2: Check PlotSystem
local function testPlotSystem()
	print("\n🏠 TEST 2: Plot System Check")
	print("---------------------------")

	-- Check if PlotFinder script is running
	if _G.PlotSystem then
		print("✅ PlotSystem global is available")

		-- Check functions
		local functions = {"getPlayerPlot", "assignPlotToPlayer", "getPlotData", "isPositionInPlot"}
		for _, funcName in ipairs(functions) do
			if _G.PlotSystem[funcName] then
				print("✅ PlotSystem." .. funcName .. " is available")
			else
				print("❌ PlotSystem." .. funcName .. " is missing")
			end
		end

		-- Check plots folder
		local plotsFolder = Workspace:FindFirstChild("Plots")
		if plotsFolder then
			print("✅ Plots folder exists")
			local plotCount = #plotsFolder:GetChildren()
			print("   Current plots:", plotCount)
		else
			print("❌ Plots folder not found")
		end

	else
		print("❌ PlotSystem not available - PlotFinder.lua may not be running")
	end
end

-- Test 3: Check SeedSystem
local function testSeedSystem()
	print("\n🌱 TEST 3: Seed System Check")
	print("----------------------------")

	if _G.SeedSystem then
		print("✅ SeedSystem global is available")

		-- Check functions
		local functions = {"getSeedInventory", "plantSeed", "giveSeedsToPlayer"}
		for _, funcName in ipairs(functions) do
			if _G.SeedSystem[funcName] then
				print("✅ SeedSystem." .. funcName .. " is available")
			else
				print("❌ SeedSystem." .. funcName .. " is missing")
			end
		end
	else
		print("❌ SeedSystem not available - SeedGrowth.lua may not be running")
	end
end

-- Test 4: Check RemoteEvents
local function testRemoteEvents()
	print("\n📡 TEST 4: RemoteEvents Check")
	print("-----------------------------")

	local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEventsFolder then
		print("✅ RemoteEvents folder exists")

		local expectedRemotes = {"PlantSeed", "UpdateSeedGUI"}
		for _, remoteName in ipairs(expectedRemotes) do
			local remote = remoteEventsFolder:FindFirstChild(remoteName)
			if remote then
				print("✅ " .. remoteName .. " RemoteEvent exists")
			else
				print("❌ " .. remoteName .. " RemoteEvent missing")
			end
		end
	else
		print("❌ RemoteEvents folder not found")
	end
end

-- Test 5: Simulate player joining and getting a plot
local function testPlayerPlotAssignment()
	print("\n👤 TEST 5: Player Plot Assignment Simulation")
	print("--------------------------------------------")

	if not _G.PlotSystem then
		print("❌ Cannot test - PlotSystem not available")
		return
	end

	-- Check if there are any existing plots
	local plotsFolder = Workspace:FindFirstChild("Plots")
	if plotsFolder and #plotsFolder:GetChildren() > 0 then
		print("✅ Plots already exist from previous runs")
		for _, plot in ipairs(plotsFolder:GetChildren()) do
			print("   Plot:", plot.Name)
		end
	else
		print("ℹ️ No plots exist yet - they will be created when players join")
	end
end

-- Test 6: Check for harvest system compatibility
local function testHarvestSystemCompatibility()
	print("\n🍌 TEST 6: Harvest System Compatibility")
	print("--------------------------------------")

	-- Check if harvest scripts exist
	local harvestClient = game.StarterPlayer.StarterPlayerScripts:FindFirstChild("HarvestFruit")
	local harvestServer = game.ServerScriptService:FindFirstChild("HarvestFruitServer")

	if harvestClient then
		print("✅ HarvestFruit client script found")
	else
		print("❌ HarvestFruit client script not found")
	end

	if harvestServer then
		print("✅ HarvestFruitServer script found")
	else
		print("❌ HarvestFruitServer script not found")
	end

	-- Check if PlotBananaGrowth is running
	if _G.PlotBananaGrowth then
		print("✅ PlotBananaGrowth system is running")
	else
		print("❌ PlotBananaGrowth system not found")
	end
end

-- Run all tests
local function runAllTests()
	testBanappleTreeTemplate()
	task.wait(1)
	testPlotSystem()
	task.wait(1)
	testSeedSystem()
	task.wait(1)
	testRemoteEvents()
	task.wait(1)
	testPlayerPlotAssignment()
	task.wait(1)
	testHarvestSystemCompatibility()

	print("\n🏁 SYSTEM TEST COMPLETE")
	print("======================")
	print("If any tests failed, check the console for error messages.")
	print("Make sure all scripts are properly placed and running.")
end

-- Start tests after a short delay to allow other scripts to load
task.wait(3)
runAllTests()
