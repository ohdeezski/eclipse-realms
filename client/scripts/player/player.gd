extends CharacterBody2D
class_name Player
## Player.gd - Playable character for Eclipse Realms (v0.1 vertical slice)
## Wires movement/camera to InputManager, combat to GameManager/SaveManager.

signal health_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal gold_changed(amount: int)
signal died
signal leveled_up(level: int)
signal attack_performed(direction: Vector2)
signal damage_dealt(amount: int, is_critical: bool)
signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_progress_changed(quest_id: String, current: int, target: int)

const SPEED: float = 180.0
const RUN_SPEED: float = 280.0
const ATTACK_RANGE: float = 48.0
const ATTACK_COOLDOWN: float = 0.4
const CRIT_CHANCE: float = 0.15  # 15% crit chance
const CRIT_MULTIPLIER: float = 1.5

# ---- Stats (initialized from GameData character on spawn) ----
var max_health: int = 100
var health: int = 100
var max_mana: int = 50
var mana: int = 50
var attack: int = 10
var defense: int = 5
var level: int = 1
var experience: int = 0
var gold: int = 0
var is_dead: bool = false
var is_guarding: bool = false
var guard_timer: float = 0.0

# ---- Combat State ----
var _attack_cooldown: float = 0.0
var _facing: Vector2 = Vector2.RIGHT
var _combo_count: int = 0
var _combo_timer: float = 0.0
const COMBO_WINDOW: float = 0.8
const COMBO_BONUS: float = 0.1  # 10% damage per combo hit

var inventory: Array = []          # item ids
var equipment: Dictionary = {}      # slot -> item id
var active_quests: Dictionary = {} # quest_id -> {current counts}
var completed_quests: Array = []

# Movement state
var facing_direction: Vector2 = Vector2.DOWN
var is_running: bool = false
var _facing_name: String = "down"

@onready var sprite: ColorRect = $Sprite
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D
@onready var hit_flash: Timer = $HitFlash
@onready var combat_effects: CombatEffects = null
var combat_feedback: CombatFeedback = null

func _ready() -> void:
    add_to_group("player")
    # Center the sprite on the body
    if sprite:
        sprite.position = Vector2(-16, -16)
    # Load character base if available
    var char_data = GameData.get_character("human_adept")
    if char_data.has("base_stats"):
        _apply_stats(char_data["base_stats"])

    # Apply pending save data if a load was triggered before this scene spawned
    if SaveManager.has_pending_data():
        load_from_save_data(
            SaveManager.consume_pending_player_data(),
            SaveManager.consume_pending_inventory_data(),
            SaveManager.consume_pending_quest_data(),
            SaveManager.consume_pending_equipment_data()
        )
    else:
        health = max_health
        mana = max_mana

    health_changed.emit(health, max_health)
    mana_changed.emit(mana, max_mana)
    InputManager.set_input_context("game")

    # Configure camera follow
    if camera:
        camera.position_smoothing_enabled = true
        camera.position_smoothing_speed = 8.0
        camera.make_current()

    # Initialize combat effects
    combat_effects = CombatEffects.new()
    add_child(combat_effects)

    # Find combat feedback in parent (set up by World)
    call_deferred("_find_combat_feedback")


func _find_combat_feedback() -> void:
    var world = get_parent()
    if world and world.has_node("CombatFeedback"):
        combat_feedback = world.get_node("CombatFeedback")


func _apply_stats(stats: Dictionary) -> void:
    max_health = int(stats.get("health", max_health))
    max_mana = int(stats.get("mana", max_mana))
    attack = int(stats.get("attack", attack))
    defense = int(stats.get("defense", defense))
    mana = max_mana


# ============================================================================
# MOVEMENT & VISUALS
# ============================================================================

func _get_direction_name(dir: Vector2) -> String:
    if abs(dir.x) > abs(dir.y):
        return "right" if dir.x > 0 else "left"
    return "down" if dir.y > 0 else "up"


func _update_visual(dir: Vector2) -> void:
    if not sprite:
        return
    # Hit flash takes priority
    if not hit_flash.is_stopped():
        sprite.color = Color(1.0, 1.0, 1.0)
        return
    if dir == Vector2.ZERO:
        sprite.color = Color(0.2, 0.6, 0.9, 1.0)
    else:
        match _facing_name:
            "down":
                sprite.color = Color(0.2, 0.6, 0.9, 1.0)
            "up":
                sprite.color = Color(0.3, 0.75, 0.95, 1.0)
            "left":
                sprite.color = Color(0.15, 0.55, 0.85, 1.0)
            "right":
                sprite.color = Color(0.25, 0.65, 0.95, 1.0)


