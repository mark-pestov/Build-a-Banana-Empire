-- DetailedInventoryGUI.lua
-- Client-side inventory data handler for existing GUI system
-- Manages inventory updates without creating GUI elements

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryHandler = {}

-- RemoteEvent for inventory updates from server
local InventoryUpdateEvent = ReplicatedStorage:FindFirstChild("InventoryUpdateEvent")
if not InventoryUpdateEvent then
	InventoryUpdateEvent = Instance.new("RemoteEvent")
	InventoryUpdateEvent.Name = "InventoryUpdateEvent"
	InventoryUpdateEvent.Parent = ReplicatedStorage
end

-- Current inventory data
local currentInventory = {}

-- Function to process inventory data
local function ProcessInventoryUpdate(items)
	currentInventory = items or {}

	-- Fire a BindableEvent that your existing GUI can listen to
	local inventoryBindable = ReplicatedStorage:FindFirstChild("InventoryDisplayUpdate")
	if not inventoryBindable then
		inventoryBindable = Instance.new("BindableEvent")
		inventoryBindable.Name = "InventoryDisplayUpdate"
		inventoryBindable.Parent = ReplicatedStorage
	end

	inventoryBindable:Fire(currentInventory)
	print("Inventory updated with " .. tostring(#currentInventory) .. " items") -- Debug output
end

-- Listen for inventory updates from server
InventoryUpdateEvent.OnClientEvent:Connect(ProcessInventoryUpdate)

-- Utility functions for your GUI system
function InventoryHandler:GetCurrentInventory()
	return currentInventory
end

function InventoryHandler:GetItemByName(itemName)
	for _, item in ipairs(currentInventory) do
		if item.Name == itemName then
			return item
		end
	end
	return nil
end

function InventoryHandler:GetItemCount(itemName)
	local item = self:GetItemByName(itemName)
	return item and item.Amount or 0
end

function InventoryHandler:GetTotalItems()
	local total = 0
	for _, item in ipairs(currentInventory) do
		total = total + (item.Amount or 0)
	end
	return total
end

-- Request inventory update from server
function InventoryHandler:RequestInventoryUpdate()
	local requestEvent = ReplicatedStorage:FindFirstChild("RequestInventoryUpdate")
	if not requestEvent then
		requestEvent = Instance.new("RemoteEvent")
		requestEvent.Name = "RequestInventoryUpdate"
		requestEvent.Parent = ReplicatedStorage
	end
	requestEvent:FireServer()
end

return InventoryHandler
