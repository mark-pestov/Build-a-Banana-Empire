-- BananaKingBossEvent.lua
-- Server-side Banana King Boss Battle event system
-- Cooperative boss fight with all players working together

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BananaKingBossEvent = {}

-- Configuration
local Config = {
	EventDuration = 600, -- 10 minutes
	BossHealth = 10000,
	BossPosition = Vector3.new(0, 10, 0), -- Center of map, elevated

	-- Boss phases
	Phases = {
		{threshold = 1.0, name = "Arrival", abilities = {"summon_minions"}},
		{threshold = 0.75, name = "Angry", abilities = {"banana_storm", "summon_minions"}},
		{threshold = 0.5, name = "Furious", abilities = {"banana_storm", "ground_pound", "summon_minions"}},
		{threshold = 0.25, name = "Desperate", abilities = {"mega_banana_storm", "ground_pound", "healing"}},
		{threshold = 0.0, name = "Defeated", abilities = {}}
	},

	-- Rewards for defeating boss
	DefeatRewards = {
		coinsPerPlayer = 10000,
		royalSeeds = 3, -- Number of Royal Seeds to drop
		specialRewards = {"Banana Crown", "Golden Banana Staff", "Royal Banana Cape"}
	},

	-- Boss abilities
	AbilityCooldowns = {
		summon_minions = 30,
		banana_storm = 45,
		ground_pound = 20,
		mega_banana_storm = 60,
		healing = 90
	}
}

-- Active event tracking
local activeEvent = {
	isActive = false,
	startTime = 0,
	bossData = nil,
	participants = {}, -- Players who dealt damage
	lastAbilityTimes = {}, -- Track ability cooldowns
	currentPhase = 1,
	minions = {} -- Boss minions
}

-- Initialize event system
function BananaKingBossEvent.Initialize()
	print("Banana King Boss Event System initialized")
end

-- Start the Banana King boss battle
function BananaKingBossEvent.StartEvent()
	if activeEvent.isActive then return false end

	activeEvent.isActive = true
	activeEvent.startTime = tick()
	activeEvent.participants = {}
	activeEvent.lastAbilityTimes = {}
	activeEvent.currentPhase = 1
	activeEvent.minions = {}

	-- Spawn the Banana King boss
	BananaKingBossEvent.SpawnBananaKing()

	print("👑 BANANA KING BOSS BATTLE STARTED!")

	-- Notify all players
	BananaKingBossEvent.NotifyPlayers("👑 THE BANANA KING HAS APPEARED! All players must work together to defeat this mighty foe! Coordinate your attacks!")

	-- Set event timer
	task.spawn(function()
		task.wait(Config.EventDuration)
		if activeEvent.isActive then
			BananaKingBossEvent.EndEvent("timeout")
		end
	end)

	-- Start boss AI
	BananaKingBossEvent.StartBossAI()

	-- Integrate with random events system
	if _G.RandomEventsSystem then
		_G.RandomEventsSystem.SetCurrentEvent({
			name = "The Banana King Appears",
			description = "Epic boss battle! All players cooperate to defeat the Banana King!",
			beneficial = false,
			duration = Config.EventDuration
		})
	end

	return true
end

-- Spawn the Banana King boss (data-only)
function BananaKingBossEvent.SpawnBananaKing()
	activeEvent.bossData = {
		health = Config.BossHealth,
		maxHealth = Config.BossHealth,
		position = Config.BossPosition,
		state = "fighting", -- fighting, defeated
		lastMoveTime = tick(),
		abilities = Config.Phases[1].abilities
	}

	print("👑 Banana King spawned at", Config.BossPosition, "with", Config.BossHealth, "health")
end

-- Start boss AI behavior
function BananaKingBossEvent.StartBossAI()
	task.spawn(function()
		while activeEvent.isActive and activeEvent.bossData and activeEvent.bossData.health > 0 do
			BananaKingBossEvent.UpdateBossAI()
			task.wait(1) -- Update every second
		end
	end)
