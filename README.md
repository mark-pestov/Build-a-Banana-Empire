# 🍌 Build a Banana Empire Roblox Game

A Roblox plot-based game with a unique conveyor pathway system where buildings travel past player plots.

## Overview

Players get assigned individual plots (up to 8 players) where they can interact with buildings that move along a central conveyor pathway. Buildings spawn and travel from one end of the map to the other, allowing players to buy or steal them as they pass by.

## Game Features

### Plot System
- **8 player plots** with automatic assignment
- Player-specific plot teleportation on spawn
- Custom plot signs showing player name and avatar
- Plot management with PlotHolders system

### Pathway/Conveyor System
- Central conveyor belt that moves buildings across the map
- Buildings spawn randomly from templates
- Configurable conveyor speed (10 studs/second)
- Buildings can be purchased or stolen as they pass

## Development

### Prerequisites

- **Git** - Version control
- **GitHub Account** - For hosting and CI/CD
- **Roblox Studio** - For game development
- **Roblox Account** - With a published game/experience

### Project Structure

```
Banana/
├── .github/
│   └── workflows/
│       └── sync-scripts.yml        # Auto-sync scripts to Roblox
├── ServerScriptService/
│   ├── PathwaySystem.luau          # Conveyor/building movement system
│   └── PlotLoader.luau             # Player plot assignment & management
├── RBXCLOUD_SETUP.md               # This file (setup guide)
└── README.md                       # Project overview
```

### Local Development

You can develop directly in Roblox Studio or use external editors:

1. **Edit scripts** in your preferred code editor (VSCode, etc.)
2. **Copy changes** to Roblox Studio manually, or
3. **Push to GitHub** and let the workflow sync them automatically

### Automatic Deployment

This project uses **GitHub Actions** with **rbxcloud** to automatically sync script changes to your Roblox game.

#### How It Works

- When you push changes to the `main` branch
- GitHub Actions detects changes in:
  - `ServerScriptService/`
  - `ReplicatedStorage/`
  - `StarterPlayer/`
- Each modified `.luau` script is synced to Roblox using the Open Cloud API
- Scripts must already exist in your Roblox place (they are updated, not created)

#### Advantages over traditional deployment

- **No cookie expiration** - Uses permanent API keys instead of `.ROBLOSECURITY` cookies
- **Faster syncing** - Only changed scripts are updated, not the entire place
- **Official API** - Uses Roblox's supported Open Cloud API
- **Selective updates** - Only syncs specific script files that changed

## Current Status

**Note**: The automatic script syncing workflow is currently **not functional** due to Roblox Instance API restrictions. The Instance API (required for updating individual scripts) is being blocked by Roblox's WAF (Web Application Firewall) even with proper permissions. This API appears to be in closed beta and not yet publicly available.

The workflow infrastructure is complete and will work automatically once Roblox enables public access to the Instance API.

## Setup Instructions

### Step 1: Get Your Universe ID

