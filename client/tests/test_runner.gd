extends SceneTree
# test_runner.gd — CI gate that runs in `godot --headless --script` mode.
# Asserts on the REAL project.godot file content (read from disk), not on
# ProjectSettings quirks in --script mode. Quits 0 on pass, 1 on failure.
# Autoload/constant assertions live in comprehensive_validation.gd (run in-editor).

var _failed: bool = false


func _init():
	print("\n=== ECLIPSE REALMS - test_runner (project.godot gate) ===")

	var f = FileAccess.open("res://project.godot", FileAccess.READ)
	var text: String = ""
	if f != null:
		text = f.get_as_text()
		f.close()
	else:
		_check(false, "project.godot readable")
		_fail()

	_check(text.find("config/name=\"Eclipse Realms\"") >= 0, "project name == Eclipse Realms")
	_check(text.find("\"4.4\"") >= 0, "config/features includes 4.4 (not 4.2)")
	_check(text.find("res://scenes/main_menu/main_menu.tscn") >= 0, "main_scene set to main_menu")

	if not _failed:
		print("✅ test_runner: PROJECT CONFIG GATE PASSED")
		quit(0)
	else:
		print("❌ test_runner: PROJECT CONFIG GATE FAILED")
		quit(1)


func _check(cond: bool, msg: String):
	if cond:
		print("  ✓ " + msg)
	else:
		print("  ✗ " + msg)
		_failed = true


func _fail():
	pass
