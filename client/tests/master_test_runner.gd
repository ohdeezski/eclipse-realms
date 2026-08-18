extends Node
# Master Test Runner - runs all validation tests
# Attach to a Node in a scene and run the scene

var _test_scripts = [
    "res://client/tests/test_runner.gd",
    "res://client/tests/comprehensive_validation.gd",
    "res://client/tests/test_avatar_catalog.gd",
]

var _current_test_index: int = 0
var _all_passed: bool = true
var _started: bool = false


func _ready() -> void:
    call_deferred("_run_next_test")


func _run_next_test() -> void:
    if _current_test_index >= _test_scripts.size():
        _finish()
        return

    var test_script_path = _test_scripts[_current_test_index]
    print("\n=== RUNNING TEST: %s ===" % test_script_path)

    # Load and instantiate the test script
    var script = load(test_script_path)
    if script == null:
        print("  FAILED: Could not load script")
        _all_passed = false
        _current_test_index += 1
        call_deferred("_run_next_test")
        return

    var test_instance = script.new()
    if test_instance == null:
        print("  FAILED: Could not instantiate script")
        _all_passed = false
        _current_test_index += 1
        call_deferred("_run_next_test")
        return

    # Add as child to run it
    add_child(test_instance)

    # Check for completion
    call_deferred("_check_test_completion", test_instance)


func _check_test_completion(test_instance) -> void:
    # Check if test is done
    if test_instance.has("_exit_code"):
        var exit_code = test_instance.get("_exit_code")
        if exit_code != 0:
            _all_passed = false
        print("  Test completed with exit code: %d" % exit_code)
    else:
        print("  Test running (async)...")

    _current_test_index += 1
    call_deferred("_run_next_test")


func _finish() -> void:
    print("\n=== MASTER TEST RUNNER RESULTS ===")
    if _all_passed:
        print("✅ ALL TESTS PASSED")
        get_tree().quit(0)
    else:
        print("❌ SOME TESTS FAILED")
        get_tree().quit(1)

