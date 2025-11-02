-- AFKSystem.lua - AFK Farming System (NO PHYSICAL PARTS)
-- testing sync
-- Place in ServerScriptService

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local afkDataStore = DataStoreService:GetDataStore("AFKData")

-- AFK Configuration
local MAX_AFK_TIME = 12 * 60 * 60 -- 12 hours in seconds
local AFK_INCOME_RATE = 1.0 -- base income multiplier during AFK
local POSITION_CHECK_INTERVAL = 5 -- seconds between position checks

-- Player AFK data
local playerAFKData = {} -- {userId: {isAFK: bool, startTime: tick(), lastPosition: Vector3, totalAFKTime: number}}

-- Initialize AFK data
local function initializeAFKData(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return afkDataStore:GetAsync(userId)
	end)

	if success and data then
		playerAFKData[userId] = data
		-- Reset AFK state on join (they're not AFK when they just joined)
		playerAFKData[userId].isAFK = false
		playerAFKData[userId].startTime = nil
	else
		playerAFKData[userId] = {
			isAFK = false,
			startTime = nil,
			lastPosition = nil,
			totalAFKTime = 0,
			afkSessionsToday = 0,
			lastResetTime = tick()
		}
	end

	print("😴 Initialized AFK data for", player.Name)
end

-- Save AFK data
local function saveAFKData(player)
	local userId = player.UserId
	if not playerAFKData[userId] then return end

	local success, error = pcall(function()
		afkDataStore:SetAsync(userId, playerAFKData[userId])
	end)

	if not success then
		warn("Failed to save AFK data for", player.Name, ":", error)
	end
end

-- Check if player can go AFK
local function canGoAFK(player)
	local userId = player.UserId
	local data = playerAFKData[userId]
	if not data then return false, "AFK data not loaded" end

	if data.isAFK then
		return false, "Already in AFK mode"
	end

	-- Reset daily counter if needed (24 hours)
	local timeSinceReset = tick() - (data.lastResetTime or 0)
	if timeSinceReset >= 24 * 60 * 60 then -- 24 hours
		data.afkSessionsToday = 0
		data.lastResetTime = tick()
	end

	-- Check if player has reached daily AFK limit (optional restriction)
	-- For now, allow unlimited AFK sessions but with 12-hour max each

	return true, "Can go AFK"
end

-- Start AFK mode
local function startAFK(player)
	local canAFK, reason = canGoAFK(player)
	if not canAFK then
		return false, reason
	end

	local userId = player.UserId
	local data = playerAFKData[userId]

	-- Store player's current position
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		data.lastPosition = player.Character.HumanoidRootPart.Position
	end

	data.isAFK = true
	data.startTime = tick()
	data.afkSessionsToday = (data.afkSessionsToday or 0) + 1

	-- Lock player in place (disable movement)
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.PlatformStand = true
		player.Character.Humanoid.WalkSpeed = 0
		player.Character.Humanoid.JumpPower = 0
	end

	saveAFKData(player)

	if _G.NotificationSystem and _G.NotificationSystem.showNotification then
		_G.NotificationSystem.showNotification(player, "🛌 AFK Mode Activated! You're locked in place for up to 12 hours.", "info")
	end

	return true, "AFK mode started successfully"
end

-- End AFK mode
local function endAFK(player, reason)
	local userId = player.UserId
	local data = playerAFKData[userId]
	if not data or not data.isAFK then return false, "Not in AFK mode" end

	local afkDuration = tick() - data.startTime
	data.totalAFKTime = (data.totalAFKTime or 0) + afkDuration
	data.isAFK = false
	data.startTime = nil

	-- Restore player movement
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.PlatformStand = false
		player.Character.Humanoid.WalkSpeed = 16
		player.Character.Humanoid.JumpPower = 50
	end

	-- Calculate AFK rewards
	local hours = afkDuration / 3600
	local baseIncome = _G.WorkerSystem and _G.WorkerSystem.calculateWorkerIncome(player) or 10
	local totalReward = math.floor(baseIncome * hours * AFK_INCOME_RATE)

	if totalReward > 0 and _G.CoinSystem and _G.CoinSystem.addCoins then
		_G.CoinSystem.addCoins(player, totalReward)

		if _G.NotificationSystem and _G.NotificationSystem.showNotification then
			local timeText = string.format("%.1f hours", hours)
			_G.NotificationSystem.showNotification(player, 
				"💰 AFK Rewards: +" .. totalReward .. " coins from " .. timeText .. " AFK!", 
				"success")
		end
	end

	saveAFKData(player)

	local reasonText = reason or "AFK ended"
	return true, reasonText .. " (Duration: " .. string.format("%.1f", hours) .. " hours)"
end

-- Check AFK time limit
local function checkAFKTimeLimit(player)
	local userId = player.UserId
	local data = playerAFKData[userId]
	if not data or not data.isAFK then return end

	local afkDuration = tick() - data.startTime
	if afkDuration >= MAX_AFK_TIME then
		endAFK(player, "12-hour time limit reached")
	end
end

-- Check if player moved (anti-AFK abuse)
local function checkPlayerMovement(player)
	local userId = player.UserId
	local data = playerAFKData[userId]
	if not data or not data.isAFK or not data.lastPosition then return end

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local currentPos = player.Character.HumanoidRootPart.Position
		local distance = (currentPos - data.lastPosition).Magnitude

		-- If player moved more than 5 studs, end AFK
		if distance > 5 then
			endAFK(player, "Movement detected - AFK cancelled")
		end
	end
end

-- Get AFK status
local function getAFKStatus(player)
	local userId = player.UserId
	local data = playerAFKData[userId]
	if not data then return {isAFK = false} end

	local status = {
		isAFK = data.isAFK,
		totalAFKTime = data.totalAFKTime or 0,
		afkSessionsToday = data.afkSessionsToday or 0
	}

	if data.isAFK and data.startTime then
		status.currentAFKDuration = tick() - data.startTime
		status.timeRemaining = MAX_AFK_TIME - status.currentAFKDuration
	end

	return status
end

-- Wait for manually created RemoteEvents
-- Note: Create these RemoteEvents manually in ReplicatedStorage/RemoteEvents/:
-- - ToggleAFK (RemoteEvent)
-- - GetAFKStatus (RemoteFunction)
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local toggleAFKRemote = remoteEventsFolder:WaitForChild("ToggleAFK")
local getAFKStatusRemote = remoteEventsFolder:WaitForChild("GetAFKStatus")

-- Remote handlers
toggleAFKRemote.OnServerEvent:Connect(function(player, action)
	local userId = player.UserId
	local data = playerAFKData[userId]

	if action == "start" then
		local success, message = startAFK(player)
		if not success and _G.NotificationSystem and _G.NotificationSystem.showNotification then
			_G.NotificationSystem.showNotification(player, "❌ " .. message, "error")
		end
	elseif action == "end" then
		local success, message = endAFK(player, "Manual stop")
		if success and _G.NotificationSystem and _G.NotificationSystem.showNotification then
			_G.NotificationSystem.showNotification(player, "✅ " .. message, "success")
		end
	end
end)

getAFKStatusRemote.OnServerInvoke = function(player)
	return getAFKStatus(player)
end

-- AFK monitoring loop
task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			checkAFKTimeLimit(player)
			checkPlayerMovement(player)
		end
		task.wait(POSITION_CHECK_INTERVAL)
	end
end)

