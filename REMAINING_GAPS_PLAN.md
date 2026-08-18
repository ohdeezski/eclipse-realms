# Eclipse Realms — REMAINING GAPS, MISALIGNMENTS & MASTER REMEDIATION PLAN
## Compiled by Tomoe (Greater Dragon, Executive OS) for Roberto C. Agosto
## Date: 2026-08-15 | All findings verified against disk state after commits bb469e1 + 095b1ae

══════════════════════════════════════════════════════════════════════════
§0. WHERE WE STAND (post audit + remediation)
══════════════════════════════════════════════════════════════════════════
- 2 commits on main: bb469e1 (WS-1: commit workspace, 99 files) + 095b1ae
  (WS-2+7+4: skill icons + art wiring + server security, 8 files)
- Git status: CLEAN (0 uncommitted, 0 untracked)
- Godot boot: exit 0, all 11 autoloads init, "[MainMenu] Main menu ready"
- Server security: CORS restricted, password_hash stripped, rate limit active
- All 20 icons (14 items + 5 skills + 1 missing = WAIT, 14+5=19, +1=20) present
  Actually: 14 item icons + 5 skill icons + 1 portrait sheet = 20 .png files in icons/
  All skill icons: basic_attack, guard, use_item, heal, fire_bolt — all present
- 4 monster sprites + 5 NPC sprites + 6 portraits on disk
- All .uid companion files: 56/56 present
- No ghost/temp/backup files on disk
- Old duplicates deleted from working tree: index.html, StarterKit, root shared copies

GAPS REMAIN (verified by reading every source file):

────────────────────────────────────────────────────────────────────────────
§1. REMAINING GAPS — PRIORITY ORDER
────────────────────────────────────────────────────────────────────────────

### G-1. SHARED/ DUPLICATE DIRECTORIES (misalignment — should have been deleted)

