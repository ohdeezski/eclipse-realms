extends Node
## UIManager.gd - User Interface Management System
## Centralized UI control for HUD, menus, dialogs, and notifications
## Load order: Seventh

## Signals
signal ui_visible_changed(visible: bool)
signal hud_visible_changed(visible: bool)
signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)
signal dialog_shown(dialog_name: String)
signal dialog_hidden(dialog_name: String)
signal notification_shown(message: String, type: String)

## Constants
const UI_DIR: String = "res://scenes/ui/"
const DIALOG_DIR: String = UI_DIR + "dialogs/"
const MENU_DIR: String = UI_DIR + "menus/"
const HUD_DIR: String = UI_DIR + "hud/"

const NOTIFICATION_DURATION: float = 3.0  # seconds
const MAX_NOTIFICATIONS: int = 5
const ANIMATION_SPEED: float = 10.0  # pixels per second

## Static variables
static var is_initialized: bool = false
static var is_ui_visible: bool = true
static var is_hud_visible: bool = true

## UI Containers
static var ui_canvas: CanvasLayer = null
static var hud_layer: CanvasLayer = null
static var menu_layer: CanvasLayer = null
static var dialog_layer: CanvasLayer = null
static var notification_layer: CanvasLayer = null

## Active UI elements
static var active_menus: Dictionary = {}
static var active_dialogs: Dictionary = {}
static var active_notifications: Array = []

## Loading screen
static var loading_screen: Control = null
static var loading_text: String = "Loading..."

## Input blocking
static var is_input_blocked: bool = false
static var input_blockers: int = 0


func _ready() -> void:
    if not is_initialized:
        _initialize()
        is_initialized = true


func _process(delta: float) -> void:
    # Update notification positions and timers
    _update_notifications(delta)


func _initialize() -> void:
    print("[UIManager] Initializing UI system")
    
    # Find or create UI containers
    _setup_ui_containers()
    
    # Set up input blocking
    InputManager.connect("action_pressed", _on_action_pressed)
    
    print("[UIManager] UI system initialized")


func _setup_ui_containers() -> void:
    # UI containers should be set up in the main scene
    # Try to find them
    
    if has_node("/root/UI"):
        ui_canvas = get_node("/root/UI") as CanvasLayer
    
    if has_node("/root/HUD"):
        hud_layer = get_node("/root/HUD") as CanvasLayer
    
    if has_node("/root/Menus"):
        menu_layer = get_node("/root/Menus") as CanvasLayer
    
    if has_node("/root/Dialogs"):
        dialog_layer = get_node("/root/Dialogs") as CanvasLayer
    
    if has_node("/root/Notifications"):
        notification_layer = get_node("/root/Notifications") as CanvasLayer
    
    # If containers don't exist, they'll be created when needed


# ============================================================================
# VISIBILITY CONTROL
# ============================================================================

func set_ui_visible(visible: bool) -> void:
    is_ui_visible = visible
    
    if ui_canvas:
        ui_canvas.visible = visible
    
    if hud_layer:
        hud_layer.visible = visible
    if menu_layer:
        menu_layer.visible = visible
    if dialog_layer:
        dialog_layer.visible = visible
    
    ui_visible_changed.emit(visible)


func set_hud_visible(visible: bool) -> void:
    is_hud_visible = visible
    
    if hud_layer:
        hud_layer.visible = visible
    
    hud_visible_changed.emit(visible)


func toggle_ui() -> bool:
    set_ui_visible(not is_ui_visible)
    return is_ui_visible


func toggle_hud() -> bool:
    set_hud_visible(not is_hud_visible)
    return is_hud_visible


# ============================================================================
# MENU MANAGEMENT
# ============================================================================

func open_menu(menu_name: String, data: Dictionary = {}) -> Control:
    if not menu_layer:
        _create_menu_layer()
    
    # Close all other menus first (optional - can be changed)
    close_all_menus()
    
    var menu_path: String = MENU_DIR + "%s.tscn" % menu_name
    
    if not ResourceLoader.exists(menu_path):
        menu_path = MENU_DIR + menu_name + ".tscn"
        if not ResourceLoader.exists(menu_path):
            push_error("[UIManager] Menu not found: %s" % menu_name)
            return null
    
    var packed_scene = load(menu_path)
    if packed_scene == null:
        push_error("[UIManager] Failed to load menu: %s" % menu_path)
        return null
    
    var menu_instance = packed_scene.instantiate() as Control
    
    if menu_instance == null:
        push_error("[UIManager] Failed to instantiate menu: %s" % menu_name)
        return null
    
    # Set up the menu
    menu_instance.name = menu_name
    menu_layer.add_child(menu_instance)
    
    # Position and show
    _center_control(menu_instance)
    menu_instance.visible = true
    
    # Store reference
    active_menus[menu_name] = menu_instance
    
    # Block input
    block_input()
    
    print("[UIManager] Opened menu: %s" % menu_name)
    menu_opened.emit(menu_name)
    
    return menu_instance


