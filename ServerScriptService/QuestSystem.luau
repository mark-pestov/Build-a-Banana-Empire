-- QuestSystem.lua - Daily Quests and Battle Pass System
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Data stores
local questDataStore = DataStoreService:GetDataStore("PlayerQuests")
local battlePassDataStore = DataStoreService:GetDataStore("PlayerBattlePass")

-- Player quest data
local playerQuests = {} -- {userId: {dailyQuests: {}, battlePass: {}}}

-- Quest types and configurations
local DAILY_QUEST_TYPES = {
	{
		id = "harvest_bananas",
		name = "Harvest Master",
		description = "Harvest {target} bananas",
		targetMin = 10,
		targetMax = 50,
		reward = {coins = 500, xp = 100}
	},
	{
		id = "plant_seeds",
		name = "Green Thumb",
		description = "Plant {target} seeds",
		targetMin = 3,
		targetMax = 10,
		reward = {coins = 300, xp = 75}
	},
	{
		id = "sell_to_vendor",
		name = "Business Savvy",
		description = "Sell {target} times to vendor",
		targetMin = 5,
		targetMax = 15,
		reward = {coins = 800, xp = 150}
	},
	{
		id = "use_truck",
		name = "Delivery Driver",
		description = "Complete {target} truck deliveries",
		targetMin = 2,
		targetMax = 8,
		reward = {coins = 1000, xp = 200}
	},
	{
		id = "clear_pests",
		name = "Pest Controller",
		description = "Clear {target} pest infestations",
		targetMin = 1,
		targetMax = 5,
		reward = {coins = 600, xp = 120}
	}
}

-- Battle Pass tiers (Season 1: Banana Empire)
local BATTLE_PASS_TIERS = {
	{tier = 1, xpRequired = 0, freeReward = {coins = 100}, premiumReward = {coins = 200, seeds = 5}},
	{tier = 2, xpRequired = 100, freeReward = {coins = 150}, premiumReward = {coins = 300, sprinkler = "Bad"}},
	{tier = 3, xpRequired = 250, freeReward = {coins = 200}, premiumReward = {coins = 500, worker_upgrade = "Rookie Ripper"}},
	{tier = 4, xpRequired = 450, freeReward = {seeds = 3}, premiumReward = {coins = 750, insurance = "1_hour"}},
	{tier = 5, xpRequired = 700, freeReward = {coins = 300}, premiumReward = {coins = 1000, sprinkler = "Medium"}},
	{tier = 6, xpRequired = 1000, freeReward = {coins = 400}, premiumReward = {coins = 1500, worker_upgrade = "Speedy Sprout"}},
	{tier = 7, xpRequired = 1350, freeReward = {coins = 500}, premiumReward = {coins = 2000, special_skin = "Golden Banana"}},
	{tier = 8, xpRequired = 1750, freeReward = {seeds = 5}, premiumReward = {coins = 2500, sprinkler = "Advanced"}},
	{tier = 9, xpRequired = 2200, freeReward = {coins = 600}, premiumReward = {coins = 3000, rebirth_boost = "25%"}},
	{tier = 10, xpRequired = 2700, freeReward = {coins = 1000}, premiumReward = {coins = 5000, exclusive_title = "Banana Emperor"}}
}

-- Wait for manually created RemoteEvents
-- Note: Create these RemoteEvents manually in ReplicatedStorage/RemoteEvents/:
-- - GetQuestData (RemoteFunction)
-- - ClaimQuestReward (RemoteEvent)
-- - ClaimBattlePassReward (RemoteEvent)
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local getQuestDataRemote = remoteEventsFolder:WaitForChild("GetQuestData")
local claimQuestRewardRemote = remoteEventsFolder:WaitForChild("ClaimQuestReward")
local claimBattlePassRewardRemote = remoteEventsFolder:WaitForChild("ClaimBattlePassReward")

-- Initialize player quest data
local function initPlayerQuestData(player)
	local success, savedQuests = pcall(function()
		return questDataStore:GetAsync(player.UserId)
	end)

	local success2, savedBattlePass = pcall(function()
		return battlePassDataStore:GetAsync(player.UserId)
	end)

	local questData = {
		dailyQuests = {},
		lastQuestReset = 0,
		battlePass = {
			xp = 0,
			tier = 1,
			hasPremium = false,
			claimedRewards = {}
		}
	}

	if success and savedQuests then
		questData.dailyQuests = savedQuests.dailyQuests or {}
		questData.lastQuestReset = savedQuests.lastQuestReset or 0
	end

	if success2 and savedBattlePass then
		questData.battlePass = savedBattlePass
	end

	playerQuests[player.UserId] = questData

	-- Generate new daily quests if needed
	generateDailyQuests(player)

	print("📋 Initialized quest data for", player.Name)
