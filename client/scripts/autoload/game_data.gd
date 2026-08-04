extends Node
## GameData.gd - Game Data Management System
## Centralized data storage for game content, items, characters, etc.
## Load order: Eighth

## Signals
signal data_loaded(data_type: String)
signal data_changed(data_type: String)
signal item_registered(item_id: String)
signal character_registered(character_id: String)
signal monster_registered(monster_id: String)

## Constants
const DATA_DIR: String = "res://resources/game_data/"
const ITEMS_FILE: String = DATA_DIR + "items.json"
const CHARACTERS_FILE: String = DATA_DIR + "characters.json"
const MONSTERS_FILE: String = DATA_DIR + "monsters.json"
const NPCS_FILE: String = DATA_DIR + "npcs.json"
const QUESTS_FILE: String = DATA_DIR + "quests.json"
const SKILLS_FILE: String = DATA_DIR + "skills.json"
const EQUIPMENT_FILE: String = DATA_DIR + "equipment.json"

## Static variables
static var is_initialized: bool = false

## Data storage
static var items: Dictionary = {}
static var characters: Dictionary = {}
static var monsters: Dictionary = {}
static var npcs: Dictionary = {}
static var quests: Dictionary = {}
static var skills: Dictionary = {}
static var equipment: Dictionary = {}
static var species: Dictionary = {}
static var world_data: Dictionary = {}

## Indexes for fast lookup
static var item_index: Dictionary = {}
static var character_index: Dictionary = {}
static var monster_index: Dictionary = {}


func _ready() -> void:
    if not is_initialized:
        _initialize()
        is_initialized = true


func _initialize() -> void:
    print("[GameData] Initializing game data system")
    
    # Load all data files
    load_all_data()
    
    # Build indexes
    _build_indexes()
    
    print("[GameData] Game data system initialized")


# ============================================================================
# DATA LOADING
# ============================================================================

func load_all_data() -> void:
    load_items()
    load_characters()
    load_monsters()
    load_npcs()
    load_quests()
    load_skills()
    load_equipment()
    load_world_data()


func load_items() -> bool:
    if not ResourceLoader.exists(ITEMS_FILE):
        _create_default_items()
        return false
    
    var file = FileAccess.open(ITEMS_FILE, FileAccess.READ)
    if file == null:
        push_error("[GameData] Failed to open items file")
        _create_default_items()
        return false
    
    var content = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var err = json.parse(content)
    
    if err == OK and json.data is Dictionary:
        items = json.data
        data_loaded.emit("items")
        print("[GameData] Loaded %d items" % items.size())
        return true
    
    push_error("[GameData] Failed to parse items file")
    _create_default_items()
    return false


func load_characters() -> bool:
    if not ResourceLoader.exists(CHARACTERS_FILE):
        _create_default_characters()
        return false
    
    var file = FileAccess.open(CHARACTERS_FILE, FileAccess.READ)
    if file == null:
        push_error("[GameData] Failed to open characters file")
        _create_default_characters()
        return false
    
    var content = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var err = json.parse(content)
    
    if err == OK and json.data is Dictionary:
        characters = json.data
        data_loaded.emit("characters")
        print("[GameData] Loaded %d characters" % characters.size())
        return true
    
    push_error("[GameData] Failed to parse characters file")
    _create_default_characters()
    return false


func load_monsters() -> bool:
    if not ResourceLoader.exists(MONSTERS_FILE):
        _create_default_monsters()
        return false
    
    var file = FileAccess.open(MONSTERS_FILE, FileAccess.READ)
    if file == null:
        push_error("[GameData] Failed to open monsters file")
        _create_default_monsters()
        return false
    
    var content = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var err = json.parse(content)
    
    if err == OK and json.data is Dictionary:
        monsters = json.data
        data_loaded.emit("monsters")
        print("[GameData] Loaded %d monsters" % monsters.size())
        return true
    
    push_error("[GameData] Failed to parse monsters file")
    _create_default_monsters()
    return false


func load_npcs() -> bool:
    if not ResourceLoader.exists(NPCS_FILE):
        _create_default_npcs()
        return false
    
    var file = FileAccess.open(NPCS_FILE, FileAccess.READ)
    if file == null:
        push_error("[GameData] Failed to open NPCs file")
        _create_default_npcs()
        return false
    
    var content = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var err = json.parse(content)
    
    if err == OK and json.data is Dictionary:
        npcs = json.data
        data_loaded.emit("npcs")
        print("[GameData] Loaded %d NPCs" % npcs.size())
        return true
    
    push_error("[GameData] Failed to parse NPCs file")
    _create_default_npcs()
    return false


func load_quests() -> bool:
    if not ResourceLoader.exists(QUESTS_FILE):
        _create_default_quests()
        return false
    
    var file = FileAccess.open(QUESTS_FILE, FileAccess.READ)
    if file == null:
        push_error("[GameData] Failed to open quests file")
        _create_default_quests()
        return false
    
    var content = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var err = json.parse(content)
    
    if err == OK and json.data is Dictionary:
        quests = json.data
        data_loaded.emit("quests")
        print("[GameData] Loaded %d quests" % quests.size())
        return true
    
    push_error("[GameData] Failed to parse quests file")
    _create_default_quests()
    return false


func load_skills() -> bool:
    if not ResourceLoader.exists(SKILLS_FILE):
        _create_default_skills()
        return false
    
    var file = FileAccess.open(SKILLS_FILE, FileAccess.READ)
    if file == null:
        push_error("[GameData] Failed to open skills file")
        _create_default_skills()
        return false
    
    var content = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var err = json.parse(content)
    
    if err == OK and json.data is Dictionary:
        skills = json.data
        data_loaded.emit("skills")
        print("[GameData] Loaded %d skills" % skills.size())
        return true
    
    push_error("[GameData] Failed to parse skills file")
    _create_default_skills()
    return false


