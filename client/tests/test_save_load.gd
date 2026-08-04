extends SceneTree
## test_save_load.gd - Save/Load Roundtrip Verification
## Run from the Godot editor: godot --headless -s tests/test_save_load.gd
## Verifies SaveManager correctly serializes and deserializes player data,
## inventory, quests, equipment, and session state.

var _pass: int = 0
var _fail: int = 0


func _init() -> void:
    print("\n========== Eclipse Realms - Save/Load Test Suite ==========\n")
    _test_save_slot_basics()
    _test_collect_and_apply_game_data()
    _test_player_serialization()
    _test_save_roundtrip()
    _test_config_save_load()
    _test_slot_management()
    _test_edge_cases()
    print("\n========== Results: %d passed, %d failed ==========\n" % [_pass, _fail])
    if _fail > 0:
        print("TESTS FAILED")
    else:
        print("ALL TESTS PASSED")
    quit(_fail)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _assert(condition: bool, description: String) -> void:
    if condition:
        _pass += 1
        print("  [PASS] %s" % description)
    else:
        _fail += 1
        print("  [FAIL] %s" % description)


func _assert_eq(actual, expected, description: String) -> void:
    if actual == expected:
        _pass += 1
        print("  [PASS] %s" % description)
    else:
        _fail += 1
        print("  [FAIL] %s — expected %s, got %s" % [description, str(expected), str(actual)])


# ---------------------------------------------------------------------------
# Test: Save slot basics
# ---------------------------------------------------------------------------

func _test_save_slot_basics() -> void:
    print("\n--- Test: Save Slot Basics ---")

    _assert_eq(SaveManager.MAX_SAVES, 10, "MAX_SAVES is 10")
    _assert_eq(SaveManager.SAVE_EXTENSION, ".eclipse", "SAVE_EXTENSION is .eclipse")
    _assert(SaveManager.get_save_path(0).ends_with("save_00.eclipse"), "Save path for slot 0 has correct format")
    _assert(SaveManager.get_save_path(9).ends_with("save_09.eclipse"), "Save path for slot 9 has correct format")

    # Invalid slots
    _assert_eq(SaveManager.get_save_info(-1), {}, "Invalid slot -1 returns empty dict")
    _assert_eq(SaveManager.get_save_info(10), {}, "Invalid slot 10 returns empty dict")


# ---------------------------------------------------------------------------
# Test: _collect_game_data and _apply_loaded_data
# ---------------------------------------------------------------------------

func _test_collect_and_apply_game_data() -> void:
    print("\n--- Test: Collect & Apply Game Data ---")

    # Collect data without a Player node in tree (fallback path)
    var data = SaveManager._collect_game_data()
    _assert(data.has("player"), "Collected data has 'player' key")
    _assert(data.has("inventory"), "Collected data has 'inventory' key")
    _assert(data.has("quests"), "Collected data has 'quests' key")
    _assert(data.has("world"), "Collected data has 'world' key")
    _assert(data.has("equipment"), "Collected data has 'equipment' key")
    _assert(data.has("session"), "Collected data has 'session' key")

    # Player defaults when no player exists
    _assert_eq(data["player"]["level"], 1, "Default player level is 1")
    _assert_eq(data["inventory"]["items"], [], "Default inventory items is empty array")
    _assert_eq(data["inventory"]["gold"], 0, "Default gold is 0")
    _assert(data["quests"]["active"] is Dictionary, "Default active quests is a Dictionary")
    _assert_eq(data["quests"]["completed"], [], "Default completed quests is empty array")

    # Apply to pending stores
    SaveManager._apply_loaded_data(data)
    _assert(SaveManager.has_pending_data(), "has_pending_data() returns true after apply with no player")
    SaveManager.consume_pending_player_data()
    SaveManager.consume_pending_inventory_data()
    SaveManager.consume_pending_quest_data()
    SaveManager.consume_pending_equipment_data()
    SaveManager.consume_pending_world_data()
    _assert(not SaveManager.has_pending_data(), "has_pending_data() returns false after consume")


# ---------------------------------------------------------------------------
# Test: Player serialization
# ---------------------------------------------------------------------------

