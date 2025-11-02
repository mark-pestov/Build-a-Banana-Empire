-- FruitVendorNPC.lua - Interactive Fruit Vendor with Dialog System
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- NPC Configuration
local NPC_NAME = "Berry the Fruit Vendor"
local INTERACTION_DISTANCE = 10 -- studs
local FRUIT_PRICES = {
	["banapple"] = 25,
	["golden banapple"] = 75,
	["rainbow banapple"] = 150,
	["large banapple"] = 40,
	["mini banapple"] = 15
}

-- Store active interactions
local activeInteractions = {} -- {userId: {npc: Model, startTime: number}}
local proximityPlayers = {} -- {userId: bool} -- Players near NPC

-- RemoteEvents
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder")
remoteEventsFolder.Name = "RemoteEvents"
remoteEventsFolder.Parent = ReplicatedStorage

local showInteractionRemote = Instance.new("RemoteEvent")
showInteractionRemote.Name = "ShowVendorInteraction"
showInteractionRemote.Parent = remoteEventsFolder

local hideInteractionRemote = Instance.new("RemoteEvent")
hideInteractionRemote.Name = "HideVendorInteraction"
hideInteractionRemote.Parent = remoteEventsFolder

local vendorInteractRemote = Instance.new("RemoteEvent")
vendorInteractRemote.Name = "VendorInteract"
vendorInteractRemote.Parent = remoteEventsFolder

local vendorDialogRemote = Instance.new("RemoteEvent")
vendorDialogRemote.Name = "VendorDialog"
vendorDialogRemote.Parent = remoteEventsFolder

local openSeedShopRemote = Instance.new("RemoteEvent")
openSeedShopRemote.Name = "OpenSeedShop"
openSeedShopRemote.Parent = remoteEventsFolder

local sellFruitRemote = Instance.new("RemoteEvent")
sellFruitRemote.Name = "SellFruit"
sellFruitRemote.Parent = remoteEventsFolder

local getFruitPriceRemote = Instance.new("RemoteFunction")
getFruitPriceRemote.Name = "GetFruitPrice"
getFruitPriceRemote.Parent = remoteEventsFolder

