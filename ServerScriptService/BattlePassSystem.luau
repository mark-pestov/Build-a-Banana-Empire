-- BattlePassSystem.lua - Battle Pass Progression System
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Data Store
local battlePassStore = DataStoreService:GetDataStore("BattlePassData")

-- Premium Battle Pass GamePass ID (set this to your actual gamepass ID)
local PREMIUM_GAMEPASS_ID = 123456789 -- Replace with actual ID

-- XP Sources and Values
local XP_VALUES = {
	-- Selling bananas
	banana_sell = 1, -- 1 XP per banana sold

	-- Quest completion
	quest_complete = 50, -- 50 XP per quest completed

	-- Buying fruit from shop (rarer = more XP)
	fruit_purchase = {
		basic = 1,      -- Basic fruit = 5 XP
		solid = 5,     -- Solid fruit = 15 XP  
		legendary = 15, -- Legendary fruit = 40 XP
		mythical = 40, -- Mythical fruit = 100 XP
		celestial = 100, -- Celestial fruit = 250 XP
		ascended = 250,  -- Ascended fruit = 500 XP
		godly = 500,    -- Godly fruit = 1000 XP
		transcendent = 1000 -- Transcendent fruit = 2500 XP
	},

	-- Other activities
	worker_hire = 10,      -- 10 XP for hiring worker
	sprinkler_buy = 15,    -- 15 XP for buying sprinkler
	pest_clear = 5,        -- 5 XP per pest cleared
	event_participate = 25, -- 25 XP for participating in events
	rebirth = 200          -- 200 XP for rebirth
}

