-- PhysicalSecretButton.lua
-- Creates a physical part in the game world that serves as a secret admin button
-- Only visible to admins/owners and provides access to admin panel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Admin/Owner IDs (Updated with actual IDs)
local ADMIN_IDS = {3389224707} -- Admin user IDs (can add more)
local OWNER_IDS = {3389224707} -- Owner user ID

local PhysicalSecretButton = {}
local secretButton = nil
local clickDetector = nil

-- Configuration
local BUTTON_CONFIG = {
	Position = Vector3.new(0, 50, 0), -- High up in the sky, adjust as needed
	Size = Vector3.new(2, 1, 2),
	Material = Enum.Material.Neon,
	Color = Color3.fromRGB(255, 215, 0), -- Gold color
	Transparency = 0.3,
	CanCollide = false,
	Shape = Enum.PartType.Block,
	TopDecal = "rbxasset://textures/face.png" -- Crown-like symbol
}

-- Check if player is admin or owner
local function isAdmin(player)
	local userId = player.UserId
	for _, id in ipairs(ADMIN_IDS) do
		if userId == id then return true end
	end
	for _, id in ipairs(OWNER_IDS) do
		if userId == id then return true end
	end
	return false
end

-- Check if player is owner
local function isOwner(player)
	local userId = player.UserId
	for _, id in ipairs(OWNER_IDS) do
		if userId == id then return true end
	end
	return false
end

-- Create the physical secret button
function PhysicalSecretButton.CreateSecretButton()
	-- Remove existing button if it exists
	if secretButton then
		secretButton:Destroy()
	end

	-- Create the main button part
	secretButton = Instance.new("Part")
	secretButton.Name = "SecretAdminButton"
	secretButton.Size = Vector3.new(BUTTON_CONFIG.Size.X, BUTTON_CONFIG.Size.Y, BUTTON_CONFIG.Size.Z)
	secretButton.Position = BUTTON_CONFIG.Position
	secretButton.Material = BUTTON_CONFIG.Material
	secretButton.Color = BUTTON_CONFIG.Color
	secretButton.Transparency = BUTTON_CONFIG.Transparency
	secretButton.CanCollide = BUTTON_CONFIG.CanCollide
	secretButton.Shape = BUTTON_CONFIG.Shape
	secretButton.Anchored = true
	secretButton.TopSurface = Enum.SurfaceType.Smooth
	secretButton.BottomSurface = Enum.SurfaceType.Smooth
	secretButton.Parent = workspace

	-- Add special effects
	local pointLight = Instance.new("PointLight")
	pointLight.Color = BUTTON_CONFIG.Color
	pointLight.Brightness = 2
	pointLight.Range = 10
	pointLight.Parent = secretButton

	-- Add particle effects
	local attachment = Instance.new("Attachment")
	attachment.Parent = secretButton

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Parent = attachment
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(BUTTON_CONFIG.Color)
	sparkles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.8)
	}
	sparkles.Lifetime = NumberRange.new(0.5, 1.5)
	sparkles.Rate = 50
	sparkles.SpreadAngle = Vector2.new(360, 360)
	sparkles.Speed = NumberRange.new(2, 5)

	-- Add crown symbol on top
	local decal = Instance.new("Decal")
	decal.Texture = "rbxasset://textures/face.png" -- You can replace with a crown texture
	decal.Face = Enum.NormalId.Top
	decal.Color3 = Color3.new(1, 1, 1)
	decal.Parent = secretButton

	-- Add floating animation
	local floatHeight = 2
	local floatSpeed = 2
	local originalPosition = secretButton.Position

	spawn(function()
		while secretButton and secretButton.Parent do
			local time = tick() * floatSpeed
			local offset = math.sin(time) * floatHeight
			secretButton.Position = originalPosition + Vector3.new(0, offset, 0)
			wait(0.1)
		end
	end)

	-- Add rotation animation
	spawn(function()
		while secretButton and secretButton.Parent do
			secretButton.CFrame = secretButton.CFrame * CFrame.Angles(0, math.rad(1), 0)
			wait(0.1)
		end
	end)

	-- Create click detector
	clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 50
	clickDetector.Parent = secretButton

	-- Handle clicks
	clickDetector.MouseClick:Connect(function(player)
		PhysicalSecretButton.HandleButtonClick(player)
	end)

	-- Add hover effects
	clickDetector.MouseHoverEnter:Connect(function(player)
		if isAdmin(player) then
			-- Increase glow for admins
			pointLight.Brightness = 3
			sparkles.Rate = 100
		end
	end)

	clickDetector.MouseHoverLeave:Connect(function(player)
		-- Reset effects
		pointLight.Brightness = 2
		sparkles.Rate = 50
	end)

	-- Make button only visible to admins
	PhysicalSecretButton.UpdateButtonVisibility()

	print("Physical secret admin button created at position:", BUTTON_CONFIG.Position)
	return secretButton
end

