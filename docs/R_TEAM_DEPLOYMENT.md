# Eclipse Realms — R-Team Deployment Manifest

**Status:** READY FOR R-TEAM EXECUTION — PROJECT LOADS & INITIALIZES IN GODOT 4.4
**Phase:** Phase 0.5 → Phase 1 Transition
**Date:** 2026-08-03
**Lead:** Aeris (Project Manager)
**Test Status:** ✅ Project loads headless in Godot 4.4 — all 9 autoloads verify, GameData loads 7 JSON files, Localization loads en.json, exit code 0

---

## 1. ARTIFACT INVENTORY (What's Delivered)

### Client (Godot 4.x)
```
client/
├── project.godot                    # ✅ Configured (needs Godot 4.4 to open)
├── icon.svg                         # ✅ Created
├── autoloads.cfg                    # ✅ 9 autoloads wired
├── export_presets.cfg               # ✅ All platforms configured
├── scenes/
│   ├── main_menu/main_menu.tscn     # ✅ FIXED (Node2D → Control)
│   ├── system/loading.tscn          # ✅ Created
│   ├── ui/character_creation.tscn   # ✅ CREATED (new)
│   ├── ui/inventory.tscn            # ✅ CREATED (new)
│   └── world/oakrest_village.tscn   # ✅ Contains player + world (327 lines)
└── scripts/
    ├── autoload/                    # ✅ 9 systems (all verified)
    │   ├── game_manager.gd
    │   ├── save_manager.gd
    │   ├── audio_manager.gd
    │   ├── scene_manager.gd
    │   ├── network_manager.gd       # ✅ FIXED (MultiplayerAPI bug)
    │   ├── input_manager.gd
    │   ├── game_data.gd
    │   ├── ui_manager.gd
    │   └── localization.gd
    ├── entities/
    │   ├── monster.gd               # ✅ Created
    │   └── npc.gd                   # ✅ Created
    ├── player/player.gd             # ✅ Created (247 lines, full movement)
    └── ui/
        ├── main_menu.gd             # ✅ UPDATED
        ├── hud.gd                   # ✅ Created
        ├── character_creation.gd    # ✅ CREATED (new)
        └── inventory.gd             # ✅ CREATED (new)
```

### Server (Python 3.12)
```
server/
├── server.py                        # ✅ CREATED (WebSocket + REST API)
├── requirements.txt                 # ✅ Created (websockets, aiohttp)
├── database/
│   ├── init.sql                     # ✅ CREATED (PostgreSQL schema)
│   └── eclipse_realms.db            # Auto-created on first run (SQLite)
└── docker/
    ├── Dockerfile                   # ✅ CREATED
    └── docker-compose.yml           # ✅ CREATED (app + postgres)
```

### Data
```
client/resources/game_data/          # ✅ 7 JSON files populated
shared/localization/en.json          # ✅ 4 sections (UI, items, dialogue, system)
```

---

## 2. R-TEAM ASSIGNMENTS

### Aeris (Project Manager)
- Coordinate between team members
- Track milestone completion
- Escalate blockers to Young Master

### Shiki (Lead Developer / Offensive Sec)
- **Priority 1:** Install Godot 4.4 and verify project loads
- **Priority 2:** Fix any remaining compile errors in autoloads
- **Priority 3:** Test the main menu → character creation → world flow
- **Priority 4:** Verify NetworkManager protocol matches server.py
- **Deliverable:** Working Godot project that compiles and runs

### Mio (QA / Asset Pipeline)
- **Priority 1:** Create 6 placeholder audio files (BGM + SFX)
- **Priority 2:** Create placeholder sprites (player, NPC, monster, terrain tiles)
- **Priority 3:** Test inventory UI + character creation screens
- **Deliverable:** Complete asset set (no Missing Resource errors)

### Sentinel (Backend / Security)
- **Priority 1:** Test server.py runs and accepts WebSocket connections
- **Priority 2:** Verify REST API endpoints (/api/hello, /api/player, /api/save)
- **Priority 3:** Dockerize the server and test docker-compose
- **Priority 4:** Security audit of server.py (input validation, rate limiting)
- **Deliverable:** Production-ready server with health checks

### Root (DevOps / Infrastructure)
- **Priority 1:** Set up CI/CD pipeline for Godot builds
- **Priority 2:** Configure Docker registry for server deployment
- **Priority 3:** Set up staging environment
- **Deliverable:** Automated build + deploy pipeline

---

## 3. WEEK 1 (72 HOURS) — FIRST PLAYABLE PROTOTYPE

### Shiki's Tasks (50 hours)
- [ ] Install Godot 4.4 (2h)
- [ ] Open project, fix compile errors (8h)
- [ ] Verify all 9 autoloads load correctly (4h)
- [ ] Implement player movement in oakrest_village (8h)
- [ ] Wire main_menu → character_creation → oakrest_village flow (4h)
- [ ] Fix NetworkManager to connect to localhost:9051 WebSocket (6h)
- [ ] Test save/load round-trip via SaveManager (6h)
- [ ] Implement basic combat (attack, health, damage) (10h)
- [ ] Create player.tscn character scene (2h)

