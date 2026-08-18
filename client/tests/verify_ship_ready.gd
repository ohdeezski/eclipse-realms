extends SceneTree
# verify_ship_ready.gd — proves main_menu + oakrest_village instantiate (New Game path).
var errors := 0
func _init():
	print("\n=== ECLIPSE REALMS - Ship-Ready Verification ===\n")
	_verify_main_menu()
	_verify_oakrest_transition()
	_report()
func _verify_main_menu():
	var path := "res://scenes/main_menu/main_menu.tscn"
	if not ResourceLoader.exists(path):
		_err("main_menu.tscn missing"); return
	var ps := load(path) as PackedScene
	if ps == null: _err("main_menu PackedScene load fail"); return
	var inst := ps.instantiate()
	if inst == null: _err("main_menu instantiate fail"); return
	if inst.has_node("MenuContainer"):
		var mc = inst.get_node("MenuContainer")
		for btn in ["NewGameButton","SettingsButton","CreditsButton","QuitButton"]:
			if mc.has_node(btn): print("  + MenuContainer/%s present" % btn)
			else: _err("MenuContainer missing %s" % btn)
		print("  + MainMenu: Background+MenuContainer+buttons OK")
	else:
		_err("MainMenu missing MenuContainer")
	if inst.has_node("Background"): print("  + Background present")
	else: _err("MainMenu missing Background")
	inst.queue_free()
func _verify_oakrest_transition():
	var path := "res://scenes/world/oakrest_village.tscn"
	if not ResourceLoader.exists(path):
		_err("oakrest_village.tscn missing"); return
	var ps := load(path) as PackedScene
	if ps == null: _err("oakrest PackedScene load fail"); return
	var inst := ps.instantiate()
	if inst == null: _err("oakrest instantiate fail"); return
	print("  + 'New Game' target oakrest_village.tscn instantiates (%s)" % inst.get_class())
	inst.queue_free()
func _err(msg):
	errors += 1
	print("  - " + msg)
func _report():
	var status = "PASSED" if errors == 0 else "FAILED"
	print("\n=== VERIFICATION %s (errors=%d) ===" % [status, errors])
	quit(0 if errors == 0 else 1)
