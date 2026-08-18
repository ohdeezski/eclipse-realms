extends Node
## AudioManager.gd - Audio Management System
## Handles all sound and music playback with volume control, fading,
## zone-based music, combat music overlay, and ambient sounds.
## Load order: Third

## Signals
signal music_started(track_name: String)
signal music_stopped
signal sfx_played(sfx_name: String)
signal music_volume_changed(volume: float)
signal sfx_volume_changed(volume: float)
signal audio_initialized
signal combat_music_started
signal combat_music_ended
signal zone_audio_changed(zone_id: String)

## Constants
const AUDIO_DIR: String = "res://assets/audio/"
const MUSIC_DIR: String = AUDIO_DIR + "music/"
const SFX_DIR: String = AUDIO_DIR + "sfx/"
const VOICE_DIR: String = AUDIO_DIR + "voice/"
const AMBIENT_DIR: String = AUDIO_DIR + "ambient/"

const FADE_SPEED: float = 2.0  # Volume units per second
const SFX_POOL_SIZE: int = 8
const COMBAT_MUSIC_FADE: float = 0.5
const ZONE_MUSIC_FADE: float = 1.0

## Static variables
static var is_initialized: bool = false
static var music_enabled: bool = true
static var sfx_enabled: bool = true
static var music_volume: float = 1.0
static var sfx_volume: float = 1.0
static var master_volume: float = 1.0

## Audio streams cache
static var music_streams: Dictionary = {}
static var sfx_streams: Dictionary = {}

## Current playback state
static var current_music: String = ""
static var current_music_player: AudioStreamPlayer = null
static var target_music_volume: float = 0.0
static var fading_in: bool = false
static var fading_out: bool = false

## Zone audio state
static var current_zone: String = ""
static var zone_music_volume_scale: float = 1.0
static var zone_ambient_volume_scale: float = 0.3

## Combat music state
static var in_combat: bool = false
static var combat_music_track: String = ""
static var pre_combat_music: String = ""
static var combat_ambient_players: Array[AudioStreamPlayer] = []

## Ambient sound tracking
static var active_ambient_players: Dictionary = {}  # ambient_name -> Array[AudioStreamPlayer]
static var current_zone_ambient: Array[String] = []

## SFX player pool
static var sfx_player_pool: Array[AudioStreamPlayer] = []
static var active_sfx_players: Array[AudioStreamPlayer] = []

## Preloaded streams cache
static var preloaded_streams: Dictionary = {}


func _ready() -> void:
	if not is_initialized:
		_initialize()
		is_initialized = true


func initialize() -> void:
	if not is_initialized:
		_initialize()
		is_initialized = true


func _initialize() -> void:
	print("[AudioManager] Initializing audio system")

	# Load configuration from GameManager
	music_volume = GameManager.get_game_config("music_volume", 1.0)
	sfx_volume = GameManager.get_game_config("sfx_volume", 1.0)
	master_volume = GameManager.get_game_config("master_volume", GameManager.get_game_config("music_volume", 1.0))
	music_enabled = music_volume > 0
	sfx_enabled = sfx_volume > 0

	# Setup audio buses for mixing
	_setup_audio_buses()

	# Create SFX player pool
	_init_sfx_pool()

	# Preload common audio files
	_preload_essential_audio()

	print("[AudioManager] Audio system initialized")
	audio_initialized.emit()


func _process(delta: float) -> void:
	# Handle music fading
	if current_music_player and (fading_in or fading_out):
		var current_vol = current_music_player.volume_db
		var target_vol_db = linear_to_db(target_music_volume)

		if fading_in:
			current_music_player.volume_db = move_toward(
				current_vol,
				target_vol_db,
				FADE_SPEED * delta
			)
			if abs(current_vol - target_vol_db) < 0.1:
				fading_in = false
		elif fading_out:
			current_music_player.volume_db = move_toward(
				current_vol,
				-80.0,
				FADE_SPEED * delta
			)
			if current_music_player.volume_db < -79.0:
				current_music_player.stop()
				fading_out = false


func _setup_audio_buses() -> void:
	# Audio buses are configured in the Godot project settings.
	# Recommended bus structure:
	# - Master
	#   - Music (with effects: reverb, compressor)
	#   - SFX (with effects: compressor, limiter)
	#   - Voice (with effects: compressor, eq)
	#   - Ambient (with effects: reverb)
	print("[AudioManager] Audio buses configured in project settings")


func _init_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_player_pool.append(player)


