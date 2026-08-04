"""
Eclipse Realms - Backend Server (v0.1.0-alpha)
Python 3 async ENet/WebSocket hybrid server

Protocol:
- ENet (port 9050): Real-time game state sync (movement, combat, chat)
- WebSocket (port 9051): REST-like fallback for web clients
- HTTP REST (port 9052): Authentication, account management, persistence

Message Format (JSON):
{
    "type": int (MessageType enum from NetworkManager.gd),
    "version": "0.1.0",
    "timestamp": <unix_ms>,
    "sender": <peer_id>,
    "data": { ... }
}
"""

import asyncio
import json
import sqlite3
import os
import time
import signal
import sys
from collections import defaultdict

# --- Configuration ---
ENET_PORT = 9050
WS_PORT = 9051
HTTP_PORT = 9052
MAX_PLAYERS = 100
DB_PATH = os.path.join(os.path.dirname(__file__), "database", "eclipse_realms.db")
PROTOCOL_VERSION = "0.1.0"

# Auth module (G-S1 — Shiki security review pending)
from auth import register as _auth_register, login as _auth_login, \
    logout as _auth_logout, get_peer_for_session as _auth_peer

_CORS = os.environ.get("ECLIPSE_CORS_ORIGINS", "*").split(",")

# --- Message Types (must match NetworkManager.gd enum) ---
MSG_HELLO = 0
MSG_HELLO_REPLY = 1
MSG_PING = 2
MSG_PONG = 3
MSG_PLAYER_CONNECT = 4
MSG_PLAYER_DISCONNECT = 5
MSG_PLAYER_UPDATE = 6
MSG_CHAT_MESSAGE = 7
MSG_SYNC_REQUEST = 8
MSG_SYNC_DATA = 9
MSG_COMMAND = 10
MSG_ERROR = 11


class Player:
    """Represents a connected player."""
    def __init__(self, peer_id: int, ws=None):
        self.peer_id = peer_id
        self.ws = ws
        self.connected = False
        self.player_data = {
            "name": f"Player_{peer_id}",
            "level": 1,
            "experience": 0,
            "position": {"x": 0, "y": 0},
            "health": 100,
            "max_health": 100,
            "mana": 50,
            "max_mana": 50,
            "attack": 10,
            "defense": 5,
            "inventory": [],
            "equipment": {},
            "active_quests": [],
            "completed_quests": [],
            "gold": 0,
        }
        self.last_ping = time.time()
        self.ip_address = "unknown"

    def to_dict(self):
        return self.player_data

    def update_position(self, x: float, y: float):
        self.player_data["position"] = {"x": x, "y": y}


