-- Plot Finder and Assignment System
-- This script handles plot assignment and player spawning for the fruit farming game

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Configuration
local PLOT_SIZE = Vector3.new(50, 1, 50) -- Size of each plot (50x50 studs)
local PLOTS_PER_ROW = 5 -- How many plots in each row
local PLOT_SPACING = 10 -- Space between plots
local STARTING_PLOT_POSITION = Vector3.new(0, 5, 0) -- Where the first plot starts
local SPAWN_HEIGHT_OFFSET = 5 -- How high above the plot to spawn the player

-- DataStore for plot ownership
local plotDataStore = DataStoreService:GetDataStore("PlotOwnership")

-- Storage for plot information
local plotData = {} -- {plotId: {owner: userId, position: Vector3, model: plotModel}}
local playerPlots = {} -- {userId: plotId}

-- Create plots folder
local plotsFolder = Workspace:FindFirstChild("Plots")
if not plotsFolder then
	plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = Workspace
end

-- Function to calculate plot position based on plot number
local function calculatePlotPosition(plotNumber)
	local row = math.floor((plotNumber - 1) / PLOTS_PER_ROW)
	local col = (plotNumber - 1) % PLOTS_PER_ROW

	local x = STARTING_PLOT_POSITION.X + (col * (PLOT_SIZE.X + PLOT_SPACING))
	local z = STARTING_PLOT_POSITION.Z + (row * (PLOT_SIZE.Z + PLOT_SPACING))
	local y = STARTING_PLOT_POSITION.Y

	return Vector3.new(x, y, z)
end

