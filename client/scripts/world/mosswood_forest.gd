extends Node
## MosswoodForest.gd - Mosswood Forest controller (Phase 3).
## Initializes tilemap, entities from GameData, zone transitions, and player interaction.

@onready var world: Node = get_parent()
@onready var player: Node = world.get_node_or_null("Player") if world else null
@onready var tilemap: TileMap = world.get_node_or_null("TileMap") if world else null
@onready var zone_manager: Node = world.get_node_or_null("ZoneManager") if world else null

## Respawn timers for monsters
var _respawn_timers: Dictionary = {}
const RESPAWN_TIME: float = 60.0  # 1 minute respawn


func _ready() -> void:
	GameManager.start_game()

	# Build the tilemap from the layout definition
	_build_tilemap()

	# Configure all entities (monsters, NPCs)
	_configure_entities()

	# Wire up zone management
	_setup_zones()

	# Show HUD
	UIManager.set_hud_visible(true)
	UIManager.show_notification("You enter the Mosswood Forest. Beware of wolves and wisps.", "info")


## ---------------------------------------------------------------------------
## Tilemap
## ---------------------------------------------------------------------------

func _build_tilemap() -> void:
	if tilemap == null:
		return
    var builder_node = tilemap.get_node_or_null("TilemapBuilder") if tilemap else null
	if builder_node and builder_node.has_method("build"):
		builder_node.build(tilemap)
		print("[MosswoodForest] Tilemap built successfully")
	else:
		push_warning("[MosswoodForest] TilemapBuilder not found or missing build() method")


## ---------------------------------------------------------------------------
## Zone Management
## ---------------------------------------------------------------------------

func _setup_zones() -> void:
	if zone_manager == null:
		return
	zone_manager.set_player(player)
	zone_manager.zone_entered.connect(_on_zone_entered)
	zone_manager.zone_changed.connect(_on_zone_changed)


func _on_zone_entered(zone_id: String, display_name: String) -> void:
	print("[MosswoodForest] Player entered zone: %s (%s)" % [zone_id, display_name])


func _on_zone_changed(old_zone: String, new_zone: String) -> void:
	print("[MosswoodForest] Zone transition: %s -> %s" % [old_zone, new_zone])
	# Future: trigger music change, spawn/despawn entities, etc.


## ---------------------------------------------------------------------------
## Entity Configuration
## ---------------------------------------------------------------------------

func _configure_entities() -> void:
    for node in world.get_children():
		if node.is_in_group("enemy"):
			var mid = _resolve_monster_id(node.name)
			var mdata = GameData.get_monster(mid)
			if not mdata.is_empty() and node.has_method("configure"):
				node.configure(mdata)
				node.died.connect(_on_monster_died.bind(node))


func _resolve_monster_id(node_name: String) -> String:
	"""Map monster node names to their GameData IDs."""
	if "Wolf" in node_name:
		return "forest_wolf"
	elif "Wisp" in node_name:
		return "thorn_wisp"
	elif "Slime" in node_name:
		return "moss_slime"
	return "moss_slime"


## ---------------------------------------------------------------------------
## Interaction
## ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()


func _try_interact() -> void:
	if not player or (player.has_method("is_dead") and player.is_dead):
		return
	for n in get_tree().get_nodes_in_group("npc"):
		if player.global_position.distance_to(n.global_position) < 60.0:
			if n.has_method("interact"):
				n.interact(player)
			return


## ---------------------------------------------------------------------------
## Monster Respawning
## ---------------------------------------------------------------------------

func _on_monster_died(m: Node) -> void:
	"""Handle monster death and start respawn timer"""
	var monster_name = m.name
	_respawn_timers[monster_name] = {
		"position": m.global_position,
		"monster_id": _resolve_monster_id(monster_name),
		"time_left": RESPAWN_TIME
	}
	print("[MosswoodForest] %s defeated. Respawning in %ds" % [monster_name, RESPAWN_TIME])


func _process(delta: float) -> void:
	"""Update respawn timers"""
	var completed: Array = []
	for monster_name in _respawn_timers.keys():
		var timer = _respawn_timers[monster_name]
		timer["time_left"] -= delta
		if timer["time_left"] <= 0.0:
			completed.append(monster_name)

	# Spawn completed respawns
	for monster_name in completed:
		_respawn_monster(monster_name, _respawn_timers[monster_name])
		_respawn_timers.erase(monster_name)


func _respawn_monster(monster_name: String, data: Dictionary) -> void:
	"""Respawn a defeated monster"""
	var mid = data["monster_id"]
	var mdata = GameData.get_monster(mid)
	if mdata.is_empty():
		return

	# Create new monster instance
	var monster = CharacterBody2D.new()
	monster.name = monster_name
	monster.position = data["position"]
	monster.collision_layer = 4  # enemy layer
	monster.collision_mask = 1   # world terrain

	# Add collision shape
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 14.0
	collision.shape = circle
	monster.add_child(collision)

	# Add sprite
	var sprite = ColorRect.new()
	sprite.name = "Sprite"
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)
	# Color based on monster type
	if "Wolf" in monster_name:
		sprite.color = Color(0.5, 0.5, 0.55, 1)
	elif "Wisp" in monster_name:
		sprite.color = Color(0.6, 0.3, 0.9, 1)
	else:
		sprite.color = Color(0.3, 0.8, 0.4, 1)
	monster.add_child(sprite)

	# Add HP bar
	var hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.position = Vector2(-16, -44)
	hp_bar.size = Vector2(32, 6)
	monster.add_child(hp_bar)

	# Add hit flash timer
	var hit_flash = Timer.new()
	hit_flash.name = "HitFlash"
	hit_flash.wait_time = 0.1
	hit_flash.one_shot = true
	monster.add_child(hit_flash)

	# Set script
	monster.set_script(load("res://scripts/entities/monster.gd"))

	add_child(monster)
	monster.configure(mdata)
	monster.died.connect(_on_monster_died.bind(monster))
	print("[MosswoodForest] Respawned %s at %s" % [monster_name, data["position"]])