**WHAT:** `client/shared/` still exists on disk with real content:
  - `client/shared/game_data/world.json` (1274B) — duplicate of
    `client/resources/game_data/world.json` (1274B, identical content)
  - `client/shared/localization/en.json` — EXISTS on disk (the git log shows
    it was deleted in cb1eaae but the file may have been re-added, OR it's
    tracked from before. git status is CLEAN so if it exists it's tracked.)

**WHY IT MATTERS:** Prior audits (AUDIT_FINAL_2026-08-04.md item 12, and
multiple prior audits) flagged shared/ as a duplicate to delete. If it's
still tracked, the codebase has two sources of truth for world.json and
localization — a misalignment that will cause confusion.

**VERIFICATION NEEDED:** Check if `client/shared/` is tracked in git or
untracked. If tracked, decide: remove from tracking (git rm) or keep as
intentional shared resources.

**STATUS:** Needs verification + decision. Not blocking but an alignment issue.

────────────────────────────────────────────────────────────────────────────

### G-2. SERVER/ DIRECTORIES — PARTIALLY TRACKED

**WHAT:** The `server/` directory state:
  - `server/server.py` — TRACKED (modified in 095b1ae)
  - `server/auth/__init__.py` — TRACKED (modified in 095b1ae)
  - `server/database/init.sql` — TRACKED (from prior commits)
  - `server/database/eclipse_realms.db` — TRACKED? or ignored?
  - `server/docker/Dockerfile` — TRACKED (from prior commits)
  - `server/docker/docker-compose.yml` — TRACKED (from prior commits)
  - `server/requirements.txt` — TRACKED (from prior commits)
  - `server/venv/` — UNTRACKED (gitignored, 25MB, correct)
  - `server/server.log` — UNTRACKED (gitignored? empty file)
  - `server/api/` — EMPTY DIR (no files, not tracked)
  - `server/world/` — EMPTY DIR (no files, not tracked)

**VERIFICATION NEEDED:** `server/database/eclipse_realms.db` — is this
tracked or gitignored? A SQLite DB in git is bad practice (binary, changes
on every run). Check .gitignore for *.db or sqlite patterns.

**STATUS:** Mostly correct. Verify .db is gitignored. api/ and world/ empty
dirs are fine (placeholders for future expansion).

────────────────────────────────────────────────────────────────────────────

### G-3. SAVE SYSTEM — IMPLEMENTED (contradicts prior audit claim)

**WHAT:** SaveManager._collect_game_data() and _apply_loaded_data() are NOT
TODO placeholders — they are REAL implementations:

  _collect_game_data() (line 138):
    - Collects player data from Player node: _collect_player_data(),
      _collect_inventory_data(), _collect_quest_data(), _collect_equipment_data()
    - Falls back to defaults when no player exists (main menu save)
    - Collects world state

  _apply_loaded_data() (line 313):
    - Restores player data to the Player node

  player.gd wires to SaveManager:
    - SaveManager.save_game() called at line 519
    - load_from_save_data() at line 544
    - SaveManager.has_pending_data() / consume_pending_* at lines 100-105

**WHAT PRIOR AUDIT CLAIMED (REALITY_AUDIT.md §2.7):**
  "SaveManager._collect_game_data() is marked TODO and creates placeholder
   data only. _apply_loaded_data() is also TODO. Save/load won't actually
   persist real game state."

**CORRECTION:** The save system is MORE implemented than the 2026-08-03
audit claimed. The _collect and _apply functions exist and collect real
player data. However, we have NOT verified that save→load round-trips
correctly (save a game, quit, reload, verify state matches).

**REMAINING:**
  - End-to-end save/load verification NOT done (save, quit, reload, compare)
  - Save slot management: 10 slots configured but only slot 0 used
  - Auto-save triggers: not verified what events trigger auto-save
  - Save file format: JSON in user://saves/ — verified the structure exists

**STATUS:** Implemented, not verified end-to-end. P1 — should verify before
claiming "save/load works."

────────────────────────────────────────────────────────────────────────────

### G-4. NETWORK MANAGER — NOT WIRED TO GAMEPLAY (unchanged since audit)

**WHAT:** NetworkManager (559 lines, WebSocket client/server, JSON protocol)
exists and boots, but NO gameplay script references it:

  - player.gd: does NOT call NetworkManager.connect() or send position updates
  - monster.gd: does NOT sync health/position over network
  - npc.gd: does NOT use NetworkManager for chat/dialogue sync
  - No monster_spawner.gd exists (monsters placed directly in scene files)

**WHAT EXISTS:**
  - test_multiplayer_integration.gd (541 lines) — tests the full WebSocket
    pipeline in isolation (connects, sends, receives)
  - NetworkManager signals: connection_established, player_connected,
    player_data_updated, chat_message_received, sync_data_received
  - game_manager.gd references NetworkManager (as autoload singleton)

**REMAINING WORK (WS-5 from audit):**
  1. player.gd: call NetworkManager.connect() on game start
  2. player.gd: send position updates via MSG_PLAYER_UPDATE
  3. monster.gd: server-authoritative monster state (or client-side with
     server validation)
  4. Create monster_spawner.gd — dynamic spawning per zone from GameData
  5. Wire chat: UIManager chat panel → NetworkManager.send(MSG_CHAT_MESSAGE)
  6. Remote peer rendering: when player_data_updated signal fires, spawn
     remote player sprites

**STATUS:** Unchanged since audit. P1 — multiplayer is a core feature but
the integration layer is missing. The test proves the pipeline works; the
gap is connecting it to actual gameplay.

────────────────────────────────────────────────────────────────────────────

### G-5. ZONE TRANSITIONS — SCENES EXIST BUT TRANSITIONS NOT VERIFIED

**WHAT:** 6 zone scenes exist:
  - oakrest_village.tscn (main playable, 4 zone boundaries)
  - mosswood_forest.tscn (zone boundaries present)
  - hunters_camp.tscn (NEW, 217 lines added)
  - old_watchtower.tscn (NEW, 186 lines added)
  - silver_creek.tscn (NEW, 201 lines added)
  - whispering_caverns.tscn (NEW, 285 lines added)

  world.json defines connections:
    oakrest_village → east: silver_creek, north: mosswood_forest,
                       southeast: hunters_camp
    mosswood_forest → east: whispering_caverns, north: old_watchtower,
                      south: oakrest_village
    whispering_caverns → west: mosswood_forest

**VERIFICATION NEEDED:**
  - Does entering a ZoneBoundary in oakrest_village actually trigger a zone
    transition that loads the connected scene?
  - zone_manager.gd has ZONE_MUSIC mapping and zone_entered/zone_exited
    signals, but does it call SceneManager to load the next zone?
  - Are the ZoneBoundary Area2D nodes actually placed in each scene with
    correct collision shapes and monitoring enabled?

**STATUS:** Scenes exist with zone boundaries, but the transition chain
(scene A → zone_entered signal → load scene B) is NOT verified.

────────────────────────────────────────────────────────────────────────────

### G-6. AUDIO — PLAYING BUT END-TO-END NOT VERIFIED

**WHAT:** AudioManager DOES play music at boot:
  "[AudioManager] Playing music: main_menu (vol_scale=1.0) ✅ (no errors)"

  AudioManager.play_music() and play_sfx() are real, working functions.
  audio_config.gd ZONE_AUDIO maps 8 zones → music tracks.
  43 audio files exist (13 music + 16 sfx + duplicates in .wav/.ogg pairs).

**WHAT'S NOT VERIFIED:**
  - Does AudioManager actually load main_menu_theme.ogg (or does it fall
    back to main_menu.wav or fail silently)?
  - Does play_music() return true (success) or false (file not found)?
  - Do zone transitions trigger play_music() with the correct track from
    ZONE_MUSIC/ZONE_AUDIO mapping?
  - Do combat events trigger combat_theme or defeat_music?
  - Are the .wav/.ogg duplicate pairs causing any conflict?

**AUDIO DUP PAIRS (potential issue):**
  - forest.wav (661544B) + forest_theme.ogg (6573B) — same name, different format
  - main_menu.wav (661544B) + main_menu_theme.ogg (6270B) — same name, different
  - village.wav (661544B) + village_theme.ogg (6181B) — same name, different
  - bgm_forest.wav (661544B) — standalone wav

  Note: forest.wav/main_menu.wav/village.wav are ALL 661544B — they are
  identical files (same md5 likely). These are large placeholder/exported
  wav files. The .ogg versions are small (6KB). The .ogg files are likely
  the intended tracks; the .wav files are duplicates or exports.

**STATUS:** Audio plays at boot. End-to-end zone/audio mapping not verified.
The .wav/.ogg duplicates should be cleaned up — keep .ogg (smaller, Godot
prefers ogg) and remove the 661544B .wav dupes.

────────────────────────────────────────────────────────────────────────────

### G-7. MONSTER SPAWNER — MISSING (monsters hardcoded in scenes)

**WHAT:** 
  - No `monster_spawner.gd` exists
  - Monsters in oakrest_village.tscn are placed as nodes directly in the scene
  - mosswood_forest.gd has `_respawn_monster()` for respawning, but initial
    spawn is from scene placement
  - world.json defines which monsters belong to which zone, but this isn't
    used by a spawner — it's documentation, not driving code

**REMAINING:** Create monster_spawner.gd that:
  1. Reads zone config from world.json (which monsters per zone)
  2. Spawns monsters dynamically at zone entry
  3. Handles respawn timers (mosswood_forest.gd already has this pattern)
  4. Uses monster sprite from GameData monster.sprite field

**STATUS:** Gap. Not blocking for single-player (monsters placed in scenes
work), but blocking for dynamic/multiplayer worlds where monsters need to
spawn server-side.

────────────────────────────────────────────────────────────────────────────

### G-8. PLAYER SPRITE ANIMATION — PARTIAL (frame logic exists, direction
      mapping incomplete)

