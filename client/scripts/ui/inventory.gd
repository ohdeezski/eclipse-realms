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

# UI Components for enhanced inventory
@onready var all_tab: Button = $TabContainer/AllTab
@onready var weapons_tab: Button = $TabContainer/WeaponsTab
@onready var armor_tab: Button = $TabContainer/ArmorTab
@onready var consumables_tab: Button = $TabContainer/ConsumablesTab
@onready var materials_tab: Button = $TabContainer/MaterialsTab
@onready var quest_tab: Button = $TabContainer/QuestTab

# Inventory filtering
var current_filter: String = "all"  # all, weapons, armor, consumables, materials, quest

func _ready() -> void:
    close_button.pressed.connect(_on_close_pressed)
    # Create item slot UI elements
    _create_slots()
    
    # Connect tab buttons
    all_tab.toggled.connect(_on_tab_changed.bind("all"))
    weapons_tab.toggled.connect(_on_tab_changed.bind("weapons"))
    armor_tab.toggled.connect(_on_tab_changed.bind("armor"))
    consumables_tab.toggled.connect(_on_tab_changed.bind("consumables"))
    materials_tab.toggled.connect(_on_tab_changed.bind("materials"))
    quest_tab.toggled.connect(_on_tab_changed.bind("quest"))
    
    # Connect tab group signals for single selection
    all_tab.button_group.pressed.connect(_on_tab_group_changed.bind("all"))
    weapons_tab.button_group.pressed.connect(_on_tab_group_changed.bind("weapons"))
    armor_tab.button_group.pressed.connect(_on_tab_group_changed.bind("armor"))
    consumables_tab.button_group.pressed.connect(_on_tab_group_changed.bind("consumables"))
    materials_tab.button_group.pressed.connect(_on_tab_group_changed.bind("materials"))
    quest_tab.button_group.pressed.connect(_on_tab_group_changed.bind("quest"))
    
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

    # Reset slots array to populate it
    item_slots.clear()

    for i in range(INVENTORY_SLOTS):
        # Get existing slot or create new one
        var slot = null
        if i < item_grid.get_child_count():
            slot = item_grid.get_child(i)
        else:
            # Create slot if needed (fallback)
            slot = Control.new()
            slot.custom_minimum_size = SLOT_SIZE
            slot.name = "Slot_%d" % i

            # Background
            var bg = ColorRect.new()
            bg.anchor_right = 1.0
            bg.anchor_bottom = 1.0
            bg.color = Color(0.15, 0.15, 0.2, 0.5)
            bg.mouse_filter = 2
            slot.add_child(bg)

            # Item icon placeholder
            var icon = TextureRect.new()
            icon.anchor_right = 0.5
            icon.anchor_bottom = 0.5
            icon.position = Vector2(8, 8)
            icon.size = Vector2(32, 32)
            icon.expand = true
            icon.texture_filter = TextureFilter.TEXTURE_FILTER_LINEAR
            icon.mouse_filter = 2
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

        item_slots.append(slot)

        # Clear slot first
        _clear_slot(slot)

        if i < inventory.size():
            var item_id = inventory[i]
            var item_data = GameData.get_item(item_id)
            if not item_data.is_empty():
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

                # Connect slot click (disconnect any existing connections)
                slot.disconnect(self, "gui_input", self, "_on_slot_clicked")
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


# Tab management functions
func _on_tab_changed(filter: String) -> void:
    """Handle tab change events."""
    current_filter = filter
    _update_tab_visuals()
    _populate_slots()


func _on_tab_group_changed(filter: String) -> void:
    """Handle tab group pressed events (single selection)."""
    if current_filter != filter:
        current_filter = filter
        _update_tab_visuals()
        _populate_slots()


func _update_tab_visuals() -> void:
    """Update visual state of all tab buttons."""
    all_tab.button_pressed = current_filter == "all"
    weapons_tab.button_pressed = current_filter == "weapons"
    armor_tab.button_pressed = current_filter == "armor"
    consumables_tab.button_pressed = current_filter == "consumables"
    materials_tab.button_pressed = current_filter == "materials"
    quest_tab.button_pressed = current_filter == "quest"


