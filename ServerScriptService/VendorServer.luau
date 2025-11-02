-- VendorServer.lua
-- Server-side vendor system for PokerproA4 NPC
-- Handles vendor dialogs, fruit selling, and seed purchasing

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VendorServer = {}

-- Configuration
local Config = {
	VendorName = "PokerproA4",
	VendorDisplayName = "Fruit Merchant PokerproA4",

	-- Fruit prices (base prices, can be modified by events)
	FruitPrices = {
		Banana = 10,
		Apple = 15,
		Orange = 12,
		Grape = 20,
		Strawberry = 25
	},

	-- Seed prices (what players pay to buy seeds)
	SeedPrices = {
		Standard = 50,
		Basic = 150,
		Solid = 500,
		Legendary = 2000,
		Mythical = 8000,
		Celestial = 25000,
		Ascended = 75000,
		Godly = 200000,
		Transcendent = 1000000
	}
}

-- Create RemoteEvent for vendor interactions
local function setupRemoteEvents()
	local vendorRemote = ReplicatedStorage:FindFirstChild("VendorInteraction")
	if not vendorRemote then
		vendorRemote = Instance.new("RemoteEvent")
		vendorRemote.Name = "VendorInteraction"
		vendorRemote.Parent = ReplicatedStorage
	end
	return vendorRemote
end

-- Get player's fruit inventory (placeholder - integrate with your inventory system)
local function getPlayerInventory(player)
	-- This should integrate with your existing inventory system
	-- For now, returning a sample inventory
	return {
		Banana = math.random(0, 50),
		Apple = math.random(0, 30),
		Orange = math.random(0, 25)
	}
end

-- Get player's coins (integrate with your CoinSystem)
local function getPlayerCoins(player)
	if _G.CoinSystem and _G.CoinSystem.GetCoins then
		return _G.CoinSystem.GetCoins(player)
	end
	return 0
end

-- Add coins to player (integrate with your CoinSystem)
local function addPlayerCoins(player, amount)
	if _G.CoinSystem and _G.CoinSystem.AddCoins then
		_G.CoinSystem.AddCoins(player, amount)
		return true
	end
	return false
end

-- Remove coins from player (integrate with your CoinSystem)
local function removePlayerCoins(player, amount)
	if _G.CoinSystem and _G.CoinSystem.RemoveCoins then
		return _G.CoinSystem.RemoveCoins(player, amount)
	end
	return false
end

-- Main vendor dialog
function VendorServer.GetMainDialog()
	return {
		text = "Welcome to my fruit stand! I buy fresh fruit and sell premium banana seeds. What can I do for you today?",
		options = {
			{
				text = "💰 Sell Fruit",
				action = "sell_menu"
			},
			{
				text = "🌱 Buy Seeds",
				action = "seed_menu"
			},
			{
				text = "📊 Check Prices",
				action = "price_menu"
			},
			{
				text = "👋 Nothing, thanks",
				action = "close"
			}
		}
	}
end

-- Sell fruit menu
function VendorServer.GetSellMenu(player)
	local inventory = getPlayerInventory(player)
	local hasFruit = false

	for _, amount in pairs(inventory) do
		if amount > 0 then
			hasFruit = true
			break
		end
	end

	if not hasFruit then
		return {
			text = "Looks like you don't have any fruit to sell! Come back when you've harvested some.",
			options = {
				{
					text = "🔙 Back to Main Menu",
					action = "main_menu"
				}
			}
		}
	end

	local options = {}
	local totalValue = 0

	-- Individual fruit selling options
	for fruitType, amount in pairs(inventory) do
		if amount > 0 and Config.FruitPrices[fruitType] then
			local value = Config.FruitPrices[fruitType] * amount
			totalValue = totalValue + value
			table.insert(options, {
				text = string.format("Sell %d %s(s) - %d coins", amount, fruitType, value),
				action = "sell_fruit",
				data = {fruitType = fruitType, amount = amount, value = value}
			})
		end
	end

	-- Sell all option
	if totalValue > 0 then
		table.insert(options, {
			text = string.format("💎 Sell All Fruit - %d coins", totalValue),
			action = "sell_all",
			data = {value = totalValue}
		})
	end

	table.insert(options, {
		text = "🔙 Back to Main Menu",
		action = "main_menu"
	})

	return {
		text = "I'll buy your fresh fruit at fair prices! What would you like to sell?",
		options = options
	}
