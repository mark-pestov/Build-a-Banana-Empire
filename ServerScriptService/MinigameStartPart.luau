-- MinigameStartPart.lua
-- Creates a physical part that serves as the minigame start location
-- Players are teleported here when they select the minigame option from the vendor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local MinigameStartPart = {}
local minigamePart = nil
local teleportPad = nil

-- Configuration
local MINIGAME_CONFIG = {
	Position = Vector3.new(100, 10, 100), -- Adjust position as needed
	Size = Vector3.new(10, 1, 10),
	Material = Enum.Material.Neon,
	Color = Color3.fromRGB(0, 255, 127), -- Spring green
	Transparency = 0.2,
	CanCollide = true,
	Shape = Enum.PartType.Block
}

-- Create the minigame start part
function MinigameStartPart.CreateMinigamePart()
	-- Remove existing part if it exists
	if minigamePart then
		minigamePart:Destroy()
	end

	-- Create the main minigame part
	minigamePart = Instance.new("Part")
	minigamePart.Name = "MinigameStartPart"
	minigamePart.Size = Vector3.new(MINIGAME_CONFIG.Size.X, MINIGAME_CONFIG.Size.Y, MINIGAME_CONFIG.Size.Z)
	minigamePart.Position = MINIGAME_CONFIG.Position
	minigamePart.Material = MINIGAME_CONFIG.Material
	minigamePart.Color = MINIGAME_CONFIG.Color
	minigamePart.Transparency = MINIGAME_CONFIG.Transparency
	minigamePart.CanCollide = MINIGAME_CONFIG.CanCollide
	minigamePart.Shape = MINIGAME_CONFIG.Shape
	minigamePart.Anchored = true
	minigamePart.TopSurface = Enum.SurfaceType.Smooth
	minigamePart.BottomSurface = Enum.SurfaceType.Smooth
	minigamePart.Parent = workspace

	-- Add glowing effect
	local pointLight = Instance.new("PointLight")
	pointLight.Color = MINIGAME_CONFIG.Color
	pointLight.Brightness = 1.5
	pointLight.Range = 15
	pointLight.Parent = minigamePart

	-- Add particle effects
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, MINIGAME_CONFIG.Size.Y/2, 0)
	attachment.Parent = minigamePart

	local particles = Instance.new("ParticleEmitter")
	particles.Parent = attachment
	particles.Texture = "rbxasset://textures/particles/fire_main.dds"
	particles.Color = ColorSequence.new(MINIGAME_CONFIG.Color)
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1.2)
	}
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 25
	particles.SpreadAngle = Vector2.new(45, 45)
	particles.Speed = NumberRange.new(3, 8)
	particles.Acceleration = Vector3.new(0, -5, 0)

	-- Add text label above the part
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 200, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 5, 0)
	billboardGui.Parent = minigamePart

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "🎮 MINIGAME ZONE 🎮"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.Parent = billboardGui

	-- Add pulsing animation
	spawn(function()
		while minigamePart and minigamePart.Parent do
			-- Pulse the light
			for i = 1, 50 do
				if pointLight and pointLight.Parent then
					pointLight.Brightness = 1.5 + math.sin(i/10) * 0.5
				end
				wait(0.05)
			end
		end
	end)

	-- Add touch detection for players who walk onto it
	local connection
	connection = minigamePart.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then                
				MinigameStartPart.StartMinigameForPlayer(player)
			end
		end
	end)

	print("Minigame start part created at position:", MINIGAME_CONFIG.Position)
	return minigamePart
end

-- Teleport player to minigame area
function MinigameStartPart.TeleportPlayerToMinigame(player)
	if not minigamePart or not player.Character then return end

	local character = player.Character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart then
		-- Calculate spawn position above the minigame part
		local spawnPosition = minigamePart.Position + Vector3.new(0, 10, 0)

		-- Create teleport effect
		local teleportEffect = Instance.new("Explosion")
		teleportEffect.Parent = workspace
		teleportEffect.Position = humanoidRootPart.Position
		teleportEffect.BlastRadius = 0
		teleportEffect.BlastPressure = 0
		teleportEffect.Visible = false

		-- Play teleport sound
		local teleportSound = Instance.new("Sound")
		teleportSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		teleportSound.Volume = 0.4
		teleportSound.Pitch = 1.2
		teleportSound.Parent = humanoidRootPart
		teleportSound:Play()

		-- Teleport player
		humanoidRootPart.CFrame = CFrame.new(spawnPosition)

		-- Create arrival effect
		wait(0.1)
		local arrivalEffect = Instance.new("Explosion")
		arrivalEffect.Parent = workspace
		arrivalEffect.Position = spawnPosition
		arrivalEffect.BlastRadius = 0
		arrivalEffect.BlastPressure = 0
		arrivalEffect.Visible = false

		-- Clean up sound
		teleportSound.Ended:Connect(function()
			teleportSound:Destroy()
		end)

		-- Send notification
		if _G.NotificationSystem then
			_G.NotificationSystem.ShowInfo(player, "Minigame Zone", "Welcome to the minigame area!")
		end

		print("Teleported", player.Name, "to minigame area")
		return true
	end

	return false
end