func _should_show_item(item_id: String) -> bool:
    """Check if an item should be displayed based on current filter."""
    var item = GameData.get_item(item_id)
    if item.is_empty():
        return false
    
    var item_type = item.get("type", "")
    
    switch current_filter:
        case "all":
            return true
        case "weapons":
            return item_type == "weapon"
        case "armor":
            return item_type == "armor"
        case "consumables":
            return item_type == "consumable"
        case "materials":
            return item_type in ["material", "misc"]
        case "quest":
            return item_type == "quest" or item_type == "key_item"
        _:
            return false


func _get_tab_name(item_type: String) -> String:
    """Get display name for item type."""
    match item_type:
        "weapon": return "Weapons"
        "armor": return "Armor"
        "consumable": return "Consumables"
        "material": return "Materials"
        "misc": return "Materials"
        "quest": return "Quest"
        "key_item": return "Quest"
        _:
            return item_type.capitalize()


# Additional helper methods for enhanced functionality
func _get_available_filters() -> Array:
    """Get list of available filters with counts."""
    var filters: Array = [
        {"name": "All", "value": "all", "count": INVENTORY_SLOTS},
        {"name": "Weapons", "value": "weapons", "count": 0},
        {"name": "Armor", "value": "armor", "count": 0},
        {"name": "Consumables", "value": "consumables", "count": 0},
        {"name": "Materials", "value": "materials", "count": 0},
        {"name": "Quest", "value": "quest", "count": 0}
    ]
    
    if current_player:
        var inventory = current_player.inventory
        for item_id in inventory:
            var item = GameData.get_item(item_id)
            if not item.is_empty():
                var item_type = item.get("type", "")
                if item_type == "weapon":
                    filters[1]["count"] += 1
                elif item_type == "armor":
                    filters[2]["count"] += 1
                elif item_type == "consumable":
                    filters[3]["count"] += 1
                elif item_type in ["material", "misc"]:
                    filters[4]["count"] += 1
                elif item_type in ["quest", "key_item"]:
                    filters[5]["count"] += 1
    
    return filters


func _get_item_tooltip_text(item_id: String) -> String:
    """Generate tooltip text for an item."""
    var item = GameData.get_item(item_id)
    if item.is_empty():
        return ""
    
    var rarity = item.get("rarity", "common")
    var rarity_color = _get_rarity_color(rarity)
    var rarity_text = "[%s]" % rarity.capitalize()
    
    var value = item.get("value", 0)
    var weight = item.get("weight", 0.0)
    
    var tooltip = ""
    tooltip += "%s %s" % [rarity_text, item["name"]]
    tooltip += "\n"
    tooltip += "%s" % item["description"]
    tooltip += "\n"
    
    if item.has("stats"):
        tooltip += "\nStats:"
        for stat_key in item["stats"]:
            var stat_value = item["stats"][stat_key]
            if isinstance(stat_value, float):
                stat_value = int(stat_value)
            tooltip += "\n  %s: %d" % [stat_key.capitalize(), stat_value]
    
    if value > 0:
        tooltip += "\nValue: %d gold" % value
    
    if weight > 0:
        tooltip += "\nWeight: %.1f" % weight
    
    if item.get("stackable", false):
        tooltip += "\nStackable"
    
    return tooltip


func _filter_inventory_items(items: Array) -> Array:
    """Filter inventory items based on current filter."""
    var filtered_items: Array = []
    for item_id in items:
        if _should_show_item(item_id):
            filtered_items.append(item_id)
    return filtered_items