func load_equipment() -> bool:
    if not ResourceLoader.exists(EQUIPMENT_FILE):
        _create_default_equipment()
        return false
    
    var file = FileAccess.open(EQUIPMENT_FILE, FileAccess.READ)
    if file == null:
        push_error("[GameData] Failed to open equipment file")
        _create_default_equipment()
        return false
    
    var content = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var err = json.parse(content)
    
    if err == OK and json.data is Dictionary:
        equipment = json.data
        data_loaded.emit("equipment")
        print("[GameData] Loaded %d equipment items" % equipment.size())
        return true
    
    push_error("[GameData] Failed to parse equipment file")
    _create_default_equipment()
    return false


func load_world_data() -> bool:
    # Load world data from shared resources (try user:// first, then res://)
    var world_file_user = "user://shared/game_data/world.json"
    var world_file_res = "res://shared/game_data/world.json"
    
    # Try user:// first (where we save)
    if FileAccess.file_exists(world_file_user):
        var file = FileAccess.open(world_file_user, FileAccess.READ)
        if file:
            var content = file.get_as_text()
            file.close()
            
            var json = JSON.new()
            var err = json.parse(content)
            
            if err == OK:
                world_data = json.data
                print("[GameData] Loaded world data from user://")
                return true
    
    # Fall back to res://
    if ResourceLoader.exists(world_file_res):
        var file = FileAccess.open(world_file_res, FileAccess.READ)
        if file:
            var content = file.get_as_text()
            file.close()
            
            var json = JSON.new()
            var err = json.parse(content)
            
            if err == OK:
                world_data = json.data
                print("[GameData] Loaded world data from res://")
                return true
    
    _create_default_world_data()
    return false


func save_all_data() -> void:
    _save_data(items, ITEMS_FILE)
    _save_data(characters, CHARACTERS_FILE)
    _save_data(monsters, MONSTERS_FILE)
    _save_data(npcs, NPCS_FILE)
    _save_data(quests, QUESTS_FILE)
    _save_data(skills, SKILLS_FILE)
    _save_data(equipment, EQUIPMENT_FILE)


func _save_data(data: Dictionary, file_path: String) -> void:
    if not DirAccess.dir_exists_absolute(DATA_DIR):
        DirAccess.make_dir_recursive_absolute(DATA_DIR)
    
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file == null:
        push_error("[GameData] Failed to save data to: %s" % file_path)
        return
    
    var json = JSON.new()
    var json_string = json.stringify(data)
    file.store_string(json_string)
    file.close()
    
    print("[GameData] Saved data to: %s" % file_path)


# ============================================================================
# INDEX BUILDING
# ============================================================================

func _build_indexes() -> void:
    # Build indexes for fast lookup by various keys
    item_index.clear()
    for item_id in items:
        var item = items[item_id]
        item_index[item.get("name", "").to_lower()] = item_id
        if item.has("tags"):
            for tag in item["tags"]:
                if not item_index.has("tag:%s" % tag):
                    item_index["tag:%s" % tag] = []
                item_index["tag:%s" % tag].append(item_id)
    
    character_index.clear()
    for char_id in characters:
        var character = characters[char_id]
        character_index[character.get("name", "").to_lower()] = char_id
    
    monster_index.clear()
    for monster_id in monsters:
        var monster = monsters[monster_id]
        monster_index[monster.get("name", "").to_lower()] = monster_id


# ============================================================================
# DEFAULT DATA CREATION
# ============================================================================

func _create_default_items() -> void:
    items = {
        "wooden_sword": {
            "id": "wooden_sword",
            "name": "Wooden Sword",
            "description": "A basic wooden sword for beginners",
            "type": "weapon",
            "subtype": "sword",
            "rarity": "common",
            "level": 1,
            "stats": {
                "attack": 5,
                "defense": 0,
                "speed": 1.0
            },
            "value": 100,
            "weight": 2.0,
            "stackable": false,
            "icon": "items/wooden_sword",
            "tags": ["weapon", "sword", "beginner"]
        },
        "leather_armor": {
            "id": "leather_armor",
            "name": "Leather Armor",
            "description": "Light armor made of tough leather",
            "type": "armor",
            "subtype": "chest",
            "rarity": "common",
            "level": 1,
            "stats": {
                "attack": 0,
                "defense": 3,
                "speed": 0.95
            },
            "value": 150,
            "weight": 4.0,
            "stackable": false,
            "icon": "items/leather_armor",
            "tags": ["armor", "chest", "light"]
        },
        "health_potion": {
            "id": "health_potion",
            "name": "Health Potion",
            "description": "Restores 50 HP when used",
            "type": "consumable",
            "subtype": "potion",
            "rarity": "common",
            "level": 1,
            "effect": {
                "type": "heal",
                "amount": 50,
                "target": "health"
            },
            "value": 50,
            "weight": 0.5,
            "stackable": true,
            "max_stack": 99,
            "icon": "items/health_potion",
            "tags": ["consumable", "potion", "health"]
        },
        "mana_potion": {
            "id": "mana_potion",
            "name": "Mana Potion",
            "description": "Restores 30 MP when used",
            "type": "consumable",
            "subtype": "potion",
            "rarity": "common",
            "level": 1,
            "effect": {
                "type": "restore",
                "amount": 30,
                "target": "mana"
            },
            "value": 40,
            "weight": 0.5,
            "stackable": true,
            "max_stack": 99,
            "icon": "items/mana_potion",
            "tags": ["consumable", "potion", "mana"]
        },
        "iron_sword": {
            "id": "iron_sword",
            "name": "Iron Sword",
            "description": "A sturdy iron sword, reliable in combat",
            "type": "weapon",
            "subtype": "sword",
            "rarity": "common",
            "level": 3,
            "stats": {
                "attack": 12,
                "defense": 0,
                "speed": 1.0
            },
            "value": 350,
            "weight": 3.5,
            "stackable": false,
            "icon": "items/iron_sword",
            "tags": ["weapon", "sword", "iron"]
        },
        "chainmail": {
            "id": "chainmail",
            "name": "Chainmail Armor",
            "description": "Interlocking metal rings provide good protection",
            "type": "armor",
            "subtype": "chest",
            "rarity": "common",
            "level": 3,
            "stats": {
                "attack": 0,
                "defense": 8,
                "speed": 0.9
            },
            "value": 500,
            "weight": 8.0,
            "stackable": false,
            "icon": "items/chainmail",
            "tags": ["armor", "chest", "medium"]
        },
        "rope": {
            "id": "rope",
            "name": "Rope",
            "description": "A sturdy rope, useful for climbing and binding",
            "type": "misc",
            "subtype": "tool",
            "rarity": "common",
            "level": 1,
            "value": 25,
            "weight": 1.0,
            "stackable": true,
            "max_stack": 20,
            "icon": "items/rope",
            "tags": ["misc", "tool", "utility"]
        },
        "torch": {
            "id": "torch",
            "name": "Torch",
            "description": "Provides light in dark places",
            "type": "misc",
            "subtype": "light",
            "rarity": "common",
            "level": 1,
            "value": 15,
            "weight": 0.5,
            "stackable": true,
            "max_stack": 20,
            "icon": "items/torch",
            "tags": ["misc", "light", "utility"]
        },
        "antidote": {
            "id": "antidote",
            "name": "Antidote",
            "description": "Cures poison status effects",
            "type": "consumable",
            "subtype": "potion",
            "rarity": "common",
            "level": 1,
            "effect": {
                "type": "cure",
                "target": "poison"
            },
            "value": 30,
            "weight": 0.3,
            "stackable": true,
            "max_stack": 99,
            "icon": "items/antidote",
            "tags": ["consumable", "potion", "cure"]
        }
    }
    
    print("[GameData] Created default items")
    data_changed.emit("items")
    
    # Save to file
    _save_data(items, ITEMS_FILE)


