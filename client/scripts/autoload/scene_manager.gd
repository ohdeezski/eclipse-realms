extends Node
## SceneManager.gd - Scene Transition System
## Handles loading, unloading, and transitions between scenes
## Load order: Fifth

## Signals
signal scene_loading(scene_path: String)
signal scene_loaded(scene_path: String)
signal scene_unloading(scene_path: String)
signal scene_unloaded(scene_path: String)
signal scene_changed(from_scene: String, to_scene: String)
signal transition_started(transition_type: String)
signal transition_completed

## Constants
const DEFAULT_SCENE: String = "res://scenes/main_menu/main_menu.tscn"
const LOADING_SCENE: String = "res://scenes/system/loading.tscn"
var FADE_TIME: float = 0.5

## Static variables
static var is_initialized: bool = false
static var current_scene: Node = null
static var previous_scene: Node = null
static var next_scene_path: String = ""
static var is_transitioning: bool = false
static var transition_type: String = "instant"

## Scene cache (for faster transitions)
static var scene_cache: Dictionary = {}

## Transition effects
static var transition_canvas: CanvasLayer = null
static var transition_alpha: float = 0.0


func _ready() -> void:
    if not is_initialized:
        _initialize()
        is_initialized = true


func _process(delta: float) -> void:
    # Handle transition effects
    if transition_canvas:
        if transition_type == "fade_out" and transition_alpha < 1.0:
            transition_alpha += delta / FADE_TIME
            _update_transition_alpha()
            if transition_alpha >= 1.0:
                transition_alpha = 1.0
                _update_transition_alpha()
                _complete_transition()
        elif transition_type == "fade_in" and transition_alpha > 0.0:
            transition_alpha -= delta / FADE_TIME
            _update_transition_alpha()
            if transition_alpha <= 0.0:
                transition_alpha = 0.0
                _update_transition_alpha()
                transition_completed.emit()


func _initialize() -> void:
    print("[SceneManager] Initializing scene system")
    
    # Set up transition canvas if it exists
    if has_node("/root/TransitionCanvas"):
        transition_canvas = get_node("/root/TransitionCanvas") as CanvasLayer
        transition_canvas.visible = false
    
    # Check if GameManager is available
    if not has_node("/root/GameManager"):
        push_error("[SceneManager] GameManager not found - scene transitions may not work correctly")
    else:
        # GameManager is available
        pass
    
    # Load initial scene
    if get_tree().root.get_child_count() > 1:  # Already has scenes
        current_scene = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
    else:
        change_scene(DEFAULT_SCENE)
    
    print("[SceneManager] Scene system initialized")


# ============================================================================
# SCENE CHANGE FUNCTIONS
# ============================================================================

func change_scene(scene_path: String, transition: String = "instant") -> void:
    if is_transitioning:
        push_warning("[SceneManager] Transition already in progress: %s" % scene_path)
        return
    
    if not ResourceLoader.exists(scene_path):
        push_error("[SceneManager] Scene not found: %s" % scene_path)
        return
    
    next_scene_path = scene_path
    transition_type = transition
    
    match transition:
        "instant":
            _change_scene_instant()
        "fade":
            _start_fade_transition()
        _:
            _change_scene_instant()


func reload_current_scene() -> void:
    if current_scene:
        var scene_path = current_scene.scene_file_path
        change_scene(scene_path, "fade")


func go_to_main_menu() -> void:
    change_scene(DEFAULT_SCENE, "fade")


func _change_scene_instant() -> void:
    is_transitioning = true
    var from_path = current_scene.scene_file_path if current_scene else ""
    var old_scene = current_scene
    _persist_player_session()
    
    # Free current scene
    if old_scene:
        scene_unloading.emit(from_path)
        previous_scene = old_scene
        old_scene.queue_free()
        scene_unloaded.emit(from_path)
    
    # Load new scene
    var new_scene = load(next_scene_path)
    if new_scene == null:
        push_error("[SceneManager] Failed to load scene: %s" % next_scene_path)
        is_transitioning = false
        return
    
    # Instantiate and add to tree
    current_scene = new_scene.instantiate()
    get_tree().root.add_child(current_scene)
    get_tree().current_scene = current_scene
    
    scene_loading.emit(next_scene_path)
    scene_loaded.emit(next_scene_path)
    
    # Check if GameManager is available before emitting scene_changed
    if GameManager != null:
        scene_changed.emit(from_path, next_scene_path)
    
    print("[SceneManager] Changed scene to: %s" % next_scene_path)
    is_transitioning = false


func _start_fade_transition() -> void:
    if transition_canvas == null:
        _change_scene_instant()
        return
    
    is_transitioning = true
    transition_type = "fade_out"
    transition_canvas.visible = true
    transition_alpha = 0.0
    _update_transition_alpha()
    transition_started.emit("fade")


func _complete_transition() -> void:
    # Scene is fully faded out, now change it
    var old_scene = current_scene
    var old_path = old_scene.scene_file_path if old_scene else ""
    _persist_player_session()
    
    if old_scene:
        scene_unloading.emit(old_path)
        old_scene.queue_free()
        scene_unloaded.emit(old_path)
    
    # Load new scene
    var new_scene = load(next_scene_path)
    if new_scene == null:
        push_error("[SceneManager] Failed to load scene: %s" % next_scene_path)
        is_transitioning = false
        transition_canvas.visible = false
        return
    
    current_scene = new_scene.instantiate()
    get_tree().root.add_child(current_scene)
    get_tree().current_scene = current_scene
    
    # Start fade in
    transition_type = "fade_in"
    transition_alpha = 1.0
    _update_transition_alpha()
    
    scene_loading.emit(next_scene_path)
    scene_loaded.emit(next_scene_path)
    
    # Check if GameManager is available before emitting scene_changed
    if GameManager != null:
        scene_changed.emit(old_path, next_scene_path)


