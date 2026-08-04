extends Area2D
class_name NPC
## NPC.gd - Interactive NPC with dialogue trees, quests, and shop functionality
## Version: 0.2 - Phase 2 First Playable

signal interacted(npc_id: String)
signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)
signal quest_offered(npc_id: String, quest_id: String)
signal shop_opened(npc_id: String)

## NPC Configuration
var npc_id: String = ""
var npc_name: String = "NPC"
var npc_title: String = ""
var role: String = ""  # "quest_giver", "merchant", "innkeeper", "service", "villager"

## Dialogue System
var dialogue: Dictionary = {}
var dialogue_tree: Dictionary = {}  # Structured dialogue tree with states
var current_dialogue_state: String = "greeting"
var dialogue_history: Array = []  # Track what player has seen

## Quest System
var quest_ids: Array = []
var related_quest: String = ""
var max_quests_per_interaction: int = 1

## Shop System
var shop_data: Dictionary = {}
var is_shop_open: bool = false

## Service System (for innkeeper, etc.)
var services: Array = []
var service_costs: Dictionary = {}

## Interaction Settings
var interaction_cooldown: float = 0.5
var interaction_timer: float = 0.0
var interaction_range: float = 60.0
var can_interact: bool = true

## Visual Components
@onready var sprite: ColorRect = $Sprite
@onready var label: Label = $Label
@onready var interaction_indicator: Sprite2D = $InteractionIndicator if has_node("InteractionIndicator") else null
@onready var cooldown_timer: Timer = $CooldownTimer if has_node("CooldownTimer") else null

## State Tracking
var is_player_nearby: bool = false
var nearby_player: Node = null


func _ready() -> void:
    add_to_group("npc")
    _setup_signals()
    _setup_cooldown_timer()
    print("[NPC] Initialized: %s (%s)" % [npc_name, npc_id])


func _setup_signals() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)


func _setup_cooldown_timer() -> void:
    if not has_node("CooldownTimer"):
        var timer = Timer.new()
        timer.name = "CooldownTimer"
        timer.one_shot = true
        timer.wait_time = interaction_cooldown
        add_child(timer)
        cooldown_timer = timer
    else:
        cooldown_timer = get_node("CooldownTimer")
    
    if not cooldown_timer.timeout.is_connected(_on_cooldown_timeout):
        cooldown_timer.timeout.connect(_on_cooldown_timeout)


func _process(delta: float) -> void:
    # Update interaction indicator visibility
    if interaction_indicator and nearby_player:
        var dist = global_position.distance_to(nearby_player.global_position)
        interaction_indicator.visible = dist < interaction_range and can_interact


## ============================================================================
## CONFIGURATION
## ============================================================================

func configure(data: Dictionary) -> void:
    """Configure NPC from GameData dictionary"""
    npc_id = data.get("id", npc_id)
    npc_name = data.get("name", npc_name)
    npc_title = data.get("title", npc_title)
    role = data.get("category", role)
    dialogue = data.get("dialogue", {})
    dialogue_tree = data.get("dialogue_tree", {})
    quest_ids = data.get("quests", [])
    related_quest = data.get("related_quest", "")
    shop_data = data.get("shop", {})
    services = data.get("services", [])
    service_costs = {
        "rest": data.get("rest_cost", 10),
        "heal": data.get("heal_cost", 50)
    }
    
    # Set display name
    if label:
        label.text = npc_name
        if npc_title:
            label.text += "\n" + npc_title
    
    # Set sprite position
    if sprite:
        sprite.position = Vector2(-16, -16)
    
    # Initialize dialogue tree if not provided
    if dialogue_tree.is_empty():
        _initialize_default_dialogue_tree()
    
    print("[NPC] Configured %s: role=%s, quests=%d, has_shop=%s" % [
        npc_name, role, quest_ids.size(), not shop_data.is_empty()
    ])


