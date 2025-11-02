# Banana Game - Complete Setup Instructions

## Overview

This is a **hybrid farming/city management Roblox game** featuring:

- Fruit/seed farming and harvesting system
- Building placement and passive income generation
- City/Empire management with citizens, mood, and taxes
- Battle Pass progression system (100 tiers)
- Quest system, title system, and random events
- Worker automation and rebirth mechanics

---

## Critical Setup Steps

### 1. Configure Admin User IDs

**IMPORTANT**: Update admin IDs before publishing your game.

Edit [ServerScriptService/AdminCommands.luau](ServerScriptService/AdminCommands.luau):

```lua
local ADMIN_IDS = {
    12345678,  -- Replace with your admin user IDs
    87654321,  -- Add more as needed
}
local OWNER_ID = 3389224707 -- Replace with YOUR Roblox user ID
```

The OWNER_ID `3389224707` appears in multiple scripts - search and replace with your actual ID.

### 2. DataStore Access

Enable DataStore access in Game Settings > Security:

- DataStoreService must be enabled
- API access enabled for HTTP requests (if using external features)

**Active DataStores:**

- PlayerData (Blox currency, inventory, seeds, workers, rebirths)
- PlayerTitles (unlocked titles and equipped title)
- PlayerSettings (UI preferences, display settings)
- BattlePassData (tier progress, claimed rewards)
- QuestData (daily quest progress)
- EmpireData (citizen mood, tax rates, buildings)

### 3. RemoteEvents Setup

The game will automatically create RemoteEvents in ReplicatedStorage. If you encounter errors, manually create a `RemoteEvents` folder in ReplicatedStorage.

### 4. Clean Up Before Publishing

**Remove test/deprecated scripts:**

```
ServerScriptService/
├── SystemTest.luau (test script)
├── TestScript.luau (test script)
├── CoinSystem.luau (DEPRECATED - use BloxSystem)
└── SellingSystem.luau (DEPRECATED - use TruckSellingSystem)

StarterPlayer/StarterPlayerScripts/
└── CoinGUI.luau (DEPRECATED - use BloxGUI)
```

**Fix duplicate folders:**

- Remove nested `ServerScriptService/StarterPlayer/` and `ServerScriptService/ReplicatedStorage/` folders
- Scripts should only be in the proper service folders

---

## Core Game Systems

### Economy & Currency

#### BloxSystem (Primary Currency)

- **File**: [ServerScriptService/BloxSystem.luau](ServerScriptService/BloxSystem.luau)
- **GUI**: [StarterPlayer/StarterPlayerScripts/BloxGUI.luau](StarterPlayer/StarterPlayerScripts/BloxGUI.luau)
- **Function**: Main currency system (replaces deprecated CoinSystem)
- **Features**: Add/remove Blox, persistent storage, global access via `_G.BloxSystem`

#### BuildingMoneySystem (Passive Income)

- **Files**:
  - [ServerScriptService/BuildingMoneySystem.luau](ServerScriptService/BuildingMoneySystem.luau)
  - [StarterPlayer/StarterPlayerScripts/BuildingMoneyUI.luau](StarterPlayer/StarterPlayerScripts/BuildingMoneyUI.luau)
- **Function**: Buildings generate passive Blox income over time

### Farming Systems

#### SeedSystem

- **File**: [ServerScriptService/SeedSystem.luau](ServerScriptService/SeedSystem.luau)
- **Seed Types**: Banapple, Mango, Special, Mythical
- **Features**: Inventory management, seed planting, growth tracking

#### PlotBananaGrowth

- **File**: [ServerScriptService/PlotBananaGrowth.luau](ServerScriptService/PlotBananaGrowth.luau)
- **Function**: Per-plot fruit spawning, weight calculation, growth stages

#### HarvestFruitServer

- **File**: [ServerScriptService/HarvestFruitServer.luau](ServerScriptService/HarvestFruitServer.luau)
- **Function**: Handles fruit collection, weight tracking, inventory updates

#### SprinklerSystem

- **File**: [ServerScriptService/SprinklerSystem.luau](ServerScriptService/SprinklerSystem.luau)
- **Function**: Growth acceleration for planted seeds

#### TrowelSeedRemoval

- **File**: [ServerScriptService/TrowelSeedRemoval.luau](ServerScriptService/TrowelSeedRemoval.luau)
- **Function**: Tool for removing planted seeds

