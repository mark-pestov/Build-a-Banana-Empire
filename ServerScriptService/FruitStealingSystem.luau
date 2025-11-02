-- FruitStealingSystem.lua - Fruit Stealing Developer Product System
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

-- Admin/Owner Configuration
local ADMIN_USER_IDS = {
	123456789, -- Replace with actual admin user IDs
	987654321, -- Add more admin IDs as needed
}

local OWNER_USER_IDS = {
	3389224707, -- Replace with actual owner user ID(s)
}

-- Developer Product Configuration
local STEAL_FRUIT_PRODUCT_ID = 0 -- Replace with actual developer product ID from Roblox

-- DataStore for tracking purchases
local stealingDataStore = DataStoreService:GetDataStore("FruitStealing")

-- RemoteEvents
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder")
remoteEventsFolder.Name = "RemoteEvents"
remoteEventsFolder.Parent = ReplicatedStorage

local stealFruitRemote = Instance.new("RemoteEvent")
stealFruitRemote.Name = "StealFruit"
stealFruitRemote.Parent = remoteEventsFolder

local purchaseStealRemote = Instance.new("RemoteEvent")
purchaseStealRemote.Name = "PurchaseSteal"
purchaseStealRemote.Parent = remoteEventsFolder

-- Player stealing data
local playerStealingData = {} -- {userId: {stealsRemaining: number, lastPurchase: number}}

-- Utility functions
local function isAdmin(player)
	local userId = player.UserId
	for _, adminId in ipairs(ADMIN_USER_IDS) do
		if userId == adminId then
			return true
		end
	end
	return false
end

local function isOwner(player)
	local userId = player.UserId
	for _, ownerId in ipairs(OWNER_USER_IDS) do
		if userId == ownerId then
			return true
		end
	end
	return false
end

local function isAuthorized(player)
	return isOwner(player) or isAdmin(player)
end

-- Initialize player stealing data
local function initPlayerStealingData(player)
	local success, savedData = pcall(function()
		return stealingDataStore:GetAsync(player.UserId)
	end)

	local stealingData = {
		stealsRemaining = 0,
		lastPurchase = 0,
		totalSteals = 0
	}

	if success and savedData then
		stealingData = savedData
	end

	playerStealingData[player.UserId] = stealingData
	print("🥷 Initialized stealing data for", player.Name, "- Steals remaining:", stealingData.stealsRemaining)
end

-- Save player stealing data
local function savePlayerStealingData(player)
	local data = playerStealingData[player.UserId]
	if not data then return end

	pcall(function()
		stealingDataStore:SetAsync(player.UserId, data)
	end)
end

-- Get fruit owner from plot system
local function getFruitOwner(fruit)
	if not fruit or not fruit.Parent then return nil end

	-- Check if fruit has owner attribute
	local ownerUserId = fruit:GetAttribute("OwnerUserId")
	if ownerUserId then
		return Players:GetPlayerByUserId(ownerUserId)
	end

	-- Try to find owner through plot system
	if _G.PlotSystem and _G.PlotSystem.getPlotOwner then
		local plotOwner = _G.PlotSystem.getPlotOwner(fruit.Position)
		return plotOwner
	end

	return nil
end

-- Check if player can steal from target plot
local function canStealFruit(stealer, targetFruit)
	local fruitOwner = getFruitOwner(targetFruit)

	-- Can't steal if no owner found
	if not fruitOwner then
		return false, "Cannot determine fruit owner"
	end

	-- Can't steal from yourself
	if stealer.UserId == fruitOwner.UserId then
		return false, "Cannot steal from your own plot"
	end

	-- Admins and owners can always steal
	if isAuthorized(stealer) then
		return true, "Admin/Owner privilege"
	end

	-- Check if player has steals remaining
	local stealingData = playerStealingData[stealer.UserId]
	if not stealingData or stealingData.stealsRemaining <= 0 then
		return false, "No steals remaining. Purchase steal ability!"
	end

	return true, "Steal authorized"
end

