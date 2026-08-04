extends Node
## InputManager.gd - Input Handling System
## Centralized input management with action mapping and device support
## Load order: Fourth

## Signals
signal action_pressed(action_name: String, event: InputEvent)
signal action_released(action_name: String, event: InputEvent)
signal action_held(action_name: String, strength: float)
signal mouse_moved(position: Vector2, delta: Vector2)
signal mouse_wheel(value: Vector2)
signal gamepad_connected(device_id: int)
signal gamepad_disconnected(device_id: int)

## Constants
const DEADZONE: float = 0.2
const HOLD_THRESHOLD: float = 0.5

## Static variables
static var is_initialized: bool = false
static var input_enabled: bool = true
static var mouse_enabled: bool = true
static var gamepad_enabled: bool = true

## Action states
static var action_states: Dictionary = {}
static var action_timers: Dictionary = {}

## Input context system (for context-sensitive controls)
static var current_context: String = "default"
static var context_maps: Dictionary = {}

## Mouse state
static var mouse_position: Vector2 = Vector2.ZERO
static var mouse_delta: Vector2 = Vector2.ZERO
static var mouse_mode: int = Input.MOUSE_MODE_VISIBLE  # 0=visible, 1=hidden, 2=captured

## Gamepad state
static var connected_gamepads: Array = []
static var last_gamepad_check: float = 0.0
static var gamepad_check_interval: float = 2.0


func _ready() -> void:
    if not is_initialized:
        _initialize()
        is_initialized = true


func _process(delta: float) -> void:
    # Update mouse position
    if mouse_enabled:
        mouse_position = get_viewport().get_mouse_position()
    
    # Check for gamepad connections
    if gamepad_enabled and Time.get_ticks_msec() - last_gamepad_check > gamepad_check_interval * 1000:
        _check_gamepads()
        last_gamepad_check = Time.get_ticks_msec()


func _unhandled_input(event: InputEvent) -> void:
    if not input_enabled:
        return
    
    # Check all action states first
    for action_name in InputMap.get_actions():
        if Input.is_action_just_pressed(action_name):
            action_pressed.emit(action_name, event)
        elif Input.is_action_just_released(action_name):
            action_released.emit(action_name, event)
        elif Input.get_action_strength(action_name) > 0:
            action_held.emit(action_name, Input.get_action_strength(action_name))
    
    # Handle mouse events
    if event is InputEventMouseMotion and mouse_enabled:
        mouse_delta = event.relative
        mouse_moved.emit(mouse_position, mouse_delta)
    
    if event is InputEventMouseButton:
        var mouse_event = event as InputEventMouseButton
        _handle_mouse_button(mouse_event)
    
    if event is InputEventMouseButton and mouse_enabled:
        # Godot 4 folded the mouse wheel into InputEventMouseButton (WHEEL_UP=4, WHEEL_DOWN=5)
        if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            mouse_wheel.emit(Vector2(0, -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1))
    
    # Handle key events
    if event is InputEventKey:
        var key_event = event as InputEventKey
        _handle_key_event(key_event)
    
    # Handle joypad events
    if event is InputEventJoypadButton:
        var joy_event = event as InputEventJoypadButton
        _handle_joypad_button(joy_event)
    
    if event is InputEventJoypadMotion:
        var joy_motion = event as InputEventJoypadMotion
        _handle_joypad_motion(joy_motion)


func _initialize() -> void:
    print("[InputManager] Initializing input system")
    
    # Set up default context mappings (context is selected after maps exist)
    var default_map = {
        "move_left": "move_left",
        "move_right": "move_right",
        "move_up": "move_up",
        "move_down": "move_down",
        "jump": "jump",
        "attack": "attack",
        "interact": "interact",
        "run": "run",
        "guard": "guard",
        "inventory": "inventory",
        "character": "character",
        "map": "map",
        "quest_log": "quest_log",
        "ui_accept": "ui_accept",
        "ui_cancel": "ui_cancel"
    }
    add_input_context("default", default_map)
    
    # Set up game context (same as default for now)
    add_input_context("game", default_map.duplicate())
    
    # Set up menu context (different bindings for menu)
    var menu_map = {
        "ui_accept": "ui_accept",
        "ui_cancel": "ui_cancel", 
        "ui_up": "ui_up",
        "ui_down": "ui_down",
        "ui_left": "ui_left",
        "ui_right": "ui_right"
    }
    add_input_context("menu", menu_map)
    
    # Set up dialog context
    add_input_context("dialog", menu_map.duplicate())
    
    # Now select the default context (maps exist)
    set_input_context("default")
    
    # Initialize connected gamepads
    _check_gamepads()
    
    # Set initial mouse mode
    set_mouse_mode(mouse_mode)
    
    print("[InputManager] Input system initialized")