-- Battle Pass Tier Rewards (100 tiers)
local BATTLE_PASS_TIERS = {
	[1] = {
		level = 1,
		free_reward = {type = "coins", amount = 500, name = "500 Coins"},
		premium_reward = {type = "bundle", items = {{type = "coins", amount = 500}, {type = "cosmetic", id = "banana_buddy_hat", name = "Banana Buddy Hat"}}, name = "+500 Coins & Banana Buddy Hat"}
	},
	[2] = {
		level = 2,
		free_reward = {type = "pet", id = "banana_pet_tiny", name = "Banana Pet (Tiny)"},
		premium_reward = {type = "cosmetic", id = "banana_floaty", name = "+Banana Floaty Cosmetic"}
	},
	[3] = {
		level = 3,
		free_reward = {type = "seed", tier = "basic", amount = 1, name = "1 Basic Seed"},
		premium_reward = {type = "seed", tier = "basic", amount = 1, name = "+1 Extra Basic Seed"}
	},
	[4] = {
		level = 4,
		free_reward = {type = "worker_coins", amount = 100, name = "+100 Worker Coins"},
		premium_reward = {type = "cosmetic", id = "banana_socks", name = "+Banana Socks Cosmetic"}
	},
	[5] = {
		level = 5,
		free_reward = {type = "cosmetic", id = "decorative_banana_hat", name = "Decorative Banana Hat"},
		premium_reward = {type = "pet", id = "mini_banana_crate", name = "+Mini Banana Crate Pet"}
	},
	[6] = {
		level = 6,
		free_reward = {type = "coins", amount = 750, name = "750 Coins"},
		premium_reward = {type = "gear", id = "banana_smoothie", name = "+Banana Smoothie Gear"}
	},
	[7] = {
		level = 7,
		free_reward = {type = "gear", id = "banana_bucket", name = "Banana Bucket Gear"},
		premium_reward = {type = "seed", tier = "solid", amount = 1, name = "+1 Solid Seed"}
	},
	[8] = {
		level = 8,
		free_reward = {type = "seed", tier = "basic", amount = 1, name = "1 Basic Seed"},
		premium_reward = {type = "worker_coins", amount = 150, name = "+150 Worker Coins"}
	},
	[9] = {
		level = 9,
		free_reward = {type = "decoration", id = "banana_plush", name = "Banana Plush Decoration"},
		premium_reward = {type = "cosmetic", id = "banana_cape", name = "+Banana Cape Cosmetic"}
	},
	[10] = {
		level = 10,
		free_reward = {type = "seed", tier = "basic", amount = 5, name = "5 Basic Seeds"},
		premium_reward = {type = "seed", tier = "solid", amount = 2, name = "+2 Solid Seeds"}
	},
	[11] = {
		level = 11,
		free_reward = {type = "worker_coins", amount = 200, name = "+200 Worker Coins"},
		premium_reward = {type = "cosmetic", id = "banana_sticker_pack", name = "+Banana Sticker Pack"}
	},
	[12] = {
		level = 12,
		free_reward = {type = "pet", id = "banana_crate", name = "Banana Crate Pet"},
		premium_reward = {type = "pet", id = "banana_bubble", name = "+Banana Bubble Pet"}
	},
	[13] = {
		level = 13,
		free_reward = {type = "seed", tier = "solid", amount = 1, name = "1 Solid Seed"},
		premium_reward = {type = "seed", tier = "solid", amount = 1, name = "+1 Extra Solid Seed"}
	},
	[14] = {
		level = 14,
		free_reward = {type = "gear", id = "banana_umbrella", name = "Banana Umbrella Gear"},
		premium_reward = {type = "cosmetic", id = "banana_punch", name = "+Banana Punch Cosmetic"}
	},
	[15] = {
		level = 15,
		free_reward = {type = "coins", amount = 1000, name = "1,000 Coins"},
		premium_reward = {type = "bundle", items = {{type = "coins", amount = 1000}, {type = "emote", id = "banana_emote", name = "Banana Emote"}}, name = "+1,000 Coins & Banana Emote"}
	},
	[16] = {
		level = 16,
		free_reward = {type = "furniture", id = "banana_beach_towel", name = "Banana Beach Towel"},
		premium_reward = {type = "furniture", id = "banana_hammock_xl", name = "+Banana Hammock (XL)"}
	},
	[17] = {
		level = 17,
		free_reward = {type = "seed", tier = "solid", amount = 1, name = "1 Solid Seed"},
		premium_reward = {type = "seed", tier = "basic", amount = 2, name = "+2 Basic Seeds"}
	},
	[18] = {
		level = 18,
		free_reward = {type = "worker_coins", amount = 250, name = "+250 Worker Coins"},
		premium_reward = {type = "cosmetic", id = "banana_glow_trails", name = "+Banana Glow Trails"}
	},
	[19] = {
		level = 19,
		free_reward = {type = "furniture", id = "banana_hammock", name = "Banana Hammock Furniture"},
		premium_reward = {type = "cosmetic", id = "banana_sleep_mask", name = "+Banana Sleep Mask"}
	},
	[20] = {
		level = 20,
		free_reward = {type = "seed", tier = "solid", amount = 3, name = "3 Solid Seeds"},
		premium_reward = {type = "seed", tier = "legendary", amount = 1, name = "+1 Legendary Seed"}
	},
	[21] = {
		level = 21,
		free_reward = {type = "gear", id = "banana_shades", name = "Banana Shades Gear"},
		premium_reward = {type = "cosmetic", id = "banana_bling", name = "+Banana Bling Cosmetic"}
	},
	[22] = {
		level = 22,
		free_reward = {type = "coins", amount = 1250, name = "1,250 Coins"},
		premium_reward = {type = "seed", tier = "solid", amount = 2, name = "+2 Solid Seeds"}
	},
	[23] = {
		level = 23,
		free_reward = {type = "decoration", id = "banana_flag", name = "Banana Flag Decoration"},
		premium_reward = {type = "gear", id = "banana_staff", name = "+Banana Staff Gear"}
	},
	[24] = {
		level = 24,
		free_reward = {type = "pet", id = "banana_bouncer", name = "Banana Bouncer Pet"},
		premium_reward = {type = "mount", id = "banana_surfboard", name = "+Banana Surfboard Mount"}
	},
	[25] = {
		level = 25,
		free_reward = {type = "seed", tier = "legendary", amount = 1, name = "1 Legendary Seed"},
		premium_reward = {type = "seed", tier = "legendary", amount = 1, name = "+1 Extra Legendary Seed"}
	},
	[26] = {
		level = 26,
		free_reward = {type = "worker_coins", amount = 300, name = "+300 Worker Coins"},
		premium_reward = {type = "decoration", id = "golden_banana_statue", name = "+Golden Banana Statue"}
	},
	[27] = {
		level = 27,
		free_reward = {type = "gear", id = "banana_water_gun", name = "Banana Water Gun Gear"},
		premium_reward = {type = "cosmetic", id = "banana_jetpack_skin", name = "+Banana Jetpack (Skin)"}
	},
	[28] = {
		level = 28,
		free_reward = {type = "seed", tier = "basic", amount = 2, name = "2 Basic Seeds"},
		premium_reward = {type = "seed", tier = "solid", amount = 1, name = "+1 Solid Seed"}
	},
	[29] = {
		level = 29,
		free_reward = {type = "seed", tier = "solid", amount = 1, name = "1 Solid Seed"},
		premium_reward = {type = "pet", id = "banana_tank", name = "+Banana Tank Pet"}
	},
	[30] = {
		level = 30,
		free_reward = {type = "seed", tier = "legendary", amount = 2, name = "2 Legendary Seeds"},
		premium_reward = {type = "seed", tier = "mythical", amount = 1, name = "+1 Mythical Seed"}
	},
	[31] = {
		level = 31,
		free_reward = {type = "decoration", id = "banana_sprinkler_decoration", name = "Banana Sprinkler Decoration"},
		premium_reward = {type = "cosmetic", id = "banana_aura", name = "+Banana Aura Cosmetic"}
	},
	[32] = {
		level = 32,
		free_reward = {type = "seed", tier = "mythical", amount = 1, name = "1 Mythical Seed"},
		premium_reward = {type = "seed", tier = "mythical", amount = 1, name = "+1 Extra Mythical Seed"}
	},
	[33] = {
		level = 33,
		free_reward = {type = "coins", amount = 1500, name = "1,500 Coins"},
		premium_reward = {type = "coins", amount = 2000, name = "+2,000 Coins"}
	},
	[34] = {
		level = 34,
		free_reward = {type = "furniture", id = "banana_dj_set", name = "Banana DJ Set"},
		premium_reward = {type = "gear", id = "banana_bass_speaker", name = "+Banana Bass Speaker"}
	},
	[35] = {
		level = 35,
		free_reward = {type = "cosmetic", id = "banana_mask", name = "Banana Mask"},
		premium_reward = {type = "cosmetic", id = "banana_power_mask", name = "+Banana Power Mask"}
	},
	[36] = {
		level = 36,
		free_reward = {type = "pet", id = "banana_scooter", name = "Banana Scooter Pet"},
		premium_reward = {type = "gear", id = "banana_wheels", name = "+Banana Wheels Gear"}
	},
	[37] = {
		level = 37,
		free_reward = {type = "seed", tier = "solid", amount = 1, name = "1 Solid Seed"},
		premium_reward = {type = "cosmetic", id = "banana_juice_trail", name = "+Banana Juice Trail"}
	},
	[38] = {
		level = 38,
		free_reward = {type = "worker_coins", amount = 350, name = "+350 Worker Coins"},
		premium_reward = {type = "coins", amount = 500, name = "+500 Coins"}
	},
	[39] = {
		level = 39,
		free_reward = {type = "furniture", id = "banana_grill", name = "Banana Grill"},
		premium_reward = {type = "gear", id = "banana_cooking", name = "+Banana Cooking Gear"}
	},
	[40] = {
		level = 40,
		free_reward = {type = "seed", tier = "mythical", amount = 2, name = "2 Mythical Seeds"},
		premium_reward = {type = "seed", tier = "celestial", amount = 1, name = "+1 Celestial Seed"}
	},
	[41] = {
		level = 41,
		free_reward = {type = "cosmetic", id = "banana_hat_2", name = "Banana Hat 2.0"},
		premium_reward = {type = "cosmetic", id = "banana_king_crown", name = "+Banana King's Crown"}
	},
	[42] = {
		level = 42,
		free_reward = {type = "furniture", id = "banana_campfire", name = "Banana Campfire"},
		premium_reward = {type = "cosmetic", id = "banana_fire", name = "+Banana Fire Cosmetic"}
	},
	[43] = {
		level = 43,
		free_reward = {type = "seed", tier = "celestial", amount = 1, name = "1 Celestial Seed"},
		premium_reward = {type = "seed", tier = "mythical", amount = 2, name = "+2 Mythical Seeds"}
	},
	[44] = {
		level = 44,
		free_reward = {type = "coins", amount = 2000, name = "2,000 Coins"},
		premium_reward = {type = "cosmetic", id = "banana_emblem", name = "+Banana Emblem (Back Cosmetic)"}
	},
	[45] = {
		level = 45,
		free_reward = {type = "decoration", id = "banana_painting", name = "Banana Painting"},
		premium_reward = {type = "cosmetic", id = "banana_graffiti", name = "+Banana Graffiti Cosmetic"}
	},
	[46] = {
		level = 46,
		free_reward = {type = "gear", id = "banana_seed_bag", name = "Banana Seed Bag"},
		premium_reward = {type = "cosmetic", id = "banana_carry_case", name = "+Banana Carry Case Cosmetic"}
	},
	[47] = {
		level = 47,
		free_reward = {type = "pet", id = "banana_balloon", name = "Banana Balloon Pet"},
		premium_reward = {type = "pet", id = "banana_monkey", name = "+Banana Monkey Pet"}
	},
	[48] = {
		level = 48,
		free_reward = {type = "seed", tier = "ascended", amount = 1, name = "1 Ascended Seed"},
		premium_reward = {type = "seed", tier = "celestial", amount = 1, name = "+1 Extra Celestial Seed"}
	},
	[49] = {
		level = 49,
		free_reward = {type = "seed", tier = "solid", amount = 3, name = "3 Solid Seeds"},
		premium_reward = {type = "seed", tier = "legendary", amount = 1, name = "+1 Legendary Seed"}
	},
	[50] = {
		level = 50,
		free_reward = {type = "seed", tier = "celestial", amount = 1, name = "1 Celestial Seed"},
		premium_reward = {type = "seed", tier = "ascended", amount = 1, name = "+1 Ascended Seed"}
	},
	[51] = {
		level = 51,
		free_reward = {type = "emote", id = "banana_dance", name = "Banana Dance Emote"},
		premium_reward = {type = "emote", id = "banana_dance_v2", name = "+Banana Dance V2"}
	},
	[52] = {
		level = 52,
		free_reward = {type = "decoration", id = "banana_billboard", name = "Banana Billboard"},
		premium_reward = {type = "cosmetic", id = "banana_ad", name = "+Banana Ad Cosmetic"}
	},
	[53] = {
		level = 53,
		free_reward = {type = "seed", tier = "mythical", amount = 1, name = "1 Mythical Seed"},
		premium_reward = {type = "seed", tier = "celestial", amount = 1, name = "+1 Celestial Seed"}
	},
	[54] = {
		level = 54,
		free_reward = {type = "gear", id = "banana_glowlight", name = "Banana Glowlight"},
		premium_reward = {type = "cosmetic", id = "banana_neon_mask", name = "+Banana Neon Mask"}
	},
	[55] = {
		level = 55,
		free_reward = {type = "coins", amount = 2500, name = "2,500 Coins"},
		premium_reward = {type = "coins", amount = 3000, name = "+3,000 Coins"}
	},
	[56] = {
		level = 56,
		free_reward = {type = "gear", id = "banana_waffle", name = "Banana Waffle Gear"},
		premium_reward = {type = "cosmetic", id = "banana_fork_weapon", name = "+Banana Fork Weapon Skin"}
	},
	[57] = {
		level = 57,
		free_reward = {type = "worker_coins", amount = 500, name = "+500 Worker Coins"},
		premium_reward = {type = "seed", tier = "ascended", amount = 1, name = "+1 Ascended Seed"}
	},
	[58] = {
		level = 58,
		free_reward = {type = "decoration", id = "banana_plushie_mega", name = "Banana Plushie Mega"},
		premium_reward = {type = "cosmetic", id = "banana_plushie", name = "+Banana Plushie Cosmetic"}
	},
	[59] = {
		level = 59,
		free_reward = {type = "furniture", id = "banana_tent", name = "Banana Tent"},
		premium_reward = {type = "mount", id = "banana_camp", name = "+Banana Camp Mount"}
	},
	[60] = {
		level = 60,
		free_reward = {type = "seed", tier = "ascended", amount = 1, name = "1 Ascended Seed"},
		premium_reward = {type = "seed", tier = "godly", amount = 1, name = "+1 Godly Seed"}
	},
	[61] = {
		level = 61,
		free_reward = {type = "seed", tier = "celestial", amount = 1, name = "1 Celestial Seed"},
		premium_reward = {type = "cosmetic", id = "banana_god_cape", name = "+1 Banana God Cape"}
	},
	[62] = {
		level = 62,
		free_reward = {type = "furniture", id = "banana_lawn_chair", name = "Banana Lawn Chair"},
		premium_reward = {type = "furniture", id = "banana_throne_jr", name = "+Banana Throne Jr."}
	},
	[63] = {
		level = 63,
		free_reward = {type = "furniture", id = "banana_swing", name = "Banana Swing"},
		premium_reward = {type = "furniture", id = "golden_banana_swing", name = "+Golden Banana Swing"}
	},
	[64] = {
		level = 64,
		free_reward = {type = "cosmetic", id = "banana_crown", name = "Banana Crown"},
		premium_reward = {type = "cosmetic", id = "banana_royal_aura", name = "+Banana Royal Aura"}
	},
	[65] = {
		level = 65,
		free_reward = {type = "seed", tier = "godly", amount = 1, name = "1 Godly Seed"},
		premium_reward = {type = "seed", tier = "ascended", amount = 1, name = "+1 Extra Ascended Seed"}
	},
	[66] = {
		level = 66,
		free_reward = {type = "mount", id = "banana_surfboard", name = "Banana Surfboard"},
		premium_reward = {type = "cosmetic", id = "surfboard_trail", name = "+Surfboard Trail Cosmetic"}
	},
	[67] = {
		level = 67,
		free_reward = {type = "seed", tier = "mythical", amount = 3, name = "3 Mythical Seeds"},
		premium_reward = {type = "seed", tier = "godly", amount = 1, name = "+1 Godly Seed"}
	},
	[68] = {
		level = 68,
		free_reward = {type = "coins", amount = 3000, name = "3,000 Coins"},
		premium_reward = {type = "coins", amount = 5000, name = "+5,000 Coins"}
	},
	[69] = {
		level = 69,
		free_reward = {type = "gear", id = "banana_jetpack", name = "Banana Jetpack"},
		premium_reward = {type = "cosmetic", id = "banana_rocket_pack", name = "+Banana Rocket Pack Skin"}
	},
	[70] = {
		level = 70,
		free_reward = {type = "seed", tier = "godly", amount = 1, name = "1 Godly Seed"},
		premium_reward = {type = "seed", tier = "celestial", amount = 1, name = "+1 Celestial Seed"}
	},
	[71] = {
		level = 71,
		free_reward = {type = "decoration", id = "banana_king_statue", name = "Banana King Statue"},
		premium_reward = {type = "furniture", id = "banana_king_throne", name = "+Banana King's Throne"}
	},
	[72] = {
		level = 72,
		free_reward = {type = "worker_coins", amount = 800, name = "+800 Worker Coins"},
		premium_reward = {type = "cosmetic", id = "banana_portal", name = "+Banana Portal Cosmetic"}
	},
	[73] = {
		level = 73,
		free_reward = {type = "furniture", id = "banana_throne", name = "Banana Throne"},
		premium_reward = {type = "cosmetic", id = "banana_royal_robe", name = "+Banana Royal Robe"}
	},
	[74] = {
		level = 74,
		free_reward = {type = "gear", id = "banana_torch", name = "Banana Torch Gear"},
		premium_reward = {type = "cosmetic", id = "banana_fire_aura", name = "+Banana Fire Aura"}
	},
	[75] = {
		level = 75,
		free_reward = {type = "pet", id = "banana_fox", name = "Banana Fox Pet"},
		premium_reward = {type = "pet", id = "banana_tiger", name = "+Banana Tiger Pet"}
	},
	[76] = {
		level = 76,
		free_reward = {type = "gear", id = "banana_toolbox", name = "Banana Toolbox Gear"},
		premium_reward = {type = "cosmetic", id = "golden_tool", name = "+Golden Tool Cosmetic"}
	},
	[77] = {
		level = 77,
		free_reward = {type = "decoration", id = "banana_sandcastle", name = "Banana Sandcastle"},
		premium_reward = {type = "pet", id = "banana_castle_mini", name = "+Banana Castle Mini-Pet"}
	},
	[78] = {
		level = 78,
		free_reward = {type = "seed", tier = "mythical", amount = 1, name = "1 Mythical Seed"},
		premium_reward = {type = "seed", tier = "godly", amount = 1, name = "+1 Godly Seed"}
	},
	[79] = {
		level = 79,
		free_reward = {type = "furniture", id = "banana_juice_machine", name = "Banana Juice Machine"},
		premium_reward = {type = "cosmetic", id = "banana_energy", name = "+Banana Energy Cosmetic"}
	},
	[80] = {
		level = 80,
		free_reward = {type = "seed", tier = "godly", amount = 1, name = "1 Godly Seed"},
		premium_reward = {type = "seed", tier = "ascended", amount = 1, name = "+1 Ascended Seed"}
	},
	[81] = {
		level = 81,
		free_reward = {type = "furniture", id = "banana_hammock_xl", name = "Banana Hammock XL"},
		premium_reward = {type = "furniture", id = "banana_pool_float", name = "+Banana Pool Float"}
	},
	[82] = {
		level = 82,
		free_reward = {type = "furniture", id = "banana_generator", name = "Banana Generator"},
		premium_reward = {type = "cosmetic", id = "banana_energy_core", name = "+Banana Energy Core Cosmetic"}
	},
	[83] = {
		level = 83,
		free_reward = {type = "gear", id = "banana_cookout_pack", name = "Banana Cookout Pack"},
		premium_reward = {type = "gear", id = "banana_chef", name = "+Banana Chef Gear"}
	},
	[84] = {
		level = 84,
		free_reward = {type = "furniture", id = "banana_alarm_clock", name = "Banana Alarm Clock"},
		premium_reward = {type = "cosmetic", id = "banana_timekeeper_trail", name = "+Banana Timekeeper Trail"}
	},
	[85] = {
		level = 85,
		free_reward = {type = "seed", tier = "celestial", amount = 1, name = "1 Celestial Seed"},
		premium_reward = {type = "seed", tier = "ascended", amount = 1, name = "+1 Ascended Seed"}
	},
	[86] = {
		level = 86,
		free_reward = {type = "seed", tier = "ascended", amount = 3, name = "3 Ascended Seeds"},
		premium_reward = {type = "seed", tier = "godly", amount = 1, name = "+1 Godly Seed"}
	},
	[87] = {
		level = 87,
		free_reward = {type = "seed", tier = "legendary", amount = 1, name = "1 Legendary Seed"},
		premium_reward = {type = "seed", tier = "mythical", amount = 1, name = "+1 Mythical Seed"}
	},
	[88] = {
		level = 88,
		free_reward = {type = "seed", tier = "mythical", amount = 1, name = "1 Mythical Seed"},
		premium_reward = {type = "seed", tier = "celestial", amount = 1, name = "+1 Celestial Seed"}
	},
	[89] = {
		level = 89,
		free_reward = {type = "seed", tier = "solid", amount = 1, name = "1 Solid Seed"},
		premium_reward = {type = "seed", tier = "legendary", amount = 1, name = "+1 Legendary Seed"}
	},
	[90] = {
		level = 90,
		free_reward = {type = "seed", tier = "mythical", amount = 1, name = "1 Mythical Seed"},
		premium_reward = {type = "seed", tier = "godly", amount = 1, name = "+1 Godly Seed"}
	},
	[91] = {
		level = 91,
		free_reward = {type = "decoration", id = "banana_statue_final", name = "Banana Statue (Final Form)"},
		premium_reward = {type = "decoration", id = "banana_core_totem", name = "+Banana Core Totem"}
	},
	[92] = {
		level = 92,
		free_reward = {type = "mount", id = "banana_cart", name = "Banana Cart Mount"},
		premium_reward = {type = "mount", id = "golden_banana_cart", name = "+Golden Banana Cart"}
	},
	[93] = {
		level = 93,
		free_reward = {type = "seed", tier = "ascended", amount = 1, name = "1 Ascended Seed"},
		premium_reward = {type = "seed", tier = "godly", amount = 1, name = "+1 Godly Seed"}
	},
	[94] = {
		level = 94,
		free_reward = {type = "furniture", id = "banana_throne_xl", name = "Banana Throne XL"},
		premium_reward = {type = "furniture", id = "banana_empire_throne", name = "+Banana Empire Throne"}
	},
	[95] = {
		level = 95,
		free_reward = {type = "cosmetic", id = "banana_god_mask", name = "Banana God Mask"},
		premium_reward = {type = "cosmetic", id = "banana_ascendant_mask", name = "+Banana Ascendant Mask"}
	},
	[96] = {
		level = 96,
		free_reward = {type = "seed", tier = "godly", amount = 1, name = "1 Godly Seed"},
		premium_reward = {type = "seed", tier = "celestial", amount = 1, name = "+1 Celestial Seed"}
	},
	[97] = {
		level = 97,
		free_reward = {type = "seed", tier = "celestial", amount = 2, name = "2 Celestial Seeds"},
		premium_reward = {type = "seed", tier = "ascended", amount = 1, name = "+1 Ascended Seed"}
	},
	[98] = {
		level = 98,
		free_reward = {type = "seed", tier = "ascended", amount = 1, name = "1 Ascended Seed"},
		premium_reward = {type = "seed", tier = "godly", amount = 1, name = "+1 Godly Seed"}
	},
	[99] = {
		level = 99,
		free_reward = {type = "gear", id = "banana_lightning_orb", name = "Banana Lightning Orb"},
		premium_reward = {type = "cosmetic", id = "banana_storm_trail", name = "+Banana Storm Trail"}
	},
	[100] = {
		level = 100,
		free_reward = {type = "seed", tier = "transcendent", amount = 1, name = "1 Transcendent Seed"},
		premium_reward = {type = "cosmetic", id = "transcendent_banana_relic", name = "+Transcendent Banana Relic Cosmetic"}
	}
}

