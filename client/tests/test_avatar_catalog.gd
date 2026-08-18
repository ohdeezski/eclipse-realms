extends SceneTree
## TestAvatarCatalog.gd - Validates all assets referenced in avatar_visuals.json exist.
## Run with: godot --headless --script res://client/tests/test_avatar_catalog.gd

var _failed: bool = false
var _total: int = 0
var _passed: int = 0
var _started: bool = false


func _init() -> void:
    call_deferred("_run_once")


func _run_once() -> void:
    if _started:
        return
    _started = true
    _run()


func _singleton(name: String):
    return get_root().get_node_or_null(name)


func _run() -> void:
    print("\n=== ECLIPSE REALMS - AVATAR CATALOG VALIDATION ===\n")

    var GameData = _singleton("GameData")
    _test("GameData autoload available", GameData != null)

    if GameData == null:
        _finish()
        return

    _test("GameData initialized", GameData.is_initialized)

    if not GameData.is_initialized:
        _finish()
        return

    # Test get_all_avatar_visuals method exists
    _test("GameData has get_all_avatar_visuals method", GameData.has_method("get_all_avatar_visuals"))

    if not GameData.has_method("get_all_avatar_visuals"):
        _finish()
        return

    var visuals = GameData.get_all_avatar_visuals()
    _test("Avatar visuals catalog loaded", visuals.size() > 0)

    if visuals.empty():
        print("  No avatar visuals found in catalog")
        _finish()
        return

    print("  Found " + str(visuals.size()) + " avatar visuals")

    var all_passed = true

    for visual_id in visuals:
        var visual = visuals[visual_id]
        var world = visual.get("world", {})
        var portraits = visual.get("portraits", {})

        # Check world textures
        if world.has("idle"):
            var idle_path = "res://%s" % world.get("idle", "")
            _test("Avatar visual " + visual_id + " has world idle texture", ResourceLoader.exists(idle_path))
            if not ResourceLoader.exists(idle_path):
                push_error("Avatar visual %s missing world idle: %s" % [visual_id, idle_path])
                all_passed = false

        if world.has("walk"):
            var walk_path = "res://%s" % world.get("walk", "")
            _test("Avatar visual " + visual_id + " has world walk texture", ResourceLoader.exists(walk_path))
            if not ResourceLoader.exists(walk_path):
                push_error("Avatar visual %s missing world walk: %s" % [visual_id, walk_path])
                all_passed = false

        # Check portrait textures
        for p_key in portraits:
            var p_path = "res://%s" % portraits[p_key]
            _test("Avatar visual " + visual_id + " has portrait '" + p_key + "'", ResourceLoader.exists(p_path))
            if not ResourceLoader.exists(p_path):
                push_error("Avatar visual %s missing portrait '%s': %s" % [visual_id, p_key, p_path])
                all_passed = false

    if all_passed:
        print("\n✅ ALL AVATAR ASSETS VALIDATED SUCCESSFULLY")
    else:
        print("\n❌ SOME AVATAR ASSETS ARE MISSING")

    _finish()


func _test(name: String, ok: bool):
    _total += 1
    if ok:
        _passed += 1
        print("	 ✓ " + name)
    else:
        print("	 ✗ " + name)
        _failed = true


func _finish() -> void:
    print("\n=== RESULTS ===")
    print("Total: %d  Passed: %d" % [_total, _passed])
    if _passed == _total and !_failed:
        print("🎉 AVATAR CATALOG VALIDATION PASSED")
        quit(0)
    else:
        print("❌ AVATAR CATALOG VALIDATION FAILED")
        quit(1)
