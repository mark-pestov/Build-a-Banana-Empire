-- BananaThiefEvent.lua
-- Server-side Banana Thief Alert event system
-- Spawns thief targeting random plots, defeat for rare seeds

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BananaThiefEvent = {}

-- Configuration
local Config = {
	EventDuration = 180, -- 3 minutes
	ThiefHealth = 100,
	ThiefSpeed = 16, -- Studs per second
	ThiefStealDelay = 5, -- Seconds before thief steals from a plot
	DefeatRewards = {
		coins = 2500,
		seeds = {"Legendary", "Mythical", "Celestial"}, -- Possible rare seeds
		seedChance = 0.7 -- 70% chance to get a rare seed
	},
	TargetPlotRadius = 50 -- Radius to find plots to target
}

-- Active event tracking
local activeEvent = {
	isActive = false,
	startTime = 0,
	thiefData = nil,
	targetPlot = nil,
	lastPosition = Vector3.new(0, 0, 0)
}

-- Initialize event system
function BananaThiefEvent.Initialize()
	print("Banana Thief Event System initialized")
end

-- Start the banana thief event
function BananaThiefEvent.StartEvent()
	if activeEvent.isActive then return false end

	activeEvent.isActive = true
	activeEvent.startTime = tick()

	-- Select random target plot
	activeEvent.targetPlot = BananaThiefEvent.SelectRandomPlot()
	if not activeEvent.targetPlot then
		print("No valid plots found for thief event")
		return false
	end

	-- Spawn thief
	BananaThiefEvent.SpawnThief()

	print("🦹 BANANA THIEF ALERT EVENT STARTED!")

	-- Notify all players
	BananaThiefEvent.NotifyPlayers("🦹 BANANA THIEF ALERT! A thief is targeting plot " .. activeEvent.targetPlot.id .. "! Defeat them for rare rewards!")

	-- Set event timer
	task.spawn(function()
		task.wait(Config.EventDuration)
		BananaThiefEvent.EndEvent("timeout")
	end)

	-- Start thief AI
	BananaThiefEvent.StartThiefAI()

	-- Integrate with random events system
	if _G.RandomEventsSystem then
		_G.RandomEventsSystem.SetCurrentEvent({
			name = "Banana Thief Alert",
			description = "Thief targeting plots! Defeat for rare seeds!",
			beneficial = false,
			duration = Config.EventDuration
		})
	end

	return true
end