func _initialize_default_dialogue_tree() -> void:
    """Create a default dialogue tree structure"""
    dialogue_tree = {
        "greeting": {
            "text": dialogue.get("greeting", ["Hello, traveler."]),
            "next": "main_menu",
            "conditions": {},
            "effects": []
        },
        "main_menu": {
            "text": "How can I help you?",
            "options": _build_main_menu_options(),
            "type": "branching"
        },
        "farewell": {
            "text": dialogue.get("farewell", ["Farewell, traveler."]),
            "next": null,
            "effects": ["clear_dialogue"]
        }
    }


func _build_main_menu_options() -> Array:
    """Build main menu options based on NPC role"""
    var options: Array = []
    
    # Quest option
    if role in ["quest_giver", "villager"] and not quest_ids.is_empty():
        options.append({
            "text": "Do you have any work for me?",
            "next": "quest_menu",
            "conditions": {}
        })
    
    # Shop option
    if role == "merchant" and not shop_data.is_empty():
        options.append({
            "text": "Show me your wares",
            "next": "shop_menu",
            "conditions": {}
        })
    
    # Service option (innkeeper)
    if role == "service" and not services.is_empty():
        options.append({
            "text": "I need some rest",
            "next": "service_menu",
            "conditions": {}
        })
    
    # Lore/flavor option
    options.append({
        "text": "Tell me about this place",
        "next": "lore_dialogue",
        "conditions": {}
    })
    
    # Always add farewell
    options.append({
        "text": "Goodbye",
        "next": "farewell",
        "conditions": {}
    })
    
    return options


## ============================================================================
## PROXIMITY DETECTION
## ============================================================================

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        is_player_nearby = true
        nearby_player = body
        UIManager.show_notification("Press E to talk to %s" % npc_name, "info")
        
        # Show interaction indicator
        if interaction_indicator:
            interaction_indicator.visible = true


func _on_body_exited(body: Node) -> void:
    if body.is_in_group("player"):
        is_player_nearby = false
        nearby_player = null
        
        # Hide interaction indicator
        if interaction_indicator:
            interaction_indicator.visible = false
        
        # Close any open dialogs/menus
        _close_all_dialogs()


func _close_all_dialogs() -> void:
    """Close any open dialogs when player leaves"""
    if is_shop_open:
        _close_shop()
    dialogue_ended.emit(npc_id)


## ============================================================================
## INTERACTION SYSTEM
## ============================================================================

func interact(player) -> void:
    """Main interaction entry point"""
    # Check cooldown
    if not can_interact:
        return
    
    # Check if player is in range
    if not is_player_nearby or not player:
        return
    
    # Start cooldown
    _start_cooldown()
    
    # Emit signal
    interacted.emit(npc_id)
    
    # Route to appropriate handler based on state
    match current_dialogue_state:
        "greeting":
            _handle_greeting(player)
        "main_menu":
            _handle_main_menu(player)
        "quest_menu":
            _handle_quest_menu(player)
        "shop_menu":
            _handle_shop_menu(player)
        "service_menu":
            _handle_service_menu(player)
        "lore_dialogue":
            _handle_lore_dialogue(player)
        _:
            _handle_greeting(player)


func _start_cooldown() -> void:
    """Start interaction cooldown"""
    can_interact = false
    cooldown_timer.start(interaction_cooldown)


func _on_cooldown_timeout() -> void:
    """Reset interaction after cooldown"""
    can_interact = true


## ============================================================================
## DIALOGUE HANDLERS
## ============================================================================

func _handle_greeting(player) -> void:
    """Handle initial greeting"""
    dialogue_started.emit(npc_id)
    
    # Get greeting text (can be array for random selection)
    var greet_text = dialogue.get("greeting", "Hello, traveler.")
    if greet_text is Array:
        greet_text = greet_text[randi() % greet_text.size()]
    
    _say(greet_text)
    
    # Move to main menu after a short delay
    await get_tree().create_timer(0.5).timeout
    current_dialogue_state = "main_menu"
    _handle_main_menu(player)


