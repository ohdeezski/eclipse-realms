extends Node
## CreekWorld.gd - Silver Creek controller.
## River zone with bridge, fishing spots, water ambience.

@onready var player: Node = $Player
@onready var tilemap: TileMap = $TileMap if has_node("TileMap") else null
@onready var zone_manager: Node = $ZoneManager if has_node("ZoneManager") else null


func _ready() -> void:
	GameManager.start_game()

	# Build the tilemap from the layout definition
	_build_tilemap()

	# Configure all entities (NPCs, monsters)
	_configure_entities()

	# Wire up zone management
	_setup_zones()

	# Show HUD
	UIManager.set_hud_visible(true)
	
	# Play creek music
	if AudioManager:
		AudioManager.play_music("creek_theme")
	
	UIManager.show_notification("Welcome to Silver Creek. The water flows peacefully.", "info")


## ---------------------------------------------------------------------------
## Tilemap
## ---------------------------------------------------------------------------

func _build_tilemap() -> void:
	if tilemap == null:
		return
	var builder_node = $TileMap/TilemapBuilder if has_node("TileMap/TilemapBuilder") else null
	if builder_node and builder_node.has_method("build"):
		builder_node.build(tilemap)
		# Add creek details (bridge, reeds, lily pads, rocks, fishing spots)
		if builder_node.has_method("add_creek_details"):
			builder_node.add_creek_details(tilemap)
		print("[CreekWorld] Tilemap built successfully")
	else:
		push_warning("[CreekWorld] TilemapBuilder not found or missing build() method")


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
	print("[CreekWorld] Player entered zone: %s (%s)" % [zone_id, display_name])


func _on_zone_changed(old_zone: String, new_zone: String) -> void:
	print("[CreekWorld] Zone transition: %s -> %s" % [old_zone, new_zone])
	# Handle zone transitions that load new scenes
	match new_zone:
		"forest_transition":
			SceneManager.change_scene("res://scenes/world/mosswood_forest.tscn", "fade")
		"village_transition":
			SceneManager.change_scene("res://scenes/world/oakrest_village.tscn", "fade")
		"creek":
			if get_tree().current_scene.scene_file_path != "res://scenes/world/silver_creek.tscn":
				SceneManager.change_scene("res://scenes/world/silver_creek.tscn", "fade")
	# Future: trigger music change, spawn/despawn entities, etc.


## ---------------------------------------------------------------------------
## Entity Configuration
## ---------------------------------------------------------------------------

func _configure_entities() -> void:
	for node in get_children():
		if node.is_in_group("enemy"):
			var mid = "moss_slime" if "Slime" in node.name else "forest_wolf"
			var mdata = GameData.get_monster(mid)
			if not mdata.is_empty() and node.has_method("configure"):
				node.configure(mdata)
				node.died.connect(_on_monster_died.bind(node))
		elif node.is_in_group("npc"):
			var nid = _resolve_npc_id(node.name)
			var ndata = GameData.get_npc(nid)
			if not ndata.is_empty() and node.has_method("configure"):
				node.configure(ndata)


func _resolve_npc_id(node_name: String) -> String:
	"""Map NPC node names to their GameData IDs."""
	return "village_elder"


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


func _on_monster_died(m: Node) -> void:
	pass