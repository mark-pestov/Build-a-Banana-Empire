# GitHub Actions & Rojo Setup Guide

This guide will help you set up automatic syncing from GitHub to Roblox using Rojo and GitHub Actions.

## Prerequisites

- A GitHub account
- A Roblox account
- Your Roblox game/place already created on Roblox.com

## What Was Set Up

This project now includes:

1. **Git version control** - Track all changes to your code
2. **Rojo configuration** ([default.project.json](default.project.json)) - Syncs your file structure to Roblox
3. **GitHub Actions workflows** - Automatically deploy to Roblox on every push
4. **Aftman configuration** ([aftman.toml](aftman.toml)) - Manages Rojo tooling

## Step 1: Install Rojo Locally (Optional but Recommended)

For local development and testing, install Rojo:

### Option A: Using Aftman (Recommended)

```bash
# Install Aftman
cargo install aftman

# Install tools (Rojo)
aftman install
```

### Option B: Direct Install

Download from: https://github.com/rojo-rbx/rojo/releases

## Step 2: Get Your Roblox Security Cookie

**⚠️ IMPORTANT: Keep this secret! Never share it or commit it to Git!**

1. Open your browser and go to [roblox.com](https://www.roblox.com)
2. Log in to your account
3. Open Developer Tools (F12 or Right-click → Inspect)
4. Go to the **Application** or **Storage** tab
5. Find **Cookies** → `https://www.roblox.com`
6. Copy the value of the `.ROBLOSECURITY` cookie
   - It's a long string starting with `_|WARNING:-DO-NOT-SHARE-THIS...`

## Step 3: Get Your Roblox Place ID

1. Go to [Roblox Creator Dashboard](https://create.roblox.com/)
2. Find your game/place
3. Click on it to open
4. The Place ID is in the URL: `https://create.roblox.com/dashboard/creations/experiences/PLACE_ID/...`
   - Example: If URL is `...experiences/123456789/...`, your Place ID is `123456789`

## Step 4: Create GitHub Repository

1. Go to [GitHub](https://github.com) and create a new repository
2. Name it (e.g., "BananaGame")
3. **Do NOT initialize with README** (we already have files)
4. Create the repository

## Step 5: Add GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add these two secrets:

### Secret 1: ROBLOSECURITY
- **Name**: `ROBLOSECURITY`
- **Value**: Paste your `.ROBLOSECURITY` cookie value (the full string)

### Secret 2: ROBLOX_PLACE_ID
- **Name**: `ROBLOX_PLACE_ID`
- **Value**: Your Place ID (just the numbers)

## Step 6: Push Your Code to GitHub

Run these commands in your project directory:

```bash
# Add all files to git
git add .

# Create your first commit
git commit -m "Initial commit: Banana game with GitHub Actions setup"

# Add your GitHub repository as remote (replace YOUR_USERNAME and YOUR_REPO)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Step 7: Verify Deployment

1. Go to your GitHub repository
2. Click the **Actions** tab
3. You should see a workflow running called "Deploy to Roblox"
4. Click on it to see the deployment progress
5. If successful, your game on Roblox will be updated!

## How It Works

### Automatic Deployment (deploy.yml)

- Triggers on every push to the `main` branch
- Builds your game using Rojo
- Uploads the built file to your Roblox place
- You can also trigger manually from the Actions tab

### Build Checks (ci.yml)

- Runs on pull requests and non-main branches
- Verifies your Rojo project builds correctly
- Helps catch errors before deploying

## Local Development Workflow

### Using Rojo Serve (Live Sync)

1. Install the Rojo plugin in Roblox Studio from: https://create.roblox.com/store/asset/13916111004/Rojo
2. Open your place in Roblox Studio
3. Run in terminal:
   ```bash
   rojo serve
   ```
4. In Roblox Studio, click the Rojo plugin and click "Connect"
5. Now changes you make to files will sync live to Studio!

### Making Changes

1. Edit your `.luau` files in your code editor
2. Test in Roblox Studio (using Rojo serve)
3. Commit your changes:
   ```bash
   git add .
   git commit -m "Description of changes"
   git push
   ```
4. GitHub Actions will automatically deploy to your live game!

## Recommended Git Workflow

### Working on Features

```bash
# Create a feature branch
git checkout -b feature/new-quest-system

# Make your changes and commit
git add .
git commit -m "Add new quest system"

# Push to GitHub
git push -u origin feature/new-quest-system

# Create a Pull Request on GitHub
# After review, merge to main
# Merging to main triggers automatic deployment!
```

### Hotfixes

```bash
# For urgent fixes, work directly on main (carefully!)
git add .
git commit -m "Fix critical bug in BloxSystem"
git push
# Automatically deploys to Roblox
```

## Troubleshooting

### Deployment Failed

**Check these:**
1. Verify `ROBLOSECURITY` secret is correct and not expired
   - Roblox cookies expire after ~30 days
   - You'll need to update the secret when it expires
2. Verify `ROBLOX_PLACE_ID` is correct
3. Check the Actions log for specific error messages

### Rojo Build Errors

- Ensure all `.luau` files have valid syntax
- Check that folder structure matches [default.project.json](default.project.json)
- Review the CI workflow logs in GitHub Actions

### Cookie Expired

If deployments suddenly fail:
1. Get a fresh `.ROBLOSECURITY` cookie (Step 2)
2. Update the GitHub secret
3. Re-run the failed workflow

## Security Best Practices

✅ **DO:**
- Keep your `.ROBLOSECURITY` cookie secret
- Rotate your cookie periodically (update the GitHub secret)
- Review who has access to your GitHub repository
- Use branch protection on `main` to require reviews

❌ **DON'T:**
- Share your `.ROBLOSECURITY` cookie
- Commit secrets to your repository
- Give repository access to untrusted users
- Use the same cookie across multiple repositories (use different accounts if possible)

## Additional Tools (Optional)

### Selene (Linting)

Catch common Lua/Luau errors:
```bash
aftman add Kampfkarren/selene@0.27.1
aftman install
selene .
```

### StyLua (Code Formatting)

Auto-format your code:
```bash
aftman add JohnnyMorganz/StyLua@0.20.0
aftman install
stylua .
```

Add these to [aftman.toml](aftman.toml) if you want them.

## File Structure Reference

```
Banana/
├── .git/                          # Git repository data
├── .github/
│   └── workflows/
│       ├── deploy.yml             # Auto-deployment to Roblox
│       └── ci.yml                 # Build verification
├── .gitignore                     # Files to ignore in Git
├── aftman.toml                    # Tool dependencies
├── default.project.json           # Rojo configuration
├── ReplicatedStorage/             # Syncs to ReplicatedStorage
├── ServerScriptService/           # Syncs to ServerScriptService
├── StarterPlayer/                 # Syncs to StarterPlayer
└── GITHUB_SETUP.md                # This file
```

## Next Steps

1. ✅ Complete Steps 1-7 above
2. Install Rojo locally for live development
3. Set up branch protection on `main` in GitHub settings
4. Consider adding collaborators to your repository
5. Set up a development place (separate from production) for testing

## Resources

- [Rojo Documentation](https://rojo.space/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Roblox Open Cloud API](https://create.roblox.com/docs/cloud/open-cloud)

---

**Need Help?**

- Check the [GitHub Actions logs](https://github.com/YOUR_USERNAME/YOUR_REPO/actions) for errors
- Review the [Rojo documentation](https://rojo.space/docs)
- Ensure all secrets are configured correctly

Happy developing! 🍌