### City/Empire Management

#### EmpireSystem

- **File**: [ServerScriptService/EmpireSystem.luau](ServerScriptService/EmpireSystem.luau)
- **Features**:
  - Citizen mood system (affects income)
  - Tax rate management (player-adjustable)
  - Job assignments for citizens
  - Passive income calculation
  - Building-based mood modifiers

#### CivilianSystem

- **File**: [ServerScriptService/CivilianSystem.luau](ServerScriptService/CivilianSystem.luau)
- **Function**: Spawns NPC civilians, pathfinding, building navigation

### Building Systems

#### BuildingPlacementSystem

- **Files**:
  - [ServerScriptService/BuildingPlacementSystem.luau](ServerScriptService/BuildingPlacementSystem.luau)
  - [StarterPlayer/StarterPlayerScripts/BuildingPlacementClient.luau](StarterPlayer/StarterPlayerScripts/BuildingPlacementClient.luau)
- **Features**: Preview outline, collision detection, placement validation

#### PickUpBuildingSystem

- **File**: [ServerScriptService/PickUpBuildingSystem.luau](ServerScriptService/PickUpBuildingSystem.luau)
- **Function**: Remove/relocate placed buildings

#### HammerTool

- **File**: [StarterPlayer/StarterPlayerScripts/HammerTool.luau](StarterPlayer/StarterPlayerScripts/HammerTool.luau)
- **Function**: Client-side building interaction tool

### Selling & Trading

#### TruckSellingSystem

- **File**: [ServerScriptService/TruckSellingSystem.luau](ServerScriptService/TruckSellingSystem.luau)
- **Features**: Minigame-based selling with rank multipliers (S, A, B, C, D, F)

#### VendorServer & VendorClient

- **Files**:
  - [ServerScriptService/VendorServer.luau](ServerScriptService/VendorServer.luau)
  - [StarterPlayer/StarterPlayerScripts/VendorClient.luau](StarterPlayer/StarterPlayerScripts/VendorClient.luau)
- **Function**: NPC trading system for fruits and seeds

#### FruitVendorNPC

- **File**: [ServerScriptService/FruitVendorNPC.luau](ServerScriptService/FruitVendorNPC.luau)
- **Function**: Alternative fruit vendor system

### Progression Systems

#### BattlePassSystem

- **Files**:
  - [ServerScriptService/BattlePassSystem.luau](ServerScriptService/BattlePassSystem.luau)
  - [StarterPlayer/StarterPlayerScripts/BattlePassClient.luau](StarterPlayer/StarterPlayerScripts/BattlePassClient.luau)
- **Features**: 100-tier seasonal progression, free & premium rewards

#### RebirthSystem

- **File**: [ServerScriptService/RebirthSystem.luau](ServerScriptService/RebirthSystem.luau)
- **Function**: Progress reset with permanent upgrades, worker unlocks

#### QuestSystem

- **File**: [ServerScriptService/QuestSystem.luau](ServerScriptService/QuestSystem.luau)
- **Quest Types**: Harvest, Plant, Sell, Build, Explore
- **Rewards**: Blox, XP, items

#### PlayerTitleSystem

- **File**: [ServerScriptService/PlayerTitleSystem.luau](ServerScriptService/PlayerTitleSystem.luau)
- **Features**: 22+ achievement-based titles, color customization, code redemption

**Example Redemption Codes:**

```lua
local RedemptionCodes = {
    ["WELCOME"] = { title = "City Founder", blox = 1000 },
    ["EMPIRE"] = { title = "Empire Builder", blox = 2500 },
    ["CITIZEN"] = { title = "Citizen Leader", blox = 5000 },
    ["TAXTIME"] = { title = "Tax Master", blox = 10000 },
    ["DEVELOPER"] = { title = "Developer", blox = 50000 }
}
```

### Worker & Automation

#### WorkerSystem

- **File**: [ServerScriptService/WorkerSystem.luau](ServerScriptService/WorkerSystem.luau)
- **Worker Tiers**:
  - Tier 1: 1,000 Blox
  - Tier 2: 10,000 Blox
  - Tier 3: 100,000 Blox
  - Tier 4: 500,000 Blox
  - Tier 5: 1,000,000 Blox
- **Features**: Automated harvesting, planting, selling

#### AFKSystem