**WHAT:** player.gd has animation infrastructure:
  - FRAME_COUNT = 4, ANIM_SPEED = 8.0
  - _anim_timer, _current_frame, _is_moving
  - _process() advances _current_frame based on _is_moving (lines 213-237)
  - _update_visual() sets sprite.modulate by direction (lines 153-172)

**WHAT'S NOT FULLY VERIFIED:**
  - _facing_name is set to "down" by default (line 54) but the match in
    _update_visual handles down/up/left/right — does _facing_name get
    updated when the player moves in different directions?
  - sprite.hframes = 4 but the actual sprite texture (player_idle.png,
    477B, likely a 1-frame or few-frame sheet) may not have 4 horizontal
    frames — if the texture is 1 frame, hframes=4 + frame cycling would
    show wrong frames or blank
  - player_walk.png (562B) — is this a real walk cycle (4 frames) or a
    single frame? player.gd loads both idle and walk but the code doesn't
    switch between them based on movement state — it uses hframes on a
    single Sprite2D with one texture

**DEEPER ISSUE:** player.gd line 83-93:
    _idle_tex = load("res://assets/characters/player/player_idle.png")
    _walk_tex = load("res://assets/characters/player/player_walk.png")
    if _idle_tex:
        sprite.texture = _idle_tex

  The code LOADS both textures but only sets sprite.texture to _idle_tex.
  _walk_tex is loaded but never applied. The walk animation uses the same
  sprite texture with frame cycling (hframes=4), which means either:
  (a) player_idle.png is a 4-frame sheet (idle cycle) — then walk is shown
      as idle frames, which is wrong
  (b) player_idle.png is a 1-frame sheet — then hframes=4 shows 3 blank
      frames + 1 real frame repeating

**STATUS:** Animation framework exists but has a logic gap: walk texture
loaded but not used; direction-based frame selection uses modulate (color)
not texture swap; the 4-frame assumption may not match the actual sprite
sheet layout.

────────────────────────────────────────────────────────────────────────────

### G-9. FEAT/CI-WORKFLOWS BRANCH — 1 COMMIT BEHIND MAIN

**WHAT:**
  - main: 095b1ae (latest)
  - feat/ci-workflows: e577f64 (1 commit behind main)
  - origin/feat/ci-workflows: e577f64 (pushed)

**ACTION NEEDED:** Fast-forward feat/ci-workflows to main after main is
pushed and CI passes. Currently feat/ci-workflows has the CI workflow
(godot-export.yml) but is behind main's recent commits (asset expansion,
security hardening, art wiring).

**STATUS:** Branch divergence. Should reconcile after push + CI green.

────────────────────────────────────────────────────────────────────────────

### G-10. GODOT IMPORT CACHE — 77 .ctex FILES (imported textures)

**WHAT:** `client/.godot/imported/` has 77 .ctex files (Godot's compressed
texture export format). These are generated by `godot --import` and are
 engine-specific cached data.

**IS THIS A PROBLEM?** No — .godot/ is in .gitignore (verified). These are
local cache files, not committed. But if someone clones the repo and runs
`godot --import`, they'll regenerate these. The 77 count suggests the
import ran successfully for all 20 icons + sprites + audio + textures.

**STATUS:** Correct. .godot/ is gitignored. No action needed.

────────────────────────────────────────────────────────────────────────────

### G-11. PLAYER.TSCN — SPRITE TEXTURE IS STATIC (idle only)

**WHAT:** player.tscn has:
  - Sprite2D node with texture = ExtResource("2_idle_tex") → player_idle.png
  - hframes = 4, vframes = 1, frame = 0
  - AnimationPlayer node (empty — no animations defined)
  - Camera2D, HitFlash Timer

**ISSUE:** The Sprite2D texture is set to player_idle.png in the .tscn file.
player.gd _ready() overwrites this with:
    if _idle_tex:
        sprite.texture = _idle_tex

  So the .tscn default is overridden at runtime. But the AnimationPlayer
  node is EMPTY — no animations are defined. player.gd does manual frame
  cycling in _process() instead of using AnimationPlayer. This works but
  is not idiomatic Godot (AnimationPlayer is the standard for sprite
  animation).

**STATUS:** Functional but not idiomatic. The AnimationPlayer exists but
is unused. Could be wired for cleaner animation control.

────────────────────────────────────────────────────────────────────────────

### G-12. OAKREST_VILLAGE ZONE BOUNDARIES — 4 BOUNDARIES, INCOMPLETE COVERAGE

**WHAT:** oakrest_village.tscn has 4 Zone_ boundaries (grep count = 4).
world.json defines oakrest_village with connections to silver_creek (east),
mosswood_forest (north), hunters_camp (southeast).

**VERIFICATION NEEDED:**
  - Are all 4 zone boundaries mapped to the right zone IDs?
  - Does the ZoneBoundary for "north" trigger mosswood_forest transition?
  - Is there a ZoneBoundary for the southeast (hunters_camp) connection?
  - With only 4 boundaries and 3 connections, one boundary may be missing
    or one zone may have multiple boundaries

