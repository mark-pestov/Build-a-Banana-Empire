-- RandomEventsSystem.lua - Random Banana Events (NO PHYSICAL PARTS)
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")

-- Owner Configuration
local OWNER_USER_ID = 3389224707

-- Event Configuration
local EVENT_INTERVAL_MIN = 20 * 60 -- 20 minutes minimum
local EVENT_INTERVAL_MAX = 30 * 60 -- 30 minutes maximum
local EVENT_DURATION = 5 * 60 -- 5 minutes duration for most events

-- Event Types
local EVENTS = {
	["banana_storm"] = {
		name = "🌪️ Banana Storm",
		description = "Banana chunks fall from the sky. Collect for x2 cash per banana for 5 minutes. Ignored = rots and causes -10% growth speed for 3 minutes.",
		duration = 3 * 60, -- 3 minutes
		effects = {
			bananaChunks = true,
			bananaCashMultiplier = 5.0,
			rotPenalty = {growthSpeed = 0.9, duration = 3 * 60}
		},
		rarity = 0.10, -- Beneficial, but not the rarest
		beneficial = true
	},
	["banana_plague"] = {
		name = "☠️ Banana Plague",
		description = "A mysterious disease slows all banana growth!",
		duration = EVENT_DURATION,
		effects = {
			growthSpeedMultiplier = 0.5, -- 50% slower growth
			bananaValueMultiplier = 0.8 -- 20% less value when sold
		},
		rarity = 0.18, -- Negative, more common
		beneficial = false
	},
	["golden_monkey_raid"] = {
		name = "🐒⚔️ Golden Monkey Raid",
		description = "Elite golden monkeys invade! FIGHT for treasure chests!",
		duration = 5 * 60, -- 5 minutes of intense action
		effects = {
			spawnGoldenMonkeys = true, -- Spawn clickable golden monkeys
			maxReward = 50000, -- Top performers get massive rewards
			participationRequired = true, -- Must actively participate
			limitedChests = 3, -- Only 3 treasure chests spawn
			competitiveMode = true -- Players compete for rewards
		},
		rarity = 0.06, -- High reward, rare
		beneficial = true -- But only for those who EARN it
	},
	["banana_rush"] = {
		name = "🏃 Banana Rush Hour",
		description = "Workers are energized and work faster!",
		duration = EVENT_DURATION,
		effects = {
			workerSpeedMultiplier = 2.0, -- 2x worker income
			sellingPriceMultiplier = 1.5 -- 50% better selling prices
		},
		rarity = 0.13, -- Good, but not the best
		beneficial = true
	},
	["pest_invasion"] = {
		name = "🐛 Pest Invasion",
		description = "Aggressive pests attack all farms!",
		duration = EVENT_DURATION,
		effects = {
			pestSpawnRate = 5.0, -- 5x more pest spawns
			pestSpreadRate = 3.0 -- 3x faster spreading
		},
		rarity = 0.16, -- Negative, more common
		beneficial = false
	},
	["nuclear_meltdown"] = {
		name = "☢️ Nuclear Banana Meltdown",
		description = "Radioactive chuncks fly and when they hit a banana, it becomes radioactive spawn! Sold for 10x cash but it gives growth penalties!",
		duration = 2 * 60, -- 2 minutes
		effects = {
			radioactiveBananas = true,
			cashMultiplier = 10.0,
			growthSpeedMultiplier = 0.3, -- 70% slower growth during event
			radiationSickness = true
		},
		rarity = 0.04, -- High risk/high reward, rare
		beneficial = false -- High reward but with penalties
	},
	["banana_thief"] = {
		name = "🥷 Banana Thief Alert",
		description = "A sneaky thief is targeting random plots! Defeat for rare seeds!",
		duration = 3 * 60, -- 3 minutes
		effects = {
			thiefSpawn = true,
			plotTargeting = true,
			rareSeeds = true,
			stealthMode = true
		},
		rarity = 0.09, -- Good reward, but not the rarest
		beneficial = true -- Good rewards if you defeat the thief
	},
	["pvp_heist"] = {
		name = "🏴‍☠️ PvP Banana Heist",
		description = "Players become robbers or innocents! Use tools to survive!",
		duration = 5 * 60, -- 5 minutes
		effects = {
			pvpMode = true,
			playerRoles = true,
			specialTools = true,
			mapDarkening = true,
			heistRewards = true
		},
		rarity = 0.03, -- Very rare, high impact
		beneficial = true -- Depends on your role and performance
	},
	["banana_king_boss"] = {
		name = "👑 Banana King Boss Battle",
		description = "The legendary Banana King appears! Team up to defeat him!",
		duration = 10 * 60, -- 10 minutes
		effects = {
			bossSpawn = true,
			cooperativeMode = true,
			bossPhases = 3,
			royalSeeds = true,
			massiveRewards = true
		},
		rarity = 0.01, -- Ultra rare, always 1%
		beneficial = true -- Huge rewards for successful cooperation
	},
	["overflowing_growth"] = {
		name = "🌱 Overflowing Growth",
		description = "All bananas instantly grow for 60 seconds. Harvest = huge profit. Ignored = bananas overgrow, causing the banana to explode (disappearing).",
		duration = 60, -- 1 minute
		effects = {
			instantGrowth = true,
			overgrowPenalty = {growthEfficiency = 0.8, duration = 2 * 60}
		},
		rarity = 0.07, -- Good, but not the best
		beneficial = true
	},
	["lightning_harvest"] = {
		name = "⚡ Lightning Harvest",
		description = "Bananas turn into Electro Bananas worth x10. Must be collected within 80 seconds. Ignored = electro-burns and becomes worthless.",
		duration = 80,
		effects = {
			electroBananas = true,
			electroValueMultiplier = 10.0,
			burnPenalty = true
		},
		rarity = 0.05, -- Very beneficial, rare
		beneficial = true
	},
	["banana_bloom_burst"] = {
		name = "🌸 Banana Bloom Burst",
		description = "Banana flowers appear around plots. Click them to get: a random seed below Legendary (Standard → Solid), or a 2x growth speed buff for a short duration. Ignored = overgrowth clogs sprinklers (2-minute delay).",
		duration = 90,
		effects = {
			bananaFlowers = true,
			randomSeedReward = true,
			growthBuff = {multiplier = 2.0, duration = 30},
			sprinklerClogPenalty = {duration = 2 * 60}
		},
		rarity = 0.06, -- Good, but not the best
		beneficial = true
	},
	["festival_rain"] = {
		name = "🌈 Festival Rain",
		description = "A vibrant, sparkly rain boosts banana worker's efficiency by 50% for 2 minutes. Players without workers get +10% coin bonus, and their is a good chance their bananas become waterlogged (sold for x8 coins).",
		duration = 2 * 60,
		effects = {
			growthSpeedMultiplier = 1.5,
			goldenBananaRain = true
		},
		rarity = 0.03, -- Very beneficial, rare
		beneficial = true
	},
	["banana_eclipse"] = {
		name = "🌑 Banana Eclipse",
		description = "Sky darkens, bananas become temporarily shadow-charged, gaining +x3 value. Only visible for 90 seconds. Ignored = event ends silently; no penalty, just lost opportunity.",
		duration = 90,
		effects = {
			shadowBananas = true,
			shadowValueMultiplier = 3.0
		},
		rarity = 0.02, -- Extremely beneficial, very rare
		beneficial = true
	},
	["super_monkey_storm"] = {
		name = "🦍 Super Monkey Storm",
		description = "Powerful monkeys fly overhead dropping bonus bananas. Players with workers receive auto-collected bananas at high value. Players without workers get manual bananas that must be picked up. Ignored = no penalty, just missed loot.",
		duration = 75,
		effects = {
			monkeyBananaDrop = true,
			autoCollectForWorkers = true
		},
		rarity = 0.01, -- Extremely beneficial, ultra rare
		beneficial = true
	}
}

