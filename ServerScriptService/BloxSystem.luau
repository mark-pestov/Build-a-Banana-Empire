-- BloxSystem.lua
-- Robust, smooth, and error-free server-side currency management system (Blox)
-- Place in ServerScriptService

-- This script manages the player's Blox (currency) on the server.
-- All references to 'Coin' or 'Coins' have been replaced with 'Blox' for the new currency system.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BloxSystem = {}
local bloxDataStore = DataStoreService:GetDataStore("PlayerBlox")
local playerBlox = {} -- [userId] = amount

-- RemoteEvent for client blox updates
local BloxUpdateEvent = ReplicatedStorage:FindFirstChild("BloxUpdateEvent")
if not BloxUpdateEvent then
	BloxUpdateEvent = Instance.new("RemoteEvent")
	BloxUpdateEvent.Name = "BloxUpdateEvent"
	BloxUpdateEvent.Parent = ReplicatedStorage
end

-- Update all blox displays (client UI and leaderstats)
local function updateBloxDisplay(player)
	local userId = player.UserId
	local bloxs = playerBlox[userId] or 0
	if BloxUpdateEvent then
		BloxUpdateEvent:FireClient(player, bloxs)
	end
	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Blox") then
		player.leaderstats.Blox.Value = bloxs
	end
end

-- Inversion state for admin commands
local inversionActive = false

-- Add blox (atomic, safe, triggers all updates)
function BloxSystem.addBlox(player, amount)
	if not player or type(amount) ~= "number" or amount == 0 then return false end
	local userId = player.UserId
	playerBlox[userId] = playerBlox[userId] or 0
	local finalAmount = inversionActive and -amount or amount
	playerBlox[userId] = math.max(0, playerBlox[userId] + finalAmount)
	updateBloxDisplay(player)
	return true
end

-- Remove blox (atomic, safe)
function BloxSystem.removeBlox(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return false end
	local userId = player.UserId
	playerBlox[userId] = playerBlox[userId] or 0
	if playerBlox[userId] < amount then return false end
	playerBlox[userId] = playerBlox[userId] - amount
	updateBloxDisplay(player)
	return true
end

-- Get blox (safe)
function BloxSystem.getBlox(player)
	if not player then return 0 end
	return playerBlox[player.UserId] or 0
end

-- Set blox (admin/debug only)
function BloxSystem.setBlox(player, amount)
	if not player or type(amount) ~= "number" or amount < 0 then return false end
	local userId = player.UserId
	playerBlox[userId] = amount
	updateBloxDisplay(player)
	return true
end

-- Can afford check
function BloxSystem.canAfford(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return false end
	return BloxSystem.getBlox(player) >= amount
end

-- Data loading
local function loadPlayerData(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return bloxDataStore:GetAsync(userId)
	end)
	playerBlox[userId] = (success and type(data) == "number") and data or 0
	updateBloxDisplay(player)
end

-- Data saving
local function savePlayerData(player)
	local userId = player.UserId
	if playerBlox[userId] ~= nil then
		pcall(function()
			bloxDataStore:SetAsync(userId, playerBlox[userId])
		end)
		playerBlox[userId] = nil
	end
end

-- Periodic auto-save
local function autoSaveAll()
	for userId, bloxs in pairs(playerBlox) do
		pcall(function()
			bloxDataStore:SetAsync(userId, bloxs)
		end)
	end
end

-- Player events
Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(savePlayerData)

-- Auto-save every 5 minutes
spawn(function()
	while true do
		wait(300)
		autoSaveAll()
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
	wait(2)
end)

-- Admin inversion
function BloxSystem.invertRewards()
	inversionActive = true
end
function BloxSystem.revertRewards()
	inversionActive = false
end

-- Global exposure
_G.BloxSystem = BloxSystem

return BloxSystem