func _create_default_characters() -> void:
    characters = {
        "player_human_male": {
            "id": "player_human_male",
            "name": "Human Male",
            "description": "Default human male character",
            "species": "human",
            "gender": "male",
            "base_stats": {
                "health": 100,
                "max_health": 100,
                "mana": 50,
                "max_mana": 50,
                "strength": 10,
                "defense": 10,
                "agility": 10,
                "intelligence": 10
            },
            "growth_rates": {
                "health": 1.0,
                "mana": 0.8,
                "strength": 1.0,
                "defense": 1.0,
                "agility": 1.0,
                "intelligence": 0.9
            },
            "starting_equipment": ["wooden_sword", "leather_armor"],
            "starting_inventory": ["health_potion", "health_potion", "mana_potion"],
            "appearance": {
                "body": "male_average",
                "face": "male_01",
                "hair": "short_01",
                "eyes": "brown",
                "height": 1.75
            }
        },
        "player_human_female": {
            "id": "player_human_female",
            "name": "Human Female",
            "description": "Default human female character",
            "species": "human",
            "gender": "female",
            "base_stats": {
                "health": 90,
                "max_health": 90,
                "mana": 60,
                "max_mana": 60,
                "strength": 8,
                "defense": 8,
                "agility": 12,
                "intelligence": 12
            },
            "growth_rates": {
                "health": 0.9,
                "mana": 1.1,
                "strength": 0.9,
                "defense": 0.9,
                "agility": 1.1,
                "intelligence": 1.1
            },
            "starting_equipment": ["wooden_sword", "leather_armor"],
            "starting_inventory": ["health_potion", "health_potion", "mana_potion"],
            "appearance": {
                "body": "female_average",
                "face": "female_01",
                "hair": "long_01",
                "eyes": "blue",
                "height": 1.65
            }
        }
    }
    
    print("[GameData] Created default characters")
    data_changed.emit("characters")
    
    # Save to file
    _save_data(characters, CHARACTERS_FILE)


func _create_default_monsters() -> void:
    monsters = {
        "moss_slime": {
            "id": "moss_slime",
            "name": "Moss Slime",
            "description": "A slow, squishy blob of forest moss. Easy prey for a beginner.",
            "level": 1,
            "stats": {
                "health": 30,
                "max_health": 30,
                "attack": 6,
                "defense": 1,
                "speed": 0.5,
                "experience": 12,
                "gold": 5
            },
            "drops": [
                {"item": "health_potion", "chance": 0.25},
                {"item": "moss_essence", "chance": 0.5}
            ],
            "zones": ["mosswood_forest"],
            "behavior": "wander"
        },
        "forest_wolf": {
            "id": "forest_wolf",
            "name": "Forest Wolf",
            "description": "A lean pack hunter of Mosswood Forest. Faster and fiercer than the slime.",
            "level": 2,
            "stats": {
                "health": 55,
                "max_health": 55,
                "attack": 12,
                "defense": 3,
                "speed": 1.4,
                "experience": 28,
                "gold": 14
            },
            "drops": [
                {"item": "health_potion", "chance": 0.4},
                {"item": "wolf_pelt", "chance": 0.6}
            ],
            "zones": ["mosswood_forest"],
            "behavior": "chase"
        },
        "thorn_wisp": {
            "id": "thorn_wisp",
            "name": "Thorn Wisp",
            "description": "A ghostly spirit surrounded by thorns",
            "type": "monster",
            "category": "spirit",
            "level": 5,
            "stats": {
                "health": 25,
                "max_health": 25,
                "attack": 12,
                "defense": 1,
                "speed": 1.5,
                "experience": 45
            },
            "abilities": ["thorn_attack", "phase_shift"],
            "drops": [
                {"id": "wisp_essence", "chance": 0.6, "min": 1, "max": 2},
                {"id": "thorn", "chance": 0.4, "min": 1, "max": 3}
            ],
            "spawn_areas": ["whispering_caverns"],
            "aggro_range": 150,
            "chase_range": 250,
            "respawn_time": 60,
            "model": "monsters/thorn_wisp",
            "animation": "wisp"
        }
    }
    
    print("[GameData] Created default monsters")
    data_changed.emit("monsters")
    
    # Save to file
    _save_data(monsters, MONSTERS_FILE)


