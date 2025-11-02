-- CoinGUI.lua
-- Client-side coin display handler for existing GUI
-- Handles coin updates from server without creating GUI elements

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoinGUI = {}

-- Listen for coin updates from CoinSystem
local CoinEvent = ReplicatedStorage:WaitForChild("CoinUpdateEvent")

-- Function to format numbers with commas
local function FormatNumber(number)
	local formattedAmount = tostring(number):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return formattedAmount:gsub("^,", "")
end

-- Connection for coin updates - your existing GUI can hook into this
CoinEvent.OnClientEvent:Connect(function(newAmount)
	local formattedAmount = FormatNumber(newAmount)

	-- Fire a BindableEvent or custom event that your GUI can listen to
	local coinUpdateBindable = ReplicatedStorage:FindFirstChild("CoinDisplayUpdate")
	if not coinUpdateBindable then
		coinUpdateBindable = Instance.new("BindableEvent")
		coinUpdateBindable.Name = "CoinDisplayUpdate"
		coinUpdateBindable.Parent = ReplicatedStorage
	end

	coinUpdateBindable:Fire(formattedAmount, newAmount)
	print("Coin update: " .. formattedAmount) -- Debug output
end)

-- Utility function for your GUI to format coin amounts
function CoinGUI:FormatCoins(amount)
	return FormatNumber(amount)
end

-- This script is deprecated. All currency logic is now handled by BloxGUI (Blox currency).
return
