extends Node
## NetworkManager.gd - WebSocket Network Communication System
## Handles client-server communication for multiplayer features via WebSocket
## Load order: Sixth

## Signals
signal connection_established
signal connection_lost(reason: String)
signal connection_failed(error: String)
signal server_message_received(message: Dictionary)
signal player_connected(player_id: int, player_data: Dictionary)
signal player_disconnected(player_id: int)
signal player_data_updated(player_id: int, data: Dictionary)
signal chat_message_received(sender: String, message: String)
signal sync_data_received(data_type: String, data: Dictionary)

## Constants
const NETWORK_VERSION: int = 1
const PROTOCOL_VERSION: String = "0.1.0"
const DEFAULT_HOST: String = "127.0.0.1"
const DEFAULT_PORT: int = 9051
const MAX_PLAYERS: int = 100
const TIMEOUT: float = 30.0  # seconds
const PING_INTERVAL: float = 5.0  # seconds
const RECONNECT_DELAY: float = 10.0  # seconds

## Connection States
enum ConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    RECONNECTING,
    AUTHENTICATING,
    READY
}

## Message Types (must match server/server.py MSG_* constants)
enum MessageType {
    HELLO = 0,
    HELLO_REPLY = 1,
    PING = 2,
    PONG = 3,
    PLAYER_CONNECT = 4,
    PLAYER_DISCONNECT = 5,
    PLAYER_UPDATE = 6,
    CHAT_MESSAGE = 7,
    SYNC_REQUEST = 8,
    SYNC_DATA = 9,
    COMMAND = 10,
    ERROR = 11
}

## Static variables
static var is_initialized: bool = false
static var current_state: ConnectionState = ConnectionState.DISCONNECTED
static var is_server: bool = false
static var is_host: bool = false

## Connection info
static var server_host: String = DEFAULT_HOST
static var server_port: int = DEFAULT_PORT
static var client_id: int = 0
static var session_id: String = ""

## Network peers
static var server_peer: WebSocketMultiplayerPeer = null
static var connected_peers: Dictionary = {}
static var player_list: Dictionary = {}

## Timing
static var last_ping_time: float = 0.0
static var last_pong_time: float = 0.0
static var ping: float = 0.0
static var last_reconnect_attempt: float = 0.0

## Callbacks
static var message_handlers: Dictionary = {}


func _ready() -> void:
    if not is_initialized:
        _initialize()
        is_initialized = true


func _process(delta: float) -> void:
    _update_network(delta)


func _update_network(delta: float) -> void:
    # Placeholder heartbeat / queue flush. Multiplayer is optional and off by default.
    pass


func _initialize() -> void:
    print("[NetworkManager] Initializing WebSocket network system")
    
    # Register default message handlers
    _register_default_handlers()
    
    # Initialize WebSocket
    if not _init_websocket():
        push_error("[NetworkManager] Failed to initialize WebSocket")
        return
    
    print("[NetworkManager] Network system initialized")


func _init_websocket() -> bool:
    # WebSocket is built into Godot 4, no initialization needed
    # Just check if it's available
    if WebSocketMultiplayerPeer == null:
        return false
    return true


# ============================================================================
# CONNECTION MANAGEMENT
# ============================================================================

func connect_to_server(host: String = DEFAULT_HOST, port: int = DEFAULT_PORT) -> bool:
    if current_state == ConnectionState.CONNECTED:
        push_warning("[NetworkManager] Already connected to server")
        return false
    
    if current_state == ConnectionState.CONNECTING:
        push_warning("[NetworkManager] Connection already in progress")
        return false
    
    server_host = host
    server_port = port
    
    change_state(ConnectionState.CONNECTING)
    
    # Create peer
    server_peer = WebSocketMultiplayerPeer.new()
    
    # WebSocketMultiplayerPeer.create_client expects a WebSocket URL
    var ws_url = "ws://%s:%d" % [server_host, server_port]
    var err = server_peer.create_client(ws_url)
    if err != OK:
        push_error("[NetworkManager] Failed to create client: %s" % _get_error_string(err))
        change_state(ConnectionState.DISCONNECTED)
        connection_failed.emit("Failed to create client")
        return false
    
    # Connect signals (Godot 4.4 WebSocketMultiplayerPeer signals)
    # The signal names might be different in 4.4
    var connected = false
    if server_peer.has_signal("peer_packet_received"):
        server_peer.peer_packet_received.connect(_on_peer_packet)
        connected = true
    elif server_peer.has_signal("peer_packet"):
        server_peer.peer_packet.connect(_on_peer_packet)
        connected = true
    else:
        push_warning("[NetworkManager] Could not find peer packet signal")
    
    if server_peer.has_signal("peer_connected"):
        server_peer.peer_connected.connect(_on_peer_connected)
    if server_peer.has_signal("peer_disconnected"):
        server_peer.peer_disconnected.connect(_on_peer_disconnected)
    if server_peer.has_signal("server_disconnected"):
        server_peer.server_disconnected.connect(_on_server_disconnected)
    
    # Print available signals for debugging
    var signals = server_peer.get_signal_list()
    var signal_names = []
    for s in signals:
        if s.has("name"):
            signal_names.append(s["name"])
        else:
            signal_names.append(str(s))
    print("[NetworkManager] Available signals: %s" % signal_names)
    
    # Set as multiplayer peer (Godot 4.x uses the `multiplayer` singleton)
    multiplayer.multiplayer_peer = server_peer
    
    print("[NetworkManager] Connecting to %s" % ws_url)
    
    # Start connection timeout
    var timer = Timer.new()
    add_child(timer)
    timer.timeout.connect(_on_connection_timeout.bind(), CONNECT_ONE_SHOT)
    timer.start(TIMEOUT)
    
    return true


