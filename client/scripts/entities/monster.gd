extends CharacterBody2D
class_name Monster
## Monster.gd - Enemy entity with combat AI for Eclipse Realms.

signal died
signal health_changed(current: int, maximum: int)
signal attacked_player(damage: int)

## Monster Configuration
var monster_id: String = "moss_slime"
var monster_name: String = "Monster"
var max_health: int = 30
var health: int = 30
var attack: int = 6
var defense: int = 1
var speed: float = 0.5
var behavior: String = "wander"
var experience_value: int = 12
var gold_value: int = 5
var drops: Array = []
var is_dead: bool = false

## Combat State
var _aggro_target: Node2D = null
var _aggro_range: float = 180.0
var _attack_range: float = 40.0
var _attack_cd: float = 0.0
var _attack_cooldown_max: float = 1.2
var _chase_speed: float = 120.0
var _wander_speed: float = 60.0
var _leash_range: float = 300.0
var _spawn_position: Vector2 = Vector2.ZERO

## Wander State
var _wander_dir := Vector2.ZERO
var _wander_timer: float = 0.0
var _wander_pause_timer: float = 0.0
var _is_paused: bool = false

## Hit Reaction
var _knockback_velocity: Vector2 = Vector2.ZERO
var _stun_timer: float = 0.0

## Node References
@onready var sprite: ColorRect = $Sprite
@onready var hp_bar: ProgressBar = $HPBar
@onready var hit_flash: Timer = $HitFlash
@onready var aggro_area: Area2D = $AggroArea if has_node("AggroArea") else null
@onready var combat_effects: CombatEffects = null


func _ready() -> void:
    add_to_group("enemy")
    _spawn_position = global_position
    
    # Initialize combat effects
    combat_effects = CombatEffects.new()
    add_child(combat_effects)
    
    # Set up HP bar
    if hp_bar:
        hp_bar.max_value = max_health
        hp_bar.value = max_health


func configure(data: Dictionary) -> void:
    monster_id = data.get("id", monster_id)
    monster_name = data.get("name", monster_name)
    var s = data.get("stats", {})
    max_health = int(s.get("health", max_health))
    health = max_health
    attack = int(s.get("attack", attack))
    defense = int(s.get("defense", defense))
    speed = float(s.get("speed", speed))
    experience_value = int(s.get("experience", experience_value))
    gold_value = int(s.get("gold", gold_value))
    behavior = data.get("behavior", behavior)
    drops = data.get("drops", [])
    
    # Set aggro range based on behavior
    match behavior:
        "chase":
            _aggro_range = 180.0
            _chase_speed = 120.0
        "aggressive":
            _aggro_range = 220.0
            _chase_speed = 140.0
        "passive":
            _aggro_range = 100.0
            _chase_speed = 80.0
        _:
            _aggro_range = 150.0
    
    if hp_bar:
        hp_bar.max_value = max_health
        hp_bar.value = max_health
    if sprite:
        sprite.position = Vector2(-16, -16)


func _physics_process(delta: float) -> void:
    if is_dead:
        return
    
    # Update cooldowns
    _attack_cd -= delta
    _stun_timer -= delta
    
    # Apply knockback
    if _knockback_velocity.length() > 1.0:
        _knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 10.0)
        velocity = _knockback_velocity
        move_and_slide()
        return
    
    # Stunned - can't act
    if _stun_timer > 0.0:
        return
    
    # Get player
    var player = _get_player()
    
    # Aggro logic
    _update_aggro(player)
    
    # State machine
    if _aggro_target and is_instance_valid(_aggro_target):
        _chase_target(delta)
    else:
        _wander(delta)


func _update_aggro(player) -> void:
    if not player:
        _aggro_target = null
        return
    
    # Check if already aggroed
    if _aggro_target and is_instance_valid(_aggro_target):
        var dist_to_target = global_position.distance_to(_aggro_target.global_position)
        # Leash check
        if dist_to_target > _leash_range:
            _aggro_target = null
            return
        # Switch to player if closer
        var dist_to_player = global_position.distance_to(player.global_position)
        if dist_to_player < _aggro_range and dist_to_player < dist_to_target:
            _aggro_target = player
        return
    
    # Check for new aggro
    var dist = global_position.distance_to(player.global_position)
    if dist < _aggro_range and not player.is_dead:
        _aggro_target = player
        AudioManager.play_sfx("aggro")


func _chase_target(delta: float) -> void:
    if not _aggro_target or not is_instance_valid(_aggro_target):
        _aggro_target = null
        return
    
    var to_target = _aggro_target.global_position - global_position
    var dist = to_target.length()
    
    # Face target
    if sprite:
        sprite.flip_h = to_target.x < 0
    
    # In attack range
    if dist < _attack_range and _attack_cd <= 0.0:
        _attack_target()
        return
    
    # Move toward target
    velocity = to_target.normalized() * _chase_speed
    move_and_slide()


func _attack_target() -> void:
    if not _aggro_target or not is_instance_valid(_aggro_target):
        return
    
    if _aggro_target.has_method("take_damage"):
        var final_damage = max(1, attack)
        _aggro_target.take_damage(final_damage)
        _attack_cd = _attack_cooldown_max
        
        # Visual feedback
        if combat_effects:
            combat_effects.spawn_hit_flash(_aggro_target, CombatEffects.HIT_FLASH_COLOR, 0.1)
        
        AudioManager.play_sfx("enemy_hit")
        attacked_player.emit(final_damage)


func _wander(delta: float) -> void:
    if _is_paused:
        _wander_pause_timer -= delta
        if _wander_pause_timer <= 0.0:
            _is_paused = false
        velocity = Vector2.ZERO
        return
    
    _wander_timer -= delta
    if _wander_timer <= 0.0:
        # Random direction
        if randf() < 0.3:  # 30% chance to pause
            _is_paused = true
            _wander_pause_timer = randf_range(0.5, 1.5)
            velocity = Vector2.ZERO
        else:
            _wander_dir = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
            _wander_timer = randf_range(0.8, 2.0)
            
            # Face movement direction
            if sprite and _wander_dir.length() > 0.1:
                sprite.flip_h = _wander_dir.x < 0
    
    velocity = _wander_dir * _wander_speed
    move_and_slide()


func _get_player():
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        var player = players[0]
        if not player.is_dead:
            return player
    return null


func take_damage(amount: int) -> void:
    if is_dead:
        return
    
    var final_damage = max(1, amount - defense / 2)
    health -= final_damage
    health_changed.emit(health, max_health)
    
    if hp_bar:
        hp_bar.value = max(0, health)
    
    hit_flash.start(0.1)
    
    # Hit reaction - small knockback
    var player = _get_player()
    if player:
        var knockback_dir = (global_position - player.global_position).normalized()
        _knockback_velocity = knockback_dir * 80.0
        _stun_timer = 0.15
    
    # Visual feedback
    if combat_effects:
        combat_effects.spawn_hit_flash(self, CombatEffects.HIT_FLASH_COLOR, 0.08)
        combat_effects.spawn_hit_particles(global_position, Color(0.8, 0.8, 0.8))
    
    # Aggro the player if hit
    if player and not _aggro_target:
        _aggro_target = player
    
    if health <= 0:
        _die()


func _die() -> void:
    is_dead = true
    died.emit()
    
    # Death effect
    if combat_effects:
        combat_effects.spawn_death_effect(global_position, Color(0.8, 0.4, 0.0))
    
    AudioManager.play_sfx("enemy_death")
    
    # Disable collision
    set_collision_layer(0)
    set_collision_mask(0)
    
    # Fade out and remove
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    tween.tween_callback(queue_free)
