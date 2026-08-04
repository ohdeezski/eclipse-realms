extends Node
## SaveManager.gd - Data Persistence System
## Handles saving and loading game state to/from disk
## Load order: Second (after GameManager)

## Signals
signal save_started
signal save_completed(success: bool, message: String)
signal save_failed(error: String)
signal load_started
signal load_completed(success: bool, data: Dictionary)
signal load_failed(error: String)

## Constants
const SAVE_DIR: String = "user://saves/"
const CONFIG_FILE: String = "user://config.cfg"
const MAX_SAVES: int = 10
const SAVE_EXTENSION: String = ".eclipse"

## Static variables
static var is_initialized: bool = false
static var current_save_slot: int = 0
static var save_slots: Array[Dictionary] = []
static var is_saving: bool = false
static var is_loading: bool = false


func _ready() -> void:
    if not is_initialized:
        _initialize()
        is_initialized = true


func _initialize() -> void:
    print("[SaveManager] Initializing save system")
    
    # Create save directory if it doesn't exist
    if not DirAccess.dir_exists_absolute(SAVE_DIR):
        var err = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
        if err != OK:
            push_error("[SaveManager] Failed to create save directory: %s" % SAVE_DIR)
            push_error("[SaveManager] Error code: %d" % err)
        else:
            print("[SaveManager] Created save directory: %s" % SAVE_DIR)
    
    # Load configuration
    load_config()
    
    # Load save slot metadata
    _load_save_slots()
    
    print("[SaveManager] Initialization complete")


# ============================================================================
# SAVE FUNCTIONS
# ============================================================================

func save_game(slot: int = 0, data: Dictionary = {}) -> bool:
    if is_saving or is_loading:
        push_warning("[SaveManager] Save operation already in progress")
        return false
    
    if slot < 0 or slot >= MAX_SAVES:
        push_error("[SaveManager] Invalid save slot: %d" % slot)
        return false
    
    is_saving = true
    current_save_slot = slot
    save_started.emit()
    
    var save_data: Dictionary
    if data.is_empty():
        save_data = _collect_game_data()
    else:
        save_data = data
    
    # Add metadata
    save_data["metadata"] = {
        "timestamp": Time.get_unix_time_from_system(),
        "version": GameManager.VERSION,
        "playtime": GameManager.session_data["playtime_seconds"],
        "slot": slot
    }
    
    # Create save file path
    var save_path: String = SAVE_DIR + "save_%02d%s" % [slot, SAVE_EXTENSION]
    
    # Save to file
    var file = FileAccess.open(save_path, FileAccess.WRITE)
    if file == null:
        push_error("[SaveManager] Failed to open save file: %s" % save_path)
        save_failed.emit("Failed to open save file")
        is_saving = false
        return false
    
    # Write JSON data (single, correct serialization)
    file.store_string(_format_save_json(save_data))
    file.close()
    
    # Update save slot metadata
    _update_save_slot(slot, save_data["metadata"])
    
    print("[SaveManager] Game saved to slot %d: %s" % [slot, save_path])
    
    is_saving = false
    save_completed.emit(true, "Save successful")
    return true
func _format_save_json(save_data: Dictionary) -> String:
    var json = JSON.new()
    json.data = save_data
    return json.stringify(save_data)


func save_config(config: Dictionary = {}) -> bool:
    var save_config = config
    if save_config == {}:
        save_config = GameManager.config
    
    var file = FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
    if file == null:
        push_error("[SaveManager] Failed to open config file: %s" % CONFIG_FILE)
        return false
    
    var json = JSON.new()
    json.data = save_config
    file.store_string(json.stringify(save_config))
    file.close()
    
    print("[SaveManager] Configuration saved")
    return true


func _collect_game_data() -> Dictionary:
    var save_data: Dictionary = {
        "player": {},
        "inventory": {},
        "quests": {},
        "world": {},
        "equipment": {},
        "session": GameManager.session_data.duplicate(true)
    }

    # Collect player data from the Player node in the scene tree
    var player = _find_player()
    if player:
        save_data["player"] = _collect_player_data(player)
        save_data["inventory"] = _collect_inventory_data(player)
        save_data["quests"] = _collect_quest_data(player)
        save_data["equipment"] = _collect_equipment_data(player)
    else:
        # Fallback defaults when no player exists (e.g. saving from main menu)
        save_data["player"] = {
			"name": "Player",
			"level": 1,
			"experience": 0,
			"species": "human",
			"appearance": {},
			"position_x": 0.0,
			"position_y": 0.0,
			"stats": {
				"health": 100,
				"max_health": 100,
				"mana": 50,
				"max_mana": 50,
				"attack": 10,
				"defense": 5
			}
		}
        save_data["inventory"] = { "items": [], "gold": 0 }
        save_data["quests"] = { "active": {}, "completed": [] }
        save_data["equipment"] = {}

    # World state
    save_data["world"] = {
        "current_scene": GameManager.current_scene,
        "previous_scene": GameManager.previous_scene
    }

    return save_data