func disconnect_from_server() -> void:
    if current_state == ConnectionState.DISCONNECTED:
        return
    
    print("[NetworkManager] Disconnecting from server")
    
    # Clean up
    if server_peer:
        server_peer.close()
        server_peer = null
    
    # Set multiplayer peer to null (Godot 4.x uses the `multiplayer` singleton)
    multiplayer.multiplayer_peer = null
    change_state(ConnectionState.DISCONNECTED)
    connection_lost.emit("Manual disconnect")


func start_server(port: int = DEFAULT_PORT, max_players: int = MAX_PLAYERS) -> bool:
    if current_state != ConnectionState.DISCONNECTED:
        push_warning("[NetworkManager] Must be disconnected to start server")
        return false
    
    is_server = true
    is_host = true
    server_port = port
    
    change_state(ConnectionState.CONNECTING)
    
    # Create server peer
    server_peer = WebSocketMultiplayerPeer.new()
    
    # WebSocketMultiplayerPeer.create_server in Godot 4.4: port (int), bind_address (String), tls_options (TLSOptions = null)
    var bind_address = "0.0.0.0"
    var err = server_peer.create_server(port, bind_address)
    if err != OK:
        push_error("[NetworkManager] Failed to create server: %s" % _get_error_string(err))
        change_state(ConnectionState.DISCONNECTED)
        return false
    
    # Connect signals (Godot 4.4 WebSocketMultiplayerPeer signals)
    if server_peer.has_signal("peer_packet_received"):
        server_peer.peer_packet_received.connect(_on_peer_packet)
    elif server_peer.has_signal("peer_packet"):
        server_peer.peer_packet.connect(_on_peer_packet)
    else:
        push_warning("[NetworkManager] Could not find peer packet signal")
    
    if server_peer.has_signal("peer_connected"):
        server_peer.peer_connected.connect(_on_peer_connected)
    if server_peer.has_signal("peer_disconnected"):
        server_peer.peer_disconnected.connect(_on_peer_disconnected)
    
    # Set as multiplayer peer (Godot 4.x uses the `multiplayer` singleton)
    multiplayer.multiplayer_peer = server_peer
    
    print("[NetworkManager] Server started on port %d" % port)
    change_state(ConnectionState.READY)
    connection_established.emit()
    
    return true


func stop_server() -> void:
    if not is_server:
        return
    
    print("[NetworkManager] Stopping server")
    
    if server_peer:
        server_peer.close()
        server_peer = null
    
    if multiplayer:
        multiplayer.multiplayer_peer = null
    is_server = false
    is_host = false
    
    change_state(ConnectionState.DISCONNECTED)


# ============================================================================
# STATE MANAGEMENT
# ============================================================================

func change_state(new_state: ConnectionState) -> void:
    var old_state = current_state
    current_state = new_state
    
    print("[NetworkManager] State changed: %s -> %s" % [old_state, new_state])


func get_current_state() -> ConnectionState:
    return current_state


# ============================================================================
# MESSAGE SENDING
# ============================================================================

func send_message(message_type: MessageType, data: Dictionary = {}) -> bool:
    if current_state != ConnectionState.CONNECTED and current_state != ConnectionState.READY:
        push_warning("[NetworkManager] Not connected, cannot send message")
        return false
    
    var message: Dictionary = {
        "type": message_type,
        "version": PROTOCOL_VERSION,
        "timestamp": Time.get_ticks_msec(),
        "sender": client_id,
        "data": data
    }
    
    var buffer = _serialize_message(message)
    
    if is_server:
        # Send to all connected clients
        for peer_id in server_peer.get_peers():
            server_peer.send(peer_id, buffer)
    else:
        # Send to server
        server_peer.send(1, buffer)  # Server is always ID 1
    
    return true