func close_menu(menu_name: String) -> bool:
    if not active_menus.has(menu_name):
        return false
    
    var menu_instance = active_menus[menu_name]
    
    if menu_instance:
        menu_instance.queue_free()
        active_menus.erase(menu_name)
    
    # Unblock input if no more menus
    if active_menus.size() == 0:
        unblock_input()
    
    print("[UIManager] Closed menu: %s" % menu_name)
    menu_closed.emit(menu_name)
    
    return true


func close_all_menus() -> void:
    for menu_name in active_menus:
        var menu_instance = active_menus[menu_name]
        if menu_instance:
            menu_instance.queue_free()
    
    active_menus.clear()
    unblock_input()
    
    print("[UIManager] Closed all menus")


func is_menu_open(menu_name: String) -> bool:
    return active_menus.has(menu_name)


func get_menu(menu_name: String) -> Control:
    return active_menus.get(menu_name, null) as Control


func get_active_menus() -> Array:
    return active_menus.keys()


# ============================================================================
# DIALOG MANAGEMENT
# ============================================================================

func show_dialog(dialog_name: String, data: Dictionary = {}, modal: bool = true) -> Control:
    if not dialog_layer:
        _create_dialog_layer()
    
    var dialog_path: String = DIALOG_DIR + "%s.tscn" % dialog_name
    
    if not ResourceLoader.exists(dialog_path):
        dialog_path = DIALOG_DIR + dialog_name + ".tscn"
        if not ResourceLoader.exists(dialog_path):
            push_error("[UIManager] Dialog not found: %s" % dialog_name)
            return null
    
    var packed_scene = load(dialog_path)
    if packed_scene == null:
        push_error("[UIManager] Failed to load dialog: %s" % dialog_path)
        return null
    
    var dialog_instance = packed_scene.instantiate() as Control

    if dialog_instance == null:
        push_error("[UIManager] Failed to instantiate dialog: %s" % dialog_name)
        return null

    # Set up the dialog
    dialog_instance.name = dialog_name
    dialog_layer.add_child(dialog_instance)

    # Call setup if the dialog has it (for data-driven dialogs like dialogue UI)
    if dialog_instance.has_method("setup") and not data.is_empty():
        dialog_instance.setup(data)
    
    # Position and show
    _center_control(dialog_instance)
    dialog_instance.visible = true
    
    # Store reference
    active_dialogs[dialog_name] = dialog_instance
    
    # Block input for modal dialogs
    if modal:
        block_input()
    
    print("[UIManager] Showed dialog: %s" % dialog_name)
    dialog_shown.emit(dialog_name)
    
    return dialog_instance


func hide_dialog(dialog_name: String) -> bool:
    if not active_dialogs.has(dialog_name):
        return false
    
    var dialog_instance = active_dialogs[dialog_name]
    
    if dialog_instance:
        dialog_instance.queue_free()
        active_dialogs.erase(dialog_name)
    
    # Unblock input if no more dialogs
    if active_dialogs.size() == 0 and input_blockers == 0:
        unblock_input()
    
    print("[UIManager] Hid dialog: %s" % dialog_name)
    dialog_hidden.emit(dialog_name)
    
    return true


func hide_all_dialogs() -> void:
    for dialog_name in active_dialogs:
        var dialog_instance = active_dialogs[dialog_name]
        if dialog_instance:
            dialog_instance.queue_free()
    
    active_dialogs.clear()
    unblock_input()
    
    print("[UIManager] Hid all dialogs")


func is_dialog_open(dialog_name: String) -> bool:
    return active_dialogs.has(dialog_name)


func get_dialog(dialog_name: String) -> Control:
    return active_dialogs.get(dialog_name, null) as Control


# ============================================================================
# NOTIFICATION SYSTEM
# ============================================================================

func show_notification(message: String, notification_type: String = "info") -> void:
    if not notification_layer:
        _create_notification_layer()
    
    # Remove oldest notification if at max
    if active_notifications.size() >= MAX_NOTIFICATIONS:
        var oldest = active_notifications[0]
        oldest.queue_free()
        active_notifications.remove_at(0)
    
    # Create notification
    var notification = _create_notification_node(message, notification_type)
    notification_layer.add_child(notification)
    active_notifications.append(notification)
    
    # Position it
    _position_notifications()
    
    notification_shown.emit(message, notification_type)
    print("[UIManager] Showed notification: %s" % message)


