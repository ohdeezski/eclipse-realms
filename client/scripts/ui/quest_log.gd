extends Control
## QuestLog.gd - Quest log UI for Eclipse Realms
## Displays active and completed quests with objectives and rewards.
## Toggled via the quest_log input action (default: N key).

signal quest_log_opened
signal quest_log_closed

const QUEST_ITEM_HEIGHT: int = 80
const QUEST_PADDING: int = 8

var current_player: Node = null
var is_open: bool = false
var selected_quest_id: String = ""

# UI nodes (built in _ready if missing from scene tree)
@onready var background: Panel = $Background if has_node("Background") else null
@onready var title_bar: Panel = $TitleBar if has_node("TitleBar") else null
@onready var title_label: Label = $TitleBar/TitleLabel if has_node("TitleBar/TitleLabel") else null
@onready var close_button: Button = $TitleBar/CloseButton if has_node("TitleBar/CloseButton") else null
@onready var tab_container: TabContainer = $TabContainer if has_node("TabContainer") else null
@onready var active_list: Control = $TabContainer/ActiveTab/ActiveList if has_node("TabContainer/ActiveTab/ActiveList") else null
@onready var completed_list: Control = $TabContainer/CompletedTab/CompletedList if has_node("TabContainer/CompletedTab/CompletedList") else null
@onready var detail_panel: Panel = $DetailPanel if has_node("DetailPanel") else null
@onready var detail_label: Label = $DetailPanel/DetailLabel if has_node("DetailPanel/DetailLabel") else null

# Content containers for quest items
var active_content: Control = null
var completed_content: Control = null


