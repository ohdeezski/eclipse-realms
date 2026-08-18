extends Control
## MainMenu.gd - Main Menu UI Controller
## Handles main menu navigation, settings, and game start

## Signals
signal start_game_requested
signal open_settings_requested
signal open_credits_requested
signal quit_game_requested


func _ready() -> void:
	# Connect button signals
	$MenuContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$MenuContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$MenuContainer/CreditsButton.pressed.connect(_on_credits_pressed)
	$MenuContainer/QuitButton.pressed.connect(_on_quit_pressed)
	
	# Focus first button for gamepad navigation
	$MenuContainer/NewGameButton.grab_focus()
	
	# Initialize audio
	if AudioManager:
		AudioManager.play_music(AudioConfig.get_special_music("main_menu"))
	
	print("[MainMenu] Main menu ready")


func _on_new_game_pressed() -> void:
	print("[MainMenu] New Game pressed")
	# Transition to character creation
	call_deferred("_transition_to_character_creation")


func _transition_to_character_creation() -> void:
	SceneManager.change_scene("res://scenes/ui/character_creation.tscn", "fade")


func _on_settings_pressed() -> void:
	print("[MainMenu] Settings pressed")
	call_deferred("_transition_to_settings")


func _transition_to_settings() -> void:
	SceneManager.change_scene("res://scenes/ui/settings.tscn", "fade")


func _on_credits_pressed() -> void:
	print("[MainMenu] Credits pressed")
	call_deferred("_transition_to_credits")


func _transition_to_credits() -> void:
	SceneManager.change_scene("res://scenes/ui/credits.tscn", "fade")


func _on_quit_pressed() -> void:
	print("[MainMenu] Quit pressed")
	quit_game_requested.emit()
	
	# Actually quit the game
	if GameManager:
		GameManager.quit_game()
	else:
		get_tree().quit()
