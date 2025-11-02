-- Gamepasses.lua
-- Place this script in ServerScriptService or a relevant location
-- Contains gamepass definitions and effect logic only (no object or GUI creation)

local Gamepasses = {
	{
		Name = "Auto-Sell",
		Id = 1, -- Replace with your actual GamepassId
		Price = 1000,
		Description = "Automatically sells bananas when your crate is full.",
		Effect = function(player)
			player:SetAttribute("AutoSellEnabled", true)
		end
	},
	{
		Name = "Weather Dominator",
		Id = 2, -- Replace with your actual GamepassId
		Price = 1500,
		Description = "Lets you force any weather event at will.",
		Effect = function(player)
			player:SetAttribute("WeatherDominatorEnabled", true)
		end
	},
	{
		Name = "Banana Tax Troll",
		Id = 3, -- Replace with your actual GamepassId
		Price = 5000,
		Description = "For 1 hour, all players pay double prices, but you pay half.",
		Effect = function(player)
			player:SetAttribute("BananaTaxTrollActive", true)
			task.delay(3600, function()
				player:SetAttribute("BananaTaxTrollActive", false)
			end)
		end
	},
	{
		Name = "Pest Overdrive (Server)",
		Id = 4, -- Replace with your actual GamepassId
		Price = 500,
		Description = "Triggers a cutscene of pests marching in (server only).",
		Effect = function(player)
			player:SetAttribute("PestOverdriveServer", true)
		end
	},
	{
		Name = "Pest Overdrive (Global)",
		Id = 5, -- Replace with your actual GamepassId
		Price = 10000,
		Description = "Triggers a cutscene of pests marching in (global).",
		Effect = function(player)
			player:SetAttribute("PestOverdriveGlobal", true)
		end
	},
	{
		Name = "Banana Buddy",
		Id = 6, -- Replace with your actual GamepassId
		Price = 200,
		Description = "Floating banana NPC drops bonus bananas and boosts jump/speed.",
		Effect = function(player)
			player:SetAttribute("BananaBuddyActive", true)
		end
	},
	{
		Name = "Pest Zapper",
		Id = 7, -- Replace with your actual GamepassId
		Price = 150,
		Description = "Instantly zaps pests on your plot whenever they appear.",
		Effect = function(player)
			player:SetAttribute("PestZapperActive", true)
		end
	},
	{
		Name = "Banana Alarm",
		Id = 8, -- Replace with your actual GamepassId
		Price = 100,
		Description = "Alerts you with a sound and pop-up when high-tier events or pests appear.",
		Effect = function(player)
			player:SetAttribute("BananaAlarmActive", true)
		end
	},
	{
		Name = "Banana Vacuum",
		Id = 9, -- Replace with your actual GamepassId
		Price = 250,
		Description = "Auto-collects any dropped bananas around your plot within a certain radius.",
		Effect = function(player)
			player:SetAttribute("BananaVacuumActive", true)
		end
	},
	{
		Name = "Seed Saver Pro",
		Id = 10, -- Replace with your actual GamepassId
		Price = 300,
		Description = "A good chance planted seed does not get consumed.",
		Effect = function(player)
			player:SetAttribute("SeedSaverProActive", true)
		end
	},
	{
		Name = "Monkey Messenger",
		Id = 11, -- Replace with your actual GamepassId
		Price = 175,
		Description = "NPC monkey at your plot tells you the best item in stock.",
		Effect = function(player)
			player:SetAttribute("MonkeyMessengerActive", true)
		end
	},
	{
		Name = "Banana Jackpot",
		Id = 12, -- Replace with your actual GamepassId
		Price = 275,
		Description = "Chance to earn bonus coins when selling, like a hidden lottery.",
		Effect = function(player)
			player:SetAttribute("BananaJackpotActive", true)
		end
	}
}

return Gamepasses