func send_to_peer(peer_id: int, message_type: MessageType, data: Dictionary = {}) -> bool:
    if current_state != ConnectionState.CONNECTED and current_state != ConnectionState.READY:
        return false
    
    var message: Dictionary = {
        "type": message_type,
        "version": PROTOCOL_VERSION,
        "timestamp": Time.get_ticks_msec(),
        "sender": client_id,
        "data": data
    }
    
    var buffer = _serialize_message(message)
    server_peer.send(peer_id, buffer)
    return true


func broadcast_message(message_type: MessageType, data: Dictionary = {}, exclude_peer: int = -1) -> bool:
    if not is_server:
        return send_message(message_type, data)
    
    var message: Dictionary = {
        "type": message_type,
        "version": PROTOCOL_VERSION,
        "timestamp": Time.get_ticks_msec(),
        "sender": client_id,
        "data": data
    }
    
    var buffer = _serialize_message(message)
    
    for peer_id in server_peer.get_peers():
        if peer_id != exclude_peer:
            server_peer.send(peer_id, buffer)
    
    return true


# ============================================================================
# MESSAGE HANDLING
# ============================================================================

func register_message_handler(message_type: MessageType, callback: Callable) -> void:
    message_handlers[message_type] = callback


func unregister_message_handler(message_type: MessageType) -> bool:
    if message_handlers.has(message_type):
        message_handlers.erase(message_type)
        return true
    return false


func _register_default_handlers() -> void:
    # Register handlers for default message types
    register_message_handler(MessageType.HELLO_REPLY, _handle_hello_reply)
    register_message_handler(MessageType.PING, _handle_ping)
    register_message_handler(MessageType.PONG, _handle_pong)
    register_message_handler(MessageType.PLAYER_CONNECT, _handle_player_connect)
    register_message_handler(MessageType.PLAYER_DISCONNECT, _handle_player_disconnect)
    register_message_handler(MessageType.PLAYER_UPDATE, _handle_player_update)
    register_message_handler(MessageType.CHAT_MESSAGE, _handle_chat_message)
    register_message_handler(MessageType.SYNC_DATA, _handle_sync_data)
    register_message_handler(MessageType.ERROR, _handle_error)


func _on_peer_packet(peer_id: int, packet: PackedByteArray) -> void:
    var message = _deserialize_message(packet)
    
    if message == null:
        push_error("[NetworkManager] Failed to deserialize message")
        return
    
    # Validate message
    if not message.has("type") or not message.has("version"):
        push_error("[NetworkManager] Invalid message format")
        return
    
    # Check version
    if message["version"] != PROTOCOL_VERSION:
        push_error("[NetworkManager] Protocol version mismatch: %s vs %s" % [message["version"], PROTOCOL_VERSION])
        return
    
    # Handle the message
    var message_type = message["type"] as MessageType
    
    if message_handlers.has(message_type):
        var handler = message_handlers[message_type]
        if handler:
            handler.call(message)
    else:
        push_warning("[NetworkManager] No handler for message type: %d" % message_type)


# Godot 4.4 WebSocketMultiplayerPeer uses peer_packet_received signal
func _on_peer_packet_received(peer_id: int, packet: PackedByteArray) -> void:
    _on_peer_packet(peer_id, packet)


func _on_peer_connected(peer_id: int) -> void:
    print("[NetworkManager] Peer connected: %d" % peer_id)
    connected_peers[peer_id] = true
    
    if is_server:
        # Send welcome message
        var welcome_data = {
            "client_id": peer_id,
            "session_id": session_id,
            "max_players": MAX_PLAYERS,
            "player_count": connected_peers.size()
        }
        send_to_peer(peer_id, MessageType.HELLO_REPLY, welcome_data)


func _on_peer_disconnected(peer_id: int) -> void:
    print("[NetworkManager] Peer disconnected: %d" % peer_id)
    
    if connected_peers.has(peer_id):
        connected_peers.erase(peer_id)
    
    if player_list.has(peer_id):
        player_disconnected.emit(peer_id)
        player_list.erase(peer_id)


func _on_server_disconnected() -> void:
    print("[NetworkManager] Server disconnected")
    connected_peers.clear()
    player_list.clear()
    
    change_state(ConnectionState.DISCONNECTED)
    connection_lost.emit("Server disconnected")


func _on_connection_timeout() -> void:
    if current_state == ConnectionState.CONNECTING:
        push_error("[NetworkManager] Connection timeout")
        disconnect_from_server()
        connection_failed.emit("Connection timeout")


# ============================================================================
# DEFAULT MESSAGE HANDLERS
# ============================================================================

func _handle_hello_reply(message: Dictionary) -> void:
    client_id = message["data"].get("client_id", 0)
    session_id = message["data"].get("session_id", "")
    
    change_state(ConnectionState.CONNECTED)
    connection_established.emit()
    
    print("[NetworkManager] Connected to server, client ID: %d" % client_id)