func _preload_essential_audio() -> void:
	# Preload critical SFX that are used frequently
	var critical_sfx = [
		"player_attack", "player_hit", "enemy_hit", "enemy_death",
		"gold_pickup", "item_pickup", "quest_complete", "level_up",
		"button_click", "zone_transition"
	]
	for sfx_name in critical_sfx:
		preload_sound(sfx_name, "sfx")

	# Preload all music tracks listed in AudioConfig
	if has_node("/root/AudioConfig"):
		var tracks = AudioConfig.get_all_music_tracks()
		for track in tracks:
			preload_sound(track, "music")

	print("[AudioManager] Essential audio preloaded")


# ============================================================================
# MUSIC FUNCTIONS
# ============================================================================

func play_music(track_name: String, fade_duration: float = 1.0, volume_scale: float = 1.0) -> bool:
	if not music_enabled:
		return false

	# Skip if already playing this track
	if current_music == track_name and current_music_player and current_music_player.playing:
		return true

	# Stop current music if playing
	if current_music != "" and current_music != track_name:
		stop_music(fade_duration)

	var track_path: String = _resolve_music_path(track_name)
	if track_path == "":
		push_error("[AudioManager] Music track not found: %s" % track_name)
		return false

	# Create or reuse music player
	if current_music_player == null:
		current_music_player = AudioStreamPlayer.new()
		add_child(current_music_player)
		current_music_player.bus = "Music"

	# Load and play
	var stream = _load_stream(track_path)
	if stream == null:
		push_error("[AudioManager] Failed to load music: %s" % track_path)
		return false

	current_music_player.stream = stream
	current_music_player.volume_db = -80.0  # Start silent for fade-in
	current_music_player.play()

	# Set target volume with zone scale
	target_music_volume = music_volume * volume_scale
	fading_in = true
	fading_out = false

	current_music = track_name
	music_started.emit(track_name)

	print("[AudioManager] Playing music: %s (vol_scale=%.1f)" % [track_name, volume_scale])
	return true


func stop_music(fade_duration: float = 1.0) -> void:
	if current_music_player == null:
		return

	if fade_duration > 0:
		fading_out = true
		fading_in = false
	else:
		current_music_player.stop()
		current_music = ""
		music_stopped.emit()


func pause_music() -> void:
	if current_music_player and current_music_player.playing:
		current_music_player.pause()


func resume_music() -> void:
	if current_music_player and not current_music_player.playing:
		current_music_player.play()


func stop_all_music() -> void:
	stop_music(0.0)
	if current_music_player:
		current_music_player.queue_free()
		current_music_player = null


func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	GameManager.set_game_config("music_volume", music_volume)
	music_enabled = music_volume > 0.001

	if current_music_player:
		target_music_volume = music_volume * zone_music_volume_scale
		if not fading_in and not fading_out:
			current_music_player.volume_db = linear_to_db(target_music_volume)

	music_volume_changed.emit(music_volume)


func get_music_volume() -> float:
	return music_volume


func set_music_volume_scale(scale: float) -> void:
	"""Update the zone-based volume scale without changing the master setting."""
	zone_music_volume_scale = clamp(scale, 0.0, 1.0)
	if current_music_player and not fading_in and not fading_out:
		target_music_volume = music_volume * zone_music_volume_scale
		current_music_player.volume_db = linear_to_db(target_music_volume)


# ============================================================================
# ZONE-BASED AUDIO
# ============================================================================

func enter_zone(zone_id: String) -> void:
	"""Called by ZoneManager when the player enters a new zone.
	Handles music crossfade and ambient sound transitions."""
	if zone_id == current_zone:
		return

	var old_zone = current_zone
	current_zone = zone_id

	# Get zone audio config
	var zone_music = ""
	var zone_ambient: Array = []
	var music_vol_scale = 1.0
	var ambient_vol_scale = 0.3

	if has_node("/root/AudioConfig"):
		zone_music = AudioConfig.get_zone_music(zone_id)
		zone_ambient = AudioConfig.get_zone_ambient(zone_id)
		music_vol_scale = AudioConfig.get_zone_music_volume(zone_id)
		ambient_vol_scale = AudioConfig.get_zone_ambient_volume(zone_id)

	zone_music_volume_scale = music_vol_scale
	zone_ambient_volume_scale = ambient_vol_scale

	# Transition music (unless in combat)
	if not in_combat and zone_music != "":
		play_music(zone_music, ZONE_MUSIC_FADE, music_vol_scale)

	# Transition ambient sounds
	_transition_ambient(zone_ambient, ambient_vol_scale)

	zone_audio_changed.emit(zone_id)
	print("[AudioManager] Zone audio changed: %s -> %s" % [old_zone, zone_id])


