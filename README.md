# 🍌 Banana Game - Hybrid Farming/City Management

A feature-rich Roblox game combining farming mechanics with city/empire management!

## Features

- 🌱 **Farming System** - Plant, grow, and harvest various fruit types
- 🏗️ **City Building** - Place buildings and manage your empire
- 👥 **Empire Management** - Citizens, mood system, and tax collection
- 🎖️ **Battle Pass** - 100-tier seasonal progression system
- 🎯 **Quest System** - Daily quests with rewards
- 🏆 **Title System** - 22+ unlockable achievement titles
- 🤖 **Worker Automation** - Unlock workers to automate tasks
- 🎲 **Random Events** - Boss fights, heists, disasters, and more
- 💰 **Economy** - Robust Blox currency system with multiple income streams
- 🎮 **GamePasses** - 13 optional enhancements (non-pay-to-win)

## Quick Start

See [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) for detailed game setup and configuration.

## Development Setup

This project uses **Git** for version control and **GitHub Actions** for automatic deployment to Roblox.

### Prerequisites

- [Rojo](https://rojo.space/) for syncing to Roblox Studio
- Git for version control
- GitHub account for hosting and CI/CD

### Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/BananaGame.git
   cd BananaGame
   ```

2. **Install Rojo** (optional for local development)
   ```bash
   # Using Aftman (recommended)
   aftman install

   # Or download from https://github.com/rojo-rbx/rojo/releases
   ```

3. **Start local development**
   ```bash
   rojo serve
   ```
   Then connect from Roblox Studio using the Rojo plugin.

### Deployment

**Automatic Deployment** is configured via GitHub Actions:
- Push to `main` branch automatically deploys to your Roblox place
- Pull requests run build verification checks

See [GITHUB_SETUP.md](GITHUB_SETUP.md) for complete setup instructions.

## Project Structure

```
Banana/
├── ServerScriptService/     # Server-side game logic (51 scripts)
│   ├── Economy systems
│   ├── Farming systems
│   ├── Empire/City management
│   ├── Building systems
│   ├── Quest & progression
│   ├── Worker automation
│   └── Random events
├── StarterPlayer/
│   └── StarterPlayerScripts/  # Client-side UI and controls
├── ReplicatedStorage/         # Shared resources
└── Shop Scripts/              # GamePass scripts
```

## Key Systems

- **BloxSystem** - Main currency ([ServerScriptService/BloxSystem.luau](ServerScriptService/BloxSystem.luau))
- **EmpireSystem** - City management ([ServerScriptService/EmpireSystem.luau](ServerScriptService/EmpireSystem.luau))
- **SeedSystem** - Farming mechanics ([ServerScriptService/SeedSystem.luau](ServerScriptService/SeedSystem.luau))
- **BattlePassSystem** - Progression ([ServerScriptService/BattlePassSystem.luau](ServerScriptService/BattlePassSystem.luau))

## Contributing

1. Create a feature branch: `git checkout -b feature/amazing-feature`
2. Commit your changes: `git commit -m 'Add amazing feature'`
3. Push to branch: `git push origin feature/amazing-feature`
4. Open a Pull Request

## Documentation

- [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) - Complete game setup guide
- [GITHUB_SETUP.md](GITHUB_SETUP.md) - Git & GitHub Actions setup

## License

This is a personal Roblox game project.

---

Built with ❤️ using [Rojo](https://rojo.space/)
