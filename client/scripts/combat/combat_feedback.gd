extends CanvasLayer
class_name CombatFeedback
## CombatFeedback.gd - HUD overlay for combat info (combo counter, kill feed, etc.)
## Enhanced with color-cycling, dramatic scale, and high-combo screen shake.

## Signals
signal combo_ended(count: int)

## Combo tracking
var _combo_count: int = 0
var _combo_timer: float = 0.0
const COMBO_TIMEOUT: float = 1.5
const MAX_COMBO_DISPLAY: int = 99

## Combo color tiers
const COMBO_COLORS: Array[Color] = [
    Color(1.0, 1.0, 1.0),       # 1-2: white
    Color(1.0, 0.9, 0.2),       # 3-4: yellow
    Color(1.0, 0.6, 0.1),       # 5-6: orange
    Color(1.0, 0.3, 0.3),       # 7-8: red
    Color(0.7, 0.3, 1.0),       # 9+: purple
]
const COMBO_TIER_THRESHOLDS: Array[int] = [3, 5, 7, 9]

## Kill feed
var _kill_feed: Array = []
const MAX_KILL_FEED: int = 5
const KILL_FEED_DURATION: float = 4.0

## Node references
@onready var combo_label: Label = $ComboContainer/ComboLabel if has_node("ComboContainer/ComboLabel") else null
@onready var combo_container: Control = $ComboContainer if has_node("ComboContainer") else null
@onready var kill_feed_container: VBoxContainer = $KillFeedContainer if has_node("KillFeedContainer") else null


func _ready() -> void:
    if not combo_container:
        _create_combo_ui()
    if not kill_feed_container:
        _create_kill_feed_ui()


func _process(delta: float) -> void:
    if _combo_count > 0:
        _combo_timer -= delta
        if _combo_timer <= 0.0:
            _end_combo()


# ============================================================================
# UI CREATION
# ============================================================================

func _create_combo_ui() -> void:
    combo_container = Control.new()
    combo_container.name = "ComboContainer"
    combo_container.anchors_preset = Control.PRESET_TOP_RIGHT
    combo_container.anchor_left = 0.7
    combo_container.anchor_top = 0.1
    combo_container.anchor_right = 0.95
    combo_container.anchor_bottom = 0.25
    combo_container.offset_left = 0
    combo_container.offset_top = 0
    combo_container.offset_right = 0
    combo_container.offset_bottom = 0
    add_child(combo_container)

    combo_label = Label.new()
    combo_label.name = "ComboLabel"
    combo_label.anchor_right = 1.0
    combo_label.anchor_bottom = 1.0
    combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    combo_label.add_theme_font_size_override("font_size", 32)
    combo_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
    combo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
    combo_label.add_theme_constant_override("shadow_offset_x", 2)
    combo_label.add_theme_constant_override("shadow_offset_y", 2)
    combo_label.visible = false
    combo_container.add_child(combo_label)


func _create_kill_feed_ui() -> void:
    kill_feed_container = VBoxContainer.new()
    kill_feed_container.name = "KillFeedContainer"
    kill_feed_container.anchors_preset = Control.PRESET_TOP_RIGHT
    kill_feed_container.anchor_left = 0.6
    kill_feed_container.anchor_top = 0.3
    kill_feed_container.anchor_right = 0.95
    kill_feed_container.anchor_bottom = 0.6
    kill_feed_container.offset_left = 0
    kill_feed_container.offset_top = 0
    kill_feed_container.offset_right = 0
    kill_feed_container.offset_bottom = 0
    kill_feed_container.alignment = BoxContainer.ALIGNMENT_END
    add_child(kill_feed_container)


# ============================================================================
# COMBO SYSTEM
# ============================================================================

## Register a hit for the combo system
func register_hit(damage: int, enemy_name: String = "") -> void:
    _combo_count += 1
    _combo_timer = COMBO_TIMEOUT

    if _combo_count >= 2:
        _update_combo_display()

    GameManager.log_event("combat_hit", {
        "combo": _combo_count,
        "damage": damage,
        "enemy": enemy_name
    })