func exit_zone() -> void:
	"""Called when player leaves a zone (before entering next)."""
	current_zone = ""
	_stop_all_ambient()


# ============================================================================
# COMBAT MUSIC
# ============================================================================

func start_combat_music() -> void:
	"""Switch to combat music. Saves the current overworld track for restoration."""
	if in_combat:
		return

	in_combat = true
	pre_combat_music = current_music

	# Determine combat track
	combat_music_track = "combat_theme"
	if has_node("/root/AudioConfig"):
		combat_music_track = AudioConfig.get_special_music("combat")

	# Fade to combat music
	if current_music_player:
		fading_out = true
		fading_in = false

	# Small delay then play combat music
	await get_tree().create_timer(COMBAT_MUSIC_FADE).timeout
	play_music(combat_music_track, COMBAT_MUSIC_FADE, 1.0)

	combat_music_started.emit()
	print("[AudioManager] Combat music started (was: %s)" % pre_combat_music)


func end_combat_music() -> void:
	"""Restore overworld music after combat ends."""
	if not in_combat:
		return

	in_combat = false

	# Fade out combat music
	if current_music_player:
		fading_out = true
		fading_in = false

	await get_tree().create_timer(COMBAT_MUSIC_FADE).timeout

	# Restore previous music or zone default
	if pre_combat_music != "":
		play_music(pre_combat_music, ZONE_MUSIC_FADE, zone_music_volume_scale)
	elif current_zone != "":
		var zone_music = ""
		if has_node("/root/AudioConfig"):
			zone_music = AudioConfig.get_zone_music(current_zone)
		if zone_music != "":
			play_music(zone_music, ZONE_MUSIC_FADE, zone_music_volume_scale)
	else:
		stop_music(ZONE_MUSIC_FADE)

	combat_music_ended.emit()
	print("[AudioManager] Combat music ended, restoring: %s" % pre_combat_music)


func get_in_combat() -> bool:
	return in_combat


# ============================================================================
# AMBIENT SOUND FUNCTIONS
# ============================================================================

func _transition_ambient(new_ambient: Array, volume_scale: float) -> void:
	"""Stop old ambient sounds and start new ones for the zone."""
	# Determine which sounds to stop and which to start
	var sounds_to_stop: Array[String] = []
	var sounds_to_start: Array[String] = []

	# Sounds to stop (in old zone but not in new)
	for ambient_name in current_zone_ambient:
		if not new_ambient.has(ambient_name):
			sounds_to_stop.append(ambient_name)

	# Sounds to start (in new zone but not already playing)
	for ambient_name in new_ambient:
		if not current_zone_ambient.has(ambient_name):
			sounds_to_start.append(ambient_name)

	# Stop old sounds
	for ambient_name in sounds_to_stop:
		stop_ambient(ambient_name)

	# Start new sounds
	for ambient_name in sounds_to_start:
		play_ambient(ambient_name, volume_scale)

	current_zone_ambient.clear()
	for ambient_name in new_ambient:
		current_zone_ambient.append(str(ambient_name))


func play_ambient(ambient_name: String, volume_scale: float = 0.3) -> AudioStreamPlayer:
	"""Play an ambient sound (loops continuously)."""
	if not sfx_enabled:
		return null

	var ambient_path: String = AMBIENT_DIR + "%s.ogg" % ambient_name
	if not ResourceLoader.exists(ambient_path):
		ambient_path = AMBIENT_DIR + "%s.mp3" % ambient_name
		if not ResourceLoader.exists(ambient_path):
			return null

	var player = AudioStreamPlayer.new()
	add_child(player)
	player.bus = "Ambient"

	var stream = _load_stream(ambient_path)
	if stream == null:
		player.queue_free()
		return null

	player.stream = stream
	# Ambient is quieter; use zone-specific volume scale
	player.volume_db = linear_to_db(sfx_volume * volume_scale * master_volume)
	player.play()

	# Track the player
	if not active_ambient_players.has(ambient_name):
		active_ambient_players[ambient_name] = []
	active_ambient_players[ambient_name].append(player)

	return player


func stop_ambient(ambient_name: String) -> void:
	"""Stop all instances of an ambient sound."""
	if active_ambient_players.has(ambient_name):
		for player in active_ambient_players[ambient_name]:
			if player and is_instance_valid(player):
				player.stop()
				player.queue_free()
		active_ambient_players[ambient_name].clear()
		active_ambient_players.erase(ambient_name)


