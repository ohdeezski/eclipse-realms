extends Node
## Localization.gd - Language and Text Localization System
## Handles multi-language support for all game text
## Load order: Ninth

## Signals
signal language_changed(language_code: String)
signal language_loaded(language_code: String)

## Constants
const LOCALIZATION_DIR: String = "res://resources/localization/"
const DEFAULT_LANGUAGE: String = "en"
const FALLBACK_LANGUAGE: String = "en"

## Supported languages
const SUPPORTED_LANGUAGES: Array = ["en", "es", "fr", "de", "ja", "zh"]

## Static variables
static var is_initialized: bool = false
static var current_language: String = DEFAULT_LANGUAGE
static var translations: Dictionary = {}
static var loaded_languages: Array = []


func _ready() -> void:
    if not is_initialized:
        _initialize()
        is_initialized = true


func _initialize() -> void:
    print("[Localization] Initializing localization system")
    
    # Load default language
    current_language = GameManager.get_game_config("language", DEFAULT_LANGUAGE)
    load_language(current_language)
    
    # Load any saved language preference
    var saved_lang = GameManager.get_game_config("language", null)
    if saved_lang != null:
        current_language = saved_lang
        load_language(current_language)
    
    print("[Localization] Localization system initialized")
    print("[Localization] Current language: %s" % current_language)


# ============================================================================
# LANGUAGE MANAGEMENT
# ============================================================================

func load_language(language_code: String) -> bool:
    if loaded_languages.has(language_code):
        return true
    
    if not SUPPORTED_LANGUAGES.has(language_code):
        push_warning("[Localization] Language not supported: %s" % language_code)
        return false
    
    var language_file: String = LOCALIZATION_DIR + "%s.json" % language_code
    
    if not ResourceLoader.exists(language_file):
        # Try to load from user directory
        language_file = "user://localization/%s.json" % language_code
        if not ResourceLoader.exists(language_file):
            push_warning("[Localization] Language file not found: %s" % language_file)
            return false
    
    var file = FileAccess.open(language_file, FileAccess.READ)
    if file == null:
        push_error("[Localization] Failed to open language file: %s" % language_file)
        return false
    
    var content = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var err = json.parse(content)
    
    if err != OK:
        push_error("[Localization] Failed to parse language file: %s" % language_code)
        return false
    
    # Store translations
    if json.data is Dictionary:
        translations[language_code] = json.data.duplicate()
        loaded_languages.append(language_code)
        language_loaded.emit(language_code)
        
        print("[Localization] Loaded language: %s" % language_code)
        return true
    
    return false


func unload_language(language_code: String) -> bool:
    if loaded_languages.has(language_code) and language_code != current_language:
        translations.erase(language_code)
        loaded_languages.erase(language_code)
        print("[Localization] Unloaded language: %s" % language_code)
        return true
    return false


func set_language(language_code: String) -> bool:
    if current_language == language_code:
        return true
    
    if not load_language(language_code):
        return false
    
    current_language = language_code
    
    # Save preference
    GameManager.set_game_config("language", language_code)
    SaveManager.save_config({"language": language_code})
    
    language_changed.emit(language_code)
    print("[Localization] Language changed to: %s" % language_code)
    return true


func get_current_language() -> String:
    return current_language


func get_supported_languages() -> Array:
    return SUPPORTED_LANGUAGES.duplicate()


func get_loaded_languages() -> Array:
    return loaded_languages.duplicate()


# ============================================================================
# TRANSLATION FUNCTIONS
# ============================================================================

func translate(key: String, args: Array = []) -> String:
    """
    Translate a text key to the current language.
    Supports string formatting with arguments.
    Falls back to fallback language if key not found.
    """
    var text = _get_translation(key)
    
    if text == key and current_language != FALLBACK_LANGUAGE:
        # Try fallback language
        text = _get_translation(key, FALLBACK_LANGUAGE)
    
    # Format with arguments if provided
    if args.size() > 0:
        return text % args
    
    return text


func translate_plural(key: String, count: int, args: Array = []) -> String:
    """
    Translate a pluralizable text key.
    Uses different forms based on the count.
    """
    var plural_key = _get_plural_key(key, count)
    var text = translate(plural_key, args)
    
    # If no plural form found, try the base key
    if text == plural_key:
        text = translate(key, args)
    
    return text


func translate_context(context: String, key: String, args: Array = []) -> String:
    """
    Translate a key within a specific context.
    Contexts help organize keys and prevent conflicts.
    """
    var context_key = "%s.%s" % [context, key]
    var text = translate(context_key, args)
    
    # If not found in context, try without context
    if text == context_key:
        text = translate(key, args)
    
    return text


