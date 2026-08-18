
# NPC Character Controller
# Extends: CharacterBody2D
# Dependencies: VisualResolver

extends CharacterBody2D

# NPC Profile Data
@export var npc_race: String = "human"
@export var npc_gender: String = "male"
@export var npc_class: String = "adept"
@export var npc_name: String = "NPC"

# Visual Resolver Reference
@onready var visual_resolver: VisualResolver = $VisualResolver if has_node("VisualResolver") else null

# Components
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var portrait_texture: Texture2D = $Portrait.texture if has_node("Portrait") else null

# NPC-specific data
var quest_data: Dictionary = {}
var dialogue_tree: Dictionary = {}
var current_state: String = "idle"

# ==========================================
# Initialization
# ==========================================

func _ready() -> Void:
    # Ensure visual resolver is available
    if !visual_resolver:
        push_warning("VisualResolver not found as child, creating instance")
        visual_resolver = VisualResolver.new()
        add_child(visual_resolver)

    # Apply initial avatar
    apply_avatar()

    # Connect signals
    if visual_resolver:
        visual_resolver.connect("asset_loaded", _on_asset_loaded)

# ==========================================
# Avatar Management
# ==========================================

# Apply the avatar based on current profile
func apply_avatar() -> Bool:
    if !visual_resolver:
        return false

    var success = visual_resolver.apply_avatar_to_node(
        self, 
        npc_race, 
        npc_gender, 
        npc_class
    )

    if success:
        update_animation()
        return true
    return false

# Change NPC profile and update avatar
func change_profile(new_race: String, new_gender: String, new_class: String) -> Void:
    npc_race = new_race
    npc_gender = new_gender
    npc_class = new_class
    apply_avatar()

# Update animation based on state
func update_animation() -> Void:
    if !sprite:
        return

    if current_state == "idle":
        sprite.play("idle")
    elif current_state == "talking":
        sprite.play("talking")
    elif current_state == "walking":
        sprite.play("walk")
    else:
        sprite.play("idle")

# ==========================================
# NPC-specific Methods
# ==========================================

# Set NPC state (idle, talking, walking, etc.)
func set_state(new_state: String) -> Void:
    current_state = new_state
    update_animation()

# Load quest data from file or database
func load_quest_data(quest_id: String) -> Void:
    # Load from JSON or resource file
    # Example: quest_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/quests/%s.json" % quest_id))
    pass

# Get portrait texture for dialogue system
func get_dialogue_portrait() -> Texture2D:
    if visual_resolver:
        var path = visual_resolver.get_dialogue_asset(npc_race, npc_gender, npc_class)
        if !path.empty():
            return preload(path)
    return null

# ==========================================
# Dialogue System Integration
# ==========================================

# Start dialogue with player
func start_dialogue() -> Void:
    set_state("talking")
    # Emit signal to show dialogue UI
    # dialogue_started.emit(self)

# End dialogue with player
func end_dialogue() -> Void:
    set_state("idle")
    # Emit signal to hide dialogue UI
    # dialogue_ended.emit(self)

# ==========================================
# Save/Load Integration
# ==========================================

# Save NPC profile to dictionary
func save_profile() -> Dictionary:
    return {
        "race": npc_race,
        "gender": npc_gender,
        "class": npc_class,
        "name": npc_name
    }

# Load NPC profile from dictionary
func load_profile(data: Dictionary) -> Void:
    if "race" in data:
        npc_race = data["race"]
    if "gender" in data:
        npc_gender = data["gender"]
    if "class" in data:
        npc_class = data["class"]
    if "name" in data:
        npc_name = data["name"]

    apply_avatar()
