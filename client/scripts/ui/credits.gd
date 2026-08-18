extends Control
## Credits.gd - Credits Screen
## Displays development credits and acknowledgments

@onready var back_btn: Button = $BackButton


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	back_btn.grab_focus()
	
	if AudioManager:
		AudioManager.play_music(AudioConfig.get_special_music("main_menu"))
	
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	print("[Credits] Credits screen ready")


func _on_back_pressed() -> void:
	SceneManager.change_scene("res://scenes/main_menu/main_menu.tscn", "fade")
