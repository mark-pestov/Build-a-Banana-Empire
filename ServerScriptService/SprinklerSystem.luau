-- SprinklerSystem.lua - Growth Enhancement System (NO PHYSICAL PARTS)
-- Place in ServerScriptService

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sprinklerDataStore = DataStoreService:GetDataStore("SprinklerData")

-- Inversion state for admin commands
local inversionActive = false

-- Sprinkler Configurations
local SPRINKLER_TYPES = {
	["trash"] = {
		name = "Trash Sprinkler",
		cost = 5000,
		growthSpeedMultiplier = 1.2, -- 20% faster growth
		plantSizeMultiplier = 1.1, -- 10% bigger plants
		range = 5, -- affects plots within 5 studs
		emoji = "🗑️💧",
		description = "Basic sprinkler with modest benefits"
	},
	["noob"] = {
		name = "Noob Sprinkler", 
		cost = 25000,
		growthSpeedMultiplier = 1.5, -- 50% faster growth
		plantSizeMultiplier = 1.3, -- 30% bigger plants
		range = 8,
		emoji = "🌱💧",
		description = "Decent sprinkler for beginners"
	},
	["pro"] = {
		name = "Pro Sprinkler",
		cost = 125000,
		growthSpeedMultiplier = 2.0, -- 100% faster growth (double speed)
		plantSizeMultiplier = 1.6, -- 60% bigger plants
		range = 12,
		emoji = "⚡💧",
		description = "Professional-grade irrigation"
	},
	["sigma"] = {
		name = "Sigma Sprinkler",
		cost = 1000000,
		growthSpeedMultiplier = 3.0, -- 200% faster growth (triple speed)
		plantSizeMultiplier = 2.0, -- 100% bigger plants (double size)
		range = 20,
		emoji = "🔥💧",
		description = "Elite sprinkler with massive benefits"
	},
	["monkey"] = {
		name = "Monkey Sprinkler",
		cost = 100000000,
		growthSpeedMultiplier = 5.0, -- 400% faster growth (5x speed)
		plantSizeMultiplier = 4.0, -- 300% bigger plants (4x size)
		range = 50, -- affects entire farm
		emoji = "🐒💧",
		description = "Ultimate sprinkler with legendary power"
	}
}

-- Player sprinkler data
local playerSprinklers = {} -- {userId: {sprinklers: {...}, activeBonuses: {...}}}

-- Initialize sprinkler data
local function initializeSprinklerData(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return sprinklerDataStore:GetAsync(userId)
	end)

	if success and data then
		playerSprinklers[userId] = data
	else
		playerSprinklers[userId] = {
			sprinklers = {},
			activeBonuses = {}
		}
	end

	print("💧 Initialized sprinkler data for", player.Name)
end

-- Save sprinkler data
local function saveSprinklerData(player)
	local userId = player.UserId
	if not playerSprinklers[userId] then return end

	local success, error = pcall(function()
		sprinklerDataStore:SetAsync(userId, playerSprinklers[userId])
	end)

	if not success then
		warn("Failed to save sprinkler data for", player.Name, ":", error)
	end
end

