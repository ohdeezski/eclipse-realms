extends SceneTree
# validate_no_false_positives.gd — confirms the harness tests REAL state.
# Autoloads via Engine.get_singleton() to compile in a tool script. Exit 1 on fail.

var _started: bool = false
var _total: int = 0
var _passed: int = 0


func _idle(delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _singleton(name: String):
	if Engine.has_singleton(name):
		return Engine.get_singleton(name)
	return null


func _run():
	print("\n=== ECLIPSE REALMS - FALSE POSITIVE/TRUE NEGATIVE VALIDATION ===\n")

	var GameManager = _singleton("GameManager")
	var NetworkManager = _singleton("NetworkManager")

	var readme = FileAccess.open("res://README.md", FileAccess.READ)
	_test("README.md actually accessible", readme != null)
	if readme != null:
		readme.close()

	if GameManager != null:
		_test("GameManager.VERSION actually returns '0.1.0'", GameManager.VERSION == "0.1.0")
	else:
		_test("GameManager accessible", false)

	var proj = FileAccess.open("res://project.godot", FileAccess.READ)
	var proj_text: String = ""
	if proj != null:
		proj_text = proj.get_as_text()
		proj.close()
	_test("project.godot contains GameManager autoload", proj_text.find("GameManager=") >= 0)

	if NetworkManager != null:
		_test("NetworkManager.DEFAULT_HOST == 127.0.0.1", NetworkManager.DEFAULT_HOST == "127.0.0.1")
		_test("NetworkManager.DEFAULT_PORT == 9051", NetworkManager.DEFAULT_PORT == 9051)
	else:
		_test("NetworkManager accessible", false)

	_test("main_menu scene present",
		FileAccess.file_exists("res://scenes/main_menu/main_menu.tscn"))
	_test("character_creation scene present",
		FileAccess.file_exists("res://scenes/ui/character_creation.tscn"))

	print("\n=== RESULTS ===")
	print("Total: %d  Passed: %d  Success: %.0f%%" % [_total, _passed, float(_passed) * 100.0 / float(_total)])

	if _passed == _total:
		print("✅ NO FALSE POSITIVES — validation reflects real state")
		quit(0)
	else:
		print("❌ FALSE POSITIVES DETECTED — %d checks failed" % [_total - _passed])
		quit(1)


func _test(name: String, ok: bool):
	_total += 1
	if ok:
		_passed += 1
		print("  ✓ %s" % name)
	else:
		print("  ✗ %s" % name)