-- Start minigame for player
function MinigameStartPart.StartMinigameForPlayer(player)
	if not player or not player.Character then return end

	-- Create simple fruit collecting minigame
	local minigameData = {
		type = "fruit_collector",
		duration = 30, -- 30 seconds
		reward_multiplier = 2.0,
		spawn_rate = 1.0 -- fruits per second
	}

	-- Send minigame start event to client
	local remoteEvent = ReplicatedStorage:FindFirstChild("MinigameEvent")
	if remoteEvent then
		remoteEvent:FireClient(player, "StartGame", minigameData)
	end

	-- Spawn fruit collectibles around the area
	MinigameStartPart.SpawnFruitCollectibles(player, minigameData.duration)

	-- Send notification
	if _G.NotificationSystem then
		_G.NotificationSystem.ShowInfo(player, "Minigame Started!", 
			"Collect fruits for " .. minigameData.duration .. " seconds!")
	end

	print("Started minigame for", player.Name)
end

-- Spawn collectible fruits around the minigame area
function MinigameStartPart.SpawnFruitCollectibles(player, duration)
	if not minigamePart then return end

	local fruitTypes = {"Apple", "Banana", "Orange", "Grape", "Watermelon"}
	local spawnRadius = 8
	local fruitsSpawned = {}

	-- Spawn fruits over the duration
	spawn(function()
		local startTime = tick()
		while tick() - startTime < duration do
			-- Random fruit type
			local fruitType = fruitTypes[math.random(1, #fruitTypes)]

			-- Random position around the minigame part
			local angle = math.random() * math.pi * 2
			local distance = math.random(2, spawnRadius)
			local spawnPos = minigamePart.Position + Vector3.new(
				math.cos(angle) * distance,
				5,
				math.sin(angle) * distance
			)

			-- Create fruit collectible
			local fruit = Instance.new("Part")
			fruit.Name = "CollectibleFruit_" .. fruitType
			fruit.Size = Vector3.new(1, 1, 1)
			fruit.Position = spawnPos
			fruit.Material = Enum.Material.Neon
			fruit.CanCollide = false
			fruit.Anchored = false
			fruit.Shape = Enum.PartType.Ball

			-- Color based on fruit type
			if fruitType == "Apple" then
				fruit.Color = Color3.fromRGB(255, 0, 0)
			elseif fruitType == "Banana" then
				fruit.Color = Color3.fromRGB(255, 255, 0)
			elseif fruitType == "Orange" then
				fruit.Color = Color3.fromRGB(255, 165, 0)
			elseif fruitType == "Grape" then
				fruit.Color = Color3.fromRGB(128, 0, 128)
			elseif fruitType == "Watermelon" then
				fruit.Color = Color3.fromRGB(0, 255, 0)
			end

			fruit.Parent = workspace

			-- Add glow effect
			local light = Instance.new("PointLight")
			light.Color = fruit.Color
			light.Brightness = 1
			light.Range = 5
			light.Parent = fruit

			-- Add floating effect
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.new(0, 2, 0)
			bodyVelocity.MaxForce = Vector3.new(0, 4000, 0)
			bodyVelocity.Parent = fruit

			-- Touch detection for collection
			local connection
			connection = fruit.Touched:Connect(function(hit)
				local humanoid = hit.Parent:FindFirstChild("Humanoid")
				if humanoid then
					local touchPlayer = Players:GetPlayerFromCharacter(hit.Parent)
					if touchPlayer == player then
						-- Collect the fruit
						MinigameStartPart.CollectFruit(player, fruitType)

						-- Remove fruit
						connection:Disconnect()
						fruit:Destroy()
					end
				end
			end)

			-- Store reference for cleanup
			table.insert(fruitsSpawned, fruit)

			-- Auto-destroy after 10 seconds if not collected
			spawn(function()
				wait(10)
				if fruit and fruit.Parent then
					fruit:Destroy()
				end
			end)

			-- Wait before spawning next fruit
			wait(1)
		end

		-- Clean up remaining fruits
		wait(5)
		for _, fruit in pairs(fruitsSpawned) do
			if fruit and fruit.Parent then
				fruit:Destroy()
			end
		end
	end)
end

-- Handle fruit collection in minigame
function MinigameStartPart.CollectFruit(player, fruitType)
	-- Play collection sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/pop_high.wav"
	sound.Volume = 0.3
	sound.Parent = workspace
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	-- Award points/fruits
	local remoteEvent = ReplicatedStorage:FindFirstChild("VendorInteraction")
	if remoteEvent then
		remoteEvent:FireServer("MinigameFruitCollected", fruitType)
	end

	-- Show collection notification
	if _G.NotificationSystem then
		_G.NotificationSystem.ShowFruit(player, fruitType, 1)
	end
end

-- Move minigame part to new location
function MinigameStartPart.MovePart(newPosition)
	if minigamePart then
		MINIGAME_CONFIG.Position = newPosition
		minigamePart.Position = newPosition
		print("Minigame part moved to:", newPosition)
	end
end

-- Destroy the minigame part
function MinigameStartPart.DestroyPart()
	if minigamePart then
		minigamePart:Destroy()
		minigamePart = nil
		print("Minigame part destroyed")
	end
end

-- Initialize the system
function MinigameStartPart.Initialize()
	MinigameStartPart.CreateMinigamePart()

	-- Create remote events if they don't exist
	if not ReplicatedStorage:FindFirstChild("MinigameEvent") then
		local minigameRemote = Instance.new("RemoteEvent")
		minigameRemote.Name = "MinigameEvent"
		minigameRemote.Parent = ReplicatedStorage
	end

	print("Minigame Start Part system initialized")
end

-- Global access
_G.MinigameStartPart = MinigameStartPart

-- Auto-initialize
MinigameStartPart.Initialize()

return MinigameStartPart