# Additional helper methods for enhanced functionality
func _get_available_filters() -> Array:
    """Get list of available filters with counts."""
    var filters: Array = [
        {"name": "All", "value": "all", "count": INVENTORY_SLOTS},
        {"name": "Weapons", "value": "weapons", "count": 0},
        {"name": "Armor", "value": "armor", "count": 0},
        {"name": "Consumables", "value": "consumables", "count": 0},
        {"name": "Materials", "value": "materials", "count": 0},
        {"name": "Quest", "value": "quest", "count": 0}
    ]
    
    if current_player:
        var inventory = current_player.inventory
        for item_id in inventory:
            var item = GameData.get_item(item_id)
            if not item.is_empty():
                var item_type = item.get("type", "")
                if item_type == "weapon":
                    filters[1]["count"] += 1
                elif item_type == "armor":
                    filters[2]["count"] += 1
                elif item_type == "consumable":
                    filters[3]["count"] += 1
                elif item_type in ["material", "misc"]:
                    filters[4]["count"] += 1
                elif item_type in ["quest", "key_item"]:
                    filters[5]["count"] += 1
    
    return filters


func _get_item_tooltip_text(item_id: String) -> String:
    """Generate tooltip text for an item."""
    var item = GameData.get_item(item_id)
    if item.is_empty():
        return ""
    
    var rarity = item.get("rarity", "common")
    var rarity_color = _get_rarity_color(rarity)
    var rarity_text = "[%s]" % rarity.capitalize()
    
    var value = item.get("value", 0)
    var weight = item.get("weight", 0.0)
    
    var tooltip = ""
    tooltip += "%s %s" % [rarity_text, item["name"]]
    tooltip += "\n"
    tooltip += "%s" % item["description"]
    tooltip += "\n"
    
    if item.has("stats"):
        tooltip += "\nStats:"
        for stat_key in item["stats"]:
            var stat_value = item["stats"][stat_key]
            if isinstance(stat_value, float):
                stat_value = int(stat_value)
            tooltip += "\n  %s: %d" % [stat_key.capitalize(), stat_value]
    
    if value > 0:
        tooltip += "\nValue: %d gold" % value
    
    if weight > 0:
        tooltip += "\nWeight: %.1f" % weight
    
    if item.get("stackable", false):
        tooltip += "\nStackable"
    
    return tooltip


func _filter_inventory_items(items: Array) -> Array:
    """Filter inventory items based on current filter."""
    var filtered_items: Array = []
    for item_id in items:
        if _should_show_item(item_id):
            filtered_items.append(item_id)
    return filtered_items


# ============================================================================
# ENHANCED INVENTORY FUNCTIONS (continued)
# ============================================================================

# Tooltip system for enhanced inventory interaction
@onready var item_tooltip: Panel = $ItemTooltip
@onready var tooltip_name: Label = $ItemTooltip/TooltipName
@onready var tooltip_description: Label = $ItemTooltip/TooltipDescription
@onready var tooltip_stats: Label = $ItemTooltip/TooltipStats
@onready var tooltip_value: Label = $ItemTooltip/TooltipValue

func _show_item_tooltip(slot: Control, item_id: String, position: Vector2) -> void:
    """Show detailed tooltip for an item."""
    var item = GameData.get_item(item_id)
    if item.is_empty():
        _hide_item_tooltip()
        return
    
    tooltip_name.text = item["name"]
    tooltip_description.text = item["description"]
    
    var tooltip_text = _get_item_tooltip_text(item_id)
    tooltip_stats.text = ""
    tooltip_value.text = ""
    
    if item.has("stats"):
        var stats_text = "\nStats:"
        for stat_key in item["stats"]:
            var stat_value = item["stats"][stat_key]
            if isinstance(stat_value, float):
                stat_value = int(stat_value)
            stats_text += "\n  %s: %d" % [stat_key.capitalize(), stat_value]
        tooltip_stats.text = stats_text
    
    if item.get("value", 0) > 0:
        tooltip_value.text = "Value: %d gold" % item.get("value", 0)
    
    # Position tooltip
    var tooltip_rect = item_tooltip.get_rect()
    var screen_size = get_viewport_rect().size
    
    # Make sure tooltip stays within screen bounds
    var final_x = position.x + 20
    var final_y = position.y + 20
    
    if final_x + tooltip_rect.size.x > screen_size.x:
        final_x = position.x - tooltip_rect.size.x - 20
    if final_y + tooltip_rect.size.y > screen_size.y:
        final_y = position.y - tooltip_rect.size.y - 20
    
    item_tooltip.position = Vector2(final_x, final_y)
    item_tooltip.visible = true


