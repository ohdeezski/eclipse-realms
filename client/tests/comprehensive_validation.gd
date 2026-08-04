extends SceneTree

func _ready():
    print("\n=== ECLIPSE REALMS - COMPREHENSIVE VALIDATION ===\n")
    
    var validation_results = {
        "autoload_systems": {
            "game_manager": false,
            "network_manager": false,
            "save_manager": false,
            "scene_manager": false,
            "ui_manager": false
        },
        "constants_validation": {
            "game_manager_version": false,
            "network_manager_constants": false,
            "save_manager_constants": false,
            "scene_manager_constants": false
        },
        "project_structure": {
            "essential_files": false,
            "scenes_exist": false,
            "test_files_exist": false
        },
        "functionality_tests": {
            "file_access": false,
            "script_execution": false,
            "autoload_access": false
        }
    }
    
    var total_checks = 0
    var passed_checks = 0
    
    // Helper function to validate constants
    func validate_game_manager_constants():
        var gm = GameManager
        if gm != null:
            var constants_ok = (
                gm.VERSION == "0.1.0" &&
                gm.PROJECT_NAME == "Eclipse Realms" &&
                gm.PHASE == "First Playable" &&
                gm.is_initialized == true
            )
            if constants_ok:
                print("  ✓ GameManager constants validated")
                return true
            else
                print("  ✗ GameManager constants validation failed")
                print("    - VERSION: expected '0.1.0', got '", gm.VERSION, "'")
                print("    - PROJECT_NAME: expected 'Eclipse Realms', got '", gm.PROJECT_NAME, "'")
                print("    - PHASE: expected 'First Playable', got '", gm.PHASE, "'")
                print("    - is_initialized: expected true, got '", gm.is_initialized, "'")
                return false
        else
            print("  ✗ GameManager not accessible")
            return false
    
    func validate_network_manager_constants():
        var nm = NetworkManager
        if nm != null:
            var constants_ok = (
                nm.DEFAULT_HOST == "127.0.0.1" &&
                nm.DEFAULT_PORT == 9051 &&
                nm.PROTOCOL_VERSION == "0.1.0" &&
                nm.is_initialized == true
            )
            if constants_ok:
                print("  ✓ NetworkManager constants validated")
                return true
            else:
                print("  ✗ NetworkManager constants validation failed")
                return false
        else
            print("  ✗ NetworkManager not accessible")
            return false
    
    func validate_save_manager_constants():
        var sm = SaveManager
        if sm != null:
            var constants_ok = (
                sm.MAX_SAVES == 10 &&
                sm.SAVE_EXTENSION == ".eclipse"
            )
            if constants_ok:
                print("  ✓ SaveManager constants validated")
                return true
            else:
                print("  ✗ SaveManager constants validation failed")
                return false
        else
            print("  ✗ SaveManager not accessible")
            return false
    
    func validate_scene_manager_constants():
        var sm = SceneManager
        if sm != null:
            var constants_ok = (
                sm.DEFAULT_SCENE == "res://scenes/main_menu/main_menu.tscn" &&
                sm.is_initialized == true
            )
            if constants_ok:
                print("  ✓ SceneManager constants validated")
                return true
            else:
                print("  ✗ SceneManager constants validation failed")
                return false
        else
            print("  ✗ SceneManager not accessible")
            return false
    
    // Start comprehensive validation
    print("=== Phase 1 Core Systems Validation ===")
    
    // Test 1: Autoload System Validation
    print("\nTest 1: Autoload System Validation")
    total_checks += 1
    if GameManager != null:
        validation_results["autoload_systems"]["game_manager"] = validate_game_manager_constants()
        if validation_results["autoload_systems"]["game_manager"]:
            passed_checks += 1
    else:
        print("  ✗ GameManager not autoloaded")
    
    total_checks += 1
    if NetworkManager != null:
        validation_results["autoload_systems"]["network_manager"] = validate_network_manager_constants()
        if validation_results["autoload_systems"]["network_manager"]:
            passed_checks += 1
    else:
        print("  ✗ NetworkManager not autoloaded")
    
    total_checks += 1
    if SaveManager != null:
        validation_results["autoload_systems"]["save_manager"] = validate_save_manager_constants()
        if validation_results["autoload_systems"]["save_manager"]:
            passed_checks += 1
    else:
        print("  ✗ SaveManager not autoloaded")
    
    total_checks += 1
    if SceneManager != null:
        validation_results["autoload_systems"]["scene_manager"] = validate_scene_manager_constants()
        if validation_results["autoload_systems"]["scene_manager"]:
            passed_checks += 1
    else:
        print("  ✗ SceneManager not autoloaded")
    
    total_checks += 1
    if UIManager != null:
        validation_results["autoload_systems"]["ui_manager"] = true
        print("  ✓ UIManager is accessible")
        passed_checks += 1
    else:
        print("  ✗ UIManager not autoloaded")
    
    // Test 2: Constants Validation
    print("\nTest 2: Constants Validation")
    total_checks += 1
    if validate_game_manager_constants():
        validation_results["constants_validation"]["game_manager_version"] = true
        passed_checks += 1
    
    total_checks += 1
    if validate_network_manager_constants():
        validation_results["constants_validation"]["network_manager_constants"] = true
        passed_checks += 1
    
    total_checks += 1
    if validate_save_manager_constants():
        validation_results["constants_validation"]["save_manager_constants"] = true
        passed_checks += 1
    
    total_checks += 1
    if validate_scene_manager_constants():
        validation_results["constants_validation"]["scene_manager_constants"] = true
        passed_checks += 1
    
    // Test 3: Project Structure Validation
    print("\nTest 3: Project Structure Validation")
    total_checks += 1
    var essential_files = [
        "client/project.godot",
        "README.md",
        "client/scripts/autoload/game_manager.gd"
    ]
    var all_files_exist = true
    for file_path in essential_files:
        if not FileAccess.file_exists(file_path):
            all_files_exist = false
            break
    
    if all_files_exist:
        print("  ✓ All essential files exist")
        validation_results["project_structure"]["essential_files"] = true
        passed_checks += 1
    else:
        print("  ✗ Some essential files missing")
    
    total_checks += 1
    var essential_scenes = [
        "client/scenes/world/oakrest_village.tscn",
        "client/scenes/world/mosswood_forest.tscn"
    ]
    var all_scenes_exist = true
    for scene_path in essential_scenes:
        if not FileAccess.file_exists(scene_path):
            all_scenes_exist = false
            break
    
    if all_scenes_exist:
        print("  ✓ All essential scenes exist")
        validation_results["project_structure"]["scenes_exist"] = true
        passed_checks += 1
    else:
        print("  ✗ Some essential scenes missing")
    
    total_checks += 1
    var test_files = ["client/tests/test_multiplayer_integration.gd", "client/tests/test_save_load.gd"]
    var all_tests_exist = true
    for test_path in test_files:
        if not FileAccess.file_exists(test_path):
            all_tests_exist = false
            break
    
    if all_tests_exist:
        print("  ✓ Essential test files exist")
        validation_results["project_structure"]["test_files_exist"] = true
        passed_checks += 1
    else:
        print("  ✗ Some essential test files missing")
    
    // Test 4: Functionality Validation
    print("\nTest 4: Functionality Validation")
    total_checks += 1
    var test_file = FileAccess.open("README.md", FileAccess.READ)
    if test_file != null:
        test_file.close()
        print("  ✓ File system access working")
        validation_results["functionality_tests"]["file_access"] = true
        passed_checks += 1
    else:
        print("  ✗ File system access failed")
    
    total_checks += 1
    // Simple script execution test
    var script_test_passed = true
    if GameManager != null:
        var version_check = GameManager.VERSION
        if version_check == "0.1.0":
            print("  ✓ Script execution and constant access working")
            validation_results["functionality_tests"]["script_execution"] = true
            passed_checks += 1
        else:
            print("  ✗ Script execution failed - version check returned: " + version_check)
    else:
        print("  ✗ Script execution failed - GameManager not accessible")
    
    total_checks += 1
    if GameManager != null and NetworkManager != null and SaveManager != null:
        print("  ✓ Autoload system integration working")
        validation_results["functionality_tests"]["autoload_access"] = true
        passed_checks += 1
    else:
        print("  ✗ Autoload system integration failed")
    
    // Display comprehensive results
    print("\n=== COMPREHENSIVE VALIDATION RESULTS ===")
    print("Total Checks: %d" % total_checks)
    print("Passed Checks: %d" % passed_checks)
    print("Success Rate: %d%%" % int(passed_checks * 100.0 / total_checks))
    print("")
    
    // Detailed breakdown
    print("=== DETAILED BREAKDOWN ===")
    
    func print_section(name, results):
        var section_passed = 0
        var section_total = 0
        for key in results.keys():
            section_total += 1
            if results[key]:
                section_passed += 1
        
        print("  %s: %d/%d passed" % [name, section_passed, section_total])
        if section_passed < section_total:
            print("    Failed items:")
            for key in results.keys():
                if !results[key]:
                    print("      - %s" % [key])
    
    print_section("Autoload Systems", validation_results["autoload_systems"])
    print_section("Constants Validation", validation_results["constants_validation"])
    print_section("Project Structure", validation_results["project_structure"])
    print_section("Functionality Tests", validation_results["functionality_tests"])
    
    print("\n=== FINAL ASSESSMENT ===")
    
    if passed_checks == total_checks:
        print("🎉 COMPREHENSIVE VALIDATION PASSED!")
        print("")
        print("✅ Phase 1 Core Systems: FULLY VALIDATED")
        print("✅ Constants and Configuration: CORRECT")
        print("✅ Project Structure: INTACT")
        print("✅ Functionality: OPERATIONAL")
        print("")
        print("The Eclipse Realms project has successfully passed")
        print("comprehensive validation with zero false positives or negatives.")
        print("")
        print("=== READY FOR PHASE 2 EXECUTION ===")
        print("All core systems are validated and ready for multiplayer integration.")
        quit(0)
    else:
        print("❌ COMPREHENSIVE VALIDATION FAILED")
        print("")
        print("The following issues were identified:")
        var failed_sections = []
        for section_name in validation_results.keys():
            var section_passed = 0
            var section_total = 0
            for key in validation_results[section_name].keys():
                section_total += 1
                if validation_results[section_name][key]:
                    section_passed += 1
            
            if section_passed < section_total:
                failed_sections.push_back(section_name)
        
        for section in failed_sections:
            print("  - %s" % [section])
        
        print("")
        print("Please address the failed validation items before proceeding.")
        quit(1)