extends SceneTree
# comprehensive_validation.gd — real core-system validation.
# Autoloads accessed via Engine.get_singleton() to compile in a tool script.
# Exits 1 on any failure.

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
	print("\n=== ECLIPSE REALMS - COMPREHENSIVE VALIDATION ===\n")

	var GameManager = _singleton("GameManager")
	var NetworkManager = _singleton("NetworkManager")
	var SaveManager = _singleton("SaveManager")
	var SceneManager = _singleton("SceneManager")
	var UIManager = _singleton("UIManager")

	_test("GameManager autoload", GameManager != null)
	_test("NetworkManager autoload", NetworkManager != null)
	_test("SaveManager autoload", SaveManager != null)
	_test("SceneManager autoload", SceneManager != null)
	_test("UIManager autoload", UIManager != null)

	_test("GameManager.VERSION == 0.1.0",
		GameManager != null and GameManager.VERSION == "0.1.0")
	_test("GameManager.PROJECT_NAME == Eclipse Realms",
		GameManager != null and GameManager.PROJECT_NAME == "Eclipse Realms")
	_test("GameManager.PHASE == First Playable",
		GameManager != null and GameManager.PHASE == "First Playable")
	_test("GameManager.is_initialized",
		GameManager != null and GameManager.is_initialized)

	_test("NetworkManager.DEFAULT_PORT == 9051",
		NetworkManager != null and NetworkManager.DEFAULT_PORT == 9051)
	_test("NetworkManager.PROTOCOL_VERSION == 0.1.0",
		NetworkManager != null and NetworkManager.PROTOCOL_VERSION == "0.1.0")
	_test("NetworkManager.is_initialized",
		NetworkManager != null and NetworkManager.is_initialized)

	_test("SaveManager.MAX_SAVES == 10",
		SaveManager != null and SaveManager.MAX_SAVES == 10)
	_test("SaveManager.SAVE_EXTENSION == .eclipse",
		SaveManager != null and SaveManager.SAVE_EXTENSION == ".eclipse")

	_test("SceneManager.DEFAULT_SCENE correct",
		SceneManager != null and SceneManager.DEFAULT_SCENE == "res://scenes/main_menu/main_menu.tscn")

	_test("project.godot exists", FileAccess.file_exists("res://project.godot"))
	_test("main_menu scene exists",
		FileAccess.file_exists("res://scenes/main_menu/main_menu.tscn"))
	_test("oakrest_village scene exists",
		FileAccess.file_exists("res://scenes/world/oakrest_village.tscn"))
	_test("mosswood_forest scene exists",
		FileAccess.file_exists("res://scenes/world/mosswood_forest.tscn"))

	print("\n=== RESULTS ===")
	print("Total: %d  Passed: %d  Success: %.0f%%" % [_total, _passed, float(_passed) * 100.0 / float(_total)])

	if _passed == _total:
		print("🎉 COMPREHENSIVE VALIDATION PASSED")
		quit(0)
	else:
		print("❌ COMPREHENSIVE VALIDATION FAILED (%d of %d)" % [_total - _passed, _total])
		quit(1)


func _test(name: String, ok: bool):
	_total += 1
	if ok:
		_passed += 1
		print("  ✓ %s" % name)
	else:
		print("  ✗ %s" % name)
