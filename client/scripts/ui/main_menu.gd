extends Control
## MainMenu.gd - Wires the main menu buttons to real actions.
## Supports: New Game, Continue (if save exists), Settings, Quit.
## Features: entrance cascade animation, button hover/press effects, title glow.

@onready var new_game_btn: Button = $VBoxContainer/NewGameButton
@onready var settings_btn: Button = $VBoxContainer/SettingsButton
@onready var quit_btn: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var version_label: Label = $VersionLabel

## Hover animation constants
const HOVER_SCALE: float = 1.06
const HOVER_TINT: Color = Color(1.15, 1.1, 0.95)
const PRESS_SCALE: float = 0.95
const ANIM_SPEED: float = 0.12

## Title glow constants
const TITLE_GLOW_COLOR: Color = Color(0.85, 0.95, 1.0, 1.0)
const TITLE_BASE_COLOR: Color = Color(0.9, 0.9, 0.9, 1.0)


func _ready() -> void:
    # Check for existing save to toggle Settings -> Continue
    if SaveManager.has_save(0):
        settings_btn.text = "Continue"
    else:
        settings_btn.text = "Settings"

    # Connect buttons
    new_game_btn.pressed.connect(_on_new_game)
    settings_btn.pressed.connect(_on_settings)
    quit_btn.pressed.connect(_on_quit)

    # Set game state
    GameManager.change_state(GameManager.GameState.MAIN_MENU)

    # Play menu music
    AudioManager.play_music("main_menu")

    # Hide everything for entrance animation
    title_label.modulate.a = 0.0
    title_label.position.y -= 20
    new_game_btn.modulate.a = 0.0
    new_game_btn.position.y += 30
    settings_btn.modulate.a = 0.0
    settings_btn.position.y += 30
    quit_btn.modulate.a = 0.0
    quit_btn.position.y += 30
    version_label.modulate.a = 0.0

    # Setup hover effects for all buttons
    _setup_button_effects(new_game_btn)
    _setup_button_effects(settings_btn)
    _setup_button_effects(quit_btn)

    # Run entrance cascade animation
    call_deferred("_play_entrance_animation")


# ============================================================================
# ENTRANCE ANIMATION
# ============================================================================

func _play_entrance_animation() -> void:
    var tween = create_tween()
    tween.set_parallel(false)  # Sequential by default

    # 1) Title slides down and fades in
    tween.set_parallel(true)
    tween.tween_property(title_label, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
    tween.tween_property(title_label, "position:y", title_label.position.y + 20, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

    # 2) Wait a beat then cascade buttons
    tween.set_parallel(false)
    tween.tween_interval(0.2)

    # New Game button
    tween.set_parallel(true)
    tween.tween_property(new_game_btn, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
    tween.tween_property(new_game_btn, "position:y", new_game_btn.position.y - 30, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    tween.set_parallel(false)
    tween.tween_interval(0.12)

    # Settings/Continue button
    tween.set_parallel(true)
    tween.tween_property(settings_btn, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
    tween.tween_property(settings_btn, "position:y", settings_btn.position.y - 30, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    tween.set_parallel(false)
    tween.tween_interval(0.12)

    # Quit button
    tween.set_parallel(true)
    tween.tween_property(quit_btn, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
    tween.tween_property(quit_btn, "position:y", quit_btn.position.y - 30, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

    # 3) Version label fades in last
    tween.set_parallel(false)
    tween.tween_interval(0.15)
    tween.tween_property(version_label, "modulate:a", 0.7, 0.4)

    # 4) Start title glow pulse after entrance
    tween.tween_callback(_start_title_glow)


func _start_title_glow() -> void:
    if not title_label:
        return
    var glow_tween = create_tween().set_loops()
    glow_tween.tween_property(title_label, "modulate", TITLE_GLOW_COLOR, 1.5).set_ease(Tween.EASE_IN_OUT)
    glow_tween.tween_property(title_label, "modulate", TITLE_BASE_COLOR, 1.5).set_ease(Tween.EASE_IN_OUT)


# ============================================================================
# BUTTON HOVER / PRESS EFFECTS
# ============================================================================

func _setup_button_effects(btn: Button) -> void:
    btn.mouse_entered.connect(_on_button_hover.bind(btn))
    btn.mouse_exited.connect(_on_button_unhover.bind(btn))
    btn.button_down.connect(_on_button_press.bind(btn))
    btn.button_up.connect(_on_button_release.bind(btn))


func _on_button_hover(btn: Button) -> void:
    AudioManager.play_sfx("button_hover")
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(btn, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), ANIM_SPEED).set_ease(Tween.EASE_OUT)
    tween.tween_property(btn, "modulate", HOVER_TINT, ANIM_SPEED).set_ease(Tween.EASE_OUT)


func _on_button_unhover(btn: Button) -> void:
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(btn, "scale", Vector2.ONE, ANIM_SPEED).set_ease(Tween.EASE_OUT)
    tween.tween_property(btn, "modulate", Color.WHITE, ANIM_SPEED).set_ease(Tween.EASE_OUT)


func _on_button_press(btn: Button) -> void:
    var tween = create_tween()
    tween.tween_property(btn, "scale", Vector2(PRESS_SCALE, PRESS_SCALE), 0.05).set_ease(Tween.EASE_IN)


func _on_button_release(btn: Button) -> void:
    var tween = create_tween()
    tween.tween_property(btn, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), 0.1).set_ease(Tween.EASE_OUT)


# ============================================================================
# BUTTON ACTIONS
# ============================================================================

func _on_new_game() -> void:
    AudioManager.play_sfx("button_click")
    # Reset session data
    GameManager.session_data = {
        "playtime_seconds": 0.0,
        "enemies_defeated": 0,
        "items_collected": 0,
        "quests_completed": 0,
        "deaths": 0,
    }
    # Go to character creation
    SceneManager.change_scene("res://scenes/ui/character_creation.tscn", "fade")


func _on_settings() -> void:
    AudioManager.play_sfx("button_click")
    if SaveManager.has_save(0):
        # Continue: load save and go to world
        SaveManager.load_game(0)
        SceneManager.change_scene("res://scenes/world/oakrest_village.tscn", "fade")
    else:
        UIManager.show_notification("Settings coming soon.", "info")


func _on_quit() -> void:
    AudioManager.play_sfx("button_click")
    GameManager.quit_game()