func _get_translation(key: String, language: String = "") -> String:
    var lang = language if language != "" else current_language
    
    if translations.has(lang):
        if translations[lang].has(key):
            return translations[lang][key]
    
    # Return the key as fallback
    return key


func _get_plural_key(base_key: String, count: int) -> String:
    # Handle different plural forms based on language rules
    # This is a simplified version
    
    if current_language == "en":
        # English: singular (1), plural (0, 2+)
        if count == 1:
            return "%s.one" % base_key
        else:
            return "%s.other" % base_key
    elif current_language == "ja" or current_language == "zh":
        # Japanese/Chinese: no plural forms
        return base_key
    else:
        # Default: treat all as plural
        return "%s.other" % base_key


# ============================================================================
# BATCH TRANSLATION
# ============================================================================

func translate_dict(source: Dictionary) -> Dictionary:
    """Translate all values in a dictionary"""
    var result: Dictionary = {}
    
    for key in source:
        if source[key] is String:
            result[key] = translate(source[key])
        elif source[key] is Dictionary:
            result[key] = translate_dict(source[key])
        elif source[key] is Array:
            result[key] = translate_array(source[key])
        else:
            result[key] = source[key]
    
    return result


func translate_array(source: Array) -> Array:
    """Translate all string values in an array"""
    var result: Array = []
    
    for item in source:
        if item is String:
            result.append(translate(item))
        elif item is Dictionary:
            result.append(translate_dict(item))
        elif item is Array:
            result.append(translate_array(item))
        else:
            result.append(item)
    
    return result


# ============================================================================
# TEXT UTILITY FUNCTIONS
# ============================================================================

func format_text(text: String, args: Array = []) -> String:
    """Format text with arguments"""
    if args.size() == 0:
        return text
    return text % args


func wrap_text(text: String, max_length: int) -> String:
    """Wrap text to a maximum line length"""
    if max_length <= 0:
        return text
    
    var words = text.split(" ")
    var lines: Array = []
    var current_line = ""
    
    for word in words:
        if current_line.length() + word.length() + 1 <= max_length:
            current_line += " %s" % word if current_line != "" else word
        else:
            if current_line != "":
                lines.append(current_line)
            current_line = word
    
    if current_line != "":
        lines.append(current_line)
    
    return "\n".join(lines)


func truncate_text(text: String, max_length: int, ellipsis: String = "...") -> String:
    """Truncate text to a maximum length with ellipsis"""
    if text.length() <= max_length:
        return text
    
    if max_length <= ellipsis.length():
        return ellipsis.substr(0, max_length)
    
    return text.substr(0, max_length - ellipsis.length()) + ellipsis


# ============================================================================
# LOCALIZATION DATA MANAGEMENT
# ============================================================================

func has_translation(key: String, language: String = "") -> bool:
    var lang = language if language != "" else current_language
    
    if translations.has(lang):
        return translations[lang].has(key)
    
    return false


func get_all_keys(language: String = "") -> Array:
    var lang = language if language != "" else current_language
    
    if translations.has(lang):
        return translations[lang].keys()
    
    return []


func get_missing_keys(language: String = "") -> Array:
    """Get keys that are missing from a language compared to the fallback"""
    var lang = language if language != "" else current_language
    
    if lang == FALLBACK_LANGUAGE:
        return []
    
    if not translations.has(lang) or not translations.has(FALLBACK_LANGUAGE):
        return []
    
    var missing: Array = []
    
    for key in translations[FALLBACK_LANGUAGE]:
        if not translations[lang].has(key):
            missing.append(key)
    
    return missing


# ============================================================================
# LANGUAGE FILE CREATION
# ============================================================================

func create_language_file(language_code: String, from_fallback: bool = true) -> bool:
    """Create a new language file based on the fallback"""
    if not SUPPORTED_LANGUAGES.has(language_code):
        return false
    
    if from_fallback and not translations.has(FALLBACK_LANGUAGE):
        if not load_language(FALLBACK_LANGUAGE):
            return false
    
    var language_file: String = LOCALIZATION_DIR + "%s.json" % language_code
    
    var file = FileAccess.open(language_file, FileAccess.WRITE)
    if file == null:
        push_error("[Localization] Failed to create language file: %s" % language_file)
        return false
    
    var data: Dictionary
    
    if from_fallback and translations.has(FALLBACK_LANGUAGE):
        # Copy from fallback
        data = translations[FALLBACK_LANGUAGE].duplicate()
        
        # Add translation notes
        for key in data:
            data[key] = "[TRANSLATE] %s" % data[key]
    else:
        # Create empty structure
        data = {}
    
    var json = JSON.new()
    json.stringify(data)
    file.store_string(json.get_data())
    file.close()
    
    print("[Localization] Created language file: %s" % language_code)
    return true


# ============================================================================
# DYNAMIC TRANSLATIONS
# ============================================================================