-- Current active event
local activeEvent = {
	type = nil,
	startTime = 0,
	endTime = 0,
	participants = {} -- Players who were online during the event
}

-- Event history for statistics
local eventHistory = {}

-- Check if an event is currently active
local function isEventActive()
	return activeEvent.type ~= nil and tick() < activeEvent.endTime
end

-- Get current event effects
local function getCurrentEventEffects()
	if not isEventActive() then
		return {}
	end

	local eventConfig = EVENTS[activeEvent.type]
	return eventConfig and eventConfig.effects or {}
end

-- Start a random event
local function startRandomEvent()
	if isEventActive() then
		return false, "Event already active"
	end

	-- Select random event based on rarity
	local totalWeight = 0
	for _, eventConfig in pairs(EVENTS) do
		totalWeight = totalWeight + eventConfig.rarity
	end

	local random = math.random() * totalWeight
	local currentWeight = 0
	local selectedEvent = nil

	for eventType, eventConfig in pairs(EVENTS) do
		currentWeight = currentWeight + eventConfig.rarity
		if random <= currentWeight then
			selectedEvent = eventType
			break
		end
	end

	if not selectedEvent then
		return false, "No event selected"
	end

	local eventConfig = EVENTS[selectedEvent]

	-- Start the event
	activeEvent.type = selectedEvent
	activeEvent.startTime = tick()
	activeEvent.endTime = tick() + eventConfig.duration
	activeEvent.participants = {}

	-- Add all current players as participants
	for _, player in ipairs(Players:GetPlayers()) do
		activeEvent.participants[player.UserId] = {
			joinTime = tick(),
			rewardsClaimed = false
		}
	end

	-- Global notification
	for _, player in ipairs(Players:GetPlayers()) do
		if _G.NotificationSystem and _G.NotificationSystem.showNotification then
			local eventType = eventConfig.beneficial and "legendary" or "warning"
			_G.NotificationSystem.showNotification(player, 
				eventConfig.name .. " has begun! " .. eventConfig.description, 
				eventType)
		end
	end

	-- Apply immediate effects for certain events
	if selectedEvent == "golden_monkey_raid" then
		for _, player in ipairs(Players:GetPlayers()) do
			if _G.CoinSystem and _G.CoinSystem.addCoins then
				_G.CoinSystem.addCoins(player, eventConfig.effects.bonusCoins)
			end
		end

		activeEvent.raidData = {
			goldenMonkeysKilled = {},  -- Track kills per player
			treasureChestsFound = {},  -- Track chest finds per player
			participationScore = {},   -- Combat participation score
			chestsRemaining = eventConfig.effects.limitedChests,
			topPerformers = {}         -- Will be calculated at end
		}

		-- Initialize all players with zero scores
		for _, player in ipairs(Players:GetPlayers()) do
			activeEvent.raidData.goldenMonkeysKilled[player.UserId] = 0
			activeEvent.raidData.treasureChestsFound[player.UserId] = 0
			activeEvent.raidData.participationScore[player.UserId] = 0
		end

		-- Spawn competitive elements for the raid
		spawnGoldenMonkeyRaid()
	elseif selectedEvent == "nuclear_meltdown" then
		-- Start nuclear meltdown event
		if _G.NuclearMeltdownEvent and _G.NuclearMeltdownEvent.StartEvent then
			_G.NuclearMeltdownEvent.StartEvent()
		end
	elseif selectedEvent == "banana_thief" then
		-- Start banana thief event
		if _G.BananaThiefEvent and _G.BananaThiefEvent.StartEvent then
			_G.BananaThiefEvent.StartEvent()
		end
	elseif selectedEvent == "pvp_heist" then
		-- Start PvP heist event
		if _G.PvPBananaHeistEvent and _G.PvPBananaHeistEvent.StartEvent then
			_G.PvPBananaHeistEvent.StartEvent()
		end
	elseif selectedEvent == "banana_king_boss" then
		-- Start Banana King boss battle
		if _G.BananaKingBossEvent and _G.BananaKingBossEvent.StartEvent then
			_G.BananaKingBossEvent.StartEvent()
		end
	end

	-- Log event
	table.insert(eventHistory, {
		type = selectedEvent,
		startTime = activeEvent.startTime,
		duration = eventConfig.duration,
		playerCount = #Players:GetPlayers()
	})

	print("🎲 Random Event Started:", eventConfig.name)
	return true, "Event started: " .. eventConfig.name
