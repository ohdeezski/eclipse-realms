extends Node
func _ready():
    var peer = WebSocketPeer.new()
    print("CONNECTING:", peer.get_ready_state())
    peer.connect_to_url("ws://localhost:9051/")
    for i in range(10):
        peer.poll()
        print("State after poll", i, ":", peer.get_ready_state())
    get_tree().quit()