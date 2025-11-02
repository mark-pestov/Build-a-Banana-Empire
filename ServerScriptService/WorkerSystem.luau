-- WorkerSystem.lua - Automated Worker Management (NO PHYSICAL PARTS)
-- Place in ServerScriptService

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local workerDataStore = DataStoreService:GetDataStore("WorkerData")

-- Worker Configurations
local WORKER_TYPES = {
	["rookie_ripper"] = {
		name = "Rookie Ripper",
		baseCost = 1000,
		harvestSpeed = 0.5, -- harvests every 2 seconds
		bananaValue = 1.2, -- 20% bonus value
		emoji = "👤",
		description = "Basic worker with steady harvest",
		rebirthRequired = 1
	},
	["speedy_sprout"] = {
		name = "Speedy Sprout",
		baseCost = 5000,
		harvestSpeed = 0.3, -- harvests every 0.33 seconds (faster)
		bananaValue = 1.0, -- normal value
		emoji = "💨",
		description = "Harvests quickly but normal value",
		rebirthRequired = 1
	},
	["banana_bomber"] = {
		name = "Banana Bomber",
		baseCost = 25000,
		harvestSpeed = 1.0, -- harvests every 1 second
		bananaValue = 2.0, -- double value
		emoji = "💣",
		description = "Powerful harvests with double value",
		rebirthRequired = 2
	},
	["business_monkey"] = {
		name = "Business Monkey",
		baseCost = 100000,
		harvestSpeed = 0.8,
		bananaValue = 3.0, -- triple value
		emoji = "🐵💼",
		description = "Elite worker with triple banana value",
		rebirthRequired = 3
	},
	["legendary_monkey"] = {
		name = "Legendary Monkey Worker",
		baseCost = 1000000,
		harvestSpeed = 0.2, -- very fast
		bananaValue = 5.0, -- 5x value
		emoji = "🐒✨",
		description = "Ultimate worker with legendary performance",
		rebirthRequired = 5
	}
}

-- Player worker data
local playerWorkers = {} -- {userId: {workers: {...}, lastSave: tick()}}

-- Initialize worker system
local function initializeWorkerData(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return workerDataStore:GetAsync(userId)
	end)

	if success and data then
		playerWorkers[userId] = data
	else
		playerWorkers[userId] = {
			workers = {},
			totalWorkers = 0
		}
	end

	print("🔧 Initialized worker data for", player.Name)
end

-- Save worker data
local function saveWorkerData(player)
	local userId = player.UserId
	if not playerWorkers[userId] then return end

	local success, error = pcall(function()
		workerDataStore:SetAsync(userId, playerWorkers[userId])
	end)

	if not success then
		warn("Failed to save worker data for", player.Name, ":", error)
	end
end

-- Get worker cost (increases with each purchase)
local function getWorkerCost(workerType, currentCount)
	local baseConfig = WORKER_TYPES[workerType]
	if not baseConfig then return 0 end

	-- Cost increases exponentially: baseCost * (1.5 ^ currentCount)
	return math.floor(baseConfig.baseCost * (1.5 ^ currentCount))
end

-- Check if player can hire worker
local function canHireWorker(player, workerType)
	local rebirthLevel = _G.RebirthSystem and _G.RebirthSystem.getRebirthLevel(player) or 0
	local config = WORKER_TYPES[workerType]

	if not config then return false, "Invalid worker type" end
	if rebirthLevel < config.rebirthRequired then
		return false, "Requires Rebirth " .. config.rebirthRequired
	end

	local userId = player.UserId
	local workers = playerWorkers[userId] and playerWorkers[userId].workers or {}
	local currentCount = workers[workerType] or 0
	local cost = getWorkerCost(workerType, currentCount)

	local playerCoins = _G.CoinSystem and _G.CoinSystem.getCoins(player) or 0
	if playerCoins < cost then
		return false, "Not enough coins (need " .. cost .. ")"
	end

	return true, cost
end

-- Hire a worker
local function hireWorker(player, workerType)
	local canHire, costOrReason = canHireWorker(player, workerType)
	if not canHire then
		return false, costOrReason
	end

	local cost = costOrReason
	local userId = player.UserId

	-- Deduct coins
	if _G.CoinSystem and _G.CoinSystem.spendCoins then
		local success = _G.CoinSystem.spendCoins(player, cost)
		if not success then
			return false, "Failed to deduct coins"
		end
	end

	-- Add worker
	if not playerWorkers[userId] then
		playerWorkers[userId] = {workers = {}, totalWorkers = 0}
	end

	if not playerWorkers[userId].workers[workerType] then
		playerWorkers[userId].workers[workerType] = 0
	end

	playerWorkers[userId].workers[workerType] = playerWorkers[userId].workers[workerType] + 1
	playerWorkers[userId].totalWorkers = (playerWorkers[userId].totalWorkers or 0) + 1

	-- Award Battle Pass XP for worker hire
	if _G.BattlePassSystem and _G.BattlePassSystem.onWorkerHire then
		_G.BattlePassSystem.onWorkerHire(player)
	end

	-- Fire HireWorker event for other systems
	local hireWorkerRemote = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if hireWorkerRemote then
		hireWorkerRemote = hireWorkerRemote:FindFirstChild("HireWorker")
		if hireWorkerRemote then
			hireWorkerRemote:FireServer(player, workerType)
		end
	end

	-- Notify integration system
	if _G.IntegrationSystem and _G.IntegrationSystem.onWorkerHired then
		_G.IntegrationSystem.onWorkerHired(player, workerType, cost)
	end

	-- Save data
	saveWorkerData(player)

	return true, "Hired " .. WORKER_TYPES[workerType].name .. " for " .. cost .. " coins!"
