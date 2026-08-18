# Eclipse Realms Avatar System Plan

## Objective

Give the vertical slice a coherent, production-ready 2D character language: playable avatars that match character creation, readable named NPCs, distinct enemies, and dialogue portraits. Characters stay 2D sprites; restrained 2.5D comes from Y-sorting, shadows, foreground occlusion, particles, and parallax rather than 3D models or skeletal rigs.

## Locked MVP scope

Build curated presets, not a combinatorial character builder. Gender identity and visual presentation are distinct: no player is locked to an appearance, hairstyle, clothing, species, pronouns, or stats because of gender.

| Group | First release content | Motion |
| --- | --- | --- |
| Player | Human, Elf, and Dwarf presets in feminine, masculine, and androgynous presentations; every presentation is selectable by every identity | 4-frame idle and walk |
| Named NPCs | Elder Mira, Blacksmith Dorn, Ranger Silas, Merchant Lira, Innkeeper Bram | Static world pose plus neutral portrait |
| Enemies | Moss Slime, Forest Wolf, Thorn Wisp | Static world pose plus procedural bob/hit feedback |
| Boss | Cave Guardian | Static 96px world pose plus procedural pulse/impact |
| Generic NPCs, pets, companions | Deferred | Deferred |

The creator initially shows **name, avatar preset/species, optional gender identity, and optional pronouns**. Gender choices are Woman, Man, Nonbinary, Genderfluid, Self-describe, and Prefer not to say; the latter choices never block character creation. It must hide face, hair, and body controls until each visibly changes the spawned character. Appearance must not modify combat statistics: those controls are cosmetic and would otherwise become an unfair optimization and a future monetization problem.

For genderfluid players, provide three saved visual looks once the base preset system is stable. A player can label and switch a look outside combat; identity remains their own optional profile field and is never inferred from a look. Start with the same three presentation families for all players, rather than treating nonbinary or genderfluid people as a single androgynous visual trope.

### Presentation and NPC production brief

Every species receives feminine, masculine, and androgynous **presentation** options. These are art-direction families—not gender assignments—and every player can select every one.

| Pack | Shared gameplay silhouette | Presentation distinction | Required exports |
| --- | --- | --- | --- |
| Human Pathfinder | Tunic, travel satchel, wooden sword | Hairstyle, outerwear cut, stance, face/portrait framing | idle + walk 48px sheets, neutral portrait |
| Elf Wanderer | Forest cloak, bow or staff, leaf motif | Same three presentation families with varied hair and proportions | idle + walk 48px sheets, neutral portrait |
| Dwarf Vanguard | Practical layers, tool or shield, sturdy boots | Same three presentation families with varied hair and proportions | idle + walk 48px sheets, neutral portrait |

Named NPCs are fixed people, not generic gender archetypes. Their final visual anchors are:

- **Elder Mira:** silver braided bun, moss-and-burgundy robe, oak-leaf pendant, carved staff; neutral and concerned portraits.
- **Blacksmith Dorn:** leather apron, hammer, soot/metal accents; neutral portrait.
- **Ranger Silas:** weathered green cloak, bow and quiver, forest-worn boots; neutral and serious portraits.
- **Merchant Lira:** travel coat, inventory satchel, lantern and practical layered clothes; neutral and warm portraits.
- **Innkeeper Bram:** welcoming vest/apron, towel or mug; neutral portrait.

The current source PNGs remain runtime placeholders while art is redrawn to the standard; the generated lineup sheets are art-direction references only and must not be cropped into final sprites.

## Art direction and delivery specification

### World art

- Standard player frame: **48 x 48px**, transparent PNG, four cells horizontally per action. Thus each player action sheet is **192 x 48px**.
- Named NPCs: one **48 x 48px** transparent pose for MVP. Use code-driven breathing only after the static presentation is proven.
- Small monsters: 48 x 48px; use 64 x 64px only when the silhouette needs it. Cave Guardian: 96 x 96px.
- Every sprite uses one bottom-centre ground anchor and identical feet baseline; contact shadows are rendered by the game, never baked into art.
- Use nearest-neighbor filtering, readable silhouette at the existing 2x camera zoom, a restrained outline, and one top-left light source. Match Greenhaven’s palette.
- MVP movement mirrors horizontally. Four directional art is a post-slice upgrade, not a prerequisite.

### Portrait art

- Preserve a 256 x 256px layered/source master; export a transparent **96 x 96px** dialogue portrait for the current UI.
- Use head-and-shoulders framing, matching eye line, costume, hair, species traits, and primary colors of the world sprite.
- Each release avatar receives `neutral`; later dialogue-specific variants are `warm`, `concerned`, `angry`, and `hurt`.

### Stable names

Use gameplay IDs in every filename so asset identity cannot drift:

```text
assets/characters/player/pc_human_adept_01_idle.png
assets/characters/player/pc_human_adept_01_walk.png
assets/characters/player/pc_elf_wanderer_01_idle.png
assets/characters/npcs/npc_village_elder_mira_idle.png
assets/characters/monsters/mob_moss_slime_idle.png
assets/characters/monsters/boss_cave_guardian_idle.png
assets/characters/portraits/por_village_elder_mira_neutral.png
assets/characters/portraits/por_pc_human_adept_01_neutral.png
```

Resolve the present Elder Mira / `npc_elder_alric` identity mismatch before creating replacement art.

## Technical contract

Create `client/resources/game_data/avatar_visuals.json` as the single catalog of visual assets. Gameplay data points to a `visual_id`; it does not independently own sprite paths.

```json
{
  "pc_human_adept_01": {
    "kind": "player",
    "world": {
      "idle": "assets/characters/player/pc_human_adept_01_idle.png",
      "walk": "assets/characters/player/pc_human_adept_01_walk.png",
      "frame_size": [48, 48],
      "frames": 4,
      "idle_fps": 4,
      "walk_fps": 8,
      "pivot": [24, 42]
    },
    "portraits": {
      "neutral": "assets/characters/portraits/por_pc_human_adept_01_neutral.png"
    }
  }
}
```

Implement `client/scripts/visual/avatar_sprite_2d.gd` as a reusable `Sprite2D` controller. Keep each scene node named `Sprite`, preserving current combat feedback. The component resolves `visual_id`, loads actions, sets cell counts/pivot/filtering, plays idle/walk or static states, mirrors direction, and exposes a clear missing-asset fallback. It does not own collision, health, dialogue, or combat decisions.

Update records as follows:

- `characters.json`, `npcs.json`, and `monsters.json` receive `visual_id`.
- Player session/save data receives `avatar_id`; save migration defaults existing saves to `pc_human_adept_01`.
- Player session/save data stores optional `gender_identity`, `gender_identity_custom`, `pronouns`, `pronouns_custom`, and a presentation-only `active_look_id`. The server and other players receive these only with an explicit profile-sharing preference.
- Dialogue accepts optional `portrait_expression` and defaults to `neutral`.
- Existing `sprite`, `idle_sprite`, `walk_sprite`, and `portrait` paths remain migration fallbacks until all data and tests pass.
- Normalize NPC data: consume `role` rather than the current incompatible `category`; reconcile `sells`, `shop`, `services`, and quest fields before adding role markers.

## Implementation sequence

1. **Style proof — no broad production yet.** Create only Human Adept, Elder Mira, and Moss Slime to the stated specification. Verify ground anchors, camera legibility, shadows, portrait/world identity, and idle/walk timing in Oakrest.
2. **Foundation.** Add the visual catalog, GameData loading/validation, `AvatarSprite2D`, resource fallback, and scene-level anchors/scales. Migrate the existing player, NPC, and monster loading paths without changing gameplay behavior.
3. **Avatar Pack 01.** Deliver Human, Elf, and Dwarf presets across feminine, masculine, and androgynous presentations; five named NPCs; three small monsters; Cave Guardian; and neutral portraits. Standardize transparent margins and path names. Every player may select every presentation.
4. **Player wiring.** Make creation select `avatar_id`, show its real preview, persist it through new-game/save/load/scene change, and load it in `player.gd`. Persist optional gender identity and pronouns privately by default. Hide inactive customization choices.
5. **NPC and monster wiring.** Resolve each entity through `visual_id`; retain dialogue portrait lookup via the catalog. Repair all zone and respawn paths that currently create `ColorRect` placeholders so they instantiate the normal monster visual component.
6. **Slice polish.** Add only story-relevant expressions (Mira concerned, Silas serious, Lira warm), lightweight code-driven idles, and role/quest/shop markers after their data contract works.
7. **Post-slice expansion.** Add generic villagers, guards, pets/companions, attack/hurt/death sheets, then four-direction art.
8. **Optional modular customization.** Only after the preset pipeline is stable, introduce body/skin/hair/outfit/accessory layers. Each layer must have the same actions, frame count, pivot, and direction layout. Export flattened thumbnail previews for UI and multiplayer; never sell stat effects with cosmetics.

## Files expected to change during execution

- `client/resources/game_data/avatar_visuals.json` (new)
- `client/resources/game_data/characters.json`
- `client/resources/game_data/npcs.json`
- `client/resources/game_data/monsters.json`
- `client/scripts/autoload/game_data.gd`
- `client/scripts/visual/avatar_sprite_2d.gd` (new)
- `client/scripts/player/player.gd`
- `client/scripts/entities/npc.gd`
- `client/scripts/entities/monster.gd`
- `client/scripts/world/monster_spawner.gd`
- `client/scripts/ui/character_creation.gd`
- `client/scripts/ui/dialogue.gd`
- player/NPC/monster-containing world scenes, including Oakrest, Mosswood, Hunter’s Camp, Whispering Caverns, Silver Creek, and Old Watchtower
- `client/assets/characters/player/`, `client/assets/characters/npcs/`, `client/assets/characters/monsters/`, and `client/assets/characters/portraits/`