end

-- End the current event
local function endCurrentEvent()
	if not isEventActive() then
		return false, "No active event"
	end

	local eventConfig = EVENTS[activeEvent.type]

	-- Special handling for different event types
	if activeEvent.type == "golden_monkey_raid" then
		distributeRaidRewards()
	elseif activeEvent.type == "nuclear_meltdown" then
		-- End nuclear meltdown event
		if _G.NuclearMeltdownEvent and _G.NuclearMeltdownEvent.EndEvent then
			_G.NuclearMeltdownEvent.EndEvent()
		end
	elseif activeEvent.type == "banana_thief" then
		-- End banana thief event
		if _G.BananaThiefEvent and _G.BananaThiefEvent.EndEvent then
			_G.BananaThiefEvent.EndEvent()
		end
	elseif activeEvent.type == "pvp_heist" then
		-- End PvP heist event
		if _G.PvPBananaHeistEvent and _G.PvPBananaHeistEvent.EndEvent then
			_G.PvPBananaHeistEvent.EndEvent()
		end
	elseif activeEvent.type == "banana_king_boss" then
		-- End Banana King boss battle
		if _G.BananaKingBossEvent and _G.BananaKingBossEvent.EndEvent then
			_G.BananaKingBossEvent.EndEvent()
		end
	else
		-- Standard participation rewards for other events
		for userId, participantData in pairs(activeEvent.participants) do
			local player = Players:GetPlayerByUserId(userId)
			if player and not participantData.rewardsClaimed then
				-- Give participation rewards
				local participationTime = math.min(tick() - participantData.joinTime, tick() - activeEvent.startTime)
				local participationBonus = math.floor(participationTime / 60) * 50 -- 50 coins per minute

				if participationBonus > 0 and _G.CoinSystem and _G.CoinSystem.addCoins then
					_G.CoinSystem.addCoins(player, participationBonus)

					if _G.NotificationSystem and _G.NotificationSystem.showNotification then
						_G.NotificationSystem.showNotification(player, 
							"🎁 Event participation reward: +" .. participationBonus .. " coins!", 
							"success")
					end
				end
			end
		end
	end

	-- Global notification
	for _, player in ipairs(Players:GetPlayers()) do
		if _G.NotificationSystem and _G.NotificationSystem.showNotification then
			_G.NotificationSystem.showNotification(player, 
				eventConfig.name .. " has ended!", 
				"info")
		end
	end

	print("🎲 Random Event Ended:", eventConfig.name)

	-- Clear active event
	activeEvent.type = nil
	activeEvent.startTime = 0
	activeEvent.endTime = 0
	activeEvent.participants = {}

	return true, "Event ended"
