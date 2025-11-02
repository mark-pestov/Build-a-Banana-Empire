-- ServerScriptService/HarvestFruitServer.lua (Server Script)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

-- DataStore for saving player inventories
local inventoryDataStore = DataStoreService:GetDataStore("PlayerInventories")

-- Wait for manually created RemoteEvents
-- Note: RemoteEvents folder and HarvestFruit RemoteEvent should be created manually in ReplicatedStorage
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local harvestFruitRemote = remoteEventsFolder:WaitForChild("HarvestFruit")

-- Player inventory system
local playerInventories = {}

-- Inventory structure now includes weight tracking
local function createNewInventory()
	return {
		bananas = 0,
		goldenBananas = 0,
		rainbowBananas = 0,
		totalWeight = 0,
		fruits = {} -- Array to store individual fruits with their weights
	}
end

-- Initialize player inventory when they join
local function initPlayerInventory(player)
	local inventory = createNewInventory()

	-- Try to load saved data
	local success, savedData = pcall(function()
		return inventoryDataStore:GetAsync(player.UserId)
	end)

	if success and savedData then
		-- Migrate old inventory format if needed
		if savedData.fruits == nil then
			savedData.fruits = {}
			savedData.totalWeight = 0
		end
		inventory = savedData
		print("Loaded saved inventory for", player.Name, "- Bananas:", inventory.bananas, "Golden:", inventory.goldenBananas, "Rainbow:", inventory.rainbowBananas, "Total Weight:", inventory.totalWeight, "kg")
	else
		print("Using default inventory for", player.Name, "(new player or failed to load)")
	end

	playerInventories[player.UserId] = inventory
	print("Initialized inventory for player:", player.Name)
end

-- Clean up player inventory when they leave
local function cleanupPlayerInventory(player)
	-- Save player data before cleanup
	local inventory = playerInventories[player.UserId]
	if inventory then
		local success, errorMessage = pcall(function()
			inventoryDataStore:SetAsync(player.UserId, inventory)
		end)
		if success then
			print("Saved inventory for", player.Name, "- Bananas:", inventory.bananas, "Golden:", inventory.goldenBananas, "Rainbow:", inventory.rainbowBananas, "Total Weight:", inventory.totalWeight .. "kg")
		else
			warn("Failed to save inventory for", player.Name, ":", errorMessage)
		end
	end

	playerInventories[player.UserId] = nil
	print("Cleaned up inventory for player:", player.Name)
end

-- Connect player events
Players.PlayerAdded:Connect(initPlayerInventory)
Players.PlayerRemoving:Connect(cleanupPlayerInventory)

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
	initPlayerInventory(player)
end

-- Function to validate fruit and player
local function validateHarvestRequest(player, fruit, allowStealing)
	-- Check if player exists and has inventory
	if not player or not playerInventories[player.UserId] then
		warn("Invalid player or no inventory found for:", player and player.Name or "nil")
		return false
	end

	-- Check if fruit exists and is grown
	if not fruit or not fruit.Parent then
		warn("Invalid fruit object for player:", player.Name)
		return false
	end

	-- Check if fruit is actually grown
	local isGrown = fruit:GetAttribute("IsGrown")
	if not isGrown then
		warn("Player", player.Name, "tried to harvest unripe fruit")
		return false
	end

	-- Check if fruit is in the correct folder
	local fruitsFolder = fruit.Parent
	if not fruitsFolder or fruitsFolder.Name ~= "GrowingBananas" then
		warn("Player", player.Name, "tried to harvest fruit not in GrowingBananas folder")
		return false
	end

	-- Check ownership if not stealing (regular harvest)
	if not allowStealing then
		local fruitOwnerId = fruit:GetAttribute("OwnerUserId")
		if fruitOwnerId and fruitOwnerId ~= player.UserId then
			-- Check if player is admin/owner
			if _G.FruitStealingSystem and _G.FruitStealingSystem.isAuthorized(player) then
				-- Admins can harvest without stealing
				return true
			else
				warn("Player", player.Name, "tried to harvest fruit belonging to UserId:", fruitOwnerId)
				return false
			end
		end
	end

	return true