func _play_attack_visual() -> void:
    if not sprite:
        return
    var tween = create_tween()
    tween.tween_property(sprite, "color", Color(1.0, 0.3, 0.3, 1.0), 0.05)
    tween.tween_property(sprite, "color", Color(0.2, 0.6, 0.9, 1.0), 0.15)


func _physics_process(delta: float) -> void:
    if is_dead:
        return

    var dir := Vector2.ZERO
    if InputManager.is_action_pressed("move_left"):
        dir.x -= 1
    if InputManager.is_action_pressed("move_right"):
        dir.x += 1
    if InputManager.is_action_pressed("move_up"):
        dir.y -= 1
    if InputManager.is_action_pressed("move_down"):
        dir.y += 1
    if dir != Vector2.ZERO:
        dir = dir.normalized()
        _facing = dir
        facing_direction = dir
        _facing_name = _get_direction_name(dir)

    # Running
    is_running = InputManager.is_action_pressed("run")
    var current_speed = RUN_SPEED if is_running and dir != Vector2.ZERO else SPEED

    velocity = dir * current_speed
    move_and_slide()

    # Update visual feedback
    _update_visual(dir)

    # Guard timing
    if is_guarding:
        guard_timer -= delta
        if guard_timer <= 0.0:
            is_guarding = false

    # Attack cooldown
    if _attack_cooldown > 0.0:
        _attack_cooldown -= delta

    # Combo timer
    if _combo_timer > 0.0:
        _combo_timer -= delta
        if _combo_timer <= 0.0:
            _combo_count = 0

    # Attack input
    if InputManager.is_action_just_pressed("attack"):
        _perform_attack()

    # Guard input
    if InputManager.is_action_just_pressed("guard"):
        _start_guard()

    # Quest log toggle
    if InputManager.is_action_just_pressed("quest_log"):
        var quest_log = get_tree().get_first_node_in_group("quest_log")
        if quest_log:
            quest_log.toggle()

    # Character / Equipment panel toggle (C key)
    if InputManager.is_action_just_pressed("character"):
        if UIManager.is_menu_open("equipment"):
            UIManager.close_menu("equipment")
        else:
            var equip_menu = UIManager.open_menu("equipment")
            if equip_menu and equip_menu.has_method("open_equipment"):
                equip_menu.open_equipment(self)

    # Interact input handled by world via Area2D; nothing here.


func _perform_attack() -> void:
    if _attack_cooldown > 0.0:
        return
    
    _attack_cooldown = ATTACK_COOLDOWN
    _play_attack_visual()

    # Update combo
    _combo_count += 1
    _combo_timer = COMBO_WINDOW
    var combo_multiplier = 1.0 + (_combo_count - 1) * COMBO_BONUS
    
    # Spawn slash effect
    if combat_effects:
        combat_effects.spawn_slash_effect(global_position, _facing)
    
    attack_performed.emit(_facing)
    
    # Simple melee: hit monsters in front within range
    var targets = get_tree().get_nodes_in_group("enemy")
    var hit_any = false
    
    for t in targets:
        if global_position.distance_to(t.global_position) < ATTACK_RANGE and not t.is_dead:
            # Check if target is roughly in front of player
            var to_target = (t.global_position - global_position).normalized()
            var dot = _facing.dot(to_target)
            
            if dot > 0.3:  # ~70 degree cone in front
                # Calculate damage with combo
                var base_dmg = max(1, attack - t.defense)
                var combo_dmg = int(base_dmg * combo_multiplier)
                
                # Critical hit check
                var is_crit = randf() < CRIT_CHANCE
                var final_dmg = int(combo_dmg * CRIT_MULTIPLIER) if is_crit else combo_dmg
                
                # Apply damage
                t.take_damage(final_dmg)
                hit_any = true

                # Register hit with combat feedback
                if combat_feedback:
                    combat_feedback.register_hit(final_dmg, t.monster_name if t.has("monster_name") else "Enemy")

                # Visual feedback
                if combat_effects:
                    combat_effects.spawn_damage_number(t.global_position + Vector2(0, -16), final_dmg, is_crit)
                    if is_crit:
                        combat_effects.spawn_crit_flash(t)
                        combat_effects.apply_screen_shake(5.0, 0.15)
                        combat_effects.spawn_crit_particles(t.global_position)
                        combat_effects.spawn_screen_flash(Color(1.0, 0.85, 0.2, 0.12), 0.1)
                    else:
                        combat_effects.spawn_hit_flash(t)
                        combat_effects.spawn_hit_particles(t.global_position)
                
                AudioManager.play_sfx("player_attack")
                
                if t.is_dead:
                    _on_enemy_killed(t)
    
    # Show combo indicator
    if _combo_count > 1 and hit_any:
        _show_combo_indicator()
    
    # Miss feedback if no targets hit
    if not hit_any:
        AudioManager.play_sfx("miss")