-- Select a random plot to target
function BananaThiefEvent.SelectRandomPlot()
	-- Get list of available plots (integrate with your plot system)
	local availablePlots = {}

	-- For now, create sample plot data
	-- In real implementation, this would get actual player plots
	for i = 1, 10 do
		table.insert(availablePlots, {
			id = "Plot_" .. i,
			owner = "Player" .. i,
			position = Vector3.new(math.random(-50, 50), 0, math.random(-50, 50)),
			hasBananas = math.random() > 0.3 -- 70% chance plot has bananas
		})
	end

	-- Filter plots that have bananas
	local validPlots = {}
	for _, plot in ipairs(availablePlots) do
		if plot.hasBananas then
			table.insert(validPlots, plot)
		end
	end

	if #validPlots == 0 then return nil end

	return validPlots[math.random(1, #validPlots)]
end

-- Spawn the thief (data-only, no physical parts)
function BananaThiefEvent.SpawnThief()
	-- Spawn thief away from target plot
	local spawnDistance = 75
	local angle = math.random() * 2 * math.pi
	local spawnPosition = activeEvent.targetPlot.position + Vector3.new(
		math.cos(angle) * spawnDistance,
		5,
		math.sin(angle) * spawnDistance
	)

	activeEvent.thiefData = {
		health = Config.ThiefHealth,
		maxHealth = Config.ThiefHealth,
		position = spawnPosition,
		targetPosition = activeEvent.targetPlot.position,
		state = "approaching", -- approaching, stealing, fleeing, defeated
		stealStartTime = 0,
		speed = Config.ThiefSpeed
	}

	activeEvent.lastPosition = spawnPosition

	print("🦹 Thief spawned at", spawnPosition, "targeting plot", activeEvent.targetPlot.id)
end

-- Start thief AI behavior
function BananaThiefEvent.StartThiefAI()
	task.spawn(function()
		while activeEvent.isActive and activeEvent.thiefData and activeEvent.thiefData.health > 0 do
			BananaThiefEvent.UpdateThiefAI()
			task.wait(0.1) -- Update every 0.1 seconds
		end
	end)
end

-- Update thief AI behavior
function BananaThiefEvent.UpdateThiefAI()
	local thief = activeEvent.thiefData
	if not thief then return end

	local deltaTime = 0.1

	if thief.state == "approaching" then
		-- Move towards target plot
		local direction = (thief.targetPosition - thief.position).Unit
		local movement = direction * thief.speed * deltaTime
		thief.position = thief.position + movement

		-- Check if reached target
		local distance = (thief.position - thief.targetPosition).Magnitude
		if distance < 5 then
			thief.state = "stealing"
			thief.stealStartTime = tick()
			BananaThiefEvent.NotifyPlayers("🦹 The thief has reached " .. activeEvent.targetPlot.id .. " and is stealing bananas!")
		end

	elseif thief.state == "stealing" then
		-- Stay at plot and steal
		local stealTime = tick() - thief.stealStartTime
		if stealTime >= Config.ThiefStealDelay then
			BananaThiefEvent.ThiefStealsBananas()
			thief.state = "fleeing"
		end

	elseif thief.state == "fleeing" then
		-- Run away from plot
		local fleeDirection = (thief.position - thief.targetPosition).Unit
		local movement = fleeDirection * thief.speed * 1.5 * deltaTime -- 1.5x speed when fleeing
		thief.position = thief.position + movement

		-- Check if escaped
		local distance = (thief.position - thief.targetPosition).Magnitude
		if distance > 100 then
			BananaThiefEvent.EndEvent("escaped")
		end
	end

	activeEvent.lastPosition = thief.position
end

-- Handle thief stealing bananas from plot
function BananaThiefEvent.ThiefStealsBananas()
	local stolenAmount = math.random(10, 30)

	-- Remove bananas from plot (integrate with your plot system)
	-- For now, just log the theft
	print("🦹 Thief stole " .. stolenAmount .. " bananas from " .. activeEvent.targetPlot.id)

	BananaThiefEvent.NotifyPlayers("🦹 The thief stole " .. stolenAmount .. " bananas from " .. activeEvent.targetPlot.id .. "! They're escaping!")

	-- Store stolen bananas in Core Memory Crater if available
	if _G.CoreMemoryCrater and _G.CoreMemoryCrater.AddLostBananas then
		_G.CoreMemoryCrater.AddLostBananas(activeEvent.targetPlot.owner, stolenAmount, "Stolen by Banana Thief")
	end
end

-- Handle player attacking thief
function BananaThiefEvent.AttackThief(player, damage)
	if not activeEvent.isActive or not activeEvent.thiefData then return false end

	local thief = activeEvent.thiefData
	if thief.health <= 0 then return false end

	-- Apply damage
	thief.health = math.max(0, thief.health - damage)

	print(player.Name .. " attacked thief for " .. damage .. " damage! Health: " .. thief.health .. "/" .. thief.maxHealth)

	-- Check if defeated
	if thief.health <= 0 then
		BananaThiefEvent.ThiefDefeated(player)
		return true
	end

	-- Thief becomes more aggressive when damaged
	if thief.state == "stealing" then
		thief.speed = thief.speed * 1.2
	end

	return true
end

-- Handle thief being defeated
function BananaThiefEvent.ThiefDefeated(defeatedBy)
	if not activeEvent.thiefData then return end

	activeEvent.thiefData.state = "defeated"

	BananaThiefEvent.NotifyPlayers("🦹 " .. defeatedBy.Name .. " defeated the Banana Thief! They received rare rewards!")

	-- Give rewards to the player who defeated the thief
	BananaThiefEvent.GiveDefeatRewards(defeatedBy)

	-- End event
	BananaThiefEvent.EndEvent("defeated")
end

-- Give rewards for defeating the thief
function BananaThiefEvent.GiveDefeatRewards(player)
	-- Give coins
	if _G.CoinSystem and _G.CoinSystem.AddCoins then
		_G.CoinSystem.AddCoins(player, Config.DefeatRewards.coins)
	end

	-- Give rare seed (70% chance)
	if math.random() <= Config.DefeatRewards.seedChance then
		local rareSeed = Config.DefeatRewards.seeds[math.random(1, #Config.DefeatRewards.seeds)]

		-- Add seed to player inventory (integrate with your inventory system)
		print(player.Name .. " received a " .. rareSeed .. " seed for defeating the thief!")

		BananaThiefEvent.NotifyPlayer(player, "🌱 You received a " .. rareSeed .. " seed for defeating the thief!")
	end

	BananaThiefEvent.NotifyPlayer(player, "💰 You received " .. Config.DefeatRewards.coins .. " coins for defeating the thief!")
end

-- End the banana thief event
function BananaThiefEvent.EndEvent(reason)
	if not activeEvent.isActive then return end

	activeEvent.isActive = false

	local message = ""
	if reason == "timeout" then
		message = "🦹 Banana Thief event ended! The thief escaped into the shadows..."
	elseif reason == "escaped" then
		message = "🦹 The Banana Thief escaped with their stolen bananas!"
	elseif reason == "defeated" then
		message = "🦹 The Banana Thief has been defeated! Justice prevails!"
	end

	BananaThiefEvent.NotifyPlayers(message)

	-- Clean up
	activeEvent.thiefData = nil
	activeEvent.targetPlot = nil

	print("🦹 Banana Thief event ended: " .. reason)

	-- Clear from random events system
	if _G.RandomEventsSystem then
		_G.RandomEventsSystem.ClearCurrentEvent()
	end
end

-- Get thief position for client systems
function BananaThiefEvent.GetThiefPosition()
	if activeEvent.thiefData then
		return activeEvent.thiefData.position
	end
	return nil
end

-- Get event status for UI systems
function BananaThiefEvent.GetEventStatus()
	local thief = activeEvent.thiefData
	return {
		isActive = activeEvent.isActive,
		timeRemaining = activeEvent.isActive and math.max(0, Config.EventDuration - (tick() - activeEvent.startTime)) or 0,
		thiefHealth = thief and thief.health or 0,
		thiefMaxHealth = thief and thief.maxHealth or 0,
		thiefState = thief and thief.state or "none",
		targetPlot = activeEvent.targetPlot and activeEvent.targetPlot.id or "none"
	}
end

-- Notify all players
function BananaThiefEvent.NotifyPlayers(message)
	for _, player in pairs(Players:GetPlayers()) do
		BananaThiefEvent.NotifyPlayer(player, message)
	end
end

-- Notify single player
function BananaThiefEvent.NotifyPlayer(player, message)
	-- Use notification system if available
	if _G.NotificationSystem and _G.NotificationSystem.SendNotification then
		_G.NotificationSystem.SendNotification(player, "Thief Alert", message, 5)
	else
		-- Fallback to print/chat
		print("[THIEF EVENT] " .. player.Name .. ": " .. message)
	end
end

-- Initialize the system
BananaThiefEvent.Initialize()

-- Global access
_G.BananaThiefEvent = BananaThiefEvent

return BananaThiefEvent