func _persist_player_session() -> void:
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0 and players[0].has_method("get_transition_data"):
        GameManager.session_data["player"] = players[0].get_transition_data()


func _update_transition_alpha() -> void:
    if transition_canvas:
        var color_mod = Color(1, 1, 1, transition_alpha)
        transition_canvas.modulate = color_mod


# ============================================================================
# SCENE CACHING
# ============================================================================

func cache_scene(scene_path: String) -> bool:
    if scene_cache.has(scene_path):
        return true
    
    if not ResourceLoader.exists(scene_path):
        return false
    
    var packed_scene = load(scene_path)
    if packed_scene == null:
        return false
    
    scene_cache[scene_path] = packed_scene
    print("[SceneManager] Cached scene: %s" % scene_path)
    return true


func uncache_scene(scene_path: String) -> bool:
    if scene_cache.has(scene_path):
        scene_cache.erase(scene_path)
        print("[SceneManager] Uncached scene: %s" % scene_path)
        return true
    return false


func clear_scene_cache() -> void:
    scene_cache.clear()
    print("[SceneManager] Scene cache cleared")


func is_scene_cached(scene_path: String) -> bool:
    return scene_cache.has(scene_path)


# ============================================================================
# SCENE QUERY FUNCTIONS
# ============================================================================

func get_current_scene() -> Node:
    return current_scene


func get_current_scene_path() -> String:
    return current_scene.scene_file_path if current_scene else ""


func get_previous_scene() -> Node:
    return previous_scene


func get_previous_scene_path() -> String:
    return previous_scene.scene_file_path if previous_scene else ""


func is_scene_loaded(scene_name: String) -> bool:
    if not current_scene:
        return false
    return current_scene.scene_file_path.get_file().get_basename() == scene_name.get_file().get_basename()


func find_node_in_current_scene(path: String) -> Node:
    if current_scene:
        return current_scene.find_child(path, true, false)
    return null


func find_nodes_in_current_scene(type: String) -> Array:
    var nodes: Array = []
    if current_scene:
        _find_nodes_recursive(current_scene, type, nodes)
    return nodes


func _find_nodes_recursive(parent: Node, type: String, result: Array) -> void:
    for child in parent.get_children():
        if child.get_class() == type:
            result.append(child)
        _find_nodes_recursive(child, type, result)


# ============================================================================
# SCENE GROUP MANAGEMENT
# ============================================================================

func get_all_scenes_in_group(group_name: String) -> Array:
    var scenes: Array = []
    var root = get_tree().root
    
    for child in root.get_children():
        _find_nodes_in_group(child, group_name, scenes)
    
    return scenes


func _find_nodes_in_group(node: Node, group_name: String, result: Array) -> void:
    if node.is_in_group(group_name):
        result.append(node)
    
    for child in node.get_children():
        _find_nodes_in_group(child, group_name, result)


# ============================================================================
# SCENE UTILITY FUNCTIONS
# ============================================================================

func create_scene(scene_path: String) -> Node:
    """Create a new instance of a scene"""
    if not ResourceLoader.exists(scene_path):
        return null
    
    var packed_scene = load(scene_path)
    if packed_scene == null:
        return null
    
    return packed_scene.instantiate()


func add_scene_to_current(scene_path: String, parent_path: String = "") -> Node:
    """Add a scene as a child of the current scene or a specific parent"""
    var new_node = create_scene(scene_path)
    if new_node == null:
        return null
    
    var parent: Node
    if parent_path == "":
        parent = current_scene if current_scene else get_tree().root
    else:
        parent = find_node_in_current_scene(parent_path)
        if parent == null:
            parent = current_scene if current_scene else get_tree().root
    
    parent.add_child(new_node)
    return new_node


func remove_scene_from_current(node: Node) -> bool:
    """Remove a scene node from the current scene"""
    if node and node.get_parent():
        node.get_parent().remove_child(node)
        node.queue_free()
        return true
    return false


# ============================================================================
# TRANSITION CONTROL
# ============================================================================

func set_transition_time(seconds: float) -> void:
    FADE_TIME = seconds  # FADE_TIME is now a mutable var (was const)


func set_transition_canvas(canvas: CanvasLayer) -> void:
    transition_canvas = canvas
    if transition_canvas:
        transition_canvas.visible = false
        transition_canvas.modulate.a = 0.0


func force_complete_transition() -> void:
    if is_transitioning:
        transition_type = "instant"
        _change_scene_instant()
        if transition_canvas:
            transition_canvas.visible = false
            transition_alpha = 0.0
            _update_transition_alpha()
        is_transitioning = false


# ============================================================================
# DEBUG FUNCTIONS
# ============================================================================

func print_scene_hierarchy() -> void:
    print("[SceneManager] Current Scene Hierarchy:")
    if current_scene:
        _print_node_hierarchy(current_scene, 0)


func _print_node_hierarchy(node: Node, indent: int) -> void:
    var prefix = "  ".repeat(indent)
    print("%s- %s (%s)" % [prefix, node.name, node.get_class()])
    
    for child in node.get_children():
        _print_node_hierarchy(child, indent + 1)


func list_all_loaded_scenes() -> Array:
    var scenes: Array = []
    var root = get_tree().root
    
    for child in root.get_children():
        if child is Node2D or child is Control:
            scenes.append(child.scene_file_path)
    
    return scenes


func get_memory_usage() -> Dictionary:
    return {
        "cached_scenes": scene_cache.size(),
        "current_scene": current_scene.scene_file_path if current_scene else "",
        "total_nodes": get_tree().get_node_count()
    }
