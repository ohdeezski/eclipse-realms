extends Control
## HUD.gd - Heads-up display for Eclipse Realms
## Health bar, mana bar, level display, gold counter, minimap placeholder.
## Connects to Player signals for real-time updates.

class_name HUD

# --- Panel nodes (top-left cluster) ---
@onready var panel: Panel = $Panel
@onready var health_bar: ProgressBar = $Panel/HealthBar
@onready var mana_bar: ProgressBar = $Panel/ManaBar
@onready var hp_label: Label = $Panel/HPLabel
@onready var mp_label: Label = $Panel/MPLabel
@onready var gold_label: Label = $Panel/GoldLabel
@onready var level_label: Label = $Panel/LevelLabel
@onready var exp_label: Label = $Panel/ExpLabel
@onready var quest_label: Label = $Panel/QuestLabel

# --- Minimap placeholder (top-right) ---
@onready var minimap_panel: Panel = $MinimapPanel
@onready var minimap_label: Label = $MinimapPanel/MinimapLabel

var player_ref: Node = null


func _ready() -> void:
    add_to_group("hud")
    # Style the bars on first frame so they look right even without a theme
    call_deferred("_init_bar_styles")

    # Find player once spawned
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        _bind(players[0])
    else:
        get_tree().process_frame.connect(_try_bind, CONNECT_ONE_SHOT)


# ---------------------------------------------------------------------------
# Binding
# ---------------------------------------------------------------------------

func _try_bind() -> void:
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        _bind(players[0])


func _bind(player: Node) -> void:
    player_ref = player
    # Connect all player signals
    player.health_changed.connect(_on_health_changed)
    player.mana_changed.connect(_on_mana_changed)
    player.gold_changed.connect(_on_gold_changed)
    player.leveled_up.connect(_on_leveled_up)
    # Initial refresh
    _on_health_changed(player.health, player.max_health)
    _on_mana_changed(player.mana, player.max_mana)
    _on_gold_changed(player.gold)
    _on_leveled_up(player.level)
    _refresh_quest()


# ---------------------------------------------------------------------------
# Bar styling
# ---------------------------------------------------------------------------

func _init_bar_styles() -> void:
    # Health bar style
    var hp_style = StyleBoxFlat.new()
    hp_style.bg_color = Color(0.7, 0.15, 0.15)
    hp_style.corner_radius_top_left = 3
    hp_style.corner_radius_top_right = 3
    hp_style.corner_radius_bottom_left = 3
    hp_style.corner_radius_bottom_right = 3
    hp_style.content_margin_left = 2
    health_bar.add_theme_stylebox_override("background", hp_style)

    var hp_fill = StyleBoxFlat.new()
    hp_fill.bg_color = Color(0.2, 0.8, 0.2)
    hp_fill.corner_radius_top_left = 3
    hp_fill.corner_radius_top_right = 3
    hp_fill.corner_radius_bottom_left = 3
    hp_fill.corner_radius_bottom_right = 3
    health_bar.add_theme_stylebox_override("fill", hp_fill)
    health_bar.show_percentage = false

    # Mana bar style
    var mp_style = StyleBoxFlat.new()
    mp_style.bg_color = Color(0.1, 0.1, 0.3)
    mp_style.corner_radius_top_left = 3
    mp_style.corner_radius_top_right = 3
    mp_style.corner_radius_bottom_left = 3
    mp_style.corner_radius_bottom_right = 3
    mp_style.content_margin_left = 2
    mana_bar.add_theme_stylebox_override("background", mp_style)

    var mp_fill = StyleBoxFlat.new()
    mp_fill.bg_color = Color(0.2, 0.4, 0.95)
    mp_fill.corner_radius_top_left = 3
    mp_fill.corner_radius_top_right = 3
    mp_fill.corner_radius_bottom_left = 3
    mp_fill.corner_radius_bottom_right = 3
    mana_bar.add_theme_stylebox_override("fill", mp_fill)
    mana_bar.show_percentage = false


# ---------------------------------------------------------------------------
# Signal handlers — Player signals
# ---------------------------------------------------------------------------

func _on_health_changed(current: int, maximum: int) -> void:
    health_bar.max_value = maximum
    health_bar.value = current
    hp_label.text = "HP  %d / %d" % [current, maximum]
    # Colour-code the bar based on percentage
    _update_health_bar_color(current, maximum)


func _on_mana_changed(current: int, maximum: int) -> void:
    mana_bar.max_value = maximum
    mana_bar.value = current
    mp_label.text = "MP  %d / %d" % [current, maximum]


func _on_gold_changed(amount: int) -> void:
    gold_label.text = "Gold: %d" % amount


func _on_leveled_up(level: int) -> void:
    level_label.text = "Lv.%d" % level
    _refresh_exp_display()


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _update_health_bar_color(current: int, maximum: int) -> void:
    if maximum <= 0:
        return
    var pct: float = float(current) / float(maximum)
    var fill = health_bar.get_theme_stylebox("fill") as StyleBoxFlat
    if fill == null:
        return
    if pct > 0.5:
        fill.bg_color = Color(0.2, 0.8, 0.2)   # green
    elif pct > 0.25:
        fill.bg_color = Color(0.9, 0.75, 0.1)   # yellow
    else:
        fill.bg_color = Color(0.85, 0.15, 0.15)  # red


func _refresh_exp_display() -> void:
    if not player_ref:
        return
    var needed: int = player_ref.level * 50
    if exp_label:
        exp_label.text = "Exp: %d / %d" % [player_ref.experience, needed]


func _refresh_quest() -> void:
    if not player_ref:
        return
    if player_ref.active_quests.size() > 0:
        var qid = player_ref.active_quests.keys()[0]
        var q = GameData.get_quest(qid)
        var cur = player_ref.active_quests[qid]["current"]
        var tgt = q["objectives"][0]["count"]
        quest_label.text = "Quest: %s (%d/%d)" % [q["name"], cur, tgt]
    else:
        quest_label.text = "Quest: -"
