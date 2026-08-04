extends Control
## Settings.gd - Settings Menu Controller
## Handles audio, graphics, and control settings persistence

@onready var master_volume_slider: HSlider = $SettingsContainer/AudioSection/MasterVolumeSlider
@onready var master_volume_label: Label = $SettingsContainer/AudioSection/MasterVolumeLabel
@onready var music_volume_slider: HSlider = $SettingsContainer/AudioSection/MusicVolumeSlider
@onready var music_volume_label: Label = $SettingsContainer/AudioSection/MusicVolumeLabel
@onready var sfx_volume_slider: HSlider = $SettingsContainer/AudioSection/SFXVolumeSlider
@onready var sfx_volume_label: Label = $SettingsContainer/AudioSection/SFXVolumeLabel
@onready var vsync_check: CheckButton = $SettingsContainer/GraphicsSection/VSyncCheck
@onready var fullscreen_check: CheckButton = $SettingsContainer/GraphicsSection/FullscreenCheck
@onready var back_btn: Button = $ButtonContainer/BackButton
@onready var apply_btn: Button = $ButtonContainer/ApplyButton


func _ready() -> void:
	# Load current settings
	_load_settings()
	
	# Connect signals
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	back_btn.pressed.connect(_on_back_pressed)
	apply_btn.pressed.connect(_on_apply_pressed)
	
	# Focus first slider for gamepad
	master_volume_slider.grab_focus()
	
	# Keep menu music playing
	if AudioManager:
		AudioManager.play_music("main_menu")
	
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	print("[Settings] Settings menu ready")


func _load_settings() -> void:
	var config = GameManager.config
	
	master_volume_slider.value = config.get("master_volume", 1.0)
	music_volume_slider.value = config.get("music_volume", 1.0)
	sfx_volume_slider.value = config.get("sfx_volume", 1.0)
	vsync_check.button_pressed = config.get("vsync", true)
	fullscreen_check.button_pressed = config.get("fullscreen", false)
	
	_update_labels()


func _update_labels() -> void:
	master_volume_label.text = "Master Volume: %d%%" % (master_volume_slider.value * 100)
	music_volume_label.text = "Music Volume: %d%%" % (music_volume_slider.value * 100)
	sfx_volume_label.text = "SFX Volume: %d%%" % (sfx_volume_slider.value * 100)


func _on_master_volume_changed(value: float) -> void:
	master_volume_label.text = "Master Volume: %d%%" % (value * 100)
	if AudioManager:
		AudioManager.set_master_volume(value)


func _on_music_volume_changed(value: float) -> void:
	music_volume_label.text = "Music Volume: %d%%" % (value * 100)
	if AudioManager:
		AudioManager.set_music_volume(value)


func _on_sfx_volume_changed(value: float) -> void:
	sfx_volume_label.text = "SFX Volume: %d%%" % (value * 100)
	if AudioManager:
		AudioManager.set_sfx_volume(value)


func _on_apply_pressed() -> void:
	# Save settings
	var config = {
		"master_volume": master_volume_slider.value,
		"music_volume": music_volume_slider.value,
		"sfx_volume": sfx_volume_slider.value,
		"vsync": vsync_check.button_pressed,
		"fullscreen": fullscreen_check.button_pressed,
	}
	
	for key in config:
		GameManager.set_game_config(key, config[key])
	
	SaveManager.save_config(config)
	
	# Apply graphics settings
	if OS.has_feature("vsync"):
		OS.vsync_enabled = vsync_check.button_pressed
	if OS.has_feature("fullscreen"):
		OS.window_fullscreen = fullscreen_check.button_pressed
	
	print("[Settings] Settings applied and saved")


func _on_back_pressed() -> void:
	# Ask to save if there are unsaved changes
	_on_apply_pressed()
	SceneManager.change_scene("res://scenes/main_menu/main_menu.tscn", "fade")