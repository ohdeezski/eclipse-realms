extends Control
## Dialogue.gd - NPC conversation UI for Eclipse Realms
## Handles dialogue display, choice selection, and quest acceptance.
## Connects to UIManager.show_dialog("dialogue", data) from npc.gd.

signal dialogue_closed
signal option_selected(index: int)
signal quest_accepted(quest_id: String)
signal quest_declined(quest_id: String)

## UI References
@onready var panel: Panel = $Panel
@onready var npc_name_label: Label = $Panel/NameBar/NPCNameLabel
@onready var npc_title_label: Label = $Panel/NameBar/NPCTitleLabel
@onready var dialogue_text_label: RichTextLabel = $Panel/DialogueBox/DialogueTextLabel
@onready var choices_container: VBoxContainer = $Panel/DialogueBox/ChoicesContainer
@onready var portrait_rect: TextureRect = $Panel/Portrait/PortraitRect
@onready var continue_prompt: Label = $Panel/DialogueBox/ContinuePrompt
@onready var close_button: Button = $Panel/CloseButton

## Quest UI Elements
@onready var quest_panel: Panel = $Panel/QuestPanel
@onready var quest_name_label: Label = $Panel/QuestPanel/QuestNameLabel
@onready var quest_desc_label: RichTextLabel = $Panel/QuestPanel/QuestDescLabel
@onready var quest_rewards_label: RichTextLabel = $Panel/QuestPanel/QuestRewardsLabel
@onready var accept_button: Button = $Panel/QuestPanel/AcceptButton
@onready var decline_button: Button = $Panel/QuestPanel/DeclineButton

## State
var npc_id: String = ""
var npc_name: String = ""
var current_options: Array = []
var current_callback: Callable = Callable()
var is_typing: bool = false
var full_text: String = ""
var current_char_index: int = 0
var type_speed: float = 0.03
var current_quest_id: String = ""

## Typing effect timer
var _type_timer: Timer = null

func _ready() -> void:
	_setup_type_timer()
	_connect_signals()
	hide()
	quest_panel.visible = false


func _setup_type_timer() -> void:
	_type_timer = Timer.new()
	_type_timer.name = "TypeTimer"
	_type_timer.wait_time = type_speed
	_type_timer.timeout.connect(_on_type_timer_tick)
	add_child(_type_timer)


func _connect_signals() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if accept_button:
		accept_button.pressed.connect(_on_accept_pressed)
	if decline_button:
		decline_button.pressed.connect(_on_decline_pressed)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				_close_dialogue()
			KEY_SPACE, KEY_ENTER:
				if is_typing:
					_finish_typing()
				elif continue_prompt.visible:
					_close_dialogue()


## ============================================================================
## PUBLIC API
## ============================================================================

func setup(data: Dictionary) -> void:
	"""Configure the dialogue UI with data from UIManager.show_dialog"""
	npc_id = data.get("npc_id", "")
	npc_name = data.get("npc_name", "NPC")
	current_options = data.get("options", [])
	current_callback = data.get("callback", Callable())
	
	# Set NPC name
	if npc_name_label:
		npc_name_label.text = npc_name
	
	# Set NPC title if available
	var npc_title = data.get("npc_title", "")
	if npc_title_label:
		npc_title_label.text = npc_title
		npc_title_label.visible = npc_title != ""
	
	# Get the header text
	var header = data.get("header", "Hello, traveler.")
	
	# Show dialogue text with typing effect
	_show_text(header)
	
	# Build choice buttons
	_build_choices(current_options)
	
	# Hide quest panel by default
	quest_panel.visible = false
	
	# Show continue prompt for non-choice dialogue
	continue_prompt.visible = current_options.is_empty()


func show_quest_offer(quest_data: Dictionary) -> void:
	"""Display quest offer with accept/decline buttons"""
	current_quest_id = quest_data.get("id", "")
	
	if quest_name_label:
		quest_name_label.text = "New Quest: %s" % quest_data.get("name", "Unknown")
	
	if quest_desc_label:
		quest_desc_label.text = quest_data.get("description", "No description available.")
	
	if quest_rewards_label:
		var rewards_text = "Rewards:\n"
		var rewards = quest_data.get("rewards", {})
		if rewards.has("experience"):
			rewards_text += "  • %d Experience\n" % rewards["experience"]
		if rewards.has("gold"):
			rewards_text += "  • %d Gold\n" % rewards["gold"]
		if rewards.has("items"):
			for item_id in rewards["items"]:
				var item = GameData.get_item(item_id)
				rewards_text += "  • %s\n" % item.get("name", item_id)
		quest_rewards_label.text = rewards_text
	
	quest_panel.visible = true
	accept_button.visible = true
	decline_button.visible = true


