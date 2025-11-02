-- PlotBananaGrowth.lua - Banana Growth System for Individual Player Plots
-- This script spawns bananas within player plots instead of globally

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Wait for PlotSystem to be available
repeat task.wait() until _G.PlotSystem

-- Configuration
local FRUIT_TEMPLATE = ServerStorage:FindFirstChild("FruitTemplate")
local BASE_SPAWN_INTERVAL = 5 -- Base seconds between spawns
local BASE_GROWTH_DURATION = 15 -- Base seconds for fruit to fully grow

-- Banana part names (for reference - these are the parts in your banana model)
-- Ordered from bottom to top of the banana
local BANANA_PARTS = {
	"Bottombrowntip",   -- Bottom brown tip (stem end)
	"Yellow5",          -- Bottom yellow section
	"Yellow4",          -- Lower-middle yellow section  
	"Yellow2",          -- Middle yellow section
	"Yellow3",          -- Upper-middle yellow section
	"Yellow1",          -- Top yellow section
	"Topbrowntip"       -- Top brown tip (blossom end)
}

-- Compatibility mapping for old names (with "1" suffix)
local BANANA_PARTS_OLD = {
	"Bottombrowntip1",  -- Old name with suffix
	"Yellow51",         -- Old name with suffix
	"Yellow41",         -- Old name with suffix  
	"Yellow21",         -- Old name with suffix
	"Yellow31",         -- Old name with suffix
	"Yellow11",         -- Old name with suffix
	"Topbrowntip1"      -- Old name with suffix
}

if not FRUIT_TEMPLATE then
	warn("FruitTemplate not found in ServerStorage! Please add a Part or Model named 'FruitTemplate'.")
	return
end

print("🍌 PLOT BANANA GROWTH SCRIPT STARTING...")

-- If FruitTemplate is a Model, find the main part inside it and store all part sizes
local MAIN_FRUIT_PART = FRUIT_TEMPLATE
local ALL_FRUIT_PARTS = {}
local ORIGINAL_PART_SIZES = {}

if FRUIT_TEMPLATE:IsA("Model") then
	-- Get all banana parts in the model
	for _, child in ipairs(FRUIT_TEMPLATE:GetChildren()) do
		if child:IsA("Part") or child:IsA("MeshPart") or child:IsA("UnionOperation") then
			table.insert(ALL_FRUIT_PARTS, child)
			ORIGINAL_PART_SIZES[child.Name] = child.Size
			print("DEBUG: Found banana part:", child.Name, "Size:", child.Size)
		end
	end

	-- Check if we have new or old naming convention
	local usingOldNames = false
	for _, oldName in ipairs(BANANA_PARTS_OLD) do
		if FRUIT_TEMPLATE:FindFirstChild(oldName) then
			usingOldNames = true
			break
		end
	end

	if usingOldNames then
		print("⚠️  Using OLD naming convention (with '1' suffix)")
		print("💡 Consider renaming parts to remove '1' suffix for cleaner names")
	else
		print("✅ Using NEW clean naming convention")
	end

	-- Set the main part (prefer yellow sections for main positioning)
	for _, part in ipairs(ALL_FRUIT_PARTS) do
		if string.find(part.Name, "Yellow") then
			MAIN_FRUIT_PART = part
			break
		end
	end

	-- Fallback to first part if no yellow section found
	if not MAIN_FRUIT_PART and #ALL_FRUIT_PARTS > 0 then
		MAIN_FRUIT_PART = ALL_FRUIT_PARTS[1]
	end

	if not MAIN_FRUIT_PART then
		warn("FruitTemplate Model doesn't contain any Part! Please add a Part inside the FruitTemplate Model.")
		return
	end
else
	-- If it's just a single part
	table.insert(ALL_FRUIT_PARTS, FRUIT_TEMPLATE)
	ORIGINAL_PART_SIZES[FRUIT_TEMPLATE.Name] = FRUIT_TEMPLATE.Size
end

