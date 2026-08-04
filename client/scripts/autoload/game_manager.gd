extends Node
## GameManager.gd - Core Game Management System
## This is the primary singleton that coordinates all game systems
## Load order: First

## Signals
signal game_started
signal game_paused
signal game_resumed
signal game_over
signal scene_changed(scene_name: String)
signal player_logged_in(player_data: Dictionary)
signal player_logged_out

## Constants
const PROJECT_NAME: String = "Eclipse Realms"
const VERSION: String = "0.1.0"
const PHASE: String = "First Playable"

## Game States
enum GameState {
    INITIALIZING,
    MAIN_MENU,
    LOADING,
    PLAYING,
    PAUSED,
    SAVING,
    LOADING_SAVE,
    QUITTING
}

## Static variables
static var current_state: GameState = GameState.INITIALIZING
static var is_initialized: bool = false
static var debug_mode: bool = true
static var current_scene: String = ""
static var previous_scene: String = ""

## Game configuration
static var config: Dictionary = {
    "difficulty": "normal",
    "language": "en",
    "sfx_volume": 1.0,
    "music_volume": 1.0,
    "show_tutorials": true,
    "auto_save": true,
    "target_fps": 60
}

## Runtime data
static var session_data: Dictionary = {
    "playtime_seconds": 0.0,
    "enemies_defeated": 0,
    "items_collected": 0,
    "quests_completed": 0,
    "deaths": 0
}


func _ready() -> void:
    if not is_initialized:
        _initialize_game()
        is_initialized = true
    
    # Connect to process for session tracking
    var scene_tree = get_tree()
    scene_tree.connect("node_added", _on_node_added)


func _process(delta: float) -> void:
    if current_state == GameState.PLAYING:
        session_data["playtime_seconds"] += delta


func _initialize_game() -> void:
    print("[GameManager] Initializing Eclipse Realms v%s - %s" % [VERSION, PHASE])
    
    # Initialize subsystems
    _initialize_subsystems()
    
    # Set game state
    change_state(GameState.MAIN_MENU)
    
    print("[GameManager] Initialization complete")


func _initialize_subsystems() -> void:
    # Verify all critical subsystems are loaded
    var subsystems = [
        "SaveManager",
        "AudioManager", 
        "InputManager",
        "SceneManager",
        "NetworkManager",
        "UIManager",
        "GameData",
        "Localization"
    ]
    
    for subsystem in subsystems:
        if has_node("/root/%s" % subsystem):
            print("[GameManager] Found subsystem: %s" % subsystem)
        else:
            push_error("[GameManager] Critical subsystem missing: %s" % subsystem)


func change_state(new_state: GameState) -> void:
    var old_state = current_state
    current_state = new_state
    
    match new_state:
        GameState.INITIALIZING:
            _handle_initializing()
        GameState.MAIN_MENU:
            _handle_main_menu()
        GameState.LOADING:
            _handle_loading()
        GameState.PLAYING:
            _handle_playing()
        GameState.PAUSED:
            _handle_paused()
        GameState.SAVING:
            _handle_saving()
        GameState.LOADING_SAVE:
            _handle_loading_save()
        GameState.QUITTING:
            _handle_quitting()
    
    print("[GameManager] State changed: %s -> %s" % [old_state, new_state])


# State handlers
func _handle_initializing() -> void:
    pass  # Already handled in _initialize_game


func _handle_main_menu() -> void:
    AudioManager.initialize()
    AudioManager.play_music("main_menu")


func _handle_loading() -> void:
    UIManager.show_loading_screen()


func _handle_playing() -> void:
    AudioManager.play_music("overworld")
    game_started.emit()


func _handle_paused() -> void:
    get_tree().paused = true
    AudioManager.pause_music()
    game_paused.emit()


func _handle_resumed() -> void:
    get_tree().paused = false
    AudioManager.resume_music()
    game_resumed.emit()


func _handle_saving() -> void:
    UIManager.show_saving_indicator()


func _handle_loading_save() -> void:
    UIManager.show_loading_indicator("Loading Save...")


func _handle_quitting() -> void:
    # Clean up before quitting
    AudioManager.stop_all()
    SaveManager.save_game()
    get_tree().quit()


# Public API
func start_game() -> void:
    change_state(GameState.PLAYING)


func pause_game() -> void:
    if current_state == GameState.PLAYING:
        change_state(GameState.PAUSED)


func resume_game() -> void:
    if current_state == GameState.PAUSED:
        change_state(GameState.PLAYING)


func quit_game() -> void:
    SaveManager.save_game()
    change_state(GameState.QUITTING)


func load_scene(scene_path: String) -> void:
    previous_scene = current_scene
    current_scene = scene_path
    SceneManager.change_scene(scene_path)
    scene_changed.emit(scene_path)


func save_game(slot: int = 0) -> void:
    SaveManager.save_game(slot)


func get_game_config(key: String, default_value = null) -> Variant:
    if config.has(key):
        return config[key]
    return default_value


func set_game_config(key: String, value: Variant) -> void:
    config[key] = value
    # Save config to disk
    SaveManager.save_config(config.duplicate())


func log_event(event_type: String, details: Dictionary = {}) -> void:
    if not debug_mode:
        return
    
    var log_entry = {
        "timestamp": Time.get_ticks_msec(),
        "type": event_type,
        "details": details,
        "scene": current_scene,
        "state": current_state
    }
    
    # In production, this would write to a log file
    print("[GAME_EVENT] %s: %s" % [event_type, JSON.stringify(details)])


func show_debug_info() -> void:
    print("\n--- Eclipse Realms Debug Info ---")
    print("Version: %s" % VERSION)
    print("Phase: %s" % PHASE)
    print("State: %s" % current_state)
    print("Scene: %s" % current_scene)
    print("Playtime: %.1f seconds" % session_data["playtime_seconds"])
    print("FPS: %d" % get_tree().debug_get_tree_fps())
    print("-----------------------------------\n")


# Callbacks
func _on_node_added(node: Node) -> void:
    # Track important scene changes
    if node is CharacterBody2D and current_state == GameState.PLAYING:
        log_event("character_spawned", {"type": node.get_class()})


# Static helper methods
static func get_version() -> String:
    return VERSION


static func get_phase() -> String:
    return PHASE


static func is_debug() -> bool:
    return debug_mode