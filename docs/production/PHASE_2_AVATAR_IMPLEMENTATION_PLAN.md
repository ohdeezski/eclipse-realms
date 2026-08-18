# Phase 2 Avatar Implementation Roadmap

**Status:** Ready to start.
**Objective:** Complete avatar customization for races (ancestry), genders, and jobs (calling) by executing a sequential roadmap.

## Roadmap Order

To ensure system stability, I have prioritized the four requested work areas into a validated development sequence:

1.  **Work Package 3: Prototype Style-Proof (Elder Mira, Moss Slime, Human Adept)**
    *   Verify the catalog-driven system and `AvatarSprite2D` visual resolver in a real-world scenario.
    *   Ensure preview, world, dialogue, and save/load agree before scaling.
2.  **Work Package 4: Resolver Expansion (Class/Job Variations)**
    *   Extend `visual_resolver.gd` to handle job-based animation profiles and cosmetic variations.
    *   Ensure the resolver remains clean and catalog-driven.
3.  **Work Package 1: Asset Implementation**
    *   Produce final sprite sheets (Idle/Walk) for the expanded resolver.
    *   Standardize paths and naming as per `AVATAR_SYSTEM_PLAN.md`.
4.  **Work Package 2: System Integration**
    *   Wire the refactored `Player.gd` and `NPC.gd` to the fully expanded resolver.
    *   Final automated testing using `test_visual_resolver.py` and the updated `test_greenhaven_loop.gd`.

## Work Packages

### WP3: Prototype Style-Proof
- **Goal:** Author and verify Human Adept, Elder Mira, and Moss Slime.
- **Verification:** Loop test (save/reload/load) + direct inspection of world vs. portrait.

### WP4: Resolver Expansion
- **Goal:** Enhance `visual_resolver.gd` logic.
- **Logic:** Add mapping for `job_id` -> animation profile; `species_id` -> base assets.
- **Verification:** Unit tests for resolver path resolution.

### WP1: Asset Implementation
- **Goal:** Deliver standardized PNG sheets.
- **Spec:** 48x48 world; 96x96 portrait; 4-frame walk cycle.
- **Verification:** `test_visual_resolver.py` asset-existence check.

### WP2: System Integration
- **Goal:** Full wiring in `Player.gd` / `NPC.gd`.
- **Verification:** Full Greenhaven chapter loop test.

## Verification Gates
1. **Style Proof:** No broken portraits or world sprites in Oakrest.
2. **Resolver Logic:** Correct resolution for all test cases in `test_visual_resolver.py`.
3. **Asset Integrity:** All paths verified by the asset scanner.
4. **Integration:** Full Greenhaven playthrough with no visual regressions or script errors.

---
*Next Action: Begin Work Package 3 (Prototype Style-Proof).*