func add_translation(key: String, text: String, language: String = "") -> bool:
    """Add a translation for a key"""
    var lang = language if language != "" else current_language
    
    if not translations.has(lang):
        translations[lang] = {}
    
    translations[lang][key] = text
    return true


func add_translations(translation_dict: Dictionary, language: String = "") -> bool:
    """Add multiple translations at once"""
    var lang = language if language != "" else current_language
    
    if not translations.has(lang):
        translations[lang] = {}
    
    for key in translation_dict:
        translations[lang][key] = translation_dict[key]
    
    return true


func remove_translation(key: String, language: String = "") -> bool:
    """Remove a translation"""
    var lang = language if language != "" else current_language
    
    if translations.has(lang) and translations[lang].has(key):
        translations[lang].erase(key)
        return true
    
    return false


# ============================================================================
# SPECIAL TEXT HANDLING
# ============================================================================

func translate_npc_dialogue(npc_id: String, dialogue_type: String, index: int = 0) -> String:
    """Translate NPC dialogue"""
    var key = "dialogue.%s.%s.%d" % [npc_id, dialogue_type, index]
    return translate(key)


func translate_item_name(item_id: String) -> String:
    """Translate item name"""
    var key = "items.%s.name" % item_id
    var name = translate(key)
    
    if name == key:
        # Check if GameData is available
        if has_node("/root/GameData") and GameData.is_initialized:
            var item = GameData.get_item(item_id)
            if item and item.has("name"):
                return item["name"]
        return item_id
    
    return name


func translate_item_description(item_id: String) -> String:
    """Translate item description"""
    var key = "items.%s.description" % item_id
    var description = translate(key)
    
    if description == key:
        # Check if GameData is available
        if has_node("/root/GameData") and GameData.is_initialized:
            var item = GameData.get_item(item_id)
            if item and item.has("description"):
                return item["description"]
        return ""
    
    return description


func translate_quest_name(quest_id: String) -> String:
    """Translate quest name"""
    var key = "quests.%s.name" % quest_id
    var name = translate(key)
    
    if name == key:
        var quest = GameData.get_quest(quest_id)
        if quest.size() > 0 and quest.has("name"):
            return quest["name"]
        return quest_id
    
    return name


func translate_quest_description(quest_id: String) -> String:
    """Translate quest description"""
    var key = "quests.%s.description" % quest_id
    var description = translate(key)
    
    if description == key:
        var quest = GameData.get_quest(quest_id)
        if quest.size() > 0 and quest.has("description"):
            return quest["description"]
        return ""
    
    return description


func translate_skill_name(skill_id: String) -> String:
    """Translate skill name"""
    var key = "skills.%s.name" % skill_id
    var name = translate(key)
    
    if name == key:
        var skill = GameData.get_skill(skill_id)
        if skill.size() > 0 and skill.has("name"):
            return skill["name"]
        return skill_id
    
    return name


func translate_area_name(area_id: String) -> String:
    """Translate area name"""
    var key = "world.areas.%s.name" % area_id
    var name = translate(key)
    
    if name == key:
        var area = GameData.get_area(area_id)
        if area.size() > 0 and area.has("name"):
            return area["name"]
        return area_id
    
    return name


# ============================================================================
# NUMBER AND CURRENCY FORMATTING
# ============================================================================

func format_number(number: int) -> String:
    """Format number according to current language"""
    # For now, just return the number
    # This can be expanded for different number formats
    return str(number)


func format_currency(amount: int, currency_symbol: String = "G") -> String:
    """Format currency amount"""
    var key = "ui.currency_format"
    var format = translate(key)
    
    if format == key:
        # Default format
        return "%s %d" % [currency_symbol, amount]
    
    return format % [currency_symbol, amount]


func format_percentage(value: float) -> String:
    """Format percentage value"""
    var key = "ui.percentage_format"
    var format = translate(key)
    
    if format == key:
        return "%.1f%%" % (value * 100)
    
    return format % (value * 100)


# ============================================================================
# DEBUG AND STATISTICS
# ============================================================================

func get_translation_count(language: String = "") -> int:
    var lang = language if language != "" else current_language
    
    if translations.has(lang):
        return translations[lang].size()
    
    return 0


func get_statistics() -> Dictionary:
    var stats: Dictionary = {
        "current_language": current_language,
        "loaded_languages": loaded_languages.size(),
        "supported_languages": SUPPORTED_LANGUAGES.size()
    }
    
    for lang in loaded_languages:
        stats["translations_%s" % lang] = translations.get(lang, {}).size()
    
    return stats


func print_statistics() -> void:
    print("[Localization] Statistics:")
    var stats = get_statistics()
    
    for key in stats:
        print("  %s: %s" % [key, stats[key]])