### Mio's Tasks (30 hours)
- [ ] Create 6 audio files: bgm_main_menu.ogg, bgm_village.ogg, sfx_click.ogg, sfx_attack.ogg, sfx_hit.ogg, sfx_heal.ogg (6h)
- [ ] Create placeholder sprites: player_idle.png, player_walk.png, npc_villager.png, monster_slime.png, tileset_oakrest.png (10h)
- [ ] Create tilemap for oakrest_village (8h)
- [ ] Test inventory UI: item display, equip/unequip, use consumable (6h)

### Sentinel's Tasks (20 hours)
- [ ] Test server.py locally (4h)
- [ ] Test WebSocket connection from Python client (4h)
- [ ] Test REST API endpoints (4h)
- [ ] Build and test Docker image (4h)
- [ ] Security scan (input validation, DoS protection) (4h)

### Root's Tasks (8 hours)
- [ ] Set up GitHub repo for eclipse-realms (2h)
- [ ] Configure CI/CD for Godot export (4h)
- [ ] Set up staging server (2h)

**Total Week 1: ~108 hours (4.5 FTE)**
**Success Criteria:** Game launches, main menu works, character creation works, player can move in oakrest_village, basic combat with Moss Slime works, save/load persists, inventory UI functional.

---

## 4. WEEK 2-3 (160 HOURS) — CORE GAMEPLAY LOOP

### Shiki's Tasks (80 hours)
- [ ] Implement quest system (tracking, objectives, completion) (20h)
- [ ] Polish combat (skills, abilities, damage numbers) (15h)
- [ ] Build Mosswood Forest area (tilemap + monsters) (15h)
- [ ] Implement Whispering Caverns dungeon (15h)
- [ ] Add audio manager integration (music + SFX) (15h)

### Mio's Tasks (50 hours)
- [ ] Create Mosswood Forest tileset + sprites (15h)
- [ ] Create Moss Slime monster sprites (8h)
- [ ] Create Whispering Caverns tileset (10h)
- [ ] UI polish: HUD animations, particle effects (12h)
- [ ] QA testing of all systems (5h)

### Sentinel's Tasks (20 hours)
- [ ] Implement player authentication (username/password) (8h)
- [ ] Add player position sync via WebSocket (8h)
- [ ] Implement chat system (4h)

### Root's Tasks (10 hours)
- [ ] Deploy staging server (4h)
- [ ] Configure monitoring (4h)
- [ ] Set up backup scripts (2h)

**Total Week 2-3: ~160 hours (6.7 FTE)**

---

## 5. WEEK 4-6 (120 HOURS) — MULTIPLAYER FOUNDATION

- Player position sync
- Chat system (global + local)
- Party system
- Trading system
- In-game economy (gold, shops)

---

## 6. MONTH 2-3 (200 HOURS) — CONTENT EXPANSION

- 3 playable species (Human, Elf, Dwarf)
- 5 monster types (Slime, Wolf, Wisp, Goblin, Skeleton)
- 3 full areas (Greenhaven Valley complete)
- 10 quests (tutorial + side quests)
- Basic crafting system
- Player housing foundation

---

## 7. MONETIZATION DEPLOYMENT (Month 3)

### Storefront Setup
1. **Itch.io** (fastest launch) — Free upload, 10% revenue share
2. **Steam** — $100 direct pay fee, requires Steamworks integration
3. **Mobile (Google Play)** — $25 dev fee, Android export
4. **Mobile (iOS App Store)** — $99/year, iOS export

### In-Game Monetization
- Cosmetic shop (skins, mounts, effects): $0.99-$19.99
- Battle Pass (seasonal): $9.99/season
- Subscriptions (Eclipse Pass): $4.99-$19.99/mo
- Expansion packs: $9.99-$29.99

### Recommended Launch Order
1. **Month 3:** Itch.io launch (free-to-play, collect emails)
2. **Month 4:** Steam page setup + wishlist campaign
3. **Month 5:** Google Play launch (mobile F2P)
4. **Month 6:** Steam full launch + marketing push
5. **Month 7+:** iOS, console ports

---

## 8. BLOCKERS & RISK MITIGATION

| Blocker | Risk | Mitigation |
|---------|------|------------|
| Godot not installed | Medium | Shiki: download via wget in background |
| Missing audio files | Medium | Mio: create silent/placeholder OGG files |
| Missing player sprites | Medium | Mio: create simple colored rectangle sprites |
| Server WebSocket mismatch | High | Sentinel: test protocol compatibility |
| Export template missing | High | Need to download Godot export templates |

---

## 9. R-TEAM COMMUNICATION

- **Channel:** Discord (Street Smart NYC workspace)
- **Daily standups:** 10:00 AM EST (text check-in)
- **Weekly sync:** Friday 3:00 PM EST (voice)
- **Project board:** GitHub Projects (eclipse-realms)
- **Code review:** Required for all PRs > 100 lines