-- BloxGUI.lua
-- Client-side blox (currency) display handler for existing GUI
-- Handles blox updates from server without creating GUI elements
-- This script handles the player's Blox (currency) display and updates.
-- All references to 'Coin' or 'Coins' have been replaced with 'Blox' for the new currency system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BloxGUI = {}

-- Listen for blox updates from BloxSystem
local BloxEvent = ReplicatedStorage:WaitForChild("BloxUpdateEvent")

-- Function to format numbers with commas
local function FormatNumber(number)
	local formattedAmount = tostring(number):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return formattedAmount:gsub("^,", "")
end

-- Connection for blox updates - your existing GUI can hook into this
BloxEvent.OnClientEvent:Connect(function(newAmount)
	local formattedAmount = FormatNumber(newAmount)

	-- Fire a BindableEvent or custom event that your GUI can listen to
	local bloxUpdateBindable = ReplicatedStorage:FindFirstChild("BloxDisplayUpdate")
	if not bloxUpdateBindable then
		bloxUpdateBindable = Instance.new("BindableEvent")
		bloxUpdateBindable.Name = "BloxDisplayUpdate"
		bloxUpdateBindable.Parent = ReplicatedStorage
	end

	bloxUpdateBindable:Fire(formattedAmount, newAmount)
	print("Blox update: " .. formattedAmount) -- Debug output
end)

-- Utility function for your GUI to format blox amounts
function BloxGUI:FormatBlox(amount)
	return FormatNumber(amount)
end

return BloxGUI