-- Player management
Players.PlayerAdded:Connect(function(player)
	initializeAFKData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	-- End AFK if player leaves
	endAFK(player, "Player left game")
	saveAFKData(player)
	playerAFKData[player.UserId] = nil
end)

-- Character respawned - end AFK mode
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local userId = player.UserId
		local data = playerAFKData[userId]
		if data and data.isAFK then
			endAFK(player, "Character respawned")
		end
	end)
end)

-- Auto-save every 5 minutes
task.spawn(function()
	while true do
		task.wait(300) -- 5 minutes
		for _, player in ipairs(Players:GetPlayers()) do
			saveAFKData(player)
		end
	end
end)

-- Initialize for existing players
for _, player in ipairs(Players:GetPlayers()) do
	initializeAFKData(player)
end

-- Global functions
_G.AFKSystem = {
	startAFK = startAFK,
	endAFK = endAFK,
	getAFKStatus = getAFKStatus,
	canGoAFK = canGoAFK,
	isPlayerAFK = function(player)
		local data = playerAFKData[player.UserId]
		return data and data.isAFK or false
	end,
	initializePlayer = initializeAFKData
}

print("😴 AFK System Loaded!")
print("   - 12-hour session limit")
print("   - Movement detection")
print("   - Passive income during AFK")
print("   - Position locking (no movement)")