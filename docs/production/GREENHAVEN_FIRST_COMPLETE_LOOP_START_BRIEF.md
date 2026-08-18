---
title: Greenhaven First Complete Loop — Start Brief
description: Implementation-ready scope, sequence, and acceptance gates for the next work package.
tags: [phase-2, greenhaven, gameplay, avatars, testing]
---

# Greenhaven First Complete Loop — Start Brief

**Status:** automated implementation complete; manual authored-world acceptance pending  
**Authority:** [Current release ledger](./RELEASE_LEDGER_2026-08-17.md) and [release readiness master plan](./RELEASE_READINESS_MASTER_PLAN.md)  
**Visual contract:** [Avatar System Plan](../../AVATAR_SYSTEM_PLAN.md)

## Objective

Deliver one locally playable Greenhaven chapter in which a new player can create a character, reach a deliberate ending, save and reload safely throughout, and see truthful catalog-backed presentation for the player, Elder Mira, and Moss Slime.

## Fixed scope

| In scope | Explicitly out of scope |
| --- | --- |
| One start-to-ending chapter path | New jobs or a job-selection expansion |
| Existing local save path and schema migration | Public networking, server redesign, accounts, or commerce |
| One quest sequence using existing catalog data | New zones unless the current path cannot be completed without one |
| Equipment, loot, respawn, retry, and reward reliability | Layered/combinatorial avatar customization |
| Human Adept + Elder Mira + Moss Slime visual proof | More avatar presets before the visual proof passes |
| Creator, world, and dialogue presentation consistency | Web/mobile release work or store publishing |

## Start conditions

Before feature changes, record a clean baseline with:

```bash
godot --headless --path client -s res://tests/test_vertical_slice.gd
godot --headless --path client -s res://tests/test_save_load.gd
godot --headless --path client -s res://tests/test_release_catalogs.gd
```

Treat the existing headless resource-cleanup warnings as tracked quality debt. Do not hide them or mark an unrelated feature failed solely because they continue; investigate them in a dedicated cleanup task.

## Implementation sequence

### 1. Chapter contract and failing end-to-end test

- Inspect the existing quest, NPC, monster, item, equipment, and world catalogs.
- Select one complete sequence using only entries that have working scenes, interactions, and assets.
- Define checkpoints, success conditions, failure/retry behavior, reward ownership, and the final completion state.
- Add `client/tests/test_greenhaven_loop.gd` first. It must cover creation, tutorial acceptance, one combat/reward action, equipment/inventory effect, return/turn-in, checkpoint save, reload, and final completion.

**Exit:** the test describes the intended player journey even while it initially fails.

### 2. Chapter systems

- Repair only the concrete quest transitions, interaction points, monster lifecycle, drops, equipment-stat recalculation, inventory bounds, scene transitions, audio transitions, and retry behavior required by the selected route.
- Keep one derived-stat authority. Clamp current health/mana when equipment changes.
- Keep all rewards idempotent across retry, reload, and repeated interaction.
- Add focused regression tests whenever a system change fixes a chapter blocker.

**Exit:** the full loop passes once from a fresh save and once after a checkpoint reload.

### 3. Visual proof in parallel

- Add the reusable visual resolver/controller specified by the avatar contract.
- Wire the current `visual_id` catalog into the player, Elder Mira, and Moss Slime without changing collision, combat, or quest ownership.
- Add truthful creator preview and dialogue portrait fallback behavior.
- Do not enable any visual choice that does not produce a real preview, world result, and portrait/fallback.

**Exit:** the three proof entities are visually consistent through creation, scene transition, save/load, and dialogue.

### 4. Gate and handoff

- Run the three baseline suites plus the new full-loop suite.
- Perform ten consecutive internal runs, alternating fresh-start and checkpoint-reload routes.
- Record every blocker with reproduction steps; do not add content to compensate for a broken core loop.
- Update the current ledger only with test-backed status.

**Exit:** no progression, duplication, or data-loss blocker remains in the selected chapter.

## File boundaries

| Concern | Primary locations |
| --- | --- |
| Chapter data and objective selection | `client/resources/game_data/{quests,npcs,monsters,items,equipment,world}.json` |
| Local gameplay flow | `client/scripts/world/`, `client/scripts/entities/`, `client/scripts/player/player.gd` |
| Quest, inventory, equipment, dialogue, HUD | `client/scripts/ui/` and their scenes |
| Saves and profile migration | `client/scripts/autoload/save_manager.gd`, `client/scripts/character/` |
| Visual proof | `client/resources/game_data/avatar_visuals.json`, new `client/scripts/visual/`, player/NPC/monster scenes |
| Regression coverage | `client/tests/test_greenhaven_loop.gd` plus focused existing tests |

## Definition of ready to continue

Begin coding when the first quest path has been selected from existing live data and the failing `test_greenhaven_loop.gd` names its exact checkpoints. No new content, art, or network work is authorized until that path is explicit.
