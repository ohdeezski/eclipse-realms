# Visual Resolver Controller v3.0
# Purpose: Map character profile (race, gender, class/job, cosmetics) to visual assets
# Extends: Node2D (for Godot 4.x)
# Author: Futsu (prime-agent)
# Version: 3.0

extends Node2D

# ==========================================
# Asset Mapping (Built-in Fallback)
# Structure: {species: {gender: {class_or_job: {asset_type: path}}}}
# ==========================================

var avatar_map = {
    # Human species assets
    "human": {
        "male": {
            "adept": {
                "portrait": "res://assets/characters/human/male/adept.png",
                "world": "res://assets/characters/human/male/adept.png",
                "preview": "res://assets/characters/human/male/adept.png",
                "sprite": "res://assets/characters/human/male/adept.png"
            },
            "warrior": {
                "portrait": "res://assets/characters/human/male/warrior.png",
                "world": "res://assets/characters/human/male/warrior.png",
                "sprite": "res://assets/characters/human/male/warrior.png"
            },
            "mage": {
                "portrait": "res://assets/characters/human/male/mage.png",
                "world": "res://assets/characters/human/male/mage.png",
                "sprite": "res://assets/characters/human/male/mage.png"
            }
        },
        "female": {
            "adept": {
                "portrait": "res://assets/characters/human/female/adept.png",
                "world": "res://assets/characters/human/female/adept.png",
                "preview": "res://assets/characters/human/female/adept.png",
                "sprite": "res://assets/characters/human/female/adept.png"
            },
            "warrior": {
                "portrait": "res://assets/characters/human/female/warrior.png",
                "world": "res://assets/characters/human/female/warrior.png",
                "sprite": "res://assets/characters/human/female/warrior.png"
            },
            "mage": {
                "portrait": "res://assets/characters/human/female/mage.png",
                "world": "res://assets/characters/human/female/mage.png",
                "sprite": "res://assets/characters/human/female/mage.png"
            }
        }
    },
    # Elder Mira (NPC profile)
    "elder_mira": {
        "female": {
            "guide": {
                "portrait": "res://assets/characters/elder_mira/npc_elder_mira.png",
                "world": "res://assets/characters/elder_mira/npc_elder_mira.png",
                "dialogue": "res://assets/characters/elder_mira/npc_elder_mira.png",
                "preview": "res://assets/characters/elder_mira/npc_elder_mira.png"
            }
        }
    },
    # Moss Slime (Monster profile)
    "moss_slime": {
        "amorphous": {
            "default": {
                "portrait": "res://assets/characters/moss_slime/mob_moss_slime.png",
                "world": "res://assets/characters/moss_slime/mob_moss_slime.png",
                "combat": "res://assets/characters/moss_slime/mob_moss_slime.png",
                "preview": "res://assets/characters/moss_slime/mob_moss_slime.png"
            }
        }
    }
}

# ==========================================
# Job/Class Animation Profiles
# Maps job_id -> animation override data
# ==========================================

var job_animation_profiles = {
    "adept": {
        "idle_frames": 4,
        "walk_frames": 4,
        "attack_frames": 6,
        "cast_frames": 8,
        "idle_speed": 8,
        "walk_speed": 12,
        "attack_speed": 16,
        "cast_speed": 10,
        "offset": Vector2(0, 0)
    },
    "warrior": {
        "idle_frames": 4,
        "walk_frames": 6,
        "attack_frames": 8,
        "block_frames": 4,
        "idle_speed": 6,
        "walk_speed": 10,
        "attack_speed": 14,
        "block_speed": 12,
        "offset": Vector2(0, -2)
    },
    "mage": {
        "idle_frames": 4,
        "walk_frames": 4,
        "cast_frames": 10,
        "channel_frames": 6,
        "idle_speed": 6,
        "walk_speed": 8,
        "cast_speed": 12,
        "channel_speed": 8,
        "offset": Vector2(0, 4)
    },
    "guide": {
        "idle_frames": 2,
        "walk_frames": 4,
        "talk_frames": 4,
        "idle_speed": 4,
        "walk_speed": 8,
        "talk_speed": 6,
        "offset": Vector2(0, 0)
    },
    "default": {
        "idle_frames": 4,
        "walk_frames": 4,
        "idle_speed": 8,
        "walk_speed": 12,
        "offset": Vector2(0, 0)
    }
}

# ==========================================
# Cosmetic/Loadout Variations
# Maps cosmetic_id -> texture overlays or palette swaps
# ==========================================