-- Plot-specific growth parameters with bonus integration
local function getGrowthDuration(plotId)
	local baseDuration = BASE_GROWTH_DURATION

	-- Apply sprinkler bonus
	if _G.SprinklerSystem then
		local sprinklerMultiplier = _G.SprinklerSystem.getSprinklerMultiplier(plotId)
		baseDuration = baseDuration / sprinklerMultiplier
	end

	-- Apply worker bonuses if plot has owner
	if _G.PlotSystem and _G.RebirthSystem then
		local plotData = _G.PlotSystem.getPlotData()
		for pId, data in pairs(plotData) do
			if tonumber(pId) == tonumber(plotId) and data.userId then
				local player = Players:GetPlayerByUserId(data.userId)
				if player then
					local workerMultiplier = _G.RebirthSystem.getWorkerMultiplier(player, "growth_speed")
					baseDuration = baseDuration / workerMultiplier
				end
				break
			end
		end
	end

	return math.max(1, baseDuration) -- Minimum 1 second
end

local function getSpawnInterval(plotId)
	local baseInterval = BASE_SPAWN_INTERVAL

	-- Apply worker bonuses for banana spawn rate
	if _G.PlotSystem and _G.RebirthSystem then
		local plotData = _G.PlotSystem.getPlotData()
		for pId, data in pairs(plotData) do
			if tonumber(pId) == tonumber(plotId) and data.userId then
				local player = Players:GetPlayerByUserId(data.userId)
				if player then
					local workerMultiplier = _G.RebirthSystem.getWorkerMultiplier(player, "banana_spawn")
					baseInterval = baseInterval / workerMultiplier
				end
				break
			end
		end
	end

	return math.max(2, baseInterval) -- Minimum 2 seconds
end

-- Get sprinkler plant size multiplier for a plot
local function getSprinklerPlantSizeMultiplier(plotId)
	if _G.SprinklerSystem and _G.SprinklerSystem.getSprinklerPlantSizeMultiplier then
		return _G.SprinklerSystem.getSprinklerPlantSizeMultiplier(plotId)
	end
	return 1
end

local GROWTH_DURATION = 10 -- Base duration - will be modified by bonuses
local MAX_FRUIT_SIZE = MAIN_FRUIT_PART.Size -- Final size when fully grown
local TIP_SIZE = Vector3.new(0.05, 0.05, 0.05) -- Tiny initial tip
local SLICE_THICKNESS = 0.05 -- How thick the horizontal slice is
local SLICE_SIZE = Vector3.new(MAX_FRUIT_SIZE.X, SLICE_THICKNESS, MAX_FRUIT_SIZE.Z) -- Thin horizontal slice
local HORIZONTAL_EXPANSION_DURATION_RATIO = 0.3 -- 30% of growth time for tip to slice expansion

local MAX_FRUITS_PER_PLOT = 3 -- Maximum fruits that can grow in each plot
local SPAWN_INTERVAL = 8 -- seconds between spawn attempts per plot
local MIN_FRUIT_DISTANCE = 4 -- minimum distance between fruits in studs
local PLOT_BORDER_MARGIN = 5 -- Stay away from plot edges

local GOLD_CHANCE = 0.05 -- 5%
local RAINBOW_CHANCE = 0.01 -- 1%

-- Size variation system
local SIZE_NORMAL_CHANCE = 0.90 -- 90% normal size
local SIZE_BIG_CHANCE = 0.05 -- 5% big size  
local SIZE_SMALL_CHANCE = 0.05 -- 5% small size

-- Size multipliers
local SIZE_NORMAL_MIN = 0.85 -- 85% of original size
local SIZE_NORMAL_MAX = 1.15 -- 115% of original size
local SIZE_BIG_MIN = 1.3 -- 130% of original size
local SIZE_BIG_MAX = 1.8 -- 180% of original size
local SIZE_SMALL_MIN = 0.4 -- 40% of original size
local SIZE_SMALL_MAX = 0.75 -- 75% of original size

-- Weight calculation constants (in kg)
local WEIGHT_BASE = 8.5 -- Base weight for normal banana in kg
local WEIGHT_DENSITY_FACTOR = 1.2 -- Weight scales with size but not linearly

-- Storage for plot fruit folders
local plotFruitFolders = {}

-- Function to get or create fruit folder for a specific plot
local function getPlotFruitFolder(plotId)
	if not plotFruitFolders[plotId] then
		local plotsFolder = Workspace:FindFirstChild("Plots")
		if plotsFolder then
			local plotModel = plotsFolder:FindFirstChild("Plot_" .. plotId)
			if plotModel then
				local fruitFolder = plotModel:FindFirstChild("GrowingBananas")
				if not fruitFolder then
					fruitFolder = Instance.new("Folder")
					fruitFolder.Name = "GrowingBananas"
					fruitFolder.Parent = plotModel
				end
				plotFruitFolders[plotId] = fruitFolder
				print("Created/found fruit folder for Plot #" .. plotId)
			end
		end
	end
	return plotFruitFolders[plotId]