end

-- Function to add fruit to player inventory
local function addFruitToInventory(player, fruitType, fruitName, weight)
	local inventory = playerInventories[player.UserId]
	if not inventory then return false end

	-- Add individual fruit to fruits array
	table.insert(inventory.fruits, {
		name = fruitName,
		type = fruitType,
		weight = weight,
		timestamp = os.time()
	})

	-- Update totals
	inventory.totalWeight = inventory.totalWeight + weight

	-- Notify quest system
	if _G.QuestSystem then
		_G.QuestSystem.onBananaHarvested(player)
	end

	if fruitType == "rainbow" then
		inventory.rainbowBananas = inventory.rainbowBananas + 1
		print("Added Rainbow Banapple to", player.Name, "- Weight:", weight .. "kg", "Total:", inventory.rainbowBananas, "Total Weight:", inventory.totalWeight .. "kg")

	elseif fruitType == "golden" then
		inventory.goldenBananas = inventory.goldenBananas + 1
		print("Added Golden Banapple to", player.Name, "- Weight:", weight .. "kg", "Total:", inventory.goldenBananas, "Total Weight:", inventory.totalWeight .. "kg")

	else -- normal banana
		inventory.bananas = inventory.bananas + 1
		print("Added Banapple to", player.Name, "- Weight:", weight .. "kg", "Total:", inventory.bananas, "Total Weight:", inventory.totalWeight .. "kg")
	end

	return true
end

-- Function to create harvest effect
local function createHarvestEffect(fruit)
	-- Find the main part for effect positioning
	local mainPart = fruit
	if fruit:IsA("Model") then
		for _, child in ipairs(fruit:GetChildren()) do
			if child:IsA("BasePart") then
				mainPart = child
				break
			end
		end
	end

	if not mainPart or not mainPart:IsA("BasePart") then return end

	-- Create sparkle effect
	local attachment = Instance.new("Attachment")
	attachment.Parent = mainPart

	local sparkles = Instance.new("Sparkles")
	sparkles.Parent = mainPart
	sparkles.SparkleColor = Color3.fromRGB(255, 255, 0)

	-- Remove effect after short duration
	game:GetService("Debris"):AddItem(sparkles, 0.5)
	game:GetService("Debris"):AddItem(attachment, 0.5)

	-- Play collection sound (optional)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav" -- Default Roblox sound
	sound.Volume = 0.5
	sound.Parent = mainPart
	sound:Play()

	game:GetService("Debris"):AddItem(sound, 2)
end

-- Main harvest handler
harvestFruitRemote.OnServerEvent:Connect(function(player, fruit, isSteal)
	print("Harvest request from", player.Name, "for fruit:", fruit and fruit.Name or "nil", "- Steal:", isSteal or false)

	-- Report action to anti-bot system
	if _G.AFKSystem and _G.AFKSystem.reportAction then
		_G.AFKSystem.reportAction(player, isSteal and "steal" or "harvest", {
			fruitName = fruit and fruit.Name or "unknown"
		})
	end

	-- If this is a steal attempt, validate through stealing system
	if isSteal then
		if not _G.FruitStealingSystem then
			warn("Fruit stealing system not loaded")
			return
		end

		local canSteal, reason = _G.FruitStealingSystem.canStealFruit(player, fruit)
		if not canSteal then
			if _G.showNotification then
				_G.showNotification(player, "❌ " .. reason, "error")
			end
			return
		end

		-- Process the steal (this handles notifications and effects)
		local success = _G.FruitStealingSystem.processFruitSteal(player, fruit)
		if not success then
			return
		end
	end

	-- Validate the harvest request (normal validation for non-steal or after steal validation)
	if not validateHarvestRequest(player, fruit, isSteal) then
		return
	end

	-- Get fruit information
	local fruitName = fruit.Name
	local weight = fruit:GetAttribute("Weight") or 8.5 -- Default weight if not set

	-- Determine fruit type
	local fruitType = "normal"
	local fruitNameLower = fruitName:lower()

	if string.find(fruitNameLower, "rainbow") then
		fruitType = "rainbow"
	elseif string.find(fruitNameLower, "gold") then
		fruitType = "golden"
	end

	-- Create harvest effect before removing fruit
	createHarvestEffect(fruit)

	-- Add to player inventory with weight
	local success = addFruitToInventory(player, fruitType, fruitName, weight)

	if success then
		-- Remove fruit from world after short delay (for effect)
		task.wait(0.2)
		if fruit and fruit.Parent then
			fruit:Destroy()
			print("Successfully harvested", fruitName, "for", player.Name, "- Weight:", weight .. "kg")
		end
	else
		warn("Failed to add fruit to inventory for", player.Name)
	end
end)