func _check_gamepads() -> void:
    var new_gamepads: Array = []
    
    for i in Input.get_connected_joypads():
        new_gamepads.append(i)
        if not connected_gamepads.has(i):
            gamepad_connected.emit(i)
            print("[InputManager] Gamepad connected: Device %d" % i)
    
    # Check for disconnected gamepads
    for old_id in connected_gamepads:
        if not new_gamepads.has(old_id):
            gamepad_disconnected.emit(old_id)
            print("[InputManager] Gamepad disconnected: Device %d" % old_id)
    
    connected_gamepads = new_gamepads.duplicate()


# ============================================================================
# INPUT ACTIONS
# ============================================================================

func is_action_pressed(action_name: String, context: String = "") -> bool:
    if not input_enabled:
        return false
    
    var context_to_use = context if context != "" else current_context
    
    # Check if action is mapped in current context
    if context_maps.has(context_to_use) and context_maps[context_to_use].has(action_name):
        var action = context_maps[context_to_use][action_name]
        return Input.is_action_pressed(action)
    
    # Fall back to default action
    return Input.is_action_pressed(action_name)


func is_action_just_pressed(action_name: String, context: String = "") -> bool:
    if not input_enabled:
        return false
    
    var context_to_use = context if context != "" else current_context
    
    if context_maps.has(context_to_use) and context_maps[context_to_use].has(action_name):
        var action = context_maps[context_to_use][action_name]
        return Input.is_action_just_pressed(action)
    
    return Input.is_action_just_pressed(action_name)


func is_action_just_released(action_name: String, context: String = "") -> bool:
    if not input_enabled:
        return false
    
    var context_to_use = context if context != "" else current_context
    
    if context_maps.has(context_to_use) and context_maps[context_to_use].has(action_name):
        var action = context_maps[context_to_use][action_name]
        return Input.is_action_just_released(action)
    
    return Input.is_action_just_released(action_name)


func get_action_strength(action_name: String, context: String = "") -> float:
    if not input_enabled:
        return 0.0
    
    var context_to_use = context if context != "" else current_context
    
    if context_maps.has(context_to_use) and context_maps[context_to_use].has(action_name):
        var action = context_maps[context_to_use][action_name]
        return Input.get_action_strength(action)
    
    return Input.get_action_strength(action_name)


# ============================================================================
# INPUT CONTEXT SYSTEM
# ============================================================================

func set_input_context(context_name: String) -> bool:
    if not context_maps.has(context_name):
        push_error("[InputManager] Context not found: %s" % context_name)
        return false
    
    current_context = context_name
    print("[InputManager] Switched to context: %s" % context_name)
    return true


func add_input_context(context_name: String, action_map: Dictionary) -> void:
    context_maps[context_name] = action_map.duplicate()
    print("[InputManager] Added context: %s" % context_name)


func remove_input_context(context_name: String) -> bool:
    if context_maps.has(context_name):
        context_maps.erase(context_name)
        if current_context == context_name:
            current_context = "default"
        return true
    return false


func get_current_context() -> String:
    return current_context


# ============================================================================
# MOUSE HANDLING
# ============================================================================

func get_mouse_position() -> Vector2:
    return mouse_position


func get_mouse_delta() -> Vector2:
    return mouse_delta


func set_mouse_mode(mode: int) -> void:
    mouse_mode = mode
    
    if mouse_enabled:
        match mode:
            Input.MOUSE_MODE_VISIBLE:
                Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
            Input.MOUSE_MODE_HIDDEN:
                Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
            Input.MOUSE_MODE_CAPTURED:
                if current_context == "game":  # Only capture in game context
                    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func show_mouse() -> void:
    set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func hide_mouse() -> void:
    set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func capture_mouse() -> void:
    set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func set_mouse_enabled(enabled: bool) -> void:
    mouse_enabled = enabled
    if enabled:
        show_mouse()


func is_mouse_enabled() -> bool:
    return mouse_enabled


func _handle_mouse_button(event: InputEventMouseButton) -> void:
    var action_name: String = ""
    
    match event.button_index:
        MOUSE_BUTTON_LEFT:
            action_name = "mouse_left"
        MOUSE_BUTTON_RIGHT:
            action_name = "mouse_right"
        MOUSE_BUTTON_MIDDLE:
            action_name = "mouse_middle"
    
    if action_name != "" and event.pressed:
        action_pressed.emit(action_name, event)
    elif action_name != "" and not event.pressed:
        action_released.emit(action_name, event)


# ============================================================================
# KEYBOARD HANDLING
# ============================================================================

func _handle_key_event(event: InputEventKey) -> void:
    var action_name: String = ""
    
    # Map common keys to action names
    match event.keycode:
        KEY_ESCAPE:
            action_name = "ui_cancel"
        KEY_ENTER, KEY_KP_ENTER:
            action_name = "ui_accept"
        KEY_SPACE:
            if event.shift_pressed:
                action_name = ""
            else:
                action_name = "jump"
        KEY_SHIFT:
            action_name = "run"
        KEY_TAB:
            action_name = "inventory"
        KEY_C:
            action_name = "character"
        KEY_M:
            action_name = "map"
        KEY_Q:
            action_name = "quick_slot_1"
        KEY_E:
            action_name = "interact"
        KEY_J:
            action_name = "attack"
        KEY_K:
            action_name = "skill_1"
        KEY_L:
            action_name = "skill_2"
        KEY_G:
            action_name = "guard"
        KEY_N:
            action_name = "quest_log"
    
    if action_name != "" and event.pressed:
        action_pressed.emit(action_name, event)
    elif action_name != "" and not event.pressed:
        action_released.emit(action_name, event)


