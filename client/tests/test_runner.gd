extends Node
## Test runner scene script - attach to a test scene

@tool
@export var auto_run_test: bool = true
@export var test_host: String = "127.0.0.1"
@export var test_port: int = 9051

var test_instance = null

func _ready() -> void:
    if auto_run_test and not Engine.editor_hint:
        _run_test()

func _run_test() -> void:
    var test_script = preload("res://tests/test_websocket_connection.gd")
    test_instance = test_script.new()
    add_child(test_instance)
    test_instance.TEST_HOST = test_host
    test_instance.TEST_PORT = test_port

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        if test_instance:
            test_instance.queue_free()
        get_tree().quit()