## Register a kill
func register_kill(enemy_name: String, experience: int = 0, gold: int = 0) -> void:
    var kill_text = "Defeated %s" % enemy_name
    if experience > 0:
        kill_text += " (+%d XP)" % experience
    _add_kill_feed_entry(kill_text)

    if _combo_count > 0:
        _end_combo()


## Update the combo display with color tier and scale animation
func _update_combo_display() -> void:
    if not combo_label:
        return

    combo_label.visible = true
    var display_count = min(_combo_count, MAX_COMBO_DISPLAY)
    combo_label.text = "%d COMBO!" % display_count

    # Determine color tier
    var color = COMBO_COLORS[0]
    for i in range(COMBO_TIER_THRESHOLDS.size()):
        if _combo_count >= COMBO_TIER_THRESHOLDS[i]:
            color = COMBO_COLORS[i + 1]
    combo_label.add_theme_color_override("font_color", color)

    # Scale punch animation (bigger punch for higher combos)
    var punch_scale = 1.2 + min(_combo_count * 0.03, 0.5)
    var tween = create_tween()
    tween.tween_property(combo_label, "scale", Vector2(punch_scale, punch_scale), 0.08).set_ease(Tween.EASE_OUT)
    tween.tween_property(combo_label, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_IN_OUT)

    # Screen shake on big combos (5+)
    if _combo_count >= 5:
        var camera = get_viewport().get_camera_2d()
        if camera:
            # Find CombatEffects on the player
            var players = get_tree().get_nodes_in_group("player")
            if players.size() > 0 and players[0].has_node("CombatEffects"):
                var fx = players[0].get_node("CombatEffects") as CombatEffects
                if fx:
                    var shake_amount = min(_combo_count * 0.3, 3.0)
                    fx.apply_screen_shake(shake_amount, 0.1)


## End the combo
func _end_combo() -> void:
    if _combo_count > 1:
        combo_ended.emit(_combo_count)
        GameManager.log_event("combo_ended", {"count": _combo_count})

    _combo_count = 0
    _combo_timer = 0.0

    if combo_label:
        # Fade out and shrink
        var tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(combo_label, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
        tween.tween_property(combo_label, "scale", Vector2(0.8, 0.8), 0.3).set_ease(Tween.EASE_IN)
        tween.chain().tween_callback(func():
            combo_label.visible = false
            combo_label.modulate.a = 1.0
            combo_label.scale = Vector2.ONE
        )


# ============================================================================
# KILL FEED
# ============================================================================

func _add_kill_feed_entry(text: String) -> void:
    if not kill_feed_container:
        return

    if _kill_feed.size() >= MAX_KILL_FEED:
        var oldest = _kill_feed[0]
        _kill_feed.remove_at(0)
        oldest.queue_free()

    var label = Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", 14)
    label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 1)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    label.modulate.a = 0.0
    # Start slightly to the right for slide-in
    label.position.x = 30

    kill_feed_container.add_child(label)
    _kill_feed.append(label)

    # Slide-in + fade-in animation
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
    tween.tween_property(label, "position:x", 0, 0.25).set_ease(Tween.EASE_OUT)

    # Schedule removal
    var timer = Timer.new()
    timer.one_shot = true
    timer.wait_time = KILL_FEED_DURATION
    timer.timeout.connect(_remove_kill_feed_entry.bind(label))
    label.add_child(timer)
    timer.start()


func _remove_kill_feed_entry(label: Label) -> void:
    if not is_instance_valid(label):
        return

    # Slide out + fade out
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
    tween.tween_property(label, "position:x", 20, 0.3).set_ease(Tween.EASE_IN)
    tween.chain().tween_callback(func():
        var index = _kill_feed.find(label)
        if index != -1:
            _kill_feed.remove_at(index)
        label.queue_free()
    )


# ============================================================================
# PUBLIC API
# ============================================================================

## Get current combo count
func get_combo_count() -> int:
    return _combo_count


## Reset combo (e.g., on player hit)
func reset_combo() -> void:
    _combo_count = 0
    _combo_timer = 0.0
    if combo_label:
        combo_label.visible = false
        combo_label.scale = Vector2.ONE