func _hide_item_tooltip() -> void:
    """Hide the item tooltip."""
    item_tooltip.visible = false


func _on_slot_mouse_entered(slot: Control, item_id: String, event: InputEvent) -> void:
    """Handle mouse entering a slot to show tooltip."""
    if event is InputEventMouseMotion:
        _show_item_tooltip(slot, item_id, event.position)


func _on_slot_mouse_exited(slot: Control, item_id: String, event: InputEvent) -> void:
    """Handle mouse exiting a slot to hide tooltip."""
    if event is InputEventMouseMotion:
        _hide_item_tooltip()


# Gold management improvements
func _get_available_gold_display(gold_amount: int) -> String:
    """Format gold display with thousand separators."""
    return "{:,}".format(gold_amount) + "g"


func _calculate_inventory_weight(items: Array) -> float:
    """Calculate total weight of inventory items."""
    var total_weight: float = 0.0
    for item_id in items:
        var item = GameData.get_item(item_id)
        if not item.is_empty() and item.has("weight"):
            total_weight += item["weight"]
    return total_weight


func _get_inventory_weight_status(weight: float) -> Color:
    """Get color for weight status based on total weight."""
    if weight <= 20.0:
        return Color(0.2, 0.8, 0.2)  # Green - light load
    elif weight <= 40.0:
        return Color(0.9, 0.75, 0.1)  # Yellow - medium load
    else:
        return Color(0.85, 0.15, 0.15)  # Red - heavy load


func _get_inventory_summary() -> Dictionary:
    """Get a summary of current inventory status."""
    var summary = {
        "total_items": current_player.inventory.size() if current_player else 0,
        "gold": current_player.gold if current_player else 0,
        "weight": 0.0,
        "filter": current_filter,
        "max_slots": INVENTORY_SLOTS,
        "free_slots": INVENTORY_SLOTS,
        "weight_color": Color(0.2, 0.8, 0.2)
    }
    
    if current_player:
        var inventory = current_player.inventory
        summary["total_items"] = inventory.size()
        summary["gold"] = current_player.gold
        summary["weight"] = _calculate_inventory_weight(inventory)
        summary["weight_color"] = _get_inventory_weight_status(summary["weight"])
        
        # Calculate free slots (accounting for gold slot)
        var used_slots = 0
        for item_id in inventory:
            var item = GameData.get_item(item_id)
            if not item.is_empty():
                if item.get("stackable", false):
                    # Stackable items count as 1 slot
                    used_slots += 1
                else:
                    # Non-stackable items count as 1 slot
                    used_slots += 1
        
        summary["free_slots"] = INVENTORY_SLOTS - used_slots
    
    return summary


func _update_inventory_header() -> void:
    """Update inventory header with current filter and stats."""
    if not current_player:
        return
    
    var filters = _get_available_filters()
    var active_filter = filters[current_filter]
    
    # Update title bar with filter info
    var filter_text = active_filter["name"]
    if active_filter["count"] > 0:
        filter_text += " (%d)" % active_filter["count"]
    
    # Update gold display
    var gold_label = get_node("%s/GoldLabel" % $TitleBar/GoldContainer.name)
    if gold_label:
        gold_label.text = _get_available_gold_display(current_player.gold)