end

-- Function to check if a position is too close to existing fruits in the same plot
local function isPositionTooClose(newPosition, plotId, minDistance)
	local fruitFolder = getPlotFruitFolder(plotId)
	if not fruitFolder then return false end

	for _, existingFruit in ipairs(fruitFolder:GetChildren()) do
		local existingPosition
		if existingFruit:IsA("Model") then
			-- Get position of the main part or first part
			local mainPart = existingFruit:FindFirstChildOfClass("Part") or existingFruit:FindFirstChildOfClass("MeshPart") or existingFruit:FindFirstChildOfClass("UnionOperation")
			if mainPart then
				existingPosition = mainPart.Position
			end
		else
			existingPosition = existingFruit.Position
		end

		if existingPosition then
			local distance = (newPosition - existingPosition).Magnitude
			if distance < minDistance then
				return true
			end
		end
	end
	return false
end

-- Function to determine size variation for fruit
local function determineSizeVariation(plotId)
	local randomValue = math.random()
	local sizeMultiplier = 1.0
	local sizeCategory = "Normal"

	-- Sprinkler enhancement: shift RNG upward if sprinkler present
	local sprinklerMultiplier = 1
	if _G.SprinklerSystem and plotId then
		sprinklerMultiplier = getSprinklerPlantSizeMultiplier(plotId)
		if sprinklerMultiplier > 1 then
			-- Shift randomValue upward, making big fruit more likely
			randomValue = math.min(1, randomValue + 0.15 * (sprinklerMultiplier - 1))
		end
	end

	if randomValue <= SIZE_SMALL_CHANCE then
		-- Small fruit (5%)
		sizeMultiplier = math.random() * (SIZE_SMALL_MAX - SIZE_SMALL_MIN) + SIZE_SMALL_MIN
		sizeCategory = "Small"
	elseif randomValue <= SIZE_SMALL_CHANCE + SIZE_BIG_CHANCE then
		-- Big fruit (5%)
		sizeMultiplier = math.random() * (SIZE_BIG_MAX - SIZE_BIG_MIN) + SIZE_BIG_MIN
		sizeCategory = "Big"
	else
		-- Normal fruit (90%)
		sizeMultiplier = math.random() * (SIZE_NORMAL_MAX - SIZE_NORMAL_MIN) + SIZE_NORMAL_MIN
		sizeCategory = "Normal"
	end

	-- Apply sprinkler plant size multiplier as a final boost
	if sprinklerMultiplier > 1 then
		sizeMultiplier = sizeMultiplier * sprinklerMultiplier
		sizeCategory = sizeCategory .. " (Sprinkler Enhanced)"
		print("DEBUG: Sprinkler size boost applied to plot", plotId, "- Multiplier:", sprinklerMultiplier, "Final size:", sizeMultiplier)
	end

	return sizeMultiplier, sizeCategory
end

-- Function to calculate fruit weight based on size
local function calculateFruitWeight(sizeMultiplier, fruitType)
	-- Base weight varies by fruit type
	local baseWeight = WEIGHT_BASE
	if fruitType == "golden" then
		baseWeight = baseWeight * 1.5 -- Golden fruits are denser
	elseif fruitType == "rainbow" then
		baseWeight = baseWeight * 0.8 -- Rainbow fruits are lighter (magical)
	end

	-- Weight scales with size but not linearly (volume relationship)
	local weightMultiplier = math.pow(sizeMultiplier, WEIGHT_DENSITY_FACTOR)
	local finalWeight = baseWeight * weightMultiplier

	-- Add some random variation (±10%)
	local variation = 0.9 + (math.random() * 0.2)
	finalWeight = finalWeight * variation

	-- Round to 1 decimal place
	return math.floor(finalWeight * 10) / 10
end

