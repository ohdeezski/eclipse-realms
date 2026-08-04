extends Control
## Inventory.gd - Player inventory UI and management system
## Displays items, handles equipment, and integrates with GameData and SaveManager.

signal inventory_closed
signal item_used(item_id: String)
signal item_equipped(slot: String, item_id: String)
signal item_dropped(item_id: String)

const SLOT_SIZE: Vector2 = Vector2(64, 64)
const INVENTORY_SLOTS: int = 20
const GOLD_SLOT_INDEX: int = 19  # Last slot reserved for gold display

@onready var title_label: Label = $TitleBar/TitleLabel
@onready var close_button: Button = $TitleBar/CloseButton
@onready var item_grid: GridContainer = $ItemList
@onready var background: Panel = $Background

# Item slots (array of texture buttons or panels)
var item_slots: Array[Control] = []
var current_player: Node = null
var is_open: bool = false

func _ready() -> void:
    close_button.pressed.connect(_on_close_pressed)
    # Create item slot UI elements
    _create_slots()
    hide()

func _create_slots() -> void:
    """Create visual slot containers for the inventory grid."""
    for i in range(INVENTORY_SLOTS):
        var slot = Control.new()
        slot.custom_minimum_size = SLOT_SIZE
        slot.name = "Slot_%d" % i

        # Background
        var bg = ColorRect.new()
        bg.anchor_right = 1.0
        bg.anchor_bottom = 1.0
        bg.color = Color(0.15, 0.15, 0.2, 0.5)
        bg.mouse_filter = 2  # Ignore
        slot.add_child(bg)

        # Item icon placeholder
        var icon = TextureRect.new()
        icon.anchor_right = 0.5
        icon.anchor_bottom = 0.5
        icon.position = Vector2(8, 8)
        icon.size = Vector2(32, 32)
        icon.expand = true
        icon.texture_filter = TextureFilter.TEXTURE_FILTER_LINEAR
        icon.mouse_filter = 2  # Ignore
        icon.visible = false
        slot.add_child(icon)

        # Item count label
        var count_label = Label.new()
        count_label.anchor_top = 1.0
        count_label.anchor_right = 1.0
        count_label.position = Vector2(40, 44)
        count_label.size = Vector2(20, 16)
        count_label.horizontal_alignment = 1
        count_label.theme_type_variation = "font_size=12"
        count_label.add_theme_color_override("font_color", Color(1, 1, 1))
        count_label.visible = false
        slot.add_child(count_label)

        item_grid.add_child(slot)

func open_inventory(player: Node) -> void:
    """Open the inventory and bind to the player."""
    if is_open:
        return

    current_player = player
    is_open = true

    # Block game input
    InputManager.set_input_blocked(true)

    # Show the inventory
    show()
    center()

    # Populate slots from player inventory
    _populate_slots()

    # Pause the game
    if GameManager.current_state == GameManager.GameState.PLAYING:
        GameManager.pause_game()

func close_inventory() -> void:
    """Close the inventory."""
    if not is_open:
        return

    is_open = false
    hide()

    # Unblock game input
    InputManager.set_input_blocked(false)

    # Resume game
    if GameManager.current_state == GameManager.GameState.PAUSED:
        GameManager.resume_game()

    inventory_closed.emit()
    current_player = null

func _populate_slots() -> void:
    """Fill slots with player's inventory items."""
    if not current_player:
        return

    var inventory = current_player.inventory  # Array of item IDs

    for i in range(INVENTORY_SLOTS):
        var slot = item_slots[i] if i < item_slots.size() else null
        if not slot:
            continue

        if i < inventory.size():
            var item_id = inventory[i]
            var item_data = GameData.get_item(item_id)
            if item_data:
                # Update slot visuals
                var bg = slot.get_node("ColorRect") as ColorRect
                var icon = slot.get_node("TextureRect") as TextureRect
                var count_label = slot.get_node("Label") as Label

                if item_data.has("rarity"):
                    var rarity_color = _get_rarity_color(item_data["rarity"])
                    bg.color = rarity_color

                icon.visible = true
                icon.texture = _load_item_icon(item_id)

                # Check if stackable
                var is_stackable = item_data.get("stackable", false)
                if is_stackable:
                    var count = _get_item_count(item_id)
                    count_label.text = str(count)
                    count_label.visible = true

                # Connect slot click
                slot.gui_input.connect(_on_slot_clicked.bind(slot, i, item_id))
            else:
                # Invalid item, clear slot
                _clear_slot(slot)
        else:
            # Empty slot up to gold slot
            var bg = slot.get_node("ColorRect") as ColorRect
            bg.color = Color(0.15, 0.15, 0.2, 0.5)
            var icon = slot.get_node("TextureRect") as TextureRect
            icon.visible = false
            var count_label = slot.get_node("Label") as Label
            count_label.visible = false

            if i == GOLD_SLOT_INDEX and current_player:
                # Gold display
                bg.color = Color(0.8, 0.7, 0.1, 0.5)
                count_label.text = str(current_player.gold)
                count_label.visible = true