end

-- Get event status for a player
local function getEventStatus(player)
	local status = {
		isActive = isEventActive(),
		currentEvent = nil,
		timeRemaining = 0,
		effects = getCurrentEventEffects(),
		participating = false,
		eventHistory = {}
	}

	if isEventActive() then
		local eventConfig = EVENTS[activeEvent.type]
		status.currentEvent = {
			type = activeEvent.type,
			name = eventConfig.name,
			description = eventConfig.description,
			beneficial = eventConfig.beneficial
		}
		status.timeRemaining = activeEvent.endTime - tick()
		status.participating = activeEvent.participants[player.UserId] ~= nil
	end

	-- Recent event history (last 5 events)
	local recentHistory = {}
	for i = math.max(1, #eventHistory - 4), #eventHistory do
		local event = eventHistory[i]
		table.insert(recentHistory, {
			type = event.type,
			name = EVENTS[event.type] and EVENTS[event.type].name or "Unknown Event",
			startTime = event.startTime,
			playerCount = event.playerCount
		})
	end
	status.eventHistory = recentHistory

	return status
end

-- Apply event effects to game systems
local function applyEventEffects()
	if not isEventActive() then return end

	local effects = getCurrentEventEffects()

	-- This is where you would modify other systems based on event effects
	-- For example:
	-- - Modify worker income rates
	-- - Modify banana growth speeds
	-- - Modify selling prices
	-- - Trigger special pest behaviors

	-- Example integration points:
	if effects.workerSpeedMultiplier and _G.WorkerSystem then
		-- You could modify worker calculations here
	end

	if effects.sellingPriceMultiplier and _G.SellingSystem then
		-- You could modify selling prices here
	end

	if effects.pestSpawnRate and _G.PestSystem then
		-- You could increase pest spawn rates here
	end
end

-- Golden Monkey Raid competitive mechanics
local function spawnGoldenMonkeyRaid()
	if not activeEvent.raidData then return end

	local eventConfig = EVENTS["golden_monkey_raid"]

	-- Announce the high-stakes nature
	for _, player in ipairs(Players:GetPlayers()) do
		if _G.NotificationSystem and _G.NotificationSystem.showNotification then
			_G.NotificationSystem.showNotification(player, 
				"⚔️ RAID ALERT: Only " .. eventConfig.effects.limitedChests .. " treasure chests available! FIGHT FOR THEM!", 
				"warning")
		end
	end

	print("🐒⚔️ Golden Monkey Raid spawned - " .. eventConfig.effects.limitedChests .. " chests available")
end

-- Track raid participation (called when player kills golden monkey)
local function recordMonkeyKill(player)
	if not activeEvent.raidData then return false end

	local userId = player.UserId
	activeEvent.raidData.goldenMonkeysKilled[userId] = (activeEvent.raidData.goldenMonkeysKilled[userId] or 0) + 1
	activeEvent.raidData.participationScore[userId] = (activeEvent.raidData.participationScore[userId] or 0) + 100

	-- Notify other players of competition
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and _G.NotificationSystem then
			_G.NotificationSystem.showNotification(otherPlayer, 
				"⚔️ " .. player.Name .. " killed a golden monkey! Competition is fierce!", 
				"warning")
		end
	end

	return true
end

-- Award treasure chest (limited quantity)
local function awardTreasureChest(player)
	if not activeEvent.raidData then return false end
	if activeEvent.raidData.chestsRemaining <= 0 then
		-- No chests left!
		if _G.NotificationSystem then
			_G.NotificationSystem.showNotification(player, 
				"💔 ALL TREASURE CHESTS CLAIMED! You were too slow!", 
				"error")
		end
		return false
	end

	local userId = player.UserId
	activeEvent.raidData.treasureChestsFound[userId] = (activeEvent.raidData.treasureChestsFound[userId] or 0) + 1
	activeEvent.raidData.participationScore[userId] = (activeEvent.raidData.participationScore[userId] or 0) + 1000
	activeEvent.raidData.chestsRemaining = activeEvent.raidData.chestsRemaining - 1

	-- Calculate chest reward based on performance and scarcity
	local baseReward = 10000
	local scarcityMultiplier = (11 - activeEvent.raidData.chestsRemaining) * 0.5 -- Later chests worth more
	local performanceBonus = activeEvent.raidData.goldenMonkeysKilled[userId] * 500
	local totalReward = math.floor(baseReward * scarcityMultiplier + performanceBonus)

	-- Award the earned coins
	if _G.CoinSystem and _G.CoinSystem.addCoins then
		_G.CoinSystem.addCoins(player, totalReward)
	end

	-- Announce to all players
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if _G.NotificationSystem then
			local message = "💰 " .. player.Name .. " claimed treasure chest #" .. (11 - activeEvent.raidData.chestsRemaining) .. " for " .. totalReward .. " coins!"
			_G.NotificationSystem.showNotification(otherPlayer, message, "legendary")
		end
	end

	-- Warn about remaining chests
	if activeEvent.raidData.chestsRemaining > 0 then
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player and _G.NotificationSystem then
				_G.NotificationSystem.showNotification(otherPlayer, 
					"⚠️ ONLY " .. activeEvent.raidData.chestsRemaining .. " TREASURE CHESTS LEFT!", 
					"warning")
			end
		end
	else
		-- All chests claimed - raid over early
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if _G.NotificationSystem then
				_G.NotificationSystem.showNotification(otherPlayer, 
					"💀 ALL CHESTS CLAIMED! Golden Monkey Raid ending early!", 
					"error")
			end
		end
	end

	return true
end

-- Calculate final raid rewards (called at event end)
local function distributeRaidRewards()
	if not activeEvent.raidData then return end

	-- Calculate top performers
	local playerScores = {}
	for userId, score in pairs(activeEvent.raidData.participationScore) do
		if score > 0 then -- Only players who participated
			table.insert(playerScores, {userId = userId, score = score})
		end
	end

	-- Sort by score (highest first)
	table.sort(playerScores, function(a, b) return a.score > b.score end)

	-- Award top 3 performers additional bonuses
	for i, data in ipairs(playerScores) do
		if i > 3 then break end -- Only top 3

		local player = Players:GetPlayerByUserId(data.userId)
		if player then
			local bonusReward = 0
			local rank = ""

			if i == 1 then
				bonusReward = 25000
				rank = "🥇 RAID CHAMPION"
			elseif i == 2 then
				bonusReward = 15000
				rank = "🥈 RAID ELITE"
			elseif i == 3 then
				bonusReward = 10000
				rank = "🥉 RAID WARRIOR"
			end

			if _G.CoinSystem and _G.CoinSystem.addCoins then
				_G.CoinSystem.addCoins(player, bonusReward)
			end

			if _G.NotificationSystem then
				_G.NotificationSystem.showNotification(player, 
					rank .. " - Earned " .. bonusReward .. " bonus coins for outstanding performance!", 
					"legendary")
			end
		end
	end

	-- Announce final results to all players
	for _, player in ipairs(Players:GetPlayers()) do
		if _G.NotificationSystem then
			local chestsFound = activeEvent.raidData.treasureChestsFound[player.UserId] or 0
			local monkeysKilled = activeEvent.raidData.goldenMonkeysKilled[player.UserId] or 0
			local message = "⚔️ RAID RESULTS: You found " .. chestsFound .. " chests, killed " .. monkeysKilled .. " monkeys"
			_G.NotificationSystem.showNotification(player, message, "info")
		end
	end

	print("🐒⚔️ Golden Monkey Raid completed - Rewards distributed to top performers only")
end

-- Random event scheduler
task.spawn(function()
	while true do
		local nextEventTime = math.random(EVENT_INTERVAL_MIN, EVENT_INTERVAL_MAX)
		task.wait(nextEventTime)

		-- Only start event if there are players online
		if #Players:GetPlayers() > 0 then
			startRandomEvent()
		end
	end
end)

-- Event monitoring loop
task.spawn(function()
	while true do
		task.wait(1)

		-- Check if current event should end
		if isEventActive() and tick() >= activeEvent.endTime then
			endCurrentEvent()
		end

		-- Apply continuous event effects
		applyEventEffects()
	end
end)

-- Handle new players joining during events
Players.PlayerAdded:Connect(function(player)
	if isEventActive() then
		activeEvent.participants[player.UserId] = {
			joinTime = tick(),
			rewardsClaimed = false
		}

		local eventConfig = EVENTS[activeEvent.type]
		if eventConfig and _G.NotificationSystem and _G.NotificationSystem.showNotification then
			_G.NotificationSystem.showNotification(player, 
				"🎲 You joined during " .. eventConfig.name .. "! " .. eventConfig.description,
				eventConfig.beneficial and "legendary" or "warning")
		end
	end
end)

-- Wait for manually created RemoteEvents
-- Note: Create these RemoteEvents manually in ReplicatedStorage/RemoteEvents/:
-- - GetEventStatus (RemoteFunction)
-- - TriggerEvent (RemoteEvent)
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local getEventStatusRemote = remoteEventsFolder:WaitForChild("GetEventStatus")
local triggerEventRemote = remoteEventsFolder:WaitForChild("TriggerEvent")

-- Remote handlers
getEventStatusRemote.OnServerInvoke = function(player)
	return getEventStatus(player)
end

triggerEventRemote.OnServerEvent:Connect(function(player, eventType)
	-- Admin-only event triggering (you could add permission checks here)
	if eventType and EVENTS[eventType] then
		endCurrentEvent() -- End current event if any

		activeEvent.type = eventType
		activeEvent.startTime = tick()
		activeEvent.endTime = tick() + EVENTS[eventType].duration
		activeEvent.participants = {}

		for _, p in ipairs(Players:GetPlayers()) do
			activeEvent.participants[p.UserId] = {
				joinTime = tick(),
				rewardsClaimed = false
			}
		end

		print("🔧 Admin triggered event:", EVENTS[eventType].name)
	end
end)

-- Global functions
_G.RandomEventsSystem = {
	startRandomEvent = startRandomEvent,
	endCurrentEvent = endCurrentEvent,
	getEventStatus = getEventStatus,
	getCurrentEventEffects = getCurrentEventEffects,
	isEventActive = isEventActive,
	recordMonkeyKill = recordMonkeyKill, -- For Golden Monkey Raid
	awardTreasureChest = awardTreasureChest, -- For Golden Monkey Raid
	EVENTS = EVENTS
}

-- Global event broadcasting
local function broadcastEventGlobally(eventType, eventData)
	local success, err = pcall(function()
		MessagingService:PublishAsync("BananaGameEvent", {
			eventType = eventType,
			eventData = eventData,
			timestamp = tick(),
			serverId = game.JobId
		})
	end)

	if not success then
		warn("Failed to broadcast event globally:", err)
	end
end

-- Listen for global events
local function listenForGlobalEvents()
	local success, connection = pcall(function()
		return MessagingService:SubscribeAsync("BananaGameEvent", function(message)
			local data = message.Data
			if data.serverId ~= game.JobId then -- Don't process our own events
				print("🌍 Global event received:", data.eventType)
				-- Process global event data here
			end
		end)
	end)

	if not success then
		warn("Failed to subscribe to global events:", connection)
	end
end

-- Owner command system
local function isOwner(player)
	return player.UserId == OWNER_USER_ID
end

-- Execute specific event (owner command)
local function executeEvent(eventType)
	if not EVENTS[eventType] then
		return false, "Event type not found: " .. eventType
	end

	if isEventActive() then
		-- Force stop current event
		endCurrentEvent()
		wait(1)
	end

	local eventConfig = EVENTS[eventType]

	-- Start the event
	activeEvent.type = eventType
	activeEvent.startTime = tick()
	activeEvent.endTime = tick() + eventConfig.duration
	activeEvent.participants = {}

	-- Add all current players as participants
	for _, player in ipairs(Players:GetPlayers()) do
		activeEvent.participants[player.UserId] = {
			joinTime = tick(),
			rewardsClaimed = false
		}
	end

	-- Broadcast event start to all players
	for _, player in ipairs(Players:GetPlayers()) do
		local NotificationSystem = require(script.Parent.NotificationSystem)
		if NotificationSystem then
			NotificationSystem:SendNotification(player, "🎲 " .. eventConfig.name, eventConfig.description, eventConfig.duration / 60)
		end
	end

	-- Broadcast globally
	broadcastEventGlobally("event_start", {
		eventType = eventType,
		eventName = eventConfig.name,
		duration = eventConfig.duration,
		forcedByOwner = true
	})

	-- Log the event
	table.insert(eventHistory, {
		type = eventType,
		startTime = activeEvent.startTime,
		duration = eventConfig.duration,
		participants = #Players:GetPlayers(),
		forcedByOwner = true
	})

	print("👑 Owner executed event:", eventConfig.name)
	return true, "Event started: " .. eventConfig.name
end

-- Give coins to player (owner command)
local function giveCoinsToPlayer(targetUsername, amount)
	local targetPlayer = nil

	-- Find player by username (case insensitive)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower() == targetUsername:lower() or player.DisplayName:lower() == targetUsername:lower() then
			targetPlayer = player
			break
		end
	end

	if not targetPlayer then
		return false, "Player not found: " .. targetUsername
	end

	-- Get CoinSystem
	local CoinSystem = require(script.Parent.CoinSystem)
	if CoinSystem then
		local success = CoinSystem:AddCoins(targetPlayer, amount)
		if success then
			-- Notify player
			local NotificationSystem = require(script.Parent.NotificationSystem)
			if NotificationSystem then
				NotificationSystem:SendNotification(targetPlayer, "💰 Owner Gift", "You received " .. amount .. " coins from the owner!", 5)
			end

			return true, "Gave " .. amount .. " coins to " .. targetPlayer.Name
		else
			return false, "Failed to give coins to " .. targetPlayer.Name
		end
	else
		return false, "CoinSystem not found"
	end
end

-- Broadcast message to server or globally
local function broadcastOwnerMessage(scope, message)
	if scope == "server" then
		-- Broadcast to current server
		for _, player in ipairs(Players:GetPlayers()) do
			local NotificationSystem = require(script.Parent.NotificationSystem)
			if NotificationSystem then
				NotificationSystem:SendNotification(player, "📢 Owner Announcement", message, 10)
			end
		end
		return true, "Broadcast to server: " .. message
	elseif scope == "global" then
		-- Broadcast globally via MessagingService
		broadcastEventGlobally("owner_broadcast", {
			message = message,
			timestamp = tick()
		})

		-- Also broadcast to current server
		for _, player in ipairs(Players:GetPlayers()) do
			local NotificationSystem = require(script.Parent.NotificationSystem)
			if NotificationSystem then
				NotificationSystem:SendNotification(player, "📢 Global Owner Announcement", message, 10)
			end
		end
		return true, "Broadcast globally: " .. message
	else
		return false, "Invalid scope. Use 'server' or 'global'"
	end
end

-- Owner chat command handler
local function handleOwnerCommand(player, message)
	if not isOwner(player) then
		return
	end

	local command = message:lower()

	-- \execute event (event_name)
	if command:match("^\\execute event (.+)") then
		local eventType = command:match("^\\execute event (.+)")
		eventType = eventType:gsub(" ", "_"):lower()

		local success, result = executeEvent(eventType)
		local NotificationSystem = require(script.Parent.NotificationSystem)
		if NotificationSystem then
			NotificationSystem:SendNotification(player, success and "✅ Success" or "❌ Error", result, 5)
		end
		print("👑 Owner command result:", result)

		-- \give (username) (amount) coins
	elseif command:match("^\\give (%S+) (%d+) coins?") then
		local username, amountStr = command:match("^\\give (%S+) (%d+) coins?")
		local amount = tonumber(amountStr)

		if amount and amount > 0 then
			local success, result = giveCoinsToPlayer(username, amount)
			local NotificationSystem = require(script.Parent.NotificationSystem)
			if NotificationSystem then
				NotificationSystem:SendNotification(player, success and "✅ Success" or "❌ Error", result, 5)
			end
			print("👑 Owner coin command result:", result)
		else
			local NotificationSystem = require(script.Parent.NotificationSystem)
			if NotificationSystem then
				NotificationSystem:SendNotification(player, "❌ Error", "Invalid coin amount", 5)
			end
		end

		-- \broadcast server (message)
	elseif command:match("^\\broadcast server (.+)") then
		local broadcastMsg = message:match("^\\broadcast server (.+)")
		local success, result = broadcastOwnerMessage("server", broadcastMsg)
		print("👑 Owner broadcast result:", result)

		-- \broadcast global (message)  
	elseif command:match("^\\broadcast global (.+)") then
		local broadcastMsg = message:match("^\\broadcast global (.+)")
		local success, result = broadcastOwnerMessage("global", broadcastMsg)
		print("👑 Owner global broadcast result:", result)
	end
end

-- Connect owner command handler to player chats
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		handleOwnerCommand(player, message)
	end)