end

-- Update boss AI and abilities
function BananaKingBossEvent.UpdateBossAI()
	local boss = activeEvent.bossData
	if not boss or boss.health <= 0 then return end

	local currentTime = tick()

	-- Check for phase transitions
	BananaKingBossEvent.CheckPhaseTransition()

	-- Use abilities based on current phase
	for _, ability in ipairs(boss.abilities) do
		local lastUsed = activeEvent.lastAbilityTimes[ability] or 0
		local cooldown = Config.AbilityCooldowns[ability] or 30

		if currentTime - lastUsed >= cooldown then
			if BananaKingBossEvent.UseAbility(ability) then
				activeEvent.lastAbilityTimes[ability] = currentTime
				break -- Only use one ability per update
			end
		end
	end
end

-- Check if boss should transition to next phase
function BananaKingBossEvent.CheckPhaseTransition()
	local boss = activeEvent.bossData
	local healthPercent = boss.health / boss.maxHealth

	for i = activeEvent.currentPhase + 1, #Config.Phases do
		local phase = Config.Phases[i]
		if healthPercent <= phase.threshold then
			activeEvent.currentPhase = i
			boss.abilities = phase.abilities

			BananaKingBossEvent.NotifyPlayers("👑 The Banana King enters " .. phase.name .. " phase! Health: " .. math.floor(healthPercent * 100) .. "%")
			print("👑 Boss phase transition to:", phase.name)
			break
		end
	end
end

-- Use boss ability
function BananaKingBossEvent.UseAbility(ability)
	local boss = activeEvent.bossData
	if not boss then return false end

	if ability == "summon_minions" then
		return BananaKingBossEvent.SummonMinions()
	elseif ability == "banana_storm" then
		return BananaKingBossEvent.BananaStorm()
	elseif ability == "ground_pound" then
		return BananaKingBossEvent.GroundPound()
	elseif ability == "mega_banana_storm" then
		return BananaKingBossEvent.MegaBananaStorm()
	elseif ability == "healing" then
		return BananaKingBossEvent.BossHealing()
	end

	return false
end

-- Summon minions ability
function BananaKingBossEvent.SummonMinions()
	local minionCount = math.random(3, 6)

	for i = 1, minionCount do
		local angle = (i / minionCount) * 2 * math.pi
		local distance = 15
		local minionPos = activeEvent.bossData.position + Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		)

		local minion = {
			id = "minion_" .. i .. "_" .. tick(),
			health = 500,
			maxHealth = 500,
			position = minionPos,
			spawnTime = tick()
		}

		table.insert(activeEvent.minions, minion)
	end

	BananaKingBossEvent.NotifyPlayers("👑 The Banana King summons " .. minionCount .. " Banana Minions! Defeat them quickly!")
	print("👑 Boss summoned", minionCount, "minions")

	return true
end

-- Banana storm ability
function BananaKingBossEvent.BananaStorm()
	BananaKingBossEvent.NotifyPlayers("👑 The Banana King unleashes a BANANA STORM! Take cover!")

	-- Apply area damage to all players
	for _, player in pairs(Players:GetPlayers()) do
		BananaKingBossEvent.DamagePlayer(player, 200, "Banana Storm")
	end

	print("👑 Boss used Banana Storm")
	return true
end

-- Ground pound ability
function BananaKingBossEvent.GroundPound()
	BananaKingBossEvent.NotifyPlayers("👑 The Banana King performs a devastating GROUND POUND!")

	-- Apply heavy damage to players near the boss
	local bossPos = activeEvent.bossData.position
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (player.Character.HumanoidRootPart.Position - bossPos).Magnitude
			if distance < 30 then -- Within ground pound range
				local damage = math.max(100, 500 - distance * 10) -- Closer = more damage
				BananaKingBossEvent.DamagePlayer(player, damage, "Ground Pound")
			end
		end
	end

	print("👑 Boss used Ground Pound")
	return true
end

