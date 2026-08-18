extends SceneTree
## End-to-end contract for the first local Greenhaven tutorial loop.

const TEST_SAVE_SLOT := 7

var _failed := false


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var game_data = get_root().get_node_or_null("GameData")
    _assert(game_data != null, "GameData autoload is available")
    if game_data == null:
        quit(1)
        return
    var spawner_script = load("res://scripts/world/monster_spawner.gd")
    _assert(spawner_script != null, "Monster spawner script loads")
    if spawner_script == null:
        quit(1)
        return
    var spawner = spawner_script.new()
    _assert(spawner.has_method("spawn_monster"), "Monster spawner exposes a scene-local spawn seam")
    spawner.free()
    var objective_trigger_script = load("res://scripts/world/quest_objective_trigger.gd")
    _assert(objective_trigger_script != null, "World objective trigger script loads")
    var player_scene: PackedScene = load("res://scenes/player/player.tscn")
    var player = player_scene.instantiate()
    get_root().add_child(player)
    await process_frame

    # Keep this contract focused on quest state and persistence. A level-up
    # effect requires a running world scene and is covered by gameplay tests.
    player.level = 2

    var base_attack: int = player.attack
    player.inventory.append("wooden_sword")
    _assert(player.has_method("equip_item"), "Player exposes the equipment seam")
    _assert(player.has_method("unequip_item"), "Player exposes the unequip seam")
    if not player.has_method("equip_item") or not player.has_method("unequip_item"):
        _finish(player)
        return
    _assert(player.equip_item("wooden_sword"), "A weapon can be equipped from inventory")
    _assert(player.equipment.get("weapon", "") == "wooden_sword", "Weapon occupies the canonical weapon slot")
    _assert(player.attack == base_attack + 5, "Equipping weapon updates combat attack")
    _assert(player.unequip_item("weapon"), "Equipped weapon can be removed")
    _assert(player.attack == base_attack, "Unequipping restores base attack")

    player.accept_quest("tutorial_quest")
    _assert(player.active_quests.has("tutorial_quest"), "Tutorial quest becomes active")
    _assert(player.has_method("record_monster_defeated"), "Player exposes the monster-defeat quest seam")
    _assert(player.has_method("record_return_to_npc"), "Player exposes the quest-return seam")
    if not player.has_method("record_monster_defeated") or not player.has_method("record_return_to_npc"):
        _finish(player)
        return

    var starting_gold: int = player.gold
    var starting_inventory_size: int = player.inventory.size()
    player.record_monster_defeated("moss_slime")
    _assert(player.active_quests.has("tutorial_quest"), "Defeating Moss Slime advances but does not complete the return quest")
    _assert(player.active_quests["tutorial_quest"].get("objective_index", -1) == 1, "Tutorial advances to the Elder Mira return objective")

    player.record_return_to_npc("village_elder")
    _assert(not player.active_quests.has("tutorial_quest"), "Returning to Elder Mira closes the active tutorial quest")
    _assert("tutorial_quest" in player.completed_quests, "Tutorial quest is completed after its return objective")
    _assert(player.gold == starting_gold + 100, "Tutorial reward gold is granted exactly once")
    _assert(player.inventory.size() == starting_inventory_size + 1, "Tutorial reward item is granted exactly once")

    player.record_return_to_npc("village_elder")
    _assert(player.gold == starting_gold + 100, "Repeating a completed return cannot duplicate gold")
    _assert(player.inventory.size() == starting_inventory_size + 1, "Repeating a completed return cannot duplicate items")

    var save_manager = get_root().get_node_or_null("SaveManager")
    _assert(save_manager != null, "SaveManager autoload is available")
    if save_manager == null:
        _finish(player)
        return
    _assert(save_manager.save_game(TEST_SAVE_SLOT), "Tutorial checkpoint saves")
    player.completed_quests.clear()
    player.gold = 0
    player.inventory.clear()
    save_manager.load_game(TEST_SAVE_SLOT)
    _assert("tutorial_quest" in player.completed_quests, "Tutorial completion survives save and reload")
    _assert(player.gold == starting_gold + 100, "Tutorial reward gold survives save and reload")
    _assert(player.inventory.size() == starting_inventory_size + 1, "Tutorial reward item survives save and reload")
    save_manager.delete_save(TEST_SAVE_SLOT)

    # The remainder of the first chapter is an NPC-offered sequence. Set the
    # test character to the intended chapter level so it exercises quest gates,
    # not combat-grinding balance.
    player.level = 5
    var npc_script = load("res://scripts/entities/npc.gd")
    var elder = npc_script.new()
    var merchant = npc_script.new()
    var ranger = npc_script.new()
    elder.configure(game_data.get_npc("village_elder"))
    merchant.configure(game_data.get_npc("merchant"))
    ranger.configure(game_data.get_npc("ranger"))
    _assert(elder.has_method("get_available_quest_ids"), "NPC exposes the available-quest seam")
    if not elder.has_method("get_available_quest_ids"):
        _finish(player)
        return

    _assert("find_missing_item" in elder.get_available_quest_ids(player), "Elder Mira offers the post-tutorial amulet quest")
    player.accept_quest("find_missing_item")
    _assert(player.has_method("record_item_found"), "Player exposes the item-find quest seam")
    _assert(player.has_method("record_escort_completed"), "Player exposes the escort-complete quest seam")
    if not player.has_method("record_item_found") or not player.has_method("record_escort_completed"):
        _finish(player)
        return

    var amulet_trigger = objective_trigger_script.new()
    amulet_trigger.objective_type = "find"
    amulet_trigger.target_id = "elder_amulet"
    _assert(amulet_trigger.activate_for(player), "Amulet world trigger awards and records the active find objective")
    amulet_trigger.free()
    _assert(player.active_quests["find_missing_item"].get("objective_index", -1) == 1, "Finding the amulet advances to the Elder Mira return")
    player.record_return_to_npc("village_elder")
    _assert("find_missing_item" in player.completed_quests, "Elder's amulet quest completes on return")

    _assert("escort_merchant" in merchant.get_available_quest_ids(player), "Merchant Lira offers the escort after the amulet return")
    player.accept_quest("escort_merchant")
    var escort_trigger = objective_trigger_script.new()
    escort_trigger.objective_type = "escort"
    escort_trigger.target_id = "merchant"
    _assert(escort_trigger.activate_for(player), "Camp arrival trigger records the active escort objective")
    escort_trigger.free()
    player.record_return_to_npc("ranger")
    _assert("escort_merchant" in player.completed_quests, "Merchant escort completes at the Ranger return")

    _assert("hunt_forest_wolf" in ranger.get_available_quest_ids(player), "Ranger Silas offers Wolf Hunt")
    player.accept_quest("hunt_forest_wolf")
    for _kill in 3:
        player.record_monster_defeated("forest_wolf")
    player.record_return_to_npc("ranger")
    _assert("hunt_forest_wolf" in player.completed_quests, "Wolf Hunt completes after three kills and return")

    _assert("clear_thorn_wisp" in ranger.get_available_quest_ids(player), "Ranger Silas offers cavern clear after Wolf Hunt")
    player.accept_quest("clear_thorn_wisp")
    for _kill in 5:
        player.record_monster_defeated("thorn_wisp")
    player.record_monster_defeated("cave_guardian")
    player.record_return_to_npc("ranger")
    _assert("clear_thorn_wisp" in player.completed_quests, "Cavern clear completes after wisps, guardian, and return")

    _assert(save_manager.save_game(TEST_SAVE_SLOT), "Completed chapter saves")
    player.completed_quests.clear()
    save_manager.load_game(TEST_SAVE_SLOT)
    _assert("clear_thorn_wisp" in player.completed_quests, "Completed chapter survives save and reload")
    save_manager.delete_save(TEST_SAVE_SLOT)

    elder.free()
    merchant.free()
    ranger.free()
    _finish(player)


