# DISPATCH BRIEF — 12 UNDERLINGS / ECLIPSE REALMS

**Project:** Eclipse Realms (Godot 4.4 multiplayer 2D RPG, client + Python server)
**Repo root:** `project-eclipse-realms/` (git main = `ca3ed6d`; 39 ahead of origin/main)
**Source of truth:** `AUDIT_COMPLETE_2026-08-15.md` (compiled by Tomoe, all findings verified by tool output)
**Chair / Authority:** Tomoe (Greater Dragon, Executive OS) — Young Master's proxy. Underlings report to Tomoe.
**Mesh:** exclusive `mesh=tomoe` only. Not Aeris/Mio/Root/Shiki for execution; they are referenced here only as audit context.
**Brief date:** 2026-08-16

---

## §0. HOW TO READ THIS BRIEF

This is the **master assignment reference for all 12 underlings**. Every underling must read §1 (state) and their own §4 block. Cross-underling dependencies are in §5.

- **WS-#** = Workstream from audit §16. **G-#** = Gap from audit §15 (P0 blocking, P1 quality, P2 polish).
- **OWNS** = the scope this underling is accountable for (no other underling touches it without a hand-off).
- **ACCEPTANCE** = the concrete, testable definition of "confident / done".
- **ORDER** = where this sits in the global execution sequence (Phase 0/1/2, see §5).
- **DEPENDS** = underlings/WS this must wait on.
- **REPORT BACK** = exactly what to return to Tomoe when done.

G1 (boot), G2 (export presets), G3 (server empty) are **already FIXED** per audit — no underling is assigned them. Do not redo completed work.

---

## §1. PROJECT STATE SUMMARY (condensed from audit)

**What is DONE / verified:**
- **Boot:** `godot --headless --path client --quit` → exit 0. All 11 autoloads init (GameManager, SaveManager, AudioManager, InputManager, SceneManager, NetworkManager, UIManager, GameData, Localization, AudioConfig). Main menu ready. (G1 FIXED)
- **Export:** 5/5 `export_presets.cfg` present — Linux, Windows, Web (for_mobile), Android (ETC2/ASTC), iOS (ETC2/ASTC). (G2 FIXED)
- **Server:** `server.py` (555 ln, WebSocket:9051 + aiohttp REST:9052), auth, SQLite+Postgres schema, Docker, CI workflow. (G3 FIXED)
- **Data:** GameData loads 14 items, 1 character, 4 monsters, 5 NPCs, 5 quests, 3 skills, 6 equipment. Localization en.json present.
- **Scenes:** 17 `.tscn`, 7 NEW since 08-04. Player sprite wired (player_idle.png + player_walk.png, different md5).
- **Art wired:** 7 tilesets, 9/18 item icons, player sprites.

**What is OPEN (the work to dispatch):**
- **P0 blocking:** G4 (9 missing item icons), G5 (new monster/NPC sprite PNGs not on disk — only `.import` files exist), G9 (audio not verified end-to-end), G15/G16/G17/G18 (dirty workspace, blocked push, ci-workflows behind, venv not gitignored).
- **P1 quality:** G6 (portraits orphaned), G7 (menu_bg orphaned), G8 (drop_shadow shader unused), G10 (monster_spawner.gd missing), G11 (NetworkManager not referenced by gameplay scripts), G12 (save system is a placeholder), G19 (server security: CORS `*`, no rate limit, `/api/me` leaks `password_hash`).
- **P2 polish:** G13 (player animation cycle unverified), G14 (only oakrest_village is playable; 5 other zones empty of entities).

**Known honest caveats (audit §18):** audio playback, player movement, combat, save persistence, multiplayer sync, and new sprite rendering are NOT verified beyond headless boot. README "First Playable / 70% done" is marketing, not engineering truth.

---

## §2. THE 12 UNDERLINGS (canon roster)