-- Function to get spawn position within a specific plot
local function getPlotSpawnPosition(plotId)
	local plotData = _G.PlotSystem.getPlayerPlot(Players:GetPlayerByUserId(plotId))
	if not plotData then
		-- Try to get plot data directly
		local plotsFolder = Workspace:FindFirstChild("Plots")
		if plotsFolder then
			local plotModel = plotsFolder:FindFirstChild("Plot_" .. plotId)
			if plotModel then
				local plotBase = plotModel:FindFirstChild("PlotBase")
				if plotBase then
					local plotPosition = plotBase.Position
					local plotSize = plotBase.Size

					local attempts = 0
					while attempts < 30 do
						-- Generate random position within the plot bounds (with margin)
						local randomX = plotPosition.X + (math.random() - 0.5) * (plotSize.X - PLOT_BORDER_MARGIN * 2)
						local randomY = plotPosition.Y + plotSize.Y * 0.5 + math.random() * 3 -- Above the plot surface
						local randomZ = plotPosition.Z + (math.random() - 0.5) * (plotSize.Z - PLOT_BORDER_MARGIN * 2)

						local candidatePosition = Vector3.new(randomX, randomY, randomZ)

						-- Check if this position is far enough from existing fruits
						if not isPositionTooClose(candidatePosition, plotId, MIN_FRUIT_DISTANCE) then
							print("DEBUG: Found good position in Plot #" .. plotId .. ":", candidatePosition)
							return candidatePosition
						end

						attempts = attempts + 1
					end

					-- Fallback: use center of plot with random offset
					local fallbackPosition = Vector3.new(
						plotPosition.X + math.random(-plotSize.X/4, plotSize.X/4),
						plotPosition.Y + plotSize.Y/2 + math.random() * 3,
						plotPosition.Z + math.random(-plotSize.Z/4, plotSize.Z/4)
					)

					print("DEBUG: Using fallback position for Plot #" .. plotId .. ":", fallbackPosition)
					return fallbackPosition
				end
			end
		end
	end

	warn("Could not find plot data for Plot #" .. plotId)
	return Vector3.new(0, 10, 0)
end

-- Utility: Normal-like random (Box-Muller transform)
local function normalRandom(mean, stddev, min, max)
	local u, v, s
	repeat
		u = 2 * math.random() - 1
		v = 2 * math.random() - 1
		s = u * u + v * v
	until s > 0 and s < 1
	local z = u * math.sqrt(-2 * math.log(s) / s)
	local value = mean + stddev * z
	if min then value = math.max(min, value) end
	if max then value = math.min(max, value) end
	return value
end

-- Function to determine fruit width (X/Z) using normal-like RNG
local function rollFruitWidth(base, min, max)
	local mean = base
	local stddev = (max - min) / 6 -- 99.7% within [min, max]
	return normalRandom(mean, stddev, min, max)
end