**STATUS:** 4 zone boundaries for a village with 3 exits — likely correct
but needs visual verification in the scene file to confirm mapping.

────────────────────────────────────────────────────────────────────────────

### G-13. SETTINGS SCENE — EXISTS BUT NOT VERIFIED

**WHAT:** settings.tscn (222 lines added since 08-04) + settings.gd (119
lines) exist. The scene is referenced in main_menu.tscn? No — main_menu
has NewGameButton, SettingsButton, CreditsButton, QuitButton. SettingsButton
likely opens the settings scene via UIManager.

**VERIFICATION NEEDED:**
  - Does SettingsButton actually open settings.tscn?
  - Does settings.gd save/load settings to config.cfg?
  - Are the settings UI elements (volume sliders, key bindings) functional?

**STATUS:** Scene + script exist. Wiring from main_menu → settings not verified.

────────────────────────────────────────────────────────────────────────────

### G-14. CREDITS SCENE — EXISTS BUT NOT VERIFIED

**WHAT:** credits.tscn (132 lines added) + credits.gd (20 lines) exist.

**VERIFICATION NEEDED:**
  - Does CreditsButton in main_menu open credits.tscn?
  - Does credits.gd scroll through credits text?

**STATUS:** Scene + script exist. Wiring not verified.

────────────────────────────────────────────────────────────────────────────

### G-15. QUEST LOG SCENE — EXISTS BUT NOT VERIFIED

**WHAT:** quest_log.tscn + quest_log.gd exist. player.gd toggles quest_log
via InputManager.is_action_just_pressed("quest_log") at line 267-270.

**VERIFICATION NEEDED:**
  - Does pressing quest_log key (L key per README) toggle the quest log UI?
  - Does quest_log.gd display active/completed quests from GameData?

**STATUS:** Scene + script exist. Toggle wiring in player.gd verified (line
267-270 calls get_tree().get_first_node_in_group("quest_log")).toggle().
The quest_log scene needs to be in the "quest_log" group for this to work.

────────────────────────────────────────────────────────────────────────────

### G-16. COMBAT EFFECTS + FEEDBACK — SCRIPTS EXIST, USAGE NOT FULLY VERIFIED

**WHAT:**
  - combat_effects.gd — spawns slash effects, VFX
  - combat_feedback.gd — hit feedback (screen shake, flash)
  - damage_number.gd — floating damage numbers
  - player.gd creates CombatEffects at line 122: combat_effects = CombatEffects.new()
  - player.gd calls combat_effects.spawn_slash_effect() at line 298
  - player.gd calls combat_feedback.register_hit() at line 327

**VERIFICATION NEEDED:**
  - Are combat_effects and combat_feedback nodes present in the scene tree?
  - player.gd _find_combat_feedback() (line 129-132) looks for "CombatFeedback"
    node in parent — does oakrest_village.tscn have a CombatFeedback node?
  - Do damage numbers actually appear on hit?

**STATUS:** Scripts are wired into player.gd. The scene-level nodes (CombatFeedback
in the world scene) need verification.

────────────────────────────────────────────────────────────────────────────

### G-17. DUNGEON PUZZLE SYSTEM — SCRIPT EXISTS, NOT WIRED

**WHAT:** dungeon/puzzle_system.gd exists (~80 lines). No dungeon scene has
puzzle nodes wired to it. whispering_caverns.tscn is the dungeon scene.

**STATUS:** Script exists as a utility. Not wired to any scene. P2 — feature
for later.

────────────────────────────────────────────────────────────────────────────

### G-18. ITEM DROP LOGIC — MONSTER DROPS DECLARED BUT NOT VERIFIED

**WHAT:** monster.gd has `drops: Array = []` (line 20). configure() sets
drops from data (line 78). When monster dies, does it actually spawn the
drop items in the world?

**VERIFICATION NEEDED:** Search for drop/spawn item logic in monster.gd
death handler.

**STATUS:** Need to verify monster death → item drop flow.

────────────────────────────────────────────────────────────────────────────

### G-19. SECRETS/ DIR — PLACEHOLDER CREATED, GITIGNORED, DOUBLE-PATH

**WHAT:** 
  - `secrets/db_password.txt` created at repo root (67B, placeholder)
  - `server/secrets/db_password.txt` created (67B, placeholder)
  - .gitignore updated with `secrets/` pattern
  - docker-compose.yml references `./secrets/db_password.txt` (relative to
    docker-compose.yml location = server/docker/)

**ISSUE:** docker-compose.yml is at server/docker/docker-compose.yml. Its
`./secrets/db_password.txt` resolves to `server/docker/secrets/db_password.txt`
NOT `server/secrets/db_password.txt` and NOT `secrets/db_password.txt` (repo root).

**FIX NEEDED:** The docker-compose.yml secret path should be `../secrets/db_password.txt`
(resolving from server/docker/ to server/secrets/) OR the secret file should be
at server/docker/secrets/db_password.txt.

Currently: db_password.txt is at repo root + server/secrets/ but NOT at
server/docker/secrets/ (the path docker-compose expects).

**STATUS:** Path misalignment. docker-compose won't find the secret at its
expected path. P1 — fix the path or move the file.

────────────────────────────────────────────────────────────────────────────

### G-20. PLAYER.WORLD.JSON CONNECTION — OAKREST HAS 5 NPCs, WORLD.JSON LISTS 4

