-- NuclearMeltdownEvent.lua
-- Server-side Nuclear Banana Meltdown event system
-- Spawns radioactive bananas worth 10x cash but with growth penalties

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local NuclearMeltdownEvent = {}

-- Configuration
local Config = {
	EventDuration = 120, -- 2 minutes
	RadioactiveBananaCount = 15, -- Number of radioactive bananas to spawn
	CashMultiplier = 10, -- 10x normal cash value
	GrowthPenaltyDuration = 120, -- 2 minutes growth penalty
	SpawnRadius = 100, -- Radius to spawn radioactive bananas
	RequiredProtection = "RadiationSuit" -- Gamepass or item needed for protection
}

-- Active event tracking
local activeEvent = {
	isActive = false,
	startTime = 0,
	radioactiveBananas = {},
	affectedPlayers = {} -- Players with radiation sickness
}

-- Initialize event system
function NuclearMeltdownEvent.Initialize()
	print("Nuclear Meltdown Event System initialized")
end

-- Start the nuclear meltdown event
function NuclearMeltdownEvent.StartEvent()
	if activeEvent.isActive then return false end

	activeEvent.isActive = true
	activeEvent.startTime = tick()
	activeEvent.radioactiveBananas = {}
	activeEvent.affectedPlayers = {}

	print("☢️ NUCLEAR BANANA MELTDOWN EVENT STARTED!")

	-- Notify all players
	NuclearMeltdownEvent.NotifyPlayers("☢️ NUCLEAR BANANA MELTDOWN! Radioactive bananas are spawning! They give 10x cash but cause radiation sickness!")

	-- Spawn radioactive bananas
	NuclearMeltdownEvent.SpawnRadioactiveBananas()

	-- Set event timer
	task.spawn(function()
		task.wait(Config.EventDuration)
		NuclearMeltdownEvent.EndEvent()
	end)

	-- Integrate with random events system if available
	if _G.RandomEventsSystem then
		_G.RandomEventsSystem.SetCurrentEvent({
			name = "Nuclear Banana Meltdown",
			description = "Radioactive bananas spawning! 10x cash but radiation penalty!",
			beneficial = false,
			duration = Config.EventDuration
		})
	end

	return true
end

-- Spawn radioactive bananas around the map
function NuclearMeltdownEvent.SpawnRadioactiveBananas()
	local spawnCenter = Vector3.new(0, 0, 0) -- Center of map, adjust as needed

	for i = 1, Config.RadioactiveBananaCount do
		-- Random position within spawn radius
		local angle = math.random() * 2 * math.pi
		local distance = math.random(10, Config.SpawnRadius)
		local x = spawnCenter.X + math.cos(angle) * distance
		local z = spawnCenter.Z + math.sin(angle) * distance
		local y = spawnCenter.Y + 5 -- Spawn above ground

		local bananaData = {
			position = Vector3.new(x, y, z),
			value = 100 * Config.CashMultiplier, -- Base banana value * 10
			id = "radioactive_" .. i,
			spawnTime = tick()
		}

		table.insert(activeEvent.radioactiveBananas, bananaData)

		-- Create visual marker (data-only, no physical parts)
		NuclearMeltdownEvent.CreateRadioactiveBananaMarker(bananaData)
	end

	print("Spawned " .. Config.RadioactiveBananaCount .. " radioactive bananas")
end

-- Create a data marker for radioactive banana (no physical parts)
function NuclearMeltdownEvent.CreateRadioactiveBananaMarker(bananaData)
	-- Store banana data for client detection
	-- This would integrate with your existing fruit/banana system

	-- Log the radioactive banana spawn
	print("☢️ Radioactive banana spawned at", bananaData.position, "Value:", bananaData.value)
end

-- Handle player collecting radioactive banana
function NuclearMeltdownEvent.CollectRadioactiveBanana(player, bananaId)
	if not activeEvent.isActive then return false end

	-- Find the banana
	local bananaIndex = nil
	local bananaData = nil

	for i, banana in ipairs(activeEvent.radioactiveBananas) do
		if banana.id == bananaId then
			bananaIndex = i
			bananaData = banana
			break
		end
	end

	if not bananaData then return false end

	-- Check if player has protection
	local hasProtection = NuclearMeltdownEvent.PlayerHasProtection(player)

	-- Give cash reward
	if _G.CoinSystem and _G.CoinSystem.AddCoins then
		_G.CoinSystem.AddCoins(player, bananaData.value)
		print(player.Name .. " collected radioactive banana for " .. bananaData.value .. " coins!")
	end

	-- Apply radiation effect if no protection
	if not hasProtection then
		NuclearMeltdownEvent.ApplyRadiationSickness(player)
	end

	-- Remove the banana from active list
	table.remove(activeEvent.radioactiveBananas, bananaIndex)

	-- Notify player
	local message = hasProtection and 
		"☢️ Collected radioactive banana safely! +" .. bananaData.value .. " coins!" or
		"☢️ Collected radioactive banana! +" .. bananaData.value .. " coins! Radiation sickness applied!"

	NuclearMeltdownEvent.NotifyPlayer(player, message)

	return true