-- Battle Pass System
local BattlePassSystem = {}

-- Player data tracking
local playerData = {}

-- Initialize player data
local function initializePlayer(player)
	local userId = player.UserId

	-- Load or create player data
	local success, data = pcall(function()
		return battlePassStore:GetAsync(userId)
	end)

	if success and data then
		playerData[userId] = data
	else
		playerData[userId] = {
			level = 1,
			xp = 0,
			totalXp = 0,
			hasPremium = false,
			claimedRewards = {
				free = {},
				premium = {}
			},
			seasonStartTime = tick()
		}
	end

	-- Check if player has premium gamepass
	local hasPremium = false
	pcall(function()
		hasPremium = MarketplaceService:UserOwnsGamePassAsync(userId, PREMIUM_GAMEPASS_ID)
	end)

	playerData[userId].hasPremium = hasPremium

	print("🎫 Battle Pass initialized for " .. player.Name .. " (Level " .. playerData[userId].level .. ", " .. playerData[userId].xp .. " XP)")
end

-- Save player data
local function savePlayerData(userId)
	if not playerData[userId] then return end

	pcall(function()
		battlePassStore:SetAsync(userId, playerData[userId])
	end)
end

-- Calculate level from total XP
local function calculateLevel(totalXp)
	local level = 1
	local xpNeeded = 0

	-- Level progression: Level 1 = 1 XP, Level 2 = 3 XP total (1+2), Level 3 = 6 XP total (1+2+3), etc.
	while level <= 100 do
		xpNeeded = xpNeeded + level
		if totalXp < xpNeeded then
			break
		end
		level = level + 1
	end

	return math.min(level, 100)