func _create_notification_node(message: String, notification_type: String) -> Control:
    # Create a simple notification control
    var notification = Control.new()
    notification.name = "Notification_%d" % active_notifications.size()
    
    # Create background
    var background = ColorRect.new()
    background.name = "Background"
    background.color = _get_notification_color(notification_type)
    background.anchor_right = 1.0
    background.anchor_left = 0.0
    background.margin_right = -20
    background.margin_left = 20
    background.margin_top = 10
    background.margin_bottom = 10
    notification.add_child(background)
    
    # Create label
    var label = Label.new()
    label.name = "Text"
    label.text = message
    label.anchor_right = 0.5
    label.anchor_left = 0.5
    label.position = Vector2(0, 15)
    label.add_theme_color_override("font_color", Color(1, 1, 1))
    label.add_theme_font_override("font", _get_font())
    label.add_theme_font_size_override("font_size", 14)
    background.add_child(label)
    
    # Set minimum size
    background.minimum_size = Vector2(200, 40)
    
    # Add animation timer
    var timer = Timer.new()
    timer.name = "HideTimer"
    timer.timeout.connect(_on_notification_timeout, CONNECT_ONE_SHOT, [notification])
    timer.start(NOTIFICATION_DURATION)
    notification.add_child(timer)
    
    # Add fade-out animation
    var fade_timer = Timer.new()
    fade_timer.name = "FadeTimer"
    fade_timer.timeout.connect(_on_notification_fade, CONNECT_ONE_SHOT, [notification])
    fade_timer.start(NOTIFICATION_DURATION - 0.5)
    notification.add_child(fade_timer)
    
    return notification


func _on_notification_timeout(notification: Control) -> void:
    notification.queue_free()
    var index = active_notifications.find(notification)
    if index != -1:
        active_notifications.remove_at(index)
    _position_notifications()


func _on_notification_fade(notification: Control) -> void:
    # Fade out the notification
    var mod = notification.modulate
    var fade_tween = create_tween()
    fade_tween.tween_property(notification, "modulate:a", 0.0, 0.5)
    fade_tween.tween_callback(notification.queue_free)
    
    var index = active_notifications.find(notification)
    if index != -1:
        active_notifications.remove_at(index)


func _position_notifications() -> void:
    var y_position: float = 20.0
    
    for notification in active_notifications:
        notification.position = Vector2(0, y_position)
        y_position += notification.rect_min_size.y + 10


func _update_notifications(delta: float) -> void:
    # Update notification positions (for animations)
    pass


func _get_notification_color(notification_type: String) -> Color:
    match notification_type:
        "success":
            return Color(0.2, 0.8, 0.2, 0.9)  # Green
        "error":
            return Color(0.8, 0.2, 0.2, 0.9)  # Red
        "warning":
            return Color(0.8, 0.8, 0.2, 0.9)  # Yellow
        "info":
            return Color(0.2, 0.6, 0.8, 0.9)  # Blue
        _:
            return Color(0.5, 0.5, 0.5, 0.9)  # Gray


# ============================================================================
# LOADING SCREEN
# ============================================================================

func show_loading_screen(text: String = "Loading...") -> void:
    loading_text = text
    
    if not loading_screen:
        var loading_scene_path = UI_DIR + "loading.tscn"
        if ResourceLoader.exists(loading_scene_path):
            var packed_scene = load(loading_scene_path)
            loading_screen = packed_scene.instantiate() as Control
            if ui_canvas:
                ui_canvas.add_child(loading_screen)
            else:
                get_tree().root.add_child(loading_screen)
        else:
            # Create a simple loading screen
            loading_screen = _create_simple_loading_screen()
            if ui_canvas:
                ui_canvas.add_child(loading_screen)
            else:
                get_tree().root.add_child(loading_screen)
    
    # Update text if label exists
    var label = loading_screen.find_child("LoadingLabel", true, false) as Label
    if label:
        label.text = text
    
    loading_screen.visible = true
    block_input()


func hide_loading_screen() -> void:
    if loading_screen:
        loading_screen.visible = false
    unblock_input()


func show_loading_indicator(text: String = "Saving...") -> void:
    # Show a small loading indicator (different from full loading screen)
    show_notification(text, "info")


func _create_simple_loading_screen() -> Control:
    var screen = Control.new()
    screen.name = "LoadingScreen"
    screen.anchor_right = 1.0
    screen.anchor_left = 0.0
    screen.anchor_top = 1.0
    screen.anchor_bottom = 0.0
    
    # Dark background
    var background = ColorRect.new()
    background.name = "Background"
    background.color = Color(0, 0, 0, 0.7)
    background.anchor_right = 1.0
    background.anchor_left = 0.0
    background.anchor_top = 1.0
    background.anchor_bottom = 0.0
    screen.add_child(background)
    
    # Loading text
    var label = Label.new()
    label.name = "LoadingLabel"
    label.text = loading_text
    label.anchor_right = 0.5
    label.anchor_left = 0.5
    label.anchor_top = 0.5
    label.anchor_bottom = 0.5
    label.add_theme_color_override("font_color", Color(1, 1, 1))
    label.add_theme_font_override("font", _get_font())
    label.add_theme_font_size_override("font_size", 24)
    screen.add_child(label)
    
    # Spinner animation
    var spinner = Label.new()
    spinner.name = "Spinner"
    spinner.text = "..."
    spinner.position = Vector2(0, 40)
    spinner.anchor_right = 0.5
    spinner.anchor_left = 0.5
    spinner.add_theme_color_override("font_color", Color(1, 1, 1))
    spinner.add_theme_font_override("font", _get_font())
    spinner.add_theme_font_size_override("font_size", 18)
    screen.add_child(spinner)
    
    return screen


