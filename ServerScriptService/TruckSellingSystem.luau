-- TruckSellingSystem.lua - Truck Driving Mini-Game for Selling
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Selling configuration
local CRATE_REQUIREMENT = 20 -- Need 20 bananas to get a crate
local TRUCK_SPEED = 50 -- Truck driving speed

-- Time bonus ranks
local TIME_RANKS = {
	{name = "S", maxTime = 15, bonus = 1.5,  color = Color3.fromRGB(255, 215, 0)}, -- +50%
	{name = "A", maxTime = 25, bonus = 1.3,  color = Color3.fromRGB(192, 192, 192)}, -- +30%
	{name = "B", maxTime = 35, bonus = 1.15, color = Color3.fromRGB(205, 127, 50)}, -- +15%
	{name = "C", maxTime = 45, bonus = 1.0,  color = Color3.fromRGB(255, 255, 255)}, -- no bonus
	{name = "F", maxTime = 999, bonus = 0.8, color = Color3.fromRGB(255, 0, 0)} -- -20% penalty
}

-- RemoteEvents
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder")
remoteEventsFolder.Name = "RemoteEvents"
remoteEventsFolder.Parent = ReplicatedStorage

local startTruckSaleRemote = Instance.new("RemoteEvent")
startTruckSaleRemote.Name = "StartTruckSale"
startTruckSaleRemote.Parent = remoteEventsFolder

local completeTruckSaleRemote = Instance.new("RemoteEvent")
completeTruckSaleRemote.Name = "CompleteTruckSale"
completeTruckSaleRemote.Parent = remoteEventsFolder

-- Store active truck sessions
local activeTruckSessions = {} -- {userId: {bananas: number, startTime: number, truck: Model}}