# ============================================================================
# GAMEPAD HANDLING
# ============================================================================

func _handle_joypad_button(event: InputEventJoypadButton) -> void:
    if not gamepad_enabled:
        return
    
    var action_name: String = ""
    
    # Map gamepad buttons to actions
    # Map gamepad buttons to actions. Uses integer button indices directly
    # (engine-version-agnostic; Godot 4 exposes wheel as mouse button 4/5 too).
    match event.button_index:
        0:  # South / A
            action_name = "ui_accept"
        1:  # East / B
            action_name = "ui_cancel"
        2:  # North / Y
            action_name = "interact"
        3:  # West / X
            action_name = "attack"
        4:  # Start
            action_name = "menu"
        5:  # Select / Guide
            action_name = "inventory"
        6:  # L1
            action_name = "run"
        7:  # R1
            action_name = "jump"
        8:  # L2
            action_name = "special"
        9:  # R2
            action_name = "skill_1"
    
    if action_name != "" and event.pressed:
        action_pressed.emit(action_name, event)
    elif action_name != "" and not event.pressed:
        action_released.emit(action_name, event)


func _handle_joypad_motion(event: InputEventJoypadMotion) -> void:
    if not gamepad_enabled:
        return
    
    var action_name: String = ""
    var strength: float = abs(event.axis_value)
    
    # Apply deadzone
    if strength < DEADZONE:
        return
    
    # Normalize
    strength = (strength - DEADZONE) / (1.0 - DEADZONE)
    
    # Map gamepad axes to actions. Integer axis indices (engine-version-agnostic).
    match event.axis:
        0:  # Left stick X
            action_name = "move_left" if event.axis_value < 0 else "move_right"
            strength = abs(event.axis_value)
        1:  # Left stick Y
            action_name = "move_up" if event.axis_value < 0 else "move_down"
            strength = abs(event.axis_value)
        2:  # Right stick X
            action_name = "camera_left" if event.axis_value < 0 else "camera_right"
            strength = abs(event.axis_value)
        3:  # Right stick Y
            action_name = "camera_up" if event.axis_value < 0 else "camera_down"
            strength = abs(event.axis_value)
        6:  # Left trigger
            action_name = "zoom_in"
            strength = event.axis_value
        7:  # Right trigger
            action_name = "zoom_out"
            strength = event.axis_value
    
    if action_name != "":
        action_held.emit(action_name, strength)


func get_gamepad_axis(device_id: int, axis: int) -> float:
    return Input.get_joy_axis(device_id, axis)


func is_gamepad_connected(device_id: int = 0) -> bool:
    return connected_gamepads.has(device_id)


func get_connected_gamepads() -> Array:
    return connected_gamepads.duplicate()


func set_gamepad_enabled(enabled: bool) -> void:
    gamepad_enabled = enabled


func is_gamepad_enabled() -> bool:
    return gamepad_enabled


# ============================================================================
# INPUT ENABLE/DISABLE
# ============================================================================

func enable_input() -> void:
    input_enabled = true


func disable_input() -> void:
    input_enabled = false


func toggle_input() -> bool:
    input_enabled = not input_enabled
    return input_enabled


func is_input_enabled() -> bool:
    return input_enabled


# ============================================================================
# VIBRATION (if supported)
# ============================================================================

func vibrate_gamepad(device_id: int, left_strength: float, right_strength: float, duration: float) -> void:
    if not gamepad_enabled:
        return
    
    Input.start_joy_vibration(device_id, left_strength, right_strength, duration)


func stop_vibration(device_id: int) -> void:
    if not gamepad_enabled:
        return
    
    Input.stop_joy_vibration(device_id)


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func get_input_device_type() -> String:
    # Determine primary input device
    if is_gamepad_connected():
        return "gamepad"
    if mouse_enabled:
        return "mouse_keyboard"
    return "keyboard"


func is_using_controller() -> bool:
    return get_input_device_type() == "gamepad"


func reset_all_actions() -> void:
    # Reset action states
    action_states.clear()
    action_timers.clear()


func print_input_state() -> void:
    print("[InputManager] Current Input State:")
    print("  Enabled: %s" % input_enabled)
    print("  Context: %s" % current_context)
    print("  Mouse: %s (Position: %s)" % [mouse_enabled, mouse_position])
    print("  Gamepad: %s (Connected: %s)" % [gamepad_enabled, connected_gamepads])