end)

-- Handle players already in game
for _, player in ipairs(Players:GetPlayers()) do
	player.Chatted:Connect(function(message)
		handleOwnerCommand(player, message)
	end)
end

-- Initialize global event system
listenForGlobalEvents()

print("🌍 RandomEventsSystem loaded with global broadcasting and owner commands")
print("👑 Owner ID:", OWNER_USER_ID)
print("💬 Owner Commands:")
print("   \\execute event <event_name> - Force start an event")
print("   \\give <username> <amount> coins - Give coins to a player")
print("   \\broadcast server <message> - Broadcast to current server")
print("   \\broadcast global <message> - Broadcast to all servers")

-- Weather Dominator Gamepass Integration
local playerWeatherStack = {}
local WEATHER_EVENT_LIMIT = 3
local WEATHER_EVENT_COOLDOWN = 0 -- Set to 0 to allow stacking, but you can adjust if needed
local specialWeatherEvents = {
	banana_storm = true,
	overflowing_growth = true,
	lightning_harvest = true,
	banana_bloom_burst = true,
	festival_rain = true,
	banana_eclipse = true,
	super_monkey_storm = true
}

function _G.RandomEventsSystem.ForceWeatherEventByPlayer(player, eventType)
	if not player or not player:GetAttribute("WeatherDominatorEnabled") then
		return false, "You do not own the Weather Dominator gamepass."
	end
	eventType = eventType:lower()
	if not specialWeatherEvents[eventType] then
		return false, "Not a valid special weather event."
	end
	-- Initialize stack for player
	playerWeatherStack[player.UserId] = playerWeatherStack[player.UserId] or {}
	local stack = playerWeatherStack[player.UserId]
	-- Remove expired events from stack
	local now = tick()
	for i = #stack, 1, -1 do
		if stack[i].endTime and now > stack[i].endTime then
			table.remove(stack, i)
		end
	end
	if #stack >= WEATHER_EVENT_LIMIT then
		return false, "You have reached the max of 3 stacked weather events."
	end
	-- Check if this event is already running for this player
	for _, evt in ipairs(stack) do
		if evt.type == eventType and now < evt.endTime then
			return false, "This weather event is already active for you."
		end
	end
	-- Get event config
	local eventConfig = EVENTS[eventType]
	if not eventConfig then
		return false, "Event config not found."
	end
	-- Start the event for all players (global effect)
	activeEvent.type = eventType
	activeEvent.startTime = now
	activeEvent.endTime = now + eventConfig.duration
	activeEvent.participants = {}
	for _, p in ipairs(Players:GetPlayers()) do
		activeEvent.participants[p.UserId] = {
			joinTime = now,
			rewardsClaimed = false
		}
	end
	-- Add to player's stack
	table.insert(stack, {type = eventType, endTime = now + eventConfig.duration})
	-- Notify
	for _, p in ipairs(Players:GetPlayers()) do
		if _G.NotificationSystem and _G.NotificationSystem.showNotification then
			_G.NotificationSystem.showNotification(p, "🌩️ Weather Dominator: " .. player.Name .. " forced " .. eventConfig.name .. "!", "legendary")
		end
	end
	print("[Weather Dominator] " .. player.Name .. " forced event: " .. eventType)
	return true, "Weather event started: " .. eventConfig.name
end

-- Add-on complete: Weather Dominator can now force/stack up to 3 special weather events per player.
