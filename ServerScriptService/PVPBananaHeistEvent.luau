-- PvPBananaHeistEvent.lua
-- Server-side PvP Banana Heist event system
-- One player becomes robber, others get tools to catch them

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local PvPBananaHeistEvent = {}

-- Configuration
local Config = {
	EventDuration = 300, -- 5 minutes
	RobberReward = 5000, -- Coins for successful steal
	RobberPenalty = -5000, -- Coins lost for being caught
	RobberSelectionTimeout = 30, -- Time to accept robber role
	StealTimeout = 60, -- Time limit for robber to steal

	-- Innocent tools
	InnocentTools = {
		BearTraps = 3,
		TripwireAlarms = 1,
		Flashlights = 1 -- Infinite use
	},

	-- Lighting effects
	DarknessLevel = 0.2, -- How dark the map becomes (0-1)
	OriginalBrightness = 1
}

-- Active event tracking
local activeEvent = {
	isActive = false,
	startTime = 0,
	robber = nil,
	innocents = {},
	robbberAccepted = false,
	robberTarget = nil,
	innocentTools = {}, -- Track tools placed by innocents
	gamePhase = "selection" -- selection, active, completed
}

-- Initialize event system
function PvPBananaHeistEvent.Initialize()
	print("PvP Banana Heist Event System initialized")
end

-- Start the PvP heist event
function PvPBananaHeistEvent.StartEvent()
	if activeEvent.isActive then return false end

	-- Need at least 2 players for PvP event
	local players = Players:GetPlayers()
	if #players < 2 then
		print("Not enough players for PvP Banana Heist (need at least 2)")
		return false
	end

	activeEvent.isActive = true
	activeEvent.startTime = tick()
	activeEvent.gamePhase = "selection"
	activeEvent.innocents = {}
	activeEvent.innocentTools = {}

	-- Select random robber
	PvPBananaHeistEvent.SelectRobber()

	print("🔫 PVP BANANA HEIST EVENT STARTED!")

	-- Integrate with random events system
	if _G.RandomEventsSystem then
		_G.RandomEventsSystem.SetCurrentEvent({
			name = "PvP Banana Heist",
			description = "Robber vs Innocents! High stakes fruit stealing!",
			beneficial = false,
			duration = Config.EventDuration
		})
	end

	return true
end