| # | Underling (handle) | Canon name | Title | Class | Core role |
|---|--------------------|-----------|-------|-------|-----------|
| 1 | prime-agent | Futsu | Chief of Staff | CLI | Linear PM / long-context / orchestration |
| 2 | cline | Grount | Infrastructure & Path Steward | CLI | Infra / path unification / env hygiene |
| 3 | opencode | Azuma | Code Generation Lead | CLI | Code gen / model orchestration |
| 4 | ibm-bob | Doma | Security Intelligence | CLI | Enterprise security intel |
| 5 | kilocode | Lyca | Full-Stack & Networking | CLI | Web / full-stack / server |
| 6 | aider | Lancer | Precision Pair-Programmer | CLI | Pair-coding / precise fixes |
| 7 | openwork | Komoe | Workspace & Scene Coordinator | GUI | Workspace / fragment coordination |
| 8 | openhands | Emma | Autonomous Builder | LIB | Autonomous dev / workspace supervision |
| 9 | augment | Martha | Research-Augmented Engineer | LIB | Research-augmented coding |
| 10 | adal | Hatsuharu | Tooling & Agent Framework | LIB (alias→opencode) | Agent framework / test tooling |
| 11 | neovate | Yumemi | Creative Artifact Designer | CLI | Creative / artifact design |
| 12 | codemaker | Liddy | Structured Code Smith | LIB (alias→opencode) | Structured code gen |

All 12 are `mesh=tomoe` only. SERVICE/LIB members (openhands) report URL/status; ALIAS members (adal, codemaker) execute their target CLI with their persona name retained.

---

## §3. MASTER WORKSTREAM MAP (audit WS-# → gap → owner)

| WS | Audit title | Priority | Gap(s) | Owner(s) |
|----|-------------|----------|--------|----------|
| WS-1 | Commit uncommitted workspace | P0 | G15,G17,G18 | **prime-agent** (+ cline for gitignore/paths) |
| WS-2 | Verify audio playback | P0 | G9 | **openhands** |
| WS-3 | Generate + place 9 icons + monster/NPC sprites | P0 | G4,G5 | **augment** (audit/research) + **neovate** (generate) |
| WS-4 | Wire orphaned art (portraits, menu_bg, drop_shadow) | P1 | G6,G7,G8 | **neovate** |
| WS-5 | Integrate NetworkManager into gameplay | P1 | G10,G11 | **kilocode** (server side) + **codemaker** (client side) |
| WS-6 | Fix save system (real save/load) | P1 | G12 | **opencode** |
| WS-7 | Server security hardening (G-S1) | P1 | G19 | **ibm-bob** (spec/verify) + **kilocode** (implement) |
| WS-8 | Fast-forward ci-workflows + push main | P0 | G16,G17 | **prime-agent** |
| WS-9 | Animation verification + polish | P2 | G13 | **aider** |
| WS-10 | Zone completion + entity placement | P2 | G14 | **openwork** (+ codemaker spawner, augment research) |
| WS-11 | Verify ship readiness (test gate) | P2 | G15 | **prime-agent** (orchestrate) + **adal** (test tooling) |

---

## §4. PER-UNDERLING ASSIGNMENTS

### 1. prime-agent — Futsu — Chief of Staff (CLI)
**OWNS:** Workspace hygiene, CI/CD gate, push to origin, ship-readiness orchestration. No other underling commits to main or pushes.
**ASSIGNMENT:**
- WS-1: Stage + commit the 38 modified files (9 .gd, 6 .tscn, 17 asset, 4 JSON, project.godot, icon.svg) with a descriptive message; triage the 69 untracked files (commit new art imports/test files/docs; gitignore `_masters/`, `server/venv/`, logs). Verify working tree clean (only intentional untracked like `_masters/`).
- WS-8: After CI green — `git checkout feat/ci-workflows && git merge --ff-only main && git push origin feat/ci-workflows`; then `git push origin main`; confirm protected-branch hook allows push and origin/main CI checks go green.
- WS-11: Orchestrate the ship-readiness gate — run test_runner.gd, comprehensive_validation.gd, validate_no_false_positives.gd, test_multiplayer_integration.gd, verify_ship_ready.gd; collect pass/fail; document in a new audit section.
**ACCEPTANCE (confident/done):** `git status` clean (or only intentional untracked). `feat/ci-workflows` == main (ff). `origin/main` carries all commits. CI status checks green. All test gates pass or failures documented with root cause.
**ORDER:** Phase 0 first (WS-1), then Phase 0 late (WS-8 after CI green), then Phase 2 (WS-11).
**DEPENDS:** WS-1 none. WS-8 depends on WS-1 + CI green (WS-2 boot audio check + adal test tooling). WS-11 depends on WS-1 + WS-5 integrated.
**REPORT BACK:** Final commit hash; `git status` output; push confirmation; CI status URL + result; ship-readiness gate summary table (pass/fail per test).