-- Purchase a sprinkler
local function purchaseSprinkler(player, sprinklerType, plotId)
	local config = SPRINKLER_TYPES[sprinklerType]
	if not config then
		return false, "Invalid sprinkler type"
	end

	local userId = player.UserId
	local playerCoins = _G.CoinSystem and _G.CoinSystem.getCoins(player) or 0

	if playerCoins < config.cost then
		return false, "Not enough coins (need " .. config.cost .. ")"
	end

	-- Deduct coins
	if _G.CoinSystem and _G.CoinSystem.spendCoins then
		local success = _G.CoinSystem.spendCoins(player, config.cost)
		if not success then
			return false, "Failed to deduct coins"
		end
	end

	-- Add sprinkler to player data
	if not playerSprinklers[userId] then
		playerSprinklers[userId] = {sprinklers = {}, activeBonuses = {}}
	end

	if not playerSprinklers[userId].sprinklers[plotId] then
		playerSprinklers[userId].sprinklers[plotId] = {}
	end

	-- Add sprinkler (can have multiple per plot)
	table.insert(playerSprinklers[userId].sprinklers[plotId], {
		type = sprinklerType,
		purchaseTime = tick(),
		active = true
	})

	-- Award Battle Pass XP for sprinkler purchase
	if _G.BattlePassSystem and _G.BattlePassSystem.onSprinklerBuy then
		_G.BattlePassSystem.onSprinklerBuy(player)
	end

	-- Fire PurchaseSprinkler event for other systems
	local purchaseSprinklerRemote = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if purchaseSprinklerRemote then
		purchaseSprinklerRemote = purchaseSprinklerRemote:FindFirstChild("PurchaseSprinkler")
		if purchaseSprinklerRemote then
			purchaseSprinklerRemote:FireServer(player, sprinklerType, plotId)
		end
	end

	-- Update active bonuses
	updatePlayerBonuses(player)

	-- Notify integration system
	if _G.IntegrationSystem and _G.IntegrationSystem.onSprinklerPurchased then
		_G.IntegrationSystem.onSprinklerPurchased(player, sprinklerType, config.cost)
	end

	-- Save data
	saveSprinklerData(player)

	return true, "Purchased " .. config.name .. " for " .. config.cost .. " coins!"
end

-- Calculate best bonuses for a plot
local function calculatePlotBonuses(player, plotId)
	local userId = player.UserId
	if not playerSprinklers[userId] or not playerSprinklers[userId].sprinklers then
		return 1.0, 1.0 -- default multipliers
	end

	local bestGrowthMultiplier = 1.0
	local bestSizeMultiplier = 1.0

	-- Check sprinklers on this plot
	local plotSprinklers = playerSprinklers[userId].sprinklers[plotId] or {}
	for _, sprinkler in ipairs(plotSprinklers) do
		if sprinkler.active then
			local config = SPRINKLER_TYPES[sprinkler.type]
			if config then
				bestGrowthMultiplier = math.max(bestGrowthMultiplier, config.growthSpeedMultiplier)
				bestSizeMultiplier = math.max(bestSizeMultiplier, config.plantSizeMultiplier)
			end
		end
	end

	-- Check nearby sprinklers with range effects
	for otherPlotId, sprinklers in pairs(playerSprinklers[userId].sprinklers) do
		if otherPlotId ~= plotId then
			for _, sprinkler in ipairs(sprinklers) do
				if sprinkler.active then
					local config = SPRINKLER_TYPES[sprinkler.type]
					if config then
						-- Calculate distance between plots (simplified)
						local distance = math.abs(plotId - otherPlotId) * 10 -- assuming plots are 10 studs apart
						if distance <= config.range then
							local effectMultiplier = 1 - (distance / config.range) * 0.5 -- 50% reduction at max range
							local effectiveGrowth = 1 + (config.growthSpeedMultiplier - 1) * effectMultiplier
							local effectiveSize = 1 + (config.plantSizeMultiplier - 1) * effectMultiplier

							bestGrowthMultiplier = math.max(bestGrowthMultiplier, effectiveGrowth)
							bestSizeMultiplier = math.max(bestSizeMultiplier, effectiveSize)
						end
					end
				end
			end
		end
	end

	return bestGrowthMultiplier, bestSizeMultiplier
end

-- Update player's active bonuses
local function updatePlayerBonuses(player)
	local userId = player.UserId
	if not playerSprinklers[userId] then return end

	playerSprinklers[userId].activeBonuses = {}

	-- Calculate bonuses for each plot the player might use
	for plotId = 1, 50 do -- assuming max 50 plots
		local growthMult, sizeMult = calculatePlotBonuses(player, plotId)
		if growthMult > 1.0 or sizeMult > 1.0 then
			playerSprinklers[userId].activeBonuses[plotId] = {
				growthMultiplier = growthMult,
				sizeMultiplier = sizeMult
			}
		end
	end
end