func _create_default_npcs() -> void:
    npcs = {
        "village_elder": {
            "id": "village_elder",
            "name": "Elder Alric",
            "title": "Village Elder",
            "description": "The wise elder of Oakrest Village",
            "type": "npc",
            "category": "quest_giver",
            "location": "oakrest_village",
            "position": Vector2(100, 100),
            "dialogue": {
                "greeting": [
                    "Welcome, traveler. I am Elder Alric.",
                    "Greetings, young one. The village awaits your aid.",
                    "Ah, a new face in Oakrest. Come, let us speak."
                ],
                "farewell": [
                    "May the light guide your path, traveler.",
                    "Farewell. Return when you have need.",
                    "Stay vigilant out there."
                ],
                "quest_offer": [
                    "I have a matter that requires your attention.",
                    "The village faces trials that only a brave soul can address.",
                    "Will you lend your strength to Oakrest?"
                ],
                "quest_active": [
                    "How fares your quest? The village watches with hope.",
                    "Progress report, traveler. What news do you bring?",
                    "The task remains unfinished. Stay focused."
                ],
                "lore": [
                    "Oakrest Village has stood for three hundred years.",
                    "The forest to the north hides many secrets.",
                    "Legend speaks of an ancient power sealed beneath the Whispering Caverns."
                ]
            },
            "dialogue_tree": {
                "greeting": {"text": "greeting", "next": "main_menu", "effects": ["greeting_played"]},
                "main_menu": {
                    "text": "How can I assist you today?",
                    "type": "branching",
                    "options": [
                        {"text": "Do you have any tasks for me?", "next": "quest_menu", "conditions": {}},
                        {"text": "Tell me about Oakrest Village", "next": "village_lore", "conditions": {}},
                        {"text": "Tell me about the surrounding areas", "next": "area_lore", "conditions": {}},
                        {"text": "Goodbye, Elder", "next": "farewell", "conditions": {}}
                    ]
                },
                "quest_menu": {"text": "quest_offer", "next": "quest_details", "conditions": {}},
                "quest_details": {"text": "quest_active", "type": "quest_display", "next": "main_menu", "effects": ["check_available_quests"]},
                "village_lore": {
                    "text": "lore",
                    "options": [
                        {"text": "Tell me more about the founders", "next": "founder_lore", "conditions": {}},
                        {"text": "What about the current threats?", "next": "threat_lore", "conditions": {}},
                        {"text": "Return to main menu", "next": "main_menu", "conditions": {}}
                    ]
                },
                "founder_lore": {"text": "The founders were warriors and scholars who sought refuge. They built something lasting.", "next": "village_lore", "effects": ["lore_founder_learned"]},
                "threat_lore": {"text": "The Moss Slimes have grown bolder, and wolves in the forest trouble me greatly.", "next": "village_lore", "effects": ["lore_threats_learned"]},
                "area_lore": {
                    "text": "To the north lies Mosswood Forest. Further north, the Whispering Caverns. To the southeast, the Hunter's Camp.",
                    "options": [
                        {"text": "Tell me about Mosswood Forest", "next": "forest_lore", "conditions": {}},
                        {"text": "What of the Whispering Caverns?", "next": "cavern_lore", "conditions": {}},
                        {"text": "Return to main menu", "next": "main_menu", "conditions": {}}
                    ]
                },
                "forest_lore": {"text": "Mosswood Forest is ancient. Moss Slimes dwell in its damp undergrowth, while Forest Wolves roam deeper.", "next": "area_lore", "effects": ["lore_forest_learned"]},
                "cavern_lore": {"text": "The Whispering Caverns hold both wonder and dread. Thorn Wisps haunt its passages.", "next": "area_lore", "effects": ["lore_cavern_learned"]},
                "farewell": {"text": "farewell", "next": null, "effects": ["clear_dialogue", "end_conversation"]}
            },
            "quests": ["tutorial_quest", "find_missing_item", "village_defense"],
            "schedule": {
                "morning": {"position": Vector2(100, 100), "action": "stand"},
                "afternoon": {"position": Vector2(120, 100), "action": "walk"},
                "evening": {"position": Vector2(100, 100), "action": "stand"},
                "night": {"position": Vector2(80, 80), "action": "sleep"}
            },
            "model": "npcs/village_elder",
            "animation": "human",
            "interactable": true
        },
        "blacksmith": {
            "id": "blacksmith",
            "name": "Blacksmith Thoren",
            "title": "Blacksmith",
            "description": "The village blacksmith who forges weapons and armor",
            "type": "npc",
            "category": "merchant",
            "location": "oakrest_village",
            "position": Vector2(200, 150),
            "dialogue": {
                "greeting": [
                    "Welcome to my forge! What can I do for you?",
                    "Need some new gear? You've come to the right place!",
                    "Ah, a customer! Browse my wares at your leisure."
                ],
                "farewell": [
                    "Stay sharp out there!",
                    "Come back anytime you need repairs!",
                    "May your blade never dull!"
                ],
                "shop": [
                    "Take a look at what I've forged!",
                    "Only the finest weapons and armor here!",
                    "Each piece crafted with care and quality."
                ],
                "buy": ["Good choice!", "A wise purchase!", "This weapon has been tempered to perfection."],
                "sell": ["I'll give you a fair price.", "Good craftsmanship. I'll take it."],
                "lore": ["I learned my craft from my father.", "Good steel is hard to come by these days."]
            },
            "dialogue_tree": {
                "greeting": {"text": "greeting", "next": "main_menu", "effects": ["greeting_played"]},
                "main_menu": {
                    "text": "What can I do for you today?",
                    "type": "branching",
                    "options": [
                        {"text": "Show me your wares", "next": "shop_menu", "conditions": {}},
                        {"text": "I'd like to sell something", "next": "sell_menu", "conditions": {}},
                        {"text": "Tell me about your craft", "next": "craft_lore", "conditions": {}},
                        {"text": "Goodbye, Thoren", "next": "farewell", "conditions": {}}
                    ]
                },
                "shop_menu": {
                    "text": "shop",
                    "type": "shop",
                    "shop_type": "blacksmith",
                    "options": [
                        {"text": "Buy Weapons", "next": "weapons_shop", "conditions": {}},
                        {"text": "Buy Armor", "next": "armor_shop", "conditions": {}},
                        {"text": "Back", "next": "main_menu", "conditions": {}}
                    ]
                },
                "weapons_shop": {"text": "Here are the finest blades in the valley!", "type": "shop_display", "shop_category": "weapon", "next": "shop_menu", "effects": ["open_shop", "filter_weapons"]},
                "armor_shop": {"text": "Protection is worth its weight in gold!", "type": "shop_display", "shop_category": "armor", "next": "shop_menu", "effects": ["open_shop", "filter_armor"]},
                "sell_menu": {"text": "sell", "type": "sell", "next": "main_menu", "effects": ["open_sell_menu"]},
                "craft_lore": {
                    "text": "lore",
                    "options": [
                        {"text": "How did you become a blacksmith?", "next": "origin_lore", "conditions": {}},
                        {"text": "What makes a good weapon?", "next": "weapon_lore", "conditions": {}},
                        {"text": "Return to main menu", "next": "main_menu", "conditions": {}}
                    ]
                },
                "origin_lore": {"text": "My father taught me the ways of the forge when I was just a boy.", "next": "craft_lore", "effects": ["lore_blacksmith_origin"]},
                "weapon_lore": {"text": "A good weapon is balanced, sharp, and true to its purpose.", "next": "craft_lore", "effects": ["lore_weapon_craft"]},
                "farewell": {"text": "farewell", "next": null, "effects": ["clear_dialogue", "end_conversation"]}
            },
            "quests": ["forge_materials"],
            "shop": {
                "type": "blacksmith",
                "items": ["wooden_sword", "iron_sword", "leather_armor", "chainmail", "health_potion"],
                "buy_multiplier": 1.2,
                "sell_multiplier": 0.8
            },
            "schedule": {
                "morning": {"position": Vector2(200, 150), "action": "forge"},
                "afternoon": {"position": Vector2(200, 150), "action": "forge"},
                "evening": {"position": Vector2(180, 140), "action": "stand"},
                "night": {"position": Vector2(200, 150), "action": "sleep"}
            },
            "model": "npcs/blacksmith",
            "animation": "human",
            "interactable": true
        },
        "merchant": {
            "id": "merchant",
            "name": "Merchant Lira",
            "title": "General Merchant",
            "description": "Sells various goods and supplies",
            "type": "npc",
            "category": "merchant",
            "location": "oakrest_village",
            "position": Vector2(300, 120),
            "dialogue": {
                "greeting": [
                    "Welcome to Lira's Shop!",
                    "Looking for something special? You've come to the right place!",
                    "Greetings, traveler! I have goods from across the valley."
                ],
                "farewell": ["Thank you, come again!", "Safe travels!", "May your purse be ever full!"],
                "shop": ["Take a look at my collection!", "Everything you need for your adventures!"],
                "lore": ["I travel between villages, gathering goods and news.", "Trade is the lifeblood of these settlements."]
            },
            "dialogue_tree": {
                "greeting": {"text": "greeting", "next": "main_menu", "effects": ["greeting_played"]},
                "main_menu": {
                    "text": "What brings you to my shop?",
                    "type": "branching",
                    "options": [
                        {"text": "Show me your wares", "next": "shop_menu", "conditions": {}},
                        {"text": "I'd like to sell something", "next": "sell_menu", "conditions": {}},
                        {"text": "Any news from the road?", "next": "road_lore", "conditions": {}},
                        {"text": "Goodbye, Lira", "next": "farewell", "conditions": {}}
                    ]
                },
                "shop_menu": {"text": "shop", "type": "shop", "shop_type": "general", "next": "main_menu", "effects": ["open_shop"]},
                "sell_menu": {"text": "sell", "type": "sell", "next": "main_menu", "effects": ["open_sell_menu"]},
                "road_lore": {"text": "The roads have been quiet lately, but I've heard rumors of strange lights in the Whispering Caverns.", "next": "main_menu", "effects": ["lore_road_news"]},
                "farewell": {"text": "farewell", "next": null, "effects": ["clear_dialogue", "end_conversation"]}
            },
            "shop": {
                "type": "general",
                "items": ["health_potion", "mana_potion", "antidote", "rope", "torch"],
                "buy_multiplier": 1.5,
                "sell_multiplier": 0.7
            },
            "schedule": {
                "morning": {"position": Vector2(300, 120), "action": "stand"},
                "afternoon": {"position": Vector2(320, 120), "action": "walk"},
                "evening": {"position": Vector2(300, 120), "action": "stand"},
                "night": {"position": Vector2(280, 100), "action": "sleep"}
            },
            "model": "npcs/merchant",
            "animation": "human",
            "interactable": true
        },
        "innkeeper": {
            "id": "innkeeper",
            "name": "Innkeeper Mara",
            "title": "Innkeeper",
            "description": "Runs the local inn and provides rest for travelers",
            "type": "npc",
            "category": "service",
            "location": "oakrest_village",
            "position": Vector2(400, 100),
            "dialogue": {
                "greeting": ["Welcome to the Restful Oak!", "Come in! What can I do for you?", "Ah, a weary traveler!"],
                "farewell": ["Rest well, traveler!", "Safe journeys ahead!", "Come back whenever you need rest!"],
                "service": ["I can offer you rest or healing for a fair price.", "Tired? A night's rest will do you wonders."],
                "lore": ["The Restful Oak has hosted travelers for over a century.", "My true passion is herbalism."]
            },
            "dialogue_tree": {
                "greeting": {"text": "greeting", "next": "main_menu", "effects": ["greeting_played"]},
                "main_menu": {
                    "text": "What can I do for you?",
                    "type": "branching",
                    "options": [
                        {"text": "I need some rest (10 gold)", "next": "rest_service", "conditions": {"gold": 10}},
                        {"text": "Heal my wounds (50 gold)", "next": "heal_service", "conditions": {"gold": 50}},
                        {"text": "Tell me about the inn", "next": "inn_lore", "conditions": {}},
                        {"text": "Goodbye, Mara", "next": "farewell", "conditions": {}}
                    ]
                },
                "rest_service": {"text": "service", "type": "service", "service_type": "rest", "cost": 10, "effects": ["perform_rest"], "next": "rest_complete"},
                "rest_complete": {"text": "You feel fully refreshed! All health and mana restored.", "next": "main_menu", "effects": ["heal_full", "save_game"]},
                "heal_service": {"text": "service", "type": "service", "service_type": "heal", "cost": 50, "effects": ["perform_heal"], "next": "heal_complete"},
                "heal_complete": {"text": "Your wounds have been tended to. You feel much better!", "next": "main_menu", "effects": ["heal_hp"]},
                "inn_lore": {
                    "text": "lore",
                    "options": [
                        {"text": "How long have you run this inn?", "next": "history_lore", "conditions": {}},
                        {"text": "Tell me about your herbalism", "next": "herbal_lore", "conditions": {}},
                        {"text": "Return to main menu", "next": "main_menu", "conditions": {}}
                    ]
                },
                "history_lore": {"text": "I've run the Restful Oak for twenty years. Three generations of hospitality!", "next": "inn_lore", "effects": ["lore_inn_history"]},
                "herbal_lore": {"text": "The forest provides many herbs with healing properties. I use them in my potions.", "next": "inn_lore", "effects": ["lore_herbalism"]},
                "farewell": {"text": "farewell", "next": null, "effects": ["clear_dialogue", "end_conversation"]}
            },
            "services": ["rest", "heal"],
            "rest_cost": 10,
            "heal_cost": 50,
            "schedule": {
                "morning": {"position": Vector2(400, 100), "action": "clean"},
                "afternoon": {"position": Vector2(400, 100), "action": "serve"},
                "evening": {"position": Vector2(400, 100), "action": "serve"},
                "night": {"position": Vector2(420, 80), "action": "sleep"}
            },
            "model": "npcs/innkeeper",
            "animation": "human",
            "interactable": true
        },
        "ranger": {
            "id": "ranger",
            "name": "Ranger Elias",
            "title": "Hunter's Camp Ranger",
            "description": "Guides hunters and offers quests to protect the village",
            "type": "npc",
            "category": "quest_giver",
            "location": "hunters_camp",
            "position": Vector2(50, 50),
            "dialogue": {
                "greeting": ["The forest needs protectors like you.", "I have work for a skilled hunter.", "Welcome to the Hunter's Camp."],
                "farewell": ["Stay safe out there.", "Report back when you're done.", "May your aim be true."],
                "quest_offer": ["The wolves have been getting bold. Need someone to thin their numbers.", "There's trouble in the Whispering Caverns.", "I have contracts for capable hunters."],
                "lore": ["The Hunter's Camp has guarded Oakrest for generations.", "The forest respects those who respect it."]
            },
            "dialogue_tree": {
                "greeting": {"text": "greeting", "next": "main_menu", "effects": ["greeting_played"]},
                "main_menu": {
                    "text": "What brings you to the Hunter's Camp?",
                    "type": "branching",
                    "options": [
                        {"text": "I'm looking for work", "next": "quest_menu", "conditions": {}},
                        {"text": "Tell me about the forest", "next": "forest_lore", "conditions": {}},
                        {"text": "Goodbye, Elias", "next": "farewell", "conditions": {}}
                    ]
                },
                "quest_menu": {"text": "quest_offer", "type": "quest_display", "next": "main_menu", "effects": ["check_available_quests"]},
                "forest_lore": {
                    "text": "lore",
                    "options": [
                        {"text": "What creatures lurk in the forest?", "next": "creature_lore", "conditions": {}},
                        {"text": "Any hunting tips?", "next": "hunting_lore", "conditions": {}},
                        {"text": "Return to main menu", "next": "main_menu", "conditions": {}}
                    ]
                },
                "creature_lore": {"text": "Moss Slimes are common but harmless if you keep your distance. Forest Wolves hunt in packs.", "next": "forest_lore", "effects": ["lore_creatures_learned"]},
                "hunting_lore": {"text": "Patience is key. Watch your target, learn its patterns, and strike when vulnerable.", "next": "forest_lore", "effects": ["lore_hunting_tips"]},
                "farewell": {"text": "farewell", "next": null, "effects": ["clear_dialogue", "end_conversation"]}
            },
            "quests": ["hunt_forest_wolf", "clear_thorn_wisp", "escort_merchant"],
            "schedule": {
                "morning": {"position": Vector2(50, 50), "action": "patrol"},
                "afternoon": {"position": Vector2(70, 60), "action": "patrol"},
                "evening": {"position": Vector2(50, 50), "action": "stand"},
                "night": {"position": Vector2(30, 40), "action": "rest"}
            },
            "model": "npcs/ranger",
            "animation": "human",
            "interactable": true
        }
    }

    print("[GameData] Created default NPCs")
    data_changed.emit("npcs")
    
    # Save to file
    _save_data(npcs, NPCS_FILE)


