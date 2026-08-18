extends Sprite2D
class_name AvatarSprite2D

## AvatarSprite2D.gd - Reusable visual controller for character sprites.
## Resolves visual_id from GameData, loads textures, and sets sprite properties.

@export var visual_id: String = "pc_human_adept_01"

var _current_visual: Dictionary = {}
var _idle_tex: Texture2D = null
var _walk_tex: Texture2D = null

func _ready() -> void:
    # Set default filtering
    texture_filter = TEXTURE_FILTER_NEAREST
    load_visual(visual_id)

func load_visual(id: String) -> void:
    visual_id = id
    _current_visual = GameData.get_avatar_visual(visual_id)
    
    # Apply fallback if not found
    if _current_visual.is_empty():
        push_warning("Avatar visual not found: %s, falling back to default" % visual_id)
        _current_visual = GameData.get_avatar_visual("pc_human_adept_01")
        
    var world: Dictionary = _current_visual.get("world", {})
    
    # Load textures
    var idle_path: String = "res://%s" % world.get("idle", "assets/characters/player/player_idle.png")
    var walk_path: String = "res://%s" % world.get("walk", world.get("idle", "assets/characters/player/player_walk.png"))
    
    _idle_tex = load(idle_path) if ResourceLoader.exists(idle_path) else null
    _walk_tex = load(walk_path) if ResourceLoader.exists(walk_path) else _idle_tex
    
    # Apply properties
    hframes = int(world.get("frames", 4))
    vframes = 1
    frame = 0
    texture = _idle_tex
    
    # Set pivot (offset in Godot 4)
    var pivot = world.get("pivot", [24, 42])
    offset = Vector2(pivot[0], pivot[1])

func play_action(action: String) -> void:
    if action == "walk":
        texture = _walk_tex
    else:
        texture = _idle_tex
        
func set_mirrored(mirrored: bool) -> void:
    flip_h = mirrored
