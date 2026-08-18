extends Node
## AudioConfig.gd - Audio Configuration Data
## Maps zones to music tracks, ambient sounds, and defines SFX categories.
## Central reference for all audio asset names used by AudioManager.

## ============================================================================
## ZONE MUSIC MAPPING
## ============================================================================

## Maps zone_id -> { "music": track_name, "ambient": [ambient_names] }
const ZONE_AUDIO: Dictionary = {
	"village": {
		"music": "village_theme",
		"ambient": ["village_ambient", "birds"],
		"music_volume_scale": 0.8,
		"ambient_volume_scale": 0.3,
	},
	"forest": {
		"music": "forest_theme",
		"ambient": ["forest_ambient", "birds", "wind_gentle"],
		"music_volume_scale": 0.9,
		"ambient_volume_scale": 0.4,
	},
	"caverns": {
		"music": "caverns_theme",
		"ambient": ["cavern_drip", "cavern_wind"],
		"music_volume_scale": 1.0,
		"ambient_volume_scale": 0.35,
	},
	"training": {
		"music": "training_theme",
		"ambient": [],
		"music_volume_scale": 0.7,
		"ambient_volume_scale": 0.0,
	},
	"blacksmith": {
		"music": "village_theme",
		"ambient": ["fire_crackle"],
		"music_volume_scale": 0.6,
		"ambient_volume_scale": 0.25,
	},
	"inn": {
		"music": "inn_theme",
		"ambient": ["fire_crackle"],
		"music_volume_scale": 0.7,
		"ambient_volume_scale": 0.2,
	},
	"merchant": {
		"music": "village_theme",
		"ambient": ["crowd_murmur"],
		"music_volume_scale": 0.6,
		"ambient_volume_scale": 0.2,
	},
	"hunters_camp": {
		"music": "forest_theme",
		"ambient": ["campfire", "crickets"],
		"music_volume_scale": 0.8,
		"ambient_volume_scale": 0.3,
	},
	"creek": {
		"music": "forest_theme",
		"ambient": ["wind_gentle", "birds"],
		"music_volume_scale": 0.8,
		"ambient_volume_scale": 0.35,
	},
	"watchtower": {
		"music": "forest_theme",
		"ambient": ["wind_gentle"],
		"music_volume_scale": 0.7,
		"ambient_volume_scale": 0.25,
	},
}

## Scene boundary IDs that share an existing audio profile. Keeping this mapping
## here prevents world scenes from inventing track names that are not exported.
const ZONE_AUDIO_ALIASES: Dictionary = {
	"entrance": "forest",
	"clearing": "forest",
	"deep_forest": "forest",
	"cavern": "caverns",
	"camp": "hunters_camp",
}

## ============================================================================
## SPECIAL MUSIC STATES
## ============================================================================

## Music for special game states (combat, boss, etc.)
const SPECIAL_MUSIC: Dictionary = {
	"combat": "combat_theme",
	"boss": "boss_theme",
	"victory": "victory_sting",
	"defeat": "defeat_music",
	"main_menu": "main_menu_theme",
	"game_over": "defeat_music",
}

## ============================================================================
## SFX CATEGORIES
## ============================================================================

## Organized SFX names by category for easy reference and preloading.
## These correspond to files in assets/audio/sfx/

const SFX_CATEGORIES: Dictionary = {
	"player": [
		"player_attack",
		"player_hit",
		"player_death",
		"guard_start",
		"level_up",
		"heal",
		"footstep_grass",
		"footstep_stone",
		"footstep_wood",
		"footstep_dirt",
	],
	"combat": [
		"miss",
		"critical_hit",
		"parry",
		"spell_cast",
		"spell_impact",
	],
	"enemy": [
		"enemy_hit",
		"enemy_death",
		"aggro",
		"boss_intro",
	],
	"ui": [
		"button_click",
		"button_hover",
		"menu_open",
		"menu_close",
		"menu_navigate",
		"equip_item",
		"unequip_item",
		"drop_item",
		"buy_item",
		"sell_item",
	],
	"items": [
		"item_pickup",
		"gold_pickup",
		"potion_drink",
		"scroll_use",
		"chest_open",
		"chest_locked",
	],
	"world": [
		"door_open",
		"door_locked",
		"zone_transition",
		"quest_complete",
		"quest_accepted",
		"npc_greeting",
		"blacksmith_forging",
	],
}

## Flat list of all SFX names (built at runtime)
static var all_sfx_names: Array[String] = []


func _ready() -> void:
	_build_sfx_list()


func _build_sfx_list() -> void:
	all_sfx_names.clear()
	for category in SFX_CATEGORIES:
		for sfx_name in SFX_CATEGORIES[category]:
			if not all_sfx_names.has(sfx_name):
				all_sfx_names.append(sfx_name)


## ============================================================================
## LOOKUP HELPERS
## ============================================================================

static func get_zone_music(zone_id: String) -> String:
	"""Return the music track name for a zone, or empty string if none."""
	zone_id = get_zone_audio_id(zone_id)
	if ZONE_AUDIO.has(zone_id):
		return ZONE_AUDIO[zone_id].get("music", "")
	return ""


static func get_zone_ambient(zone_id: String) -> Array:
	"""Return the list of ambient sound names for a zone."""
	zone_id = get_zone_audio_id(zone_id)
	if ZONE_AUDIO.has(zone_id):
		return ZONE_AUDIO[zone_id].get("ambient", [])
	return []


static func get_zone_music_volume(zone_id: String) -> float:
	"""Return the volume scale for zone music."""
	zone_id = get_zone_audio_id(zone_id)
	if ZONE_AUDIO.has(zone_id):
		return ZONE_AUDIO[zone_id].get("music_volume_scale", 1.0)
	return 1.0


static func get_zone_ambient_volume(zone_id: String) -> float:
	"""Return the volume scale for zone ambient sounds."""
	zone_id = get_zone_audio_id(zone_id)
	if ZONE_AUDIO.has(zone_id):
		return ZONE_AUDIO[zone_id].get("ambient_volume_scale", 0.3)
	return 0.3


static func get_special_music(state: String) -> String:
	"""Return the music track name for a special game state."""
	return SPECIAL_MUSIC.get(state, "")


static func get_zone_audio_id(zone_id: String) -> String:
	"""Resolve a scene-zone alias to the canonical audio profile ID."""
	return ZONE_AUDIO_ALIASES.get(zone_id, zone_id)


static func get_sfx_for_category(category: String) -> Array:
	"""Return all SFX names in a category."""
	return SFX_CATEGORIES.get(category, [])


static func get_all_music_tracks() -> Array[String]:
	"""Return all unique music track names (zones + specials)."""
	var tracks: Array[String] = []
	for zone_id in ZONE_AUDIO:
		var track = ZONE_AUDIO[zone_id].get("music", "")
		if track != "" and not tracks.has(track):
			tracks.append(track)
	for state in SPECIAL_MUSIC:
		var track = SPECIAL_MUSIC[state]
		if track != "" and not tracks.has(track):
			tracks.append(track)
	return tracks


static func get_all_ambient_tracks() -> Array[String]:
	"""Return all unique ambient asset names referenced by the zone catalog."""
	var tracks: Array[String] = []
	for zone_id in ZONE_AUDIO:
		for track in ZONE_AUDIO[zone_id].get("ambient", []):
			if track != "" and not tracks.has(track):
				tracks.append(track)
	return tracks