-- Create the NPC
local function createVendorNPC()
	local npc = Instance.new("Model")
	npc.Name = NPC_NAME

	-- NPC Body
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Position = Vector3.new(0, 10, 50) -- Adjust position as needed
	torso.Material = Enum.Material.Plastic
	torso.Color = Color3.fromRGB(255, 220, 177) -- Skin color
	torso.Anchored = true
	torso.Parent = npc

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.Position = torso.Position + Vector3.new(0, 1.5, 0)
	head.Material = Enum.Material.Plastic
	head.Color = Color3.fromRGB(255, 220, 177)
	head.Shape = Enum.PartType.Block
	head.Anchored = true
	head.Parent = npc

	-- Face
	local face = Instance.new("Decal")
	face.Name = "Face"
	face.Face = Enum.NormalId.Front
	face.Texture = "rbxasset://textures/face.png"
	face.Parent = head

	-- Arms
	for i, side in ipairs({"Left", "Right"}) do
		local arm = Instance.new("Part")
		arm.Name = side .. "Arm"
		arm.Size = Vector3.new(1, 2, 1)
		arm.Position = torso.Position + Vector3.new(i == 1 and -1.5 or 1.5, 0, 0)
		arm.Material = Enum.Material.Plastic
		arm.Color = Color3.fromRGB(255, 220, 177)
		arm.Anchored = true
		arm.Parent = npc
	end

	-- Legs
	for i, side in ipairs({"Left", "Right"}) do
		local leg = Instance.new("Part")
		leg.Name = side .. "Leg"
		leg.Size = Vector3.new(1, 2, 1)
		leg.Position = torso.Position + Vector3.new(i == 1 and -0.5 or 0.5, -2, 0)
		leg.Material = Enum.Material.Plastic
		leg.Color = Color3.fromRGB(0, 0, 139) -- Blue pants
		leg.Anchored = true
		leg.Parent = npc
	end

	-- Vendor Hat
	local hat = Instance.new("Part")
	hat.Name = "VendorHat"
	hat.Size = Vector3.new(2.2, 0.5, 2.2)
	hat.Position = head.Position + Vector3.new(0, 0.75, 0)
	hat.Material = Enum.Material.Fabric
	hat.Color = Color3.fromRGB(139, 69, 19) -- Brown
	hat.Shape = Enum.PartType.Cylinder
	hat.Anchored = true
	hat.Parent = npc

	-- Name tag
	local nameGui = Instance.new("BillboardGui")
	nameGui.Name = "NameTag"
	nameGui.Size = UDim2.new(0, 200, 0, 50)
	nameGui.StudsOffset = Vector3.new(0, 3, 0)
	nameGui.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "🍌 " .. NPC_NAME .. " 🍌"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Parent = nameGui

	-- Vendor stall/counter
	local counter = Instance.new("Part")
	counter.Name = "Counter"
	counter.Size = Vector3.new(6, 3, 2)
	counter.Position = torso.Position + Vector3.new(0, -0.5, -2)
	counter.Material = Enum.Material.Wood
	counter.Color = Color3.fromRGB(139, 69, 19)
	counter.Anchored = true
	counter.Parent = npc

	-- Fruit display on counter
	local fruits = {"🍌", "🍎", "🍊", "🥝"}
	for i, fruit in ipairs(fruits) do
		local fruitDisplay = Instance.new("Part")
		fruitDisplay.Name = "FruitDisplay" .. i
		fruitDisplay.Size = Vector3.new(0.8, 0.8, 0.8)
		fruitDisplay.Position = counter.Position + Vector3.new(-2 + i * 1, 1.8, 0)
		fruitDisplay.Material = Enum.Material.Neon
		fruitDisplay.Color = Color3.fromRGB(255, 255, 0)
		fruitDisplay.Shape = Enum.PartType.Ball
		fruitDisplay.Anchored = true
		fruitDisplay.Parent = npc

		-- Fruit emoji display
		local fruitGui = Instance.new("BillboardGui")
		fruitGui.Size = UDim2.new(0, 100, 0, 100)
		fruitGui.Parent = fruitDisplay

		local fruitLabel = Instance.new("TextLabel")
		fruitLabel.Size = UDim2.new(1, 0, 1, 0)
		fruitLabel.BackgroundTransparency = 1
		fruitLabel.Text = fruit
		fruitLabel.TextScaled = true
		fruitLabel.Parent = fruitGui
	end

	npc.PrimaryPart = torso
	npc.Parent = workspace

	return npc
end

-- Check if item is a fruit
local function isFruit(item)
	if not item or not item:IsA("Tool") then return false end

	local itemName = item.Name:lower()
	for fruitType, _ in pairs(FRUIT_PRICES) do
		if itemName:find(fruitType) then
			return true
		end
	end
	return false
end

-- Get fruit value
local function getFruitValue(fruit)
	if not isFruit(fruit) then return 0 end

	local fruitName = fruit.Name:lower()
	local baseValue = 0

	-- Determine base fruit type
	for fruitType, price in pairs(FRUIT_PRICES) do
		if fruitName:find(fruitType) then
			baseValue = price
			break
		end
	end

	-- Apply weight multiplier if available
	local weight = fruit:GetAttribute("Weight") or 1
	return math.floor(baseValue * weight)
end

-- Get all fruits in player inventory
local function getPlayerFruits(player)
	local fruits = {}

	-- Check backpack
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if isFruit(tool) then
			table.insert(fruits, tool)
		end
	end

	-- Check equipped tool
	if player.Character then
		local equippedTool = player.Character:FindFirstChildOfClass("Tool")
		if equippedTool and isFruit(equippedTool) then
			table.insert(fruits, equippedTool)
		end
	end

	return fruits