var cosmetic_variations = {
    # Hair styles
    "hair_short": {
        "layer": "hair",
        "path": "res://assets/characters/cosmetics/hair/hair_short.png",
        "z_index": 10
    },
    "hair_long": {
        "layer": "hair",
        "path": "res://assets/characters/cosmetics/hair/hair_long.png",
        "z_index": 10
    },
    "hair_ponytail": {
        "layer": "hair",
        "path": "res://assets/characters/cosmetics/hair/hair_ponytail.png",
        "z_index": 10
    },
    # Facial hair
    "beard_full": {
        "layer": "facial_hair",
        "path": "res://assets/characters/cosmetics/beard/beard_full.png",
        "z_index": 5
    },
    "beard_stubble": {
        "layer": "facial_hair",
        "path": "res://assets/characters/cosmetics/beard/beard_stubble.png",
        "z_index": 5
    },
    # Equipment overlays (weapons, shields, backpacks)
    "weapon_staff": {
        "layer": "weapon",
        "path": "res://assets/characters/cosmetics/weapons/weapon_staff.png",
        "z_index": 15,
        "attachment_point": "hand_r"
    },
    "weapon_sword": {
        "layer": "weapon",
        "path": "res://assets/characters/cosmetics/weapons/weapon_sword.png",
        "z_index": 15,
        "attachment_point": "hand_r"
    },
    "shield_round": {
        "layer": "shield",
        "path": "res://assets/characters/cosmetics/shields/shield_round.png",
        "z_index": 12,
        "attachment_point": "hand_l"
    },
    # Color palette swaps (for skin tone, clothing dye)
    "skin_pale": {
        "layer": "palette",
        "type": "color_swap",
        "from_color": Color(1.0, 0.8, 0.6, 1.0),
        "to_color": Color(1.0, 0.9, 0.8, 1.0)
    },
    "skin_dark": {
        "layer": "palette",
        "type": "color_swap",
        "from_color": Color(1.0, 0.8, 0.6, 1.0),
        "to_color": Color(0.4, 0.3, 0.25, 1.0)
    }
}

# ==========================================
# Cache for GameData catalog lookups
# ==========================================

var _gamedata_cache: Dictionary = {}
var _use_catalog: Bool = true

# ==========================================
# Asset Retrieval Functions
# ==========================================

# Retrieve a specific asset path for a given profile
func get_asset(race: String, gender: String, class_or_job: String, asset_type: String) -> String:
    # Bridging with GameData: prioritize catalog if available
    if _use_catalog and _try_gamedata_catalog(race, gender, class_or_job, asset_type):
        return _gamedata_cache["%s/%s/%s/%s" % [race, gender, class_or_job, asset_type]]

    var path = avatar_map

    # Navigate the nested dictionary
    if race in path:
        path = path[race]
    else:
        # Fallback to GameData or warn
        return ""

    if gender in path:
        path = path[gender]
    elif gender == "default":
        # Fallback to first available gender
        var first_gender = path.keys()[0] if path.keys().size() > 0 else ""
        if first_gender != "":
            path = path[first_gender]
        else:
            return ""
    else:
        return ""

    if class_or_job in path:
        path = path[class_or_job]
    else:
        return ""

    if asset_type in path:
        return path[asset_type]
    else:
        return ""

func _try_gamedata_catalog(race: String, gender: String, class_or_job: String, asset_type: String) -> Bool:
    """Try to resolve asset from GameData catalog"""
    if not _use_catalog:
        return false

    try:
        var visual_id = "%s_%s_%s" % [race, gender, class_or_job]
        var visuals = GameData.get_all_avatar_visuals() if GameData.has_method("get_all_avatar_visuals") else {}

        if visual_id in visuals:
            var visual = visuals[visual_id]
            var world = visual.get("world", {})
            var portraits = visual.get("portraits", {})

            # Map asset_type to catalog keys
            var catalog_key = ""
            match asset_type:
                "portrait":
                    # Try different portrait variants
                    if portraits.has("neutral"):
                        catalog_key = portraits["neutral"]
                    elif portraits.has("portrait"):
                        catalog_key = portraits["portrait"]
                    elif portraits.keys().size() > 0:
                        catalog_key = portraits[portraits.keys()[0]]
                "world", "sprite":
                    if world.has("idle"):
                        catalog_key = world["idle"]
                    elif world.has("walk"):
                        catalog_key = world["walk"]
                    elif world.keys().size() > 0:
                        catalog_key = world[world.keys()[0]]
                "combat":
                    if world.has("attack"):
                        catalog_key = world["attack"]
                "dialogue":
                    if portraits.has("dialogue"):
                        catalog_key = portraits["dialogue"]
                    elif portraits.has("neutral"):
                        catalog_key = portraits["neutral"]
                "preview":
                    if portraits.has("preview"):
                        catalog_key = portraits["preview"]
                    elif portraits.has("neutral"):
                        catalog_key = portraits["neutral"]

            if catalog_key != "":
                var full_path = "res://%s" % catalog_key
                if ResourceLoader.exists(full_path):
                    var cache_key = "%s/%s/%s/%s" % [race, gender, class_or_job, asset_type]
                    _gamedata_cache[cache_key] = full_path
                    return true
    except:
        pass

    return false

