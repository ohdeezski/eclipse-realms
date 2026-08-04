extends Node
func _ready():
    var peer = WebSocketPeer.new()
    peer.connect_to_url("ws://localhost:9051/")
    # Poll a few times to establish connection
    for i in range(20):
        peer.poll()
        var state = peer.get_ready_state()
        if state == 0:  # OPEN
            print("Connected! State:", state)
            # Try to receive data
            if peer.get_available_packet_count() > 0:
                var packet = peer.get_packet()
                var text = packet.get_string_from_utf8()
                print("Received:", text)
            break
    get_tree().quit()