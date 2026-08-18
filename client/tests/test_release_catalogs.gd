extends SceneTree
## Release-candidate catalog checks.
##
## Data-driven content is only shippable when every enabled record resolves to
## real assets and valid gameplay references. Keep this test independent of
## scenes so CI catches catalog drift before an export is produced.

const DATA_DIR := "res://resources/game_data/"
const AudioConfigData = preload("res://scripts/autoload/audio_config.gd")
const ReleaseInfoData = preload("res://scripts/release/release_info.gd")

var _failed := false


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var release_metadata := _load_json("res://release_metadata.json")
    var avatars := _load_catalog("avatar_visuals.json")
    var species := _load_catalog("species.json")
    var jobs := _load_catalog("jobs.json")
    var characters := _load_catalog("characters.json")
    var npcs := _load_catalog("npcs.json")
    var monsters := _load_catalog("monsters.json")
    var skills := _load_catalog("skills.json")
    var items := _load_catalog("items.json")
    var equipment := _load_catalog("equipment.json")
    var cosmetics := _load_catalog("cosmetics.json")

    _test("Avatar visual catalog is populated", not avatars.is_empty())
    _test("Species catalog is populated", not species.is_empty())
    _test("Job catalog is populated", not jobs.is_empty())
    _validate_release_metadata(release_metadata)

    _validate_avatar_catalog(avatars)
    _validate_entity_visuals("character", characters, avatars)
    _validate_entity_visuals("NPC", npcs, avatars)
    _validate_entity_visuals("monster", monsters, avatars)
    _validate_species(species, avatars)
    _validate_jobs(jobs, skills, items, equipment)
    _validate_cosmetics(cosmetics)
    _validate_audio_catalog()

    quit(1 if _failed else 0)


func _load_catalog(filename: String) -> Dictionary:
    return _load_json(DATA_DIR + filename)


func _load_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        _test("%s opens" % path, false)
        return {}
    var json := JSON.new()
    var error := json.parse(file.get_as_text())
    file.close()
    _test("%s parses" % path, error == OK and json.data is Dictionary)
    return json.data if error == OK and json.data is Dictionary else {}


func _validate_release_metadata(metadata: Dictionary) -> void:
    _test("Release metadata has a version", not str(metadata.get("release_version", "")).is_empty())
    _test("Release metadata matches runtime version", metadata.get("release_version", "") == ReleaseInfoData.VERSION)
    _test("Release metadata matches content version", int(metadata.get("content_version", 0)) == ReleaseInfoData.CONTENT_VERSION)
    _test("Release metadata matches save schema", int(metadata.get("save_schema_version", 0)) == ReleaseInfoData.SAVE_SCHEMA_VERSION)
    _test("Release metadata matches network protocol", metadata.get("protocol_version", "") == ReleaseInfoData.PROTOCOL_VERSION)
    _test("Release metadata declares the launch mode", metadata.get("online_mode", "") == ReleaseInfoData.ONLINE_MODE)


func _validate_avatar_catalog(avatars: Dictionary) -> void:
    for visual_id in avatars:
        var visual: Dictionary = avatars[visual_id]
        var world: Dictionary = visual.get("world", {})
        _test("Visual %s has a kind" % visual_id, not str(visual.get("kind", "")).is_empty())
        _test("Visual %s has an idle path" % visual_id, not str(world.get("idle", "")).is_empty())
        _test("Visual %s idle asset exists" % visual_id, _resource_exists(str(world.get("idle", ""))))
        _test("Visual %s frame size is valid" % visual_id, _is_pair_of_positive_numbers(world.get("frame_size", [])))
        _test("Visual %s has frames" % visual_id, int(world.get("frames", 0)) > 0)
        _test("Visual %s pivot is valid" % visual_id, _is_pair_of_positive_numbers(world.get("pivot", [])))

        if visual.get("kind", "") == "player":
            _test("Player visual %s walk asset exists" % visual_id, _resource_exists(str(world.get("walk", ""))))
            var portraits: Dictionary = visual.get("portraits", {})
            _test("Player visual %s neutral portrait exists" % visual_id, _resource_exists(str(portraits.get("neutral", ""))))


func _validate_entity_visuals(label: String, entities: Dictionary, avatars: Dictionary) -> void:
    for entity_id in entities:
        var entity: Dictionary = entities[entity_id]
        var visual_id := str(entity.get("visual_id", ""))
        _test("%s %s has a visual ID" % [label, entity_id], not visual_id.is_empty())
        _test("%s %s resolves its visual ID" % [label, entity_id], avatars.has(visual_id))


func _validate_species(species: Dictionary, avatars: Dictionary) -> void:
    for species_id in species:
        var record: Dictionary = species[species_id]
        if not record.get("enabled", false):
            continue
        var avatar_id := str(record.get("default_avatar_id", ""))
        _test("Enabled ancestry %s has a default avatar" % species_id, avatars.has(avatar_id))
        _test("Enabled ancestry %s resolves a player visual" % species_id, avatars.get(avatar_id, {}).get("kind", "") == "player")


func _validate_jobs(jobs: Dictionary, skills: Dictionary, items: Dictionary, equipment: Dictionary) -> void:
    for job_id in jobs:
        var job: Dictionary = jobs[job_id]
        if not job.get("enabled", false):
            continue
        _test("Enabled calling %s has base stats" % job_id, not job.get("base_stats", {}).is_empty())
        for skill_id in job.get("starting_skill_ids", []):
            _test("Calling %s skill %s exists" % [job_id, skill_id], skills.has(skill_id))
        for item_id in job.get("starting_item_ids", []):
            _test("Calling %s item %s exists" % [job_id, item_id], items.has(item_id))
        for slot in job.get("starting_equipment", {}):
            var equipment_id := str(job["starting_equipment"][slot])
            _test("Calling %s equipment %s exists" % [job_id, equipment_id], equipment.has(equipment_id))


func _validate_cosmetics(cosmetics: Dictionary) -> void:
    for cosmetic_id in cosmetics:
        var cosmetic: Dictionary = cosmetics[cosmetic_id]
        _test("Cosmetic %s is explicitly visual-only" % cosmetic_id, cosmetic.get("visual_only", false))
        _test("Cosmetic %s has an entitlement policy" % cosmetic_id, not str(cosmetic.get("entitlement", "")).is_empty())


func _validate_audio_catalog() -> void:
    for track in AudioConfigData.get_all_music_tracks():
        _test("Music track %s exists" % track, FileAccess.file_exists("res://assets/audio/music/%s.ogg" % track))
    for track in AudioConfigData.get_all_ambient_tracks():
        _test("Ambient track %s exists" % track, FileAccess.file_exists("res://assets/audio/ambient/%s.ogg" % track))
    for alias in AudioConfigData.ZONE_AUDIO_ALIASES:
        _test("Audio alias %s resolves to a music track" % alias, not AudioConfigData.get_zone_music(alias).is_empty())
    _test("Main-menu music resolves", not AudioConfigData.get_special_music("main_menu").is_empty())


func _resource_exists(relative_path: String) -> bool:
    return not relative_path.is_empty() and ResourceLoader.exists("res://" + relative_path)


func _is_pair_of_positive_numbers(value: Variant) -> bool:
    return value is Array and value.size() == 2 and float(value[0]) > 0.0 and float(value[1]) > 0.0


func _test(description: String, condition: bool) -> void:
    if condition:
        print("  [PASS] %s" % description)
    else:
        _failed = true
        print("  [FAIL] %s" % description)
