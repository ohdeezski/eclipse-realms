# Phase 2 Avatar Visual Resolver & Planning

## Current Status
- Completed: Test-first Greenhaven loop implementation  
- Next Focus: Avatar visual system (Human Adept, Elder Mira, Moss Slime)

## Visual Resolver Implementation
- Created: `/client/scripts/visual_resolver.gd`
- Features:
  1. Asset mapping by race/gender/class
  2. Fallback to human default if race-specific asset missing
  3. Preload assets for performance optimization
  4. Support for future jobs/classes without restructuring

## Asset Structure
- Base directory: `/client/assets/`
- Format pattern: `{race}_{gender}_{class}.[type].png`
- Types: portrait, world, dialogue, preview, sprite, combat

## Placeholder Assets Created
- Elder Mira: `elder_mira.png`, `elder_mira_world.png`, `elder_mira_dialogue.png`, `elder_mira_preview.png`
- Moss Slime: `moss_slime_body.png`, `moss_slime_world.png`, `moss_slime_combat.png`

## Test Updates
- Modified: `/client/tests/test_greenhaven_loop.gd`
- Added: Avatar preview/dialogue sync verification
- Next Steps:
  1. Integrate visual resolver into player.gd and npc.gd
  2. Create actual sprite assets for Elder Mira and Moss Slime
  3. Run automated tests to verify avatar display in preview/dialogue

## Remaining Work
1. Finalize sprites for baseline avatars
2. Sync avatar visuals across systems (creator, world, dialogue)
3. Add support for additional races/classes in resolver
4. Ensure deterministic save-reload for character visuals
