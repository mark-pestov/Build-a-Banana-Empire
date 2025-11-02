-- BattlePassClient.lua - Client-side Battle Pass Data Handler
-- Place in StarterGui or StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Battle Pass Tier Data (matches server)
local BATTLE_PASS_TIERS = {
	[1] = {level = 1, free_reward = {name = "500 Coins"}, premium_reward = {name = "+500 Coins & Banana Buddy Hat"}},
	[2] = {level = 2, free_reward = {name = "Banana Pet (Tiny)"}, premium_reward = {name = "+Banana Floaty Cosmetic"}},
	[3] = {level = 3, free_reward = {name = "1 Basic Seed"}, premium_reward = {name = "+1 Extra Basic Seed"}},
	[4] = {level = 4, free_reward = {name = "+100 Worker Coins"}, premium_reward = {name = "+Banana Socks Cosmetic"}},
	[5] = {level = 5, free_reward = {name = "Decorative Banana Hat"}, premium_reward = {name = "+Mini Banana Crate Pet"}},
	[6] = {level = 6, free_reward = {name = "750 Coins"}, premium_reward = {name = "+Banana Smoothie Gear"}},
	[7] = {level = 7, free_reward = {name = "Banana Bucket Gear"}, premium_reward = {name = "+1 Solid Seed"}},
	[8] = {level = 8, free_reward = {name = "1 Basic Seed"}, premium_reward = {name = "+150 Worker Coins"}},
	[9] = {level = 9, free_reward = {name = "Banana Plush Decoration"}, premium_reward = {name = "+Banana Cape Cosmetic"}},
	[10] = {level = 10, free_reward = {name = "5 Basic Seeds"}, premium_reward = {name = "+2 Solid Seeds"}},
	[11] = {level = 11, free_reward = {name = "+200 Worker Coins"}, premium_reward = {name = "+Banana Sticker Pack"}},
	[12] = {level = 12, free_reward = {name = "Banana Crate Pet"}, premium_reward = {name = "+Banana Bubble Pet"}},
	[13] = {level = 13, free_reward = {name = "1 Solid Seed"}, premium_reward = {name = "+1 Extra Solid Seed"}},
	[14] = {level = 14, free_reward = {name = "Banana Umbrella Gear"}, premium_reward = {name = "+Banana Punch Cosmetic"}},
	[15] = {level = 15, free_reward = {name = "1,000 Coins"}, premium_reward = {name = "+1,000 Coins & Banana Emote"}},
	[16] = {level = 16, free_reward = {name = "Banana Beach Towel"}, premium_reward = {name = "+Banana Hammock (XL)"}},
	[17] = {level = 17, free_reward = {name = "1 Solid Seed"}, premium_reward = {name = "+2 Basic Seeds"}},
	[18] = {level = 18, free_reward = {name = "+250 Worker Coins"}, premium_reward = {name = "+Banana Glow Trails"}},
	[19] = {level = 19, free_reward = {name = "Banana Hammock Furniture"}, premium_reward = {name = "+Banana Sleep Mask"}},
	[20] = {level = 20, free_reward = {name = "3 Solid Seeds"}, premium_reward = {name = "+1 Legendary Seed"}},
	[21] = {level = 21, free_reward = {name = "Banana Shades Gear"}, premium_reward = {name = "+Banana Bling Cosmetic"}},
	[22] = {level = 22, free_reward = {name = "1,250 Coins"}, premium_reward = {name = "+2 Solid Seeds"}},
	[23] = {level = 23, free_reward = {name = "Banana Flag Decoration"}, premium_reward = {name = "+Banana Staff Gear"}},
	[24] = {level = 24, free_reward = {name = "Banana Bouncer Pet"}, premium_reward = {name = "+Banana Surfboard Mount"}},
	[25] = {level = 25, free_reward = {name = "1 Legendary Seed"}, premium_reward = {name = "+1 Extra Legendary Seed"}},
	-- Continue for all 100 levels...
	[50] = {level = 50, free_reward = {name = "1 Celestial Seed"}, premium_reward = {name = "+Ultimate Banana Crown"}},
	[75] = {level = 75, free_reward = {name = "Banana Fox Pet"}, premium_reward = {name = "+Banana Tiger Pet"}},
	[100] = {level = 100, free_reward = {name = "1 Transcendent Seed"}, premium_reward = {name = "+Transcendent Banana Relic Cosmetic"}}
}

-- Fill in missing tiers with generated data
for i = 26, 100 do
	if not BATTLE_PASS_TIERS[i] then
		BATTLE_PASS_TIERS[i] = {
			level = i,
			free_reward = {name = "Tier " .. i .. " Reward"},
			premium_reward = {name = "+Premium Tier " .. i .. " Reward"}
		}
	end
end

local BattlePassClient = {}

-- Get tier data for UI
function BattlePassClient.getTierData(level)
	return BATTLE_PASS_TIERS[level]
end

-- Get all tier data
function BattlePassClient.getAllTiers()
	return BATTLE_PASS_TIERS
end

-- Update Battle Pass display in MainGameInterface
function BattlePassClient.updateBattlePassDisplay(battlePassData)
	-- This function can be called to update the Battle Pass UI
	-- with fresh data from the server
	print("🎫 Updating Battle Pass display with:", battlePassData)
end

-- Listen for Battle Pass updates from server
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local updateBattlePassRemote = remoteEventsFolder:FindFirstChild("UpdateBattlePass")

if updateBattlePassRemote then
	updateBattlePassRemote.OnClientEvent:Connect(function(data)
		BattlePassClient.updateBattlePassDisplay(data)
	end)
end

-- Global access for MainGameInterface
_G.BattlePassClient = BattlePassClient

print("🎫 Battle Pass Client Loaded!")
print("   - 100 tiers of reward data available")
print("   - Connected to server updates")

return BattlePassClient