end

-- Get XP needed for next level
local function getXpForNextLevel(currentLevel)
	if currentLevel >= 100 then return 0 end
	return currentLevel + 1
end

-- Add XP to player
function BattlePassSystem.addXP(player, amount, source)
	if not player or not player.Parent then return end

	local userId = player.UserId
	if not playerData[userId] then
		initializePlayer(player)
	end

	local data = playerData[userId]
	local oldLevel = data.level

	-- Add XP
	data.totalXp = data.totalXp + amount
	data.level = calculateLevel(data.totalXp)

	-- Calculate current level XP
	local xpForCurrentLevel = 0
	for i = 1, data.level - 1 do
		xpForCurrentLevel = xpForCurrentLevel + i
	end
	data.xp = data.totalXp - xpForCurrentLevel

	-- Check for level up
	if data.level > oldLevel then
		-- Level up notification
		if _G.NotificationSystem and _G.NotificationSystem.showNotification then
			_G.NotificationSystem.showNotification(player, 
				"🎫 Battle Pass Level Up! You reached Level " .. data.level .. "!", 
				"legendary")
		end

		-- Check for new rewards
		for level = oldLevel + 1, data.level do
			if BATTLE_PASS_TIERS[level] then
				if _G.NotificationSystem and _G.NotificationSystem.showNotification then
					_G.NotificationSystem.showNotification(player, 
						"🎁 New Battle Pass rewards available at Level " .. level .. "!", 
						"info")
				end
			end
		end

		print("🎫 " .. player.Name .. " leveled up to Battle Pass Level " .. data.level)
	end

	-- XP gain notification
	if _G.NotificationSystem and _G.NotificationSystem.showNotification then
		_G.NotificationSystem.showNotification(player, 
			"+" .. amount .. " XP from " .. (source or "activity"), 
			"info")
	end

	-- Save data
	savePlayerData(userId)

	-- Update client UI if exists
	local updateBattlePassRemote = ReplicatedStorage:FindFirstChild("UpdateBattlePass")
	if updateBattlePassRemote then
		updateBattlePassRemote:FireClient(player, BattlePassSystem.getPlayerData(player))
	end