func _find_player():
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        return players[0]
    return null


func _collect_player_data(player) -> Dictionary:
    return {
        "name": "Player",
        "level": player.level,
        "experience": player.experience,
        "species": "human",
        "appearance": {},
        "position_x": player.global_position.x,
        "position_y": player.global_position.y,
        "stats": {
            "health": player.health,
            "max_health": player.max_health,
            "mana": player.mana,
            "max_mana": player.max_mana,
            "attack": player.attack,
            "defense": player.defense
        }
    }


func _collect_inventory_data(player) -> Dictionary:
    return {
        "items": player.inventory.duplicate(),
        "gold": player.gold
    }


func _collect_quest_data(player) -> Dictionary:
    return {
        "active": player.active_quests.duplicate(true),
        "completed": player.completed_quests.duplicate()
    }


func _collect_equipment_data(player) -> Dictionary:
    return player.equipment.duplicate()


# ============================================================================
# LOAD FUNCTIONS
# ============================================================================

func load_game(slot: int = 0) -> Dictionary:
    if is_saving or is_loading:
        push_warning("[SaveManager] Load operation already in progress")
        return {}
    
    if slot < 0 or slot >= MAX_SAVES:
        push_error("[SaveManager] Invalid save slot: %d" % slot)
        return {}
    
    is_loading = true
    current_save_slot = slot
    load_started.emit()
    
    var save_path: String = SAVE_DIR + "save_%02d%s" % [slot, SAVE_EXTENSION]
    
    if not FileAccess.file_exists(save_path):
        push_error("[SaveManager] Save file not found: %s" % save_path)
        load_failed.emit("Save file not found")
        is_loading = false
        return {}
    
    var file = FileAccess.open(save_path, FileAccess.READ)
    if file == null:
        push_error("[SaveManager] Failed to open save file: %s" % save_path)
        load_failed.emit("Failed to open save file")
        is_loading = false
        return {}
    
    var content = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(content)
    
    if parse_result != OK:
        push_error("[SaveManager] Failed to parse save file: %s" % json.get_error_message())
        load_failed.emit("Failed to parse save file")
        is_loading = false
        return {}
    
    var save_data = json.data
    
    print("[SaveManager] Game loaded from slot %d: %s" % [slot, save_path])
    
    # Apply loaded data to game
    _apply_loaded_data(save_data)
    
    is_loading = false
    load_completed.emit(true, save_data)
    return save_data


func load_config() -> Dictionary:
    if not FileAccess.file_exists(CONFIG_FILE):
        print("[SaveManager] No config file found, using defaults")
        return GameManager.config
    
    var file = FileAccess.open(CONFIG_FILE, FileAccess.READ)
    if file == null:
        push_error("[SaveManager] Failed to open config file: %s" % CONFIG_FILE)
        return GameManager.config
    
    var content = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(content)
    
    if parse_result == OK:
        GameManager.config = json.data
        print("[SaveManager] Configuration loaded")
        return json.data
    else:
        push_error("[SaveManager] Failed to parse config: %s" % json.get_error_message())
        return GameManager.config


func _apply_loaded_data(save_data: Dictionary) -> void:
    # Restore session data
    if save_data.has("session"):
        GameManager.session_data = save_data["session"].duplicate(true)

    # Store world data for use by SceneManager when loading the scene
    if save_data.has("world"):
        _pending_world_data = save_data["world"].duplicate(true)

    # Restore player data if a Player node exists in the current scene
    var player = _find_player()
    if player:
        _apply_player_data(save_data.get("player", {}), player)
        _apply_inventory_data(save_data.get("inventory", {}), player)
        _apply_quest_data(save_data.get("quests", {}), player)
        _apply_equipment_data(save_data.get("equipment", {}), player)
    else:
        # Store pending data so the Player can pick it up on spawn
        _pending_player_data = save_data.get("player", {})
        _pending_inventory_data = save_data.get("inventory", {})
        _pending_quest_data = save_data.get("quests", {})
        _pending_equipment_data = save_data.get("equipment", {})

    print("[SaveManager] Applied loaded data to game state")


## Pending data containers used when loading a save before the Player node exists
static var _pending_player_data: Dictionary = {}
static var _pending_inventory_data: Dictionary = {}
static var _pending_quest_data: Dictionary = {}
static var _pending_equipment_data: Dictionary = {}
static var _pending_world_data: Dictionary = {}


func has_pending_data() -> bool:
    return not _pending_player_data.is_empty() or not _pending_world_data.is_empty()


func consume_pending_player_data() -> Dictionary:
    var data = _pending_player_data.duplicate(true)
    _pending_player_data = {}
    return data


func consume_pending_inventory_data() -> Dictionary:
    var data = _pending_inventory_data.duplicate(true)
    _pending_inventory_data = {}
    return data


func consume_pending_quest_data() -> Dictionary:
    var data = _pending_quest_data.duplicate(true)
    _pending_quest_data = {}
    return data


func consume_pending_equipment_data() -> Dictionary:
    var data = _pending_equipment_data.duplicate(true)
    _pending_equipment_data = {}
    return data


