extends Node
## NetworkManager.gd - WebSocket Network Communication System
## Handles client-server communication for multiplayer features via WebSocket (raw JSON protocol)
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

## Network client (WebSocketClient for raw WebSocket)
static var ws_client: WebSocketClient = null

## Timing
static var last_ping_time: float = 0.0
static var last_pong_time: float = 0.0
static var ping: float = 0.0
static var last_reconnect_attempt: float = 0.0

## Callbacks
static var message_handlers: Dictionary = {}

## Pending messages queue (for when connection is not ready)
static var pending_messages: Array = []

## Player list
static var player_list: Dictionary = {}


func _ready() -> void:
    if not is_initialized:
        _initialize()
        is_initialized = true


func _process(delta: float) -> void:
    _update_network(delta)


func _update_network(delta: float) -> void:
    # Poll WebSocket client for incoming messages
    if ws_client:
        ws_client.poll()
    
    # Send periodic pings
    if current_state == ConnectionState.CONNECTED or current_state == ConnectionState.READY:
        var now = Time.get_ticks_msec() / 1000.0
        if now - last_ping_time >= PING_INTERVAL:
            _send_ping()


func _initialize() -> void:
    print("[NetworkManager] Initializing WebSocket network system (raw JSON protocol)")
    
    # Register default message handlers
    _register_default_handlers()
    
    print("[NetworkManager] Network system initialized")


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
    
    # Create WebSocket client
    ws_client = WebSocketClient.new()
    
    # Connect signals
    ws_client.connected_to_server.connect(_on_ws_connected)
    ws_client.disconnected_from_server.connect(_on_ws_disconnected)
    ws_client.data_received.connect(_on_ws_data_received)
    ws_client.connection_failed.connect(_on_ws_connection_failed)
    
    # Connect to server
    var ws_url = "ws://%s:%d" % [server_host, server_port]
    var err = ws_client.connect_to_url(ws_url)
    if err != OK:
        push_error("[NetworkManager] Failed to connect: %s" % _get_error_string(err))
        change_state(ConnectionState.DISCONNECTED)
        connection_failed.emit("Failed to connect: %s" % _get_error_string(err))
        return false
    
    print("[NetworkManager] Connecting to %s" % ws_url)
    
    # Start connection timeout
    var timer = Timer.new()
    add_child(timer)
    timer.one_shot = true
    timer.wait_time = TIMEOUT
    timer.timeout.connect(_on_connection_timeout.bind())
    timer.start()
    
    return true


func disconnect_from_server() -> void:
    if current_state == ConnectionState.DISCONNECTED:
        return
    
    print("[NetworkManager] Disconnecting from server")
    
    # Clean up
    if ws_client:
        ws_client.close()
        ws_client = null
    
    change_state(ConnectionState.DISCONNECTED)
    connection_lost.emit("Manual disconnect")


# Server hosting not supported with raw WebSocket (would need separate implementation)
func start_server(port: int = DEFAULT_PORT, max_players: int = MAX_PLAYERS) -> bool:
    push_error("[NetworkManager] Server hosting not implemented for raw WebSocket protocol. Use dedicated server.")
    return false


func stop_server() -> void:
    pass


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
        # Queue message for later
        pending_messages.append({
            "type": message_type,
            "data": data
        })
        return false
    
    var message: Dictionary = {
        "type": message_type,
        "version": PROTOCOL_VERSION,
        "timestamp": Time.get_ticks_msec(),
        "sender": client_id,
        "data": data
    }
    
    return _send_raw_message(message)


func send_to_peer(peer_id: int, message_type: MessageType, data: Dictionary = {}) -> bool:
    # For client, all messages go to server (peer_id ignored)
    return send_message(message_type, data)


func broadcast_message(message_type: MessageType, data: Dictionary = {}, exclude_peer: int = -1) -> bool:
    # For client, same as send_message
    return send_message(message_type, data)


func _send_raw_message(message: Dictionary) -> bool:
    if not ws_client:
        return false
    
    var json = JSON.new()
    var text = json.stringify(message)
    
    var err = ws_client.send(text)
    if err != OK:
        push_error("[NetworkManager] Failed to send message: %s" % _get_error_string(err))
        return false
    
    return true


func _send_ping() -> void:
    last_ping_time = Time.get_ticks_msec() / 1000.0
    send_message(MessageType.PING, {})


func _flush_pending_messages() -> void:
    for msg in pending_messages:
        send_message(msg["type"], msg["data"])
    pending_messages.clear()


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


# WebSocket client signal handlers
func _on_ws_connected(protocol: String = "") -> void:
    print("[NetworkManager] WebSocket connected")
    # Send HELLO message
    var hello_msg = {
        "type": MessageType.HELLO,
        "version": PROTOCOL_VERSION,
        "timestamp": Time.get_ticks_msec(),
        "sender": 0,
        "data": {}
    }
    _send_raw_message(hello_msg)


func _on_ws_disconnected(was_clean: bool = false, code: int = 0, reason: String = "") -> void:
    print("[NetworkManager] WebSocket disconnected: clean=%s code=%d reason=%s" % [was_clean, code, reason])
    
    if current_state == ConnectionState.CONNECTING:
        connection_failed.emit("Disconnected during connection: %s" % reason)
    elif current_state == ConnectionState.CONNECTED or current_state == ConnectionState.READY:
        connection_lost.emit("Disconnected: %s" % reason)
    
    connected_peers.clear()
    player_list.clear()
    change_state(ConnectionState.DISCONNECTED)


func _on_ws_data_received() -> void:
    if not ws_client:
        return
    
    # Get all available messages
    while ws_client.get_available_packet_count() > 0:
        var packet = ws_client.get_packet()
        if packet.size() > 0:
            var text = packet.get_string_from_utf8()
            var json = JSON.new()
            var err = json.parse(text)
            
            if err != OK:
                push_error("[NetworkManager] JSON parse error: %s" % json.get_error_message())
                continue
            
            _handle_incoming_message(json.data)


func _on_ws_connection_failed() -> void:
    print("[NetworkManager] WebSocket connection failed")
    change_state(ConnectionState.DISCONNECTED)
    connection_failed.emit("Connection failed")


func _on_connection_timeout() -> void:
    if current_state == ConnectionState.CONNECTING:
        push_error("[NetworkManager] Connection timeout")
        if ws_client:
            ws_client.close()
            ws_client = null
        change_state(ConnectionState.DISCONNECTED)
        connection_failed.emit("Connection timeout")


func _handle_incoming_message(message: Dictionary) -> void:
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


# ============================================================================
# DEFAULT MESSAGE HANDLERS
# ============================================================================

func _handle_hello_reply(message: Dictionary) -> void:
    client_id = message["data"].get("client_id", 0)
    session_id = message["data"].get("session_id", "")
    
    change_state(ConnectionState.CONNECTED)
    connection_established.emit()
    
    print("[NetworkManager] Connected to server, client ID: %d" % client_id)
    
    # Flush any pending messages
    _flush_pending_messages()


func _handle_ping(message: Dictionary) -> void:
    # Client doesn't handle incoming PING (server sends PING, client replies with PONG)
    # But we can send PONG back if needed
    send_message(MessageType.PONG, {})


func _handle_pong(message: Dictionary) -> void:
    last_pong_time = Time.get_ticks_msec() / 1000.0
    if last_ping_time > 0:
        ping = last_pong_time - last_ping_time


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
    return player_list.size()


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
        "player_count": player_list.size()
    }