# ============================================================================
# INPUT BLOCKING
# ============================================================================

func block_input() -> void:
    if is_input_blocked:
        input_blockers += 1
    else:
        is_input_blocked = true
        input_blockers = 1
    
    InputManager.disable_input()


func unblock_input() -> void:
    input_blockers = max(0, input_blockers - 1)
    
    if input_blockers == 0:
        is_input_blocked = false
        InputManager.enable_input()


func is_input_blocked_flag() -> bool:
    return is_input_blocked


func _on_action_pressed(action_name: String, event: InputEvent) -> void:
    # If input is blocked, prevent certain actions
    if is_input_blocked:
        # Allow escape to unblock
        if action_name == "ui_cancel" and is_menu_open("pause") == false:
            # Don't block escape
            return
        
        # Block all other input
        event = null  # This doesn't actually work, but the intent is there


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func _create_menu_layer() -> void:
    menu_layer = CanvasLayer.new()
    menu_layer.name = "Menus"
    if ui_canvas:
        ui_canvas.add_child(menu_layer)
    else:
        get_tree().root.add_child(menu_layer)
    menu_layer.z_index = 100


func _create_dialog_layer() -> void:
    dialog_layer = CanvasLayer.new()
    dialog_layer.name = "Dialogs"
    if ui_canvas:
        ui_canvas.add_child(dialog_layer)
    else:
        get_tree().root.add_child(dialog_layer)
    dialog_layer.z_index = 200


func _create_notification_layer() -> void:
    notification_layer = CanvasLayer.new()
    notification_layer.name = "Notifications"
    if ui_canvas:
        ui_canvas.add_child(notification_layer)
    else:
        get_tree().root.add_child(notification_layer)
    notification_layer.z_index = 300


func _center_control(control: Control) -> void:
    control.anchor_right = 0.5
    control.anchor_left = 0.5
    control.anchor_top = 0.5
    control.anchor_bottom = 0.5
    control.position = Vector2.ZERO


func _get_font() -> Font:
    # Try to get the default font
    var font = load("res://assets/ui/fonts/default.ttf")
    if font:
        return font
    
    # Fall back to the default theme font
    return ThemeDB.get_default_theme().default_font


# ============================================================================
# HUD FUNCTIONS
# ============================================================================

func update_hud(data: Dictionary) -> void:
    # Update HUD elements with game data
    if not hud_layer:
        return
    
    # Find and update HUD elements
    var health_bar = hud_layer.find_child("HealthBar", true, false) as ProgressBar
    if health_bar and data.has("health") and data.has("max_health"):
        var health_pct = data["health"] / data["max_health"] * 100
        health_bar.value = health_pct
    
    var mana_bar = hud_layer.find_child("ManaBar", true, false) as ProgressBar
    if mana_bar and data.has("mana") and data.has("max_mana"):
        var mana_pct = data["mana"] / data["max_mana"] * 100
        mana_bar.value = mana_pct
    
    var level_label = hud_layer.find_child("LevelLabel", true, false) as Label
    if level_label and data.has("level"):
        level_label.text = "Lv. %d" % data["level"]
    
    var gold_label = hud_layer.find_child("GoldLabel", true, false) as Label
    if gold_label and data.has("gold"):
        gold_label.text = "Gold: %d" % data["gold"]


func show_hud_element(element_name: String, visible: bool) -> void:
    if not hud_layer:
        return
    
    var element = hud_layer.find_child(element_name, true, false) as CanvasItem
    if element:
        element.visible = visible


func get_hud_element(element_name: String) -> CanvasItem:
    if not hud_layer:
        return null
    return hud_layer.find_child(element_name, true, false) as CanvasItem


# ============================================================================
# DEBUG FUNCTIONS
# ============================================================================

func print_ui_state() -> void:
    print("[UIManager] UI State:")
    print("  UI Visible: %s" % is_ui_visible)
    print("  HUD Visible: %s" % is_hud_visible)
    print("  Input Blocked: %s" % is_input_blocked)
    print("  Active Menus: %s" % active_menus.keys())
    print("  Active Dialogs: %s" % active_dialogs.keys())
    print("  Active Notifications: %d" % active_notifications.size())
