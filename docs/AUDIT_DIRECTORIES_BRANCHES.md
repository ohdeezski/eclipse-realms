# Eclipse Realms — Directory & Branch Audit (Authoritative)

**Date:** 2026-08-03 23:45 EDT
**Auditor:** Agent Zero (live filesystem + git + runtime verification)
**Status:** Phase 0.5 → Phase 1 transition. Use this as the team's single source of truth.

---

## 0. EXECUTIVE SNAPSHOT

- **Active branch:** `feat/ci-workflows` (16 commits ahead of `main`)
- **Working tree:** 8 modified files + 5 untracked items (uncommitted)
- **Protocol:** ✅ Client+server aligned on WebSocket port 9051 (zero ENet references)
- **Engine:** ✅ Godot 4.4.stable; export templates 4.2.2 / 4.3 / 4.4 installed
- **Client:** ✅ loads headless, exit 0; all autoloads init; 8 JSON data files + en.json load
- **Server:** ✅ boots on Python 3.13 host; WS 9051 + REST 9052 + SQLite; `/api/hello` → ok
- **Remote:** https://github.com/ohdeezski/eclipse-realms.git
- **CI/CD:** ⚠️ workflows exist but only on `feat/ci-workflows` and pin Godot 4.2.2 (game is 4.4)

---

## 1. BRANCH MAP (verified)

| Branch | HEAD | Notes |
|--------|------|-------|
| `main` | e50e1e3 | Workflows added, but lacks the WebSocket migration + test files |
| `feat/ci-workflows` * | 9407b2e | Active branch: WebSocket migration, tests, workflow fixes, gitignore updates |
| `origin/master` | dac3c1a | Abandoned WIP (pre-GitHub) |

- `git log --oneline main..feat/ci-workflows` = 16 commits (ENet→WS migration, test harness, CI template fixes).
- `main..feat` diff: 21 files changed, +521/−226 lines (network_manager.gd rewritten 367 lines, 11 test files, docs/WEB_EXPORT_PROCESS.md, workflows).

---

## 2. DIRECTORY-BY-DIRECTORY INVENTORY (file counts exclude .godot/venv/__pycache__)

| Directory | Files | Contents & Status |
|-----------|-------|-------------------|
| `client/` | 222 (404 on disk) | Godot project — primary source of truth for the game |
| `client/scenes/` | ~14 .tscn | main_menu, player, loading, ui (character_creation, inventory, quest_log, dialogue, settings, credits), world (oakrest_village, mosswood_forest), combat (damage_number) — ✅ built |
| `client/scripts/` | 29 .gd | 10 autoloads, combat(3), dungeon(1), entities(2), player(1), ui(6), world(6) — ✅ all real code |
| `client/assets/audio/` | ~48 files | music (10+ themes), sfx (15+), ambient (9) — ✅ real OGG/WAV now imported |
| `client/assets/characters/player/` | player_idle.png | ✅ new idle sprite; walk/attack frames still TODO |
| `client/assets/monsters/` | monster_slime.png | ✅ |
| `client/assets/npcs/` | npc_villager.png | ✅ |
| `client/assets/ui/` | ui_icons.png, fonts/default.tres | ✅ |
| `client/assets/environment/oakrest_village/` | tileset.png, tileset_oakrest.png | ✅ |
| `client/resources/game_data/` | 8 JSON | items, characters, monsters, npcs, quests, skills, equipment, world — ✅ |
| `client/resources/localization/` | en.json | ✅ |
| `client/resources/tilesets/` | 2 .tres | oakrest + mosswood — ✅ |
| `client/build/web/` | 9 files | ⚠️ index.wasm 33.8MB — built 20:28, predates some audio/WS changes → needs re-export |
| `client/tests/` | many | WS connection + class + debug tests — ✅ on feature branch |
| `server/` | 7 tracked | server.py (493 lines, WS+REST+SQLite), requirements, database (init.sql + db), docker (Dockerfile + compose) — ✅ boots |
| `server/venv/` | local | Python 3.13 virtualenv — local only, not tracked (good) |
| `shared/` | 1 | localization/en.json — ✅ |
| `resources/` | 1 | resources/game_data/npcs.json — ⚠️ duplicate of client/resources; decide eventually |
| `tools/` | 1 | generate_tileset.py — ✅ |
| `builds/` | 0 | empty output dir (only client/build used) — ℹ️ keep or clean |
| `docs/` | 10 | MASTER_INDEX, technical, production, coordination docs — ✅ main coordination hub |
| `.github/workflows/` | 2 | godot-export.yml (4.2.2) + docker-build.yml — ⚠️ bump to 4.4, merge to main |
| `Bible_01_Vision_Bible_v0.1/` | 3 | vision bible md/pdf/docx — ✅ |
| `EclipseRealms_StarterKit/` | 2 | reference/template — ℹ️ clarify vs client/ |

