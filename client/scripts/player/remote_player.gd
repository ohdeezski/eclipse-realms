extends CharacterBody2D
class_name RemotePlayer

## RemotePlayer.gd - Representation of other players in the world.
## Syncs position and visuals based on data from NetworkManager.

var peer_id: int = 0
var player_name: String = ""
var player_race: String = "human"
var player_class: String = "adept"

@onready var sprite: AvatarSprite2D = $Sprite
@onready var label: Label = $NameLabel

func _ready() -> void:
	add_to_group("remote_player")
	if label:
		label.text = player_name
	_update_visuals()

func setup(id: int, data: Dictionary) -> void:
	peer_id = id
	update_data(data)

func update_data(data: Dictionary) -> void:
	if data.has("name"):
		player_name = data["name"]
		if label: label.text = player_name
	
	if data.has("race"):
		player_race = data["race"]
		_update_visuals()
		
	if data.has("class"):
		player_class = data["class"]
		_update_visuals()
		
	if data.has("position"):
		var pos = data["position"]
		global_position = Vector2(pos.x, pos.y)
		
	if data.has("is_moving"):
		if data["is_moving"]:
			sprite.play_action("walk")
		else:
			sprite.play_action("idle")
			
	if data.has("facing"):
		var facing = data["facing"]
		match facing:
			"left": sprite.set_mirrored(true)
			"right": sprite.set_mirrored(false)

func _update_visuals() -> void:
	if sprite:
		var vid = "pc_%s_%s_01" % [player_race, player_class]
		sprite.load_visual(vid)