func _test_player_serialization() -> void:
    print("\n--- Test: Player Serialization ---")

    # Create a mock player-like Dictionary to test roundtrip
    var mock_player_data = {
        "level": 5,
        "experience": 123,
        "position_x": 320.0,
        "position_y": 480.0,
        "stats": {
            "health": 80,
            "max_health": 150,
            "mana": 30,
            "max_mana": 75,
            "attack": 25,
            "defense": 12
        }
    }

    var mock_inventory = {
        "items": ["wooden_sword", "health_potion", "health_potion"],
        "gold": 500
    }

    var mock_quests = {
        "active": {"tutorial_quest": {"current": 2}},
        "completed": ["find_missing_item"]
    }

    var mock_equipment = {
        "main_hand": "wooden_sword",
        "chest": "leather_armor"
    }

    # Verify the data structure is valid
    _assert_eq(mock_player_data["level"], 5, "Mock player level is 5")
    _assert_eq(mock_player_data["stats"]["health"], 80, "Mock health is 80")
    _assert_eq(mock_inventory["items"].size(), 3, "Mock inventory has 3 items")
    _assert_eq(mock_inventory["gold"], 500, "Mock gold is 500")
    _assert(mock_quests["active"].has("tutorial_quest"), "Mock active quests has tutorial_quest")
    _assert_eq(mock_quests["completed"].size(), 1, "Mock completed quests has 1 entry")
    _assert(mock_equipment.has("main_hand"), "Mock equipment has main_hand")

    # Test that pending data round-trips through consume
    SaveManager._pending_player_data = mock_player_data.duplicate(true)
    SaveManager._pending_inventory_data = mock_inventory.duplicate(true)
    SaveManager._pending_quest_data = mock_quests.duplicate(true)
    SaveManager._pending_equipment_data = mock_equipment.duplicate(true)

    var got_player = SaveManager.consume_pending_player_data()
    _assert_eq(got_player["level"], 5, "Consumed player level is 5")
    _assert_eq(got_player["stats"]["attack"], 25, "Consumed player attack is 25")

    var got_inv = SaveManager.consume_pending_inventory_data()
    _assert_eq(got_inv["gold"], 500, "Consumed inventory gold is 500")
    _assert_eq(got_inv["items"][0], "wooden_sword", "First item is wooden_sword")

    var got_quests = SaveManager.consume_pending_quest_data()
    _assert(got_quests["active"].has("tutorial_quest"), "Consumed active quests has tutorial_quest")
    _assert_eq(got_quests["completed"][0], "find_missing_item", "Consumed completed quest is find_missing_item")

    var got_equip = SaveManager.consume_pending_equipment_data()
    _assert_eq(got_equip["main_hand"], "wooden_sword", "Consumed main_hand is wooden_sword")

    # Cleanup
    SaveManager.consume_pending_world_data()


# ---------------------------------------------------------------------------
# Test: Full save/load roundtrip with explicit data
# ---------------------------------------------------------------------------

func _test_save_roundtrip() -> void:
    print("\n--- Test: Save/Load Roundtrip ---")

    var test_slot = 9  # Use last slot to avoid overwriting real saves
    # Clean up first
    SaveManager.delete_save(test_slot)

    # Build a known save payload
    var payload = {
        "player": {
            "name": "TestHero",
            "level": 7,
            "experience": 321,
            "position_x": 100.0,
            "position_y": 200.0,
            "stats": {
                "health": 75,
                "max_health": 200,
                "mana": 40,
                "max_mana": 100,
                "attack": 30,
                "defense": 15
            }
        },
        "inventory": {
            "items": ["iron_sword", "health_potion", "health_potion", "mana_potion"],
            "gold": 1250
        },
        "quests": {
            "active": {"hunt_forest_wolf": {"current": 1}},
            "completed": ["tutorial_quest", "find_missing_item"]
        },
        "equipment": {
            "main_hand": "iron_sword",
            "chest": "leather_armor"
        },
        "world": {
            "current_scene": "res://scenes/world/oakrest_village.tscn",
            "previous_scene": ""
        },
        "session": {
            "playtime_seconds": 600.0,
            "enemies_defeated": 15,
            "items_collected": 8,
            "quests_completed": 2,
            "deaths": 1
        }
    }

    # Save
    var save_ok = SaveManager.save_game(test_slot, payload)
    _assert(save_ok, "save_game returns true for valid slot 9")
    _assert(FileAccess.file_exists(SaveManager.get_save_path(test_slot)), "Save file exists on disk")

    # Verify the file is valid JSON
    var file = FileAccess.open(SaveManager.get_save_path(test_slot), FileAccess.READ)
    var content = file.get_as_text()
    file.close()
    var json = JSON.new()
    var parse_ok = json.parse(content)
    _assert(parse_ok == OK, "Save file parses as valid JSON")
    _assert(json.data.has("metadata"), "Save data has metadata")
    _assert(json.data.has("player"), "Save data has player section")
    _assert_eq(json.data["player"]["level"], 7, "Saved player level is 7")
    _assert_eq(json.data["player"]["stats"]["max_health"], 200, "Saved max_health is 200")
    _assert_eq(json.data["inventory"]["gold"], 1250, "Saved gold is 1250")
    _assert_eq(json.data["inventory"]["items"].size(), 4, "Saved inventory has 4 items")
    _assert(json.data["quests"]["active"].has("hunt_forest_wolf"), "Saved active quest has hunt_forest_wolf")
    _assert_eq(json.data["quests"]["completed"].size(), 2, "Saved 2 completed quests")
    _assert_eq(json.data["equipment"]["main_hand"], "iron_sword", "Saved equipment main_hand is iron_sword")
    _assert_eq(json.data["session"]["enemies_defeated"], 15, "Saved session enemies_defeated is 15")

    # Metadata check
    var meta = json.data["metadata"]
    _assert(meta.has("timestamp"), "Metadata has timestamp")
    _assert_eq(meta["slot"], 9, "Metadata slot is 9")
    _assert_eq(meta["version"], GameManager.VERSION, "Metadata version matches GameManager.VERSION")

    # Load back
    SaveManager.is_saving = false
    SaveManager.is_loading = false
    var loaded = SaveManager.load_game(test_slot)
    _assert(not loaded.is_empty(), "load_game returns non-empty data")
    _assert_eq(loaded["player"]["level"], 7, "Loaded player level is 7")
    _assert_eq(loaded["player"]["stats"]["attack"], 30, "Loaded attack is 30")
    _assert_eq(loaded["inventory"]["gold"], 1250, "Loaded gold is 1250")
    _assert_eq(loaded["inventory"]["items"][0], "iron_sword", "Loaded first item is iron_sword")
    _assert_eq(loaded["quests"]["active"]["hunt_forest_wolf"]["current"], 1, "Loaded quest progress is 1")
    _assert_eq(loaded["quests"]["completed"][1], "find_missing_item", "Loaded second completed quest")
    _assert_eq(loaded["equipment"]["chest"], "leather_armor", "Loaded equipment chest is leather_armor")
    _assert_eq(loaded["session"]["playtime_seconds"], 600.0, "Loaded session playtime is 600")
    _assert_eq(loaded["metadata"]["slot"], 9, "Loaded metadata slot is 9")

    # Cleanup
    SaveManager.delete_save(test_slot)
    SaveManager.is_saving = false
    SaveManager.is_loading = false