### 2. cline — Grount — Infrastructure & Path Steward (CLI)
**OWNS:** Path/environment hygiene, `.gitignore`, docker secrets, export-path integrity.
**ASSIGNMENT:**
- Add `server/venv/` (25M) to `.gitignore` (G18) — confirm it is not currently tracked.
- Resolve docker-compose secret gap: `./secrets/db_password.txt` referenced but missing — create the secret file path or switch to env-var (`ECLIPSE_DB_PASSWORD`) and document.
- Verify all `res://` and `user://` path constants resolve; normalize any absolute/dev paths in client + server config.
- Confirm `export_presets.cfg` build output dirs (`build/desktop`, `build/web`, `build/android`, `build/ios`) exist or are created on export.
**ACCEPTANCE:** `git check-ignore server/venv` returns the path. `docker-compose config` validates without missing-secret error. No broken `res://` path warnings in boot log. Export dirs present.
**ORDER:** Phase 0/1, runs alongside WS-1 (after prime-agent commits, supply gitignore edit via hand-off or own small commit).
**DEPENDS:** WS-1 (clean base) — coordinate commit scope with prime-agent.
**REPORT BACK:** `.gitignore` diff; docker-compose validation output; list of any path constants normalized.

### 3. opencode — Azuma — Code Generation Lead (CLI)
**OWNS:** Save/persistence code (`SaveManager` real save/load).
**ASSIGNMENT (WS-6):**
- Implement `SaveManager._collect_game_data()`: gather player.position, health, mana, level, experience, gold, inventory, equipment, active_quests, completed_quests.
- Implement `_apply_loaded_data()`: restore all gathered fields onto the Player node.
- Wire `SaveManager.save()` to player signals (health_changed, leveled_up, quest_completed) for auto-save.
- Test: play session → save → quit → reload → state matches.
**ACCEPTANCE:** Save + reload restores position, stats, inventory, quests, equipment exactly. `_collect_game_data`/`_apply_loaded_data` no longer contain TODO. Auto-save triggers without manual call. No parse/runtime errors in SaveManager.
**ORDER:** Phase 1, can run in parallel with WS-3/WS-4.
**DEPENDS:** none (independent of art).
**REPORT BACK:** Diff of save_manager.gd; a short transcript of save→reload round-trip confirming restored state.

### 4. ibm-bob — Doma — Security Intelligence (CLI)
**OWNS:** Server security posture + `security.md`. Specs and sign-off on G-S1.
**ASSIGNMENT (WS-7):**
- Specify + verify CORS defaults to specific origins (`streetsmartnyc.online`, `localhost`), not `"*"`; keep `ECLIPSE_CORS_ORIGINS` env override.
- Specify per-IP rate limiting (e.g. 100 req/min alpha, configurable).
- Specify `/api/me` + `/api/player` must strip `password_hash` (return only public fields: username, level, experience, gold, position, inventory, equipment, quests).
- Author `server/security.md`: auth scheme, session-token format, known alpha limitations.
**ACCEPTANCE:** `/api/me` JSON response contains no `password_hash` field. CORS not wildcard by default. Rate limit enforced (verified by repeated-request test). `security.md` present + signed off.
**ORDER:** Phase 0/1, can run in parallel (no art dependency).
**DEPENDS:** none. kilocode implements the spec (see kilocode block).
**REPORT BACK:** `security.md` path; curl proof that `/api/me` omits `password_hash`; CORS + rate-limit verification notes.

