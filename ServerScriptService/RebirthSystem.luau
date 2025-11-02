-- RebirthSystem.lua - Rebirth and Workers System
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Data stores
local rebirthDataStore = DataStoreService:GetDataStore("PlayerRebirth")
local workerDataStore = DataStoreService:GetDataStore("PlayerWorkers")

-- Player data
local playerRebirthData = {} -- {userId: {rebirths: number, bananasSold: number}}
local playerWorkers = {} -- {userId: {workers: {workerType: level}}}

-- Worker types and their effects
local WORKER_TYPES = {
	["Rookie Ripper"] = {
		basePrice = 1000,
		effect = "harvest_speed",
		multiplier = 0.05, -- 5% faster harvesting per level
		maxLevel = 10,
		unlockRebirth = 1
	},
	["Speedy Sprout"] = {
		basePrice = 5000,
		effect = "growth_speed",
		multiplier = 0.03, -- 3% faster growth per level
		maxLevel = 15,
		unlockRebirth = 1
	},
	["Banana Bomber"] = {
		basePrice = 25000,
		effect = "banana_spawn",
		multiplier = 0.02, -- 2% more bananas per level
		maxLevel = 20,
		unlockRebirth = 2
	},
	["Business Monkey"] = {
		basePrice = 100000,
		effect = "sell_bonus",
		multiplier = 0.04, -- 4% better selling prices per level
		maxLevel = 25,
		unlockRebirth = 3
	},
	["Legendary Monkey Worker"] = {
		basePrice = 1000000,
		effect = "all_boost",
		multiplier = 0.01, -- 1% boost to everything per level
		maxLevel = 50,
		unlockRebirth = 5
	}
}

-- Rebirth requirements
local REBIRTH_REQUIREMENTS = {
	[1] = 100000,   -- 100k bananas sold for rebirth 1
	[2] = 500000,   -- 500k bananas sold for rebirth 2
	[3] = 2000000,  -- 2M bananas sold for rebirth 3
	[4] = 10000000, -- 10M bananas sold for rebirth 4
	[5] = 50000000  -- 50M bananas sold for rebirth 5
}

-- Wait for manually created RemoteEvents
-- Note: Create these RemoteEvents manually in ReplicatedStorage/RemoteEvents/:
-- - PerformRebirth (RemoteEvent)
-- - BuyWorker (RemoteEvent)
-- - GetRebirthData (RemoteFunction)
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local rebirthRemote = remoteEventsFolder:WaitForChild("PerformRebirth")
local buyWorkerRemote = remoteEventsFolder:WaitForChild("BuyWorker")
local getRebirthDataRemote = remoteEventsFolder:WaitForChild("GetRebirthData")

-- Initialize player rebirth data
local function initPlayerRebirthData(player)
	local success, savedData = pcall(function()
		return rebirthDataStore:GetAsync(player.UserId)
	end)

	local rebirthData = {
		rebirths = 0,
		bananasSold = 0,
		totalBananasSold = 0
	}

	if success and savedData then
		rebirthData = savedData
	end

	playerRebirthData[player.UserId] = rebirthData

	-- Initialize workers
	local workerSuccess, workerSavedData = pcall(function()
		return workerDataStore:GetAsync(player.UserId)
	end)

	local workers = {}
	if workerSuccess and workerSavedData then
		workers = workerSavedData
	end

	playerWorkers[player.UserId] = workers

	print("🔄 Initialized rebirth data for", player.Name, "- Rebirths:", rebirthData.rebirths)
end

-- Save player rebirth data
local function savePlayerRebirthData(player)
	pcall(function()
		rebirthDataStore:SetAsync(player.UserId, playerRebirthData[player.UserId])
	end)
	pcall(function()
		workerDataStore:SetAsync(player.UserId, playerWorkers[player.UserId])
	end)
end

-- Check if player can rebirth
local function canRebirth(player)
	local data = playerRebirthData[player.UserId]
	if not data then return false end

	local nextRebirthLevel = data.rebirths + 1
	local requirement = REBIRTH_REQUIREMENTS[nextRebirthLevel]

	if not requirement then return false end -- Max rebirths reached

	return data.bananasSold >= requirement
end