# ---------------------------------------------------------------------------
# Test: Config save/load
# ---------------------------------------------------------------------------

func _test_config_save_load() -> void:
    print("\n--- Test: Config Save/Load ---")

    # Save current config
    var original_difficulty = GameManager.config.get("difficulty", "normal")
    GameManager.config["difficulty"] = "test_hard"
    var config_ok = SaveManager.save_config()
    _assert(config_ok, "save_config returns true")

    # Modify config
    GameManager.config["difficulty"] = "test_easy"

    # Load config back
    var loaded_config = SaveManager.load_config()
    _assert_eq(loaded_config.get("difficulty", ""), "test_hard", "Loaded config difficulty is test_hard")

    # Restore original
    GameManager.config["difficulty"] = original_difficulty
    SaveManager.save_config()


# ---------------------------------------------------------------------------
# Test: Slot management
# ---------------------------------------------------------------------------

func _test_slot_management() -> void:
    print("\n--- Test: Slot Management ---")

    var test_slot = 8
    _assert(not SaveManager.has_save(test_slot), "Slot 8 has no save before creation")

    # Create a save
    SaveManager.save_game(test_slot, {"player": {"level": 1}, "inventory": {}, "quests": {}, "equipment": {}, "world": {}, "session": GameManager.session_data})
    _assert(SaveManager.has_save(test_slot), "Slot 8 has save after creation")

    # Check get_save_info
    var info = SaveManager.get_save_info(test_slot)
    _assert(info.get("exists", false), "get_save_info exists is true")
    _assert(info.get("timestamp", 0) > 0, "get_save_info timestamp > 0")

    # get_save_slots returns correct size
    var slots = SaveManager.get_save_slots()
    _assert_eq(slots.size(), 10, "get_save_slots returns 10 slots")

    # get_latest_save
    var latest = SaveManager.get_latest_save()
    _assert_eq(latest, test_slot, "get_latest_save returns slot 8")

    # Delete
    var del_ok = SaveManager.delete_save(test_slot)
    _assert(del_ok, "delete_save returns true")
    _assert(not SaveManager.has_save(test_slot), "Slot 8 has no save after deletion")


# ---------------------------------------------------------------------------
# Test: Edge cases
# ---------------------------------------------------------------------------

func _test_edge_cases() -> void:
    print("\n--- Test: Edge Cases ---")

    # Invalid slot saves
    _assert(not SaveManager.save_game(-1), "save_game with slot -1 returns false")
    _assert(not SaveManager.save_game(99), "save_game with slot 99 returns false")

    # Invalid slot loads
    _assert(SaveManager.load_game(-1).is_empty(), "load_game with slot -1 returns empty")
    _assert(SaveManager.load_game(99).is_empty(), "load_game with slot 99 returns empty")

    # Load non-existent save
    SaveManager.is_loading = false
    SaveManager.is_saving = false
    var result = SaveManager.load_game(7)
    _assert(result.is_empty(), "load_game for non-existent slot returns empty")

    # format_timestamp
    var ts = SaveManager.format_timestamp(0.0)
    _assert(ts is String, "format_timestamp returns a String")
    _assert(ts.length() > 0, "format_timestamp returns non-empty string")

    # has_save with invalid slot
    _assert(not SaveManager.has_save(-1), "has_save(-1) returns false")
    _assert(not SaveManager.has_save(100), "has_save(100) returns false")

    # get_save_path
    _assert(SaveManager.get_save_path(0).contains("save_00"), "get_save_path(0) contains save_00")
    _assert(SaveManager.get_save_path(0).ends_with(".eclipse"), "get_save_path(0) ends with .eclipse")
