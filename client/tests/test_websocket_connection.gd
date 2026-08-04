extends Node
## Test script to verify WebSocket client-server connection
## Run this as an autoload or from a test scene

## Configuration
const TEST_HOST = "127.0.0.1"
const TEST_PORT = 9051
const TEST_TIMEOUT = 10.0

## State
var network_manager = null
var connection_timer: Timer = null
var test_passed = false
var test_failed = false
var failure_reason = ""

func _ready() -> void:
    print("[Test] WebSocket Connection Test Starting...")
    
    # Get NetworkManager instance - in Godot 4, autoloads are globals
    # The autoload name is "NetworkManager" as defined in project.godot
    # We can access it directly as a global variable
    if typeof(NetworkManager) != TYPE_NIL:
        network_manager = NetworkManager
        print("[Test] Found NetworkManager as global")
    else:
        push_error("[Test] NetworkManager not found in autoloads")
        _fail("NetworkManager not found")
        return
    
    # Set up test timeout
    connection_timer = Timer.new()
    add_child(connection_timer)
    connection_timer.one_shot = true
    connection_timer.wait_time = TEST_TIMEOUT
    connection_timer.timeout.connect(_on_test_timeout)
    
    # Listen for connection signals
    network_manager.connection_established.connect(_on_connection_established)
    network_manager.connection_failed.connect(_on_connection_failed)
    network_manager.connection_lost.connect(_on_connection_lost)
    
    # Start test by connecting to server
    _run_test()

func _run_test() -> void:
    print("[Test] Attempting to connect to ws://%s:%d" % [TEST_HOST, TEST_PORT])
    connection_timer.start()
    
    var success = network_manager.connect_to_server(TEST_HOST, TEST_PORT)
    if not success:
        _fail("Failed to initiate connection")

func _on_connection_established() -> void:
    print("[Test] Connection established successfully!")
    connection_timer.stop()
    
    # Send a test message (ping)
    var sent = network_manager.send_message(NetworkManager.MessageType.PING, {})
    if sent:
        print("[Test] PING sent successfully")
    else:
        push_warning("[Test] Failed to send PING")
    
    # Give server time to respond
    var timer = Timer.new()
    add_child(timer)
    timer.one_shot = true
    timer.wait_time = 2.0
    timer.timeout.connect(_check_ping_response)
    timer.start()

func _check_ping_response() -> void:
    var ping = network_manager.get_ping()
    if ping > 0:
        print("[Test] PONG received! Round-trip time: %.2f ms" % (ping * 1000))
        _pass()
    else:
        print("[Test] No PONG received yet, waiting...")
        var timer = Timer.new()
        add_child(timer)
        timer.one_shot = true
        timer.wait_time = 3.0
        timer.timeout.connect(_check_ping_response)
        timer.start()

func _on_connection_failed(error: String) -> void:
    connection_timer.stop()
    _fail("Connection failed: %s" % error)

func _on_connection_lost(reason: String) -> void:
    connection_timer.stop()
    if not test_passed:
        _fail("Connection lost: %s" % reason)

func _on_test_timeout() -> void:
    _fail("Connection timeout after %s seconds" % TEST_TIMEOUT)

func _pass() -> void:
    if test_passed or test_failed:
        return
    test_passed = true
    print("[Test] ✓ TEST PASSED: WebSocket client-server connection working!")
    _cleanup()

func _fail(reason: String) -> void:
    if test_passed or test_failed:
        return
    test_failed = true
    failure_reason = reason
    print("[Test] ✗ TEST FAILED: %s" % reason)
    _cleanup()

func _cleanup() -> void:
    if connection_timer:
        connection_timer.stop()
    
    if network_manager and network_manager.is_network_connected():
        network_manager.disconnect_from_server()
    
    # Print summary
    print("========================================")
    print("WebSocket Connection Test Summary")
    print("========================================")
    print("Host: %s" % TEST_HOST)
    print("Port: %d" % TEST_PORT)
    if test_passed:
        print("Result: PASSED")
    else:
        print("Result: FAILED")
        print("Reason: %s" % failure_reason)
    print("========================================")
    
    # Quit if running headless
    if OS.get_name() == "Server" or OS.get_cmdline_args().has("--test"):
        get_tree().quit(0 if test_passed else 1)