-- Get sprinkler bonuses for a plot
local function getSprinklerBonuses(player, plotId)
	local userId = player.UserId
	if not playerSprinklers[userId] or not playerSprinklers[userId].activeBonuses then
		return 1.0, 1.0
	end

	local bonuses = playerSprinklers[userId].activeBonuses[plotId]
	if bonuses then
		return bonuses.growthMultiplier, bonuses.sizeMultiplier
	else
		return 1.0, 1.0
	end
end

-- Get player's sprinklers
local function getPlayerSprinklers(player)
	local userId = player.UserId
	return playerSprinklers[userId] and playerSprinklers[userId].sprinklers or {}
end

-- RemoteEvents setup
-- Wait for manually created RemoteEvents
-- Note: Create these RemoteEvents manually in ReplicatedStorage/RemoteEvents/:
-- - PurchaseSprinkler (RemoteEvent)
-- - GetSprinklerInfo (RemoteFunction)
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local purchaseSprinklerRemote = remoteEventsFolder:WaitForChild("PurchaseSprinkler")
local getSprinklerInfoRemote = remoteEventsFolder:WaitForChild("GetSprinklerInfo")

-- Remote handlers
purchaseSprinklerRemote.OnServerEvent:Connect(function(player, sprinklerType, plotId)
	local success, message = purchaseSprinkler(player, sprinklerType, plotId or 1)

	if _G.NotificationSystem and _G.NotificationSystem.showNotification then
		local notifType = success and "success" or "error"
		_G.NotificationSystem.showNotification(player, message, notifType)
	end
end)

getSprinklerInfoRemote.OnServerInvoke = function(player)
	local sprinklers = getPlayerSprinklers(player)
	local playerCoins = _G.CoinSystem and _G.CoinSystem.getCoins(player) or 0

	local sprinklerInfo = {}
	for sprinklerType, config in pairs(SPRINKLER_TYPES) do
		sprinklerInfo[sprinklerType] = {
			name = config.name,
			cost = config.cost,
			canAfford = playerCoins >= config.cost,
			growthBonus = math.floor((config.growthSpeedMultiplier - 1) * 100),
			sizeBonus = math.floor((config.plantSizeMultiplier - 1) * 100),
			range = config.range,
			emoji = config.emoji,
			description = config.description
		}
	end

	return {
		available = sprinklerInfo,
		owned = sprinklers,
		activeBonuses = playerSprinklers[player.UserId] and playerSprinklers[player.UserId].activeBonuses or {}
	}
end

-- Player management
Players.PlayerAdded:Connect(function(player)
	initializeSprinklerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	saveSprinklerData(player)
	playerSprinklers[player.UserId] = nil
end)

-- Auto-save every 5 minutes
task.spawn(function()
	while true do
		task.wait(300) -- 5 minutes
		for _, player in ipairs(Players:GetPlayers()) do
			saveSprinklerData(player)
		end
	end
end)

-- Initialize for existing players
for _, player in ipairs(Players:GetPlayers()) do
	initializeSprinklerData(player)
end

-- Global functions
_G.SprinklerSystem = {
	purchaseSprinkler = purchaseSprinkler,
	getSprinklerBonuses = getSprinklerBonuses,
	getPlayerSprinklers = getPlayerSprinklers,
	calculatePlotBonuses = calculatePlotBonuses,
	SPRINKLER_TYPES = SPRINKLER_TYPES,
	initializePlayer = initializeSprinklerData,

	-- Legacy function for existing integrations
	getSprinklerPlantSizeMultiplier = function(plotId)
		-- This is a simplified version - in practice you'd need player context
		return 1.0
	end,
	
	-- Inversion functions for admin commands
	invertEffects = function()
		inversionActive = true
		print("🔄 SprinklerSystem: Effects inverted - sprinklers now drain money and slow growth!")
	end,
	
	revertEffects = function()
		inversionActive = false
		print("✅ SprinklerSystem: Effects restored to normal")
	end
}

print("💧 Sprinkler System Loaded!")
print("   - 5 Sprinkler types with growth/size bonuses")
print("   - Range-based effects")
print("   - Data-only system (no physical parts)")
print("   - Plot-specific bonus calculation")

-- DEPRECATED: Sprinkler/farming logic removed for city/empire game.
return