func _handle_main_menu(player) -> void:
    """Handle main dialogue menu"""
    var options = _build_main_menu_options()
    _show_dialogue_options("How can I help you?", options)


func _handle_quest_menu(player) -> void:
    """Handle quest-related dialogue"""
    var available_quests = _get_available_quests(player)
    var active_quests = _get_active_quests(player)
    var completed_quests = _get_completed_quests(player)
    
    if not available_quests.is_empty():
        # Offer quest
        var quest_id = available_quests[0]
        var quest_data = GameData.get_quest(quest_id)
        
        if not quest_data.is_empty():
            var quest_text = dialogue.get("quest_offer", "I have a task for you.")
            if quest_text is Array:
                quest_text = quest_text[randi() % quest_text.size()]
            
            _say(quest_text)
            _show_quest_details(quest_data)
    elif not active_quests.is_empty():
        # Check active quests
        var quest_id = active_quests[0]
        var quest_data = GameData.get_quest(quest_id)
        
        if not quest_data.is_empty():
            _say("How is your quest going?")
            _show_quest_status(quest_data)
    else:
        _say("Come back later, I might have something for you.")
    
    # Return to main menu
    current_dialogue_state = "main_menu"


func _handle_shop_menu(player) -> void:
    """Handle shop dialogue and open shop UI"""
    if shop_data.is_empty():
        _say("I don't have anything to sell right now.")
        return
    
    # Show shop greeting
    var shop_text = dialogue.get("shop", "Take a look at my wares.")
    if shop_text is Array:
        shop_text = shop_text[randi() % shop_text.size()]
    
    _say(shop_text)
    
    # Open shop UI
    _open_shop(player)
    shop_opened.emit(npc_id)


func _handle_service_menu(player) -> void:
    """Handle service dialogue (innkeeper, etc.)"""
    if services.is_empty():
        _say("I don't offer any services right now.")
        return
    
    # Show service options
    var service_options = []
    for service in services:
        var cost = service_costs.get(service, 0)
        var service_text = "%s (%d gold)" % [service.capitalize(), cost]
        service_options.append({
            "text": service_text,
            "next": "service_%s" % service,
            "conditions": {"gold": cost}
        })
    
    service_options.append({
        "text": "Never mind",
        "next": "main_menu",
        "conditions": {}
    })
    
    _show_dialogue_options("What would you like?", service_options)


func _handle_lore_dialogue(player) -> void:
    """Handle lore/flavor dialogue"""
    var lore_text = dialogue.get("lore", [
        "This village has stood for generations.",
        "The forest to the north is full of mysteries.",
        "May the light guide you on your journey."
    ])
    
    if lore_text is Array:
        _say(lore_text[randi() % lore_text.size()])
    else:
        _say(lore_text)
    
    # Return to main menu
    current_dialogue_state = "main_menu"


## ============================================================================
## DIALOGUE DISPLAY
## ============================================================================

func _say(text: String) -> void:
    """Display dialogue text"""
    UIManager.show_notification("%s: %s" % [npc_name, text], "info")


func _show_dialogue_options(header: String, options: Array) -> void:
    """Show dialogue options to player via the Dialogue UI"""
    UIManager.show_dialog("dialogue", {
        "npc_id": npc_id,
        "npc_name": npc_name,
        "npc_title": npc_title,
        "header": header,
        "options": options,
        "callback": _on_dialogue_option_selected
    })


func _on_dialogue_option_selected(option_index: int) -> void:
    """Handle dialogue option selection from Dialogue UI"""
    var options = _build_main_menu_options()
    if option_index < options.size():
        var selected = options[option_index]
        current_dialogue_state = selected.get("next", "greeting")
        # Re-interact with the player to handle the new state
        var players = get_tree().get_nodes_in_group("player")
        if players.size() > 0:
            interact(players[0])