## Definition of done and verification

- Each visible character in the vertical slice uses the same visual language and has a valid `visual_id`.
- Creator selection visibly matches the spawned player and survives new game, save/load, and zone changes. Gender identity and pronouns are optional, never inferred from presentation, and private by default.
- Woman, man, nonbinary, genderfluid, custom, and undisclosed identities can select every available player presentation; no identity or presentation modifies stats or unlocks different power.
- Genderfluid visual looks can be changed only outside combat, persist correctly, and do not overwrite a player’s optional identity or pronouns.
- Every player sheet has exactly four 48px-wide frames with stable anchors and no animation jitter.
- NPC portrait and world sprite unambiguously depict the same person; Elder Mira’s identity is consistent in ID, data, and filename.
- NPC role-driven behavior resolves from `role`; no shop/quest marker claims are made until its data is working.
- Respawned monsters use proper sprites, never `ColorRect` stand-ins; collision shapes remain independent of transparent bounds.
- Add an asset-catalog validation test that asserts each `visual_id`, path, frame dimension, action, and neutral portrait exists.
- Run the project boot smoke test, direct test runner, comprehensive validation, multiplayer integration, save/load test, and vertical-slice test. Add focused avatar tests for the catalog resolver, creation-to-spawn selection, portrait fallback, and spawner visuals.

## Scope guard

Curated presets are the sellable vertical-slice solution. Layered, fully combinatorial avatars multiply every species, body, hair, outfit, animation, direction, portrait, preview, and network case; they begin only after this catalog-backed preset system has proved stable.

## Character Expansion Plan: Ancestry, Calling, and Details

### Product boundaries

- **Identity and pronouns** are optional private profile data. They never determine visuals, ancestry, job, abilities, items, collision, or stats.
- **Ancestry** is the player-facing name for the internal `species_id`: Human, Elf, and Dwarf. It provides lore and visual traits, not combat advantages, class restrictions, or better starter gear.
- **Calling** is the player-facing name for `job_id`. It is the only character-creation choice that sets starting combat stats, skills, equipment, and growth.
- **Appearance** is cosmetic. Use body-frame labels (`frame_a`, `frame_b`, `frame_c`) rather than gendered body labels; every frame is available to every identity, ancestry, and job.
- **Cosmetics** are visual overrides only. Equipment retains gameplay stats; an outfit/transmog can alter its appearance but never its value, hitbox, speed, targeting, or damage.

### Release sequence

#### Slice A — make the existing creator truthful

1. Ship Human, Elf, and Dwarf ancestry records.
2. Ship three visual body frames per ancestry: slim, average/soft, and broad. Concept briefs may use feminine, masculine, and androgynous presentation families, but the player-facing UI must not assign gender.
3. Ship eight skin tones, six hair colors, four hairstyles plus no-hair, three faces, three eye colors, two markings, and three free starter outfits. Show a choice only when it changes a portrait or world preview.
4. Ship **Adept** as the sole enabled job: balanced melee/support, basic attack, guard, and use item.
5. Produce nine flattened 48px runtime avatars (3 ancestry × 3 body frames) and matching neutral portraits. Persist all detail IDs even if a first-slice world sprite only renders the resolved preset.

#### Slice B — add real combat variety

- **Vanguard:** durable melee, guard/control; enable only with sword-and-shield skills and effects.
- **Ranger:** mobile ranged damage; enable only with bow equipment, projectile/aiming support, and animation.
- **Arcanist:** mana ranged/support; enable only with a level-one spell and cast effect, not the current gated Fire Bolt alone.
- Add job-specific starter kits of equal value, tutorial text, world/portrait outfit variants, and a free early-game respec.

### Canonical player record

```json
{
  "schema_version": 2,
  "name": "Ari",
  "species_id": "elf",
  "job_id": "adept",
  "avatar_id": "pc_elf_frame_b_01",
  "appearance": {
    "body_frame_id": "frame_b",
    "skin_tone_id": "skin_06",
    "face_id": "face_02",
    "eye_color_id": "eye_hazel",
    "hair_style_id": "hair_braided_01",
    "hair_color_id": "hair_black",
    "facial_hair_id": "none",
    "marking_id": "freckles_01",
    "outfit_palette_id": "oakrest_blue"
  },
  "profile": {
    "gender_identity": "Genderfluid",
    "gender_identity_custom": "",
    "pronouns": "They/them",
    "pronouns_custom": "",
    "sharing_enabled": false
  },
  "cosmetic_loadout": {
    "head": "",
    "outfit": "cos_starter_tunic",
    "back": "",
    "weapon_skin": ""
  }
}
```