func _stop_all_ambient() -> void:
	"""Stop all ambient sounds."""
	var names = active_ambient_players.keys()
	for ambient_name in names:
		stop_ambient(ambient_name)
	current_zone_ambient.clear()


func set_ambient_volume_scale(scale: float) -> void:
	"""Adjust ambient volume for the current zone."""
	zone_ambient_volume_scale = clamp(scale, 0.0, 1.0)
	for ambient_name in active_ambient_players:
		for player in active_ambient_players[ambient_name]:
			if player and is_instance_valid(player):
				player.volume_db = linear_to_db(sfx_volume * zone_ambient_volume_scale * master_volume)


# ============================================================================
# SFX FUNCTIONS
# ============================================================================

func play_sfx(sfx_name: String, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if not sfx_enabled:
		return null

	var sfx_path: String = _resolve_sfx_path(sfx_name)
	if sfx_path == "":
		push_warning("[AudioManager] SFX not found: %s" % sfx_name)
		return null

	# Get a player from pool or create new
	var player: AudioStreamPlayer = _get_sfx_player()
	if player == null:
		player = AudioStreamPlayer.new()
		add_child(player)
		player.bus = "SFX"
		active_sfx_players.append(player)

	# Configure and play
	var stream = _load_stream(sfx_path)
	if stream == null:
		push_error("[AudioManager] Failed to load SFX: %s" % sfx_path)
		return null

	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * volume_scale * master_volume)
	player.pitch_scale = pitch_scale
	player.play()

	# Return to pool when finished
	player.finished.connect(_on_sfx_finished.bind(player))

	sfx_played.emit(sfx_name)
	return player


func play_sfx_3d(sfx_name: String, position: Vector2, volume_scale: float = 1.0) -> AudioStreamPlayer:
	"""Play SFX with positional attenuation (simplified 2D for now)."""
	if not sfx_enabled:
		return null

	# Calculate volume based on distance from camera center
	var cam = get_viewport().get_camera_2d()
	if cam:
		var dist = position.distance_to(cam.global_position)
		var max_dist = 800.0  # Max audible distance
		var attenuation = clamp(1.0 - (dist / max_dist), 0.1, 1.0)
		return play_sfx(sfx_name, volume_scale * attenuation)
	return play_sfx(sfx_name, volume_scale)


func play_random_sfx(sfx_names: Array, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	"""Play a random SFX from a list."""
	if sfx_names.is_empty():
		return null
	var idx = randi() % sfx_names.size()
	return play_sfx(sfx_names[idx], volume_scale, pitch_scale)


func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	"""Return player to pool after SFX finishes."""
	player.stream = null
	player.volume_db = 0.0
	player.pitch_scale = 1.0

	var index = active_sfx_players.find(player)
	if index != -1:
		active_sfx_players.remove_at(index)
		sfx_player_pool.append(player)


func _get_sfx_player() -> AudioStreamPlayer:
	if sfx_player_pool.size() > 0:
		var player = sfx_player_pool.pop_back()
		active_sfx_players.append(player)
		return player
	return null


func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	GameManager.set_game_config("sfx_volume", sfx_volume)
	sfx_enabled = sfx_volume > 0.001
	sfx_volume_changed.emit(sfx_volume)


func get_sfx_volume() -> float:
	return sfx_volume


# ============================================================================
# MASTER CONTROLS
# ============================================================================

func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)

	# Update all active players
	if current_music_player:
		current_music_player.volume_db = linear_to_db(music_volume * zone_music_volume_scale * master_volume)

	for player in active_sfx_players:
		if player.stream:
			player.volume_db = linear_to_db(sfx_volume * master_volume)

	for ambient_name in active_ambient_players:
		for player in active_ambient_players[ambient_name]:
			if player and is_instance_valid(player):
				player.volume_db = linear_to_db(sfx_volume * zone_ambient_volume_scale * master_volume)


func get_master_volume() -> float:
	return master_volume


func stop_all() -> void:
	stop_all_music()
	_stop_all_ambient()
	for player in active_sfx_players:
		player.stop()
		player.stream = null
	active_sfx_players.clear()
	sfx_player_pool.clear()
	in_combat = false


func toggle_music() -> bool:
	music_enabled = not music_enabled
	if music_enabled:
		resume_music()
	else:
		pause_music()
	return music_enabled


func toggle_sfx() -> bool:
	sfx_enabled = not sfx_enabled
	return sfx_enabled


# ============================================================================
# VOICE FUNCTIONS (for NPC dialogue, etc.)
# ============================================================================