-- Function to create a visual plot
local function createPlotModel(plotId, position)
	local plotModel = Instance.new("Model")
	plotModel.Name = "Plot_" .. plotId

	-- Create the base platform
	local basePart = Instance.new("Part")
	basePart.Name = "PlotBase"
	basePart.Size = PLOT_SIZE
	basePart.Position = position
	basePart.Anchored = true
	basePart.Material = Enum.Material.Grass
	basePart.Color = Color3.fromRGB(106, 127, 45) -- Dark green
	basePart.Parent = plotModel

	-- Create border walls
	local wallHeight = 2
	local wallThickness = 1

	-- Front wall
	local frontWall = Instance.new("Part")
	frontWall.Name = "FrontWall"
	frontWall.Size = Vector3.new(PLOT_SIZE.X, wallHeight, wallThickness)
	frontWall.Position = position + Vector3.new(0, wallHeight/2, -PLOT_SIZE.Z/2)
	frontWall.Anchored = true
	frontWall.Material = Enum.Material.Wood
	frontWall.Color = Color3.fromRGB(139, 69, 19) -- Brown
	frontWall.Parent = plotModel

	-- Back wall
	local backWall = frontWall:Clone()
	backWall.Name = "BackWall"
	backWall.Position = position + Vector3.new(0, wallHeight/2, PLOT_SIZE.Z/2)
	backWall.Parent = plotModel

	-- Left wall
	local leftWall = Instance.new("Part")
	leftWall.Name = "LeftWall"
	leftWall.Size = Vector3.new(wallThickness, wallHeight, PLOT_SIZE.Z)
	leftWall.Position = position + Vector3.new(-PLOT_SIZE.X/2, wallHeight/2, 0)
	leftWall.Anchored = true
	leftWall.Material = Enum.Material.Wood
	leftWall.Color = Color3.fromRGB(139, 69, 19)
	leftWall.Parent = plotModel

	-- Right wall
	local rightWall = leftWall:Clone()
	rightWall.Name = "RightWall"
	rightWall.Position = position + Vector3.new(PLOT_SIZE.X/2, wallHeight/2, 0)
	rightWall.Parent = plotModel

	-- Create a sign for the plot
	local signPart = Instance.new("Part")
	signPart.Name = "PlotSign"
	signPart.Size = Vector3.new(6, 4, 1)
	signPart.Position = position + Vector3.new(0, 3, -PLOT_SIZE.Z/2 - 2)
	signPart.Anchored = true
	signPart.Material = Enum.Material.Wood
	signPart.Color = Color3.fromRGB(160, 82, 45) -- Lighter brown
	signPart.Parent = plotModel

	-- Add sign text and profile picture
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = signPart

	-- Plot number label at the top
	local plotLabel = Instance.new("TextLabel")
	plotLabel.Size = UDim2.new(1, 0, 0.3, 0)
	plotLabel.Position = UDim2.new(0, 0, 0, 0)
	plotLabel.BackgroundTransparency = 1
	plotLabel.Text = "Plot #" .. plotId
	plotLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	plotLabel.TextScaled = true
	plotLabel.Font = Enum.Font.SourceSansBold
	plotLabel.Parent = signGui

	-- Container for profile picture and username
	local profileFrame = Instance.new("Frame")
	profileFrame.Size = UDim2.new(1, 0, 0.7, 0)
	profileFrame.Position = UDim2.new(0, 0, 0.3, 0)
	profileFrame.BackgroundTransparency = 1
	profileFrame.Parent = signGui

	-- Profile picture on the left
	local profilePicture = Instance.new("ImageLabel")
	profilePicture.Size = UDim2.new(0.35, 0, 0.8, 0)
	profilePicture.Position = UDim2.new(0.05, 0, 0.1, 0)
	profilePicture.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	profilePicture.BorderSizePixel = 2
	profilePicture.BorderColor3 = Color3.fromRGB(255, 255, 255)
	profilePicture.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Default placeholder
	profilePicture.Parent = profileFrame

	-- Add corner rounding to profile picture
	local profileCorner = Instance.new("UICorner")
	profileCorner.CornerRadius = UDim.new(0.1, 0)
	profileCorner.Parent = profilePicture

	-- Username label on the right
	local ownerLabel = Instance.new("TextLabel")
	ownerLabel.Size = UDim2.new(0.55, 0, 0.8, 0)
	ownerLabel.Position = UDim2.new(0.4, 0, 0.1, 0)
	ownerLabel.BackgroundTransparency = 1
	ownerLabel.Text = "Available"
	ownerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	ownerLabel.TextScaled = true
	ownerLabel.Font = Enum.Font.SourceSans
	ownerLabel.TextXAlignment = Enum.TextXAlignment.Left
	ownerLabel.Parent = profileFrame

	-- Store reference to labels for updating
	plotModel:SetAttribute("PlotId", plotId)
	plotModel:SetAttribute("PlotLabel", plotLabel)
	plotModel:SetAttribute("OwnerLabel", ownerLabel)

	-- Create dirt patch for planting seeds
	local dirtPatch = Instance.new("Part")
	dirtPatch.Name = "DirtPatch"
	dirtPatch.Size = Vector3.new(8, 0.5, 8)
	dirtPatch.Position = position + Vector3.new(0, 1, 0)
	dirtPatch.Anchored = true
	dirtPatch.Material = Enum.Material.Ground
	dirtPatch.Color = Color3.fromRGB(101, 67, 33) -- Brown dirt color
	dirtPatch.Parent = plotModel

	-- Create invisible seed planting detection area (required by SeedGrowth.lua)
	local seedPlantingPart = Instance.new("Part")
	seedPlantingPart.Name = "SeedPlantingPart"
	seedPlantingPart.Size = Vector3.new(8, 1, 8) -- Same size as dirt patch
	seedPlantingPart.Position = position + Vector3.new(0, 1.5, 0) -- Above dirt patch
	seedPlantingPart.Anchored = true
	seedPlantingPart.CanCollide = false
	seedPlantingPart.Transparency = 1 -- Invisible
	seedPlantingPart.Parent = plotModel

	-- Add click detector for seed planting
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 20
	clickDetector.Parent = seedPlantingPart

	-- Create harvest area (where fruits spawn - required by HarvestFruitServer.lua)
	local harvestArea = Instance.new("Part")
	harvestArea.Name = "HarvestArea"
	harvestArea.Size = Vector3.new(10, 0.1, 10) -- Slightly larger than dirt patch
	harvestArea.Position = position + Vector3.new(0, 1.5, 0)
	harvestArea.Anchored = true
	harvestArea.CanCollide = false
	harvestArea.Transparency = 1 -- Invisible
	harvestArea.Parent = plotModel

	-- Store plot ID in all parts for system integration
	dirtPatch:SetAttribute("PlotId", plotId)
	seedPlantingPart:SetAttribute("PlotId", plotId)
	harvestArea:SetAttribute("PlotId", plotId)

	plotModel.Parent = plotsFolder
	return plotModel