func _create_default_quests() -> void:
    quests = {
        "tutorial_quest": {
            "id": "tutorial_quest",
            "name": "A Humble Beginning",
            "description": "Learn the basics of combat by defeating a Moss Slime",
            "giver": "village_elder",
            "category": "tutorial",
            "level": 1,
            "requirements": {
                "level": 1
            },
            "objectives": [
                {"type": "kill", "target": "moss_slime", "amount": 1, "completed": false},
                {"type": "return", "target": "village_elder", "completed": false}
            ],
            "rewards": {
                "experience": 50,
                "gold": 100,
                "items": ["health_potion"]
            },
            "next_quests": ["find_missing_item"],
            "repeatable": false
        },
        "find_missing_item": {
            "id": "find_missing_item",
            "name": "The Elder's Request",
            "description": "Find the elder's missing amulet",
            "giver": "village_elder",
            "category": "fetch",
            "level": 2,
            "requirements": {
                "completed_quests": ["tutorial_quest"]
            },
            "objectives": [
                {"type": "find", "target": "elder_amulet", "amount": 1, "completed": false},
                {"type": "return", "target": "village_elder", "completed": false}
            ],
            "rewards": {
                "experience": 75,
                "gold": 150,
                "items": ["mana_potion"]
            },
            "next_quests": ["hunt_forest_wolf"],
            "repeatable": false
        },
        "hunt_forest_wolf": {
            "id": "hunt_forest_wolf",
            "name": "Wolf Hunt",
            "description": "Hunt down Forest Wolves threatening the village",
            "giver": "ranger",
            "category": "hunting",
            "level": 3,
            "requirements": {
                "level": 3,
                "completed_quests": ["tutorial_quest"]
            },
            "objectives": [
                {"type": "kill", "target": "forest_wolf", "amount": 3, "completed": false},
                {"type": "return", "target": "ranger", "completed": false}
            ],
            "rewards": {
                "experience": 150,
                "gold": 300,
                "items": ["wolf_pelt", "health_potion"]
            },
            "next_quests": ["clear_thorn_wisp"],
            "repeatable": true,
            "daily_limit": 5
        }
    }
    
    print("[GameData] Created default quests")
    data_changed.emit("quests")
    
    # Save to file
    _save_data(quests, QUESTS_FILE)


