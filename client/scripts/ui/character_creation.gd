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
    }

    # Also set the player name on save data for next session
    GameManager.set_game_config("character_name", name)
    GameManager.set_game_config("character_species", species_key)

    # Fade to world
    SceneManager.change_scene("res://scenes/world/oakrest_village.tscn", "fade")

func _on_back_pressed() -> void:
    SceneManager.change_scene("res://scenes/main_menu/main_menu.tscn", "fade")