-- Modified growFruit function: width is set instantly, only Y grows, parts revealed top-to-bottom
local function growFruit(fruitModel)
	local allFruitParts = {}
	local mainPart = nil
	if fruitModel:IsA("Model") then
		for _, child in ipairs(fruitModel:GetChildren()) do
			if child:IsA("Part") or child:IsA("MeshPart") or child:IsA("UnionOperation") then
				table.insert(allFruitParts, child)
				if not mainPart and string.find(child.Name, "Yellow") then
					mainPart = child
				end
			end
		end
		if not mainPart and #allFruitParts > 0 then mainPart = allFruitParts[1] end
	else
		table.insert(allFruitParts, fruitModel)
		mainPart = fruitModel
	end
	if not mainPart then warn("No parts found in fruit model for growth!") return end

	-- Roll width using normal-like RNG
	local baseWidth = (ORIGINAL_PART_SIZES[mainPart.Name] or mainPart.Size).X
	local minWidth = baseWidth * 0.5
	local maxWidth = baseWidth * 1.7
	local finalWidth = rollFruitWidth(baseWidth, minWidth, maxWidth)
	fruitModel:SetAttribute("FinalWidth", finalWidth)

	-- Set all parts' X/Z to final width instantly, set Y to minimum
	local originalSizes = {}
	for _, part in ipairs(allFruitParts) do
		local templateSize = ORIGINAL_PART_SIZES[part.Name] or part.Size
		originalSizes[part.Name] = Vector3.new(finalWidth, templateSize.Y, finalWidth)
		part.Size = Vector3.new(finalWidth, 0.05, finalWidth)
		part.Transparency = 1
		part.CanCollide = false
	end

	-- Order parts by Y (top to bottom)
	table.sort(allFruitParts, function(a, b)
		return a.Position.Y > b.Position.Y
	end)

	-- Normalize Y so stem stays at correct height
	local stemY = mainPart.Position.Y
	local baseY = allFruitParts[#allFruitParts].Position.Y
	local yOffset = stemY - baseY
	for _, part in ipairs(allFruitParts) do
		part.Position = Vector3.new(part.Position.X, part.Position.Y + yOffset, part.Position.Z)
	end

	-- Animate growth: reveal parts top-to-bottom, grow Y only
	local growthDuration = getGrowthDuration(fruitModel:GetAttribute("PlotId"))
	local partGrowTime = growthDuration / #allFruitParts
	for i, part in ipairs(allFruitParts) do
		-- Reveal this part
		part.Transparency = 0
		part.CanCollide = false
		-- Animate Y from 0.05 to full
		local startY = 0.05
		local endY = originalSizes[part.Name].Y
		local startTime = time()
		while time() - startTime < partGrowTime do
			local t = (time() - startTime) / partGrowTime
			part.Size = Vector3.new(finalWidth, startY + (endY - startY) * t, finalWidth)
			task.wait()
		end
		part.Size = Vector3.new(finalWidth, endY, finalWidth)
		part.CanCollide = true
	end
	fruitModel:SetAttribute("GrowthPercentage", 100)
	fruitModel:SetAttribute("IsGrown", true)
end

-- Function to spawn a new fruit in a specific plot
local function spawnFruitInPlot(plotId)
	local fruitFolder = getPlotFruitFolder(plotId)
	if not fruitFolder then
		warn("Could not find fruit folder for Plot #" .. plotId)
		return
	end

	-- Check if plot has a fully grown tree
	local plotsFolder = Workspace:FindFirstChild("Plots")
	local plotModel = plotsFolder:FindFirstChild("Plot_" .. plotId)
	local hasFullyGrownTree = false

	if plotModel then
		for _, child in ipairs(plotModel:GetChildren()) do
			if child.Name == "BanappleTree" and child:GetAttribute("IsFullyGrown") == true then
				hasFullyGrownTree = true
				break
			end
		end
	end

	-- Only spawn fruits if there's a fully grown tree
	if not hasFullyGrownTree then
		return -- No fully grown tree, don't spawn fruits
	end

	-- Check if plot has reached max fruits
	if #fruitFolder:GetChildren() >= MAX_FRUITS_PER_PLOT then
		return -- Don't spawn more fruits
	end

	print("DEBUG: Spawning fruit in Plot #" .. plotId .. " (tree is fully grown)")
	local newFruit = FRUIT_TEMPLATE:Clone()

	-- Set up fruit parts
	local allFruitParts = {}
	local mainPart = newFruit

	if newFruit:IsA("Model") then
		for _, child in ipairs(newFruit:GetChildren()) do
			if child:IsA("Part") or child:IsA("MeshPart") or child:IsA("UnionOperation") then
				table.insert(allFruitParts, child)
				if not mainPart or mainPart == newFruit then
					if string.find(child.Name, "Yellow") then
						mainPart = child
					elseif not mainPart or mainPart == newFruit then
						mainPart = child
					end
				end
			end
		end
	else
		table.insert(allFruitParts, newFruit)
		mainPart = newFruit
	end

	-- Set properties for all banana parts
	for _, part in ipairs(allFruitParts) do
		part.Anchored = true
		part.CanCollide = true
	end

	-- Set initial attributes
	newFruit:SetAttribute("GrowthPercentage", 0)
	newFruit:SetAttribute("IsGrown", false)
	newFruit:SetAttribute("IsGold", false)
	newFruit:SetAttribute("IsRainbow", false)
	newFruit:SetAttribute("PlotId", plotId) -- Store which plot this fruit belongs to

	-- Determine size variation (with sprinkler enhancements)
	local sizeMultiplier, sizeCategory = determineSizeVariation(plotId)
	newFruit:SetAttribute("SizeMultiplier", sizeMultiplier)
	newFruit:SetAttribute("SizeCategory", sizeCategory)

	-- Get spawn position within the plot
	local spawnPosition = getPlotSpawnPosition(plotId)

	-- Position the fruit
	if newFruit:IsA("Model") then
		local templateMainPartPosition = MAIN_FRUIT_PART.Position
		local offsetToSpawn = spawnPosition - templateMainPartPosition
		local randomYRotation = math.rad(math.random(0, 360))
		local rotationCFrame = CFrame.Angles(0, randomYRotation, 0)

		for _, part in ipairs(allFruitParts) do
			local oldCFrame = part.CFrame
			local movedCFrame = oldCFrame + offsetToSpawn
			local mainPartNewPos = MAIN_FRUIT_PART.Position + offsetToSpawn
			local relativeToMain = movedCFrame.Position - mainPartNewPos
			local rotatedRelative = rotationCFrame:VectorToWorldSpace(relativeToMain)
			local finalPosition = mainPartNewPos + rotatedRelative
			part.CFrame = CFrame.new(finalPosition) * rotationCFrame * (oldCFrame - oldCFrame.Position)
		end
	else
		mainPart.Position = spawnPosition
		mainPart.Orientation = Vector3.new(0, math.random(0, 360), 0)
	end

	-- Determine rarity and apply effects
	local randomNumber = math.random()

	if randomNumber <= RAINBOW_CHANCE then -- 1% chance for Rainbow
		newFruit:SetAttribute("IsRainbow", true)
		for _, part in ipairs(allFruitParts) do
			part:SetAttribute("IsRainbow", true)
			part.Color = Color3.fromRGB(128, 0, 128)
			part.Material = Enum.Material.Neon
		end
		newFruit.Name = "Growing Rainbow Banana"
	elseif randomNumber <= RAINBOW_CHANCE + GOLD_CHANCE then -- Next 5% chance for Gold
		newFruit:SetAttribute("IsGold", true)
		for _, part in ipairs(allFruitParts) do
			part:SetAttribute("IsGold", true)
			part.Color = Color3.fromRGB(255, 215, 0)
			part.Material = Enum.Material.Metal
		end
		newFruit.Name = "Growing Golden Banana"
	else -- Normal banana
		for i, part in ipairs(allFruitParts) do
			local originalPart = ALL_FRUIT_PARTS[i]
			if originalPart then
				part.Color = originalPart.Color
				part.Material = originalPart.Material
			end
		end
		newFruit.Name = "Growing Banana"
	end

	newFruit.Parent = fruitFolder
	task.wait()

	-- Start growth animation
	coroutine.wrap(growFruit)(newFruit)
	print("DEBUG: Fruit spawned in Plot #" .. plotId)
end

-- Function to get list of all plot IDs that have players
local function getActivePlots()
	local activePlots = {}
	local plotsFolder = Workspace:FindFirstChild("Plots")

	if plotsFolder then
		for _, plotModel in ipairs(plotsFolder:GetChildren()) do
			if plotModel.Name:match("^Plot_(%d+)$") then
				local plotId = tonumber(plotModel.Name:match("^Plot_(%d+)$"))
				if plotId then
					table.insert(activePlots, plotId)
				end
			end
		end
	end

	return activePlots
end

-- Main spawn loop for all plots
task.spawn(function()
	while true do
		local activePlots = getActivePlots()

		-- Spawn fruits in each active plot with dynamic intervals
		for _, plotId in ipairs(activePlots) do
			local spawnInterval = getSpawnInterval(plotId)
			task.spawn(function()
				spawnFruitInPlot(plotId)
			end)
		end

		-- Use base spawn interval for the main loop
		task.wait(BASE_SPAWN_INTERVAL)
	end
end)

-- Rainbow effect for growing rainbow bananas
RunService.Heartbeat:Connect(function(deltaTime)
	local plotsFolder = Workspace:FindFirstChild("Plots")
	if not plotsFolder then return end

	for _, plotModel in ipairs(plotsFolder:GetChildren()) do
		local fruitFolder = plotModel:FindFirstChild("GrowingBananas")
		if fruitFolder then
			for _, banana in ipairs(fruitFolder:GetChildren()) do
				if banana:GetAttribute("IsRainbow") then
					-- Find all parts of the banana
					local bananaParts = {}
					if banana:IsA("Model") then
						for _, child in ipairs(banana:GetChildren()) do
							if (child:IsA("Part") or child:IsA("MeshPart") or child:IsA("UnionOperation")) and child:GetAttribute("IsRainbow") then
								table.insert(bananaParts, child)
							end
						end
					else
						if banana:GetAttribute("IsRainbow") then
							table.insert(bananaParts, banana)
						end
					end

					if #bananaParts > 0 then
						-- Continuous hue shift for rainbow effect
						local hue = (time() * 0.3) % 1
						for _, part in ipairs(bananaParts) do
							part.Color = Color3.fromHSV(hue, 1, 1)
						end
					end
				end
			end
		end
	end
end)

print("🍌 Plot Banana Growth System Loaded!")

-- DEPRECATED: All fruit/banana/plot growth logic removed for money-only game. Nothing grows anymore.
return