end

-- Get player battle pass data
function BattlePassSystem.getPlayerData(player)
	if not player or not player.Parent then return nil end

	local userId = player.UserId
	if not playerData[userId] then
		initializePlayer(player)
	end

	return playerData[userId]
end

-- Claim reward
function BattlePassSystem.claimReward(player, level, rewardType)
	if not player or not player.Parent then return false end

	local userId = player.UserId
	if not playerData[userId] then
		initializePlayer(player)
		return false
	end

	local data = playerData[userId]

	-- Check if player has reached the level
	if data.level < level then
		return false, "Level not reached"
	end

	-- Check if reward already claimed
	if data.claimedRewards[rewardType][level] then
		return false, "Reward already claimed"
	end

	-- Check if premium reward and player doesn't have premium
	if rewardType == "premium" and not data.hasPremium then
		return false, "Premium Battle Pass required"
	end

	-- Get reward data
	local tierData = BATTLE_PASS_TIERS[level]
	if not tierData then
		return false, "Invalid level"
	end

	local reward = tierData[rewardType .. "_reward"]
	if not reward then
		return false, "No reward data"
	end

	-- Give reward
	local success = BattlePassSystem.giveReward(player, reward)
	if success then
		-- Mark as claimed
		data.claimedRewards[rewardType][level] = true
		savePlayerData(userId)

		-- Notification
		if _G.NotificationSystem and _G.NotificationSystem.showNotification then
			_G.NotificationSystem.showNotification(player, 
				"🎁 Claimed: " .. reward.name, 
				"legendary")
		end

		print("🎁 " .. player.Name .. " claimed " .. rewardType .. " reward at level " .. level .. ": " .. reward.name)
		return true
	end

	return false, "Failed to give reward"
