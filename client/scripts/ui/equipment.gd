extends Control
## Equipment.gd - Character equipment panel.
## Shows equipped gear per slot + computed stat totals.
## Reads from current_player.equipment (Dictionary keyed by slot -> item_id).
## Equip/unequip is handled by inventory.gd; this panel is a read-only view
## that also offers "Unequip" by clicking a filled slot.

signal equipment_closed
signal item_unequipped(slot: String, item_id: String)

const SLOT_ORDER: Array = ["weapon", "chest", "feet", "accessory", "consumable"]
const SLOT_LABELS: Dictionary = {
	"weapon": "Weapon",
	"chest": "Chest",
	"feet": "Feet",
	"accessory": "Accessory",
	"consumable": "Consumable",
	"main_hand": "Main Hand",
	"off_hand": "Off Hand",
	"head": "Head",
	"legs": "Legs",
	"ring": "Ring",
}

var current_player: Node = null
var is_open: bool = false

@onready var title_label: Label = $TitleBar/TitleLabel
@onready var close_button: Button = $TitleBar/CloseButton
@onready var slot_list: VBoxContainer = $SlotList
@onready var stat_label: Label = $StatPanel/StatLabel


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	hide()


func open_equipment(player: Node) -> void:
	if is_open:
		return
	current_player = player
	is_open = true
	show()
	center()
	_populate()
	if GameManager.current_state == GameManager.GameState.PLAYING:
		GameManager.pause_game()


func close_equipment() -> void:
	if not is_open:
		return
	is_open = false
	hide()
	if GameManager.current_state == GameManager.GameState.PAUSED:
		GameManager.resume_game()
	equipment_closed.emit()
	current_player = null


func toggle() -> void:
	if is_open:
		close_equipment()
	else:
		# Find the active player if none bound
		if current_player == null:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				current_player = players[0]
		open_equipment(current_player)


func _populate() -> void:
	if not current_player:
		return

	# Clear existing rows
	for child in slot_list.get_children():
		child.queue_free()

	var equipment: Dictionary = current_player.equipment if current_player.has_method("get") and "equipment" in current_player else {}
	# Fallback: some players store equipment as property directly
	if equipment.is_empty() and current_player.get("equipment") != null:
		equipment = current_player.equipment

	# Build a display order from SLOT_ORDER plus any extra slots present
	var display_slots: Array = SLOT_ORDER.duplicate()
	for slot in equipment.keys():
		if slot not in display_slots:
			display_slots.append(slot)

	for slot in display_slots:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 36)

		var slot_name := Label.new()
		slot_name.custom_minimum_size = Vector2(120, 0)
		slot_name.text = SLOT_LABELS.get(slot, slot.capitalize())
		slot_name.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 1))
		row.add_child(slot_name)

		var item_label := Label.new()
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var item_id: String = equipment.get(slot, "")
		if item_id != "":
			var item_data = GameData.get_item(item_id)
			if not item_data.is_empty():
				item_label.text = item_data["name"]
				item_label.add_theme_color_override("font_color", _rarity_color(item_data.get("rarity", "common")))
			else:
				item_label.text = item_id
				item_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5, 1))
		else:
			item_label.text = "— empty —"
			item_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		row.add_child(item_label)

		if item_id != "":
			var unequip_btn := Button.new()
			unequip_btn.text = "Unequip"
			unequip_btn.custom_minimum_size = Vector2(80, 28)
			unequip_btn.pressed.connect(_on_unequip_pressed.bind(slot, item_id))
			row.add_child(unequip_btn)

		slot_list.add_child(row)

	_update_stat_totals(equipment)


func _update_stat_totals(equipment: Dictionary) -> void:
	var totals := {"attack": 0, "defense": 0, "speed": 0, "health": 0, "mana": 0}
	for slot in equipment.keys():
		var item_id: String = equipment[slot]
		var item_data = GameData.get_item(item_id)
		if item_data.is_empty() or not item_data.has("stats"):
			continue
		for stat_key in item_data["stats"].keys():
			if totals.has(stat_key):
				totals[stat_key] += item_data["stats"][stat_key]

	var lines := PackedStringArray()
	lines.append("EQUIPPED STAT TOTALS")
	lines.append("Attack:  %d" % totals["attack"])
	lines.append("Defense: %d" % totals["defense"])
	lines.append("Speed:   %.2f" % totals["speed"])
	if totals["health"] > 0:
		lines.append("Health:  %d" % totals["health"])
	if totals["mana"] > 0:
		lines.append("Mana:    %d" % totals["mana"])
	stat_label.text = "\n".join(lines)


func _on_unequip_pressed(slot: String, item_id: String) -> void:
	if not current_player:
		return
	if current_player.has_method("unequip_item") and current_player.unequip_item(slot):
		item_unequipped.emit(slot, item_id)
		SaveManager.save_game()
		_populate()
		UIManager.show_notification("Unequipped: %s" % item_id, "info")


func _on_close_pressed() -> void:
	close_equipment()


func center() -> void:
	var viewport_size = get_viewport_rect().size
	position = (viewport_size - size) / 2


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.7, 0.7, 0.7, 1)
		"uncommon": return Color(0.2, 0.8, 0.2, 1)
		"rare": return Color(0.2, 0.5, 0.9, 1)
		"epic": return Color(0.6, 0.2, 0.9, 1)
		"legendary": return Color(0.9, 0.7, 0.1, 1)
		_: return Color(0.9, 0.9, 0.9, 1)
