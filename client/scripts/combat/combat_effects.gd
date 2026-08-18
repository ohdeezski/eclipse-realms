extends Node2D
class_name CombatEffects
## CombatEffects.gd - Visual effects for combat (hit flashes, particles,
## screen shake, slash trails, guard aura, screen flash).

## Screen shake
var _shake_intensity: float = 0.0
var _shake_decay: float = 5.0
var _shake_offset: Vector2 = Vector2.ZERO

## Flash overlay reference
var _screen_flash_rect: ColorRect = null
var _screen_flash_layer: CanvasLayer = null

## Flash colors
const HIT_FLASH_COLOR: Color = Color(1.0, 0.3, 0.3, 0.8)
const CRIT_FLASH_COLOR: Color = Color(1.0, 0.8, 0.0, 0.9)
const HEAL_FLASH_COLOR: Color = Color(0.3, 1.0, 0.3, 0.7)
const GUARD_FLASH_COLOR: Color = Color(0.4, 0.6, 1.0, 0.6)


func _process(delta: float) -> void:
    # Update screen shake with smooth damping
    if _shake_intensity > 0.0:
        _shake_intensity = lerpf(_shake_intensity, 0.0, _shake_decay * delta)
        if _shake_intensity < 0.1:
            _shake_intensity = 0.0
            _shake_offset = Vector2.ZERO

        var camera = get_viewport().get_camera_2d()
        if camera:
            _shake_offset = Vector2(
                randf_range(-1.0, 1.0) * _shake_intensity,
                randf_range(-1.0, 1.0) * _shake_intensity
            )
            camera.offset = camera.offset + _shake_offset


# ============================================================================
# DAMAGE NUMBERS
# ============================================================================

## Spawn a floating damage number at position
func spawn_damage_number(pos: Vector2, amount: int, crit: bool = false, heal: bool = false) -> void:
    var dmg_num = DamageNumber.new()
    dmg_num.position = pos + Vector2(randf_range(-8, 8), -20)

    # Create label node
    var label = Label.new()
    label.name = "Label"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 16 if not crit else 22)
    dmg_num.add_child(label)

    # Add to scene
    get_tree().current_scene.add_child(dmg_num)
    dmg_num.setup(amount, crit, heal)


# ============================================================================
# HIT FLASH EFFECTS
# ============================================================================

## Spawn hit flash on a target with smooth tween
func spawn_hit_flash(target: Node2D, color: Color = HIT_FLASH_COLOR, duration: float = 0.1) -> void:
    if not target or not target.has_node("Sprite"):
        return

    var sprite = target.get_node("Sprite") as CanvasItem
    if not sprite:
        return

    var original_modulate = sprite.modulate
    sprite.modulate = color

    var tween = create_tween()
    tween.tween_property(sprite, "modulate", original_modulate, duration).set_ease(Tween.EASE_OUT)
    tween.tween_callback(tween.kill)


## Spawn crit flash (more dramatic with scale punch)
func spawn_crit_flash(target: Node2D) -> void:
    if not target or not target.has_node("Sprite"):
        return

    var sprite = target.get_node("Sprite") as CanvasItem
    if not sprite:
        return

    var original_modulate = sprite.modulate
    var original_scale = sprite.scale

    var tween = create_tween()
    # Quick scale punch
    tween.tween_property(sprite, "scale", original_scale * 1.25, 0.05).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(sprite, "modulate", CRIT_FLASH_COLOR, 0.05)
    tween.tween_property(sprite, "scale", original_scale, 0.15).set_ease(Tween.EASE_IN_OUT)
    tween.parallel().tween_property(sprite, "modulate", original_modulate, 0.15)
    tween.tween_callback(tween.kill)


## Spawn heal flash with glow
func spawn_heal_flash(target: Node2D) -> void:
    spawn_hit_flash(target, HEAL_FLASH_COLOR, 0.2)