# Convenience wrappers for each asset type
func get_portrait(race: String, gender: String, class_or_job: String) -> String:
    return get_asset(race, gender, class_or_job, "portrait")

func get_world_asset(race: String, gender: String, class_or_job: String) -> String:
    return get_asset(race, gender, class_or_job, "world")

func get_dialogue_asset(race: String, gender: String, class_or_job: String) -> String:
    return get_asset(race, gender, class_or_job, "dialogue")

func get_preview_asset(race: String, gender: String, class_or_job: String) -> String:
    return get_asset(race, gender, class_or_job, "preview")

func get_sprite_asset(race: String, gender: String, class_or_job: String) -> String:
    return get_asset(race, gender, class_or_job, "sprite")

func get_combat_asset(race: String, gender: String, class_or_job: String) -> String:
    return get_asset(race, gender, class_or_job, "combat")

# ==========================================
# Job Animation Profile Access
# ==========================================

func get_job_animation_profile(job_id: String) -> Dictionary:
    return job_animation_profiles.get(job_id, job_animation_profiles["default"])

func get_animation_param(job_id: String, param: String, default = null) -> Variant:
    var profile = get_job_animation_profile(job_id)
    return profile.get(param, default)

# Apply job animation profile to an AvatarSprite2D
func apply_job_animation(sprite: Node, job_id: String) -> Void:
    var profile = get_job_animation_profile(job_id)
    if sprite.has_method("set_animation_profile"):
        sprite.set_animation_profile(profile)
    elif sprite is AvatarSprite2D:
        sprite.apply_animation_profile(profile)

# ==========================================
# Cosmetic/Loadout System
# ==========================================

func get_cosmetic(cosmetic_id: String) -> Dictionary:
    return cosmetic_variations.get(cosmetic_id, {})

func apply_cosmetics(sprite: Node, cosmetic_ids: Array[String]) -> Void:
    """Apply cosmetic overlays to a sprite"""
    if not sprite.has_method("apply_cosmetic_layer"):
        push_warning("Sprite does not support cosmetic layers")
        return

    for cosmetic_id in cosmetic_ids:
        var cosmetic = get_cosmetic(cosmetic_id)
        if cosmetic.empty():
            push_warning("Unknown cosmetic: %s" % cosmetic_id)
            continue
        sprite.apply_cosmetic_layer(cosmetic)

# ==========================================
# Asset Validation
# ==========================================

func has_asset(race: String, gender: String, class_or_job: String, asset_type: String) -> Bool:
    var path = get_asset(race, gender, class_or_job, asset_type)
    return !path.empty()

func is_profile_complete(race: String, gender: String, class_or_job: String) -> Bool:
    var required = ["portrait", "world", "preview"]
    for asset in required:
        if !has_asset(race, gender, class_or_job, asset):
            return False
    return True

# Validate all profiles in avatar_map
func validate_all_profiles() -> Array[String]:
    var missing = []
    for race in avatar_map:
        for gender in avatar_map[race]:
            for class_or_job in avatar_map[race][gender]:
                if !is_profile_complete(race, gender, class_or_job):
                    missing.append("%s/%s/%s" % [race, gender, class_or_job])
    return missing

# ==========================================
# Asset Preloading
# ==========================================

func load_assets(race: String, gender: String, class_or_job: String) -> Dictionary:
    var asset_types = ["portrait", "world", "preview", "sprite", "dialogue", "combat"]
    var assets = {}

    for asset_type in asset_types:
        var path = get_asset(race, gender, class_or_job, asset_type)
        if !path.empty():
            var loader = preload(path)
            if loader:
                assets[asset_type] = loader

    return assets

# ==========================================
# Fallback Logic
# ==========================================