end

-- Get player's workers
local function getPlayerWorkers(player)
	local userId = player.UserId
	return playerWorkers[userId] and playerWorkers[userId].workers or {}
end

-- Calculate total worker income per second
local function calculateWorkerIncome(player)
	local workers = getPlayerWorkers(player)
	local totalIncome = 0

	for workerType, count in pairs(workers) do
		local config = WORKER_TYPES[workerType]
		if config then
			-- Income = count * (harvestSpeed * bananaValue * base_banana_price)
			local basePrice = 10 -- base banana price
			local incomePerWorker = config.harvestSpeed * config.bananaValue * basePrice
			totalIncome = totalIncome + (incomePerWorker * count)
		end
	end

	return totalIncome
end

-- Worker income loop (passive income)
local function startWorkerIncomeLoop()
	task.spawn(function()
		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				local income = calculateWorkerIncome(player)
				if income > 0 then
					if _G.CoinSystem and _G.CoinSystem.addCoins then
						_G.CoinSystem.addCoins(player, income)
					end

					-- Notify integration system
					if _G.IntegrationSystem and _G.IntegrationSystem.onMoneyEarned then
						_G.IntegrationSystem.onMoneyEarned(player, income, "workers")
					end
				end
			end
			task.wait(1) -- Income every second
		end
	end)
end

-- Wait for manually created RemoteEvents
-- Note: Create these RemoteEvents manually in ReplicatedStorage/RemoteEvents/:
-- - HireWorker (RemoteEvent)  
-- - GetWorkerInfo (RemoteFunction)
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local hireWorkerRemote = remoteEventsFolder:WaitForChild("HireWorker")
local getWorkerInfoRemote = remoteEventsFolder:WaitForChild("GetWorkerInfo")

-- Remote handlers
hireWorkerRemote.OnServerEvent:Connect(function(player, workerType)
	local success, message = hireWorker(player, workerType)

	if _G.NotificationSystem and _G.NotificationSystem.showNotification then
		local notifType = success and "success" or "error"
		_G.NotificationSystem.showNotification(player, message, notifType)
	end
end)

getWorkerInfoRemote.OnServerInvoke = function(player)
	local workers = getPlayerWorkers(player)
	local income = calculateWorkerIncome(player)
	local rebirthLevel = _G.RebirthSystem and _G.RebirthSystem.getRebirthLevel(player) or 0

	local workerInfo = {}
	for workerType, config in pairs(WORKER_TYPES) do
		local currentCount = workers[workerType] or 0
		local cost = getWorkerCost(workerType, currentCount)
		local canHire, reason = canHireWorker(player, workerType)

		workerInfo[workerType] = {
			name = config.name,
			count = currentCount,
			cost = cost,
			canHire = canHire,
			reason = reason,
			emoji = config.emoji,
			description = config.description,
			rebirthRequired = config.rebirthRequired,
			unlocked = rebirthLevel >= config.rebirthRequired
		}
	end

	return {
		workers = workerInfo,
		totalIncome = income,
		totalWorkers = playerWorkers[player.UserId] and playerWorkers[player.UserId].totalWorkers or 0
	}
end

-- Player management
Players.PlayerAdded:Connect(function(player)
	initializeWorkerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	saveWorkerData(player)
	playerWorkers[player.UserId] = nil
end)

-- Auto-save every 5 minutes
task.spawn(function()
	while true do
		task.wait(300) -- 5 minutes
		for _, player in ipairs(Players:GetPlayers()) do
			saveWorkerData(player)
		end
	end
end)

-- Initialize for existing players
for _, player in ipairs(Players:GetPlayers()) do
	initializeWorkerData(player)
end

-- Start worker income
startWorkerIncomeLoop()

-- Global functions
_G.WorkerSystem = {
	hireWorker = hireWorker,
	getPlayerWorkers = getPlayerWorkers,
	calculateWorkerIncome = calculateWorkerIncome,
	getWorkerCost = getWorkerCost,
	canHireWorker = canHireWorker,
	WORKER_TYPES = WORKER_TYPES,
	initializePlayer = initializeWorkerData
}

print("👷 Worker System Loaded!")
print("   - 5 Worker types with different abilities")
print("   - Passive income generation")
print("   - Rebirth-gated progression")
print("   - No physical parts created")