func _show_combo_indicator() -> void:
    if combat_effects:
        combat_effects.spawn_damage_number(global_position + Vector2(0, -40), _combo_count, false, false)
        # Override the text for combo display
        var dmg_nodes = get_tree().get_nodes_in_group("damage_number")
        if dmg_nodes.size() > 0:
            var dmg_num = dmg_nodes[-1]
            if dmg_num.has_node("Label"):
                dmg_num.get_node("Label").text = "%d HIT COMBO!" % _combo_count
                dmg_num.get_node("Label").modulate = Color(0.8, 0.8, 1.0)


func _start_guard() -> void:
    if not is_guarding and mana >= 5:
        is_guarding = true
        guard_timer = 1.5
        mana -= 5
        mana_changed.emit(mana, max_mana)
        AudioManager.play_sfx("guard_start")
        # Guard visual: shield aura + flash
        if combat_effects:
            combat_effects.spawn_guard_aura(self, 0.5)
            combat_effects.spawn_guard_flash(self)


func take_damage(amount: int) -> void:
    if is_dead:
        return
    var final = int(amount * (0.5 if is_guarding else 1.0))
    final = max(1, final - defense / 2)  # Defense reduces damage
    health -= final
    health_changed.emit(health, max_health)
    AudioManager.play_sfx("player_hit")
    hit_flash.start(0.12)
    
    # Visual feedback
    if combat_effects:
        combat_effects.spawn_damage_number(global_position + Vector2(0, -16), final, false, false)
        if is_guarding:
            combat_effects.spawn_guard_flash(self)
        else:
            combat_effects.spawn_hit_flash(self, CombatEffects.HIT_FLASH_COLOR, 0.15)
        combat_effects.apply_screen_shake(2.5, 0.1)
        combat_effects.spawn_screen_flash(Color(0.8, 0.1, 0.1, 0.08), 0.08)
    
    if health <= 0:
        health = 0
        is_dead = true
        died.emit()
        GameManager.session_data["deaths"] += 1
        UIManager.show_notification("You have fallen...", "error")


func heal(amount: int) -> void:
    var healed = min(amount, max_health - health)
    health += healed
    health_changed.emit(health, max_health)
    
    # Visual feedback
    if combat_effects and healed > 0:
        combat_effects.spawn_damage_number(global_position + Vector2(0, -16), healed, false, true)
        combat_effects.spawn_heal_flash(self)
    
    AudioManager.play_sfx("heal")


func restore_mana(amount: int) -> void:
    var restored = min(amount, max_mana - mana)
    mana += restored
    mana_changed.emit(mana, max_mana)
    
    if combat_effects and restored > 0:
        combat_effects.spawn_damage_number(global_position + Vector2(0, -20), restored, false, true)


func gain_experience(amount: int) -> void:
    experience += amount
    var needed = level * 50
    while experience >= needed:
        experience -= needed
        level += 1
        max_health += 10
        health = max_health
        attack += 2
        defense += 1
        mana = max_mana
        leveled_up.emit(level)
        UIManager.show_notification("Level up! Now level %d" % level, "info")
        
        # Level up visual effect
        if combat_effects:
            combat_effects.spawn_death_effect(global_position, Color(1.0, 1.0, 0.5))
        
        needed = level * 50
    health_changed.emit(health, max_health)
    mana_changed.emit(mana, max_mana)


func add_item(item_id: String, qty: int = 1) -> void:
    for i in qty:
        inventory.append(item_id)
    GameManager.session_data["items_collected"] += qty