func _create_default_skills() -> void:
    skills = {
        "basic_attack": {
            "id": "basic_attack",
            "name": "Basic Attack",
            "description": "A simple melee attack",
            "type": "combat",
            "category": "attack",
            "level": 1,
            "requirements": {
                "level": 1
            },
            "effects": [
                {"type": "damage", "amount": 1.0, "scaling": "strength", "scale": 0.5}
            ],
            "cooldown": 0.5,
            "mana_cost": 0,
            "range": 50,
            "animation": "attack",
            "icon": "skills/basic_attack"
        },
        "heal": {
            "id": "heal",
            "name": "Heal",
            "description": "Restore a portion of health",
            "type": "support",
            "category": "heal",
            "level": 5,
            "requirements": {
                "level": 5,
                "intelligence": 10
            },
            "effects": [
                {"type": "heal", "amount": 20, "scaling": "intelligence", "scale": 0.5, "target": "self"}
            ],
            "cooldown": 5.0,
            "mana_cost": 15,
            "range": 0,
            "animation": "heal",
            "icon": "skills/heal"
        },
        "fire_bolt": {
            "id": "fire_bolt",
            "name": "Fire Bolt",
            "description": "Launch a bolt of fire at the enemy",
            "type": "combat",
            "category": "magic",
            "element": "fire",
            "level": 8,
            "requirements": {
                "level": 8,
                "intelligence": 15
            },
            "effects": [
                {"type": "damage", "amount": 15, "scaling": "intelligence", "scale": 0.8},
                {"type": "burn", "chance": 0.3, "duration": 3, "damage_per_second": 2}
            ],
            "cooldown": 2.0,
            "mana_cost": 20,
            "range": 200,
            "animation": "cast",
            "projectile": "fire_bolt",
            "icon": "skills/fire_bolt"
        }
    }
    
    print("[GameData] Created default skills")
    data_changed.emit("skills")
    
    # Save to file
    _save_data(skills, SKILLS_FILE)


