# Eclipse Realms

> **A beautiful, original, anime-inspired online RPG**
> Built with Godot 4.x, designed to scale from a small multiplayer adventure to a persistent MMORPG.

---

![Eclipse Realms Logo](https://via.placeholder.com/600x200/2d5a3d/ffffff?text=Eclipse+Realms)

**Version:** 0.1.0 - First Playable  
**Phase:** Genesis → Implementation  
**Status:** 🚀 Active Development  
**Engine:** Godot 4.x  
**License:** Proprietary (All Rights Reserved)  

---

## 📖 PROJECT OVERVIEW

**Eclipse Realms** is a cross-platform anime-inspired MMORPG built from the ground up to deliver:

- **Player Freedom** - Choose your path, play your way
- **Meaningful Progression** - Every action moves you forward
- **Living World** - Dynamic, persistent, and full of life
- **Cooperative MMO** - Team up with friends for epic adventures
- **Long-term Character Growth** - Build your legend over time
- **Respect for Player Time** - No grind, just meaningful gameplay

---

## 🎯 VISION STATEMENT

> Build a beautiful, original, anime-inspired online RPG that begins as a small multiplayer adventure and expands over time into a persistent MMORPG.

---

## 🌟 DESIGN PILLARS

### 1. Player Freedom
Players have genuine choices that impact their experience and the world around them.

### 2. Meaningful Progression
Every level, item, and skill acquisition feels earned and impactful.

### 3. Living World
A dynamic world that reacts to player actions and evolves over time.

### 4. Cooperative MMO
Social gameplay is at the heart, with teamwork rewarded above all.

### 5. Long-term Character Growth
Characters develop deep identities and capabilities over extended play.

### 6. Respect for Player Time
No artificial time gates or mandatory grind - every minute is valuable.

---

## 🎮 CORE GAMEPLAY LOOP

```
Explore → Fight → Loot → Craft → Trade → Upgrade → Unlock Skills → Take on Harder Content
```

---

## 🏗️ PROJECT STRUCTURE

```
eclipse-realms/
├── client/                          # Godot Project
│   ├── scenes/                      # All game scenes
│   │   ├── main_menu/               # Main menu and UI
│   │   ├── world/                  # World maps and areas
│   │   ├── ui/                     # UI components
│   │   ├── characters/              # Character scenes
│   │   ├── monsters/                # Monster scenes
│   │   └── system/                 # System scenes (loading, etc.)
│   ├── scripts/                     # All GDScript code
│   │   ├── autoload/                # Singleton systems (GameManager, etc.)
│   │   ├── systems/                 # Core gameplay systems
│   │   ├── utilities/               # Utility functions and helpers
│   │   └── entities/                # Character, monster, NPC scripts
│   ├── assets/                      # All game assets
│   │   ├── characters/              # Player and NPC assets
│   │   │   ├── player/              # Player character assets
│   │   │   ├── monsters/            # Monster assets
│   │   │   └── npcs/                # NPC assets
│   │   ├── environment/             # World and environment assets
│   │   │   ├── oakrest_village/     # Oakrest Village assets
│   │   │   ├── mosswood_forest/     # Mosswood Forest assets
│   │   │   └── greenhaven_valley/   # Greenhaven Valley assets
│   │   ├── ui/                     # UI assets (icons, sprites, etc.)
│   │   ├── audio/                  # Sound and music
│   │   │   ├── music/              # Background music
│   │   │   ├── sfx/                # Sound effects
│   │   │   ├── voice/              # Voice clips
│   │   │   └── ambient/            # Ambient sounds
│   │   └── shaders/                # Shader files
│   ├── resources/                   # Godot resources
│   │   ├── game_data/              # Game data as resources
│   │   └── schemas/                # Data schemas
│   ├── shaders/                     # Shader scripts
│   └── project.godot               # Godot project configuration
│
├── server/                          # Backend Server
│   ├── auth/                        # Authentication system
│   ├── world/                      # World simulation
│   ├── database/                   # Database management
│   ├── api/                        # REST/HTTP API
│   ├── docker/                     # Docker configuration
│   └── server.py                   # Main server entry point
│
├── shared/                          # Cross-Cutting Resources
│   ├── schemas/                     # JSON schemas for data
│   ├── game_data/                   # Shared game data
│   └── localization/                # Translation files
│
├── docs/                            # Documentation
│   ├── 00_MASTER_INDEX.md           # Master index of all documentation
│   ├── bibles/                      # Design Bibles
│   │   ├── 01_Vision_Bible.md       # Core vision document
│   │   ├── 02_Production_Blueprint.md # Production methodology
│   │   ├── 03_Technical_Architecture.md # Technical stack
│   │   ├── catalogs/                # Data catalogs
│   │   └── *.md                     # System bibles (04-25)
│   ├── technical/                   # Technical documentation
│   │   ├── Tech_Project_Structure.md
│   │   ├── Tech_Godot_Setup.md
│   │   └── *.md
│   └── production/                  # Production documentation
│       └── *.md
│
├── tools/                           # Development Tools
│   ├── editors/                     # Custom editors
│   ├── converters/                  # File format converters
│   └── scripts/                     # Utility scripts
│
├── builds/                          # Build Output
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── windows/
│   └── steam/
│
├── PROJECT_AUDIT.md                 # Complete project audit
├── README.md                        # This file
├── .gitignore                       # Git ignore rules
└── brainstorm                       # Original brainstorm notes
```

---

## 🎯 CURRENT DEVELOPMENT PHASES

### Phase 0: Genesis ✅ COMPLETE
- ✅ Vision defined
- ✅ Architecture planned
- ✅ World foundation established
- ✅ Technical decisions locked
- ✅ Character framework designed
- ✅ Documentation framework created

### Phase 1: First Playable 🚀 IN PROGRESS
**Target:** Players can create characters, walk, fight, level, save

#### Sprint 1 Deliverables
- [ ] Godot project foundation
- [ ] Main Menu system
- [ ] Player controller
- [ ] Camera system
- [ ] Oakrest Village
- [ ] First player character
- [ ] Basic movement and controls

#### Sprint 2 Deliverables
- [ ] Combat system
- [ ] Health and damage
- [ ] First monsters (Moss Slime, Forest Wolf)
- [ ] Basic inventory
- [ ] First NPCs (Village Elder, Blacksmith, etc.)

#### Sprint 3 Deliverables
- [ ] Character creation
- [ ] Save/Load system
- [ ] Mosswood Forest
- [ ] Quest system foundation
- [ ] Basic crafting

---

## 📁 FIRST PLAYABLE REGION: GREENHAVEN VALLEY

### Overview
Greenhaven Valley is the starting region, designed for quality over size. All Phase 1 content takes place here.

### Areas
| Area | Type | Level | Description |
|------|------|-------|-------------|
| Oakrest Village | Village | 1 | Starting town with NPCs and services |
| Mosswood Forest | Forest | 2 | Dense forest with slimes and wolves |
| Silver Creek | River | 2 | Running water with bridge and fishing |
| Whispering Caverns | Cave | 5 | Dark caves with thorn wisps |
| The Old Watchtower | Landmark | 1 | Abandoned structure for exploration |
| Hunter's Camp | Camp | 3 | Ranger outpost and quest hub |

### Starting Content
- **1 Playable Species:** Human (Male/Female variants)
- **3 Monster Types:** Moss Slime, Forest Wolf, Thorn Wisp
- **5 NPC Types:** Village Elder, Blacksmith, Merchant, Innkeeper, Ranger
- **3 Starting Quests:** Tutorial, Find Missing Item, Hunt Forest Wolf

---

## 🛠️ TECHNICAL STACK

### Engine
- **Godot 4.x** - Primary game engine
- **GDScript** - Primary scripting language
- **C#** - Optional for performance-critical systems

### Frontend (Client)
- **Godot 4 Rendering** - Forward+ renderer
- **2D/2.5D Hybrid** - Anime-inspired visuals
- **Cel Shading** - Art style
- **Dynamic Lighting** - Day/Night cycle support

### Backend (Server)
- **Node.js** or **Python** - Server runtime
- **ENet** - Built-in Godot networking
- **SQLite** - Local database (for alpha)
- **PostgreSQL** - Production database
- **Docker** - Containerization

### Development
- **Git** - Version control
- **GitHub** - Repository hosting
- **VS Code** - Recommended IDE
- **Godot Editor** - Primary development environment

---

## 📦 CORE SYSTEMS (AUTOLOAD SINGLETONS)

### GameManager
- Central game state management
- Scene transitions
- Configuration management
- Runtime data tracking

### SaveManager
- Save/Load game state
- Configuration persistence
- Save slot management
- Auto-save functionality

### AudioManager
- Music playback and control
- SFX management
- Voice support
- Ambient sounds
- Volume control and fading

### InputManager
- Input handling
- Action mapping
- Context-sensitive controls
- Gamepad support
- Mouse and keyboard

### SceneManager
- Scene loading/unloading
- Transition effects
- Scene caching
- Hierarchy management

### NetworkManager
- Client-server communication
- Multiplayer synchronization
- Message serialization
- Connection management
- Ping and latency handling

### UIManager
- UI element management
- Menu system
- Dialog system
- Notification system
- HUD management
- Input blocking

### GameData
- Game content storage
- Items, monsters, NPCs, quests
- World data
- Catalog management
- Indexed lookups

### Localization
- Multi-language support
- Translation management
- Text formatting
- Language file handling

---

## 🎮 CONTROLS

### Default Keyboard Controls
| Action | Key |
|--------|-----|
| Move Up | W / ↑ |
| Move Down | S / ↓ |
| Move Left | A / ← |
| Move Right | D / → |
| Run | Shift |
| Jump | Space |
| Attack | J |
| Skill 1 | K |
| Skill 2 | L |
| Interact | E |
| Inventory | Tab |
| Character | C |
| Map | M |
| Menu | Escape |
| Accept | Enter / Space |
| Cancel | Escape |

### Gamepad Controls
| Action | Button |
|--------|--------|
| Move | Left Stick |
| Camera | Right Stick |
| Accept | A / X |
| Cancel | B / Circle |
| Interact | Y / Triangle |
| Attack | X / Square |
| Run | Left Shoulder |
| Jump | Right Shoulder |
| Menu | Start |
| Inventory | Select |

---

## 🚀 GETTING STARTED

### Prerequisites
- **Godot 4.2+** - [Download Godot](https://godotengine.org/download)
- **Git** - [Download Git](https://git-scm.com/downloads)
- **Optional: VS Code** - [Download VS Code](https://code.visualstudio.com/)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/StreetSmartNYC/eclipse-realms.git
   cd eclipse-realms
   ```

2. **Open in Godot:**
   - Launch Godot 4.x
   - Click "Import Project"
   - Navigate to the eclipse-realms folder
   - Select `project.godot`

3. **Set up development environment:**
   ```bash
   # Optional: Set up VS Code for GDScript
   code --install-extension GEARGS.godot
   ```

### Running the Game

1. **In Godot Editor:**
   - Click the Play button (F5)
   - The game will start with the main menu

2. **From command line:**
   ```bash
   godot --path . client/project.godot
   ```

---

## 🏗️ BUILD INSTRUCTIONS

### Development Build
```bash
# Godot automatically builds when running from editor
```

### Export Builds

1. **Windows:**
   ```bash
   godot --export-release windows --path builds/windows
   ```

2. **Linux:**
   ```bash
   godot --export-release linux --path builds/linux
   ```

3. **Web:**
   ```bash
   godot --export-release html --path builds/web
   ```

4. **Android:**
   ```bash
   godot --export-release android --path builds/android
   ```

5. **iOS:**
   ```bash
   godot --export-release ios --path builds/ios
   ```

---

## 📊 PROJECT STATISTICS

| Category | Count | Status |
|----------|-------|--------|
| Autoload Systems | 9 | ✅ Complete |
| Documentation Files | 20+ | 📝 In Progress |
| Game Systems | 15+ | 🚀 Planned |
| World Areas | 6 | 🗺️ Designed |
| Monsters | 3 | 🎨 Conceptual |
| NPCs | 5 | 🎨 Conceptual |
| Items | 20+ | 📋 Designed |
| Quests | 10+ | 📋 Designed |

---

## 🤝 CONTRIBUTING

### Development Workflow

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Follow existing code style
   - Add documentation
   - Write tests if applicable

3. **Commit your changes:**
   ```bash
   git commit -m "Add your feature description"
   ```

4. **Push to the branch:**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create a Pull Request:**
   - Go to GitHub repository
   - Create PR from your branch
   - Describe changes and link to issues

### Code Style Guidelines

- **GDScript:** Follow Godot's official style guide
- **Indentation:** 4 spaces (tabs converted to spaces)
- **Naming:** snake_case for variables, PascalCase for types
- **Comments:** Use `##` for documentation comments
- **Signals:** Define at top of class
- **Constants:** ALL_CAPS with type hints

### Design Principles

1. **Golden Rule:** Every system must satisfy:
   - Is it fun?
   - Can it scale?
   - Is it maintainable?
   - Is it original?

2. **Modularity:** Systems should be independent and interchangeable

3. **Data-Driven:** Game content should be in data files, not hardcoded

4. **Performance:** Target 60 FPS on mobile devices

---

## 🐛 TROUBLESHOOTING

### Common Issues

**Q: Godot project fails to import**
A: Make sure you're using Godot 4.2+. Delete the `.godot` folder and try again.

**Q: Missing resources or scenes**
A: Run `git lfs pull` if using Git LFS for binary assets.

**Q: Input not working**
A: Check that InputManager is in the autoload list in project.godot.

**Q: Audio not playing**
A: Verify audio files exist in the correct paths and AudioManager is initialized.

**Q: Networking not working**
A: Check firewall settings and verify ENet is properly configured.

---

## 📞 CONTACT & COMMUNITY

- **Project Lead:** StreetSmartNYC BusinessBase
- **Discord:** (Coming Soon)
- **Twitter:** @StreetSmartNYC
- **Email:** contact@streetsmartnyc.com

---

## 📜 LICENSE

All rights reserved. This project is proprietary software owned by StreetSmartNYC BusinessBase.

Unauthorized reproduction, distribution, or use is prohibited.

For licensing inquiries, please contact: licensing@streetsmartnyc.com

---

## 🎉 ACKNOWLEDGMENTS

- **Godot Engine** - Amazing open-source game engine
- **Mistral Vibe** - AI assistance for code generation
- **Open Source Community** - Tools and libraries that make this possible

---

## 📝 RELEASE NOTES

### Version 0.1.0 - First Playable (2026-08-03)
- Initial project structure
- Core autoload systems (GameManager, SaveManager, AudioManager, etc.)
- Godot project configuration
- Documentation framework
- Directory structure
- Sprint 1 planning

---

## 🚀 ROADMAP

### Q3 2026
- ✅ Phase 0: Genesis (Complete)
- 🚀 Phase 1: First Playable (In Progress)

### Q4 2026
- 🎯 Phase 1: First Playable (Complete)
- 🚀 Phase 2: Friends Alpha (Start)

### Q1 2027
- ✅ Phase 2: Friends Alpha (Complete)
- 🚀 Phase 3: Online Alpha (Start)

### Q2 2027
- 🎯 Phase 3: Online Alpha (Complete)
- 🚀 Public Beta Testing

### Q3 2027
- 🎯 Public Launch

---

## 💭 QUOTES TO LIVE BY

> "We're not building an indie game. We're building a project that could realistically grow into something on the scale of RuneScape, Albion Online, or Genshin."

> "Think like a studio from Day 1 while still shipping playable milestones."

> "Every system must satisfy four questions: Is it fun? Can it scale? Is it maintainable? Is it original?"

---

## 📖 DOCUMENTATION INDEX

For complete documentation, see:
- [PROJECT_AUDIT.md](PROJECT_AUDIT.md) - Complete project audit
- [docs/00_MASTER_INDEX.md](docs/00_MASTER_INDEX.md) - Master design index
- [brainstorm](brainstorm) - Original brainstorm notes

---

**Built with ❤️ and Godot**

*Last Updated: 2026-08-03* | *Version: 0.1.0*