end

-- Give reward to player
function BattlePassSystem.giveReward(player, reward)
	if not player or not player.Parent then return false end

	if reward.type == "coins" then
		-- Give coins
		if _G.CoinSystem and _G.CoinSystem.addCoins then
			_G.CoinSystem.addCoins(player, reward.amount)
			return true
		end
	elseif reward.type == "worker_coins" then
		-- Give worker coins
		if _G.WorkerSystem and _G.WorkerSystem.addWorkerCoins then
			_G.WorkerSystem.addWorkerCoins(player, reward.amount)
			return true
		end
	elseif reward.type == "seed" then
		-- Give seeds
		if _G.InventorySystem and _G.InventorySystem.addSeed then
			for i = 1, reward.amount do
				_G.InventorySystem.addSeed(player, reward.tier)
			end
			return true
		end
	elseif reward.type == "bundle" then
		-- Give multiple items
		local success = true
		for _, item in ipairs(reward.items) do
			if not BattlePassSystem.giveReward(player, item) then
				success = false
			end
		end
		return success
	else
		-- For cosmetics, pets, furniture, etc. - just mark as owned
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local rewardValue = leaderstats:FindFirstChild("BattlePassRewards")
			if not rewardValue then
				rewardValue = Instance.new("StringValue")
				rewardValue.Name = "BattlePassRewards"
				rewardValue.Value = reward.id or reward.name
				rewardValue.Parent = leaderstats
			else
				rewardValue.Value = rewardValue.Value .. "," .. (reward.id or reward.name)
			end
		end
		return true
	end

	return false
