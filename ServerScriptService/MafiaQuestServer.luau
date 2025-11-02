-- MafiaQuestServer.lua
-- Place this script in ServerScriptService
-- Handles Mafia Quest logic and RemoteEvent communication

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Load quest data - check multiple possible locations
local MonkeyMafiaQuests

print("=== DEBUGGING MonkeyMafiaQuests SEARCH ===")
print("Looking in ServerScriptService...")
for _, child in pairs(ServerScriptService:GetChildren()) do
	print("- Found:", child.Name, "(" .. child.ClassName .. ")")
end

local possibleLocations = {
	{location = workspace:FindFirstChild("MafiaBoss"), name = "workspace.MafiaBoss"},
	{location = ServerScriptService, name = "ServerScriptService"},
	{location = ReplicatedStorage, name = "ReplicatedStorage"}
}

for _, locData in ipairs(possibleLocations) do
	local location = locData.location
	if location then
		print("Checking", locData.name, "...")
		local questScript = location:FindFirstChild("MonkeyMafiaQuests")
		if questScript then
			print("✅ Found MonkeyMafiaQuests in:", locData.name)
			print("✅ Script type:", questScript.ClassName)

			if questScript.ClassName ~= "ModuleScript" then
				warn("❌ MonkeyMafiaQuests must be a ModuleScript, not a", questScript.ClassName)
				warn("Please convert it to a ModuleScript in Roblox Studio")
				return
			end

			print("✅ Attempting to require MonkeyMafiaQuests...")
			MonkeyMafiaQuests = require(questScript)
			print("✅ Successfully required MonkeyMafiaQuests!")
			break
		else
			print("❌ MonkeyMafiaQuests not found in", locData.name)
		end
	else
		print("❌", locData.name, "location not found")
	end
end

if not MonkeyMafiaQuests then
	warn("MonkeyMafiaQuests module not found! Please place it in:")
	warn("- workspace.MafiaBoss.MonkeyMafiaQuests (ModuleScript)")
	warn("- ServerScriptService.MonkeyMafiaQuests (ModuleScript)")
	warn("- ReplicatedStorage.MonkeyMafiaQuests (ModuleScript)")
	return
end

print("MonkeyMafiaQuests loaded successfully!")

-- Create RemoteEvents folder if it doesn't exist
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

-- Create RemoteEvents
local getMafiaQuestsRemote = Instance.new("RemoteEvent")
getMafiaQuestsRemote.Name = "GetMafiaQuests"
getMafiaQuestsRemote.Parent = remoteEvents

local acceptMafiaQuestRemote = Instance.new("RemoteEvent")
acceptMafiaQuestRemote.Name = "AcceptMafiaQuest"
acceptMafiaQuestRemote.Parent = remoteEvents

-- Track active quests per player
local activeQuests = {}

-- Helper function to get available quests for a player
local function getAvailableQuests(player)
	-- For now, return all quests. You can add logic here to filter based on:
	-- - Player level
	-- - Completed quests
	-- - Active quests
	-- - Time restrictions

	local availableQuests = {}
	for i, quest in ipairs(MonkeyMafiaQuests) do
		-- Skip if player already has this quest active
		if not (activeQuests[player.UserId] and activeQuests[player.UserId][i]) then
			table.insert(availableQuests, {
				Name = quest.Name,
				Index = i,
				Description = quest.Description or "Complete this dangerous task for the Monkey Mafia",
				Difficulty = quest.Difficulty or "Medium"
			})
		end
	end

	return availableQuests
end

-- Handle quest list requests
getMafiaQuestsRemote.OnServerEvent:Connect(function(player)
	local availableQuests = getAvailableQuests(player)
	getMafiaQuestsRemote:FireClient(player, availableQuests)
end)

-- Handle quest acceptance
acceptMafiaQuestRemote.OnServerEvent:Connect(function(player, questIndex, questData)
	if not questIndex or not MonkeyMafiaQuests[questIndex] then
		warn("Invalid quest index:", questIndex)
		return
	end

	-- Initialize player's active quests if needed
	if not activeQuests[player.UserId] then
		activeQuests[player.UserId] = {}
	end

	-- Check if player already has this quest
	if activeQuests[player.UserId][questIndex] then
		warn("Player", player.Name, "already has quest", questIndex)
		return
	end

	-- Add quest to player's active quests
	activeQuests[player.UserId][questIndex] = {
		questData = MonkeyMafiaQuests[questIndex],
		startTime = tick(),
		status = "active"
	}

	-- Set player attribute to track quest
	player:SetAttribute("ActiveMafiaQuest_" .. questIndex, true)

	print("Player", player.Name, "accepted quest:", MonkeyMafiaQuests[questIndex].Name)

	-- You can add additional logic here like:
	-- - Sending quest instructions to player
	-- - Starting quest timers
	-- - Notifying other systems

	-- Example: Send notification to player
	local notificationRemote = remoteEvents:FindFirstChild("ShowNotification")
	if notificationRemote then
		notificationRemote:FireClient(player, {
			title = "Quest Accepted!",
			message = "You have accepted: " .. MonkeyMafiaQuests[questIndex].Name,
			duration = 5,
			type = "success"
		})
	end
end)

-- Function to complete a quest (call this from other systems)
local function completeQuest(player, questIndex, success)
	if not activeQuests[player.UserId] or not activeQuests[player.UserId][questIndex] then
		warn("Player", player.Name, "doesn't have active quest", questIndex)
		return
	end

	local questData = activeQuests[player.UserId][questIndex].questData

	if success then
		-- Execute reward
		if questData.Reward then
			questData.Reward(player)
		end

		print("Player", player.Name, "completed quest:", questData.Name)

		-- Send success notification
		local notificationRemote = remoteEvents:FindFirstChild("ShowNotification")
		if notificationRemote then
			notificationRemote:FireClient(player, {
				title = "Quest Completed!",
				message = "You completed: " .. questData.Name,
				duration = 5,
				type = "success"
			})
		end
	else
		-- Execute failure consequence
		if questData.Fail then
			questData.Fail(player)
		end

		print("Player", player.Name, "failed quest:", questData.Name)

		-- Send failure notification
		local notificationRemote = remoteEvents:FindFirstChild("ShowNotification")
		if notificationRemote then
			notificationRemote:FireClient(player, {
				title = "Quest Failed!",
				message = "You failed: " .. questData.Name,
				duration = 5,
				type = "error"
			})
		end
	end

	-- Remove quest from active quests
	activeQuests[player.UserId][questIndex] = nil
	player:SetAttribute("ActiveMafiaQuest_" .. questIndex, nil)
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	if activeQuests[player.UserId] then
		activeQuests[player.UserId] = nil
	end
end)

-- Export the complete quest function for other scripts
_G.CompleteMafiaQuest = completeQuest

-- Example usage functions (you can call these from other scripts):
--[[
    -- To complete a quest successfully:
    _G.CompleteMafiaQuest(player, 1, true)
    
    -- To fail a quest:
    _G.CompleteMafiaQuest(player, 1, false)
    
    -- To check if player has active quest:
    local hasQuest = player:GetAttribute("ActiveMafiaQuest_1")
--]]

print("Mafia Quest Server initialized!")