print("Harvest Fruit Server Script Loaded.")

-- Function to manually save a player's inventory
local function savePlayerInventory(player)
	local inventory = playerInventories[player.UserId]
	if not inventory then return false end

	local success, errorMessage = pcall(function()
		inventoryDataStore:SetAsync(player.UserId, inventory)
	end)

	if success then
		print("Manually saved inventory for", player.Name)
		return true
	else
		warn("Failed to manually save inventory for", player.Name, ":", errorMessage)
		return false
	end
end

-- Function to get a player's inventory (useful for other scripts)
local function getPlayerInventory(player)
	return playerInventories[player.UserId]
end

-- Function to get total fruits for a player
local function getTotalFruits(player)
	local inventory = playerInventories[player.UserId]
	if not inventory then return 0 end

	return inventory.bananas + inventory.goldenBananas + inventory.rainbowBananas
end

-- Function to get total weight for a player
local function getTotalWeight(player)
	local inventory = playerInventories[player.UserId]
	if not inventory then return 0 end

	return inventory.totalWeight
end

-- Function to get heaviest fruit for a player
local function getHeaviestFruit(player)
	local inventory = playerInventories[player.UserId]
	if not inventory or #inventory.fruits == 0 then return nil end

	local heaviest = inventory.fruits[1]
	for _, fruit in ipairs(inventory.fruits) do
		if fruit.weight > heaviest.weight then
			heaviest = fruit
		end
	end

	return heaviest
end

-- Auto-save all player inventories every 5 minutes
task.spawn(function()
	while true do
		task.wait(300) -- 5 minutes
		print("Auto-saving all player inventories...")

		for userId, inventory in pairs(playerInventories) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				local success, errorMessage = pcall(function()
					inventoryDataStore:SetAsync(userId, inventory)
				end)

				if success then
					print("Auto-saved inventory for", player.Name, "- Total Weight:", inventory.totalWeight .. "kg")
				else
					warn("Failed to auto-save inventory for", player.Name, ":", errorMessage)
				end
			end
		end

		print("Auto-save completed.")
	end
end)

-- Save all inventories when server is shutting down
game:BindToClose(function()
	print("Server shutting down, saving all inventories...")

	for userId, inventory in pairs(playerInventories) do
		local player = Players:GetPlayerByUserId(userId)
		local playerName = player and player.Name or ("UserId:" .. userId)

		local success, errorMessage = pcall(function()
			inventoryDataStore:SetAsync(userId, inventory)
		end)

		if success then
			print("Shutdown save completed for", playerName)
		else
			warn("Failed to save inventory during shutdown for", playerName, ":", errorMessage)
		end
	end

	task.wait(1) -- Give time for saves to complete
	print("All inventories saved during shutdown.")
end)

-- NOTE: Fruit growth (size, animation, reveal) is handled by PlotBananaGrowth.luau only.
-- This script only checks IsGrown and manages harvesting logic.
-- Do not add fruit growth or animation logic here.

-- DEPRECATED: Harvesting removed for city/empire game.
return