func consume_pending_world_data() -> Dictionary:
    var data = _pending_world_data.duplicate(true)
    _pending_world_data = {}
    return data


func _apply_player_data(data: Dictionary, player) -> void:
    if data.is_empty():
        return
    var stats = data.get("stats", {})
    player.level = data.get("level", player.level)
    player.experience = data.get("experience", player.experience)
    player.health = stats.get("health", player.health)
    player.max_health = stats.get("max_health", player.max_health)
    player.mana = stats.get("mana", player.mana)
    player.max_mana = stats.get("max_mana", player.max_mana)
    player.attack = stats.get("attack", player.attack)
    player.defense = stats.get("defense", player.defense)
    var px = data.get("position_x", 0.0)
    var py = data.get("position_y", 0.0)
    player.global_position = Vector2(px, py)
    player.health_changed.emit(player.health, player.max_health)


func _apply_inventory_data(data: Dictionary, player) -> void:
    if data.is_empty():
        return
    player.inventory = data.get("items", []).duplicate()
    player.gold = data.get("gold", 0)


func _apply_quest_data(data: Dictionary, player) -> void:
    if data.is_empty():
        return
    # Active quests: Dict[str, Dict]  (quest_id -> {current: int})
    var raw_active = data.get("active", {})
    player.active_quests.clear()
    for qid in raw_active.keys():
        player.active_quests[qid] = {"current": raw_active[qid].get("current", 0)}
    player.completed_quests = data.get("completed", []).duplicate()


func _apply_equipment_data(data: Dictionary, player) -> void:
    if data.is_empty():
        return
    player.equipment = data.duplicate()


# ============================================================================
# SAVE SLOT MANAGEMENT
# ============================================================================

func _load_save_slots() -> void:
    save_slots = []
    
    for i in range(MAX_SAVES):
        var save_path: String = SAVE_DIR + "save_%02d%s" % [i, SAVE_EXTENSION]
        
        if FileAccess.file_exists(save_path):
            var metadata = _get_save_metadata(save_path)
            save_slots.append({
                "slot": i,
                "exists": true,
                "timestamp": metadata.get("timestamp", 0),
                "version": metadata.get("version", "unknown"),
                "playtime": metadata.get("playtime", 0)
            })
        else:
            save_slots.append({
                "slot": i,
                "exists": false,
                "timestamp": 0,
                "version": "",
                "playtime": 0
            })


func _update_save_slot(slot: int, metadata: Dictionary) -> void:
    if slot >= 0 and slot < save_slots.size():
        save_slots[slot] = {
            "slot": slot,
            "exists": true,
            "timestamp": metadata.get("timestamp", 0),
            "version": metadata.get("version", "unknown"),
            "playtime": metadata.get("playtime", 0)
        }


func _get_save_metadata(save_path: String) -> Dictionary:
    if not FileAccess.file_exists(save_path):
        return {}
    
    var file = FileAccess.open(save_path, FileAccess.READ)
    if file == null:
        return {}
    
    var content = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    if json.parse(content) == OK and json.data.has("metadata"):
        return json.data["metadata"]
    
    return {}


func get_save_slots() -> Array:
    return save_slots.duplicate()


func get_save_info(slot: int) -> Dictionary:
    if slot >= 0 and slot < save_slots.size():
        return save_slots[slot].duplicate()
    return {}


func delete_save(slot: int) -> bool:
    if slot < 0 or slot >= MAX_SAVES:
        return false
    
    var save_path: String = SAVE_DIR + "save_%02d%s" % [slot, SAVE_EXTENSION]
    
    if FileAccess.file_exists(save_path):
        # Remove using a DirAccess instance rooted at the save directory.
        var d = DirAccess.open(SAVE_DIR)
        if d != null and d.remove("save_%02d%s" % [slot, SAVE_EXTENSION]) == OK:
            save_slots[slot]["exists"] = false
            save_slots[slot]["timestamp"] = 0
            print("[SaveManager] Deleted save slot %d" % slot)
            return true
    
    return false


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func has_save(slot: int = 0) -> bool:
    if slot < 0 or slot >= save_slots.size():
        return false
    return save_slots[slot].get("exists", false)


func get_save_path(slot: int = 0) -> String:
    return SAVE_DIR + "save_%02d%s" % [slot, SAVE_EXTENSION]


func get_latest_save() -> int:
    var latest_slot: int = -1
    var latest_time: float = 0.0
    
    for i in range(save_slots.size()):
        if save_slots[i].get("exists", false):
            var timestamp = save_slots[i].get("timestamp", 0)
            if timestamp > latest_time:
                latest_time = timestamp
                latest_slot = i
    
    return latest_slot


func format_timestamp(timestamp: float) -> String:
    var time_dict = Time.get_datetime_dict_from_unix_time(timestamp)
    return "%02d/%02d/%04d %02d:%02d" % [
        time_dict["month"],
        time_dict["day"],
        time_dict["year"],
        time_dict["hour"],
        time_dict["minute"]
    ]