func _sort_inventory_items(items: Array, sort_by: String = "name") -> Array:
    """Sort inventory items by specified criteria."""
    var sorted_items = items.duplicate()
    
    sorted_items.sort_custom(func(a, b):
        var item_a = GameData.get_item(a)
        var item_b = GameData.get_item(b)
        
        if not item_a.is_empty() and not item_b.is_empty():
            match sort_by:
                "name":
                    return item_a["name"].to_lower() < item_b["name"].to_lower()
                "rarity":
                    var rarity_order = {"common": 0, "uncommon": 1, "rare": 2, "epic": 3, "legendary": 4}
                    var rarity_a = rarity_order.get(item_a.get("rarity", "common"), 0)
                    var rarity_b = rarity_order.get(item_b.get("rarity", "common"), 0)
                    return rarity_a < rarity_b
                "value":
                    var value_a = item_a.get("value", 0)
                    var value_b = item_b.get("value", 0)
                    return value_a < value_b
                _:
                    return a < b
        else:
            return a < b
    )
    
    return sorted_items


# Enhanced drag-and-drop system
func _setup_drag_drop_support() -> void:
    """Setup drag and drop support for enhanced inventory interaction."""
    # Connect to global input events for drag detection
    get_tree().get_root().connect("gui_focus_changed", _on_gui_focus_changed)
    
    # Add item drag detection
    if current_player:
        _setup_item_drag_detection()


func _setup_item_drag_detection() -> void:
    """Setup drag detection for inventory items."""
    for i in range(INVENTORY_SLOTS):
        var slot = item_slots[i] if i < item_slots.size() else null
        if slot:
            slot.gui_input.connect(_on_slot_input.bind(slot, i))


func _on_gui_focus_changed(node) -> void:
    """Handle GUI focus changes for inventory."""
    if not is_open:
        _hide_item_tooltip()


func _on_slot_input(slot: Control, index: int, event: InputEvent) -> void:
    """Handle various input events for inventory slots."""
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            _on_slot_clicked(slot, index, current_player.inventory[index] if index < current_player.inventory.size() else "", event)
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            _on_slot_right_clicked(slot, index)
    elif event is InputEventMouseMotion:
        # Show tooltip on hover if there's an item
        if index < current_player.inventory.size():
            var item_id = current_player.inventory[index]
            var item = GameData.get_item(item_id)
            if not item.is_empty():
                _show_item_tooltip(slot, item_id, event.position)


func _on_slot_right_clicked(slot: Control, index: int) -> void:
    """Handle right-click on inventory slot for quick actions."""
    if not current_player or index >= current_player.inventory.size():
        return
    
    var item_id = current_player.inventory[index]
    var item = GameData.get_item(item_id)
    
    if item.is_empty():
        return
    
    # Quick action based on item type
    if item["type"] == "consumable":
        _use_item(item_id)
    elif item["type"] == "weapon":
        _equip_item(item_id)
    elif item["type"] == "armor":
        _equip_item(item_id)
    else:
        # For other items, show basic info
        UIManager.show_notification(item["name"], "info")


# Inventory statistics and analytics
func _get_inventory_statistics() -> Dictionary:
    """Get comprehensive inventory statistics."""
    var stats = {
        "total_items": 0,
        "gold": 0,
        "items_by_type": {},
        "items_by_rarity": {},
        "total_value": 0,
        "average_weight": 0.0,
        "weight_limit": 20.0,
        "slots_used": 0,
        "slots_available": INVENTORY_SLOTS
    }
    
    if current_player:
        var inventory = current_player.inventory
        stats["total_items"] = inventory.size()
        stats["gold"] = current_player.gold
        
        # Count items by type and rarity
        for item_id in inventory:
            var item = GameData.get_item(item_id)
            if not item.is_empty():
                # Count by type
                var item_type = item.get("type", "unknown")
                if not stats["items_by_type"].has(item_type):
                    stats["items_by_type"][item_type] = 0
                stats["items_by_type"][item_type] += 1
                
                # Count by rarity
                var rarity = item.get("rarity", "common")
                if not stats["items_by_rarity"].has(rarity):
                    stats["items_by_rarity"][rarity] = 0
                stats["items_by_rarity"][rarity] += 1
                
                # Calculate total value
                stats["total_value"] += item.get("value", 0)
        
        # Calculate average weight
        if inventory.size() > 0:
            stats["average_weight"] = _calculate_inventory_weight(inventory) / inventory.size()
        
        # Calculate slots used (accounting for stackable items)
        var used_slots = 0
        for item_id in inventory:
            var item = GameData.get_item(item_id)
            if not item.is_empty():
                used_slots += 1  # Simplified: all items take 1 slot
        
        stats["slots_used"] = used_slots
        stats["slots_available"] = INVENTORY_SLOTS - used_slots
    
    return stats


