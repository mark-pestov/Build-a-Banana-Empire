-- MafiaQuestCommands.lua
-- Place this script in ServerScriptService
-- Admin commands to manually complete/fail quests for testing

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Admin user IDs (add your Roblox user ID here)
local ADMIN_IDS = {
	3389224707, -- Replace with your actual Roblox User ID
	-- Add more admin IDs here
}

local function isAdmin(player)
	for _, id in ipairs(ADMIN_IDS) do
		if player.UserId == id then
			return true
		end
	end
	return false
end

-- Chat commands for quest completion
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if not isAdmin(player) then return end

		local args = string.split(message, " ")
		local command = args[1]:lower()

		if command == "/completequest" then
			local questIndex = tonumber(args[2])
			if questIndex and _G.CompleteMafiaQuest then
				_G.CompleteMafiaQuest(player, questIndex, true)
				print("Admin", player.Name, "completed quest", questIndex)
			else
				print("Usage: /completequest [questNumber]")
			end

		elseif command == "/failquest" then
			local questIndex = tonumber(args[2])
			if questIndex and _G.CompleteMafiaQuest then
				_G.CompleteMafiaQuest(player, questIndex, false)
				print("Admin", player.Name, "failed quest", questIndex)
			else
				print("Usage: /failquest [questNumber]")
			end

		elseif command == "/quests" then
			print("=== MAFIA QUEST COMMANDS ===")
			print("/completequest [questNumber] - Complete a quest")
			print("/failquest [questNumber] - Fail a quest")
			print("/addcoins [amount] - Add coins directly (debug)")
			print("/checkcoins - Check current coin balance")
			print("===============================")

		elseif command == "/addcoins" then
			local amount = tonumber(args[2])
			if amount and _G.CoinSystem and _G.CoinSystem.addCoins then
				print("🪙 ADMIN DEBUG: Attempting to add", amount, "coins to", player.Name)
				local success = _G.CoinSystem.addCoins(player, amount)
				if success then
					print("🪙 ADMIN DEBUG: Successfully added", amount, "coins to", player.Name)
				else
					print("🪙 ADMIN DEBUG: Failed to add coins to", player.Name)
				end
			else
				print("Usage: /addcoins [amount] or CoinSystem not available")
			end

		elseif command == "/checkcoins" then
			if _G.CoinSystem and _G.CoinSystem.getCoins then
				local coins = _G.CoinSystem.getCoins(player)
				print("🪙", player.Name, "has", coins, "coins")
			else
				print("CoinSystem not available")
			end
		end
	end)
end)

print("🎮 Mafia Quest Commands loaded!")
print("Admin commands: /completequest [1-10], /failquest [1-10], /quests")
