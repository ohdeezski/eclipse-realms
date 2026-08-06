extends Node
func _ready():
    print("WebSocketClient exists: ", typeof(WebSocketClient) != TYPE_NIL)
    print("WebSocketPeer exists: ", typeof(WebSocketPeer) != TYPE_NIL)
    get_tree().quit()