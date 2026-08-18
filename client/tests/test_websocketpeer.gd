extends Node
func _ready():
    var peer = WebSocketPeer.new()
    print("WebSocketPeer methods:")
    var methods = peer.get_method_list()
    for m in methods:
        print("  ", m.name)
    get_tree().quit()