end

-- Function to update plot sign with profile picture and username
local function updatePlotSign(plotId, player)
	local plotModel = plotsFolder:FindFirstChild("Plot_" .. plotId)
	if plotModel then
		local signPart = plotModel:FindFirstChild("PlotSign")
		if signPart then
			local signGui = signPart:FindFirstChild("SurfaceGui")
			if signGui then
				local profileFrame = signGui:FindFirstChild("Frame")
				if profileFrame then
					local profilePicture = profileFrame:FindFirstChild("ImageLabel")
					local ownerLabel = profileFrame:FindFirstChild("TextLabel")

					if player then
						-- Update username
						if ownerLabel then
							ownerLabel.Text = player.Name
							ownerLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
						end

						-- Update profile picture
						if profilePicture then
							local userId = player.UserId

							-- Use Players service to get the thumbnail
							local success, imageId = pcall(function()
								return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
							end)

							if success and imageId then
								profilePicture.Image = imageId
								print("Updated profile picture for", player.Name, "in Plot #" .. plotId)
							else
								-- Fallback to default avatar icon
								profilePicture.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
								warn("Failed to load profile picture for", player.Name)
							end
						end
					else
						-- Plot is available
						if ownerLabel then
							ownerLabel.Text = "Available"
							ownerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
						end

						if profilePicture then
							profilePicture.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
						end
					end
				end
			end
		end
	end
end

-- Function to create initial plots
local function createInitialPlots(numPlots)
	print("Creating", numPlots, "initial plots...")

	for i = 1, numPlots do
		local position = calculatePlotPosition(i)
		local plotModel = createPlotModel(i, position)

		plotData[i] = {
			owner = nil,
			position = position,
			model = plotModel
		}

		print("Created Plot #" .. i .. " at position:", position)
	end

	print("All plots created successfully!")
end

-- Function to find an unclaimed plot
local function findUnclaimedPlot()
	for plotId, data in pairs(plotData) do
		if not data.owner then
			print("Found unclaimed plot:", plotId)
			return plotId
		end
	end

	-- If no unclaimed plot exists, create a new one
	local newPlotId = #plotData + 1
	local position = calculatePlotPosition(newPlotId)
	local plotModel = createPlotModel(newPlotId, position)

	plotData[newPlotId] = {
		owner = nil,
		position = position,
		model = plotModel
	}

	print("Created new plot:", newPlotId, "at position:", position)
	return newPlotId
end

-- Function to assign plot to player
local function assignPlotToPlayer(player, plotId)
	local userId = player.UserId

	-- Check if player already has a plot
	if playerPlots[userId] then
		print("Player", player.Name, "already has plot:", playerPlots[userId])
		return playerPlots[userId]
	end

	-- Assign the plot
	plotData[plotId].owner = userId
	playerPlots[userId] = plotId

	-- Update plot sign
	updatePlotSign(plotId, player)

	-- Save to DataStore
	local success, errorMessage = pcall(function()
		plotDataStore:SetAsync("Plot_" .. plotId, userId)
		plotDataStore:SetAsync("Player_" .. userId, plotId)
	end)

	if success then
		print("Successfully assigned Plot #" .. plotId .. " to", player.Name)
	else
		warn("Failed to save plot assignment for", player.Name .. ":", errorMessage)
	end

	return plotId
end

-- Function to load plot ownership from DataStore
local function loadPlotOwnership()
	print("Loading plot ownership data...")

	for plotId, data in pairs(plotData) do
		local success, ownerId = pcall(function()
			return plotDataStore:GetAsync("Plot_" .. plotId)
		end)

		if success and ownerId then
			data.owner = ownerId
			playerPlots[ownerId] = plotId

			-- Try to get player object for sign update
			local player = Players:GetPlayerByUserId(ownerId)
			if player then
				updatePlotSign(plotId, player)
			else
				-- Player not online, update with nil to show "Available"
				updatePlotSign(plotId, nil)
			end

			print("Loaded: Plot #" .. plotId .. " owned by", playerName)
		end
	end

	print("Plot ownership data loaded.")
