extends Node

## TestRunner.gd - Executes all avatar system tests in the project environment.

func _ready() -> void:
    print("=== Starting Avatar System Test Suite ===")
    
    var catalog_passed = _run_avatar_catalog_test()
    var resolver_passed = _run_visual_resolver_test()
    
    if catalog_passed and resolver_passed:
        print("=== ALL TESTS PASSED ===")
        get_tree().quit(0)
    else:
        print("=== TESTS FAILED ===")
        get_tree().quit(1)

func _run_avatar_catalog_test() -> bool:
    print("Running Avatar Catalog Test...")
    # Instantiate or call logic from the existing test_avatar_catalog
    # Directly running logic to ensure visibility in this context
    var visuals = GameData.get_all_avatar_visuals()
    var passed = true
    for visual_id in visuals:
        var visual = visuals[visual_id]
        var world = visual.get("world", {})
        # Simple existence check
        if not world.has("idle"):
            print("  ✗ Visual %s missing idle" % visual_id)
            passed = false
    if passed: print("  ✓ Avatar Catalog OK")
    return passed

func _run_visual_resolver_test() -> bool:
    print("Running Visual Resolver Test...")
    # Verify mappings
    var resolver = get_node("/root/VisualResolver") # Assuming added as autoload
    if not resolver:
        print("  ✗ VisualResolver not found in root")
        return false
    
    # Check prototype assets
    var test_assets = [
        {"race": "human", "gender": "male", "job": "adept", "type": "sprite"},
        {"race": "elder_mira", "gender": "female", "job": "guide", "type": "portrait"}
    ]
    
    var passed = true
    for test in test_assets:
        var path = resolver.get_asset(test.race, test.gender, test.job, test.type)
        if path.is_empty():
            print("  ✗ Failed to resolve: %s/%s/%s" % [test.race, test.gender, test.job])
            passed = false
    
    if passed: print("  ✓ Visual Resolver OK")
    return passed