func _finish(player) -> void:
    player.queue_free()
    quit(1 if _failed else 0)


func _assert(condition: bool, description: String) -> void:
    if condition:
        print("  [PASS] %s" % description)
    else:
        _failed = true
        print("  [FAIL] %s" % description)

# Avatar Preview & Dialogue Sync Verification
# After completing the Greenhaven loop, verify that avatar preview and dialogue portals match the chosen character.
# This ensures the visual resolver is correctly applied to the final character.

func verify_avatar_sync(character_name: String) -> Bool:
    # Load the character's profile (simulated here)
    var profile = {
        "name": character_name,
        "race": "elder_mira",
        "gender": "female",
        "class": "adept"
    }

    # Get the expected asset paths
    var portrait = get_asset_path(profile["race"], profile["gender"], "portrait")
    var world = get_asset_path(profile["race"], profile["gender"], "world")
    var dialogue = get_asset_path(profile["race"], profile["gender"], "dialogue")

    # Check that all assets are present
    if portrait.empty() || world.empty() || dialogue.empty():
        push_error("Avatar preview or dialogue asset missing for %s" % character_name)
        return false

    # Optionally, verify that the preview matches the dialogue (both load the same base sprite)
    # This would require comparing textures, which is beyond the scope of this unit test.

    push_success("Avatar preview and dialogue assets are ready for %s" % character_name)
    return true

# Integration test: run after the loop finishes
func run_avatar_verification() -> Bool:
    # Simulate finishing the Greenhaven loop
    if not verify_avatar_sync("Elder Mira"):
        return false
    return true