end

-- Calculate total inventory value
local function calculateInventoryValue(player)
	local fruits = getPlayerFruits(player)
	local totalValue = 0

	for _, fruit in ipairs(fruits) do
		totalValue = totalValue + getFruitValue(fruit)
	end

	return totalValue, #fruits
end

-- Sell player's inventory
local function sellInventory(player)
	local fruits = getPlayerFruits(player)
	local totalValue = 0
	local fruitCount = 0

	for _, fruit in ipairs(fruits) do
		totalValue = totalValue + getFruitValue(fruit)
		fruitCount = fruitCount + 1
		fruit:Destroy()
	end

	-- Give coins
	if _G.CoinSystem and totalValue > 0 then
		_G.CoinSystem.addCoins(player, totalValue)
	end

	return totalValue, fruitCount
end

-- Sell specific fruit (equipped)
local function sellEquippedFruit(player)
	if not player.Character then return 0 end

	local equippedTool = player.Character:FindFirstChildOfClass("Tool")
	if not equippedTool or not isFruit(equippedTool) then
		return 0
	end

	local value = getFruitValue(equippedTool)
	equippedTool:Destroy()

	-- Give coins
	if _G.CoinSystem and value > 0 then
		_G.CoinSystem.addCoins(player, value)
	end

	return value
end

-- Check proximity to NPC
local function checkProximity()
	local npc = workspace:FindFirstChild(NPC_NAME)
	if not npc or not npc.PrimaryPart then return end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (player.Character.HumanoidRootPart.Position - npc.PrimaryPart.Position).Magnitude

			if distance <= INTERACTION_DISTANCE then
				-- Player is near
				if not proximityPlayers[player.UserId] then
					proximityPlayers[player.UserId] = true
					showInteractionRemote:FireClient(player)
				end
			else
				-- Player is far
				if proximityPlayers[player.UserId] then
					proximityPlayers[player.UserId] = nil
					hideInteractionRemote:FireClient(player)
				end
			end
		end
	end
end