end

-- Function to get spawn position for a plot
local function getPlotSpawnPosition(plotId)
	local plotData = plotData[plotId]
	if not plotData then
		warn("Plot", plotId, "not found!")
		return Vector3.new(0, 10, 0)
	end

	-- Spawn player in front of the plot (outside the front wall)
	local plotPosition = plotData.position
	local spawnPosition = Vector3.new(
		plotPosition.X,
		plotPosition.Y + SPAWN_HEIGHT_OFFSET,
		plotPosition.Z - (PLOT_SIZE.Z/2) - 8 -- 8 studs in front of the plot
	)

	print("Spawn position for Plot #" .. plotId .. ":", spawnPosition)
	return spawnPosition
end

-- Function to spawn player at their plot
local function spawnPlayerAtPlot(player)
	-- Find or assign a plot to the player
	local plotId = playerPlots[player.UserId]

	if not plotId then
		-- Find an unclaimed plot
		plotId = findUnclaimedPlot()
		-- Assign it to the player
		plotId = assignPlotToPlayer(player, plotId)
	else
		-- Player already has a plot, update the sign with their current profile picture
		updatePlotSign(plotId, player)
	end

	-- Get spawn position
	local spawnPosition = getPlotSpawnPosition(plotId)

	-- Wait for character to load
	if not player.Character then
		player.CharacterAdded:Wait()
	end

	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			humanoidRootPart.CFrame = CFrame.new(spawnPosition, spawnPosition + Vector3.new(0, 0, 1))
			print("Spawned", player.Name, "at Plot #" .. plotId)
		end
	end

	return plotId
end

-- Function to handle player joining
local function onPlayerAdded(player)
	print("Player joined:", player.Name)

	-- Wait a moment for the player to fully load
	task.wait(1)

	-- Spawn player at their plot
	spawnPlayerAtPlot(player)
end

-- Function to handle player leaving
local function onPlayerRemoving(player)
	print("Player leaving:", player.Name)
	-- Note: We don't remove plot ownership when players leave
	-- Plots remain owned so players can return to them
end

-- Function to clean up when player's character spawns
local function onCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Small delay to ensure character is fully loaded
	task.wait(0.5)

	local plotId = playerPlots[player.UserId]
	if plotId then
		local spawnPosition = getPlotSpawnPosition(plotId)
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			humanoidRootPart.CFrame = CFrame.new(spawnPosition, spawnPosition + Vector3.new(0, 0, 1))
			print("Respawned", player.Name, "at their Plot #" .. plotId)
		end
	end
end

-- Function to get player's plot info (useful for other scripts)
local function getPlayerPlot(player)
	local plotId = playerPlots[player.UserId]
	if plotId then
		return plotId, plotData[plotId]
	end
	return nil, nil
end

-- Initialize the system
local function initializePlotSystem()
	print("🏡 Initializing Plot System...")

	-- Create initial plots (you can adjust this number)
	createInitialPlots(10) -- Start with 10 plots

	-- Load existing plot ownership
	loadPlotOwnership()

	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)

		-- Connect character spawn event for existing players
		if player.Character then
			onCharacterAdded(player.Character)
		end
		player.CharacterAdded:Connect(onCharacterAdded)
	end

	-- Connect character spawn events for new players
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(onCharacterAdded)
	end)

	print("✅ Plot System initialized successfully!")
	print("📊 Current status:")
	print("   - Total plots:", #plotData)
	print("   - Owned plots:", #playerPlots)
	print("   - Available plots:", #plotData - #playerPlots)
end

-- Public functions for other scripts to use
_G.PlotSystem = {
	getPlayerPlot = getPlayerPlot,
	getPlotSpawnPosition = getPlotSpawnPosition,
	spawnPlayerAtPlot = spawnPlayerAtPlot,
	assignPlotToPlayer = assignPlotToPlayer,
	findUnclaimedPlot = findUnclaimedPlot
}

-- Start the system
initializePlotSystem()

print("🍌 Plot Finder System Loaded!")