## ============================================================================
## QUEST SYSTEM
## ============================================================================

func _get_available_quests(player) -> Array:
    """Get quests available to the player"""
    var available: Array = []
    
    for quest_id in quest_ids:
        var quest_data = GameData.get_quest(quest_id)
        if quest_data.is_empty():
            continue
        
        # Check if already active or completed
        if quest_id in player.active_quests or quest_id in player.completed_quests:
            continue
        
        # Check requirements
        var requirements = quest_data.get("requirements", {})
        var meets_requirements = true
        
        # Level requirement
        if requirements.has("level") and player.level < requirements["level"]:
            meets_requirements = false
        
        # Completed quests requirement
        if requirements.has("completed_quests"):
            for req_quest in requirements["completed_quests"]:
                if req_quest not in player.completed_quests:
                    meets_requirements = false
        
        if meets_requirements:
            available.append(quest_id)
    
    return available


func _get_active_quests(player) -> Array:
    """Get active quests from this NPC"""
    var active: Array = []
    for quest_id in quest_ids:
        if quest_id in player.active_quests:
            active.append(quest_id)
    return active


func _get_completed_quests(player) -> Array:
    """Get completed quests from this NPC"""
    var completed: Array = []
    for quest_id in quest_ids:
        if quest_id in player.completed_quests:
            completed.append(quest_id)
    return completed


func _show_quest_details(quest_data: Dictionary) -> void:
    """Show quest details to player via Dialogue UI quest panel"""
    # Get the dialogue UI instance and show quest offer
    var dialog = UIManager.get_dialog("dialogue")
    if dialog and dialog.has_method("show_quest_offer"):
        dialog.show_quest_offer(quest_data)
        # Connect quest signals
        if not dialog.quest_accepted.is_connected(_on_quest_accepted):
            dialog.quest_accepted.connect(_on_quest_accepted)
        if not dialog.quest_declined.is_connected(_on_quest_declined):
            dialog.quest_declined.connect(_on_quest_declined)
    else:
        # Fallback to notification
        var details = "Quest: %s\n" % quest_data.get("name", "Unknown")
        details += "Description: %s\n" % quest_data.get("description", "")
        _say(details)


func _show_quest_status(quest_data: Dictionary) -> void:
    """Show quest progress status via Dialogue UI"""
    var dialog = UIManager.get_dialog("dialogue")
    if dialog and dialog.has_method("show_quest_status"):
        dialog.show_quest_status(quest_data)
    else:
        # Fallback to notification
        var status = "Quest: %s\n" % quest_data.get("name", "Unknown")
        var objectives = quest_data.get("objectives", [])
        for obj in objectives:
            status += "- %s: %d/%d\n" % [
                obj.get("description", obj.get("target", "")),
                obj.get("current", 0),
                obj.get("count", 1)
            ]
        _say(status)


func _on_quest_accepted(quest_id: String) -> void:
    """Handle quest acceptance from Dialogue UI"""
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        var player = players[0]
        if player.has_method("accept_quest"):
            player.accept_quest(quest_id)
            quest_offered.emit(npc_id, quest_id)
            dialogue_ended.emit(npc_id)


func _on_quest_declined(quest_id: String) -> void:
    """Handle quest decline from Dialogue UI"""
    dialogue_ended.emit(npc_id)


## ============================================================================
## SHOP SYSTEM
## ============================================================================

