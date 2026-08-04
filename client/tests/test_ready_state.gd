extends Node
func _ready():
    var peer = WebSocketPeer.new()
    print("WebSocketPeer ready state constants:")
    for k in dir(peer):
        if "ready" in k.lower() or "state" in k.lower():
            print("  ", k, ":", getattr(peer, k))
    get_tree().quit()