class_name CharacterProfile
extends RefCounted

## Versioned, gameplay-neutral character identity and appearance record.
## Jobs own gameplay. Identity and appearance never affect combat values.

const SCHEMA_VERSION: int = 2
const DEFAULT_SPECIES_ID: String = "human"
const DEFAULT_JOB_ID: String = "adept"
const DEFAULT_AVATAR_ID: String = "pc_human_adept_01"


static func default_record() -> Dictionary:
    return {
        "character_schema_version": SCHEMA_VERSION,
        "species_id": DEFAULT_SPECIES_ID,
        "job_id": DEFAULT_JOB_ID,
        "avatar_id": DEFAULT_AVATAR_ID,
        "appearance": default_appearance(),
        "profile": default_profile(),
        "cosmetic_loadout": default_cosmetic_loadout()
    }


static func default_appearance() -> Dictionary:
    return {
        "body_frame_id": "frame_b",
        "skin_tone_id": "skin_03",
        "face_id": "face_01",
        "eye_color_id": "eye_brown",
        "hair_style_id": "hair_short_01",
        "hair_color_id": "hair_brown",
        "facial_hair_id": "none",
        "marking_id": "marking_none",
        "outfit_palette_id": "oakrest_blue"
    }


static func default_profile() -> Dictionary:
    return {
        "gender_identity": "Prefer not to say",
        "gender_identity_custom": "",
        "pronouns": "They/them",
        "pronouns_custom": "",
        "sharing_enabled": false
    }


static func default_cosmetic_loadout() -> Dictionary:
    return {
        "head": "",
        "outfit": "cos_starter_tunic",
        "back": "",
        "weapon_skin": ""
    }


static func migrate(record: Dictionary) -> Dictionary:
    var normalized := record.duplicate(true)
    var defaults := default_record()
    normalized["character_schema_version"] = SCHEMA_VERSION
    normalized["species_id"] = normalized.get("species_id", normalized.get("species", DEFAULT_SPECIES_ID))
    normalized["job_id"] = normalized.get("job_id", normalized.get("class_id", normalized.get("class", normalized.get("job", normalized.get("archetype", DEFAULT_JOB_ID)))))
    normalized["avatar_id"] = normalized.get("avatar_id", normalized.get("visual_id", normalized.get("avatar_visual_id", DEFAULT_AVATAR_ID)))
    normalized["species"] = normalized["species_id"] # Temporary read compatibility for existing systems.

    var stored_appearance: Dictionary = normalized.get("appearance", {})
    var appearance: Dictionary = defaults["appearance"].duplicate(true)
    appearance.merge(stored_appearance, true)
    if not stored_appearance.has("body_frame_id"):
        appearance["body_frame_id"] = _legacy_body_to_frame(normalized.get("body", stored_appearance.get("body", "")))
    if not stored_appearance.has("face_id"):
        appearance["face_id"] = _legacy_face_to_id(normalized.get("face", stored_appearance.get("face", "")))
    if not stored_appearance.has("hair_style_id"):
        appearance["hair_style_id"] = _legacy_hair_to_id(normalized.get("hair", stored_appearance.get("hair", "")))
    normalized["appearance"] = appearance

    var profile: Dictionary = defaults["profile"].duplicate(true)
    profile.merge(normalized.get("profile", {}), true)
    profile["gender_identity"] = normalized.get("gender_identity", profile["gender_identity"])
    profile["gender_identity_custom"] = normalized.get("gender_identity_custom", profile["gender_identity_custom"])
    profile["pronouns"] = normalized.get("pronouns", profile["pronouns"])
    profile["pronouns_custom"] = normalized.get("pronouns_custom", profile["pronouns_custom"])
    profile["sharing_enabled"] = bool(normalized.get("profile_sharing_enabled", profile["sharing_enabled"]))
    normalized["profile"] = profile
    normalized["gender_identity"] = profile["gender_identity"]
    normalized["gender_identity_custom"] = profile["gender_identity_custom"]
    normalized["pronouns"] = profile["pronouns"]
    normalized["pronouns_custom"] = profile["pronouns_custom"]
    normalized["profile_sharing_enabled"] = profile["sharing_enabled"]

    var cosmetic_loadout: Dictionary = defaults["cosmetic_loadout"].duplicate(true)
    cosmetic_loadout.merge(normalized.get("cosmetic_loadout", {}), true)
    normalized["cosmetic_loadout"] = cosmetic_loadout
    return normalized


static func _legacy_body_to_frame(value: String) -> String:
    match value:
        "Slim": return "frame_a"
        "Muscular", "Sturdy": return "frame_c"
        _: return "frame_b"


static func _legacy_face_to_id(value: String) -> String:
    match value:
        "Serious": return "face_02"
        "Happy", "Smiling": return "face_03"
        _: return "face_01"


static func _legacy_hair_to_id(value: String) -> String:
    match value:
        "Long": return "hair_long_01"
        "Braided": return "hair_braided_01"
        "Bald": return "hair_none"
        _: return "hair_short_01"