## Spawn guard block flash
func spawn_guard_flash(target: Node2D) -> void:
    if not target or not target.has_node("Sprite"):
        return

    var sprite = target.get_node("Sprite") as CanvasItem
    if not sprite:
        return

    var original_modulate = sprite.modulate
    var tween = create_tween()
    # Pulsing blue guard flash
    tween.tween_property(sprite, "modulate", GUARD_FLASH_COLOR, 0.06)
    tween.tween_property(sprite, "modulate", original_modulate * Color(0.8, 0.85, 1.2, 1.0), 0.1)
    tween.tween_property(sprite, "modulate", original_modulate, 0.15)
    tween.tween_callback(tween.kill)


# ============================================================================
# SCREEN EFFECTS
# ============================================================================

## Apply screen shake
func apply_screen_shake(intensity: float = 3.0, duration: float = 0.2) -> void:
    _shake_intensity = max(_shake_intensity, intensity)
    # Decay rate derived from duration: faster shake = shorter duration
    _shake_decay = intensity / max(duration, 0.05)


## Brief screen-wide color flash overlay
func spawn_screen_flash(color: Color = Color(1.0, 1.0, 1.0, 0.15), duration: float = 0.12) -> void:
    if _screen_flash_rect and is_instance_valid(_screen_flash_rect):
        return  # already flashing

    if not _screen_flash_layer:
        _screen_flash_layer = CanvasLayer.new()
        _screen_flash_layer.layer = 10
        get_tree().current_scene.add_child(_screen_flash_layer)

    _screen_flash_rect = ColorRect.new()
    _screen_flash_rect.color = color
    _screen_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    _screen_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _screen_flash_layer.add_child(_screen_flash_rect)

    var tween = create_tween()
    tween.tween_property(_screen_flash_rect, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
    tween.tween_callback(_cleanup_screen_flash)


func _cleanup_screen_flash() -> void:
    if _screen_flash_rect and is_instance_valid(_screen_flash_rect):
        _screen_flash_rect.queue_free()
        _screen_flash_rect = null


# ============================================================================
# PARTICLE EFFECTS
# ============================================================================

## Spawn hit particles at position with size/direction variety
func spawn_hit_particles(pos: Vector2, color: Color = Color.WHITE) -> void:
    for i in range(8):
        var size = randf_range(3.0, 6.0)
        var particle = _create_hit_particle(pos, color, size)
        get_tree().current_scene.add_child(particle)

        var angle = randf() * PI * 2
        var speed = randf_range(100.0, 200.0)
        var dir = Vector2(cos(angle), sin(angle))
        var travel = dir * speed * 0.25

        var tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(particle, "position", particle.position + travel, 0.25).set_ease(Tween.EASE_OUT)
        tween.tween_property(particle, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
        # Shrink as they fade
        tween.tween_property(particle, "scale", Vector2.ZERO, 0.3).set_ease(Tween.EASE_IN)
        tween.chain().tween_callback(particle.queue_free)


## Spawn crit particles (bigger, golden, more dramatic spread)
func spawn_crit_particles(pos: Vector2) -> void:
    var crit_color = Color(1.0, 0.85, 0.2)
    for i in range(14):
        var size = randf_range(4.0, 8.0)
        var particle = _create_hit_particle(pos, crit_color, size)
        get_tree().current_scene.add_child(particle)

        var angle = (i / 14.0) * PI * 2 + randf_range(-0.2, 0.2)
        var speed = randf_range(120.0, 240.0)
        var dir = Vector2(cos(angle), sin(angle))
        var travel = dir * speed * 0.3

        var tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(particle, "position", particle.position + travel, 0.3).set_ease(Tween.EASE_OUT)
        tween.tween_property(particle, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
        tween.tween_property(particle, "scale", Vector2.ZERO, 0.35).set_ease(Tween.EASE_IN)
        tween.chain().tween_callback(particle.queue_free)


func _create_hit_particle(pos: Vector2, color: Color, size: float = 4.0) -> Node2D:
    var particle = Node2D.new()
    particle.position = pos

    var rect = ColorRect.new()
    rect.color = color
    rect.size = Vector2(size, size)
    rect.position = Vector2(-size / 2.0, -size / 2.0)
    particle.add_child(rect)

    return particle


## Spawn death explosion effect with ring + scatter
func spawn_death_effect(pos: Vector2, color: Color = Color(1.0, 0.5, 0.0)) -> void:
    var scene := get_tree().current_scene
    if scene == null:
        return
    # Inner burst ring
    for i in range(10):
        var size = randf_range(3.0, 5.0)
        var particle = _create_hit_particle(pos, color, size)
        scene.add_child(particle)

        var angle = (i / 10.0) * PI * 2
        var dir = Vector2(cos(angle), sin(angle))
        var distance = randf_range(25.0, 45.0)

        var tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(particle, "position", pos + dir * distance, 0.35).set_ease(Tween.EASE_OUT)
        tween.tween_property(particle, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
        tween.tween_property(particle, "scale", Vector2(0.2, 0.2), 0.35)
        tween.chain().tween_callback(particle.queue_free)

    # Outer scatter particles
    for i in range(6):
        var particle = _create_hit_particle(pos, color.lerp(Color.WHITE, 0.3), randf_range(2.0, 3.0))
        scene.add_child(particle)

        var angle = randf() * PI * 2
        var dir = Vector2(cos(angle), sin(angle))

        var tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(particle, "position", pos + dir * randf_range(50.0, 70.0), 0.45).set_ease(Tween.EASE_OUT)
        tween.tween_property(particle, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
        tween.chain().tween_callback(particle.queue_free)


# ============================================================================
# SLASH EFFECT
# ============================================================================

## Spawn slash effect at position facing direction
func spawn_slash_effect(pos: Vector2, direction: Vector2) -> void:
    var arc = Node2D.new()
    arc.position = pos

    var base_angle = direction.angle()
    var segment_count = 6
    var spread = 0.4  # radians spread of the arc

    for i in range(segment_count):
        var t = float(i) / float(segment_count - 1)
        var angle = base_angle + (t - 0.5) * spread * 2.0
        var dist = 18.0 + t * 12.0

        var segment = ColorRect.new()
        # Color fades from bright white at center to transparent at edges
        var alpha = 1.0 - abs(t - 0.5) * 1.6
        segment.color = Color(1.0, 1.0, 1.0, max(0.3, alpha) * 0.9)
        segment.size = Vector2(10.0, 2.0)
        segment.position = Vector2(cos(angle) * dist - 5, sin(angle) * dist - 1)
        segment.rotation = angle
        arc.add_child(segment)

    get_tree().current_scene.add_child(arc)

    # Quick fade and slight scale outward
    var tween = create_tween()
    tween.tween_property(arc, "modulate:a", 0.0, 0.12).set_ease(Tween.EASE_IN)
    tween.parallel().tween_property(arc, "scale", Vector2(1.3, 1.3), 0.12).set_ease(Tween.EASE_OUT)
    tween.tween_callback(arc.queue_free)


# ============================================================================
# GUARD AURA EFFECT
# ============================================================================

## Spawn a temporary shield/aura around the player when guarding
func spawn_guard_aura(parent: Node2D, duration: float = 0.4) -> void:
    var aura = Node2D.new()
    aura.position = Vector2.ZERO
    parent.add_child(aura)

    # Create 4 arc segments forming a shield
    var segments = []
    for i in range(4):
        var rect = ColorRect.new()
        rect.color = Color(0.4, 0.6, 1.0, 0.5)
        rect.size = Vector2(12, 3)
        var angle = (i / 4.0) * PI * 2
        rect.position = Vector2(cos(angle) * 18 - 6, sin(angle) * 18 - 1.5)
        rect.rotation = angle
        aura.add_child(rect)
        segments.append(rect)

    # Pulse and fade
    var tween = create_tween()
    tween.tween_property(aura, "scale", Vector2(1.2, 1.2), duration * 0.3).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(aura, "modulate:a", 0.3, duration).set_ease(Tween.EASE_IN)
    tween.tween_callback(aura.queue_free)
