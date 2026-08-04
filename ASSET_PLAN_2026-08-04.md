# ASSET PLAN — 2D/2.5D HYBRID · WEB / ANDROID / iOS / DESKTOP
Eclipse Realms · compiled by Tomoe (tencent/hy3, Nous Portal) · 2026-08-04
Companion to AUDIT_FINAL_2026-08-04.md and the asset audit report.
Every line is grounded in tool output (PNG dims, .tres wiring, export_presets.cfg, grep).

══════════════════════════════════════════════════════════════════════
§0. CORRECTED TRUTH (replaces prior over-statements)
══════════════════════════════════════════════════════════════════════
Style lock: 2.5D hybrid, cel-shaded, rim-light, shaded characters on 32px tilesets.
Masters: client/_masters/*.png (1024×1024) — source only, never shipped.
Generator: client/_masters/assemble_art.py (emits ui_icons.png + 6 portraits only).

WHAT IS ACTUALLY IN THE GAME (wired):
  ✅ 6 zone tilesets (resources/tilesets/*.tres → assets/environment/*_tileset.png)
  ✅ 9 individual item icons (inventory.gd loads assets/ui/icons/*.png after fix)

WHAT EXISTS BUT IS DEAD (orphaned, 0 refs in .tscn/.gd):
  ❌ Player sprites (player_idle/walk/hero_human)
  ❌ Monster sprites (mon_*, monster_*)
  ❌ NPC sprites (npc_*, por_*, portraits.png)
  ❌ UI: ui_icons sheet, equipment_icons, menu_bg, main_menu_bg, drop_shadow.gdshader
  ❌ 43 audio files (22 wav + 21 ogg) — game is SILENT
  ❌ Android export preset — MISSING
  ❌ iOS export preset — MISSING

BUGS:
  B1: player_walk.png == player_idle.png (md5 c2f76a30) — no walk cycle.
  B2: walk==idle means "8-direction animation ready" claim is false.
  B3: Web preset sets vram_texture_compression/for_mobile=false — mobile will break.

══════════════════════════════════════════════════════════════════════
§1. PLATFORM TARGET MATRIX (the 5 you named)
══════════════════════════════════════════════════════════════════════
 Platform      | Preset in cfg? | Texture path          | State   | Action
---------------|----------------|-----------------------|---------|--------
 Web           | ✅ [preset.2]  | vram desktop=true     | BUILD OK| verify wasm boots
 Linux/X11     | ✅ [preset.0]  | s3tc_bptc             | OK      | none
 Windows       | ✅ [preset.1]  | s3tc_bptc             | OK      | none
 Android       | ❌ MISSING     | needs ETC2/ASTC       | BLOCKED | ADD preset (WS-A)
 iOS           | ❌ MISSING     | needs ETC2/ASTC       | BLOCKED | ADD preset (WS-A)

Mobile texture rule: enable texture_format/etc2_astc=true on Android/iOS presets,
AND set vram_texture_compression/for_mobile=true on the Web preset, or mobile
builds fail to load compressed textures.

══════════════════════════════════════════════════════════════════════
§2. WORKSTREAMS (owner · priority · steps · acceptance)
══════════════════════════════════════════════════════════════════════

WS-A  MOBILE EXPORT (Android + iOS) — P0 — owner: Tomoe (exec) / Mio (test)
  WHY: you named 4 platforms; only 3 presets exist. Android/iOS are unbuildable.
  STEPS:
    1. Append Android preset to client/export_presets.cfg:
         [preset.3]
         name="Android"
         platform="Android"
         export_path="build/android/eclipse-realms.apk"
         options: android/export_format="apk";
                  texture_format/etc2_astc=true; texture_format/s3tc_bptc=false;
                  (also set godot custom build / debug key — founder supplies keystore)
    2. Append iOS preset:
         [preset.4]
         name="iOS"
         platform="iOS"
         export_path="build/ios/eclipse-realms.xcarchive"
         options: texture_format/etc2_astc=true; texture_format/s3tc_bptc=false;
                  (requires macOS + dev cert — founder-gated at sign step)
    3. Flip Web preset: vram_texture_compression/for_mobile=true.
    4. godot --headless --export-release "Android" build/android/... (dry, no key =
       fails at sign; that's expected — documents the gate).
  ACCEPT: export_presets.cfg contains [preset.3] Android + [preset.4] iOS;
          `godot --headless --list-exports` shows 5 presets; for_mobile=true on Web.
  NOTE: actual .apk/.ipa SIGNING needs founder keystore/cert — out of scope, flagged.

WS-B  SPRITE WIRING (player/monster/NPC → scenes) — P0 — owner: Mio
  WHY: characters/monsters/NPCs exist as PNG but nothing loads them → blank actors.
  STEPS:
    1. Entity spawner: map game_data monster/npc IDs → res://assets/.../*.png.
       (game_data.gd has monster_index but NO texture key — add "sprite" field.)
    2. player.gd: load player_idle for idle, player_walk for move (see WS-E for walk).
    3. npc.gd: load npc_<id>.png (use 128×128 set: characters/npcs/).
    4. monster.gd: load mon_<id>.png.
  ACCEPT: boot a zone → player + NPCs + monsters render; 0 orphaned character PNGs
          (grep res://assets/characters|monsters|npcs in scenes+scripts returns hits).

WS-C  PORTRAIT / MENU / SHADER WIRING — P1 — owner: Mio
  STEPS:
    1. dialogue.gd: load por_<npc>.png into the dialogue portrait slot.
    2. main_menu.tscn: add TextureRect → assets/ui/main_menu_bg.png (or menu_bg).
    3. Apply assets/shaders/drop_shadow.gdshader to character/monster sprites
       (CanvasItem material) for 2.5D depth.
  ACCEPT: dialogue shows portrait; main menu shows bg; sprites cast drop shadow.

WS-D  AUDIO WIRING — P0 — owner: Shiki (files exist) / Mio (mapping)
  WHY: 43 audio files present, 0 referenced → game is silent.
  STEPS:
    1. audio_config.gd: map zone→music file, event→sfx file against assets/audio/*.
    2. audio_manager.gd: load() the mapped paths (currently AUDIO_DIR is set but
       no file list drives it).
    3. Verify each of the 43 files is referenced or mark for removal.
  ACCEPT: entering a zone plays music; attack/hit/pickup emit sfx; 0 orphaned audio.

WS-E  ANIMATION CORRECTNESS — P1 — owner: Mio
  STEPS:
    1. FIX B1: regenerate player_walk (real walk frames) — do NOT copy idle.
       Verify md5(player_walk) != md5(player_idle).
    2. Add run + attack frames if melee/visibility needs them (plan said 8-dir;
       confirm with founder whether 8-direction is required or 4-dir enough).
  ACCEPT: player has distinct idle/walk; "8-dir ready" claim either TRUE or retired.

WS-F  DE-DUP / CONSOLIDATE — P2 — owner: Mio
  STEPS:
    1. Remove stale dup sets: assets/npcs/*.png (32×48, smaller, unused) OR
       assets/characters/npcs/*.png (128×128) — keep ONE source of truth.
    2. Remove oakrest tileset_oakrest.png (128×128) if unused (tileset.png is the real one).
    3. Consolidate portraits.png (640×128) vs 6 por_*.png — keep por_*, drop combined
       OR vice-versa; don't ship both masters.
  ACCEPT: single NPC sprite source; no duplicate tileset/portrait masters.

WS-G  CROSS-PLATFORM VERIFICATION GATE — owner: Tomoe
  STEPS:
    1. For each platform preset: `godot --headless --export-release <name> <path>`
       (Android/iOS will stop at sign — document; desktop/web must fully export).
    2. Boot each desktop/web build headless; confirm sprites+audio+portraits render.
    3. Re-run test_runner.gd gate; confirm 0 new failures.
  ACCEPT: Web + Linux + Windows export and boot clean; Android/iOS presets present
          and fail only at the (founder-gated) signing step.

══════════════════════════════════════════════════════════════════════
§3. FALSE POSITIVE / NEGATIVE REGISTER (corrected record)
══════════════════════════════════════════════════════════════════════
FALSE POSITIVES (was claimed done — RETIRED):
  FP-1 "Player 8-dir sprite sheets ready" → only idle; walk==idle; no run/attack.
  FP-2 "Art integrated / in game" → only tilesets + 9 item icons wired.
  FP-3 "NPC portraits in dialogue" → exist, never loaded by dialogue.gd.
  FP-4 "Audio in game" → 43 files, 0 referenced, silent.
  FP-5 "Android/iOS ready" → no export presets exist for either.

FALSE NEGATIVES (real but missed — NOW CORRECTED):
  FN-1 Tilesets ARE wired via .tres (prior "all art orphaned" overstated).
  FN-2 menu_bg/main_menu_bg exist and are usable with one TextureRect node.
  FN-3 9 item icons wired via inventory.gd fix — functional.
  FN-4 drop_shadow.gdshader is a real, usable 2.5D depth shader.
  FN-5 Android/iOS ABSENCE is a concrete, named gap (now WS-A).

══════════════════════════════════════════════════════════════════════
§4. EXECUTION ORDER & MILESTONES
══════════════════════════════════════════════════════════════════════
 M0 (now)   : WS-A presets added (unblocks mobile build-config; signing = founder).
 M1         : WS-B + WS-D wiring (game stops being blank + silent).
 M2         : WS-C (portraits/menu/shadow) + WS-E (walk fix).
 M3         : WS-F de-dup.
 M4         : WS-G export + boot gate on all 5 presets.

══════════════════════════════════════════════════════════════════════
§5. DONE DEFINITION
══════════════════════════════════════════════════════════════════════
 - 5 export presets present (Web/Linux/Win/Android/iOS); for_mobile texture on.
 - Player, NPCs, monsters render from wired sprites (no orphaned character PNG).
 - Dialogue shows portraits; main menu shows bg; sprites use drop_shadow.
 - Audio plays (zones + sfx); 0 orphaned audio files.
 - player_walk ≠ player_idle; animation claim is true or retired.
 - No duplicate masters (NPC/tile/portrait).
 - Web + desktop builds export AND boot clean; mobile presets fail only at signing.
══════════════════════════════════════════════════════════════════════