-- Process fruit stealing
local function processFruitSteal(stealer, targetFruit)
	local canSteal, reason = canStealFruit(stealer, targetFruit)

	if not canSteal then
		if _G.showNotification then
			_G.showNotification(stealer, "❌ " .. reason, "error")
		end
		return false
	end

	local fruitOwner = getFruitOwner(targetFruit)
	local stealingData = playerStealingData[stealer.UserId]

	-- Deduct steal if not admin/owner
	if not isAuthorized(stealer) then
		stealingData.stealsRemaining = stealingData.stealsRemaining - 1
		stealingData.totalSteals = stealingData.totalSteals + 1
		savePlayerStealingData(stealer)
	end

	-- Log the steal
	print("🥷", stealer.Name, "stole fruit from", fruitOwner.Name, "- Reason:", reason)

	-- Notify players
	if _G.showNotification then
		_G.showNotification(stealer, "🥷 Successfully stole " .. targetFruit.Name .. "!", "success")
		_G.showNotification(fruitOwner, "🚨 " .. stealer.Name .. " stole your " .. targetFruit.Name .. "!", "warning")
	end

	-- Add visual effect
	createStealEffect(targetFruit)

	return true
end

-- Create stealing visual effect
function createStealEffect(fruit)
	if not fruit or not fruit:FindFirstChild("Handle") then return end

	local handle = fruit.Handle

	-- Create smoke effect
	local attachment = Instance.new("Attachment")
	attachment.Parent = handle

	local smoke = Instance.new("ParticleEmitter")
	smoke.Parent = attachment
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Lifetime = NumberRange.new(0.5, 1.5)
	smoke.Rate = 50
	smoke.SpreadAngle = Vector2.new(45, 45)
	smoke.Speed = NumberRange.new(5, 10)
	smoke.Color = ColorSequence.new(Color3.fromRGB(50, 50, 50))

	-- Create poof sound effect
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.5
	sound.Parent = handle
	sound:Play()

	-- Clean up effects
	task.wait(2)
	smoke.Enabled = false
	task.wait(2)
	attachment:Destroy()
	sound:Destroy()
end

-- Handle developer product purchase
local function onPromptPurchaseFinished(player, productId, isPurchased)
	if productId ~= STEAL_FRUIT_PRODUCT_ID then return end

	if isPurchased then
		local stealingData = playerStealingData[player.UserId]
		if stealingData then
			stealingData.stealsRemaining = stealingData.stealsRemaining + 1
			stealingData.lastPurchase = os.time()
			savePlayerStealingData(player)

			if _G.showNotification then
				_G.showNotification(player, "🥷 Steal ability purchased!", "success")
				_G.showNotification(player, "Steals remaining: " .. stealingData.stealsRemaining, "info")
			end

			print("💰", player.Name, "purchased steal ability - Total steals:", stealingData.stealsRemaining)
		end
	else
		if _G.showNotification then
			_G.showNotification(player, "❌ Purchase cancelled", "warning")
		end
	end
end

-- Remote event handlers
stealFruitRemote.OnServerEvent:Connect(function(player, targetFruit)
	-- Validate fruit
	if not targetFruit or not targetFruit.Parent then
		if _G.showNotification then
			_G.showNotification(player, "❌ Invalid fruit target", "error")
		end
		return
	end

	-- Use existing harvest system with steal flag
	local harvestRemote = remoteEventsFolder:FindFirstChild("HarvestFruit")
	if harvestRemote then
		harvestRemote:FireServer(player, targetFruit, true) -- true indicates this is a steal
	else
		warn("HarvestFruit remote not found")
	end
end)

purchaseStealRemote.OnServerEvent:Connect(function(player)
	if STEAL_FRUIT_PRODUCT_ID == 0 then
		if _G.showNotification then
			_G.showNotification(player, "❌ Steal product not configured", "error")
		end
		return
	end

	-- Prompt purchase
	MarketplaceService:PromptProductPurchase(player, STEAL_FRUIT_PRODUCT_ID)
end)

-- Connect marketplace events
MarketplaceService.PromptProductPurchaseFinished:Connect(onPromptPurchaseFinished)

-- Player events
Players.PlayerAdded:Connect(function(player)
	initPlayerStealingData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerStealingData(player)
	playerStealingData[player.UserId] = nil
end)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
	initPlayerStealingData(player)
end

-- Global functions for other scripts
_G.FruitStealingSystem = {
	canStealFruit = canStealFruit,
	processFruitSteal = processFruitSteal,
	isAuthorized = isAuthorized,
	isAdmin = isAdmin,
	isOwner = isOwner,
	getStealingData = function(player)
		return playerStealingData[player.UserId]
	end
}

print("🥷 Fruit Stealing System Loaded!")
print("   - Developer product stealing")
print("   - Admin/Owner privileges")
print("   - Anti-self-steal protection")
print("   - Visual effects and notifications")

-- DEPRECATED: Fruit/farming logic removed for city/empire game.
return
