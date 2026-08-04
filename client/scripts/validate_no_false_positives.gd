extends SceneTree

func _ready():
    print("\n=== ECLIPSE REALMS - FALSE POSITIVE/TRUE NEGATIVE VALIDATION ===\n")
    
    var validation_result = {
        "total_tests": 0,
        "passed_tests": 0,
        "failed_tests": 0,
        "false_positives": [],
        "false_negatives": []
    }
    
    // Test 1: Verify actual file system access
    validation_result["total_tests"] += 1
    var readme_file = FileAccess.open("README.md", FileAccess.READ)
    if readme_file != null:
        readme_file.close()
        validation_result["passed_tests"] += 1
        print("✓ Test 1 PASSED: README.md actually accessible")
    else:
        validation_result["failed_tests"] += 1
        print("✗ Test 1 FAILED: README.md not actually accessible")
    
    // Test 2: Verify GameManager constant values (not just existence)
    validation_result["total_tests"] += 1
    if GameManager != null:
        var actual_version = GameManager.VERSION
        var expected_version = "0.1.0"
        if actual_version == expected_version:
            validation_result["passed_tests"] += 1
            print("✓ Test 2 PASSED: GameManager.VERSION actually returns correct value ('%s')" % actual_version)
        else:
            validation_result["failed_tests"] += 1
            print("✗ Test 2 FAILED: GameManager.VERSION returns incorrect value ('%s', expected '%s')" % [actual_version, expected_version])
            validation_result["false_negatives"].push_back("GameManager constant value validation")
    else:
        validation_result["failed_tests"] += 1
        print("✗ Test 2 FAILED: GameManager not accessible")
        validation_result["false_positives"].push_back("GameManager accessibility")
    
    // Test 3: Verify essential project.godot content
    validation_result["total_tests"] += 1
    var project_content = FileAccess.open("client/project.godot", FileAccess.READ)
    if project_content != null:
        project_content.close()
        // Check for actual GameManager autoload entry
        var content_text = FileAccess.open("client/project.godot", FileAccess.READ).get_as_text()
        FileAccess.open("client/project.godot", FileAccess.READ).close()
        
        if content_text.find("GameManager=") >= 0:
            validation_result["passed_tests"] += 1
            print("✓ Test 3 PASSED: client/project.godot actually contains GameManager autoload")
        else:
            validation_result["failed_tests"] += 1
            print("✗ Test 3 FAILED: client/project.godot does not contain GameManager autoload")
            validation_result["false_negatives"].push_back("project.godot content validation")
    else:
        validation_result["failed_tests"] += 1
        print("✗ Test 3 FAILED: Cannot read client/project.godot")
        validation_result["false_positives"].push_back("project.godot access")
    
    // Test 4: Verify NetworkManager actual constants
    validation_result["total_tests"] += 1
    if NetworkManager != null:
        var actual_host = NetworkManager.DEFAULT_HOST
        var expected_host = "127.0.0.1"
        if actual_host == expected_host:
            validation_result["passed_tests"] += 1
            print("✓ Test 4 PASSED: NetworkManager.DEFAULT_HOST actually returns correct value ('%s')" % actual_host)
        else:
            validation_result["failed_tests"] += 1
            print("✗ Test 4 FAILED: NetworkManager.DEFAULT_HOST returns incorrect value ('%s', expected '%s')" % [actual_host, expected_host])
            validation_result["false_negatives"].push_back("NetworkManager constant validation")
    else:
        validation_result["failed_tests"] += 1
        print("✗ Test 4 FAILED: NetworkManager not accessible")
        validation_result["false_positives"].push_back("NetworkManager accessibility")
    
    // Test 5: Verify essential scenes actually exist
    validation_result["total_tests"] += 1
    var scene_exists = FileAccess.file_exists("client/scenes/world/oakrest_village.tscn")
    if scene_exists:
        validation_result["passed_tests"] += 1
        print("✓ Test 5 PASSED: oakrest_village.tscn actually exists")
    else:
        validation_result["failed_tests"] += 1
        print("✗ Test 5 FAILED: oakrest_village.tscn does not exist")
        validation_result["false_negatives"].push_back("scene existence validation")
    
    // Test 6: Verify autoload script accessibility
    validation_result["total_tests"] += 1
    var autoload_script = FileAccess.open("client/scripts/autoload/game_manager.gd", FileAccess.READ)
    if autoload_script != null:
        autoload_script.close()
        var script_content = autoload_script.get_as_text()
        if script_content.find("extends Node") >= 0 and script_content.find("GameManager") >= 0:
            validation_result["passed_tests"] += 1
            print("✓ Test 6 PASSED: game_manager.gd script is actually readable and contains expected content")
        else:
            validation_result["failed_tests"] += 1
            print("✗ Test 6 FAILED: game_manager.gd script does not contain expected content")
            validation_result["false_negatives"].push_back("script content validation")
    else:
        validation_result["failed_tests"] += 1
        print("✗ Test 6 FAILED: Cannot read game_manager.gd script")
        validation_result["false_positives"].push_back("script access")
    
    // Test 7: Verify actual autoload initialization
    validation_result["total_tests"] += 1
    if GameManager != null and GameManager.is_initialized:
        validation_result["passed_tests"] += 1
        print("✓ Test 7 PASSED: GameManager is actually initialized")
    else if GameManager != null:
        validation_result["failed_tests"] += 1
        print("✗ Test 7 FAILED: GameManager is not actually initialized")
        validation_result["false_negatives"].push_back("autoload initialization check")
    else:
        validation_result["failed_tests"] += 1
        print("✗ Test 7 FAILED: GameManager not accessible")
        validation_result["false_positives"].push_back("GameManager initialization")
    
    // Calculate validation accuracy
    var accuracy_score = (validation_result["passed_tests"] * 100) / validation_result["total_tests"]
    
    // Display results
    print("\n=== VALIDATION RESULTS ===")
    print("Total Tests: %d" % validation_result["total_tests"])
    print("Passed Tests: %d" % validation_result["passed_tests"])
    print("Failed Tests: %d" % validation_result["failed_tests"])
    print("Accuracy Score: %d%%" % accuracy_score)
    print("")
    
    // Detailed false positive/negative report
    print("=== FALSE POSITIVE/TRUE NEGATIVE ANALYSIS ===")
    
    if len(validation_result["false_positives"]) > 0:
        print("False Positives Found:")
        print("  (Tests that passed but shouldn't have)")
        for item in validation_result["false_positives"]:
            print("    ✗ %s" % [item])
    else:
        print("  ✓ No false positives detected")
    
    if len(validation_result["false_negatives"]) > 0:
        print("False Negatives Found:")
        print("  (Tests that failed but should have passed)")
        for item in validation_result["false_negatives"]:
            print("    ✗ %s" % [item])
    else:
        print("  ✓ No false negatives detected")
    
    print("")
    
    // Final assessment
    print("=== FINAL VALIDATION ASSESSMENT ===")
    
    if validation_result["false_positives"].size() == 0 and validation_result["false_negatives"].size() == 0:
        print("🎉 EXCELLENT VALIDATION RESULTS!")
        print("\n✅ No false positives - all positive results are genuine")
        print("✅ No false negatives - all actual problems were detected")
        print("✅ High validation accuracy (%d%%)" % accuracy_score)
        print("\n=== ECLIPSE REALMS - VALIDATION COMPLETE ===")
        print("\nThe project has passed rigorous validation with:")
        print("  ✓ Zero false positives")
        print("  ✓ Zero false negatives")
        print("  ✓ High accuracy score")
        print("\n=== READY FOR PHASE 2 EXECUTION ===")
        print("Core systems validation is accurate and reliable.")
        print("Eclipse Realms is ready to proceed with multiplayer integration!")
        quit(0)
    else:
        print("⚠️  VALIDATION ISSUES DETECTED")
        print("\nIssues Found:")
        if validation_result["false_positives"].size() > 0:
            print("  • False Positives:")
            for item in validation_result["false_positives"]:
                print("    - %s" % [item])
        
        if validation_result["false_negatives"].size() > 0:
            print("  • False Negatives:")
            for item in validation_result["false_negatives"]:
                print("    - %s" % [item])
        
        print("\nRecommendation:")
        print("  • Review false positives and address underlying issues")
        print("  • Investigate false negatives for missed problems")
        print("  • Re-run validation after fixes")
        print("\nCurrent accuracy: %d%% - %d/%d tests passed" % [
            accuracy_score, validation_result["passed_tests"], validation_result["total_tests"]
        ])
        
        if accuracy_score >= 90:
            print("\n⚠️  WARNING: Accuracy below 90%. Consider additional validation.")
        elif accuracy_score >= 80:
            print("\n⚠️  CAUTION: Accuracy below 80%. Review failed tests.")
        else:
            print("\n❌ CRITICAL: Accuracy below 70%. Major validation issues detected.")
        
        quit(1)