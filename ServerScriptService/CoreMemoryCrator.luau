-- CoreMemoryCrater.lua
-- Server-side system for storing and recovering lost/eaten bananas
-- Place in ServerScriptService

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CoreMemoryCrater = {}

-- Configuration
local Config = {
	MaxStoredBananas = 1000, -- Maximum bananas that can be stored per player
	RecoveryChance = 0.3, -- 30% chance to recover each banana
	RecoveryCost = 50, -- Cost per banana recovery attempt
	CraterDecayTime = 86400 * 7 -- 7 days before bananas decay from crater
}

-- DataStore for crater data
local CraterDataStore = DataStoreService:GetDataStore("CoreMemoryCrater")

-- Player crater data
local playerCraterData = {}

-- Initialize crater system
function CoreMemoryCrater.Initialize()
	print("Core Memory Crater system initialized")

	-- Connect to existing systems
	if _G.PestSystem then
		_G.PestSystem.OnBananaEaten = CoreMemoryCrater.OnBananaEaten
	end

	-- Set up data loading/saving
	Players.PlayerAdded:Connect(CoreMemoryCrater.OnPlayerAdded)
	Players.PlayerRemoving:Connect(CoreMemoryCrater.OnPlayerRemoving)

	-- Periodic cleanup of old bananas
	spawn(function()
		while true do
			CoreMemoryCrater.CleanupExpiredBananas()
			wait(3600) -- Check every hour
		end
	end)
end

-- Handle player joining
function CoreMemoryCrater.OnPlayerAdded(player)
	local success, data = pcall(function()
		return CraterDataStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		playerCraterData[player] = data
	else
		playerCraterData[player] = {
			storedBananas = {},
			totalLost = 0,
			totalRecovered = 0
		}
	end

	print("Loaded crater data for " .. player.Name)
end

-- Handle player leaving
function CoreMemoryCrater.OnPlayerRemoving(player)
	local data = playerCraterData[player]
	if data then
		local success = pcall(function()
			CraterDataStore:SetAsync("Player_" .. player.UserId, data)
		end)

		if success then
			print("Saved crater data for " .. player.Name)
		else
			warn("Failed to save crater data for " .. player.Name)
		end
	end

	playerCraterData[player] = nil
end

-- Called when bananas are eaten by pests or lost
function CoreMemoryCrater.OnBananaEaten(player, amount, seedType)
	local data = playerCraterData[player]
	if not data then return end

	-- Add bananas to crater with timestamp
	local currentTime = tick()

	for i = 1, amount do
		if #data.storedBananas < Config.MaxStoredBananas then
			table.insert(data.storedBananas, {
				seedType = seedType or "Standard",
				timestamp = currentTime,
				value = CoreMemoryCrater.GetBananaValue(seedType)
			})
		end
	end

	data.totalLost = data.totalLost + amount

	-- Notify player
	CoreMemoryCrater.NotifyPlayer(player, "🍌💀 " .. amount .. " bananas lost to the Core Memory Crater!")

	print(player.Name .. " lost " .. amount .. " bananas to crater")
end

-- Get banana value based on seed type
function CoreMemoryCrater.GetBananaValue(seedType)
	local values = {
		Standard = 10,
		Basic = 15,
		Solid = 25,
		Legendary = 100,
		Mythical = 250,
		Celestial = 500,
		Ascended = 1000,
		Godly = 2500,
		Transcendent = 5000
	}

	return values[seedType] or values.Standard
end

-- Attempt to recover bananas from crater
function CoreMemoryCrater.AttemptRecovery(player, maxAttempts)
	local data = playerCraterData[player]
	if not data or #data.storedBananas == 0 then
		return {success = false, message = "No bananas in your crater to recover!"}
	end

	-- Check if player has enough coins
	local totalCost = maxAttempts * Config.RecoveryCost
	local playerCoins = CoreMemoryCrater.GetPlayerCoins(player)

	if playerCoins < totalCost then
		return {success = false, message = "Not enough coins! Need " .. totalCost .. " coins."}
	end

	-- Remove coins
	CoreMemoryCrater.RemovePlayerCoins(player, totalCost)

	local recovered = {}
	local attempts = math.min(maxAttempts, #data.storedBananas)

	for i = 1, attempts do
		local banana = table.remove(data.storedBananas, math.random(#data.storedBananas))

		if math.random() <= Config.RecoveryChance then
			-- Successfully recovered
			table.insert(recovered, banana)
			data.totalRecovered = data.totalRecovered + 1

			-- Add banana back to inventory (integrate with inventory system)
			CoreMemoryCrater.AddBananaToInventory(player, banana.seedType, 1)
		end
	end

	local recoveredCount = #recovered
	local totalValue = 0
	for _, banana in ipairs(recovered) do
		totalValue = totalValue + banana.value
	end

	if recoveredCount > 0 then
		return {
			success = true, 
			message = "🎉 Recovered " .. recoveredCount .. " bananas worth " .. totalValue .. " coins!",
			recovered = recoveredCount,
			value = totalValue
		}
	else
		return {
			success = true,
			message = "😔 Recovery failed this time. Try again!",
			recovered = 0,
			value = 0
		}
	end
end

-- Get crater status for player
function CoreMemoryCrater.GetCraterStatus(player)
	local data = playerCraterData[player]
	if not data then return nil end

	local currentTime = tick()
	local validBananas = {}

	-- Filter out expired bananas
	for _, banana in ipairs(data.storedBananas) do
		if currentTime - banana.timestamp < Config.CraterDecayTime then
			table.insert(validBananas, banana)
		end
	end

	data.storedBananas = validBananas

	return {
		storedCount = #data.storedBananas,
		totalLost = data.totalLost,
		totalRecovered = data.totalRecovered,
		recoveryCost = Config.RecoveryCost,
		recoveryChance = Config.RecoveryChance * 100
	}
end

-- Cleanup expired bananas
function CoreMemoryCrater.CleanupExpiredBananas()
	local currentTime = tick()

	for player, data in pairs(playerCraterData) do
		local validBananas = {}
		local expiredCount = 0

		for _, banana in ipairs(data.storedBananas) do
			if currentTime - banana.timestamp < Config.CraterDecayTime then
				table.insert(validBananas, banana)
			else
				expiredCount = expiredCount + 1
			end
		end

		if expiredCount > 0 then
			data.storedBananas = validBananas
			CoreMemoryCrater.NotifyPlayer(player, "⏰ " .. expiredCount .. " bananas decayed from your crater.")
		end
	end
end

-- Helper functions for integration
function CoreMemoryCrater.GetPlayerCoins(player)
	if _G.CoinSystem and _G.CoinSystem.GetCoins then
		return _G.CoinSystem.GetCoins(player)
	end
	return 0
end

function CoreMemoryCrater.RemovePlayerCoins(player, amount)
	if _G.CoinSystem and _G.CoinSystem.RemoveCoins then
		return _G.CoinSystem.RemoveCoins(player, amount)
	end
	return false
end

function CoreMemoryCrater.AddBananaToInventory(player, seedType, amount)
	-- This should integrate with your inventory system
	print("Would add " .. amount .. " " .. seedType .. " bananas to " .. player.Name .. "'s inventory")
end

function CoreMemoryCrater.NotifyPlayer(player, message)
	if _G.NotificationSystem and _G.NotificationSystem.SendNotification then
		_G.NotificationSystem.SendNotification(player, message)
	else
		print("Notification for " .. player.Name .. ": " .. message)
	end
end

-- Global access
_G.CoreMemoryCrater = CoreMemoryCrater

-- Initialize on script load
CoreMemoryCrater.Initialize()

return CoreMemoryCrater
