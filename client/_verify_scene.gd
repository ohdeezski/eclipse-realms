extends Node
## Ad-hoc verification (re-run against current committed tree). Autoloads present.
const MOCK_PLAYER = preload("res://_verify_mock_player.gd")
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	print("VERIFY: UIManager=%s GameData=%s" % [UIManager != null, GameData != null])
	var scene = load("res://scenes/ui/equipment.tscn")
	var inst = scene.instantiate()
	get_tree().root.add_child(inst)
	print("VERIFY: equipment.tscn instantiated (compiled)")
	var mock = MOCK_PLAYER.new()
	if not inst.has_method("open_equipment"):
		push_error("VERIFY FAIL: open_equipment missing"); get_tree().quit(1); return
	inst.open_equipment(mock)
	var rows = inst.get_node_or_null("SlotList").get_child_count()
	print("VERIFY: rows=%d" % rows)
	if rows < 3: push_error("VERIFY FAIL rows<3"); get_tree().quit(1); return
	var stat = inst.get_node_or_null("StatPanel/StatLabel")
	if not (stat and stat.text.contains("Attack:")):
		push_error("VERIFY FAIL stats"); get_tree().quit(1); return
	print("VERIFY: stats=%s" % stat.text.replace("\n"," | "))
	# Now exercise inventory.gd the same way the game opens it
	var inv_scene = load("res://scenes/ui/inventory.tscn")
	var inv = inv_scene.instantiate()
	get_tree().root.add_child(inv)
	print("VERIFY: inventory.tscn instantiated (compiled, no set_input_blocked crash)")
	inv.open_inventory(mock)
	print("VERIFY: inventory open_inventory() OK, slots=%d" % inv.get_node_or_null("GridContainer").get_child_count())
	inv.close_inventory()
	print("VERIFY: inventory close OK")
	inst.close_equipment()
	print("VERIFY_PASS: equipment + inventory compile & run on current tree")
	get_tree().quit(0)
