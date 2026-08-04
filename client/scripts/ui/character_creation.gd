extends Control
## CharacterCreation.gd - Character creation screen
## Wires the UI elements for name, species, appearance, and body type selection.
## On create, stores data in GameManager session and transitions to the world.

@onready var name_input: LineEdit = $Panel/NameInput
@onready var species_select: OptionButton = $Panel/SpeciesSelect
@onready var face_select: OptionButton = $Panel/FaceSelect
@onready var hair_select: OptionButton = $Panel/HairSelect
@onready var body_select: OptionButton = $Panel/BodySelect
@onready var preview_sprite: ColorRect = $Preview/PreviewSprite
@onready var back_btn: Button = $ButtonContainer/BackButton
@onready var create_btn: Button = $ButtonContainer/CreateButton

# Character customization options
var species_options: Dictionary = {
    "human": {"name": "Human", "color": Color(0.9, 0.8, 0.6)},
    "elf": {"name": "Elf", "color": Color(0.6, 0.9, 0.6)},
    "dwarf": {"name": "Dwarf", "color": Color(0.7, 0.5, 0.3)},
}

var faces: Array = ["Default", "Smiling", "Serious", "Happy"]
var hairs: Array = ["Short", "Long", "Braided", "Bald"]
var bodies: Array = ["Slim", "Average", "Muscular", "Sturdy"]

func _ready() -> void:
    # Populate dropdowns
    for key in species_options:
        species_select.add_item(species_options[key]["name"])
    for face in faces:
        face_select.add_item(face)
    for hair in hairs:
        hair_select.add_item(hair)
    for body in bodies:
        body_select.add_item(body)

    # Connect signals
    species_select.item_selected.connect(_on_species_changed)
    create_btn.pressed.connect(_on_create_pressed)
    back_btn.pressed.connect(_on_back_pressed)

    # Set defaults
    species_select.select(0)
    face_select.select(0)
    hair_select.select(0)
    body_select.select(0)
    _update_preview_color()

    name_input.text = ""
    name_input.grab_focus()

    # Start in menu state
    GameManager.change_state(GameManager.GameState.MAIN_MENU)

    # Initialize character creation polish features
    _initialize_polish_features()


func _initialize_polish_features() -> void:
    """Initialize enhanced character creation features."""
    # Add focus validation for name input
    name_input.connect("text_changed", _on_name_text_changed)
    
    # Add hover effects for buttons
    _setup_button_interactions()
    
    # Setup preview animations
    _setup_preview_animations()
    
    # Initialize stat calculations
    _initialize_stat_calculations()


func _on_name_text_changed(new_text: String) -> void:
    """Validate and format character name input."""
    var trimmed_text = new_text.strip_edges()
    
    # Prevent empty names
    if trimmed_text.is_empty():
        name_input.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
    else:
        name_input.add_theme_color_override("font_color", Color(1, 1, 1))
    
    # Limit length
    if new_text.length() > 16:
        name_input.text = new_text.substr(0, 16)
        UIManager.show_notification("Name too long! Max 16 characters.", "warning")
    
    # Check for invalid characters (optional)
    if new_text.contains_any(["\"", "'", ";", "(", ")", "[", "]", "{", "}"]):
        name_input.add_theme_color_override("font_color", Color(1, 0.5, 0.5))


func _setup_button_interactions() -> void:
    """Setup enhanced button interactions with visual feedback."""
    # Back button with confirmation
    back_btn.mouse_entered.connect(_on_back_button_entered)
    back_btn.mouse_exited.connect(_on_back_button_exited)
    
    # Create button with validation
    create_btn.mouse_entered.connect(_on_create_button_entered)
    create_btn.mouse_exited.connect(_on_create_button_exited)


func _on_back_button_entered() -> void:
    """Handle back button hover."""
    back_btn.scale = Vector2(1.05, 1.05)