func _ready() -> void:
	add_to_group("quest_log")

	# Build UI programmatically if scene nodes are missing (fallback)
	if background == null:
		_build_ui()

	# Wire up close button
	if close_button and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open and event.is_action_pressed("quest_log"):
		get_viewport().set_input_as_handled()
		# Find player reference lazily
		if current_player == null:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				current_player = players[0]
		if current_player:
			open_quest_log()
	elif is_open and (event.is_action_pressed("quest_log") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		close_quest_log()


# ============================================================================
# OPEN / CLOSE
# ============================================================================

func open_quest_log() -> void:
	if is_open:
		return

	is_open = true
	show()
	center()
	_refresh_quest_list()

	# Pause game while log is open
	if GameManager.current_state == GameManager.GameState.PLAYING:
		GameManager.pause_game()

	quest_log_opened.emit()
	print("[QuestLog] Opened")


func close_quest_log() -> void:
	if not is_open:
		return

	is_open = false
	hide()
	selected_quest_id = ""

	# Resume game
	if GameManager.current_state == GameManager.GameState.PAUSED:
		GameManager.resume_game()

	quest_log_closed.emit()
	print("[QuestLog] Closed")


func toggle() -> void:
	if is_open:
		close_quest_log()
	else:
		if current_player == null:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				current_player = players[0]
		if current_player:
			open_quest_log()


func center() -> void:
	var viewport_size = get_viewport_rect().size
	var panel_size = size if size != Vector2.ZERO else Vector2(520, 400)
	position = (viewport_size - panel_size) / 2


# ============================================================================
# REFRESH QUEST DATA
# ============================================================================

func _refresh_quest_list() -> void:
	_populate_active_quests()
	_populate_completed_quests()
	_update_detail_panel()


func _populate_active_quests() -> void:
	if active_list == null or current_player == null:
		return

	# Clear existing children
	for child in active_list.get_children():
		child.queue_free()

	var active_quests: Dictionary = current_player.active_quests
	if active_quests.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No active quests"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		active_list.add_child(empty_label)
		return

	for quest_id in active_quests.keys():
		var quest_data = GameData.get_quest(quest_id)
		if quest_data.is_empty():
			continue

		var progress: int = active_quests[quest_id].get("current", 0)
		var objectives: Array = quest_data.get("objectives", [])
		var target_count: int = objectives[0].get("count", 1) if objectives.size() > 0 else 1

		var item = _create_quest_item(quest_data, progress, target_count, false)
		var btn: Button = item.get_node("Button") if item.has_node("Button") else null
		if btn:
			btn.pressed.connect(_on_quest_selected.bind(quest_id))
		active_list.add_child(item)


func _populate_completed_quests() -> void:
	if completed_list == null or current_player == null:
		return

	# Clear existing children
	for child in completed_list.get_children():
		child.queue_free()

	var completed: Array = current_player.completed_quests
	if completed.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No completed quests"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		completed_list.add_child(empty_label)
		return

	for quest_id in completed:
		var quest_data = GameData.get_quest(quest_id)
		if quest_data.is_empty():
			continue

		var objectives: Array = quest_data.get("objectives", [])
		var target_count: int = objectives[0].get("count", 1) if objectives.size() > 0 else 1

		var item = _create_quest_item(quest_data, target_count, target_count, true)
		var btn: Button = item.get_node("Button") if item.has_node("Button") else null
		if btn:
			btn.pressed.connect(_on_quest_selected.bind(quest_id))
		completed_list.add_child(item)


# ============================================================================
# QUEST ITEM CREATION
# ============================================================================

func _create_quest_item(quest_data: Dictionary, progress: int, target_count: int, completed: bool) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, QUEST_ITEM_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Background style
	var bg_style = StyleBoxFlat.new()
	if completed:
		bg_style.bg_color = Color(0.15, 0.15, 0.2, 0.6)
	else:
		bg_style.bg_color = Color(0.12, 0.14, 0.22, 0.8)
	bg_style.set_corner_radius_all(4)
	bg_style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", bg_style)

	# Clickable button overlay
	var btn = Button.new()
	btn.name = "Button"
	btn.anchor_right = 1.0
	btn.anchor_bottom = 1.0
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Make button transparent
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(1, 1, 1, 0.08)
	btn.add_theme_stylebox_override("hover", btn_hover)
	panel.add_child(btn)

	# Quest name
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = quest_data.get("name", "Unknown Quest")
	name_label.position = Vector2(10, 6)
	name_label.size = Vector2(300, 22)
	name_label.add_theme_font_size_override("font_size", 16)
	if completed:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
	else:
		name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	panel.add_child(name_label)

	# Progress text
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	if completed:
		progress_label.text = "Complete"
		progress_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	else:
		progress_label.text = "%d / %d" % [progress, target_count]
		progress_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	progress_label.position = Vector2(10, 30)
	progress_label.size = Vector2(200, 18)
	progress_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(progress_label)

	# Description (truncated)
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	var desc_text: String = quest_data.get("description", "")
	if desc_text.length() > 60:
		desc_text = desc_text.substr(0, 57) + "..."
	desc_label.text = desc_text
	desc_label.position = Vector2(10, 50)
	desc_label.size = Vector2(400, 18)
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	panel.add_child(desc_label)

	# Reward icons on the right side
	var reward_text = _format_rewards_inline(quest_data.get("rewards", {}))
	if reward_text != "":
		var reward_label = Label.new()
		reward_label.name = "RewardLabel"
		reward_label.text = reward_text
		reward_label.position = Vector2(300, 6)
		reward_label.size = Vector2(200, 22)
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		reward_label.add_theme_font_size_override("font_size", 12)
		reward_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
		panel.add_child(reward_label)

	return panel


# ============================================================================
# DETAIL PANEL
# ============================================================================

func _on_quest_selected(quest_id: String) -> void:
	selected_quest_id = quest_id
	_update_detail_panel()


func _update_detail_panel() -> void:
	if detail_label == null:
		return

	if selected_quest_id == "":
		detail_label.text = "Select a quest to view details"
		return

	var quest_data = GameData.get_quest(selected_quest_id)
	if quest_data.is_empty():
		detail_label.text = "Quest data not found"
		return

	var is_active = current_player and current_player.active_quests.has(selected_quest_id)
	var is_completed = current_player and selected_quest_id in current_player.completed_quests

	var text: String = ""
	text += quest_data.get("name", "Unknown Quest") + "\n"
	text += "---\n"
	text += quest_data.get("description", "No description") + "\n\n"

	# Objectives
	var objectives: Array = quest_data.get("objectives", [])
	if objectives.size() > 0:
		text += "Objectives:\n"
		for obj in objectives:
			var current: int = 0
			if is_active and current_player:
				current = current_player.active_quests[selected_quest_id].get("current", 0)
			elif is_completed:
				current = obj.get("count", 1)
			var target: int = obj.get("count", 1)
			var desc: String = obj.get("description", obj.get("target", ""))
			text += "  - %s: %d/%d\n" % [desc, current, target]

	# Rewards
	var rewards: Dictionary = quest_data.get("rewards", {})
	text += "\nRewards:\n"
	if rewards.has("experience"):
		text += "  - %d Experience\n" % rewards["experience"]
	if rewards.has("gold"):
		text += "  - %d Gold\n" % rewards["gold"]
	if rewards.has("items"):
		for item_id in rewards["items"]:
			var item_data = GameData.get_item(item_id)
			var item_name: String = item_data.get("name", item_id) if not item_data.is_empty() else item_id
			text += "  - %s\n" % item_name

	# Status
	text += "\nStatus: "
	if is_completed:
		text += "Completed"
	elif is_active:
		text += "In Progress"
	else:
		text += "Not Accepted"

	detail_label.text = text


func _format_rewards_inline(rewards: Dictionary) -> String:
	var parts: Array = []
	if rewards.has("experience"):
		parts.append("%d XP" % rewards["experience"])
	if rewards.has("gold"):
		parts.append("%d G" % rewards["gold"])
	return " | ".join(parts)


# ============================================================================
# PROGRAMMATIC UI BUILD (fallback if scene tree is bare)
# ============================================================================

func _build_ui() -> void:
	# Full-screen background overlay
	background = Panel.new()
	background.name = "Background"
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.85)
	background.add_theme_stylebox_override("panel", bg_style)
	add_child(background)

	# Main panel (centered)
	var main_panel = Panel.new()
	main_panel.name = "MainPanel"
	main_panel.custom_minimum_size = Vector2(520, 400)
	main_panel.size = Vector2(520, 400)
	main_panel.anchor_right = 0.5
	main_panel.anchor_bottom = 0.5
	main_panel.anchor_left = 0.5
	main_panel.anchor_top = 0.5
	main_panel.position = Vector2(-260, -200)
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.08, 0.08, 0.14, 0.95)
	main_style.border_color = Color(0.35, 0.3, 0.5)
	main_style.set_border_width_all(2)
	main_style.set_corner_radius_all(6)
	main_style.set_content_margin_all(12)
	main_panel.add_theme_stylebox_override("panel", main_style)
	add_child(main_panel)

	# Title bar
	title_bar = Panel.new()
	title_bar.name = "TitleBar"
	title_bar.anchor_right = 1.0
	title_bar.custom_minimum_size = Vector2(0, 36)
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.15, 0.13, 0.25)
	title_style.set_corner_radius_all(4)
	title_bar.add_theme_stylebox_override("panel", title_style)
	main_panel.add_child(title_bar)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Quest Log"
	title_label.position = Vector2(12, 8)
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	title_bar.add_child(title_label)

	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "X"
	close_button.anchor_left = 1.0
	close_button.anchor_right = 1.0
	close_button.position = Vector2(-36, 6)
	close_button.custom_minimum_size = Vector2(28, 24)
	close_button.pressed.connect(_on_close_pressed)
	title_bar.add_child(close_button)

	# Tab container
	tab_container = TabContainer.new()
	tab_container.name = "TabContainer"
	tab_container.anchor_top = 0.12
	tab_container.anchor_right = 0.6
	tab_container.anchor_bottom = 1.0
	tab_container.position = Vector2(0, 0)
	main_panel.add_child(tab_container)

	# Active tab
	var active_tab = ScrollContainer.new()
	active_tab.name = "ActiveTab"
	active_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_container.add_child(active_tab)

	active_list = ScrollContainer.new()
	active_list.name = "ActiveList"
	active_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_tab.add_child(active_list)
	
	# Active tab content container (VBoxContainer for quest items)
	var active_content = VBoxContainer.new()
	active_content.name = "ActiveContent"
	active_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_content.add_theme_constant_override("separation", 4)
	active_list.add_child(active_content)

	# Completed tab
	var completed_tab = ScrollContainer.new()
	completed_tab.name = "CompletedTab"
	completed_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_container.add_child(completed_tab)

	completed_list = ScrollContainer.new()
	completed_list.name = "CompletedList"
	completed_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	completed_tab.add_child(completed_list)
	
	var completed_content = VBoxContainer.new()
	completed_content.name = "CompletedContent"
	completed_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	completed_content.add_theme_constant_override("separation", 4)
	completed_list.add_child(completed_content)

	# Detail panel (right side)
	detail_panel = Panel.new()
	detail_panel.name = "DetailPanel"
	detail_panel.anchor_top = 0.12
	detail_panel.anchor_right = 1.0
	detail_panel.anchor_bottom = 1.0
	detail_panel.position = Vector2(0, 0)
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = Color(0.1, 0.1, 0.18, 0.9)
	detail_style.set_corner_radius_all(4)
	detail_style.set_content_margin_all(10)
	detail_panel.add_theme_stylebox_override("panel", detail_style)
	main_panel.add_child(detail_panel)

	detail_label = Label.new()
	detail_label.name = "DetailLabel"
	detail_label.anchor_right = 1.0
	detail_label.anchor_bottom = 1.0
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 14)
	detail_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	detail_panel.add_child(detail_label)

	size = main_panel.size


# ============================================================================
# CALLBACKS
# ============================================================================

func _on_close_pressed() -> void:
	close_quest_log()