func _clear_slot(slot: Control) -> void:
    """Clear a slot's visuals."""
    var bg = slot.get_node("ColorRect") as ColorRect if slot.get_node("ColorRect") else null
    var icon = slot.get_node("TextureRect") as TextureRect if slot.get_node("TextureRect") else null
    var count_label = slot.get_node("Label") as Label if slot.get_node("Label") else null

    if bg:
        bg.color = Color(0.15, 0.15, 0.2, 0.5)
    if icon:
        icon.visible = false
    if count_label:
        count_label.visible = false

func _on_slot_clicked(slot: Control, index: int, item_id: String, event: InputEvent) -> void:
    """Handle slot click — show item details or use item."""
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var item = GameData.get_item(item_id)
        if item.is_empty():
            return

        if item["type"] == "consumable":
            _use_item(item_id)
        elif item["type"] == "weapon" or item["type"] == "armor":
            _equip_item(item_id)
        else:
            UIManager.show_notification(item["name"], "info")

func _use_item(item_id: String) -> void:
    """Consume a usable item."""
    if not current_player:
        return

    var item_data = GameData.get_item(item_id)
    if item_data.is_empty() or not item_data.get("stackable", false):
        return

    # Remove one from inventory
    current_player.inventory.erase(item_id)
    item_used.emit(item_id)

    # Apply effect
    if item_data.has("stats") and item_data["stats"].has("heal"):
        current_player.heal(item_data["stats"]["heal"])
        UIManager.show_notification("Restored %d HP" % item_data["stats"]["heal"], "success")
    else:
        UIManager.show_notification("Used %s" % item_data["name"], "info")

    # Save
    SaveManager.save_game()
    _populate_slots()

func _equip_item(item_id: String) -> void:
    """Equip an item to the appropriate slot."""
    if not current_player:
        return

    var item_data = GameData.get_item(item_id)
    if item_data.is_empty():
        return

    var equip_slot = item_data.get("slot", "")
    if equip_slot in current_player.equipment:
        # Unequip previous
        var old_item = current_player.equipment[equip_slot]
        current_player.inventory.append(old_item)

    # Equip
    current_player.equipment[equip_slot] = item_id
    current_player.inventory.erase(item_id)
    item_equipped.emit(equip_slot, item_id)

    var slot_name = "Weapon" if equip_slot == "weapon" else equip_slot.capitalize()
    UIManager.show_notification("Equipped: %s" % item_data["name"], "success")

    SaveManager.save_game()
    _populate_slots()

func _on_close_pressed() -> void:
    close_inventory()

func _get_rarity_color(rarity: String) -> Color:
    match rarity:
        "common":
            return Color(0.7, 0.7, 0.7, 0.5)
        "uncommon":
            return Color(0.2, 0.8, 0.2, 0.5)
        "rare":
            return Color(0.2, 0.5, 0.9, 0.5)
        "epic":
            return Color(0.6, 0.2, 0.9, 0.5)
        "legendary":
            return Color(0.9, 0.7, 0.1, 0.5)
        _:
            return Color(0.5, 0.5, 0.5, 0.5)

func toggle():
    """Toggle inventory open/close."""
    if is_open:
        close_inventory()
    else:
        open_inventory(current_player)

func center() -> void:
    "Center the inventory on screen."
    var viewport_size = get_viewport_rect().size
    position = (viewport_size - size) / 2

func _load_item_icon(item_id: String) -> Texture2D:
    "Load the icon texture for an item ID."
    # Try to load from resources - returns null if not found (placeholder)
    var icon_path = "res://resources/icons/%s.png" % item_id
    if ResourceLoader.exists(icon_path):
        return load(icon_path)
    return null

func _get_item_count(item_id: String) -> int:
    "Count how many of an item are in the inventory."
    if not current_player:
        return 0
    var count = 0
    for item in current_player.inventory:
        if item == item_id:
            count += 1
    return count
