extends Node2D
class_name DamageNumber
## DamageNumber.gd - Floating damage/heal text for combat feedback.
## Features: pop-in bounce, wobble drift, crit drama, outline shadow.

## Configuration
const FLOAT_SPEED: float = 55.0
const FADE_START: float = 0.6  # fraction of lifetime when fade begins
const LIFETIME: float = 1.4
const CRIT_SCALE: float = 1.6
const CRIT_COLOR: Color = Color(1.0, 0.8, 0.0)  # Gold for crits
const NORMAL_COLOR: Color = Color(1.0, 1.0, 1.0)
const HEAL_COLOR: Color = Color(0.2, 1.0, 0.2)  # Green for heals

## Node references
@onready var label: Label = $Label

## State
var value: int = 0
var is_critical: bool = false
var is_heal: bool = false
var lifetime: float = 0.0
var alpha: float = 1.0
var _wobble_speed: float = 0.0
var _wobble_amount: float = 0.0
var _pop_scale: float = 0.0
var _target_scale: float = 1.0
var _drift_x: float = 0.0


func _ready() -> void:
    # Random horizontal offset for visual variety
    position.x += randf_range(-10.0, 10.0)
    _drift_x = randf_range(-8.0, 8.0)
    _wobble_speed = randf_range(10.0, 16.0)
    _wobble_amount = randf_range(3.0, 7.0)

    # Start at zero scale for pop-in
    _pop_scale = 0.0
    scale = Vector2.ZERO


func _process(delta: float) -> void:
    lifetime += delta

    # --- Pop-in bounce (spring towards target scale) ---
    var spring_speed = 14.0 if not is_critical else 10.0
    _pop_scale = lerpf(_pop_scale, _target_scale, spring_speed * delta)
    # Overshoot: bump target above 1.0 briefly, then settle
    if lifetime < 0.15:
        _target_scale = 1.3 if not is_critical else 1.8
    elif lifetime < 0.3:
        _target_scale = 1.0
    scale = Vector2(_pop_scale, _pop_scale)

    # --- Float upward ---
    position.y -= FLOAT_SPEED * delta

    # --- Gentle horizontal wobble ---
    position.x += sin(lifetime * _wobble_speed) * _wobble_amount * delta

    # --- Fade out in last portion ---
    var fade_start_time = LIFETIME * FADE_START
    if lifetime > fade_start_time:
        alpha -= delta / (LIFETIME - fade_start_time)
        alpha = max(0.0, alpha)
        if label:
            label.modulate.a = alpha

    # --- Gentle rotation wobble for crits ---
    if is_critical:
        rotation = sin(lifetime * 8.0) * 0.08

    # Remove when done
    if lifetime >= LIFETIME:
        queue_free()


func setup(amount: int, crit: bool = false, heal: bool = false) -> void:
    value = amount
    is_critical = crit
    is_heal = heal

    if label:
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

        if is_heal:
            label.text = "+%d" % amount
            label.modulate = HEAL_COLOR
            _target_scale = 1.0
        elif is_critical:
            label.text = "%d!" % amount
            label.modulate = CRIT_COLOR
            _target_scale = 1.6
            # Add outline for crit readability
            label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
            label.add_theme_constant_override("outline_size", 3)
        else:
            label.text = str(amount)
            label.modulate = NORMAL_COLOR
            _target_scale = 1.0
            # Subtle outline for normal readability
            label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.6))
            label.add_theme_constant_override("outline_size", 2)
