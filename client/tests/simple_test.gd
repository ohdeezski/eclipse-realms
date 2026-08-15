extends Node
## Simple Test for Eclipse Realms Multiplayer Integration
## Run with: godot --headless -s tests/simple_test.gd

var test_results = {"passed": 0, "failed": 0}

func _init():
    print("\n========== Eclipse Realms - Simple Test =========\n")
    
    # Test 1: NetworkManager is autoloaded
    var network_manager = NetworkManager
    if network_manager != null:
        _assert(true, "NetworkManager should be autoloaded")
        _assert(network_manager.is_initialized, "NetworkManager should be initialized")
        
        # Test 3: NetworkManager constants exist
        _assert(network_manager.DEFAULT_HOST != null, "NetworkManager should have DEFAULT_HOST")
        _assert(network_manager.DEFAULT_PORT > 0, "NetworkManager should have valid DEFAULT_PORT")
        _assert(network_manager.PROTOCOL_VERSION != null, "NetworkManager should have PROTOCOL_VERSION")
    else:
        _assert(false, "NetworkManager should be autoloaded")
    
    # Test 4: GameManager is autoloaded
    var game_manager = GameManager
    if game_manager != null:
        _assert(true, "GameManager should be autoloaded")
        _assert(game_manager.is_initialized, "GameManager should be initialized")
        
        # Test 6: GameManager constants exist
        _assert(game_manager.PROJECT_NAME != null, "GameManager should have PROJECT_NAME")
        _assert(game_manager.VERSION != null, "GameManager should have VERSION")
        _assert(game_manager.PHASE != null, "GameManager should have PHASE")
    else:
        _assert(false, "GameManager should be autoloaded")
    
    # Test 7: SaveManager is autoloaded
    var save_manager = SaveManager
    if save_manager != null:
        _assert(true, "SaveManager should be autoloaded")
    else:
        _assert(false, "SaveManager should be autoloaded")
    
    # Test 8: AudioManager is autoloaded
    var audio_manager = AudioManager
    if audio_manager != null:
        _assert(true, "AudioManager should be autoloaded")
    else:
        _assert(false, "AudioManager should be autoloaded")
    
    # Test 9: SceneManager is autoloaded
    var scene_manager = SceneManager
    if scene_manager != null:
        _assert(true, "SceneManager should be autoloaded")
    else:
        _assert(false, "SceneManager should be autoloaded")
    
    # Test 10: UIManager is autoloaded
    var ui_manager = UIManager
    if ui_manager != null:
        _assert(true, "UIManager should be autoloaded")
    else:
        _assert(false, "UIManager should be autoloaded")
    
    print("\n========== Test Results: %d passed, %d failed =========\n" % [test_results["passed"], test_results["failed"]])
    if test_results["failed"] > 0:
        print("TESTS FAILED")
        get_tree().quit(1)
    else:
        print("ALL TESTS PASSED")
        get_tree().quit(0)

func _assert(condition: bool, description: String) -> void:
    if condition:
        test_results["passed"] += 1
        print("  [PASS] %s" % description)
    else:
        test_results["failed"] += 1
        print("  [FAIL] %s" % description)