class Database:
    """SQLite database manager for player persistence."""
    def __init__(self, db_path: str):
        self.db_path = db_path
        self._init_db()

    def _init_db(self):
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()

        # Players table
        c.execute("""
            CREATE TABLE IF NOT EXISTS players (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                peer_id INTEGER UNIQUE,
                username TEXT UNIQUE,
                password_hash TEXT,
                email TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                level INTEGER DEFAULT 1,
                experience INTEGER DEFAULT 0,
                gold INTEGER DEFAULT 0,
                health INTEGER DEFAULT 100,
                max_health INTEGER DEFAULT 100,
                mana INTEGER DEFAULT 50,
                max_mana INTEGER DEFAULT 50,
                attack INTEGER DEFAULT 10,
                defense INTEGER DEFAULT 5,
                position_x REAL DEFAULT 300.0,
                position_y REAL DEFAULT 360.0,
                inventory TEXT,  -- JSON array
                equipment TEXT,  -- JSON dict
                active_quests TEXT,  -- JSON array
                completed_quests TEXT  -- JSON array
            )
        """)

        # Sessions table
        c.execute("""
            CREATE TABLE IF NOT EXISTS sessions (
                session_token TEXT PRIMARY KEY,
                peer_id INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                expires_at TIMESTAMP
            )
        """)

        # World state table
        c.execute("""
            CREATE TABLE IF NOT EXISTS world_state (
                key TEXT PRIMARY KEY,
                value TEXT,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        conn.commit()
        conn.close()
        print(f"[DB] Initialized database at {self.db_path}")

    def get_player(self, peer_id: int) -> dict:
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute("SELECT * FROM players WHERE peer_id = ?", (peer_id,))
        row = c.fetchone()
        conn.close()
        if row:
            columns = [d[0] for d in c.description]
            return dict(zip(columns, row))
        return {}

    def create_player(self, peer_id: int, username: str) -> dict:
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute("""
            INSERT INTO players (peer_id, username, position_x, position_y, inventory, equipment, active_quests, completed_quests)
            VALUES (?, ?, 300.0, 360.0, '[]', '{}', '[]', '[]')
        """, (peer_id, username))
        conn.commit()
        conn.close()
        return self.get_player(peer_id)

    def save_player(self, player: Player):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        d = player.player_data
        c.execute("""
            UPDATE players SET
                username = ?,
                level = ?, experience = ?, gold = ?,
                health = ?, max_health = ?, mana = ?, max_mana = ?,
                attack = ?, defense = ?,
                position_x = ?, position_y = ?,
                inventory = ?, equipment = ?,
                active_quests = ?, completed_quests = ?,
                last_login = CURRENT_TIMESTAMP
            WHERE peer_id = ?
        """, (
            d["name"], d["level"], d["experience"], d["gold"],
            d["health"], d["max_health"], d["mana"], d["max_mana"],
            d["attack"], d["defense"],
            d["position"]["x"], d["position"]["y"],
            json.dumps(d["inventory"]),
            json.dumps(d["equipment"]),
            json.dumps(d["active_quests"]),
            json.dumps(d["completed_quests"]),
            player.peer_id
        ))
        conn.commit()
        conn.close()
        print(f"[DB] Saved player {player.peer_id} ({d['name']})")

    def close(self):
        # Nothing to do for SQLite (file-based)
        pass


class GameServer:
    """Main server orchestration."""

    def __init__(self):
        self.players: dict[int, Player] = {}
        self.db = Database(DB_PATH)
        self.running = False
        self.next_peer_id = 1
        self._shutdown = False

    def _create_message(self, msg_type: int, data: dict = None, sender: int = 0) -> bytes:
        msg = {
            "type": msg_type,
            "version": PROTOCOL_VERSION,
            "timestamp": int(time.time() * 1000),
            "sender": sender,
            "data": data or {}
        }
        return json.dumps(msg).encode('utf-8')

    async def _handle_websocket_client(self, websocket):
        """Handle a WebSocket client connection."""
        peer_id = self.next_peer_id
        self.next_peer_id += 1

        player = Player(peer_id, ws=websocket)
        self.players[peer_id] = player

        print(f"[WS] Player {peer_id} connected")

        try:
            # Send HELLO_REPLY
            existing = self.db.get_player(peer_id)
            if existing:
                player.player_data.update({
                    "name": existing.get("username", player.player_data["name"]),
                    "level": existing.get("level", 1),
                    "experience": existing.get("experience", 0),
                    "gold": existing.get("gold", 0),
                    "health": existing.get("health", 100),
                    "max_health": existing.get("max_health", 100),
                    "mana": existing.get("mana", 50),
                    "max_mana": existing.get("max_mana", 50),
                    "attack": existing.get("attack", 10),
                    "defense": existing.get("defense", 5),
                    "position": {"x": existing.get("position_x", 300), "y": existing.get("position_y", 360)},
                    "inventory": json.loads(existing.get("inventory", "[]")),
                    "equipment": json.loads(existing.get("equipment", "{}")),
                    "active_quests": json.loads(existing.get("active_quests", "[]")),
                    "completed_quests": json.loads(existing.get("completed_quests", "[]")),
                })
            else:
                self.db.create_player(peer_id, player.player_data["name"])

            player.connected = True

            await websocket.send(self._create_message(MSG_HELLO_REPLY, {
                "client_id": peer_id,
                "session_id": "session_%d" % peer_id,
                "protocol_version": PROTOCOL_VERSION,
                "server_name": "Eclipse Realms Alpha",
                "player_data": player.to_dict(),
            }, sender=0))

            print(f"[WS] Sent HELLO_REPLY to player {peer_id}")

            await self._broadcast_player_connect(peer_id)

            # Listen for messages
            async for message in websocket:
                try:
                    data = json.loads(message)
                    print(f"[WS] Received from {peer_id}: {data}")
                    await self._handle_message(peer_id, data)
                except json.JSONDecodeError:
                    print(f"[WS] Invalid JSON from {peer_id}")
                    await self._send_error(peer_id, "Invalid JSON")
                except Exception as e:
                    print(f"[WS] Error handling message from {peer_id}: {e}")
                    import traceback
                    traceback.print_exc()
                    await self._send_error(peer_id, str(e))

        except Exception as e:
            print(f"[WS] Connection error for player {peer_id}: {e}")
            import traceback
            traceback.print_exc()
        finally:
            await self._handle_disconnect(peer_id)

    async def _handle_message(self, peer_id: int, data: dict):
        """Route a message to the appropriate handler."""
        msg_type = data.get("type")
        msg_data = data.get("data", {})

        if msg_type == MSG_PING:
            player = self.players.get(peer_id)
            if player:
                player.last_ping = time.time()
            await self._send_message(peer_id, MSG_PONG, {"latency": int((time.time() - player.last_ping) * 1000)})

        elif msg_type == MSG_PLAYER_UPDATE:
            player = self.players.get(peer_id)
            if player:
                pos = msg_data.get("position", {})
                player.update_position(pos.get("x", 0), pos.get("y", 0))
                # Broadcast to other players
                await self._broadcast_player_update(peer_id, msg_data)

        elif msg_type == MSG_CHAT_MESSAGE:
            player = self.players.get(peer_id)
            if player:
                chat_msg = {
                    "sender": player.player_data["name"],
                    "message": msg_data.get("message", ""),
                    "channel": msg_data.get("channel", "global"),
                }
                await self._broadcast(MSG_CHAT_MESSAGE, chat_msg)

        elif msg_type == MSG_COMMAND:
            cmd = msg_data.get("command", "")
            await self._handle_command(peer_id, cmd, msg_data)

        else:
            print(f"[SERVER] Unhandled message type {msg_type} from peer {peer_id}")

    async def _handle_command(self, peer_id: int, command: str, data: dict):
        """Handle in-game commands."""
        player = self.players.get(peer_id)
        if not player:
            return

        cmd_parts = command.split()
        if not cmd_parts:
            return

        cmd = cmd_parts[0].lower()

        if cmd == "save":
            self.db.save_player(player)
            await self._send_message(peer_id, MSG_COMMAND, {"result": "saved", "message": "Game saved."})

        elif cmd == "list":
            active = [p.player_data["name"] for p in self.players.values() if p.connected]
            await self._send_message(peer_id, MSG_COMMAND, {"result": "players", "players": active})

        elif cmd == "help":
            cmds = ["save - Save your progress", "list - List online players", "help - Show this help"]
            await self._send_message(peer_id, MSG_COMMAND, {"result": "help", "commands": cmds})

        else:
            await self._send_message(peer_id, MSG_COMMAND, {"result": "error", "message": f"Unknown command: {cmd}"})

    async def _handle_disconnect(self, peer_id: int):
        """Handle a player disconnecting."""
        player = self.players.pop(peer_id, None)
        if player:
            player.connected = False
            # Save before removing
            self.db.save_player(player)
            print(f"[WS] Player {peer_id} ({player.player_data['name']}) disconnected and saved")
            await self._broadcast_player_disconnect(peer_id)

    async def _send_message(self, peer_id: int, msg_type: int, data: dict):
        """Send a message to a specific player."""
        player = self.players.get(peer_id)
        if player and player.ws:
            try:
                await player.ws.send(self._create_message(msg_type, data, sender=0))
            except Exception as e:
                print(f"[WS] Failed to send to {peer_id}: {e}")

    async def _send_error(self, peer_id: int, message: str):
        await self._send_message(peer_id, MSG_ERROR, {"error": message})

    async def _broadcast(self, msg_type: int, data: dict, exclude: int = None):
        """Broadcast a message to all connected players."""
        for pid, player in self.players.items():
            if pid == exclude:
                continue
            if player.ws and player.connected:
                try:
                    await player.ws.send(self._create_message(msg_type, data, sender=0))
                except Exception as e:
                    print(f"[WS] Broadcast error to {pid}: {e}")

    async def _broadcast_player_connect(self, peer_id: int):
        player = self.players.get(peer_id)
        if player:
            await self._broadcast(MSG_PLAYER_CONNECT, {
                "player_id": peer_id,
                "player_data": player.to_dict()
            }, exclude=peer_id)

    async def _broadcast_player_disconnect(self, peer_id: int):
        await self._broadcast(MSG_PLAYER_DISCONNECT, {"player_id": peer_id})

    async def _broadcast_player_update(self, peer_id: int, data: dict):
        await self._broadcast(MSG_PLAYER_UPDATE, {
            "player_id": peer_id,
            "data": data
        }, exclude=peer_id)

    async def start_ws(self):
        """Start the WebSocket server."""
        import websockets
        print(f"[SERVER] Starting WebSocket server on port {WS_PORT}")
        async with websockets.serve(self._handle_websocket_client, "0.0.0.0", WS_PORT):
            print(f"[SERVER] WebSocket server listening on ws://0.0.0.0:{WS_PORT}")
            await asyncio.Future()  # Run forever

    async def start_http(self):
        """Start a simple HTTP REST API using aiohttp."""
        from aiohttp import web
        app = web.Application()
        app.middlewares.append(self._cors_middleware())

        async def handle_hello(request):
            return web.json_response({"status": "ok", "service": "Eclipse Realms Server", "version": PROTOCOL_VERSION})

        async def handle_player(request):
            peer_id = int(request.query.get("peer_id", 0))
            player = self.db.get_player(peer_id)
            if player:
                return web.json_response(player)
            return web.json_response({"error": "Player not found"}, status=404)

        async def handle_save(request):
            peer_id = int(request.query.get("peer_id", 0))
            player = self.players.get(peer_id)
            if player:
                self.db.save_player(player)
                return web.json_response({"status": "saved"})
            return web.json_response({"error": "Player not connected"}, status=404)

        async def handle_register(request):
            try:
                data = await request.json()
            except Exception:
                return web.json_response({"error": "invalid json"}, status=400)
            res = _auth_register(DB_PATH, data.get("username", ""), data.get("password", ""), data.get("email"))
            if not res.get("ok"):
                return web.json_response({"error": res.get("error")}, status=400)
            return web.json_response({"session_token": res["session_token"], "peer_id": res["peer_id"]})

        async def handle_login(request):
            try:
                data = await request.json()
            except Exception:
                return web.json_response({"error": "invalid json"}, status=400)
            res = _auth_login(DB_PATH, data.get("username", ""), data.get("password", ""))
            if not res.get("ok"):
                return web.json_response({"error": res.get("error")}, status=401)
            return web.json_response({"session_token": res["session_token"], "peer_id": res["peer_id"]})

        async def handle_logout(request):
            try:
                data = await request.json()
            except Exception:
                return web.json_response({"error": "invalid json"}, status=400)
            _auth_logout(DB_PATH, data.get("session_token", ""))
            return web.json_response({"status": "logged out"})

        async def handle_me(request):
            token = request.query.get("session_token", "")
            peer_id = _auth_peer(DB_PATH, token)
            if peer_id is None:
                return web.json_response({"error": "unauthorized"}, status=401)
            player = self.db.get_player(peer_id)
            if player:
                return web.json_response(player)
            return web.json_response({"error": "Player not found"}, status=404)

        app.router.add_get("/api/hello", handle_hello)
        app.router.add_get("/api/player", handle_player)
        app.router.add_post("/api/save", handle_save)
        app.router.add_post("/api/register", handle_register)
        app.router.add_post("/api/login", handle_login)
        app.router.add_post("/api/logout", handle_logout)
        app.router.add_get("/api/me", handle_me)

        runner = web.AppRunner(app)
        await runner.setup()
        site = web.TCPSite(runner, "0.0.0.0", HTTP_PORT)
        await site.start()
        print(f"[SERVER] REST API running on http://0.0.0.0:{HTTP_PORT}")

        # Keep running
        await asyncio.Future()

    def _cors_middleware(self):
        from aiohttp import web
        async def _mw(request, handler):
            resp = await handler(request)
            origin = request.headers.get("Origin", "")
            allow = "*" if "*" in _CORS else origin if origin in _CORS else ""
            if allow:
                resp.headers["Access-Control-Allow-Origin"] = allow
                resp.headers["Access-Control-Allow-Methods"] = "GET,POST,OPTIONS"
                resp.headers["Access-Control-Allow-Headers"] = "Content-Type"
            return resp
        return _mw

    async def start(self):
        """Start all server components."""
        self.running = True
        print("[SERVER] Eclipse Realms Backend Server starting...")
        print(f"[SERVER] Protocol version: {PROTOCOL_VERSION}")
        print(f"[SERVER] Max players: {MAX_PLAYERS}")
        print(f"[SERVER] Database: {DB_PATH}")

        # Start HTTP API
        asyncio.create_task(self.start_http())

        # Start WebSocket server
        await self.start_ws()

    def stop(self):
        """Graceful shutdown."""
        self._shutdown = True
        self.running = False
        print("[SERVER] Shutting down...")
        for player in self.players.values():
            self.db.save_player(player)
        self.db.close()
        print("[SERVER] All players saved. Goodbye.")


def main():
    server = GameServer()

    def signal_handler(sig, frame):
        server.stop()
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    try:
        asyncio.run(server.start())
    except KeyboardInterrupt:
        server.stop()


if __name__ == "__main__":
    main()