func _create_default_equipment() -> void:
    equipment = {
        "wooden_sword": {
            "id": "wooden_sword",
            "name": "Wooden Sword",
            "type": "weapon",
            "subtype": "sword",
            "slot": "main_hand",
            "rarity": "common",
            "level": 1,
            "stats": {"attack": 5, "defense": 0, "speed": 1.0},
            "requirements": {"level": 1},
            "value": 100
        },
        "leather_armor": {
            "id": "leather_armor",
            "name": "Leather Armor",
            "type": "armor",
            "subtype": "chest",
            "slot": "chest",
            "rarity": "common",
            "level": 1,
            "stats": {"attack": 0, "defense": 3, "speed": 0.95},
            "requirements": {"level": 1},
            "value": 150
        }
    }
    
    print("[GameData] Created default equipment")
    data_changed.emit("equipment")
    
    # Save to file
    _save_data(equipment, EQUIPMENT_FILE)


func _create_default_world_data() -> void:
    world_data = {
        "regions": {
            "greenhaven_valley": {
                "name": "Greenhaven Valley",
                "description": "The starting region for new adventurers",
                "level_range": [1, 10],
                "areas": ["oakrest_village", "mosswood_forest", "silver_creek", "whispering_caverns", "old_watchtower", "hunters_camp"],
                "recommended_level": 1
            }
        },
        "areas": {
            "oakrest_village": {
                "name": "Oakrest Village",
                "description": "A peaceful starting village",
                "type": "village",
                "region": "greenhaven_valley",
                "level": 1,
                "npcs": ["village_elder", "blacksmith", "merchant", "innkeeper"],
                "spawn_point": Vector2(250, 200),
                "size": Vector2(500, 400)
            },
            "mosswood_forest": {
                "name": "Mosswood Forest",
                "description": "A dense forest filled with life and danger",
                "type": "forest",
                "region": "greenhaven_valley",
                "level": 2,
                "monsters": ["moss_slime", "forest_wolf"],
                "size": Vector2(800, 600)
            },
            "whispering_caverns": {
                "name": "Whispering Caverns",
                "description": "A dark cave system rumored to be haunted",
                "type": "cave",
                "region": "greenhaven_valley",
                "level": 5,
                "monsters": ["moss_slime", "thorn_wisp"],
                "boss": "cave_guardian",
                "size": Vector2(600, 500)
            }
        },
        "connections": {
            "oakrest_village": {
                "north": "mosswood_forest",
                "east": "silver_creek",
                "southeast": "hunters_camp"
            },
            "mosswood_forest": {
                "south": "oakrest_village",
                "north": "old_watchtower",
                "east": "whispering_caverns"
            },
            "whispering_caverns": {
                "west": "mosswood_forest"
            }
        }
    }
    
    print("[GameData] Created default world data")
    data_changed.emit("world")
    
    # Save to file
    var world_file = "user://shared/game_data/world.json"
    var world_dir = "user://shared/game_data/"
    if not DirAccess.dir_exists_absolute(world_dir):
        DirAccess.make_dir_recursive_absolute(world_dir)
    _save_data(world_data, world_file)