func _open_shop(player) -> void:
    """Open the shop interface"""
    is_shop_open = true
    
    # Build shop inventory
    var shop_items = []
    var item_ids = shop_data.get("items", [])
    var buy_multiplier = shop_data.get("buy_multiplier", 1.0)
    var sell_multiplier = shop_data.get("sell_multiplier", 0.5)
    
    for item_id in item_ids:
        var item_data = GameData.get_item(item_id)
        if not item_data.is_empty():
            var price = int(item_data.get("value", 0) * buy_multiplier)
            shop_items.append({
                "id": item_id,
                "name": item_data.get("name", item_id),
                "description": item_data.get("description", ""),
                "price": price,
                "type": item_data.get("type", "misc"),
                "stats": item_data.get("stats", {})
            })
    
    # Open shop UI
    UIManager.show_dialog("shop", {
        "npc_id": npc_id,
        "npc_name": npc_name,
        "shop_type": shop_data.get("type", "general"),
        "items": shop_items,
        "player_gold": player.gold,
        "buy_multiplier": buy_multiplier,
        "sell_multiplier": sell_multiplier,
        "buy_callback": _on_shop_buy,
        "sell_callback": _on_shop_sell,
        "close_callback": _on_shop_close,
        "player": player
    })


func _close_shop() -> void:
    """Close the shop interface"""
    is_shop_open = false
    UIManager.hide_dialog("shop")


func _on_shop_buy(item_id: String, player) -> void:
    """Handle buying an item from the shop"""
    var item_data = GameData.get_item(item_id)
    if item_data.is_empty():
        return
    
    var buy_multiplier = shop_data.get("buy_multiplier", 1.0)
    var price = int(item_data.get("value", 0) * buy_multiplier)
    
    if player.gold >= price:
        player.gold -= price
        player.add_item(item_id)
        _say("Thank you for your purchase!")
        UIManager.show_notification("Bought %s for %d gold" % [item_data.get("name", item_id), price], "success")
    else:
        _say("You don't have enough gold for that.")
        UIManager.show_notification("Not enough gold!", "error")


func _on_shop_sell(item_id: String, player) -> void:
    """Handle selling an item to the shop"""
    if item_id not in player.inventory:
        return
    
    var item_data = GameData.get_item(item_id)
    if item_data.is_empty():
        return
    
    var sell_multiplier = shop_data.get("sell_multiplier", 0.5)
    var price = int(item_data.get("value", 0) * sell_multiplier)
    
    # Remove item from inventory
    var index = player.inventory.find(item_id)
    if index != -1:
        player.inventory.remove_at(index)
        player.gold += price
        _say("Pleasure doing business!")
        UIManager.show_notification("Sold %s for %d gold" % [item_data.get("name", item_id), price], "success")


func _on_shop_close() -> void:
    """Handle shop closing"""
    _close_shop()


## ============================================================================
## SERVICE SYSTEM
## ============================================================================

func _on_service_selected(service: String, player) -> void:
    """Handle service selection"""
    var cost = service_costs.get(service, 0)
    
    if player.gold < cost:
        _say("You don't have enough gold for that.")
        return
    
    match service:
        "rest":
            _handle_rest_service(player, cost)
        "heal":
            _handle_heal_service(player, cost)
        _:
            _say("That service isn't available yet.")


func _handle_rest_service(player, cost: int) -> void:
    """Handle rest service (full heal + save)"""
    player.gold -= cost
    player.health = player.max_health
    player.mana = player.max_mana
    _say("Rest well, traveler. You've been fully healed!")
    UIManager.show_notification("Fully healed! (Cost: %d gold)" % cost, "success")
    SaveManager.save_game()


func _handle_heal_service(player, cost: int) -> void:
    """Handle heal service (restore HP only)"""
    player.gold -= cost
    player.health = player.max_health
    _say("You've been healed!")
    UIManager.show_notification("Healed! (Cost: %d gold)" % cost, "success")


## ============================================================================
## UTILITY FUNCTIONS
## ============================================================================

func reset_dialogue() -> void:
    """Reset dialogue state"""
    current_dialogue_state = "greeting"
    dialogue_history.clear()


func get_npc_info() -> Dictionary:
    """Get NPC information"""
    return {
        "id": npc_id,
        "name": npc_name,
        "title": npc_title,
        "role": role,
        "has_quests": not quest_ids.is_empty(),
        "has_shop": not shop_data.is_empty(),
        "has_services": not services.is_empty()
    }