func show_quest_status(quest_data: Dictionary) -> void:
	"""Display quest progress status"""
	if quest_name_label:
		quest_name_label.text = "Quest: %s" % quest_data.get("name", "Unknown")
	
	if quest_desc_label:
		var objectives_text = "Objectives:\n"
		var objectives = quest_data.get("objectives", [])
		for obj in objectives:
			var current = obj.get("current", 0)
			var target = obj.get("count", 1)
			objectives_text += "• %s: %d/%d\n" % [
				obj.get("description", obj.get("target", "")),
				current, target
			]
		quest_desc_label.text = objectives_text
	
	quest_panel.visible = true
	accept_button.visible = false
	decline_button.visible = false
	
	# Show continue prompt
	continue_prompt.visible = true


## ============================================================================
## DIALOGUE DISPLAY
## ============================================================================

func _show_text(text: String) -> void:
	"""Display text with typing effect"""
	full_text = text
	current_char_index = 0
	is_typing = true
	continue_prompt.visible = false
	
	if dialogue_text_label:
		dialogue_text_label.text = ""
		_type_timer.start()


func _on_type_timer_tick() -> void:
	"""Add one character at a time"""
	if current_char_index < full_text.length():
		current_char_index += 1
		dialogue_text_label.text = full_text.substr(0, current_char_index)
	else:
		_finish_typing()


func _finish_typing() -> void:
	"""Complete the typing effect immediately"""
	_type_timer.stop()
	is_typing = false
	current_char_index = full_text.length()
	if dialogue_text_label:
		dialogue_text_label.text = full_text
	
	# Show continue prompt or choices
	if current_options.is_empty():
		continue_prompt.visible = true
	else:
		continue_prompt.visible = false


## ============================================================================
## CHOICE BUTTONS
## ============================================================================

func _build_choices(options: Array) -> void:
	"""Create choice buttons from dialogue options"""
	# Clear existing choices
	for child in choices_container.get_children():
		child.queue_free()
	
	current_options = options
	
	for i in range(options.size()):
		var option = options[i]
		var button = Button.new()
		button.name = "Choice_%d" % i
		button.text = "%d. %s" % [i + 1, option.get("text", "")]
		button.custom_minimum_size = Vector2(400, 36)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Style the button
		_apply_choice_button_style(button)
		
		# Connect pressed signal
		button.pressed.connect(_on_choice_selected.bind(i))
		
		choices_container.add_child(button)


func _apply_choice_button_style(button: Button) -> void:
	"""Apply styling to choice buttons"""
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.15, 0.25, 0.8)
	normal_style.border_color = Color(0.3, 0.4, 0.6, 0.8)
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(4)
	normal_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.25, 0.35, 0.55, 0.9)
	hover_style.border_color = Color(0.4, 0.6, 0.9, 1.0)
	hover_style.set_border_width_all(1)
	hover_style.set_corner_radius_all(4)
	hover_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.2, 0.3, 0.5, 1.0)
	pressed_style.border_color = Color(0.5, 0.7, 1.0, 1.0)
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(4)
	pressed_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("pressed", pressed_style)


func _on_choice_selected(index: int) -> void:
	"""Handle choice button selection"""
	if index < current_options.size():
		var selected = current_options[index]
		option_selected.emit(index)
		
		# Execute callback if available
		if current_callback.is_valid():
			current_callback.call(index)


## ============================================================================
## QUEST UI
## ============================================================================

func _on_accept_pressed() -> void:
	"""Handle quest acceptance"""
	quest_accepted.emit(current_quest_id)
	quest_panel.visible = false
	
	# Close dialogue after accepting
	_close_dialogue()


func _on_decline_pressed() -> void:
	"""Handle quest decline"""
	quest_declined.emit(current_quest_id)
	quest_panel.visible = false
	
	# Show farewell message
	_show_text("Come back if you change your mind.")
	continue_prompt.visible = true


## ============================================================================
## CLOSE / CLEANUP
## ============================================================================

func _on_close_pressed() -> void:
	"""Handle close button press"""
	_close_dialogue()


func _close_dialogue() -> void:
	"""Close the dialogue UI"""
	_type_timer.stop()
	is_typing = false
	hide()
	dialogue_closed.emit()
	
	# Clear state
	current_options = []
	current_callback = Callable()
	current_quest_id = ""
	full_text = ""
	current_char_index = 0


func _on_area_input(event: InputEvent) -> void:
	"""Handle input on dialogue area (skip typing)"""
	if is_typing and event is InputEventMouseButton and event.pressed:
		_finish_typing()
