-- CockroachSystem.lua - Cockroach Infestation Management System (NO PHYSICAL PARTS)
-- Place in ServerScriptService

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local pestDataStore = DataStoreService:GetDataStore("PestData")

-- Cockroach Configuration
local PEST_SPAWN_CHANCE = 0.02 -- 2% chance per check
local PEST_CHECK_INTERVAL = 60 -- Check every minute
local PEST_SPREAD_CHANCE = 0.1 -- 10% chance to spread per minute
local PEST_EAT_TIME = 300 -- 5 minutes before cockroaches eat money
local INFESTATION_DURATION = 1800 -- 30 minutes for server-wide infestation

-- Global cockroach state
local globalPestState = {
	isInfested = false,
	infestationEndTime = 0,
	infestationType = "none" -- "server" or "global"
}

-- Player cockroach data
local playerPestData = {} -- {userId: {plotPests: {plotId: {infectedTime: tick(), cleared: bool}}, insurance: {...}}}

-- Initialize pest data
local function initializePestData(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return pestDataStore:GetAsync(userId)
	end)

	if success and data then
		playerPestData[userId] = data
	else
		playerPestData[userId] = {
			plotPests = {},
			insurance = {
				hasInsurance = false,
				insuranceEndTime = 0,
				totalClaims = 0
			},
			pestStats = {
				totalInfections = 0,
				totalCleared = 0,
				bananasLost = 0
			}
		}
	end

	print("🐛 Initialized pest data for", player.Name)
end

-- Save pest data
local function savePestData(player)
	local userId = player.UserId
	if not playerPestData[userId] then return end

	local success, error = pcall(function()
		pestDataStore:SetAsync(userId, playerPestData[userId])
	end)

	if not success then
		warn("Failed to save pest data for", player.Name, ":", error)
	end
end

-- Check if player has active insurance
local function hasInsurance(player)
	local userId = player.UserId
	local data = playerPestData[userId]
	if not data or not data.insurance then return false end

	return data.insurance.hasInsurance and tick() < data.insurance.insuranceEndTime
end

-- Purchase insurance
local function purchaseInsurance(player, duration, cost)
	local userId = player.UserId

	if not _G.CoinSystem or not _G.CoinSystem.spendCoins then
		return false, "Coin system not available"
	end

	local success = _G.CoinSystem.spendCoins(player, cost)
	if not success then
		return false, "Not enough coins"
	end

	local data = playerPestData[userId]
	data.insurance.hasInsurance = true
	data.insurance.insuranceEndTime = tick() + duration

	savePestData(player)

	local hours = duration / 3600
	return true, string.format("Purchased %d-hour insurance for %d coins!", hours, cost)
end

-- Infect a plot with cockroaches
local function infectPlot(player, plotId, source)
	local userId = player.UserId
	local data = playerPestData[userId]

	-- Check if plot is already infected
	if data.plotPests[plotId] then return false end

	-- Check insurance
	if hasInsurance(player) then
		if _G.NotificationSystem and _G.NotificationSystem.showNotification then
			_G.NotificationSystem.showNotification(player, "🛡️ Insurance protected your plot from cockroaches!", "success")
		end
		return false
	end

	data.plotPests[plotId] = {
		infectedTime = tick(),
		cleared = false,
		source = source or "random"
	}
	data.pestStats.totalInfections = data.pestStats.totalInfections + 1

	if _G.NotificationSystem and _G.NotificationSystem.showNotification then
		_G.NotificationSystem.showNotification(player, "🪳 Plot " .. plotId .. " infested with cockroaches! Clear them quickly!", "warning")
	end

	savePestData(player)
	return true
end

-- Clear cockroaches from a plot
local function clearPests(player, plotId)
	local userId = player.UserId
	local data = playerPestData[userId]

	if not data.plotPests[plotId] then
		return false, "No cockroaches on this plot"
	end

	data.plotPests[plotId] = nil
	data.pestStats.totalCleared = data.pestStats.totalCleared + 1

	if _G.NotificationSystem and _G.NotificationSystem.showNotification then
		_G.NotificationSystem.showNotification(player, "✅ Cleared cockroaches from plot " .. plotId .. "!", "success")
	end

	-- Update quest progress
	if _G.QuestSystem and _G.QuestSystem.updateProgress then
		_G.QuestSystem.updateProgress(player, "clear_pests", 1)
	end

	savePestData(player)
	return true, "Pests cleared successfully"