-- Create truck model
local function createTruck()
	local truck = Instance.new("Model")
	truck.Name = "DeliveryTruck"

	-- Truck body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(12, 6, 6)
	body.Material = Enum.Material.Metal
	body.Color = Color3.fromRGB(255, 165, 0) -- Orange
	body.Anchored = true
	body.Parent = truck

	-- Driver seat
	local seat = Instance.new("Seat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2, 1, 2)
	seat.Position = body.Position + Vector3.new(-3, 3, 0)
	seat.Material = Enum.Material.Fabric
	seat.Color = Color3.fromRGB(139, 69, 19)
	seat.Anchored = true
	seat.Parent = truck

	-- Truck wheels
	for i, pos in ipairs({Vector3.new(-4, -2, 2), Vector3.new(-4, -2, -2), Vector3.new(4, -2, 2), Vector3.new(4, -2, -2)}) do
		local wheel = Instance.new("Part")
		wheel.Name = "Wheel" .. i
		wheel.Size = Vector3.new(1, 3, 3)
		wheel.Shape = Enum.PartType.Cylinder
		wheel.Position = body.Position + pos
		wheel.Material = Enum.Material.Rubber
		wheel.Color = Color3.fromRGB(50, 50, 50)
		wheel.Anchored = true
		wheel.Parent = truck
	end

	-- Headlights
	for i, pos in ipairs({Vector3.new(6.5, 1, 1.5), Vector3.new(6.5, 1, -1.5)}) do
		local light = Instance.new("Part")
		light.Name = "Headlight" .. i
		light.Size = Vector3.new(0.5, 1, 1)
		light.Position = body.Position + pos
		light.Material = Enum.Material.Neon
		light.Color = Color3.fromRGB(255, 255, 200)
		light.Anchored = true
		light.Parent = truck
	end

	-- Horn sound
	local horn = Instance.new("Sound")
	horn.Name = "Horn"
	horn.SoundId = "rbxasset://sounds/carhorn.mp3"
	horn.Volume = 0.5
	horn.Parent = body

	-- Engine sound
	local engine = Instance.new("Sound")
	engine.Name = "Engine"
	engine.SoundId = "rbxasset://sounds/electronicpingsharp.wav"
	engine.Volume = 0.3
	engine.Looped = true
	engine.Parent = body

	truck.PrimaryPart = body
	return truck
end

-- Create warehouse
local function createWarehouse()
	local warehouse = Instance.new("Model")
	warehouse.Name = "Warehouse"

	-- Main building
	local building = Instance.new("Part")
	building.Name = "Building"
	building.Size = Vector3.new(30, 20, 25)
	building.Position = Vector3.new(200, 10, 0) -- Far from spawn
	building.Material = Enum.Material.Concrete
	building.Color = Color3.fromRGB(100, 100, 100)
	building.Anchored = true
	building.Parent = warehouse

	-- Doors (to ram into)
	local doors = Instance.new("Part")
	doors.Name = "Doors"
	doors.Size = Vector3.new(1, 15, 12)
	doors.Position = building.Position + Vector3.new(-15.5, 0, 0)
	doors.Material = Enum.Material.Metal
	doors.Color = Color3.fromRGB(139, 69, 19)
	doors.Anchored = true
	doors.CanCollide = false -- So truck can ram through
	doors.Parent = warehouse

	-- Warehouse sign
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(15, 5, 1)
	sign.Position = building.Position + Vector3.new(0, 12, -13)
	sign.Material = Enum.Material.Neon
	sign.Color = Color3.fromRGB(0, 255, 0)
	sign.Anchored = true
	sign.Parent = warehouse

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "🏭 BANANA WAREHOUSE"
	signText.TextColor3 = Color3.fromRGB(0, 0, 0)
	signText.TextScaled = true
	signText.Font = Enum.Font.SourceSansBold
	signText.Parent = signGui

	warehouse.PrimaryPart = building
	warehouse.Parent = Workspace
	return warehouse
end

-- Check if player has enough bananas for crate
local function canCreateCrate(player)
	local bananaCount = 0

	-- Count bananas in backpack
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower():find("banapple") then
			bananaCount = bananaCount + 1
		end
	end

	return bananaCount >= CRATE_REQUIREMENT, bananaCount
end

-- Create banana crate
local function createBananaCrate(player, bananaCount)
	local crate = Instance.new("Tool")
	crate.Name = "Banana Crate (" .. bananaCount .. " bananas)"
	crate.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(3, 2, 3)
	handle.Material = Enum.Material.Wood
	handle.Color = Color3.fromRGB(139, 69, 19)
	handle.Parent = crate

	-- Add banana visual on top
	local bananas = Instance.new("Part")
	bananas.Name = "Bananas"
	bananas.Size = Vector3.new(2.5, 1, 2.5)
	bananas.Position = handle.Position + Vector3.new(0, 1.5, 0)
	bananas.Material = Enum.Material.Neon
	bananas.Color = Color3.fromRGB(255, 255, 0)
	bananas.Anchored = false
	bananas.CanCollide = false
	bananas.Parent = handle

	-- Weld bananas to handle
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = bananas
	weld.Parent = handle

	crate:SetAttribute("BananaCount", bananaCount)
	return crate
end

-- Create truck route waypoints
local function createRoute()
	local waypoints = {}
	local startPos = Vector3.new(0, 5, 0)
	local endPos = Vector3.new(180, 5, 0) -- Near warehouse

	-- Create simple straight route with some turns
	table.insert(waypoints, startPos)
	table.insert(waypoints, Vector3.new(50, 5, 20))
	table.insert(waypoints, Vector3.new(100, 5, -10))
	table.insert(waypoints, Vector3.new(150, 5, 15))
	table.insert(waypoints, endPos)

	return waypoints
end

-- Start truck selling mini-game
local function startTruckSale(player)
	local canSell, bananaCount = canCreateCrate(player)
	if not canSell then
		if _G.showNotification then
			_G.showNotification(player, "Need " .. CRATE_REQUIREMENT .. " bananas for a crate! (" .. bananaCount .. "/" .. CRATE_REQUIREMENT .. ")", "error")
		end
		return false
	end

	-- Remove bananas from inventory
	local removedCount = 0
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower():find("banapple") and removedCount < CRATE_REQUIREMENT then
			tool:Destroy()
			removedCount = removedCount + 1
		end
	end

	-- Create banana crate
	local crate = createBananaCrate(player, CRATE_REQUIREMENT)
	crate.Parent = player.Backpack

	-- Store session data
	activeTruckSessions[player.UserId] = {
		bananas = CRATE_REQUIREMENT,
		startTime = tick(),
		phase = "carry_crate"
	}

	if _G.showNotification then
		_G.showNotification(player, "🚛 Walk your crate to the truck!", "info")
		_G.showNotification(player, "Find the yellow delivery truck and touch it", "info")
	end

	return true
end

-- Handle crate touching truck
local function onCrateTouchedTruck(player, crate)
	local session = activeTruckSessions[player.UserId]
	if not session or session.phase ~= "carry_crate" then return end

	-- Remove crate and start driving phase
	crate:Destroy()
	session.phase = "driving"

	-- Create truck
	local truck = createTruck()
	truck.PrimaryPart.Position = Vector3.new(20, 5, 0)
	truck.Parent = Workspace
	session.truck = truck

	-- Black screen fade effect
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TruckTransition"
	screenGui.Parent = player.PlayerGui

	local blackFrame = Instance.new("Frame")
	blackFrame.Size = UDim2.new(1, 0, 1, 0)
	blackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	blackFrame.BackgroundTransparency = 1
	blackFrame.Parent = screenGui

	-- Fade to black
	local fadeIn = TweenService:Create(blackFrame, TweenInfo.new(1), {BackgroundTransparency = 0})
	fadeIn:Play()

	fadeIn.Completed:Connect(function()
		-- Teleport player to truck
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = CFrame.new(truck.DriverSeat.Position + Vector3.new(0, 2, 0))
		end

		-- Start engine sound
		local engine = truck.Body:FindFirstChild("Engine")
		if engine then
			engine:Play()
		end

		-- Fade back in
		local fadeOut = TweenService:Create(blackFrame, TweenInfo.new(1), {BackgroundTransparency = 1})
		fadeOut:Play()

		fadeOut.Completed:Connect(function()
			screenGui:Destroy()

			if _G.showNotification then
				_G.showNotification(player, "🚛 Drive to the warehouse!", "info")
				_G.showNotification(player, "Ram into the warehouse doors to complete delivery!", "info")
			end
		end)
	end)
end

-- Complete truck sale
local function completeTruckSale(player)
	local session = activeTruckSessions[player.UserId]
	if not session then return end

	local deliveryTime = tick() - session.startTime
	local rank = TIME_RANKS[#TIME_RANKS] -- Default to F rank

	-- Determine time rank
	for _, timeRank in ipairs(TIME_RANKS) do
		if deliveryTime <= timeRank.maxTime then
			rank = timeRank
			break
		end
	end

	-- Calculate payment
	local basePayment = session.bananas * 50 -- 50 coins per banana
	local finalPayment = math.floor(basePayment * rank.bonus)

	-- Apply worker bonuses
	if _G.RebirthSystem then
		local sellBonus = _G.RebirthSystem.getWorkerMultiplier(player, "sell_bonus")
		finalPayment = math.floor(finalPayment * sellBonus)
	end

	-- Give coins
	if _G.CoinSystem then
		_G.CoinSystem.addCoins(player, finalPayment)
	end

	-- Track for rebirth system
	if _G.RebirthSystem then
		_G.RebirthSystem.addBananasSold(player, session.bananas)
	end

	-- Clean up truck
	if session.truck then
		session.truck:Destroy()
	end

	-- Show results
	if _G.showNotification then
		_G.showNotification(player, "🏭 DELIVERY COMPLETE!", "success")
		_G.showNotification(player, string.format("Rank: %s (%.1fs)", rank.name, deliveryTime), "info")
		_G.showNotification(player, "Earned: " .. finalPayment .. " coins", "success")
	end

	-- Clean up session
	activeTruckSessions[player.UserId] = nil

	print("🚛 Player", player.Name, "completed truck sale - Rank:", rank.name, "Payment:", finalPayment)
end

-- Remote event handlers
startTruckSaleRemote.OnServerEvent:Connect(function(player)
	startTruckSale(player)
end)

completeTruckSaleRemote.OnServerEvent:Connect(function(player)
	completeTruckSale(player)
end)

-- Player cleanup
Players.PlayerRemoving:Connect(function(player)
	local session = activeTruckSessions[player.UserId]
	if session and session.truck then
		session.truck:Destroy()
	end
	activeTruckSessions[player.UserId] = nil
end)

-- Create warehouse on server start
createWarehouse()

-- Global functions for other scripts
_G.TruckSystem = {
	canStartSale = function(player)
		local canSell, bananaCount = canCreateCrate(player)
		return canSell, bananaCount
	end,
	isPlayerInTruckSale = function(player)
		return activeTruckSessions[player.UserId] ~= nil
	end
}

print("🚛 Truck Selling System Loaded!")
print("   - Banana crate creation")
print("   - Truck driving mini-game")
print("   - Time-based bonus system")
print("   - Warehouse delivery system")