end

-- XP Source Integration Functions
function BattlePassSystem.onBananaSell(player, bananaCount)
	local xp = bananaCount * XP_VALUES.banana_sell
	BattlePassSystem.addXP(player, xp, "selling bananas")
end

function BattlePassSystem.onQuestComplete(player)
	BattlePassSystem.addXP(player, XP_VALUES.quest_complete, "quest completion")
end

function BattlePassSystem.onFruitPurchase(player, fruitTier)
	local xp = XP_VALUES.fruit_purchase[fruitTier] or 5
	BattlePassSystem.addXP(player, xp, "buying " .. fruitTier .. " fruit")
end

function BattlePassSystem.onWorkerHire(player)
	BattlePassSystem.addXP(player, XP_VALUES.worker_hire, "hiring worker")
end

function BattlePassSystem.onSprinklerBuy(player)
	BattlePassSystem.addXP(player, XP_VALUES.sprinkler_buy, "buying sprinkler")
end

function BattlePassSystem.onPestClear(player, pestCount)
	local xp = pestCount * XP_VALUES.pest_clear
	BattlePassSystem.addXP(player, xp, "clearing pests")
end

function BattlePassSystem.onEventParticipate(player)
	BattlePassSystem.addXP(player, XP_VALUES.event_participate, "event participation")
