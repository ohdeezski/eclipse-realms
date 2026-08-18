extends Node
## ForestWorld.gd - Mosswood Forest controller.
## Handles tilemap, entities, zone transitions back to village and to caverns.

@onready var world: Node = get_parent()
@onready var player: Node = world.get_node_or_null("Player") if world else null
@onready var tilemap: TileMap = world.get_node_or_null("TileMap") if world else null
@onready var zone_manager: Node = world.get_node_or_null("ZoneManager") if world else null


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
	
	# Play forest music
	if AudioManager:
		AudioManager.play_music("forest_theme")
	
	UIManager.show_notification("Welcome to Mosswood Forest. Watch for wolves.", "info")


## ---------------------------------------------------------------------------
## Tilemap
## ---------------------------------------------------------------------------

func _build_tilemap() -> void:
	if tilemap == null:
		return
	var builder_node = tilemap.get_node_or_null("TilemapBuilder") if tilemap else null
	if builder_node and builder_node.has_method("build"):
		builder_node.build(tilemap)
		# Add procedural forest details
		if builder_node.has_method("add_forest_details"):
			builder_node.add_forest_details(tilemap)
		print("[ForestWorld] Tilemap built successfully")
	else:
		push_warning("[ForestWorld] TilemapBuilder not found or missing build() method")


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
	print("[ForestWorld] Player entered zone: %s (%s)" % [zone_id, display_name])


func _on_zone_changed(old_zone: String, new_zone: String) -> void:
	print("[ForestWorld] Zone transition: %s -> %s" % [old_zone, new_zone])
	# Handle zone transitions that load new scenes
	match new_zone:
		"village_transition":
			SceneManager.change_scene("res://scenes/world/oakrest_village.tscn", "fade")
		"cavern_transition":
			SceneManager.change_scene("res://scenes/world/whispering_caverns.tscn", "fade")
		"camp_transition":
			GameManager.session_data["transition_spawn"] = {"x": 256.0, "y": 384.0}
			SceneManager.change_scene("res://scenes/world/hunters_camp.tscn", "fade")
		"forest":
			if get_tree().current_scene.scene_file_path != "res://scenes/world/mosswood_forest.tscn":
				SceneManager.change_scene("res://scenes/world/mosswood_forest.tscn", "fade")
		"caverns":
			if get_tree().current_scene.scene_file_path != "res://scenes/world/whispering_caverns.tscn":
				SceneManager.change_scene("res://scenes/world/whispering_caverns.tscn", "fade")
	# Future: trigger music change, spawn/despawn entities, etc.


## ---------------------------------------------------------------------------
## Entity Configuration
## ---------------------------------------------------------------------------

func _configure_entities() -> void:
	for node in world.get_children():
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
	if "Ranger" in node_name:
		return "ranger"
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