end

-- Seed purchase menu
function VendorServer.GetSeedMenu(player)
	local playerCoins = getPlayerCoins(player)

	local options = {}

	-- Add seed purchase options
	for seedType, price in pairs(Config.SeedPrices) do
		local canAfford = playerCoins >= price
		local priceText = canAfford and string.format("%d coins", price) or string.format("%d coins (Can't afford)", price)

		table.insert(options, {
			text = string.format("%s Seed - %s", seedType, priceText),
			action = canAfford and "buy_seed" or "cant_afford",
			data = {seedType = seedType, price = price}
		})
	end

	table.insert(options, {
		text = "🔙 Back to Main Menu",
		action = "main_menu"
	})

	return {
		text = string.format("I have premium banana seeds for sale! You have %d coins.", playerCoins),
		options = options
	}
end

-- Price list menu
function VendorServer.GetPriceMenu()
	local priceText = "📊 CURRENT PRICES 📊\n\n🍎 FRUIT BUYING PRICES:\n"

	for fruitType, price in pairs(Config.FruitPrices) do
		priceText = priceText .. string.format("  %s: %d coins each\n", fruitType, price)
	end

	priceText = priceText .. "\n🌱 SEED SELLING PRICES:\n"

	for seedType, price in pairs(Config.SeedPrices) do
		priceText = priceText .. string.format("  %s: %d coins\n", seedType, price)
	end

	return {
		text = priceText,
		options = {
			{
				text = "🔙 Back to Main Menu",
				action = "main_menu"
			}
		}
	}
end

-- Handle vendor interactions
function VendorServer.HandleVendorInteraction(player, action, data)
	local vendorRemote = ReplicatedStorage:FindFirstChild("VendorInteraction")
	if not vendorRemote then return end

	local vendorData = {
		name = Config.VendorDisplayName,
		image = "rbxasset://textures/face.png" -- You can customize this
	}

	if action == "StartDialog" then
		local dialogData = VendorServer.GetMainDialog()
		vendorRemote:FireClient(player, "ShowDialog", vendorData, dialogData)

	elseif action == "main_menu" then
		local dialogData = VendorServer.GetMainDialog()
		vendorRemote:FireClient(player, "UpdateDialog", dialogData)

	elseif action == "sell_menu" then
		local dialogData = VendorServer.GetSellMenu(player)
		vendorRemote:FireClient(player, "UpdateDialog", dialogData)

	elseif action == "seed_menu" then
		local dialogData = VendorServer.GetSeedMenu(player)
		vendorRemote:FireClient(player, "UpdateDialog", dialogData)

	elseif action == "price_menu" then
		local dialogData = VendorServer.GetPriceMenu()
		vendorRemote:FireClient(player, "UpdateDialog", dialogData)

	elseif action == "sell_fruit" then
		VendorServer.HandleFruitSale(player, data)

	elseif action == "sell_all" then
		VendorServer.HandleSellAll(player)

	elseif action == "buy_seed" then
		VendorServer.HandleSeedPurchase(player, data)

	elseif action == "cant_afford" then
		local dialogData = {
			text = "Sorry, you don't have enough coins for that seed! Come back when you've earned more.",
			options = {
				{
					text = "🔙 Back to Seeds",
					action = "seed_menu"
				}
			}
		}
		vendorRemote:FireClient(player, "UpdateDialog", dialogData)
	end
end