func play_voice(voice_name: String, character: String = "") -> AudioStreamPlayer:
	if not sfx_enabled:
		return null

	var voice_path: String = VOICE_DIR + "%s/%s.ogg" % [character, voice_name]
	if not ResourceLoader.exists(voice_path):
		voice_path = VOICE_DIR + "%s.ogg" % voice_name
		if not ResourceLoader.exists(voice_path):
			return null

	var player = AudioStreamPlayer.new()
	add_child(player)
	player.bus = "Voice"

	var stream = _load_stream(voice_path)
	if stream == null:
		player.queue_free()
		return null

	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * master_volume)
	player.play()

	player.finished.connect(_on_voice_finished.bind(player))
	return player


func _on_voice_finished(player: AudioStreamPlayer) -> void:
	player.stream = null
	player.queue_free()


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func _resolve_music_path(track_name: String) -> String:
	"""Find the actual file path for a music track (ogg/mp3/wav supported)."""
	var ogg_path = MUSIC_DIR + "%s.ogg" % track_name
	if ResourceLoader.exists(ogg_path):
		return ogg_path
	var mp3_path = MUSIC_DIR + "%s.mp3" % track_name
	if ResourceLoader.exists(mp3_path):
		return mp3_path
	var wav_path = MUSIC_DIR + "%s.wav" % track_name
	if ResourceLoader.exists(wav_path):
		return wav_path
	return ""


func _resolve_sfx_path(sfx_name: String) -> String:
	"""Find the actual file path for an SFX (ogg/mp3/wav supported)."""
	var ogg_path = SFX_DIR + "%s.ogg" % sfx_name
	if ResourceLoader.exists(ogg_path):
		return ogg_path
	var mp3_path = SFX_DIR + "%s.mp3" % sfx_name
	if ResourceLoader.exists(mp3_path):
		return mp3_path
	var wav_path = SFX_DIR + "%s.wav" % sfx_name
	if ResourceLoader.exists(wav_path):
		return wav_path
	return ""


func _load_stream(path: String) -> AudioStream:
	"""Load an audio stream, using cache when available."""
	if preloaded_streams.has(path):
		return preloaded_streams[path]
	var stream = load(path)
	if stream != null:
		preloaded_streams[path] = stream
	return stream


func fade_music_to(track_name: String, fade_out_duration: float = 1.0, fade_in_duration: float = 1.0) -> bool:
	if not music_enabled:
		return false

	if current_music != "" and current_music != track_name:
		fading_out = true
		await current_music_player.finished

	return play_music(track_name, fade_in_duration)


func is_music_playing() -> bool:
	return current_music_player != null and current_music_player.playing


func get_current_music() -> String:
	return current_music


func preload_sound(sound_name: String, sound_type: String = "sfx") -> bool:
	"""Pre-load a sound into memory for faster playback."""
	var path: String

	match sound_type:
		"music":
			path = MUSIC_DIR + "%s.ogg" % sound_name
		"sfx":
			path = SFX_DIR + "%s.ogg" % sound_name
		"voice":
			path = VOICE_DIR + "%s.ogg" % sound_name
		"ambient":
			path = AMBIENT_DIR + "%s.ogg" % sound_name
		_:
			path = AUDIO_DIR + "%s.ogg" % sound_name

	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream != null:
			preloaded_streams[path] = stream
			return true

	# Try mp3 fallback
	var mp3_path = path.replace(".ogg", ".mp3")
	if ResourceLoader.exists(mp3_path):
		var stream = load(mp3_path)
		if stream != null:
			preloaded_streams[mp3_path] = stream
			return true

	# Try wav fallback
	var wav_path = path.replace(".ogg", ".wav")
	if ResourceLoader.exists(wav_path):
		var stream = load(wav_path)
		if stream != null:
			preloaded_streams[wav_path] = stream
			return true

	return false


func preload_all_zone_audio() -> void:
	"""Preload all audio for the current zone (music + ambient)."""
	if current_zone == "":
		return

	if has_node("/root/AudioConfig"):
		var track = AudioConfig.get_zone_music(current_zone)
		if track != "":
			preload_sound(track, "music")
		var ambient_list = AudioConfig.get_zone_ambient(current_zone)
		for ambient_name in ambient_list:
			preload_sound(ambient_name, "ambient")


# Static utility methods
static func linear_to_db(linear_volume: float) -> float:
	if linear_volume <= 0:
		return -80.0
	return 20.0 * log(linear_volume) / log(10.0)


static func db_to_linear(db_volume: float) -> float:
	return pow(10.0, db_volume / 20.0)
