-- MonkeyMafiaQuests.lua
-- Place in ServerScriptService
-- Robust, smooth, and error-free quest system for Monkey Mafia

-- Utility: Get player character safely
local function getCharacter(player)
	return (player and player.Character and player.Character.Parent) and player.Character or nil
end

-- Utility: Get player's coin count via CoinSystem only
local function getCoins(player)
	if _G.CoinSystem and _G.CoinSystem.getCoins then
		return _G.CoinSystem.getCoins(player)
	end
	return 0
end

-- Utility: Add coins via CoinSystem only
local function addCoins(player, amount)
	if _G.CoinSystem and _G.CoinSystem.addCoins then
		return _G.CoinSystem.addCoins(player, amount)
	else
		warn("[MonkeyMafiaQuests] CoinSystem unavailable! Could not add coins to", player and player.Name or "nil")
		return false
	end
end

-- Quest definitions
local MonkeyMafiaQuests = {
	{
		Name = "Sneak into Security without getting caught",
		Reward = function(player)
			addCoins(player, 5000)
			-- ...additional reward logic...
		end,
		Fail = function(player)
			local char = getCharacter(player)
			if char and char:FindFirstChild("HumanoidRootPart") then
				char.HumanoidRootPart.Anchored = true
			end
			player:SetAttribute("IsLockedInCell", true)
			task.delay(120, function()
				local char2 = getCharacter(player)
				if char2 and char2:FindFirstChild("HumanoidRootPart") then
					char2.HumanoidRootPart.Anchored = false
				end
				player:SetAttribute("IsLockedInCell", false)
			end)
		end
	},
	{
		Name = "Deliver illegal bananas without interception",
		Reward = function(player)
			addCoins(player, 7000)
		end,
		Fail = function(player)
			local char = getCharacter(player)
			if char then
				local crate = char:FindFirstChild("BananaCrate")
				if crate then crate:Destroy() end
				local humanoid = char:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.PlatformStand = true
					task.delay(10, function()
						local char2 = getCharacter(player)
						if char2 then
							local humanoid2 = char2:FindFirstChild("Humanoid")
							if humanoid2 then humanoid2.PlatformStand = false end
						end
					end)
				end
			end
		end
	},
	{
		Name = "Successfully bribe the guard",
		Reward = function(player)
			addCoins(player, 4000)
			player:SetAttribute("SpeedBoost", true)
			task.delay(30, function()
				player:SetAttribute("SpeedBoost", false)
			end)
		end,
		Fail = function(player)
			player:SetAttribute("IsChasedByCops", true)
			task.delay(30, function()
				player:SetAttribute("IsChasedByCops", false)
			end)
		end
	},
	{
		Name = "Steal supplies from rival warehouse without triggering alarms",
		Reward = function(player)
			addCoins(player, 10000)
			player:SetAttribute("HasRareSeeds", true)
		end,
		Fail = function(player)
			player:SetAttribute("BountyActive", true)
			task.delay(300, function()
				player:SetAttribute("BountyActive", false)
			end)
		end
	},
	{
		Name = "Collect protection fees without getting attacked",
		Reward = function(player)
			addCoins(player, 6000)
			player:SetAttribute("MinorIncomeBoost", true)
			task.delay(300, function()
				player:SetAttribute("MinorIncomeBoost", false)
			end)
		end,
		Fail = function(player)
			player:SetAttribute("CropsFrozen", true)
			task.delay(180, function()
				player:SetAttribute("CropsFrozen", false)
			end)
		end
	},
	{
		Name = "Smuggle banned bananas successfully",
		Reward = function(player)
			addCoins(player, 8000)
			player:SetAttribute("HasExclusiveSeed", true)
		end,
		Fail = function(player)
			player:SetAttribute("CoinTaxPenalty", true)
			task.delay(600, function()
				player:SetAttribute("CoinTaxPenalty", false)
			end)
		end
	},
	{
		Name = "Plant spy device in rival’s garden undetected",
		Reward = function(player)
			addCoins(player, 7000)
			player:SetAttribute("RivalMoveInfo", true)
		end,
		Fail = function(player)
			player:SetAttribute("DoubleQuestCost", 3)
		end
	},
	{
		Name = "Ambush a rival’s shipment without loss",
		Reward = function(player)
			addCoins(player, 9000)
			player:SetAttribute("HasBananaCrate", true)
		end,
		Fail = function(player)
			local bananas = player:FindFirstChild("Bananas")
			if bananas and bananas:IsA("IntValue") then
				bananas.Value = math.floor(bananas.Value / 2)
			end
		end
	},
	{
		Name = "Cover your tracks after a heist",
		Reward = function(player)
			addCoins(player, 5000)
			player:SetAttribute("CropGrowthBoost", true)
			task.delay(180, function()
				player:SetAttribute("CropGrowthBoost", false)
			end)
		end,
		Fail = function(player)
			player:SetAttribute("CropGrowthSlowed", true)
			task.delay(120, function()
				player:SetAttribute("CropGrowthSlowed", false)
			end)
		end
	},
	{
		Name = "Recruit a new member to the Monkey Mafia",
		Reward = function(player)
			addCoins(player, 6000)
			player:SetAttribute("PermanentIncomeBoost", true)
		end,
		Fail = function(player)
			local coins = getCoins(player)
			if type(coins) == "number" then
				addCoins(player, math.floor(coins * -0.1))
			end
		end
	}
}

return MonkeyMafiaQuests
