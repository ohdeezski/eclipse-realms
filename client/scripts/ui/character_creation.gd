extends Control
## CharacterCreation.gd - Character creation screen
## Wires the UI elements for name, species, appearance, and body type selection.
## On create, stores data in GameManager session and transitions to the world.

@onready var name_input: LineEdit = $Panel/NameInput
@onready var species_select: OptionButton = $Panel/SpeciesSelect
@onready var face_select: OptionButton = $Panel/FaceSelect
@onready var hair_select: OptionButton = $Panel/HairSelect
@onready var body_select: OptionButton = $Panel/BodySelect
@onready var gender_select: OptionButton = $Panel/GenderSelect
@onready var gender_custom_input: LineEdit = $Panel/GenderCustomInput
@onready var pronouns_select: OptionButton = $Panel/PronounsSelect
@onready var pronouns_custom_input: LineEdit = $Panel/PronounsCustomInput
@onready var preview_sprite: Sprite2D = $Preview/PreviewSprite
@onready var stats_label: Label = $Preview/StatsLabel
@onready var step_progress_label: Label = $Panel/StepProgressLabel
@onready var step_description_label: Label = $Panel/StepDescriptionLabel
@onready var job_summary_label: Label = $Panel/JobSummaryLabel
@onready var review_label: Label = $Panel/ReviewLabel
@onready var back_btn: Button = $ButtonContainer/BackButton
@onready var next_btn: Button = $ButtonContainer/NextButton
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
const GENDER_IDENTITIES: Array[String] = ["Woman", "Man", "Nonbinary", "Genderfluid", "Self-describe", "Prefer not to say"]
const PRONOUN_SETS: Array[String] = ["They/them", "She/her", "He/him", "Use my name", "Custom", "Prefer not to say"]
const CREATION_STEPS: Array[String] = ["Basics", "Ancestry", "Calling", "Review"]
var _is_submitting: bool = false
var _current_step: int = 0

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
    for identity in GENDER_IDENTITIES:
        gender_select.add_item(identity)
    for pronoun_set in PRONOUN_SETS:
        pronouns_select.add_item(pronoun_set)

    # Connect signals
    species_select.item_selected.connect(_on_species_changed)
    body_select.item_selected.connect(_on_body_changed)
    gender_select.item_selected.connect(_on_gender_identity_changed)
    pronouns_select.item_selected.connect(_on_pronouns_changed)
    create_btn.pressed.connect(_on_create_pressed)
    back_btn.pressed.connect(_on_back_pressed)
    next_btn.pressed.connect(_on_next_pressed)

    # Set defaults
    species_select.select(0)
    face_select.select(0)
    hair_select.select(0)
    body_select.select(0)
    gender_select.select(GENDER_IDENTITIES.find("Prefer not to say"))
    pronouns_select.select(PRONOUN_SETS.find("They/them"))
    _update_preview_color()

    name_input.text = ""
    name_input.grab_focus()
    create_btn.disabled = true

    # Initialize character creation polish features
    _initialize_polish_features()
    _set_creation_step(0)


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
    var invalid_chars = ["\"", "'", ";", "(", ")", "[", "]", "{", "}"]
    for c in invalid_chars:
        if new_text.contains(c):
            name_input.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
            break

    create_btn.disabled = not _is_create_button_enabled()


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


func _is_create_button_enabled() -> bool:
    """Enable Create only when a name is entered and a species is chosen."""
    var name_ok = name_input != null and not name_input.text.strip_edges().is_empty()
    var species_ok = species_select != null and species_select.selected >= 0
    return name_ok and species_ok


func _set_creation_step(step: int) -> void:
    _current_step = clampi(step, 0, CREATION_STEPS.size() - 1)
    var is_basics := _current_step == 0
    var is_ancestry := _current_step == 1
    var is_calling := _current_step == 2
    var is_review := _current_step == 3

    $Panel/NameLabel.visible = is_basics
    name_input.visible = is_basics
    $Panel/GenderLabel.visible = is_basics
    gender_select.visible = is_basics
    $Panel/PronounsLabel.visible = is_basics
    pronouns_select.visible = is_basics
    gender_custom_input.visible = is_basics and gender_select.get_item_text(gender_select.selected) == "Self-describe"
    pronouns_custom_input.visible = is_basics and pronouns_select.get_item_text(pronouns_select.selected) == "Custom"

    $Panel/SpeciesLabel.visible = is_ancestry
    species_select.visible = is_ancestry
    job_summary_label.visible = is_calling
    review_label.visible = is_review
    next_btn.visible = not is_review
    create_btn.visible = is_review
    create_btn.disabled = not _is_create_button_enabled()
    back_btn.text = "Back" if _current_step > 0 else "Main Menu"

    step_progress_label.text = "%d / %d  •  %s" % [_current_step + 1, CREATION_STEPS.size(), CREATION_STEPS[_current_step].to_upper()]
    match _current_step:
        0:
            step_description_label.text = "Choose how your character is addressed. Identity and pronouns are private by default."
            name_input.grab_focus()
        1:
            step_description_label.text = "Choose an ancestry. It currently changes the preview tint and your story profile; gameplay stats stay equal."
        2:
            step_description_label.text = "Choose your calling. Only fully playable callings are offered."
            _update_job_summary()
        3:
            step_description_label.text = "Check the choices that will be saved to this device."
            _update_review()


