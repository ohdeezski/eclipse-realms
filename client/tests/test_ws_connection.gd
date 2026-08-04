extends Node
func _ready():
    var peer = WebSocketPeer.new()
    peer.connect_to_url("ws://localhost:9051/")
    # Poll a few times to establish connection
    for i in range(50):
        peer.poll()
        var state = peer.get_ready_state()
        if state == 0:  # OPEN
            # Try to receive data
            while peer.get_available_packet_count() > 0:
                var packet = peer.get_packet()
                var text = packet.get_string_from_utf8()
                print("Received:", text)
        elif state == 1:  # CLOSING
            print("Closing...")
            break
        elif state == 2:  # CLOSED
            print("Closed")
            break
    get_tree().quit()