func _display_inventory_statistics() -> void:
    """Display inventory statistics in a notification."""
    var stats = _get_inventory_statistics()
    
    var message = "Inventory Statistics:\n"
    message += "Items: %d/%d" % [stats["slots_used"], stats["slots_available"]]
    message += "\nGold: %d" % stats["gold"]
    message += "\nTotal Value: %d gold" % stats["total_value"]
    message += "\nWeight: %.1f / %.1f" % [stats["average_weight"], stats["weight_limit"]]
    
    # Add item type breakdown
    if stats["items_by_type"].size() > 0:
        message += "\n\nItem Types:"
        for item_type in stats["items_by_type"].keys():
            message += "\n  %s: %d" % [item_type.capitalize(), stats["items_by_type"][item_type]]
    
    # Add rarity breakdown
    if stats["items_by_rarity"].size() > 0:
        message += "\n\nBy Rarity:"
        for rarity in stats["items_by_rarity"].keys():
            message += "\n  %s: %d" % [rarity.capitalize(), stats["items_by_rarity"][rarity]]
    
    UIManager.show_notification(message, "info")


# Advanced inventory operations
func _stack_inventory_items() -> void:
    """Organize inventory by stacking similar items."""
    if not current_player:
        return
    
    var inventory = current_player.inventory.duplicate()
    var stacked_items: Array = []
    var item_counts: Dictionary = {}
    
    # Count items
    for item_id in inventory:
        if item_counts.has(item_id):
            item_counts[item_id] += 1
        else:
            item_counts[item_id] = 1
    
    # Create stacked inventory (limit stackable items to max_stack)
    for item_id in item_counts:
        var item = GameData.get_item(item_id)
        if item.is_empty():
            continue
        
        var count = item_counts[item_id]
        var max_stack = item.get("max_stack", 1)
        var stack_count = min(count, max_stack)
        
        # Add stacked items
        for i in range(stack_count):
            stacked_items.append(item_id)
        
        # If there are remaining items, create multiple stacks
        var remaining = count - stack_count
        while remaining > 0:
            stacked_items.append(item_id)
            remaining -= 1
    
    # Replace inventory with stacked version
    current_player.inventory = stacked_items
    SaveManager.save_game()
    _populate_slots()
    
    UIManager.show_notification("Inventory organized!", "success")


func _dump_inventory_to_file() -> void:
    """Export inventory data to a file for backup/analysis."""
    if not current_player:
        return
    
    var export_data = {
        "player_name": current_player.name,
        "gold": current_player.gold,
        "inventory": current_player.inventory.duplicate(),
        "equipment": current_player.equipment.duplicate(),
        "timestamp": Time.get_unix_time_from_system(),
        "version": GameManager.VERSION
    }
    
    # Create export file path
    var export_dir = "user://exports/"
    if not DirAccess.dir_exists_absolute(export_dir):
        DirAccess.make_dir_recursive_absolute(export_dir)
    
    var file_name = "inventory_%s_%d.json" % [current_player.name, Time.get_unix_time_from_system()]
    var file_path = export_dir + file_name
    
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file == null:
        UIManager.show_notification("Failed to export inventory", "error")
        return
    
    var json = JSON.new()
    json.data = export_data
    file.store_string(json.stringify(export_data, " "))
    file.close()
    
    UIManager.show_notification("Inventory exported to %s" % file_name, "success")