-- Perform rebirth
local function performRebirth(player)
	local data = playerRebirthData[player.UserId]
	if not data or not canRebirth(player) then return false end

	-- Reset progress but keep total
	data.totalBananasSold = data.totalBananasSold + data.bananasSold
	data.rebirths = data.rebirths + 1
	data.bananasSold = 0

	-- Reset player's coins but give rebirth bonus
	if _G.CoinSystem then
		_G.CoinSystem.setPlayerCoins(player, 0)
	end

	-- Give starting seeds after rebirth
	if _G.SeedSystem then
		_G.SeedSystem.addSeeds(player, "banappleTreeSeed", 5)
	end

	savePlayerRebirthData(player)

	-- Notification
	if _G.showNotification then
		_G.showNotification(player, "🔄 REBIRTH COMPLETE! Level " .. data.rebirths, "success")
		_G.showNotification(player, "Workers unlocked! Growth speed +1% per upgrade!", "info")
	end

	print("🔄 Player", player.Name, "rebirthed to level", data.rebirths)
	return true
end

-- Buy worker upgrade
local function buyWorkerUpgrade(player, workerType)
	local rebirthData = playerRebirthData[player.UserId]
	local workers = playerWorkers[player.UserId]
	local workerConfig = WORKER_TYPES[workerType]

	if not rebirthData or not workers or not workerConfig then return false end

	-- Check rebirth requirement
	if rebirthData.rebirths < workerConfig.unlockRebirth then
		if _G.showNotification then
			_G.showNotification(player, "Requires Rebirth " .. workerConfig.unlockRebirth, "error")
		end
		return false
	end

	-- Check current level
	local currentLevel = workers[workerType] or 0
	if currentLevel >= workerConfig.maxLevel then
		if _G.showNotification then
			_G.showNotification(player, workerType .. " is at max level!", "error")
		end
		return false
	end

	-- Calculate price
	local price = workerConfig.basePrice * (currentLevel + 1)

	-- Check if player can afford
	local playerCoins = _G.CoinSystem and _G.CoinSystem.getPlayerCoins(player) or 0
	if playerCoins < price then
		if _G.showNotification then
			_G.showNotification(player, "Need " .. price .. " coins!", "error")
		end
		return false
	end

	-- Purchase worker upgrade
	if _G.CoinSystem then
		_G.CoinSystem.subtractCoins(player, price)
	end

	workers[workerType] = currentLevel + 1
	savePlayerRebirthData(player)

	if _G.showNotification then
		_G.showNotification(player, workerType .. " upgraded to level " .. workers[workerType], "success")
	end

	return true
end

-- Get worker multiplier for a specific effect
local function getWorkerMultiplier(player, effectType)
	local workers = playerWorkers[player.UserId]
	if not workers then return 1 end

	local totalMultiplier = 1

	for workerType, level in pairs(workers) do
		local config = WORKER_TYPES[workerType]
		if config and (config.effect == effectType or config.effect == "all_boost") then
			totalMultiplier = totalMultiplier + (config.multiplier * level)
		end
	end

	return totalMultiplier
end

-- Add bananas sold (for rebirth tracking)
local function addBananasSold(player, amount)
	local data = playerRebirthData[player.UserId]
	if data then
		data.bananasSold = data.bananasSold + amount
	end
end

-- Remote event handlers
rebirthRemote.OnServerEvent:Connect(function(player)
	performRebirth(player)
end)

buyWorkerRemote.OnServerEvent:Connect(function(player, workerType)
	buyWorkerUpgrade(player, workerType)
end)

getRebirthDataRemote.OnServerInvoke = function(player)
	local rebirthData = playerRebirthData[player.UserId] or {rebirths = 0, bananasSold = 0}
	local workers = playerWorkers[player.UserId] or {}

	return {
		rebirthData = rebirthData,
		workers = workers,
		workerTypes = WORKER_TYPES,
		requirements = REBIRTH_REQUIREMENTS,
		canRebirth = canRebirth(player)
	}
end

-- Player events
Players.PlayerAdded:Connect(initPlayerRebirthData)
Players.PlayerRemoving:Connect(savePlayerRebirthData)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
	initPlayerRebirthData(player)
end

-- Global functions for other scripts
_G.RebirthSystem = {
	getWorkerMultiplier = getWorkerMultiplier,
	addBananasSold = addBananasSold,
	getPlayerRebirths = function(player)
		local data = playerRebirthData[player.UserId]
		return data and data.rebirths or 0
	end
}

print("🔄 Rebirth and Workers System Loaded!")
print("   - 5 worker types available")
print("   - Growth speed bonuses implemented")
print("   - Rebirth progression system active")