func _on_enemy_killed(enemy) -> void:
    GameManager.session_data["enemies_defeated"] += 1
    gain_experience(enemy.experience_value)
    gold += enemy.gold_value
    gold_changed.emit(gold)
    # Show kill reward
    if combat_effects:
        combat_effects.spawn_damage_number(enemy.global_position + Vector2(0, -30), enemy.experience_value, false, true)
    
    # Roll drops
    for drop in enemy.drops:
        if randf() < drop["chance"]:
            add_item(drop["item"])
            var item_name = GameData.get_item(drop["item"]).get("name", drop["item"])
            UIManager.show_notification("Found %s" % item_name, "info")
    # Quest progress
    _notify_quest_kill(enemy.monster_id)


func _notify_quest_kill(monster_id: String) -> void:
    for qid in active_quests.keys():
        var q = GameData.get_quest(qid)
        if q.is_empty():
            continue
        var obj = q["objectives"][0]
        if obj["target"] == monster_id:
            active_quests[qid]["current"] += 1
            var current: int = active_quests[qid]["current"]
            var target: int = obj["count"]
            UIManager.show_notification("Quest progress: %d/%d %s" % [current, target, q["name"]], "info")
            quest_progress_changed.emit(qid, current, target)
            if current >= target:
                _complete_quest(qid)


func accept_quest(quest_id: String) -> void:
    if active_quests.has(quest_id) or completed_quests.has(quest_id):
        return
    var q = GameData.get_quest(quest_id)
    if q.is_empty():
        return
    active_quests[quest_id] = {"current": 0}
    UIManager.show_notification("Quest accepted: %s" % q["name"], "info")
    GameManager.session_data["quests_completed"]  # count only on completion


func _complete_quest(quest_id: String) -> void:
    var q = GameData.get_quest(quest_id)
    if q.is_empty():
        return
    active_quests.erase(quest_id)
    completed_quests.append(quest_id)
    GameManager.session_data["quests_completed"] += 1
    var r = q["rewards"]
    gain_experience(int(r.get("experience", 0)))
    gold += int(r.get("gold", 0))
    gold_changed.emit(gold)
    for it in r.get("items", []):
        add_item(it)
    UIManager.show_notification("Quest complete: %s!" % q["name"], "info")
    SaveManager.save_game()


# ============================================================================
# SAVE / LOAD HELPERS
# ============================================================================

func get_save_data() -> Dictionary:
    """Serialize this player's state into a dictionary for SaveManager."""
    return {
        "level": level,
        "experience": experience,
        "position_x": global_position.x,
        "position_y": global_position.y,
        "stats": {
            "health": health,
            "max_health": max_health,
            "mana": mana,
            "max_mana": max_mana,
            "attack": attack,
            "defense": defense
        }
    }


func load_from_save_data(
    player_data: Dictionary,
    inventory_data: Dictionary,
    quest_data: Dictionary,
    equipment_data: Dictionary
) -> void:
    """Restore this player's state from SaveManager data."""
    if not player_data.is_empty():
        var stats = player_data.get("stats", {})
        level = player_data.get("level", level)
        experience = player_data.get("experience", experience)
        health = stats.get("health", health)
        max_health = stats.get("max_health", max_health)
        mana = stats.get("mana", mana)
        max_mana = stats.get("max_mana", max_mana)
        attack = stats.get("attack", attack)
        defense = stats.get("defense", defense)
        var px = player_data.get("position_x", 0.0)
        var py = player_data.get("position_y", 0.0)
        global_position = Vector2(px, py)

    if not inventory_data.is_empty():
        inventory = inventory_data.get("items", []).duplicate()
        gold = inventory_data.get("gold", 0)

    if not quest_data.is_empty():
        var raw_active = quest_data.get("active", {})
        active_quests.clear()
        for qid in raw_active.keys():
            active_quests[qid] = {"current": raw_active[qid].get("current", 0)}
        completed_quests = quest_data.get("completed", []).duplicate()

    if not equipment_data.is_empty():
        equipment = equipment_data.duplicate()

    is_dead = false
    health_changed.emit(health, max_health)
    mana_changed.emit(mana, max_mana)
    print("[Player] Loaded from save data: Lv.%d, HP %d/%d, Gold %d" % [level, health, max_health, gold])