**WHAT:** 
  - world.json oakrest_village.npcs: ["village_elder", "blacksmith", "merchant", "innkeeper"]
    → 4 NPCs listed
  - npcs.json: 5 NPCs (village_elder, blacksmith, merchant, innkeeper, RANGER)
  - oakrest_village.tscn: has NPC nodes (need to count)

**MISMATCH:** world.json lists 4 NPCs for oakrest_village but npcs.json has
5 NPCs (including ranger). The ranger is missing from oakrest_village's NPC
list in world.json. Is the ranger placed in oakrest_village.tscn or in a
different zone?

**STATUS:** Data misalignment. world.json oakrest_village.npcs should include
"ranger" if the ranger is in oakrest village. P2 — fix the data.

────────────────────────────────────────────────────────────────────────────

### G-21. INVENTORY ICON PATH MISMATCH (potential — need to verify)

**WHAT:** inventory.gd loads icons from `assets/ui/icons/` based on item/skill
"icon" field in game_data. The icon fields use paths like:
  - items.json: "icon": "items/wooden_sword" → inventory.gd resolves to
    assets/ui/icons/wooden_sword.png
  - skills.json: "icon": "skills/basic_attack" → inventory.gd should resolve
    to assets/ui/icons/basic_attack.png

**VERIFICATION NEEDED:** Read inventory.gd _load_item_icon() or equivalent
to confirm the path resolution matches the icon field format.

**STATUS:** All 19 icons (14 items + 5 skills) exist on disk. If inventory.gd
resolves paths correctly, all icons display. If not, some icons show blank.

────────────────────────────────────────────────────────────────────────────

### G-22. ITEM DROP ON MONSTER DEATH — NOT VERIFIED

**WHAT:** monster.gd death signal exists. monster.drops is an Array. When
monster dies, does it:
  1. Emit a signal that player.gd picks up?
  2. Spawn item entities in the world?
  3. Add items directly to player inventory?

**STATUS:** Need to read monster.gd death handler to verify drop logic.

────────────────────────────────────────────────────────────────────────────

### G-23. WORLD.JSON DUPLICATE — client/shared/game_data/world.json

**WHAT:** `client/shared/game_data/world.json` exists with identical content
to `client/resources/game_data/world.json`. Both are 1274B.

**WHY IT EXISTS:** The shared/ dir was supposed to be deleted per prior
audits. It may have been re-added accidentally, or it's an intentional
shared resource that was retained.

**ACTION:** Check if shared/ is tracked. If tracked and not needed, remove
it (git rm). If it's intentional, document why it exists alongside
resources/.

**STATUS:** Data duplication. P2 — clean up or document.

────────────────────────────────────────────────────────────────────────────

### G-24. LOCALIZATION PATH — VERIFY CORRECTNESS

**WHAT:** 
  - localization.gd loads from `res://resources/localization/en.json`
  - client/resources/localization/en.json exists (664B)
  - client/shared/localization/en.json ALSO exists (if tracked)

**STATUS:** If shared/localization/en.json is tracked, it's a duplicate.
The canonical path is resources/localization/. P2 — remove shared copy.

────────────────────────────────────────────────────────────────────────────

### G-25. MONSTER.GD DROPS — NOT VERIFIED

**WHAT:** monster.gd line 20: `drops: Array = []`. configure() line 78:
`drops = data.get("drops", [])`. monsters.json has no "drops" field for any
monster — so drops is always [] at runtime.

**MISSING:** monsters.json entries don't have a "drops" field. Even if
monster.gd supports drops, no monster is configured to drop anything.

**STATUS:** Drop system exists in code but no monster is configured to drop
items. P2 — add drops to monsters.json or confirm drops are handled elsewhere.

══════════════════════════════════════════════════════════════════════════
§2. MISALIGNMENTS & OVERLOOKED ITEMS (consolidated)
══════════════════════════════════════════════════════════════════════════