---

## 3. KEY FILE LINE COUNTS (client/scripts)

| Script | Lines | | Script | Lines |
|--------|-------|---|--------|-------|
| game_data.gd | 1472 | | monster.gd | 283 |
| audio_manager.gd | 777 | | save_manager.gd | 540 |
| ui_manager.gd | 678 | | input_manager.gd | 542 |
| npc.gd | 693 | | network_manager.gd | 559 |
| localization.gd | 585 | | scene_manager.gd | 415 |
| player.gd | 516 | | game_manager.gd | 264 |
| quest_log.gd | 500 | | combat_effects.gd | 318 |
| dialogue.gd | 328 | | combat_feedback.gd | 261 |
| inventory.gd | 289 | | audio_config.gd | 209 |

---

## 4. REAL OPEN BLOCKERS (priority-ordered)

| # | Blocker | Owner | Est. |
|---|--------|-------|------|
| B1 | 8 modified + 5 untracked files uncommitted | Shiki | 15m |
| B2 | CI workflows only on feat/ci-workflows (not main) | Root | 1h |
| B3 | godot-export.yml pins Godot 4.2.2; game on 4.4 | Root | 30m |
| B4 | Web build possibly stale | Shiki | 1h |
| B5 | Server auth/sessions/CORS/rate-limit missing | Sentinel | 4h |
| B6 | DEFAULT_HOST="127.0.0.1" hardcoded | Shiki+Sentinel | 1h |
| B7 | Player walk/attack animation frames | Mio | 4h |
| B8 | No staging host/monitoring/alerting | Root | ongoing |
| B9 | Monetization=0 (no IAP/analytics/shop/funnels) | Business | — |

---

## 5. CONTINUATION PLAN (3 days, everyone in sync)

**Day 1 — Unify + verify base:**
- Shiki: commit B1; then run WS test vs live server (confirm PONG)
- Root: merge feat/ci-workflows → main; bump CI Godot 4.4 (template URL + barichello/godot-ci:4.4)
- Sentinel: verify /api/hello, /api/save round-trip on live server; confirm WS accept

**Day 2 — Parallel content/infra:**
- Mio: player walk/attack frames; wire into player.tscn + AnimationPlayer
- Sentinel: /api/register + /api/login + session token + CORS + rate limit
- Shiki: re-export web (godot --headless --export-release "Web" build/web/index.html)
- Root: staging host + basic uptime check

**Day 3 — Sync/verify gate:**
- CI green on main (Linux/Windows/Web artifacts)
- Web build loads in browser, no missing resources
- WS handshake confirmed client↔server
- DEFAULT_HOST configurable (env/const)

**Deploy/monetize gate (do not launch paid until):**
- [ ] Player art not placeholder; audio non-silent; import cache clean
- [ ] Auth + sessions + rate limits on server
- [ ] Monetization hooks (IAP/shop + analytics/funnels)
- [ ] CI auto-export green on main
- [ ] Staging + monitoring live

---

## 6. SYNC PROTOCOL (how we stay together)

1. Read `docs/TEAM_STATUS.md` before starting work
2. Update your role row + blockers when your status changes
3. Commit code changes; reference this audit when moving tasks
4. Any stale claim → fix immediately with evidence (commit/file/timestamp)
5. Agent Zero refreshes this audit + TEAM_STATUS from live probes whenever asked

---
*Feeds: TEAM_STATUS.md, TEAM_SYNC_STEP_1.md, REALIGNMENT_CHECKPOINT.md, WEB_EXPORT_PROCESS.md*
