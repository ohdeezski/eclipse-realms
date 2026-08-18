extends CharacterBody2D
class_name Player

## Player.gd - Main player controller for Eclipse Realms.
## Handles movement, combat stats, and network synchronization.

# --- Signals ---
signal health_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal gold_changed(amount: int)
signal leveled_up(level: int)
signal died

# --- Player Profile Data ---
@export var player_name: String = "Player"
@export var player_race: String = "human"
@export var player_gender: String = "male"
@export var player_class: String = "adept"

# --- Stats ---
var level: int = 1
var experience: int = 0
var gold: int = 0
var health: int = 100
var max_health: int = 100
var mana: int = 50
var max_mana: int = 50
var attack: int = 10
var defense: int = 5
var is_dead: bool = false

# --- Movement ---
var speed: float = 200.0
var run_multiplier: float = 1.6
var is_moving: bool = false
var _facing_name: String = "down"

# --- Networking ---
var last_sync_pos: Vector2 = Vector2.ZERO
var sync_interval: float = 0.05 # 20Hz sync
var sync_timer: float = 0.0

# --- Node References ---
@onready var sprite: AvatarSprite2D = $Sprite
@onready var camera: Camera2D = $Camera2D
@onready var hit_flash: Timer = $HitFlash
var combat_effects: CombatEffects = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("player")
	
	# Initialize combat effects
	combat_effects = CombatEffects.new()
	add_child(combat_effects)
	
	# Initial visual setup
	_update_visuals()
	
	# Connect to NetworkManager signals if available
	if NetworkManager:
		NetworkManager.connection_established.connect(_on_network_connected)

func _on_network_connected() -> void:
	print("[Player] Connected to server as ID: %d" % NetworkManager.client_id)
	_sync_full_state()

# ============================================================================
# PROCESS
# ============================================================================

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	_handle_movement(delta)
	_handle_networking(delta)

func _handle_movement(_delta: float) -> void:
	var move_dir = Vector2.ZERO
	
	if InputManager:
		move_dir.x = InputManager.get_action_strength("move_right") - InputManager.get_action_strength("move_left")
		move_dir.y = InputManager.get_action_strength("move_down") - InputManager.get_action_strength("move_up")
	
	move_dir = move_dir.normalized()
	
	var current_speed = speed
	if InputManager and InputManager.is_action_pressed("run"):
		current_speed *= run_multiplier
		
	velocity = move_dir * current_speed
	is_moving = velocity.length() > 10.0
	
	if is_moving:
		_update_facing(move_dir)
		move_and_slide()
		sprite.play_action("walk")
	else:
		sprite.play_action("idle")

func _update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			_facing_name = "right"
			sprite.set_mirrored(false)
		else:
			_facing_name = "left"
			sprite.set_mirrored(true)
	else:
		if dir.y > 0:
			_facing_name = "down"
		else:
			_facing_name = "up"

func _update_visuals() -> void:
	if sprite:
		# Map race/gender/class to visual_id for AvatarSprite2D
		# Example: pc_human_adept_01
		var vid = "pc_%s_%s_01" % [player_race, player_class]
		sprite.load_visual(vid)

# ============================================================================
# NETWORKING
# ============================================================================

func _handle_networking(delta: float) -> void:
	if not NetworkManager or NetworkManager.current_state != NetworkManager.ConnectionState.READY:
		return
		
	sync_timer += delta
	if sync_timer >= sync_interval:
		sync_timer = 0.0
		_sync_position()

func _sync_position() -> void:
	# Only sync if we've moved significantly
	if global_position.distance_to(last_sync_pos) > 1.0:
		NetworkManager.send_message(NetworkManager.MessageType.PLAYER_UPDATE, {
			"position": {"x": global_position.x, "y": global_position.y},
			"facing": _facing_name,
			"is_moving": is_moving
		})
		last_sync_pos = global_position

func _sync_full_state() -> void:
	NetworkManager.send_message(NetworkManager.MessageType.PLAYER_UPDATE, {
		"name": player_name,
		"race": player_race,
		"class": player_class,
		"level": level,
		"health": health,
		"max_health": max_health,
		"position": {"x": global_position.x, "y": global_position.y}
	})

# ============================================================================
# COMBAT & STATS
# ============================================================================

func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	var final_damage = max(1, amount - defense / 2)
	health -= final_damage
	health_changed.emit(health, max_health)
	
	# Visual feedback
	if hit_flash:
		hit_flash.start()
	
	if combat_effects:
		combat_effects.spawn_damage_number(global_position, final_damage)
		combat_effects.spawn_hit_flash(self)
	
	if health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	died.emit()
	print("[Player] Character has died.")
	# Handle death (respawn logic, etc.)

func add_experience(amount: int) -> void:
	experience += amount
	var needed = level * 50
	if experience >= needed:
		level += 1
		experience -= needed
		leveled_up.emit(level)
		if combat_effects:
			combat_effects.spawn_notification("Level Up!")

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

# ============================================================================
# SAVE/LOAD
# ============================================================================

func save_profile() -> Dictionary:
	return {
		"name": player_name,
		"race": player_race,
		"gender": player_gender,
		"class": player_class,
		"level": level,
		"experience": experience,
		"gold": gold,
		"health": health,
		"max_health": max_health,
		"mana": mana,
		"max_mana": max_mana,
		"position": {"x": global_position.x, "y": global_position.y}
	}

func load_profile(data: Dictionary) -> void:
	player_name = data.get("name", player_name)
	player_race = data.get("race", player_race)
	player_gender = data.get("gender", player_gender)
	player_class = data.get("class", player_class)
	level = data.get("level", level)
	experience = data.get("experience", experience)
	gold = data.get("gold", gold)
	health = data.get("health", health)
	max_health = data.get("max_health", max_health)
	mana = data.get("mana", mana)
	max_mana = data.get("max_mana", max_mana)
	
	var pos = data.get("position", {})
	if not pos.is_empty():
		global_position = Vector2(pos.get("x", global_position.x), pos.get("y", global_position.y))
	
	_update_visuals()
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)
	gold_changed.emit(gold)
	leveled_up.emit(level)