- **File**: [ServerScriptService/AFKSystem.luau](ServerScriptService/AFKSystem.luau)
- **Function**: Passive resource generation while AFK

### Events & Challenges

#### RandomEventSystem

- **File**: [ServerScriptService/RandomEventSystem.luau](ServerScriptService/RandomEventSystem.luau)
- **Events**: Storm, Plague, Monkey Raid, Nuclear Meltdown, Golden Hour, etc.
- **Frequency**: Every 20-30 minutes

#### BananaThiefEvent

- **File**: [ServerScriptService/BananaThiefEvent.luau](ServerScriptService/BananaThiefEvent.luau)
- **Function**: Random NPC thief steals player fruit

#### BananaKingBossEvent

- **File**: [ServerScriptService/BananaKingBossEvent.luau](ServerScriptService/BananaKingBossEvent.luau)
- **Function**: Boss fight event with rewards

#### PVPBananaHeistEvent

- **File**: [ServerScriptService/PVPBananaHeistEvent.luau](ServerScriptService/PVPBananaHeistEvent.luau)
- **Function**: Competitive multiplayer heist event

#### NuclearMeltdownEvent

- **File**: [ServerScriptService/NuclearMeltdownEvent.luau](ServerScriptService/NuclearMeltdownEvent.luau)
- **Function**: Catastrophic event affecting entire server

#### PestSystem

- **File**: [ServerScriptService/PestSystem.luau](ServerScriptService/PestSystem.luau)
- **Function**: Cockroach infestations with insurance mechanic

### Admin & Moderation

#### AdminCommands

- **Files**:
  - [ServerScriptService/AdminCommands.luau](ServerScriptService/AdminCommands.luau)
  - [StarterPlayer/StarterPlayerScripts/AdminCommandsClient.luau](StarterPlayer/StarterPlayerScripts/AdminCommandsClient.luau)
- **Commands**: Event triggers, mood control, currency management
- **Access Levels**: Owner-only and Admin-tier commands

#### Gampasses

- **File**: [ServerScriptService/Gampasses.luau](ServerScriptService/Gampasses.luau)
- **Function**: GamePass validation and benefits

### Player Interface

#### MainGameInterface

- **File**: [StarterPlayer/StarterPlayerScripts/MainGameInterface.luau](StarterPlayer/StarterPlayerScripts/MainGameInterface.luau)
- **Function**: Consolidated UI with tabbed interface

#### Settings

- **File**: [StarterPlayer/StarterPlayerScripts/Settings.luau](StarterPlayer/StarterPlayerScripts/Settings.luau)
- **Features**: Display preferences, performance mode, visibility toggles

#### PlayerDisplaySystem

- **File**: [StarterPlayer/StarterPlayerScripts/PlayerDisplaySystem.luau](StarterPlayer/StarterPlayerScripts/PlayerDisplaySystem.luau)
- **Function**: Username and title display above player heads, distance-based fading

#### DetailedInventoryGUI

- **File**: [StarterPlayer/StarterPlayerScripts/DetailedInventoryGUI.luau](StarterPlayer/StarterPlayerScripts/DetailedInventoryGUI.luau)
- **Function**: Seed and fruit inventory display

### Special Features

#### MafiaQuestServer & MafiaQuestClient

- **Files**:
  - [ServerScriptService/MafiaQuestServer.luau](ServerScriptService/MafiaQuestServer.luau)
  - [StarterPlayer/StarterPlayerScripts/MafiaQuestClient.luau](StarterPlayer/StarterPlayerScripts/MafiaQuestClient.luau)
- **Function**: Special quest line with Monkey Mafia theme

#### LeaderboardSetup

- **File**: [ServerScriptService/LeaderboardSetup.luau](ServerScriptService/LeaderboardSetup.luau)
- **Function**: Server leaderboard for top players

#### PlotFinder

- **File**: [ServerScriptService/PlotFinder.luau](ServerScriptService/PlotFinder.luau)
- **Function**: Assigns plots to players on join

---

## GamePasses

**Location**: Shop Scripts/

All GamePass scripts enhance gameplay without being pay-to-win:

1. **AutoSellPass** - Automatically sells harvested fruit
2. **BananaBuddyPass** - Companion pet with bonuses
3. **BananaAlarmPass** - Notifications for events
4. **BananaJackpotPass** - Increased rare drop chances
5. **BananaTaxTrollPass** - Tax reduction benefits
6. **GildrainSeedPass** - Access to premium Gildrain seeds
7. **MonkeyMessengerPass** - Quest tracking features
8. **PestZapperPass** - Pest prevention tool
9. **PestOverdrive (Global & Server)** - Enhanced pest control
10. **SeedSaverProPass** - Seed preservation features

---

## File Structure

```
Banana/
├── ServerScriptService/ (51 scripts)
│   ├── Economy
│   │   ├── BloxSystem.luau ✅
│   │   ├── BuildingMoneySystem.luau ✅
│   │   ├── CoinSystem.luau ❌ DEPRECATED
│   │   └── SellingSystem.luau ❌ DEPRECATED
│   │
│   ├── Farming
│   │   ├── SeedSystem.luau ✅
│   │   ├── PlotBananaGrowth.luau ✅
│   │   ├── HarvestFruitServer.luau ✅
│   │   ├── SeedGrowth.luau ✅
│   │   ├── SeedPlantingSystem.luau ✅
│   │   ├── SeedPurchaseSystem.luau ✅
│   │   ├── SprinklerSystem.luau ✅
│   │   ├── GildrainSeed.luau ✅
│   │   └── TrowelSeedRemoval.luau ✅
│   │
│   ├── City/Empire
│   │   ├── EmpireSystem.luau ✅
│   │   ├── CivilianSystem.luau ✅
│   │   └── PlotFinder.luau ✅
│   │
│   ├── Buildings
│   │   ├── BuildingPlacementSystem.luau ✅
│   │   └── PickUpBuildingSystem.luau ✅
│   │
│   ├── Selling/Trading
│   │   ├── TruckSellingSystem.luau ✅
│   │   ├── VendorServer.luau ✅
│   │   └── FruitVendorNPC.luau ✅
│   │
│   ├── Progression
│   │   ├── BattlePassSystem.luau ✅
│   │   ├── RebirthSystem.luau ✅
│   │   ├── QuestSystem.luau ✅
│   │   └── PlayerTitleSystem.luau ✅
│   │
│   ├── Workers/Automation
│   │   ├── WorkerSystem.luau ✅
│   │   └── AFKSystem.luau ✅
│   │
│   ├── Events
│   │   ├── RandomEventSystem.luau ✅
│   │   ├── BananaThiefEvent.luau ✅
│   │   ├── BananaKingBossEvent.luau ✅
│   │   ├── PVPBananaHeistEvent.luau ✅
│   │   ├── NuclearMeltdownEvent.luau ✅
│   │   └── PestSystem.luau ✅
│   │
│   ├── Admin
│   │   ├── AdminCommands.luau ✅
│   │   └── Gampasses.luau ✅
│   │
│   └── Misc
│       ├── LeaderboardSetup.luau ✅
│       ├── SetupScript.luau ✅
│       ├── FarmingGameMaster.luau ✅
│       ├── MafiaQuestServer.luau ✅
│       ├── SystemTest.luau ❌ TEST ONLY
│       └── TestScript.luau ❌ TEST ONLY
│
├── StarterPlayer/StarterPlayerScripts/ (19 scripts)
│   ├── MainGameInterface.luau ✅
│   ├── Settings.luau ✅
│   ├── PlayerDisplaySystem.luau ✅
│   ├── BloxGUI.luau ✅
│   ├── CoinGUI.luau ❌ DEPRECATED
│   ├── BattlePassClient.luau ✅
│   ├── AdminCommandsClient.luau ✅
│   ├── VendorClient.luau ✅
│   ├── MafiaQuestClient.luau ✅
│   ├── BuildingMoneyUI.luau ✅
│   ├── BuildingPlacementClient.luau ✅
│   ├── DetailedInventoryGUI.luau ✅
│   ├── HammerTool.luau ✅
│   ├── FruitStealingClient.luau ✅
│   ├── PlantingInstructions.luau ⚠️
│   ├── PlantingSettings.luau ⚠️
│   ├── InteractiveSeedPlanting.luau ⚠️
│   └── SeedToolIntegration.luau ⚠️
│
└── Shop Scripts/ (13 GamePass scripts)
    ├── AutoSellPass.luau
    ├── BananaBuddyPass.luau
    ├── BananaAlarmPass.luau
    ├── BananaJackpotPass.luau
    ├── BananaTaxTrollPass.luau
    ├── GildrainSeedPass.luau
    ├── MonkeyMessengerPass.luau
    ├── PestZapperPass.luau
    ├── PestOverdrive(Global)Pass.luau
    ├── PestOverdrive(Server)Pass.luau
    └── SeedSaverProPass.luau
```