end

-- Check if cockroaches should eat money
local function checkPestDamage(player, plotId)
	local userId = player.UserId
	local data = playerPestData[userId]
	local pestInfo = data.plotPests[plotId]

	if not pestInfo or pestInfo.cleared then return false end

	local timeInfected = tick() - pestInfo.infectedTime
	if timeInfected >= PEST_EAT_TIME then
		-- Cockroaches eat money (simulate by reducing player's banana count)
		local bananasLost = math.random(5, 15)
		data.pestStats.bananasLost = data.pestStats.bananasLost + bananasLost

		-- Clear the pests after they eat
		data.plotPests[plotId] = nil

		if _G.NotificationSystem and _G.NotificationSystem.showNotification then
			_G.NotificationSystem.showNotification(player, "💸 Cockroaches stole $" .. bananasLost .. " from plot " .. plotId .. "!", "error")
		end

		savePestData(player)
		return true, bananasLost
	end

	return false, 0
end

-- Spread cockroaches to nearby plots
local function spreadPests(player, fromPlotId)
	local userId = player.UserId
	local data = playerPestData[userId]

	-- Try to spread to adjacent plots
	local adjacentPlots = {fromPlotId - 1, fromPlotId + 1}

	for _, plotId in ipairs(adjacentPlots) do
		if plotId > 0 and plotId <= 50 and math.random() < PEST_SPREAD_CHANCE then
			if not data.plotPests[plotId] then
				infectPlot(player, plotId, "spread")
			end
		end
	end
end

-- Start global infestation (gamepass feature)
local function startGlobalInfestation(infestationType, duration)
	globalPestState.isInfested = true
	globalPestState.infestationType = infestationType
	globalPestState.infestationEndTime = tick() + duration

	-- Infect random plots for all players
	for _, player in ipairs(Players:GetPlayers()) do
		local plotsToInfect = math.random(1, 3)
		for i = 1, plotsToInfect do
			local randomPlot = math.random(1, 10)
			infectPlot(player, randomPlot, "global_infestation")
		end
	end

	-- Global notification
	for _, player in ipairs(Players:GetPlayers()) do
		if _G.NotificationSystem and _G.NotificationSystem.showNotification then
			local message = infestationType == "global" and "🌍 GLOBAL COCKROACH INVASION!" or "🖥️ SERVER COCKROACH OUTBREAK!"
			_G.NotificationSystem.showNotification(player, message .. " All farms under attack!", "error")
		end
	end

	print("🪳 Global cockroach infestation started:", infestationType, "duration:", duration)
end

-- Get player's pest status
local function getPestStatus(player)
	local userId = player.UserId
	local data = playerPestData[userId]

	local activeInfections = 0
	local plotStatus = {}

	for plotId, pestInfo in pairs(data.plotPests) do
		if not pestInfo.cleared then
			activeInfections = activeInfections + 1
			plotStatus[plotId] = {
				infectedTime = pestInfo.infectedTime,
				timeRemaining = PEST_EAT_TIME - (tick() - pestInfo.infectedTime),
				source = pestInfo.source
			}
		end
	end

	return {
		activeInfections = activeInfections,
		plotStatus = plotStatus,
		hasInsurance = hasInsurance(player),
		insuranceTimeLeft = data.insurance.hasInsurance and math.max(0, data.insurance.insuranceEndTime - tick()) or 0,
		stats = data.pestStats,
		globalInfestation = globalPestState.isInfested
	}
end

-- Pest system main loop
task.spawn(function()
	while true do
		task.wait(PEST_CHECK_INTERVAL)

		-- Check global infestation status
		if globalPestState.isInfested and tick() >= globalPestState.infestationEndTime then
			globalPestState.isInfested = false
			globalPestState.infestationType = "none"

			for _, player in ipairs(Players:GetPlayers()) do
				if _G.NotificationSystem and _G.NotificationSystem.showNotification then
					_G.NotificationSystem.showNotification(player, "✅ Global pest infestation ended!", "success")
				end
			end
		end

		for _, player in ipairs(Players:GetPlayers()) do
			local userId = player.UserId
			local data = playerPestData[userId]

			-- Check for new random infections (if not in AFK mode)
			local isAFK = _G.AFKSystem and _G.AFKSystem.isPlayerAFK(player) or false
			if not isAFK and not globalPestState.isInfested then
				if math.random() < PEST_SPAWN_CHANCE then
					local randomPlot = math.random(1, 10)
					infectPlot(player, randomPlot, "random")
				end
			end

			-- Check existing infections
			for plotId, pestInfo in pairs(data.plotPests) do
				if not pestInfo.cleared then
					-- Check if cockroaches should eat money
					checkPestDamage(player, plotId)

					-- Spread cockroaches
					if math.random() < PEST_SPREAD_CHANCE then
						spreadPests(player, plotId)
					end
				end
			end
		end
	end
end)

-- Wait for manually created RemoteEvents
-- Note: Create these RemoteEvents manually in ReplicatedStorage/RemoteEvents/:
-- - ClearPests (RemoteEvent)
-- - BuyInsurance (RemoteEvent) 
-- - GetPestStatus (RemoteFunction)
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local clearPestsRemote = remoteEventsFolder:WaitForChild("ClearPests")
local buyInsuranceRemote = remoteEventsFolder:WaitForChild("BuyInsurance")
local getPestStatusRemote = remoteEventsFolder:WaitForChild("GetPestStatus")

-- Remote handlers
clearPestsRemote.OnServerEvent:Connect(function(player, plotId)
	local success, message = clearPests(player, plotId)

	if _G.NotificationSystem and _G.NotificationSystem.showNotification then
		local notifType = success and "success" or "error"
		_G.NotificationSystem.showNotification(player, message or "Failed to clear pests", notifType)
	end
end)

buyInsuranceRemote.OnServerEvent:Connect(function(player, durationType)
	local cost, duration

	if durationType == "1hour" then
		cost = 1000
		duration = 3600
	elseif durationType == "24hour" then
		cost = 20000
		duration = 86400
	else
		return
	end

	local success, message = purchaseInsurance(player, duration, cost)

	if _G.NotificationSystem and _G.NotificationSystem.showNotification then
		local notifType = success and "success" or "error"
		_G.NotificationSystem.showNotification(player, message, notifType)
	end
end)

getPestStatusRemote.OnServerInvoke = function(player)
	return getPestStatus(player)
end

-- Player management
Players.PlayerAdded:Connect(function(player)
	initializePestData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	savePestData(player)
	playerPestData[player.UserId] = nil
end)

-- Auto-save every 5 minutes
task.spawn(function()
	while true do
		task.wait(300) -- 5 minutes
		for _, player in ipairs(Players:GetPlayers()) do
			savePestData(player)
		end
	end
end)

-- Initialize for existing players
for _, player in ipairs(Players:GetPlayers()) do
	initializePestData(player)
end

-- Global functions
_G.PestSystem = {
	infectPlot = infectPlot,
	clearPests = clearPests,
	getPestStatus = getPestStatus,
	hasInsurance = hasInsurance,
	purchaseInsurance = purchaseInsurance,
	startGlobalInfestation = startGlobalInfestation,
	spawnPest = function(player, pestType)
		-- Simple wrapper to infect player's plot
		-- Note: pestType parameter is ignored as we only have one pest type: "Pest"
		if _G.PlotSystem and _G.PlotSystem.getPlayerPlot then
			local plotId = _G.PlotSystem.getPlayerPlot(player)
			if plotId then
				infectPlot(player, plotId)
			end
		end
	end,
	PEST_GROWTH_SLOWDOWN = PEST_GROWTH_SLOWDOWN,
	initializePlayer = initializePestData
}

print("🐛 Pest System Loaded!")
print("   - Random pest spawning")
print("   - Pest spreading mechanics")
print("   - Insurance system")
print("   - Global infestation support")
print("   - No physical parts created")
-- NOTE: PestSystem only affects growth duration/attributes (via multipliers).
-- It does NOT animate or size fruit. All fruit growth logic is handled by PlotBananaGrowth.luau.