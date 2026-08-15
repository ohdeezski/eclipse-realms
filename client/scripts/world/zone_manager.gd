extends Node
## ZoneManager.gd - Manages zone transitions and area boundaries.
## Connects to Area2D nodes placed in the scene to detect when the player
## enters or exits named zones (village, forest, etc.).
##
## Usage: place as a child of the world scene and wire up ZoneBoundary
## Area2D nodes in the scene tree. Each ZoneBoundary must have:
##   - name starting with "Zone_" (e.g. "Zone_Village", "Zone_Forest")
##   - a CollisionShape2D child
##   - monitoring enabled
##   - collision_mask set to the player layer (layer 2)

signal zone_entered(zone_id: String, zone_name: String)
signal zone_exited(zone_id: String, zone_name: String)
signal zone_changed(old_zone: String, new_zone: String)

## Display names for zones (shown in notifications)
const ZONE_DISPLAY_NAMES: Dictionary = {
	"village": "Oakrest Village",
	"forest": "Mosswood Forest",
	"training": "Training Grounds",
	"blacksmith": "Blacksmith",
	"inn": "The Restful Oak Inn",
	"merchant": "Merchant Square",
	"entrance": "Forest Entrance",
	"clearing": "Mosswood Clearing",
	"deep_forest": "Deep Forest",
	"caverns": "Whispering Caverns",
	"village_transition": "Oakrest Village",
	"cavern_transition": "Whispering Caverns",
	"creek": "Silver Creek",
	"camp": "Hunter's Camp",
	"watchtower": "Old Watchtower",
	"forest_transition": "Mosswood Forest",
}

## Music track per zone (maps zone_id → audio track key in AudioConfig)
const ZONE_MUSIC: Dictionary = {
	"village": "village",
	"forest": "forest",
	"training": "training",
	"blacksmith": "blacksmith",
	"inn": "inn",
	"merchant": "merchant",
	"entrance": "forest",
	"clearing": "forest",
	"deep_forest": "forest",
	"caverns": "caverns",
	"creek": "creek",
	"camp": "hunters_camp",
	"watchtower": "forest",
}

## Which zone the player is currently in
var current_zone: String = ""
var previous_zone: String = ""

## Reference to the player node (set by world.gd)
var player: Node = null


func _ready() -> void:
	# Connect to all Zone_ area nodes
	call_deferred("_connect_zones")


func _connect_zones() -> void:
	for child in get_parent().get_children():
		if child is Area2D and child.name.begins_with("Zone_"):
			var zone_id = child.name.substr(5).to_lower()  # Strip "Zone_" prefix
			if not child.body_entered.is_connected(_on_zone_body_entered):
				child.body_entered.connect(_on_zone_body_entered.bind(zone_id))
			if not child.body_exited.is_connected(_on_zone_body_exited):
				child.body_exited.connect(_on_zone_body_exited.bind(zone_id))
			print("[ZoneManager] Connected zone: %s (id=%s)" % [child.name, zone_id])


func set_player(p: Node) -> void:
	player = p


func _on_zone_body_entered(body: Node, zone_id: String) -> void:
	if player == null:
		player = _find_player()
	if player == null:
		return
	if body != player:
		return

	previous_zone = current_zone
	current_zone = zone_id

	var display_name = ZONE_DISPLAY_NAMES.get(zone_id, zone_id.capitalize())

	zone_entered.emit(zone_id, display_name)

	# Trigger zone-based music via AudioManager
	if has_node("/root/AudioManager"):
		AudioManager.enter_zone(zone_id)

	if previous_zone != zone_id and previous_zone != "":
		zone_changed.emit(previous_zone, zone_id)
		UIManager.show_notification("Entering %s" % display_name, "info")
		AudioManager.play_sfx("zone_transition")
	elif previous_zone == "":
		# First zone on spawn
		UIManager.show_notification("Welcome to %s" % display_name, "info")


func _on_zone_body_exited(body: Node, zone_id: String) -> void:
	if player == null:
		return
	if body != player:
		return

	zone_exited.emit(zone_id, ZONE_DISPLAY_NAMES.get(zone_id, zone_id))


func get_current_zone() -> String:
	return current_zone


func get_display_name(zone_id: String = "") -> String:
	if zone_id == "":
		zone_id = current_zone
	return ZONE_DISPLAY_NAMES.get(zone_id, zone_id.capitalize())


func _find_player() -> Node:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null