func _on_next_pressed() -> void:
    if _current_step == 0 and name_input.text.strip_edges().is_empty():
        UIManager.show_notification("Enter a character name first.", "warning")
        name_input.grab_focus()
        return
    _set_creation_step(_current_step + 1)


func _update_job_summary() -> void:
    var job: Dictionary = GameData.get_job("adept")
    var stats: Dictionary = job.get("base_stats", {})
    var skills: Array = job.get("starting_skill_ids", [])
    var equipment: Dictionary = job.get("starting_equipment", {})
    job_summary_label.text = "%s\n%s\n\nHP %d  •  MP %d  •  ATK %d  •  DEF %d\nSkills: %s\nStarter weapon: %s" % [
        job.get("display_name", "Adept"),
        job.get("description", "A balanced starting path."),
        int(stats.get("health", 0)), int(stats.get("mana", 0)), int(stats.get("attack", 0)), int(stats.get("defense", 0)),
        ", ".join(skills).replace("_", " ").capitalize(),
        str(equipment.get("weapon", "wooden_sword")).replace("_", " ").capitalize()
    ]


func _update_review() -> void:
    var species_key: String = species_options.keys()[species_select.selected]
    var identity := gender_select.get_item_text(gender_select.selected)
    if identity == "Self-describe" and not gender_custom_input.text.strip_edges().is_empty():
        identity = gender_custom_input.text.strip_edges()
    var pronouns := pronouns_select.get_item_text(pronouns_select.selected)
    if pronouns == "Custom" and not pronouns_custom_input.text.strip_edges().is_empty():
        pronouns = pronouns_custom_input.text.strip_edges()
    review_label.text = "%s\n\n%s  •  %s\n%s\n\nCalling: Adept\nStarter kit: sword, clothes, 2 potions, rope, torch\n\nIdentity details are private by default." % [
        name_input.text.strip_edges(),
        species_options[species_key]["name"], identity, pronouns
    ]


func _setup_preview_animations() -> void:
    """Setup character preview animations."""
    # Add subtle pulsing animation to preview sprite
    var pulse_tween = create_tween()
    pulse_tween.set_loops()
    pulse_tween.tween_property(preview_sprite, "scale", Vector2(1.02, 1.02), 2.0)
    pulse_tween.tween_property(preview_sprite, "scale", Vector2(1, 1), 2.0)


func _initialize_stat_calculations() -> void:
    """Initialize character stat calculations and display."""
    # Jobs own gameplay starting stats; ancestry and appearance stay cosmetic.
    _calculate_job_starting_stats()
    
    # Setup stat modifiers display
    _setup_stat_modifiers_display()


func _calculate_job_starting_stats() -> void:
    """Calculate and display the current job's starting stats."""
    var base_stats = _get_job_starting_stats("adept")
    
    # Store base stats in session for later use
    GameManager.session_data["character_creation_base_stats"] = base_stats


func _get_job_starting_stats(job_id: String) -> Dictionary:
    """Get gameplay stats from a job. Ancestry and appearance do not alter them."""
    var job: Dictionary = GameData.get_job(GameData.resolve_job_id(job_id))
    return job.get("base_stats", {}).duplicate(true)


func _setup_stat_modifiers_display() -> void:
    """Setup stat modifiers display section."""
    _update_stat_display()


func _update_stat_display() -> void:
    """Update character stat display based on selections."""
    var base_stats = _get_job_starting_stats("adept")
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
    
    if stats_label:
        stats_label.text = stat_text
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
    preview_sprite.modulate = species_options[species_key]["color"]

func _on_species_changed(index: int) -> void:
    _update_preview_color()
    _update_stat_display()