1. Go to [Roblox Creator Dashboard](https://create.roblox.com/creations)
2. Click on your game/experience
3. Look at the URL: `https://create.roblox.com/dashboard/creations/experiences/XXXXXXXXX/...`
4. The number `XXXXXXXXX` is your **Universe ID** (NOT the Place ID)
   - Example: `9091399372`

### Step 2: Create an Open Cloud API Key

1. Go to [Creator Dashboard > Credentials](https://create.roblox.com/credentials)
2. Click **"CREATE API KEY"**
3. Fill in the details:
   - **Name**: `GitHub Actions Script Sync`
   - **Description**: `Automated script deployment from GitHub`

4. **Add API System** - Click "Add API System" and select:
   - **Assets API** (if available), OR
   - **Experience API** with permissions:
     - `experience.place:read`
     - `experience.place:write`

5. **Access Permissions**:
   - Select "Specific Experiences"
   - Add your game's Universe ID from Step 1

6. **Expiration**:
   - Set to "No Expiration" or 1 year+

7. **Security Settings**:
   - **Accepted IP Addresses**: Leave empty (or add GitHub Actions IPs for extra security)

8. Click **"SAVE & GENERATE KEY"**

9. **IMPORTANT**: Copy the API key immediately - you won't be able to see it again!
   - Format: `API-KEY-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`

### Step 3: Add Secrets to GitHub Repository

Using the GitHub CLI:

```bash
# Add API Key
gh secret set ROBLOX_API_KEY --body "YOUR_API_KEY_HERE"

# Add Universe ID
gh secret set ROBLOX_UNIVERSE_ID --body "YOUR_UNIVERSE_ID_HERE"
```

Or via GitHub website:

1. Go to your repository on GitHub
2. Click **Settings** > **Secrets and variables** > **Actions**
3. Click **"New repository secret"**
4. Add both secrets:
   - Name: `ROBLOX_API_KEY`, Value: Your API key
   - Name: `ROBLOX_UNIVERSE_ID`, Value: Your Universe ID

### Step 4: Verify the Setup

```bash
# List secrets to confirm they were added
gh secret list
```

You should see:
```
ROBLOX_API_KEY
ROBLOX_UNIVERSE_ID
```

### Step 5: Test Automatic Syncing

1. Make a small change to a `.luau` file in `ServerScriptService/`
2. Commit and push:
   ```bash
   git add .
   git commit -m "Test rbxcloud sync"
   git push
   ```
3. Go to **Actions** tab on GitHub to watch the workflow run
4. Check your Roblox game in Studio to verify the script was updated

## Workflow Details

The workflow ([.github/workflows/sync-scripts.yml](.github/workflows/sync-scripts.yml)) runs when:

- You push to `main` branch with changes to script files
- You manually trigger it via Actions tab ("Run workflow")

### What Gets Synced

Only files in these directories trigger syncing:
- `ServerScriptService/*.luau` → Synced as ServerScripts
- `ReplicatedStorage/*.luau` → Synced as ModuleScripts
- `StarterPlayer/**/*.luau` → (not yet configured, but monitored)

### Important Limitations

- **Scripts must already exist** in your Roblox place
- Script names must match exactly (e.g., `PlotLoader.luau` → `PlotLoader`)
- Only top-level scripts in each folder are synced (no subfolders yet)
- The script content is updated, but not created from scratch

If a script doesn't exist in Roblox, create it manually in Studio first, then the workflow can update it.

## Troubleshooting

### "Authentication failed" error
- Double-check your `ROBLOX_API_KEY` secret is correct
- Verify the API key has proper permissions
- Make sure the API key hasn't expired

### "Universe not found" error
- Verify you're using the **Universe ID**, not the Place ID
- Check that the Universe ID is added to the API key's allowed experiences

### Scripts not updating in-game
- Ensure script names match exactly between GitHub and Roblox
- Scripts must already exist in your Roblox place
- Check the Actions log for specific sync errors
- Try creating the script in Studio first, then push changes

### Workflow doesn't trigger
- Verify changes were made to files in monitored paths
- Check you pushed to the `main` branch
- Look at the "paths" filter in [sync-scripts.yml](.github/workflows/sync-scripts.yml)

## Development Workflow

### Making Changes

```bash
# 1. Create a feature branch
git checkout -b feature/new-building-type

# 2. Make your changes to .luau files

# 3. Commit and push
git add .
git commit -m "Add new building type to pathway"
git push -u origin feature/new-building-type

# 4. Create a Pull Request on GitHub

# 5. After review and merge to main, scripts auto-sync to Roblox
```

### Hotfixes

```bash
# For urgent fixes, work directly on main
git add .
git commit -m "Fix plot assignment bug"
git push

# Automatically syncs to Roblox within minutes
```

## Manual Syncing (Local Testing)

You can manually sync a script using rbxcloud CLI:

```bash
rbxcloud experience publish-script \
  --api-key "YOUR_API_KEY" \
  --universe-id "YOUR_UNIVERSE_ID" \
  --script "ServerScriptService/PathwaySystem.luau" \
  --script-type ServerScript \
  --script-name "PathwaySystem"
```

## Game Systems Breakdown

### PlotLoader System
- Assigns players to plots (1-8)
- Manages plot ownership via ReplicatedStorage PlotHolders
- Teleports players to their assigned plot on spawn
- Updates plot signs with player name and avatar
- Kicks players if all 8 plots are occupied

### PathwaySystem
- Spawns buildings from BuildingTemplates
- Moves buildings along a conveyor from start to end
- Handles building physics (anchoring, collision)
- Configurable spawn rate and conveyor speed
- Buildings can be interacted with by players

## Security Best Practices

- **Never share your API key** publicly or commit it to Git
- Store API keys only in GitHub Secrets
- Rotate your API key periodically (update the GitHub secret)
- Review repository access regularly
- Use branch protection on `main` to require PR reviews

## Resources

- [rbxcloud Documentation](https://github.com/Sleitnick/rbxcloud)
- [Roblox Open Cloud API](https://create.roblox.com/docs/cloud/open-cloud)
- [Open Cloud API Keys](https://create.roblox.com/credentials)
- [GitHub Actions Docs](https://docs.github.com/en/actions)

## License

Personal Roblox game project.

---

**Need Help?**

- Check the [GitHub Actions logs](https://github.com/YOUR_USERNAME/Banana/actions) for errors
- Review the [rbxcloud documentation](https://github.com/Sleitnick/rbxcloud)
- Verify all secrets are configured correctly in GitHub Settings
