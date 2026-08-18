extends SceneTree
# comprehensive_validation.gd — real core-system validation.
# Autoloads accessed via Engine.get_singleton() to compile in a tool script.
# Exits 1 on any failure.

var _started: bool = false
var _total: int = 0
var _passed: int = 0
var _exit_code: int = 1


func _init() -> void:
	# Direct `godot -s` runs do not invoke SceneTree._idle(). Defer until
	# autoloads have entered the tree, then exit deterministically.
	call_deferred("_run_once")


func _run_once() -> void:
	if _started:
		return
	_started = true
	_run()


func _singleton(name: String):
	return get_root().get_node_or_null(name)


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
		_exit_code = 0
	else:
		print("❌ COMPREHENSIVE VALIDATION FAILED (%d of %d)" % [_total - _passed, _total])
		_exit_code = 1
	call_deferred("_finish")


func _finish() -> void:
	quit(_exit_code)


func _test(name: String, ok: bool):
	_total += 1
	if ok:
		_passed += 1
		print("	 ✓ %s" % name)
	else:
		print("	 ✗ %s" % name)