-- Mega banana storm ability
function BananaKingBossEvent.MegaBananaStorm()
	BananaKingBossEvent.NotifyPlayers("👑 The Banana King unleashes a MEGA BANANA STORM! Massive area damage incoming!")

	-- Apply heavy area damage
	for _, player in pairs(Players:GetPlayers()) do
		BananaKingBossEvent.DamagePlayer(player, 400, "Mega Banana Storm")
	end

	print("👑 Boss used Mega Banana Storm")
	return true
end

-- Boss healing ability
function BananaKingBossEvent.BossHealing()
	local healAmount = math.min(1000, activeEvent.bossData.maxHealth - activeEvent.bossData.health)
	activeEvent.bossData.health = activeEvent.bossData.health + healAmount

	BananaKingBossEvent.NotifyPlayers("👑 The Banana King heals for " .. healAmount .. " health! Current health: " .. activeEvent.bossData.health)

	print("👑 Boss healed for", healAmount)
	return true
end

-- Apply damage to player (placeholder - integrate with your health system)
function BananaKingBossEvent.DamagePlayer(player, damage, source)
	-- This would integrate with your player health/damage system
	print(player.Name .. " takes " .. damage .. " damage from " .. source)

	BananaKingBossEvent.NotifyPlayer(player, "💥 You take " .. damage .. " damage from " .. source .. "!")
end

-- Handle player attacking boss
function BananaKingBossEvent.AttackBoss(player, damage)
	if not activeEvent.isActive or not activeEvent.bossData then return false end

	local boss = activeEvent.bossData
	if boss.health <= 0 then return false end

	-- Apply damage
	boss.health = math.max(0, boss.health - damage)

	-- Track participant
	if not activeEvent.participants[player.UserId] then
		activeEvent.participants[player.UserId] = {
			player = player,
			damageDealt = 0,
			firstAttackTime = tick()
		}
	end
	activeEvent.participants[player.UserId].damageDealt = activeEvent.participants[player.UserId].damageDealt + damage

	print(player.Name .. " dealt " .. damage .. " damage to Banana King! Health: " .. boss.health .. "/" .. boss.maxHealth)

	-- Check if boss is defeated
	if boss.health <= 0 then
		BananaKingBossEvent.BossDefeated()
		return true
	end

	-- Notify all players of damage
	local healthPercent = math.floor((boss.health / boss.maxHealth) * 100)
	BananaKingBossEvent.NotifyPlayers("⚔️ " .. player.Name .. " dealt " .. damage .. " damage! Boss health: " .. healthPercent .. "%")

	return true
end

-- Handle player attacking minion
function BananaKingBossEvent.AttackMinion(player, minionId, damage)
	for i, minion in ipairs(activeEvent.minions) do
		if minion.id == minionId then
			minion.health = math.max(0, minion.health - damage)

			if minion.health <= 0 then
				table.remove(activeEvent.minions, i)
				BananaKingBossEvent.NotifyPlayers("💥 " .. player.Name .. " defeated a Banana Minion!")

				-- Give small reward for defeating minion
				if _G.CoinSystem and _G.CoinSystem.AddCoins then
					_G.CoinSystem.AddCoins(player, 500)
				end
			end

			return true
		end
	end

	return false
end

-- Handle boss being defeated
function BananaKingBossEvent.BossDefeated()
	activeEvent.bossData.state = "defeated"

	BananaKingBossEvent.NotifyPlayers("👑 THE BANANA KING HAS BEEN DEFEATED! Victory for all participants!")

	-- Give rewards to all participants
	BananaKingBossEvent.DistributeVictoryRewards()

	-- End event
	BananaKingBossEvent.EndEvent("defeated")
end

