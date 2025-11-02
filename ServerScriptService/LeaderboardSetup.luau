-- LeaderboardSetup.lua
-- Place this script in ServerScriptService
-- Creates leaderstats for players to display coins

local Players = game:GetService("Players")

local function setupLeaderstats(player)
	-- Check if leaderstats already exists
	if player:FindFirstChild("leaderstats") then
		return -- Already set up
	end

	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Create Coins value
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats

	print("📊 Leaderstats created for", player.Name)
end

-- Set up leaderstats for new players
Players.PlayerAdded:Connect(setupLeaderstats)

-- Set up leaderstats for players already in game
for _, player in ipairs(Players:GetPlayers()) do
	setupLeaderstats(player)
end

print("📊 Leaderboard Setup Loaded!")