# ============================================================================
# DATA ACCESS FUNCTIONS
# ============================================================================

# Item functions
func get_item(item_id: String) -> Dictionary:
    return items.get(item_id, {})


func find_items_by_tag(tag: String) -> Array:
    if item_index.has("tag:%s" % tag):
        var ids = item_index["tag:%s" % tag]
        var result: Array = []
        for id in ids:
            result.append(items[id])
        return result
    return []


func find_items_by_name(name: String) -> Array:
    var result: Array = []
    for item_id in items:
        if items[item_id].get("name", "").to_lower().find(name.to_lower()) != -1:
            result.append(items[item_id])
    return result


func get_all_items() -> Array:
    return items.values()


# Character functions
func get_character(character_id: String) -> Dictionary:
    return characters.get(character_id, {})


func get_all_characters() -> Array:
    return characters.values()


# Monster functions
func get_monster(monster_id: String) -> Dictionary:
    return monsters.get(monster_id, {})


func get_monsters_by_area(area: String) -> Array:
    var result: Array = []
    for monster_id in monsters:
        if monsters[monster_id].get("spawn_areas", []).has(area):
            result.append(monsters[monster_id])
    return result


func get_all_monsters() -> Array:
    return monsters.values()


# NPC functions
func get_npc(npc_id: String) -> Dictionary:
    return npcs.get(npc_id, {})


func get_npcs_by_location(location: String) -> Array:
    var result: Array = []
    for npc_id in npcs:
        if npcs[npc_id].get("location", "") == location:
            result.append(npcs[npc_id])
    return result


func get_all_npcs() -> Array:
    return npcs.values()


# Quest functions
func get_quest(quest_id: String) -> Dictionary:
    return quests.get(quest_id, {})


func get_quests_by_giver(giver_id: String) -> Array:
    var result: Array = []
    for quest_id in quests:
        if quests[quest_id].get("giver", "") == giver_id:
            result.append(quests[quest_id])
    return result


func get_all_quests() -> Array:
    return quests.values()


# Skill functions
func get_skill(skill_id: String) -> Dictionary:
    return skills.get(skill_id, {})


func get_skills_by_type(skill_type: String) -> Array:
    var result: Array = []
    for skill_id in skills:
        if skills[skill_id].get("type", "") == skill_type:
            result.append(skills[skill_id])
    return result


func get_all_skills() -> Array:
    return skills.values()


# Equipment functions
func get_equipment(equipment_id: String) -> Dictionary:
    return equipment.get(equipment_id, {})


func get_equipment_by_slot(slot: String) -> Array:
    var result: Array = []
    for equipment_id in equipment:
        if equipment[equipment_id].get("slot", "") == slot:
            result.append(equipment[equipment_id])
    return result


func get_all_equipment() -> Array:
    return equipment.values()


# World data functions
func get_region(region_id: String) -> Dictionary:
    return world_data.get("regions", {}).get(region_id, {})


func get_area(area_id: String) -> Dictionary:
    return world_data.get("areas", {}).get(area_id, {})


func get_connections(area_id: String) -> Dictionary:
    return world_data.get("connections", {}).get(area_id, {})


# ============================================================================
# REGISTRATION FUNCTIONS
# ============================================================================

func register_item(item_data: Dictionary) -> bool:
    var item_id = item_data.get("id", "")
    if item_id == "" or items.has(item_id):
        return false
    
    items[item_id] = item_data
    _build_indexes()  # Rebuild indexes
    item_registered.emit(item_id)
    data_changed.emit("items")
    return true


func register_character(character_data: Dictionary) -> bool:
    var character_id = character_data.get("id", "")
    if character_id == "" or characters.has(character_id):
        return false
    
    characters[character_id] = character_data
    _build_indexes()
    character_registered.emit(character_id)
    data_changed.emit("characters")
    return true


func register_monster(monster_data: Dictionary) -> bool:
    var monster_id = monster_data.get("id", "")
    if monster_id == "" or monsters.has(monster_id):
        return false
    
    monsters[monster_id] = monster_data
    _build_indexes()
    monster_registered.emit(monster_id)
    data_changed.emit("monsters")
    return true


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func has_data(data_type: String) -> bool:
    match data_type:
        "items": return items.size() > 0
        "characters": return characters.size() > 0
        "monsters": return monsters.size() > 0
        "npcs": return npcs.size() > 0
        "quests": return quests.size() > 0
        "skills": return skills.size() > 0
        "equipment": return equipment.size() > 0
        "world": return world_data.size() > 0
        _: return false


func get_data_stats() -> Dictionary:
    return {
        "items": items.size(),
        "characters": characters.size(),
        "monsters": monsters.size(),
        "npcs": npcs.size(),
        "quests": quests.size(),
        "skills": skills.size(),
        "equipment": equipment.size(),
        "world_areas": world_data.get("areas", {}).size()
    }


func clear_all_data() -> void:
    items.clear()
    characters.clear()
    monsters.clear()
    npcs.clear()
    quests.clear()
    skills.clear()
    equipment.clear()
    world_data.clear()
    item_index.clear()
    character_index.clear()
    monster_index.clear()
    
    print("[GameData] All data cleared")