func _on_body_changed(index: int) -> void:
    _update_stat_display()

func _on_gender_identity_changed(index: int) -> void:
    gender_custom_input.visible = gender_select.get_item_text(index) == "Self-describe"
    if not gender_custom_input.visible:
        gender_custom_input.text = ""

func _on_pronouns_changed(index: int) -> void:
    pronouns_custom_input.visible = pronouns_select.get_item_text(index) == "Custom"
    if not pronouns_custom_input.visible:
        pronouns_custom_input.text = ""

func _on_create_pressed() -> void:
    if _is_submitting:
        return
    if not _is_create_button_enabled():
        UIManager.show_notification("Enter a character name first.", "warning")
        return

    _is_submitting = true
    create_btn.disabled = true

    var name = name_input.text.strip_edges()
    if name.is_empty():
        name = "Adventurer"
    if name.length() > 16:
        name = name.substr(0, 16)

    var species_key = species_options.keys()[species_select.selected]
    var job_id = "adept"

    # Jobs own gameplay stats. Ancestry and presentation remain cosmetic.
    var base_stats = _get_job_starting_stats(job_id)
    var final_stats = base_stats.duplicate(true)
    var gender_identity = gender_select.get_item_text(gender_select.selected)
    var pronouns = pronouns_select.get_item_text(pronouns_select.selected)

    # Store character data in session (SaveManager picks this up later)
    GameManager.session_data["character"] = {
        "name": name,
        "species": species_key,
        "species_id": species_key,
        "job_id": job_id,
        "face": faces[face_select.selected],
        "hair": hairs[hair_select.selected],
        "body": bodies[body_select.selected],
        "avatar_id": "pc_human_adept_01",
        "gender_identity": gender_identity,
        "gender_identity_custom": gender_custom_input.text.strip_edges() if gender_identity == "Self-describe" else "",
        "pronouns": pronouns,
        "pronouns_custom": pronouns_custom_input.text.strip_edges() if pronouns == "Custom" else "",
        "profile_sharing_enabled": false,
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
    call_deferred("_transition_to_world")


func _transition_to_world() -> void:
    SceneManager.change_scene("res://scenes/world/oakrest_village.tscn", "fade")


func _save_character_creation() -> void:
    """Save character creation data to disk."""
    # Create character data for SaveManager
    var character_data = GameManager.session_data["character"].duplicate(true)
    
    # Add inventory data for new character
    var job_id: String = character_data.get("job_id", "adept")
    var starting_items = _get_starting_inventory(job_id)
    var starting_equipment: Dictionary = GameData.get_job(GameData.resolve_job_id(job_id)).get("starting_equipment", {}).duplicate(true)
    
    # Create temporary player-like structure for SaveManager
    var temp_player_data = {
        "name": character_data["name"],
        "level": character_data["level"],
        "experience": character_data["experience"],
        "stats": character_data["stats"],
        "inventory": starting_items,
        "gold": 100,  # Starting gold
        "equipment": starting_equipment,
        "active_quests": ["tutorial_quest"],  # Start with tutorial quest
        "completed_quests": [],
        "position_x": character_data["position"].x,
        "position_y": character_data["position"].y,
        "species": character_data["species"],
        "species_id": character_data["species_id"],
        "job_id": job_id,
        "avatar_id": character_data["avatar_id"],
        "gender_identity": character_data["gender_identity"],
        "gender_identity_custom": character_data["gender_identity_custom"],
        "pronouns": character_data["pronouns"],
        "pronouns_custom": character_data["pronouns_custom"],
        "profile_sharing_enabled": false,
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
    UIManager.show_notification("Character %s created successfully!" % character_data["name"], "success")


func _apply_body_modifiers(base_stats: Dictionary, modifier: float) -> Dictionary:
    """Apply body type modifiers to base stats."""
    var final_stats: Dictionary = {}
    for stat_key in base_stats:
        final_stats[stat_key] = int(base_stats[stat_key] * modifier)
    return final_stats


func _get_starting_inventory(job_id: String) -> Array:
    """Get an equivalent starter kit from the selected job."""
    var job: Dictionary = GameData.get_job(GameData.resolve_job_id(job_id))
    return job.get("starting_item_ids", []).duplicate()

func _on_back_pressed() -> void:
    if _current_step > 0:
        _set_creation_step(_current_step - 1)
        return
    call_deferred("_transition_to_menu")


func _transition_to_menu() -> void:
    SceneManager.change_scene("res://scenes/main_menu/main_menu.tscn", "fade")