Keep compatibility reads temporarily: `species` → `species_id`; `class`, `class_id`, `job`, and `archetype` → `job_id`; old `body`, `face`, and `hair` → `appearance`; old visual aliases → `avatar_id`. Missing job defaults to Adept, missing ancestry defaults to Human, and missing identity defaults to Prefer not to say. Legacy `male`/`female` data must never be converted into an identity.

### Data catalogs

Add `species.json` with display/lore data, default avatar, supported body frames, appearance tags, and enabled status. Do not store stats, gender rules, job rules, or superior items there.

Add `jobs.json` with role, job starting stats, starting skill IDs, starter item IDs, starter equipment, unlocks, animation profile, and enabled status. Adept is the first entry and owns the current generic melee kit.

Add `appearance_options.json` with stable IDs, localized labels, compatibility tags, preview references, and color palette data for frames, tones, faces, hair, eyes, markings, and starter outfits.

Add `cosmetics.json` for entitlement-managed visual records only. `avatar_visuals.json` remains the resolved runtime package: animation sheets, pivot/frame metadata, portrait expressions, and fallback IDs.

Use `items.json` as the single gameplay item source. Migrate duplicate equipment definitions into it, leave a compatibility loader for `equipment.json`, then retire the duplicate catalog.

### Creator flow

1. **Basics:** name, optional identity/pronouns, private-by-default explanation.
2. **Ancestry:** Human, Elf, Dwarf with lore and visual preview—not stat advantage.
3. **Appearance:** frame, tone, face, eyes, hair, facial hair, markings, colors, and outfit. Include zoom, rotate, randomize, undo randomize, reset, and a hide-starter-gear preview toggle.
4. **Calling:** job role, starting skills, equipment, difficulty, and honest combat preview. The panel says “job starting stats.”
5. **Review:** portrait, world sprite, ancestry, job, privacy setting, and confirmation.

### Art path

Ship flattened 48×48 world sheets first. Preserve source art as synchronized layers: shadow → body → ancestry features → face/eyes → hair back → outfit → equipment → hair front/headwear → accessory/effect. Every layer shares the same pivot and action layout. The future target has four directional rows (down/left/right/up) for idle, walk, attack/cast, hit, and death; portraits use 512px masters and 256px exports. Use the assembler in previews first, then replace runtime flattened sheets only after synchronization and multiplayer performance pass.

### Privacy and multiplayer

Public packets may contain peer ID, display name, movement/action, validated `avatar_id`, sanitized cosmetic IDs, and job animation profile. They must never include gender identity, pronouns, custom profile text, or the whole save payload by default. The server validates allowed ancestry/job/avatar/cosmetic IDs, entitlement ownership, item/job-derived stats, and bounded sanitized custom strings; it rejects client paths and client-authored combat stats.

### Implementation order and files

1. Add catalogs and validators: `client/resources/game_data/species.json`, `jobs.json`, `appearance_options.json`, `cosmetics.json`; extend `client/scripts/autoload/game_data.gd`.
2. Add a schema-v2 migration module and update `client/scripts/autoload/save_manager.gd` plus `client/scripts/player/player.gd` to preserve real ancestry/job/appearance/profile/cosmetics.
3. Replace hard-coded creator species stats and starter inventory in `client/scripts/ui/character_creation.gd` with job data; redesign `client/scenes/ui/character_creation.tscn` as the five-step flow.
4. Extend `client/resources/game_data/avatar_visuals.json`; use `client/scripts/visual/` for recipe resolution and safe visual fallbacks.
5. Consolidate item/equipment contracts in `client/resources/game_data/items.json`, `equipment.json`, `client/scripts/ui/inventory.gd`, and `client/scripts/ui/equipment.gd`.
6. Add protected public-avatar payloads to `client/scripts/autoload/network_manager.gd`; mirror validation and private-profile storage in `server/server.py` and production database migrations.

### Acceptance gates

- Every enabled ancestry × body frame × job combination resolves a valid visual or explicit fallback.
- Identity/pronoun changes do not change stats, items, skills, ancestry availability, job availability, animation, or rendering.
- Ancestry/appearance do not modify job starting stats; starter-kit values are equivalent by a documented budget.
- Save/load round-trips schema-v2 records and migrates legacy saves without overwriting identity.
- Unknown IDs fall back safely and report diagnostics; no raw asset path can arrive from the client.
- Cosmetics never alter stats; equipment remains correct when its visual is hidden or overridden.
- Public packets omit private profile fields by default; server rejects unknown IDs, unauthorized cosmetics, and client-authored stats.
- Creator is usable with keyboard/controller, color-independent states, readable labels, and preview alternatives.