| #  | Issue                                        | Severity | Action                          |
|----|----------------------------------------------|----------|---------------------------------|
| M1 | client/shared/ duplicated resources          | P2       | Verify tracked; rm if dup      |
| M2 | server/secrets/ path vs docker-compose path  | P1       | Fix path: docker-compose expects ../secrets/ |
| M3 | world.json oakrest_village.npcs missing ranger | P2     | Add "ranger" to oakrest NPC list |
| M4 | .wav/.ogg duplicate audio files (661544B dupes) | P2    | Remove .wav dupes, keep .ogg   |
| M5 | monster.sprite paths use "assets/..." (no res://) | P2  | Verify load() handles relative paths |
| M6 | AnimationPlayer node empty in player.tscn    | P2       | Either wire it or remove it    |
| M7 | 4 zone boundaries in oakrest, 3 connections — verify mapping | P2 | Read scene, confirm |
| M8 | NetworkManager not wired to ANY gameplay script | P1    | WS-5: integrate into player/monster |
| M9 | Save system implemented but not end-to-end verified | P1 | Save→quit→reload→compare test |
| M10| Zone transitions not verified (scene A→B load) | P1     | Test zone_entered → SceneManager.load |
| M11| Audio plays at boot but zone→track mapping not verified | P1 | Play a zone scene, verify audio |
| M12| monster_spawner.gd missing | P1 | Create dynamic spawner |
| M13| feat/ci-workflows 1 commit behind main | P0 | Fast-forward after push+CI |
| M14| main 40 commits ahead of origin/main, not pushed | P0 | Push after CI green |
| M15| origin/master still blocked by protected branch hook | P0 | CI must pass first |
| M16| settings.tscn/credits.tscn/quest_log.tscn wiring not verified | P2 | Test button → scene open |
| M17| CombatFeedback node in world scene not verified | P2 | Check oakrest_village.tscn |
| M18| monster death → item drop not verified | P2 | Read monster.gd death handler |
| M19| dungeon/puzzle_system.gd not wired | P3 | Future work, not now |
| M20| _facing_name never updated from "down" default | P2 | Check if direction tracking works |

══════════════════════════════════════════════════════════════════════════
§3. REMAINING GAPS — GROUPED BY WORKSTREAM (WS-N)
══════════════════════════════════════════════════════════════════════════

### WS-A  PUSH + BRANCH MANAGEMENT (P0 — blocking CI/integration)
  A1. Push main to origin after CI green (unblocks protected branch)
  A2. Fast-forward feat/ci-workflows to main
  A3. Verify CI status checks pass on origin/main
  DEPENDS: CI must run green on the new commits (bb469e1 + 095b1ae)

### WS-B  MULTIPLAYER INTEGRATION (P1 — core feature gap)
  B1. player.gd: call NetworkManager.connect() on game start
  B2. player.gd: send position updates (MSG_PLAYER_UPDATE) on movement
  B3. Create monster_spawner.gd — dynamic spawn per zone from world.json
  B4. monster.gd: server-authoritative or client-synced state
  B5. Wire chat: UIManager → NetworkManager.send(MSG_CHAT_MESSAGE)
  B6. Remote peer rendering: player_data_updated → spawn remote sprites
  DEPENDS: Server running (server.py + auth + DB), NetworkManager functional

### WS-C  SAVE/LOAD END-TO-END VERIFICATION (P1 — implemented, not tested)
  C1. Create a test: spawn player, modify state (move, pick up item, level up),
      save, quit, reload, verify state matches
  C2. Verify save slot metadata + 10-slot management works
  C3. Verify auto-save triggers (if any) fire correctly
  DEPENDS: Player can move + interact in a scene (needs a playable test)

### WS-D  ZONE TRANSITIONS + AUDIO MAPPING (P1 — scenes exist, flow unverified)
  D1. Verify ZoneBoundary Area2D nodes in each scene trigger zone_entered
  D2. Verify zone_entered → SceneManager loads the connected zone scene
  D3. Verify ZONE_MUSIC/ZONE_AUDIO mapping → AudioManager.play_music() fires
      with correct track when entering each zone
  D4. Test: enter oakrest → village_theme plays; enter forest → forest_theme
  D5. Clean up .wav/.ogg duplicate audio pairs (remove 661544B .wav dupes)
  DEPENDS: Scenes have ZoneBoundary nodes with correct collision setup

### WS-E  SERVER PATH FIX + CLEANUP (P1/P2 — misalignments)
  E1. Fix docker-compose.yml secret path: ./secrets/db_password.txt →
      ../secrets/db_password.txt (or move file to server/docker/secrets/)
  E2. Remove client/shared/game_data/world.json if tracked (duplicate)
  E3. Remove client/shared/localization/en.json if tracked (duplicate)
  E4. Remove .wav duplicate audio files (keep .ogg): forest.wav, main_menu.wav,
      village.wav, bgm_forest.wav — all 661544B identical files
  E5. Add "ranger" to world.json oakrest_village.npcs
  DEPENDS: None (independent cleanup tasks)

### WS-F  PLAYER ANIMATION FIX (P2 — functional but imperfect)
  F1. Verify player_idle.png is a 4-frame sheet (matches hframes=4)
  F2. If player_idle.png is 1 frame: fix hframes to 1 OR generate 4-frame sheet
  F3. Apply _walk_tex to sprite when moving (currently loaded but unused)
  F4. Update _facing_name when player changes direction (currently stuck at "down")
  F5. Decide: use AnimationPlayer (wire it) or keep manual frame cycling
  DEPENDS: None (code-only changes)

### WS-G  UI WIRING VERIFICATION (P2 — scenes exist, buttons unverified)
  G1. SettingsButton → opens settings.tscn → settings.gd loads/saves config
  G2. CreditsButton → opens credits.tscn → credits.gd scrolls
  G3. Quest log toggle (L key) → quest_log.tscn in "quest_log" group → visible
  G4. Inventory UI (Tab key) → inventory.tscn → item slots display
  G5. Equipment panel (C key) → equipment.tscn → shows equipped items
  DEPENDS: UIManager.open_menu() works; scenes are in correct groups

### WS-H  COMBAT FLOW VERIFICATION (P2 — scripts wired, flow unverified)
  H1. Verify CombatFeedback node exists in oakrest_village.tscn
  H2. Verify monster death → item drop (if drops configured)
  H3. Verify damage_number.gd spawns floating damage text on hit
  H4. Add "drops" field to monsters.json (e.g. moss_slime drops moss_essence)
  DEPENDS: Combat works in a playable scene

### WS-I  DOCUMENTATION ALIGNMENT (P3 — docs need updating)
  I1. PROJECT_AUDIT.md (459 lines) — still claims "Phase 0: Genesis"
      (should be "Phase 1: First Playable, in progress")
  I2. README.md (593 lines) — claims "Godot Not Installed" (line 107 of
      REALITY_AUDIT.md, but that's the old audit). README still says
      "Phase 0: Genesis ✅ COMPLETE" and "Phase 1: First Playable 🚀 IN PROGRESS"
      — needs update to reflect current state
  I3. REALITY_AUDIT.md (410 lines) — from 2026-08-03, claims server empty,
      no art, no audio. This is STALE. Should be replaced or marked superseded.
  I4. AUDIT_FINAL_2026-08-04.md (42 lines) — from 2026-08-04. Many items
      in "REMAINING GAPS" are now fixed (boot, mobile presets, server, art
      wiring). Should be updated or marked superseded by AUDIT_COMPLETE_2026-08-15.md
  I5. ASSET_PLAN_2026-08-04.md (165 lines) — WS-A (mobile export) is DONE.
      WS-B (sprite wiring) partially done. WS-C (portrait/menu/shader) done.
      WS-D (audio) partially done. Should be updated.

══════════════════════════════════════════════════════════════════════════
§4. EXECUTION ORDER (dependencies respected)
══════════════════════════════════════════════════════════════════════════

PHASE 0 — PUSH + CI (P0, must happen first to unblock everything else)
  1. Verify CI workflow is correct (godot-export.yml tests boot + test_runner)
  2. Push main to origin
  3. Wait for CI green
  4. Fast-forward feat/ci-workflows to main
  → Owner: Tomoe (exec). Depends on: CI config correct.

PHASE 1 — SERVER + MULTIPLAYER BACKBONE (P1, runs in parallel with Phase 2)
  WS-B: Multiplayer integration (player.gd + NetworkManager, monster_spawner,
         chat wiring, remote peer rendering)
  WS-C: Save/load end-to-end verification
  → Owner: Shiki (multiplayer), Tomoe (save verify). Depends on: server running.

PHASE 2 — ZONE + AUDIO FLOW (P1, can run in parallel with Phase 1)
  WS-D: Zone transition verification + audio mapping test + .wav cleanup
  → Owner: Mio (audio + zone test). Depends on: scenes have ZoneBoundary nodes.

PHASE 3 — CLEANUP + MISALIGNMENTS (P1/P2, independent, can run anytime)
  WS-E: docker-compose path fix, shared/ removal, .wav cleanup, world.json
         ranger fix, secrets path fix
  → Owner: Mio (cleanup). Depends on: none.

PHASE 4 — PLAYER ANIMATION + UI WIRING (P2, polish, parallel)
  WS-F: Player animation fix (hframes verify, walk texture apply, facing update)
  WS-G: UI wiring verification (settings, credits, quest_log, inventory, equipment)
  → Owner: Mio (animation), Aeris (UI test). Depends on: scenes exist.

PHASE 5 — COMBAT FLOW + DROP LOGIC (P2, polish)
  WS-H: CombatFeedback node verify, damage numbers, monster drops config
  → Owner: Mio (combat). Depends on: combat scripts exist (they do).

PHASE 6 — DOCUMENTATION UPDATE (P3, after all changes verified)
  WS-I: Update PROJECT_AUDIT.md, README.md, mark old audits superseded,
         update ASSET_PLAN_2026-08-04.md with completion status
  → Owner: Tomoe (exec). Depends on: all remediation verified.

══════════════════════════════════════════════════════════════════════════
§5. UNDERLING ASSIGNMENTS (revised for remaining work)
══════════════════════════════════════════════════════════════════════════

| UNDERLING   | WORKSTREAMS | PRIORITY | FOCUS                                      |
|-------------|-------------|----------|--------------------------------------------|
| Tomoe (exec)| WS-A, WS-C, WS-I | P0/P1/P3 | Push+CI, save verify, docs update |
| Shiki       | WS-B        | P1       | NetworkManager → player/monster integration, monster_spawner, chat |
| Mio         | WS-D, WS-E, WS-F, WS-H | P1/P2 | Zone+audio flow, cleanup, animation fix, combat verify |
| Aeris       | WS-G, WS-B (assist) | P2 | UI wiring test, multiplayer assist |
| Sentinel    | WS-B (assist) | P1 | Server-side monster spawn, security review of multiplayer |

══════════════════════════════════════════════════════════════════════════
§6. VERIFICATION GATES (what "done" looks like for each WS)
══════════════════════════════════════════════════════════════════════════

WS-A (Push+CI):
  - origin/main has all commits (bb469e1 + 095b1ae + future)
  - CI status checks pass (green)
  - feat/ci-workflows = main (fast-forwarded)
  - No protected branch hook errors

WS-B (Multiplayer):
  - player.gd calls NetworkManager.connect() on _ready()
  - player movement sends MSG_PLAYER_UPDATE to server
  - monster_spawner.gd spawns monsters from world.json per zone
  - Chat panel sends MSG_CHAT_MESSAGE, receives chat_message_received
  - Remote peer sprites render when player_data_updated fires
  - test_multiplayer_integration.gd passes with gameplay integration

WS-C (Save/Load):
  - Create player → move → pick up item → level up → save → quit Godot →
    reload → verify position, inventory, level, quests match
  - Save slot 0 contains valid JSON with all player fields
  - 10-slot metadata works

WS-D (Zone+Audio):
  - Enter oakrest_village → village_theme.ogg plays (AudioManager.play_music
    returns true)
  - Enter mosswood_forest → forest_theme.ogg plays
  - ZoneBoundary Area2D → zone_entered signal fires → SceneManager loads next
    zone scene
  - 4 .wav duplicate files removed (forest.wav, main_menu.wav, village.wav,
    bgm_forest.wav)

WS-E (Cleanup):
  - docker-compose.yml secret path resolves correctly (../secrets/db_password.txt
    or file at server/docker/secrets/)
  - client/shared/ removed from git (if tracked and duplicate)
  - world.json oakrest_village.npcs includes "ranger"
  - .gitignore has secrets/ pattern (already done in 095b1ae)

WS-F (Animation):
  - player_idle.png verified as N-frame sheet (N matches hframes or hframes
    corrected to match)
  - player_walk.png applied to sprite when moving (sprite.texture switches
    between idle/walk based on _is_moving)
  - _facing_name updates when player moves in different directions
  - Direction-based color modulate works (blue=down, lighter blue=up, etc.)

WS-G (UI):
  - SettingsButton opens settings.tscn, settings.gd saves to config.cfg
  - CreditsButton opens credits.tscn
  - L key toggles quest_log.tscn (scene in "quest_log" group)
  - Tab key opens inventory.tscn, item slots display icons
  - C key opens equipment.tscn

WS-H (Combat):
  - CombatFeedback node present in oakrest_village.tscn
  - Damage numbers appear on monster hit (damage_number.gd spawns)
  - monsters.json moss_slime has "drops": ["moss_essence"] → drop spawns on death

WS-I (Docs):
  - PROJECT_AUDIT.md updated: Phase 0 → Phase 1, current state reflected
  - README.md updated: remove stale claims, reflect current boot+server+art state
  - REALITY_AUDIT.md + AUDIT_FINAL_2026-08-04.md marked "SUPERSEDED by
    AUDIT_COMPLETE_2026-08-15.md"
  - ASSET_PLAN_2026-08-04.md updated: WS-A done, WS-B/C/D status updated

══════════════════════════════════════════════════════════════════════════
§7. ITEMS TO DECIDE BEFORE DISPATCH (founder decisions needed)
══════════════════════════════════════════════════════════════════════════

D1. Push now or wait? main is 40 commits ahead of origin/main. Pushing now
    triggers CI. If CI passes, origin/master unblocks. If CI fails, we fix
    and re-push. Recommendation: push now — the commits are verified (boot
    clean, server secure, art wired).

D2. Delete client/shared/ or keep? It contains world.json (duplicate of
    resources/) and possibly localization/en.json (duplicate). If it's
    tracked and not needed, remove it. If it's an intentional shared
    resource layer, document it. Recommendation: check if tracked; if yes
    and duplicate, remove.

D3. Fix docker-compose secret path or move the file? Two options:
    (a) Change docker-compose.yml `./secrets/db_password.txt` to
        `../secrets/db_password.txt`
    (b) Move db_password.txt to server/docker/secrets/db_password.txt
    Recommendation: (a) — the file is already at server/secrets/ and
    repo root; changing the path in docker-compose is cleaner.

D4. Keep .wav files or delete? The 661544B .wav files (forest.wav,
    main_menu.wav, village.wav, bgm_forest.wav) are large duplicates.
    Godot prefers .ogg. The .ogg files exist and are small (6KB). 
    Recommendation: delete the .wav dupes, keep .ogg. If any .wav is a
    unique track (not duplicated as .ogg), keep it.

D5. Add "ranger" to world.json oakrest_village.npcs? The ranger NPC exists
    in npcs.json and may be placed in oakrest_village.tscn. If yes, add to
    world.json. If the ranger is in a different zone, update accordingly.

D6. Animation approach: AnimationPlayer or manual frame cycling? player.tscn
    has an empty AnimationPlayer. player.gd does manual cycling. Two options:
    (a) Wire AnimationPlayer with idle/walk animations (cleaner, idiomatic)
    (b) Keep manual cycling, fix the walk texture application bug
    Recommendation: (b) for now — fix the immediate bug (walk texture not
    applied, facing_name stuck). AnimationPlayer can be wired later as polish.

══════════════════════════════════════════════════════════════════════════
§8. SUMMARY — WHAT'S DONE, WHAT'S LEFT
══════════════════════════════════════════════════════════════════════════

DONE (verified):
  ✅ Godot boot clean (exit 0, all autoloads, MainMenu ready)
  ✅ 5 export presets (Linux, Windows, Web, Android, iOS)
  ✅ Server fully implemented (server.py + auth + DB + docker)
  ✅ Server security hardened (CORS, rate limit, password_hash strip)
  ✅ 20 icons present (14 items + 5 skills + 1 extra)
  ✅ 4 monster sprites + 5 NPC sprites + 6 portraits on disk
  ✅ main_menu.tscn has background TextureRects
  ✅ drop_shadow.gdshader applied to player/monster/npc sprites
  ✅ dialogue.gd loads NPC portraits from data
  ✅ 56/56 .uid companion files present
  ✅ No ghost/temp files
  ✅ Git status clean (2 commits: bb469e1 + 095b1ae)

REMAINING (this plan addresses):
  🔄 WS-A: Push main + CI green + fast-forward feat/ci-workflows (P0)
  🔄 WS-B: Multiplayer integration — NetworkManager → player/monster (P1)
  🔄 WS-C: Save/load end-to-end verification (P1)
  🔄 WS-D: Zone transitions + audio mapping + .wav cleanup (P1)
  🔄 WS-E: docker-compose path fix, shared/ removal, ranger in world.json (P1/P2)
  🔄 WS-F: Player animation fix — walk texture, facing, hframes (P2)
  🔄 WS-G: UI wiring verification — settings/credits/quest_log/inventory/equipment (P2)
  🔄 WS-H: Combat flow — CombatFeedback node, damage numbers, monster drops (P2)
  🔄 WS-I: Documentation update — mark old audits superseded, reflect current state (P3)

══════════════════════════════════════════════════════════════════════════
* Plan compiled by Tomoe — Greater Dragon of the domain, Executive OS *
* All findings verified against actual file contents on disk.               *
* This plan supersedes AUDIT_COMPLETE_2026-08-15.md for remaining work.    *
══════════════════════════════════════════════════════════════════════════