func _on_back_button_exited() -> void:
    """Handle back button hover end."""
    back_btn.scale = Vector2(1, 1)


func _on_create_button_entered() -> void:
    """Handle create button hover."""
    if _is_create_button_enabled():
        create_btn.scale = Vector2(1.05, 1.05)


func _on_create_button_exited() -> void:
    """Handle create button hover end."""
    create_btn.scale = Vector2(1, 1)


func _setup_preview_animations() -> void:
    """Setup character preview animations."""
    # Add subtle pulsing animation to preview sprite
    var pulse_tween = create_tween()
    pulse_tween.set_loops()
    pulse_tween.tween_property(preview_sprite, "scale", Vector2(1.02, 1.02), 2.0)
    pulse_tween.tween_property(preview_sprite, "scale", Vector2(1, 1), 2.0)


func _initialize_stat_calculations() -> void:
    """Initialize character stat calculations and display."""
    # Pre-calculate base stats for each species
    _calculate_species_base_stats()
    
    # Setup stat modifiers display
    _setup_stat_modifiers_display()


func _calculate_species_base_stats() -> void:
    """Calculate and display base stats for selected species."""
    var species_key = species_options.keys()[species_select.selected]
    var base_stats = _get_species_base_stats(species_key)
    
    # Store base stats in session for later use
    GameManager.session_data["character_creation_base_stats"] = base_stats


func _get_species_base_stats(species: String) -> Dictionary:
    """Get base stats for a species."""
    match species:
        "human":
            return {
                "health": 100,
                "mana": 50,
                "attack": 10,
                "defense": 10,
                "speed": 10,
                "intelligence": 10
            }
        "elf":
            return {
                "health": 80,
                "mana": 80,
                "attack": 8,
                "defense": 8,
                "speed": 12,
                "intelligence": 12
            }
        "dwarf":
            return {
                "health": 120,
                "mana": 30,
                "attack": 12,
                "defense": 15,
                "speed": 6,
                "intelligence": 6
            }
        _:
            return {
                "health": 100,
                "mana": 50,
                "attack": 10,
                "defense": 10,
                "speed": 10,
                "intelligence": 10
            }


func _setup_stat_modifiers_display() -> void:
    """Setup stat modifiers display section."""
    # Create stat display panel if it doesn't exist
    if not $Panel/StatDisplay:
        var stat_display = Panel.new()
        stat_display.name = "StatDisplay"
        stat_display.position = Vector2(400, 100)
        stat_display.size = Vector2(200, 150)
        stat_display.visible = false
        $Panel.add_child(stat_display)
    
    # Setup stat labels
    _update_stat_display()


func _update_stat_display() -> void:
    """Update character stat display based on selections."""
    var species_key = species_options.keys()[species_select.selected]
    var base_stats = _get_species_base_stats(species_key)
    
    # Apply body type modifiers
    var body_modifier = _get_body_type_modifier(bodies[body_select.selected])
    for stat_key in base_stats:
        base_stats[stat_key] *= body_modifier
    
    # Display stat modifiers
    _display_stat_modifiers(base_stats)


func _get_body_type_modifier(body_type: String) -> float:
    """Get stat modifier for body type."""
    match body_type:
        "Slim": return 0.9
        "Average": return 1.0
        "Muscular": return 1.1
        "Sturdy": return 1.2
        _:
            return 1.0


func _display_stat_modifiers(stats: Dictionary) -> void:
    """Display stat modifiers to user."""
    var stat_text = "Base Stats:\n"
    
    for stat_key in stats:
        var display_name = _format_stat_name(stat_key)
        var value = int(stats[stat_key])
        stat_text += "%s: %d\n" % [display_name, value]
    
    # Store for potential use in game
    GameManager.session_data["character_creation_display_text"] = stat_text