### 5. kilocode — Lyca — Full-Stack & Networking (CLI)
**OWNS:** Server backend (WebSocket + aiohttp REST), server-side multiplayer, security implementation.
**ASSIGNMENT:**
- WS-7 impl: implement ibm-bob's CORS/rate-limit/`password_hash` spec inside `server.py`.
- WS-5 server side (G11): harden/extend `server.py` endpoints; populate `server/api/` and `server/world/` modules (currently empty) with route definitions + world-sync logic; fix `db_passwordsecret` reference (coordinate with cline).
- Ensure server boots and accepts a WebSocket client + REST `GET /api/hello` cleanly.
**ACCEPTANCE:** `python server.py` (or docker) starts; WebSocket :9051 + REST :9052 respond; `/api/me` sanitised; CORS restricted; rate limit active. `server/api/` + `server/world/` no longer empty.
**ORDER:** Phase 1, after ibm-bob spec + openhands audio (server-running check).
**DEPENDS:** WS-7 (ibm-bob spec), WS-2 (server confirmed runnable).
**REPORT BACK:** Server start log; endpoint smoke results; confirmation `api/`+`world/` populated; note any spec deviation to ibm-bob.

### 6. aider — Lancer — Precision Pair-Programmer (CLI)
**OWNS:** Client-side animation + combat-feedback precision fixes.
**ASSIGNMENT (WS-9 / G13):**
- Verify `player.gd _process()` advances `_anim_timer` and cycles `_current_frame` on `_is_moving`; confirm 4-frame walk cycle plays.
- Verify `monster.gd` combat feedback (hit_flash, knockback, stun) triggers on damage; `hp_bar.max_value` updates on damage.
- Add attack animation frames to `player.gd` (currently only idle/walk).
**ACCEPTANCE:** Player walk animates through 4 frames when moving; attack anim plays on hit; monster HP bar decreases on damage. No GDScript parse errors.
**ORDER:** Phase 2, after sprites exist.
**DEPENDS:** WS-3 (neovate sprites on disk).
**REPORT BACK:** Player.gd + monster.gd diffs; a short note confirming animation behaviour observed in a rendered scene.