end

function BattlePassSystem.onRebirth(player)
	BattlePassSystem.addXP(player, XP_VALUES.rebirth, "rebirth")
end

-- Reset season (admin only)
function BattlePassSystem.resetSeason(adminPlayer)
	if adminPlayer.UserId ~= 3389224707 then return false end -- Replace with your user ID

	for userId, data in pairs(playerData) do
		data.level = 1
		data.xp = 0
		data.totalXp = 0
		data.claimedRewards = {free = {}, premium = {}}
		data.seasonStartTime = tick()
		savePlayerData(userId)
	end

	print("🎫 Battle Pass season reset by " .. adminPlayer.Name)
	return true
end

-- Player connection handlers
Players.PlayerAdded:Connect(function(player)
	initializePlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	if playerData[userId] then
		savePlayerData(userId)
		playerData[userId] = nil
	end
end)

-- Auto-save every 5 minutes
RunService.Heartbeat:Connect(function()
	if tick() % 300 < 1 then -- Every 5 minutes
		for userId, _ in pairs(playerData) do
			savePlayerData(userId)
		end
	end
end)

-- Global access
_G.BattlePassSystem = BattlePassSystem

print("🎫 Battle Pass System Loaded!")
print("   - 100 tiers of rewards")
print("   - XP from selling, quests, fruit purchases, and more")
print("   - Free and Premium reward tracks")
print("   - Level progression: Level N requires N XP to advance")

return BattlePassSystem