func _format_stat_name(stat_name: String) -> String:
    """Format stat name for display."""
    match stat_name:
        "health": return "HP"
        "mana": return "MP"
        "attack": return "ATK"
        "defense": return "DEF"
        "speed": return "SPD"
        "intelligence": return "INT"
        _:
            return stat_name.capitalize()

func _update_preview_color() -> void:
    var species_key = species_options.keys()[species_select.selected]
    preview_sprite.color = species_options[species_key]["color"]

func _on_species_changed(index: int) -> void:
    _update_preview_color()

func _on_create_pressed() -> void:
    var name = name_input.text.strip_edges()
    if name.is_empty():
        name = "Adventurer"
    if name.length() > 16:
        name = name.substr(0, 16)

    var species_key = species_options.keys()[species_select.selected]

    # Calculate final character stats
    var base_stats = _get_species_base_stats(species_key)
    var body_modifier = _get_body_type_modifier(bodies[body_select.selected])
    var final_stats = _apply_body_modifiers(base_stats, body_modifier)

    # Store character data in session (SaveManager picks this up later)
    GameManager.session_data["character"] = {
        "name": name,
        "species": species_key,
        "face": faces[face_select.selected],
        "hair": hairs[hair_select.selected],
        "body": bodies[body_select.selected],
        "level": 1,
        "experience": 0,
        "position": Vector2(300, 360),
        "stats": final_stats,
        "created_at": Time.get_unix_time_from_system()
    }

    # Also set the player name on save data for next session
    GameManager.set_game_config("character_name", name)
    GameManager.set_game_config("character_species", species_key)

    # Save character creation data
    _save_character_creation()
    
    # Fade to world
    SceneManager.change_scene("res://scenes/world/oakrest_village.tscn", "fade")


func _save_character_creation() -> void:
    """Save character creation data to disk."""
    # Create character data for SaveManager
    var character_data = GameManager.session_data["character"].duplicate(true)
    
    # Add inventory data for new character
    var species_key = character_data["species"]
    var starting_items = _get_starting_inventory(species_key)
    
    # Create temporary player-like structure for SaveManager
    var temp_player_data = {
        "name": character_data["name"],
        "level": character_data["level"],
        "experience": character_data["experience"],
        "stats": character_data["stats"],
        "inventory": starting_items,
        "gold": 100,  # Starting gold
        "equipment": {},  # Empty equipment
        "active_quests": ["tutorial_quest"],  # Start with tutorial quest
        "completed_quests": [],
        "position_x": character_data["position"].x,
        "position_y": character_data["position"].y,
        "species": character_data["species"],
        "appearance": {
            "face": character_data["face"],
            "hair": character_data["hair"],
            "body": character_data["body"]
        }
    }
    
    # Store in session data for SaveManager to pick up
    GameManager.session_data["player"] = temp_player_data
    
    # Save the game data
    SaveManager.save_game()
    
    # Show confirmation notification
    UIManager.show_notification("Character %s created successfully!" % name, "success")


func _apply_body_modifiers(base_stats: Dictionary, modifier: float) -> Dictionary:
    """Apply body type modifiers to base stats."""
    var final_stats: Dictionary = {}
    for stat_key in base_stats:
        final_stats[stat_key] = int(base_stats[stat_key] * modifier)
    return final_stats


func _get_starting_inventory(species: String) -> Array:
    """Get starting inventory items based on species."""
    var starting_items: Array = []
    
    # All characters start with basic supplies
    starting_items.append("health_potion")
    starting_items.append("health_potion")
    starting_items.append("rope")
    starting_items.append("torch")
    
    # Species-specific starting items
    match species:
        "human":
            starting_items.append("wooden_sword")
        "elf":
            starting_items.append("leather_armor")
        "dwarf":
            starting_items.append("chainmail")
        _:
            starting_items.append("wooden_sword")
    
    return starting_items

func _on_back_pressed() -> void:
    SceneManager.change_scene("res://scenes/main_menu/main_menu.tscn", "fade")
