extends SceneTree
## Contract checks for schema-v2 character records and the ancestry/job catalogs.

const CharacterProfileData = preload("res://scripts/character/character_profile.gd")

var _failed := false


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var game_data = get_root().get_node_or_null("GameData")
    _assert(game_data != null, "GameData autoload is available")
    if game_data == null:
        quit(1)
        return

    _assert(game_data.get_enabled_species().size() == 3, "Three ancestries are enabled")
    _assert(game_data.get_enabled_jobs().size() == 1, "Only the complete Adept calling is enabled")
    _assert(game_data.get_job("adept").get("starting_equipment", {}).get("weapon", "") == "wooden_sword", "Adept starter equipment is cataloged")

    var migrated: Dictionary = CharacterProfileData.migrate({
        "species": "elf",
        "body": "Muscular",
        "face": "Serious",
        "hair": "Braided",
        "gender_identity": "Nonbinary",
        "pronouns": "They/them"
    })
    _assert(migrated.get("character_schema_version", 0) == 2, "Legacy record migrates to schema v2")
    _assert(migrated.get("species_id", "") == "elf", "Legacy species maps to ancestry")
    _assert(migrated.get("job_id", "") == "adept", "Missing calling safely defaults to Adept")
    _assert(migrated.get("appearance", {}).get("body_frame_id", "") == "frame_c", "Legacy body maps to a cosmetic body frame")
    _assert(migrated.get("appearance", {}).get("face_id", "") == "face_02", "Legacy face maps to an appearance ID")
    _assert(migrated.get("appearance", {}).get("hair_style_id", "") == "hair_braided_01", "Legacy hair maps to an appearance ID")
    _assert(migrated.get("profile", {}).get("gender_identity", "") == "Nonbinary", "Identity survives migration without affecting ancestry")
    _assert(game_data.resolve_species_id("unknown") == "human", "Unknown ancestry has a safe fallback")
    _assert(game_data.resolve_job_id("ranger") == "adept", "Disabled calling has a safe fallback")

    quit(1 if _failed else 0)


func _assert(condition: bool, description: String) -> void:
    if condition:
        print("  [PASS] %s" % description)
    else:
        _failed = true
        print("  [FAIL] %s" % description)