end

-- Save player quest data
local function savePlayerQuestData(player)
	local questData = playerQuests[player.UserId]
	if not questData then return end

	pcall(function()
		questDataStore:SetAsync(player.UserId, {
			dailyQuests = questData.dailyQuests,
			lastQuestReset = questData.lastQuestReset
		})
	end)

	pcall(function()
		battlePassDataStore:SetAsync(player.UserId, questData.battlePass)
	end)
end

-- Generate daily quests
local function generateDailyQuests(player)
	local questData = playerQuests[player.UserId]
	if not questData then return end

	local currentDay = math.floor(os.time() / 86400) -- Days since epoch
	local lastResetDay = math.floor(questData.lastQuestReset / 86400)

	-- Generate new quests if it's a new day
	if currentDay > lastResetDay then
		questData.dailyQuests = {}
		questData.lastQuestReset = os.time()

		-- Generate 3 random daily quests
		local availableQuests = {}
		for i, questType in ipairs(DAILY_QUEST_TYPES) do
			table.insert(availableQuests, i)
		end

		for i = 1, 3 do
			if #availableQuests == 0 then break end

			local randomIndex = math.random(#availableQuests)
			local questTypeIndex = availableQuests[randomIndex]
			table.remove(availableQuests, randomIndex)

			local questType = DAILY_QUEST_TYPES[questTypeIndex]
			local target = math.random(questType.targetMin, questType.targetMax)

			local quest = {
				id = questType.id .. "_" .. i,
				type = questType.id,
				name = questType.name,
				description = questType.description:gsub("{target}", tostring(target)),
				target = target,
				progress = 0,
				completed = false,
				claimed = false,
				reward = questType.reward
			}

			questData.dailyQuests[quest.id] = quest
		end

		if _G.showNotification then
			_G.showNotification(player, "📋 New daily quests available!", "info")
		end

		print("📋 Generated new daily quests for", player.Name)
	end
end

-- Update quest progress
local function updateQuestProgress(player, questType, amount)
	local questData = playerQuests[player.UserId]
	if not questData then return end

	amount = amount or 1

	for questId, quest in pairs(questData.dailyQuests) do
		if quest.type == questType and not quest.completed then
			quest.progress = quest.progress + amount

			if quest.progress >= quest.target then
				quest.progress = quest.target
				quest.completed = true

				-- Check if quest is complete
				local function checkQuestCompletion(player, questId)
					local questData = playerQuests[player.UserId]
					if not questData then return false end

					local quest = questData.dailyQuests[questId]
					if not quest or quest.completed then return false end

					-- Check if progress meets target
					if quest.progress >= quest.target then
						quest.completed = true
						quest.completedTime = os.time()

						-- Award Battle Pass XP for quest completion
						if _G.BattlePassSystem and _G.BattlePassSystem.onQuestComplete then
							_G.BattlePassSystem.onQuestComplete(player)
						end

						-- Fire QuestCompleted event for other systems
						local questCompletedRemote = ReplicatedStorage:FindFirstChild("RemoteEvents")
						if questCompletedRemote then
							questCompletedRemote = questCompletedRemote:FindFirstChild("QuestCompleted")
							if questCompletedRemote then
								questCompletedRemote:FireServer(player, questId)
							end
						end

						if _G.showNotification then
							_G.showNotification(player, "✅ Quest completed: " .. quest.name, "success")
						end

						savePlayerQuestData(player)
						return true
					end

					return false
				end

				checkQuestCompletion(player, questId)
			end
		end
	end

	savePlayerQuestData(player)
end

-- Add XP to battle pass
local function addBattlePassXP(player, amount)
	local questData = playerQuests[player.UserId]
	if not questData then return end

	questData.battlePass.xp = questData.battlePass.xp + amount

	-- Check for tier ups
	local currentTier = questData.battlePass.tier
	for _, tierInfo in ipairs(BATTLE_PASS_TIERS) do
		if questData.battlePass.xp >= tierInfo.xpRequired and tierInfo.tier > currentTier then
			questData.battlePass.tier = tierInfo.tier

			if _G.showNotification then
				_G.showNotification(player, "🌟 Battle Pass Tier " .. tierInfo.tier .. " unlocked!", "success")
			end
		end
	end

	savePlayerQuestData(player)
end

-- Claim quest reward
local function claimQuestReward(player, questId)
	local questData = playerQuests[player.UserId]
	if not questData then return false end

	local quest = questData.dailyQuests[questId]
	if not quest or not quest.completed or quest.claimed then return false end

	quest.claimed = true

	-- Give rewards
	if quest.reward.coins and _G.CoinSystem then
		_G.CoinSystem.addCoins(player, quest.reward.coins)
	end

	if quest.reward.xp then
		addBattlePassXP(player, quest.reward.xp)
	end

	if _G.showNotification then
		_G.showNotification(player, "🎁 Quest reward claimed!", "success")
		if quest.reward.coins then
			_G.showNotification(player, "+" .. quest.reward.coins .. " coins", "info")
		end
		if quest.reward.xp then
			_G.showNotification(player, "+" .. quest.reward.xp .. " XP", "info")
		end
	end

	savePlayerQuestData(player)
	return true
end

-- Claim battle pass reward
local function claimBattlePassReward(player, tier, isPremium)
	local questData = playerQuests[player.UserId]
	if not questData then return false end

	local tierInfo = BATTLE_PASS_TIERS[tier]
	if not tierInfo or questData.battlePass.tier < tier then return false end

	local rewardKey = tier .. "_" .. (isPremium and "premium" or "free")
	if questData.battlePass.claimedRewards[rewardKey] then return false end

	if isPremium and not questData.battlePass.hasPremium then return false end

	local reward = isPremium and tierInfo.premiumReward or tierInfo.freeReward
	questData.battlePass.claimedRewards[rewardKey] = true

	-- Give rewards
	if reward.coins and _G.CoinSystem then
		_G.CoinSystem.addCoins(player, reward.coins)
	end

	if reward.seeds and _G.SeedSystem then
		_G.SeedSystem.addSeeds(player, "banappleTreeSeed", reward.seeds)
	end

	if reward.sprinkler then
		-- Could integrate with sprinkler system to give free sprinkler
		if _G.showNotification then
			_G.showNotification(player, "🎁 " .. reward.sprinkler .. " Sprinkler unlocked!", "info")
		end
	end

	if reward.worker_upgrade then
		if _G.showNotification then
			_G.showNotification(player, "🎁 " .. reward.worker_upgrade .. " upgrade unlocked!", "info")
		end
	end

	if _G.showNotification then
		_G.showNotification(player, "🎁 Battle Pass reward claimed!", "success")
	end

	savePlayerQuestData(player)
	return true
end

-- Remote event handlers
getQuestDataRemote.OnServerInvoke = function(player)
	local questData = playerQuests[player.UserId]
	if not questData then return {} end

	return {
		dailyQuests = questData.dailyQuests,
		battlePass = questData.battlePass,
		battlePassTiers = BATTLE_PASS_TIERS
	}
end

claimQuestRewardRemote.OnServerEvent:Connect(function(player, questId)
	claimQuestReward(player, questId)
end)

claimBattlePassRewardRemote.OnServerEvent:Connect(function(player, tier, isPremium)
	claimBattlePassReward(player, tier, isPremium)
end)

-- Player events
Players.PlayerAdded:Connect(initPlayerQuestData)
Players.PlayerRemoving:Connect(savePlayerQuestData)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
	initPlayerQuestData(player)
end

-- Connect to other systems for quest tracking
if _G.HarvestSystem then
	-- Hook into harvest events
	-- This would need to be implemented in HarvestFruitServer.lua
end

-- Auto-save every 5 minutes
task.spawn(function()
	while true do
		task.wait(300)
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayerQuestData(player)
		end
	end
end)

-- Global functions for other scripts
_G.QuestSystem = {
	updateProgress = updateQuestProgress,
	addXP = addBattlePassXP,

	-- Quest tracking functions for other systems
	onBananaHarvested = function(player)
		updateQuestProgress(player, "harvest_bananas", 1)
	end,

	onSeedPlanted = function(player)
		updateQuestProgress(player, "plant_seeds", 1)
	end,

	onVendorSale = function(player)
		updateQuestProgress(player, "sell_to_vendor", 1)
	end,

	onTruckDelivery = function(player)
		updateQuestProgress(player, "use_truck", 1)
	end,

	onPestCleared = function(player)
		updateQuestProgress(player, "clear_pests", 1)
	end
}

print("📋 Quest System Loaded!")
print("   - Daily quest generation")
print("   - Battle pass progression")
print("   - Quest tracking integration")
print("   - Reward distribution system")