-- Handle fruit sale
function VendorServer.HandleFruitSale(player, data)
	local vendorRemote = ReplicatedStorage:FindFirstChild("VendorInteraction")
	if not vendorRemote then return end

	-- Here you would integrate with your inventory system to remove the fruit
	-- For now, just add the coins
	if addPlayerCoins(player, data.value) then
		local dialogData = {
			text = string.format("Thank you! I've bought your %d %s(s) for %d coins.", data.amount, data.fruitType, data.value),
			options = {
				{
					text = "💰 Sell More Fruit",
					action = "sell_menu"
				},
				{
					text = "🔙 Back to Main Menu",
					action = "main_menu"
				}
			}
		}
		vendorRemote:FireClient(player, "UpdateDialog", dialogData)
	else
		local dialogData = {
			text = "Sorry, there was an error processing your sale. Please try again.",
			options = {
				{
					text = "🔙 Back to Main Menu",
					action = "main_menu"
				}
			}
		}
		vendorRemote:FireClient(player, "UpdateDialog", dialogData)
	end
end

-- Handle sell all
function VendorServer.HandleSellAll(player)
	local vendorRemote = ReplicatedStorage:FindFirstChild("VendorInteraction")
	if not vendorRemote then return end

	local inventory = getPlayerInventory(player)
	local totalValue = 0
	local itemsSold = {}

	for fruitType, amount in pairs(inventory) do
		if amount > 0 and Config.FruitPrices[fruitType] then
			local value = Config.FruitPrices[fruitType] * amount
			totalValue = totalValue + value
			table.insert(itemsSold, string.format("%d %s(s)", amount, fruitType))
		end
	end

	if totalValue > 0 and addPlayerCoins(player, totalValue) then
		local soldText = table.concat(itemsSold, ", ")
		local dialogData = {
			text = string.format("Excellent! I've bought all your fruit (%s) for %d coins total!", soldText, totalValue),
			options = {
				{
					text = "🌱 Buy Seeds",
					action = "seed_menu"
				},
				{
					text = "🔙 Back to Main Menu",
					action = "main_menu"
				}
			}
		}
		vendorRemote:FireClient(player, "UpdateDialog", dialogData)
	end
end

-- Handle seed purchase
function VendorServer.HandleSeedPurchase(player, data)
	local vendorRemote = ReplicatedStorage:FindFirstChild("VendorInteraction")
	if not vendorRemote then return end

	if removePlayerCoins(player, data.price) then
		-- Here you would add the seed to the player's inventory

		-- Award Battle Pass XP for seed purchase (treat seeds as fruit purchases)
		local seedTier = data.seedType:lower()
		if _G.BattlePassSystem and _G.BattlePassSystem.onFruitPurchase then
			_G.BattlePassSystem.onFruitPurchase(player, seedTier)
		end

		-- Fire FruitPurchased event for other systems
		local fruitPurchasedRemote = ReplicatedStorage:FindFirstChild("RemoteEvents") 
		if fruitPurchasedRemote then
			fruitPurchasedRemote = fruitPurchasedRemote:FindFirstChild("FruitPurchased")
			if fruitPurchasedRemote then
				fruitPurchasedRemote:FireServer(player, seedTier)
			end
		end

		local dialogData = {
			text = string.format("Great choice! You've purchased a %s seed for %d coins. Plant it and watch it grow!", data.seedType, data.price),
			options = {
				{
					text = "🌱 Buy Another Seed",
					action = "seed_menu"
				},
				{
					text = "🔙 Back to Main Menu",
					action = "main_menu"
				}
			}
		}
		vendorRemote:FireClient(player, "UpdateDialog", dialogData)
	else
		local dialogData = {
			text = "You don't have enough coins for that seed! Sell some fruit first.",
			options = {
				{
					text = "💰 Sell Fruit",
					action = "sell_menu"
				},
				{
					text = "🔙 Back to Main Menu",
					action = "main_menu"
				}
			}
		}
		vendorRemote:FireClient(player, "UpdateDialog", dialogData)
	end
end

-- Initialize vendor system
function VendorServer.Initialize()
	local vendorRemote = setupRemoteEvents()

	vendorRemote.OnServerEvent:Connect(function(player, action, data)
		VendorServer.HandleVendorInteraction(player, action, data)
	end)

	print("Vendor system initialized for " .. Config.VendorName)
end

-- Start the vendor system
VendorServer.Initialize()

-- Global access
_G.VendorServer = VendorServer

return VendorServer