-- Handle button clicks
function PhysicalSecretButton.HandleButtonClick(player)
	if not isAdmin(player) then
		-- Non-admin clicked the button (shouldn't happen if visibility is working)
		print("Non-admin attempted to click secret button:", player.Name)
		return
	end

	print("Admin clicked secret button:", player.Name)

	-- Create special effect at click location
	local clickEffect = Instance.new("Explosion")
	clickEffect.Parent = workspace
	clickEffect.Position = secretButton.Position
	clickEffect.BlastRadius = 0
	clickEffect.BlastPressure = 0
	clickEffect.Visible = false -- No visual explosion, just sound

	-- Play special sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.5
	sound.Pitch = 1.5
	sound.Parent = secretButton
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	-- Flash the button
	spawn(function()
		local originalTransparency = secretButton.Transparency
		for i = 1, 3 do
			secretButton.Transparency = 0
			wait(0.1)
			secretButton.Transparency = originalTransparency
			wait(0.1)
		end
	end)

	-- Open admin panel
	local adminPanelRemote = ReplicatedStorage:FindFirstChild("AdminPanelRemote")
	if adminPanelRemote then
		adminPanelRemote:FireClient(player, "OpenPanel")
	else
		-- Fallback: try to access global admin panel function
		if _G.AdminPanel and _G.AdminPanel.OpenPanel then
			_G.AdminPanel.OpenPanel(player)
		end
	end

	-- Send notification
	if _G.NotificationSystem then
		_G.NotificationSystem.ShowSuccess(player, "Admin Access", "Secret button activated!")
	end
end

-- Update button visibility for all players
function PhysicalSecretButton.UpdateButtonVisibility()
	if not secretButton then return end

	for _, player in pairs(Players:GetPlayers()) do
		PhysicalSecretButton.SetButtonVisibilityForPlayer(player, isAdmin(player))
	end
end

-- Set button visibility for specific player
function PhysicalSecretButton.SetButtonVisibilityForPlayer(player, visible)
	if not secretButton or not player then return end

	-- Use LocalTransparencyModifier for per-player visibility
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	-- Create or update visibility script for player
	local visibilityScript = playerGui:FindFirstChild("SecretButtonVisibility")
	if visibilityScript then
		visibilityScript:Destroy()
	end

	if visible then
		-- Button is visible to this player (admin)
		secretButton.LocalTransparencyModifier = 0
	else
		-- Hide button from this player (non-admin)
		-- We'll use a different approach - make it completely invisible
		local hiddenPart = secretButton:Clone()
		hiddenPart.Name = "HiddenSecretButton_" .. player.UserId
		hiddenPart.Transparency = 1
		hiddenPart.CanCollide = false

		-- Remove all visual effects for non-admins
		for _, child in pairs(hiddenPart:GetChildren()) do
			if child:IsA("PointLight") or child:IsA("ParticleEmitter") or child:IsA("Decal") then
				child:Destroy()
			end
		end

		hiddenPart.Parent = workspace

		-- Clean up when player leaves
		player.AncestryChanged:Connect(function()
			if hiddenPart and hiddenPart.Parent then
				hiddenPart:Destroy()
			end
		end)
	end
end

-- Handle player joining
local function onPlayerAdded(player)
	wait(1) -- Wait for player to fully load
	if secretButton then
		PhysicalSecretButton.SetButtonVisibilityForPlayer(player, isAdmin(player))
	end
end

-- Handle player leaving
local function onPlayerRemoving(player)
	-- Clean up any player-specific parts
	local hiddenButton = workspace:FindFirstChild("HiddenSecretButton_" .. player.UserId)
	if hiddenButton then
		hiddenButton:Destroy()
	end
end

-- Move button to new location
function PhysicalSecretButton.MoveButton(newPosition)
	if secretButton then
		BUTTON_CONFIG.Position = newPosition
		secretButton.Position = newPosition
		print("Secret button moved to:", newPosition)
	end
end

-- Toggle button visibility (admin command)
function PhysicalSecretButton.ToggleVisibility(player)
	if not isAdmin(player) then return end

	if secretButton then
		if secretButton.Transparency < 0.5 then
			secretButton.Transparency = 1
			print("Secret button hidden by", player.Name)
		else
			secretButton.Transparency = BUTTON_CONFIG.Transparency
			print("Secret button shown by", player.Name)
		end
	end
end

-- Destroy the button
function PhysicalSecretButton.DestroyButton()
	if secretButton then
		secretButton:Destroy()
		secretButton = nil
		clickDetector = nil
		print("Secret admin button destroyed")
	end
end

-- Initialize the system
function PhysicalSecretButton.Initialize()
	-- Create the button
	PhysicalSecretButton.CreateSecretButton()

	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle existing players
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	print("Physical Secret Button system initialized")
end

-- Admin commands
function PhysicalSecretButton.HandleAdminCommand(player, command, ...)
	if not isAdmin(player) then return end

	local args = {...}

	if command == "move_secret_button" then
		local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
		if x and y and z then
			PhysicalSecretButton.MoveButton(Vector3.new(x, y, z))
		end
	elseif command == "toggle_secret_button" then
		PhysicalSecretButton.ToggleVisibility(player)
	elseif command == "recreate_secret_button" then
		PhysicalSecretButton.DestroyButton()
		wait(0.5)
		PhysicalSecretButton.CreateSecretButton()
	end
end

-- Global access
_G.PhysicalSecretButton = PhysicalSecretButton

-- Auto-initialize if this is run as a server script
if RunService:IsServer() then
	PhysicalSecretButton.Initialize()
end

return PhysicalSecretButton