func get_fallback_asset(race: String, gender: String, class_or_job: String, asset_type: String) -> String:
    # Try human fallback
    var human_path = get_asset("human", gender, class_or_job, asset_type)
    if !human_path.empty():
        return human_path

    # Try adept fallback
    var adept_path = get_asset(race, gender, "adept", asset_type)
    if !adept_path.empty():
        return adept_path

    # Generic defaults
    var default_path = {
        "portrait": "res://assets/default_portrait.png",
        "world": "res://assets/default_world.png",
        "preview": "res://assets/default_preview.png",
        "sprite": "res://assets/default_sprite.png",
        "combat": "res://assets/default_combat.png",
        "dialogue": "res://assets/default_portrait.png"
    }
    return default_path.get(asset_type, "")

# ==========================================
# Integration Methods
# ==========================================

func apply_avatar_to_node(node: Node2D, race: String, gender: String, class_or_job: String) -> Bool:
    var assets = load_assets(race, gender, class_or_job)

    if assets.empty():
        var fallback = get_fallback_asset(race, gender, class_or_job, "sprite")
        if !fallback.empty():
            var sprite = $Sprite if has_node("$Sprite") else null
            if sprite:
                sprite.texture = preload(fallback)
                return true
        return false

    if has_node("portrait_label"):
        $portrait_label.text = "%s %s %s" % [race, gender, class_or_job]

    if has_node("sprite"):
        $sprite.texture = assets.get("sprite", null)

    # Apply job animation profile if sprite supports it
    if has_node("sprite") and $sprite.has_method("set_animation_profile"):
        $sprite.set_animation_profile(get_job_animation_profile(class_or_job))

    return true

# Apply full character profile including cosmetics
func apply_character_visuals(node: Node2D, profile: Dictionary) -> Bool:
    var race = profile.get("race", "human")
    var gender = profile.get("gender", "male")
    var class_or_job = profile.get("class", profile.get("job", "adept"))
    var cosmetics = profile.get("cosmetics", [])

    var success = apply_avatar_to_node(node, race, gender, class_or_job)

    if success and cosmetics.size() > 0 and node.has_node("sprite"):
        apply_cosmetics(node.get_node("sprite"), cosmetics)

    return success

# ==========================================
# Extensibility Hooks
# ==========================================

func register_race_profile(race_name: String, profile_data: Dictionary) -> Void:
    avatar_map[race_name] = profile_data
    push_success("Registered new race profile: %s" % race_name)

func register_class_variant(race: String, gender: String, class_name: String, asset_data: Dictionary) -> Void:
    if race in avatar_map and gender in avatar_map[race]:
        avatar_map[race][gender][class_name] = asset_data
        push_success("Registered new class variant: %s/%s/%s" % [race, gender, class_name])
    else:
        push_error("Cannot register variant: base profile incomplete")

func register_job_animation(job_id: String, animation_data: Dictionary) -> Void:
    job_animation_profiles[job_id] = animation_data
    push_success("Registered job animation profile: %s" % job_id)

func register_cosmetic(cosmetic_id: String, cosmetic_data: Dictionary) -> Void:
    cosmetic_variations[cosmetic_id] = cosmetic_data
    push_success("Registered cosmetic: %s" % cosmetic_id)

# Enable/disable GameData catalog integration
func set_catalog_enabled(enabled: Bool) -> Void:
    _use_catalog = enabled
    if enabled:
        _gamedata_cache.clear()

# ==========================================
# Example Usage Section (Commented)
# ==========================================

/*
# To use this resolver in your game:

# 1. Create player node with VisualResolver attached
# 2. Call after character creation:
#    var resolver = $VisualResolver
#    var profile = {
#        "race": "human",
#        "gender": "female",
#        "class": "mage",
#        "cosmetics": ["hair_long", "skin_pale", "weapon_staff"]
#    }
#    resolver.apply_character_visuals($Sprite, profile)

# 3. For NPCs:
#    var npc_profile = {
#        "race": "elder_mira",
#        "gender": "female",
#        "class": "guide"
#    }
#    resolver.apply_character_visuals($NPC/Sprite, npc_profile)

# 4. Loading job animation:
#    var anim_profile = resolver.get_job_animation_profile("mage")
#    $Sprite.set_animation_profile(anim_profile)

# 5. Switching job at runtime:
#    resolver.apply_avatar_to_node($Sprite, "human", "female", "warrior")
#    resolver.apply_cosmetics($Sprite, ["hair_short", "weapon_sword", "shield_round"])
*/