-- Select a random player to be the robber
function PvPBananaHeistEvent.SelectRobber()
	local players = Players:GetPlayers()
	local potentialRobbers = {}

	-- Filter active players
	for _, player in ipairs(players) do
		if player.Parent then -- Player is still in game
			table.insert(potentialRobbers, player)
		end
	end

	if #potentialRobbers == 0 then
		PvPBananaHeistEvent.EndEvent("no_players")
		return
	end

	local selectedRobber = potentialRobbers[math.random(1, #potentialRobbers)]

	-- Offer robber role
	PvPBananaHeistEvent.OfferRobberRole(selectedRobber)
end

-- Offer robber role to selected player
function PvPBananaHeistEvent.OfferRobberRole(player)
	activeEvent.robber = player

	-- Notify the selected robber
	PvPBananaHeistEvent.NotifyPlayer(player, "🔫 You've been selected as the ROBBER! Do you accept? You have " .. Config.RobberSelectionTimeout .. " seconds to decide. Success = +" .. Config.RobberReward .. " coins, Failure = " .. Config.RobberPenalty .. " coins.")

	-- Notify other players
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			PvPBananaHeistEvent.NotifyPlayer(otherPlayer, "🔫 " .. player.Name .. " has been offered the robber role! Prepare your defenses!")
		end
	end

	-- Start selection timer
	task.spawn(function()
		task.wait(Config.RobberSelectionTimeout)
		if activeEvent.gamePhase == "selection" and not activeEvent.robbberAccepted then
			-- Robber didn't accept, select another player
			PvPBananaHeistEvent.RobberDeclined()
		end
	end)
end

-- Handle robber accepting the role
function PvPBananaHeistEvent.AcceptRobberRole(player)
	if activeEvent.robber ~= player or activeEvent.gamePhase ~= "selection" then return false end

	activeEvent.robbberAccepted = true
	activeEvent.gamePhase = "active"

	-- Set up innocents
	PvPBananaHeistEvent.SetupInnocents()

	-- Start the heist phase
	PvPBananaHeistEvent.StartHeistPhase()

	return true
end

-- Handle robber declining the role
function PvPBananaHeistEvent.RobberDeclined()
	if activeEvent.gamePhase ~= "selection" then return end

	-- Select a different robber
	local players = Players:GetPlayers()
	local remainingPlayers = {}

	for _, player in ipairs(players) do
		if player ~= activeEvent.robber and player.Parent then
			table.insert(remainingPlayers, player)
		end
	end

	if #remainingPlayers == 0 then
		PvPBananaHeistEvent.EndEvent("no_robber")
		return
	end

	-- Try next player
	local nextRobber = remainingPlayers[math.random(1, #remainingPlayers)]
	PvPBananaHeistEvent.OfferRobberRole(nextRobber)
end

-- Set up innocent players with tools
function PvPBananaHeistEvent.SetupInnocents()
	activeEvent.innocents = {}

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= activeEvent.robber then
			table.insert(activeEvent.innocents, player)
			PvPBananaHeistEvent.GiveInnocentTools(player)
		end
	end
end

-- Give tools to innocent players
function PvPBananaHeistEvent.GiveInnocentTools(player)
	local playerTools = {
		bearTraps = Config.InnocentTools.BearTraps,
		tripwireAlarms = Config.InnocentTools.TripwireAlarms,
		flashlights = Config.InnocentTools.Flashlights,
		placedTraps = {},
		placedAlarms = {}
	}

	activeEvent.innocentTools[player.UserId] = playerTools

	PvPBananaHeistEvent.NotifyPlayer(player, "🛡️ INNOCENT ROLE: You received " .. playerTools.bearTraps .. " bear traps, " .. playerTools.tripwireAlarms .. " tripwire alarm, and " .. playerTools.flashlights .. " flashlight! Stop the robber!")
end

-- Start the heist phase
function PvPBananaHeistEvent.StartHeistPhase()
	-- Darken the map
	PvPBananaHeistEvent.SetMapDarkness(true)

	-- Select target for robber
	activeEvent.robberTarget = PvPBananaHeistEvent.SelectRobberTarget()

	-- Notify all players
	PvPBananaHeistEvent.NotifyPlayers("🔫 HEIST PHASE STARTED! The map has darkened. Robber must steal from " .. activeEvent.robberTarget.id .. "!")
	PvPBananaHeistEvent.NotifyPlayer(activeEvent.robber, "🔫 Your target is " .. activeEvent.robberTarget.id .. "! Avoid the innocents and steal the fruit!")

	-- Start steal timer
	task.spawn(function()
		task.wait(Config.StealTimeout)
		if activeEvent.gamePhase == "active" then
			PvPBananaHeistEvent.RobberTimedOut()
		end
	end)

	-- Start event end timer
	task.spawn(function()
		task.wait(Config.EventDuration)
		if activeEvent.isActive then
			PvPBananaHeistEvent.EndEvent("timeout")
		end
	end)
end

-- Select target plot for robber
function PvPBananaHeistEvent.SelectRobberTarget()
	-- Get available plots (integrate with your plot system)
	local availablePlots = {}

	-- Sample plot data
	for i = 1, 5 do
		table.insert(availablePlots, {
			id = "Plot_" .. i,
			position = Vector3.new(math.random(-30, 30), 0, math.random(-30, 30)),
			hasFruit = true
		})
	end

	return availablePlots[math.random(1, #availablePlots)]
end

-- Handle innocent placing bear trap
function PvPBananaHeistEvent.PlaceBearTrap(player, position)
	local playerTools = activeEvent.innocentTools[player.UserId]
	if not playerTools or playerTools.bearTraps <= 0 then return false end

	playerTools.bearTraps = playerTools.bearTraps - 1

	local trap = {
		id = "trap_" .. player.UserId .. "_" .. #playerTools.placedTraps,
		position = position,
		placedBy = player,
		active = true
	}

	table.insert(playerTools.placedTraps, trap)

	PvPBananaHeistEvent.NotifyPlayer(player, "🪤 Bear trap placed! Remaining: " .. playerTools.bearTraps)

	return true
end

-- Handle innocent placing tripwire alarm
function PvPBananaHeistEvent.PlaceTripwireAlarm(player, position)
	local playerTools = activeEvent.innocentTools[player.UserId]
	if not playerTools or playerTools.tripwireAlarms <= 0 then return false end

	playerTools.tripwireAlarms = playerTools.tripwireAlarms - 1

	local alarm = {
		id = "alarm_" .. player.UserId .. "_" .. #playerTools.placedAlarms,
		position = position,
		placedBy = player,
		active = true
	}

	table.insert(playerTools.placedAlarms, alarm)

	PvPBananaHeistEvent.NotifyPlayer(player, "🚨 Tripwire alarm placed! Remaining: " .. playerTools.tripwireAlarms)

	return true
end

-- Handle flashlight catching robber
function PvPBananaHeistEvent.FlashlightCatchRobber(player, targetPlayer, duration)
	if targetPlayer ~= activeEvent.robber or duration < 3 then return false end

	PvPBananaHeistEvent.RobberCaught(player, "flashlight")
	return true
end

-- Check if robber triggered trap
function PvPBananaHeistEvent.CheckRobberTraps(robberPosition)
	if activeEvent.robber == nil then return end

	for playerId, playerTools in pairs(activeEvent.innocentTools) do
		-- Check bear traps
		for i, trap in ipairs(playerTools.placedTraps) do
			if trap.active and (trap.position - robberPosition).Magnitude < 3 then
				trap.active = false
				PvPBananaHeistEvent.RobberCaught(trap.placedBy, "bear_trap")
				return
			end
		end

		-- Check tripwire alarms
		for i, alarm in ipairs(playerTools.placedAlarms) do
			if alarm.active and (alarm.position - robberPosition).Magnitude < 5 then
				alarm.active = false
				PvPBananaHeistEvent.NotifyPlayers("🚨 TRIPWIRE ALARM TRIGGERED! The robber is at " .. tostring(robberPosition) .. "!")
				PvPBananaHeistEvent.RobberCaught(alarm.placedBy, "tripwire")
				return
			end
		end
	end
end

-- Handle robber being caught
function PvPBananaHeistEvent.RobberCaught(caughtBy, method)
	if activeEvent.gamePhase ~= "active" then return end

	activeEvent.gamePhase = "completed"

	-- Robber loses money
	if _G.CoinSystem and _G.CoinSystem.RemoveCoins then
		_G.CoinSystem.RemoveCoins(activeEvent.robber, math.abs(Config.RobberPenalty))
	end

	-- Innocent who caught robber gets reward
	if _G.CoinSystem and _G.CoinSystem.AddCoins then
		_G.CoinSystem.AddCoins(caughtBy, math.floor(Config.RobberReward / 2))
	end

	local methodText = method == "bear_trap" and "bear trap" or method == "tripwire" and "tripwire alarm" or "flashlight"

	PvPBananaHeistEvent.NotifyPlayers("🚨 " .. activeEvent.robber.Name .. " was caught by " .. caughtBy.Name .. "'s " .. methodText .. "! Justice prevails!")
	PvPBananaHeistEvent.NotifyPlayer(activeEvent.robber, "🔫 You were caught! " .. Config.RobberPenalty .. " coins penalty!")
	PvPBananaHeistEvent.NotifyPlayer(caughtBy, "🛡️ You caught the robber! +" .. math.floor(Config.RobberReward / 2) .. " coins reward!")

	PvPBananaHeistEvent.EndEvent("robber_caught")
end

-- Handle robber successfully stealing
function PvPBananaHeistEvent.RobberStealSuccessful()
	if activeEvent.gamePhase ~= "active" then return false end

	activeEvent.gamePhase = "completed"

	-- Robber gets reward
	if _G.CoinSystem and _G.CoinSystem.AddCoins then
		_G.CoinSystem.AddCoins(activeEvent.robber, Config.RobberReward)
	end

	PvPBananaHeistEvent.NotifyPlayers("🔫 " .. activeEvent.robber.Name .. " successfully completed the heist! They escaped with the loot!")
	PvPBananaHeistEvent.NotifyPlayer(activeEvent.robber, "🔫 Heist successful! +" .. Config.RobberReward .. " coins!")

	PvPBananaHeistEvent.EndEvent("heist_successful")
	return true
end

-- Handle robber timing out
function PvPBananaHeistEvent.RobberTimedOut()
	if activeEvent.gamePhase ~= "active" then return end

	activeEvent.gamePhase = "completed"

	-- Robber loses money for timing out
	if _G.CoinSystem and _G.CoinSystem.RemoveCoins then
		_G.CoinSystem.RemoveCoins(activeEvent.robber, math.abs(Config.RobberPenalty))
	end

	PvPBananaHeistEvent.NotifyPlayers("⏰ " .. activeEvent.robber.Name .. " ran out of time! The heist failed!")
	PvPBananaHeistEvent.NotifyPlayer(activeEvent.robber, "⏰ Time's up! " .. Config.RobberPenalty .. " coins penalty!")

	PvPBananaHeistEvent.EndEvent("timeout")
end

-- Set map darkness
function PvPBananaHeistEvent.SetMapDarkness(isDark)
	if isDark then
		Lighting.Brightness = Config.DarknessLevel
		Lighting.Ambient = Color3.fromRGB(50, 50, 70)
	else
		Lighting.Brightness = Config.OriginalBrightness
		Lighting.Ambient = Color3.fromRGB(138, 138, 138)
	end
end

-- End the PvP heist event
function PvPBananaHeistEvent.EndEvent(reason)
	if not activeEvent.isActive then return end

	activeEvent.isActive = false

	-- Restore lighting
	PvPBananaHeistEvent.SetMapDarkness(false)

	local message = ""
	if reason == "robber_caught" then
		message = "🚨 PvP Banana Heist ended! The robber was caught!"
	elseif reason == "heist_successful" then
		message = "🔫 PvP Banana Heist ended! The robber escaped successfully!"
	elseif reason == "timeout" then
		message = "⏰ PvP Banana Heist ended! Time ran out!"
	elseif reason == "no_robber" then
		message = "🔫 PvP Banana Heist cancelled! No one accepted the robber role."
	elseif reason == "no_players" then
		message = "🔫 PvP Banana Heist cancelled! Not enough players."
	end

	PvPBananaHeistEvent.NotifyPlayers(message)

	-- Clean up
	activeEvent.robber = nil
	activeEvent.innocents = {}
	activeEvent.innocentTools = {}
	activeEvent.robberTarget = nil
	activeEvent.gamePhase = "selection"

	print("🔫 PvP Banana Heist event ended: " .. reason)

	-- Clear from random events system
	if _G.RandomEventsSystem then
		_G.RandomEventsSystem.ClearCurrentEvent()
	end
end

-- Get event status for UI systems
function PvPBananaHeistEvent.GetEventStatus()
	return {
		isActive = activeEvent.isActive,
		gamePhase = activeEvent.gamePhase,
		timeRemaining = activeEvent.isActive and math.max(0, Config.EventDuration - (tick() - activeEvent.startTime)) or 0,
		robber = activeEvent.robber and activeEvent.robber.Name or "none",
		innocentCount = #activeEvent.innocents,
		targetPlot = activeEvent.robberTarget and activeEvent.robberTarget.id or "none"
	}
end

-- Notify all players
function PvPBananaHeistEvent.NotifyPlayers(message)
	for _, player in pairs(Players:GetPlayers()) do
		PvPBananaHeistEvent.NotifyPlayer(player, message)
	end
end

-- Notify single player
function PvPBananaHeistEvent.NotifyPlayer(player, message)
	-- Use notification system if available
	if _G.NotificationSystem and _G.NotificationSystem.SendNotification then
		_G.NotificationSystem.SendNotification(player, "PvP Heist", message, 8)
	else
		-- Fallback to print/chat
		print("[PVP HEIST] " .. player.Name .. ": " .. message)
	end
end

-- Initialize the system
PvPBananaHeistEvent.Initialize()

-- Global access
_G.PvPBananaHeistEvent = PvPBananaHeistEvent

return PvPBananaHeistEvent