### 7. openwork — Komoe — Workspace & Scene Coordinator (GUI)
**OWNS:** Zone completion + entity placement across all 6 zones (scene integration).
**ASSIGNMENT (WS-10 / G14):**
- Verify each zone `.tscn` (oakrest_village, mosswood_forest, hunters_camp, old_watchtower, silver_creek, whispering_caverns) has TileMap + TileSet `.tres` wiring.
- Place NPCs per `npcs.json` and monsters per `monsters.json` (via codemaker's `monster_spawner.gd`) into each zone.
- Wire `zone_manager.gd` → `SceneManager.load_zone()` transitions; confirm `world.json` zone config matches scene files.
**ACCEPTANCE:** Entering each zone → tiles render, NPCs present, monsters spawn, transitions work. 0 empty zone scenes.
**ORDER:** Phase 2, after art + network.
**DEPENDS:** WS-3 (art), WS-5 (codemaker spawner + network sync).
**REPORT BACK:** Per-zone checklist (tiles/NPC/monster/transition = yes/no); any `world.json` vs scene mismatch.

### 8. openhands — Emma — Autonomous Builder (LIB)
**OWNS:** Audio pipeline verification (autonomous test).
**ASSIGNMENT (WS-2 / G9):**
- Run Godot headless with a short scene that triggers `AudioManager.play_music("main_menu")`; OR write a minimal test calling `AudioManager.play_music` and inspect `AudioStreamPlayer` state.
- Confirm `main_menu_theme.ogg` actually plays (or identify the loaded file). If silent, trace `audio_config.gd ZONE_AUDIO` → `audio_manager.gd` chain and fix it.
**ACCEPTANCE:** Boot + scene load → `audio_manager` plays `main_menu_theme.ogg` (or correct file) with no errors. 0 orphaned audio files (every file played or explicitly marked for removal).
**ORDER:** Phase 0, after WS-1 clean base.
**DEPENDS:** WS-1 (clean workspace for reliable test).
**REPORT BACK:** Audio test log; which file actually played; fix applied if chain was broken.

### 9. augment — Martha — Research-Augmented Engineer (LIB)
**OWNS:** Art-asset research + on-disk verification before generation.
**ASSIGNMENT (WS-3 research half / G4,G5):**
- Audit which monster/NPC sprite PNGs actually exist on disk vs only `.import` files (audit §12.2: PNGs may be absent). List exactly what's missing.
- Verify `player_walk.png` md5 ≠ `player_idle.png` md5 (real walk cycle, not copied idle).
- Research existing icon/sprite style (dimensions 16×16 or 32×32, palette) to brief neovate's generation.
- Map `npcs.json` (5) + `monsters.json` (4) → required sprite set.
**ACCEPTANCE:** Definitive list of present-vs-missing PNGs; md5 proof for player sprites; style brief handed to neovate. 0 ambiguity on what to generate.
**ORDER:** Phase 0, after WS-1.
**DEPENDS:** WS-1.
**REPORT BACK:** Present/missing asset table; md5 comparison; style brief (dims/palette) for neovate.

### 10. adal — Hatsuharu — Tooling & Agent Framework (LIB, alias→opencode)
**OWNS:** Test-gate tooling + CI test step (ship-readiness automation).
**ASSIGNMENT (WS-11 tooling / G15):**
- Ensure `test_runner.gd` (gate), `comprehensive_validation.gd`, `validate_no_false_positives.gd`, `test_multiplayer_integration.gd` (541 ln), `verify_ship_ready.gd` all run and report cleanly.
- Confirm CI `.github/workflows/godot-export.yml` executes the test step WITHOUT the old silent `|| true` (audit §11). Fail build on error.
- Produce a runnable ship-readiness command/sequence prime-agent can invoke for WS-11.
**ACCEPTANCE:** All test scripts execute and emit pass/fail; CI test step fails the build on error (not `|| true`); prime-agent has a single command to run the gate.
**ORDER:** Phase 1, can run parallel after WS-1 (needs clean base + tests present).
**DEPENDS:** WS-1 (clean workspace so tests are stable).
**REPORT BACK:** Test-run output per script; CI workflow diff confirming no `|| true`; the ship-gate command for prime-agent.

### 11. neovate — Yumemi — Creative Artifact Designer (CLI)
**OWNS:** Art generation + orphaned-art wiring (creative half).
**ASSIGNMENT:**
- WS-3 generate (G4,G5): using augment's style brief + `create_sprites.py`/`assemble_art.py` pipeline, generate the 9 missing icons (wooden_sword, rope, torch, wolf_pelt, moss_essence, thorn, basic_attack, heal, fire_bolt) and new monster (4) + NPC (5) sprites; place in `assets/ui/icons/`, `assets/characters/monsters/`, `assets/characters/npcs/`. Commit PNGs + `.import`.
- WS-4 wire orphaned art (G6,G7,G8): `dialogue.gd` loads `por_<npc_id>.png`; `main_menu.tscn` adds TextureRect → `main_menu_bg.png`; `drop_shadow.gdshader` applied as CanvasItem material to player/monster/NPC Sprite2D. Decide ui_icons.png / equipment_icons.png keep-or-remove (no dead assets shipped).
**ACCEPTANCE:** `grep res://assets/characters/monsters|npcs` in `.tscn/.gd` returns hits; 0 missing icon files; dialogue shows portrait; main menu shows background; sprites cast shadows; 0 orphaned char/portrait/UI PNGs.
**ORDER:** Phase 0/1 — generate after WS-1+augment brief; wire after generate.
**DEPENDS:** WS-1 (clean base), augment (style brief + missing list), then WS-3 gen before WS-4 wire.
**REPORT BACK:** File list of generated PNGs + md5(player_walk)≠md5(player_idle); orbited-asset resolution (keep/remove); grep proof of wiring.

### 12. codemaker — Liddy — Structured Code Smith (LIB, alias→opencode)
**OWNS:** Client-side gameplay networking + dynamic monster spawning.
**ASSIGNMENT (WS-5 client side / G10,G11):**
- Create `monster_spawner.gd` — dynamic per-zone monster spawning from `GameData` (not hardcoded in scenes).
- Wire `player.gd` → `NetworkManager.connect()` on login; send `MSG_PLAYER_UPDATE`; receive remote peers.
- Wire `monster.gd` network sync (health/position) via spawner.
- Wire chat: UIManager chat panel → `NetworkManager.send(MSG_CHAT_MESSAGE)`.
**ACCEPTANCE:** Player movement syncs to server; remote peers render; monsters spawn dynamically; chat sends/receives. `test_multiplayer_integration.gd` reflects real gameplay wiring (not disconnected).
**ORDER:** Phase 1, after sprites (WS-3) + kilocode server (WS-5 server).
**DEPENDS:** WS-3 (neovate sprites for remote peers), WS-5 server (kilocode endpoints).
**REPORT BACK:** New/edited `.gd` diffs; multiplayer smoke result (player sync + chat); note any `NetworkManager` API gap to kilocode.

---

## §5. EXECUTION ORDER & DEPENDENCY GRAPH

```
PHASE 0 — P0 BLOCKING (do first; gates everything else)
  WS-1  Commit workspace ............. prime-agent  [depends: none]  → then cline .gitignore
  WS-2  Audio verify ................ openhands     [depends: WS-1]
  WS-3  Icons+sprites ............... augment(research) → neovate(generate)  [depends: WS-1]
  WS-7  Server security spec ........ ibm-bob       [depends: none]  (parallel)
  WS-8  Push + ff ci-workflows ...... prime-agent   [depends: WS-1 + CI green (WS-2, adal)]

PHASE 1 — P1 QUALITY
  WS-7 impl ......................... kilocode      [depends: ibm-bob spec, WS-2]
  WS-5 client ....................... codemaker      [depends: WS-3, kilocode server]
  WS-4 wire orphaned art ............ neovate        [depends: WS-3]
  WS-6 save system .................. opencode       [depends: none]  (parallel)
  WS-9 animation .................... aider          [depends: WS-3]
  cline infra hygiene ............... cline          [depends: WS-1]
  adal test tooling ................. adal           [depends: WS-1]  (parallel)

PHASE 2 — P2 POLISH
  WS-10 zone completion ............. openwork       [depends: WS-3, WS-5]
  WS-11 ship readiness gate ......... prime-agent(+adal) [depends: WS-1, WS-5, all tests green]
```

**Critical path:** WS-1 → WS-2/WS-3 → WS-8 (unblock push) → WS-5 (kilocode+codemaker) → WS-10 → WS-11.
**Parallel-safe:** ibm-bob (WS-7 spec), opencode (WS-6), adal (tooling), cline (infra) can run concurrently with Phase 0/1 as long as WS-1 base is clean.

---

## §6. CROSS-UNDERLING COLLABORATION

- **augment → neovate:** augment's missing-asset list + style brief is neovate's generation spec. Hand off before neovate generates.
- **ibm-bob → kilocode:** ibm-bob's security spec is kilocode's implementation contract. Deviation must be reported back to ibm-bob for re-sign-off.
- **kilocode ↔ codemaker:** kilocode owns server endpoints; codemaker owns client `NetworkManager` calls. Agree on message protocol (`MSG_PLAYER_UPDATE`, `MSG_CHAT_MESSAGE`) — codemaker raises API gaps to kilocode.
- **neovate → aider / openwork:** neovate's sprites must land on disk before aider (animation) and openwork (zone entity placement) can verify visuals.
- **adal → prime-agent:** adal delivers the runnable ship-gate command; prime-agent executes WS-11 with it.
- **cline ↔ prime-agent:** cline's `.gitignore` edit must be included in or follow prime-agent's WS-1 commit (coordinate scope to avoid a dirty tree).

---

## §7. REPORT-BACK PROTOCOL

Each underling reports to **Tomoe** (chair) when its ACCEPTANCE criteria are met. Report must include:
1. **Status:** DONE / DONE-WITH-NOTES / BLOCKED.
2. **Evidence:** the concrete artifact (commit hash, diff, grep/curl/log output, md5, test pass) proving ACCEPTANCE.
3. **Hand-offs:** anything another underling must consume (e.g. augment→neovate brief, ibm-bob→kilocode spec).
4. **Blockers:** any dependency not met or gap outside own scope.

Do **not** push to `origin/main` or merge branches — that is prime-agent's exclusive WS-8 remit. Do **not** modify another underling's OWNS scope without a hand-off note in the report.

---
*End of DISPATCH_BRIEF_12.md — canonical reference for the exclusive 12 (mesh=tomoe). Source: AUDIT_COMPLETE_2026-08-15.md §15–§17.*