**Legend:**

- ✅ Active/Current
- ❌ Deprecated/Remove
- ⚠️ Verify functionality

---

## Pre-Launch Checklist

### Configuration

- [ ] Update `ADMIN_IDS` in AdminCommands.luau
- [ ] Replace `OWNER_ID = 3389224707` with your Roblox user ID (search all scripts)
- [ ] Enable DataStore access in game settings
- [ ] Test all DataStore systems save/load correctly

### Code Cleanup

- [ ] Remove `SystemTest.luau` and `TestScript.luau`
- [ ] Remove deprecated `CoinSystem.luau` and `SellingSystem.luau`
- [ ] Remove deprecated `CoinGUI.luau`
- [ ] Remove duplicate folders: `ServerScriptService/StarterPlayer/` and `ServerScriptService/ReplicatedStorage/`
- [ ] Verify no scripts reference `_G.CoinSystem` (should use `_G.BloxSystem`)

### Testing

- [ ] Test farming system (plant, grow, harvest)
- [ ] Test city/empire system (buildings, citizens, mood, taxes)
- [ ] Test selling systems (TruckSellingSystem, VendorServer)
- [ ] Test progression (BattlePass, Quests, Rebirths, Workers)
- [ ] Test random events trigger correctly
- [ ] Test GamePasses function properly
- [ ] Test admin commands work with configured admin IDs
- [ ] Test title system and code redemption
- [ ] Verify RemoteEvents folder created in ReplicatedStorage

### Performance

- [ ] Test with multiple players (10+)
- [ ] Monitor server memory and CPU usage
- [ ] Enable low-performance mode option in Settings
- [ ] Optimize civilian pathfinding if needed

### Balance

- [ ] Verify Blox economy is balanced
- [ ] Test worker tier costs are appropriate
- [ ] Ensure GamePasses provide value without being pay-to-win
- [ ] Check event frequency and rewards

---

## Troubleshooting

### DataStore Errors

- Ensure DataStore access is enabled in game settings
- Check Output for specific error messages
- Verify you're not hitting DataStore request limits

### RemoteEvents Missing

- Scripts auto-create RemoteEvents folder in ReplicatedStorage
- If errors occur, manually create the folder and restart

### Admin Commands Not Working

- Verify your user ID is in ADMIN_IDS or OWNER_ID
- Check Output for permission errors
- Ensure AdminCommands and AdminCommandsClient are both present

### Currency Not Saving

- Confirm BloxSystem is active (not CoinSystem)
- Check DataStore access
- Verify no script errors in Output

### Buildings Not Placing

- Check collision detection settings
- Verify BuildingPlacementSystem and BuildingPlacementClient are both active
- Test with different building types

### Workers Not Working

- Verify WorkerSystem is enabled
- Check player has purchased worker tier
- Ensure rebirth level meets worker requirements

---

## Architecture Notes

This game combines **two gameplay modes**:

1. **Farming Mode**: Traditional seed planting, fruit harvesting, selling
2. **City/Empire Mode**: Building placement, citizen management, passive income

Both systems coexist and share the Blox currency. Players can engage with either or both systems.

**Key Integration Points:**

- BloxSystem (shared currency)
- BuildingMoneySystem (passive income from buildings)
- TruckSellingSystem (selling harvested fruit)
- QuestSystem (quests for both modes)

---

## Support & Updates

**Current Version**: Hybrid Farming/City Management (2024)

**Previous Versions**:

- Pure farming game (deprecated scripts removed)
- Coin-based economy (migrated to Blox)

For issues or questions, check the Output console for error messages and verify all setup steps are completed.

---

## Success

Your Banana Game is ready to publish once you complete the pre-launch checklist. Players can:

- Plant and harvest fruit on their plots
- Build and manage their own city/empire
- Progress through 100-tier Battle Pass
- Complete daily quests and achievements
- Unlock titles and workers
- Experience random events and challenges
- Purchase GamePasses for enhanced gameplay

**Have fun building your banana empire!**