func _handle_ping(message: Dictionary) -> void:
    if is_server:
        # Server replies with pong
        send_to_peer(message["sender"], MessageType.PONG)
    else:
        # Client records ping time
        last_ping_time = Time.get_ticks_msec()


func _handle_pong(message: Dictionary) -> void:
    last_pong_time = Time.get_ticks_msec()
    if last_ping_time > 0:
        ping = (last_pong_time - last_ping_time) / 1000.0


func _handle_player_connect(message: Dictionary) -> void:
    var player_data = message["data"]
    var player_id = player_data.get("player_id", 0)
    
    player_list[player_id] = player_data
    player_connected.emit(player_id, player_data)
    
    print("[NetworkManager] Player connected: %d" % player_id)


func _handle_player_disconnect(message: Dictionary) -> void:
    var player_id = message["data"].get("player_id", 0)
    
    if player_list.has(player_id):
        player_list.erase(player_id)
    
    player_disconnected.emit(player_id)
    print("[NetworkManager] Player disconnected: %d" % player_id)


func _handle_player_update(message: Dictionary) -> void:
    var player_data = message["data"]
    var player_id = player_data.get("player_id", 0)
    
    player_data_updated.emit(player_id, player_data)


func _handle_chat_message(message: Dictionary) -> void:
    var data = message["data"]
    var sender = data.get("sender", "Unknown")
    var text = data.get("message", "")
    
    chat_message_received.emit(sender, text)
    print("[NetworkManager] Chat message from %s: %s" % [sender, text])


func _handle_sync_data(message: Dictionary) -> void:
    var data_type = message["data"].get("type", "")
    var data = message["data"].get("data", {})
    
    sync_data_received.emit(data_type, data)


func _handle_error(message: Dictionary) -> void:
    var error_data = message["data"]
    var error_code = error_data.get("code", 0)
    var error_message = error_data.get("message", "Unknown error")
    
    push_error("[NetworkManager] Server error: %d - %s" % [error_code, error_message])


# ============================================================================
# PLAYER MANAGEMENT
# ============================================================================

func send_player_update(update_data: Dictionary) -> bool:
    var message_data = {
        "player_id": client_id,
        "data": update_data
    }
    return send_message(MessageType.PLAYER_UPDATE, message_data)


func send_chat_message(text: String) -> bool:
    var message_data = {
        "sender": get_player_name(),
        "message": text
    }
    return send_message(MessageType.CHAT_MESSAGE, message_data)


func send_sync_request(data_type: String, request_data: Dictionary = {}) -> bool:
    var message_data = {
        "type": data_type,
        "request": request_data
    }
    return send_message(MessageType.SYNC_REQUEST, message_data)


func send_command(command: String, command_data: Dictionary = {}) -> bool:
    var message_data = {
        "command": command,
        "data": command_data
    }
    return send_message(MessageType.COMMAND, message_data)


func get_player_name() -> String:
    # TODO: Implement player name from character data
    return "Player_%d" % client_id


func get_connected_players() -> Dictionary:
    return player_list.duplicate()


func get_peer_count() -> int:
    return connected_peers.size()


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func _get_error_string(error_code: int) -> String:
    match error_code:
        FAILED:
            return "Operation failed"
        ERR_UNAVAILABLE:
            return "Feature unavailable"
        ERR_UNCONFIGURED:
            return "Not configured"
        ERR_INVALID_PARAMETER:
            return "Invalid parameter"
        ERR_ALREADY_IN_USE:
            return "Already in use"
        ERR_TIMEOUT:
            return "Timeout"
        ERR_CONNECTION_ERROR:
            return "Connection error"
        _:
            return "Unknown error (%d)" % error_code


func _serialize_message(message: Dictionary) -> PackedByteArray:
    var json = JSON.new()
    var text = json.stringify(message)
    return text.to_utf8_buffer()


func _deserialize_message(data: PackedByteArray) -> Dictionary:
    var json = JSON.new()
    var text = data.get_string_from_utf8()
    var err = json.parse(text)
    
    if err != OK:
        push_error("[NetworkManager] JSON parse error: %s" % json.get_error_message())
        return {}
    
    return json.data


func get_ping() -> float:
    return ping


func is_network_connected() -> bool:
    return current_state == ConnectionState.CONNECTED or current_state == ConnectionState.READY


func is_hosting() -> bool:
    return is_host


func get_connection_info() -> Dictionary:
    return {
        "state": current_state,
        "host": server_host,
        "port": server_port,
        "client_id": client_id,
        "session_id": session_id,
        "ping": ping,
        "is_server": is_server,
        "is_host": is_host,
        "player_count": connected_peers.size()
    }