-- Distribute rewards to all participants
function BananaKingBossEvent.DistributeVictoryRewards()
	local participantCount = 0
	for _ in pairs(activeEvent.participants) do
		participantCount = participantCount + 1
	end

	if participantCount == 0 then return end

	-- Give rewards to all participants
	for userId, participant in pairs(activeEvent.participants) do
		local player = participant.player

		if player and player.Parent then -- Player still in game
			-- Give coins
			if _G.CoinSystem and _G.CoinSystem.AddCoins then
				_G.CoinSystem.AddCoins(player, Config.DefeatRewards.coinsPerPlayer)
			end

			-- Give Royal Seeds
			BananaKingBossEvent.GiveRoyalSeeds(player)

			-- Give special cosmetic reward
			local specialReward = Config.DefeatRewards.specialRewards[math.random(1, #Config.DefeatRewards.specialRewards)]
			BananaKingBossEvent.NotifyPlayer(player, "👑 You received: " .. Config.DefeatRewards.coinsPerPlayer .. " coins, " .. Config.DefeatRewards.royalSeeds .. " Royal Seeds, and " .. specialReward .. "!")

			print(player.Name .. " received victory rewards")
		end
	end
end

-- Give Royal Seeds to player
function BananaKingBossEvent.GiveRoyalSeeds(player)
	-- Integrate with your seed/inventory system
	for i = 1, Config.DefeatRewards.royalSeeds do
		-- Add Royal Seed to player inventory
		print(player.Name .. " received Royal Seed " .. i)
	end

	BananaKingBossEvent.NotifyPlayer(player, "🌱 You received " .. Config.DefeatRewards.royalSeeds .. " Royal Seeds!")
end

-- End the Banana King boss event
function BananaKingBossEvent.EndEvent(reason)
	if not activeEvent.isActive then return end

	activeEvent.isActive = false

	local message = ""
	if reason == "defeated" then
		message = "👑 Banana King Boss Battle ended! The mighty foe has been vanquished!"
	elseif reason == "timeout" then
		message = "👑 Banana King Boss Battle ended! Time ran out - the Banana King retreats!"
	end

	BananaKingBossEvent.NotifyPlayers(message)

	-- Clean up
	activeEvent.bossData = nil
	activeEvent.participants = {}
	activeEvent.minions = {}
	activeEvent.lastAbilityTimes = {}

	print("👑 Banana King Boss event ended: " .. reason)

	-- Clear from random events system
	if _G.RandomEventsSystem then
		_G.RandomEventsSystem.ClearCurrentEvent()
	end
end

-- Get boss position for client systems
function BananaKingBossEvent.GetBossPosition()
	if activeEvent.bossData then
		return activeEvent.bossData.position
	end
	return nil
end

-- Get event status for UI systems
function BananaKingBossEvent.GetEventStatus()
	local boss = activeEvent.bossData
	local participantCount = 0
	for _ in pairs(activeEvent.participants) do
		participantCount = participantCount + 1
	end

	return {
		isActive = activeEvent.isActive,
		timeRemaining = activeEvent.isActive and math.max(0, Config.EventDuration - (tick() - activeEvent.startTime)) or 0,
		bossHealth = boss and boss.health or 0,
		bossMaxHealth = boss and boss.maxHealth or 0,
		currentPhase = Config.Phases[activeEvent.currentPhase] and Config.Phases[activeEvent.currentPhase].name or "Unknown",
		participantCount = participantCount,
		minionCount = #activeEvent.minions
	}
end

-- Notify all players
function BananaKingBossEvent.NotifyPlayers(message)
	for _, player in pairs(Players:GetPlayers()) do
		BananaKingBossEvent.NotifyPlayer(player, message)
	end
end

-- Notify single player
function BananaKingBossEvent.NotifyPlayer(player, message)
	-- Use notification system if available
	if _G.NotificationSystem and _G.NotificationSystem.SendNotification then
		_G.NotificationSystem.SendNotification(player, "Banana King", message, 8)
	else
		-- Fallback to print/chat
		print("[BANANA KING] " .. player.Name .. ": " .. message)
	end
end

-- Initialize the system
BananaKingBossEvent.Initialize()

-- Global access
_G.BananaKingBossEvent = BananaKingBossEvent

return BananaKingBossEvent