-- Handle vendor interaction
local function handleVendorInteraction(player, action, data)
	local npc = workspace:FindFirstChild(NPC_NAME)
	if not npc then return end

	if action == "start_dialog" then
		-- Show initial dialog
		vendorDialogRemote:FireClient(player, "initial", {
			text = "Hello there! What are you up to?",
			options = {
				{id = "sell", text = "I want to sell fruits"},
				{id = "buy_seeds", text = "I want to buy seeds"}
			}
		})

	elseif action == "sell" then
		-- Show sell options
		vendorDialogRemote:FireClient(player, "sell_options", {
			text = "What would you like to sell?",
			options = {
				{id = "sell_inventory", text = "I want to sell my inventory"},
				{id = "sell_equipped", text = "I want to sell this"},
				{id = "check_price", text = "How much is this worth?"}
			}
		})

	elseif action == "buy_seeds" then
		-- Open seed shop GUI (you'll handle the GUI)
		openSeedShopRemote:FireClient(player)

	elseif action == "sell_inventory" then
		-- Show inventory sell options
		local totalValue, fruitCount = calculateInventoryValue(player)
		vendorDialogRemote:FireClient(player, "inventory_options", {
			text = string.format("You have %d fruits worth %d coins total.", fruitCount, totalValue),
			options = {
				{id = "sell_now", text = "I want to sell my inventory now"},
				{id = "minigame", text = "I want to play a minigame for a potential bonus!"}
			}
		})

	elseif action == "sell_equipped" then
		-- Sell equipped fruit
		local value = sellEquippedFruit(player)
		if value > 0 then
			vendorDialogRemote:FireClient(player, "sell_complete", {
				text = string.format("Sold your fruit for %d coins!", value),
				options = {
					{id = "done", text = "Thanks!"}
				}
			})

			if _G.showNotification then
				_G.showNotification(player, "Sold fruit for " .. value .. " coins!", "success")
			end
		else
			vendorDialogRemote:FireClient(player, "no_fruit", {
				text = "You don't have a fruit equipped to sell!",
				options = {
					{id = "back", text = "Go back"}
				}
			})
		end

	elseif action == "check_price" then
		-- Check equipped fruit price
		if player.Character then
			local equippedTool = player.Character:FindFirstChildOfClass("Tool")
			if equippedTool and isFruit(equippedTool) then
				local value = getFruitValue(equippedTool)
				vendorDialogRemote:FireClient(player, "price_check", {
					text = string.format("Your %s is worth %d coins!", equippedTool.Name, value),
					options = {
						{id = "sell_it", text = "I'll sell it!"},
						{id = "back", text = "Go back"}
					}
				})
			else
				vendorDialogRemote:FireClient(player, "no_fruit", {
					text = "You don't have a fruit equipped to check!",
					options = {
						{id = "back", text = "Go back"}
					}
				})
			end
		end

	elseif action == "sell_now" then
		-- Sell inventory immediately
		local totalValue, fruitCount = sellInventory(player)
		vendorDialogRemote:FireClient(player, "sell_complete", {
			text = string.format("Sold %d fruits for %d coins!", fruitCount, totalValue),
			options = {
				{id = "done", text = "Thanks!"}
			}
		})

		if _G.showNotification then
			_G.showNotification(player, string.format("Sold %d fruits for %d coins!", fruitCount, totalValue), "success")
		end

	elseif action == "minigame" then
		-- Teleport to minigame
		local minigameStart = workspace:FindFirstChild("MinigameStartPart")
		if minigameStart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = CFrame.new(minigameStart.Position + Vector3.new(0, 5, 0))

			if _G.showNotification then
				_G.showNotification(player, "Teleported to minigame area!", "info")
			end
		else
			vendorDialogRemote:FireClient(player, "no_minigame", {
				text = "Minigame area not found! Let me just buy your fruits normally.",
				options = {
					{id = "sell_now", text = "Okay, sell them"}
				}
			})
		end

	elseif action == "sell_it" then
		-- Sell from price check
		local value = sellEquippedFruit(player)
		if value > 0 then
			vendorDialogRemote:FireClient(player, "sell_complete", {
				text = string.format("Sold your fruit for %d coins!", value),
				options = {
					{id = "done", text = "Thanks!"}
				}
			})

			if _G.showNotification then
				_G.showNotification(player, "Sold fruit for " .. value .. " coins!", "success")
			end
		end
	end
end

-- Remote event handlers
vendorInteractRemote.OnServerEvent:Connect(function(player, action, data)
	handleVendorInteraction(player, action, data)
end)

getFruitPriceRemote.OnServerInvoke = function(player, fruitName)
	-- For external scripts to check fruit prices
	for fruitType, price in pairs(FRUIT_PRICES) do
		if fruitName:lower():find(fruitType) then
			return price
		end
	end
	return 0
end

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
	proximityPlayers[player.UserId] = nil
	activeInteractions[player.UserId] = nil
end)

-- Start proximity checking
task.spawn(function()
	while true do
		checkProximity()
		task.wait(0.5) -- Check twice per second
	end
end)

-- Create NPC on server start
local npc = createVendorNPC()

-- Global functions for other scripts
_G.VendorSystem = {
	getFruitValue = getFruitValue,
	isFruit = isFruit,
	sellPlayerInventory = sellInventory,
	getNPC = function()
		return workspace:FindFirstChild(NPC_NAME)
	end
}

print("🍌 Fruit Vendor NPC System Loaded!")
print("   - Interactive NPC with proximity detection")
print("   - Comprehensive dialog system")
print("   - Fruit selling and pricing")
print("   - Minigame integration")
print("   - Mobile and PC input support")

-- DEPRECATED: Fruit/farming logic removed for city/empire game.
return