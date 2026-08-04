extends Node
func _ready():
    var peer = WebSocketPeer.new()
    print("WebSocketPeer signals:")
    var signals = peer.get_signal_list()
    for s in signals:
        print("  ", s.name)
    get_tree().quit()