end

-- Check if player has radiation protection
function NuclearMeltdownEvent.PlayerHasProtection(player)
	-- Check for radiation suit gamepass or item
	-- This would integrate with your gamepass system

	-- For now, return false (no protection system implemented)
	return false
end

-- Apply radiation sickness to player
function NuclearMeltdownEvent.ApplyRadiationSickness(player)
	if activeEvent.affectedPlayers[player.UserId] then return end -- Already affected

	activeEvent.affectedPlayers[player.UserId] = {
		startTime = tick(),
		duration = Config.GrowthPenaltyDuration
	}

	print(player.Name .. " has radiation sickness - growth penalty applied")

	-- Remove radiation sickness after duration
	task.spawn(function()
		task.wait(Config.GrowthPenaltyDuration)
		NuclearMeltdownEvent.CureRadiationSickness(player)
	end)
end

-- Remove radiation sickness from player
function NuclearMeltdownEvent.CureRadiationSickness(player)
	if activeEvent.affectedPlayers[player.UserId] then
		activeEvent.affectedPlayers[player.UserId] = nil
		NuclearMeltdownEvent.NotifyPlayer(player, "☢️ Radiation sickness has worn off! Growth speed returned to normal.")
		print(player.Name .. " cured of radiation sickness")
	end
end

-- Check if player has radiation sickness
function NuclearMeltdownEvent.PlayerHasRadiationSickness(player)
	local sickness = activeEvent.affectedPlayers[player.UserId]
	if not sickness then return false end

	-- Check if sickness duration has expired
	if tick() - sickness.startTime >= sickness.duration then
		NuclearMeltdownEvent.CureRadiationSickness(player)
		return false
	end

	return true
end

-- Get growth speed modifier for player (used by growth systems)
function NuclearMeltdownEvent.GetGrowthSpeedModifier(player)
	if NuclearMeltdownEvent.PlayerHasRadiationSickness(player) then
		return 0.5 -- 50% slower growth
	end
	return 1.0 -- Normal growth
end

-- End the nuclear meltdown event
function NuclearMeltdownEvent.EndEvent()
	if not activeEvent.isActive then return end

	activeEvent.isActive = false

	-- Clean up remaining radioactive bananas
	local remainingBananas = #activeEvent.radioactiveBananas
	activeEvent.radioactiveBananas = {}

	-- Notify players
	NuclearMeltdownEvent.NotifyPlayers("☢️ Nuclear Banana Meltdown event ended! " .. remainingBananas .. " radioactive bananas disappeared.")

	print("☢️ Nuclear Banana Meltdown event ended")

	-- Clear from random events system
	if _G.RandomEventsSystem then
		_G.RandomEventsSystem.ClearCurrentEvent()
	end
end

-- Notify all players
function NuclearMeltdownEvent.NotifyPlayers(message)
	for _, player in pairs(Players:GetPlayers()) do
		NuclearMeltdownEvent.NotifyPlayer(player, message)
	end
end

-- Notify single player
function NuclearMeltdownEvent.NotifyPlayer(player, message)
	-- Use notification system if available
	if _G.NotificationSystem and _G.NotificationSystem.SendNotification then
		_G.NotificationSystem.SendNotification(player, "Nuclear Event", message, 5)
	else
		-- Fallback to print/chat
		print("[NUCLEAR EVENT] " .. player.Name .. ": " .. message)
	end
end

-- Get event status for UI systems
function NuclearMeltdownEvent.GetEventStatus()
	return {
		isActive = activeEvent.isActive,
		timeRemaining = activeEvent.isActive and math.max(0, Config.EventDuration - (tick() - activeEvent.startTime)) or 0,
		radioactiveBananasRemaining = #activeEvent.radioactiveBananas,
		affectedPlayersCount = 0 -- Could count affected players
	}
end

-- Get radioactive bananas list (for client detection systems)
function NuclearMeltdownEvent.GetRadioactiveBananas()
	return activeEvent.radioactiveBananas
end

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
	if activeEvent.affectedPlayers[player.UserId] then
		activeEvent.affectedPlayers[player.UserId] = nil
	end
end)

-- Initialize the system
NuclearMeltdownEvent.Initialize()

-- Global access
_G.NuclearMeltdownEvent = NuclearMeltdownEvent

return NuclearMeltdownEvent
