"""
Eclipse Realms — Authentication module (G-S1, Shiki review pending).

Minimal, dependency-light auth for the REST API (port 9052):
  POST /api/register  {username, password, email?} -> {session_token, peer_id}
  POST /api/login     {username, password}         -> {session_token, peer_id}
  POST /api/logout    {session_token}              -> {status}
  GET  /api/me        ?session_token=...           -> player record (or 401)

Security notes (for Shiki / CISO review — NOT production-hardened yet):
  * Passwords hashed with PBKDF2-HMAC-SHA256 (100k iters), per-peer salt.
  * Sessions are random 32-byte hex tokens, stored in `sessions` table with expiry.
  * CORS is open by default (see CORS_ORIGINS) — tighten before prod.
  * No rate limiting yet — add at reverse proxy / in start_http.
  * No email verification — out of scope for v0.1.0.
This module is wired but must pass Shiki's G-S1 security review before multiplayer persistence is trusted.
"""
import hashlib
import hmac
import os
import secrets
import sqlite3
import time
from datetime import datetime, timedelta

# Configurable via env (so staging/prod don't hardcode 127.0.0.1).
SESSION_TTL_SECONDS = int(os.environ.get("ECLIPSE_SESSION_TTL", "86400"))
PBKDF2_ITERS = 100_000
CORS_ORIGINS = os.environ.get("ECLIPSE_CORS_ORIGINS", "*").split(",")


def _hash_password(password: str, salt: bytes = None) -> tuple[str, str]:
    """Return (salt_hex, hash_hex) using PBKDF2-HMAC-SHA256."""
    if salt is None:
        salt = secrets.token_bytes(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, PBKDF2_ITERS)
    return salt.hex(), dk.hex()


def _verify_password(password: str, salt_hex: str, hash_hex: str) -> bool:
    _, check = _hash_password(password, bytes.fromhex(salt_hex))
    return hmac.compare_digest(check, hash_hex)


def register(db_path: str, username: str, password: str, email: str = None) -> dict:
    """Create account + session. Returns {ok, session_token, peer_id, error}."""
    username = (username or "").strip()
    if not username or not password:
        return {"ok": False, "error": "username and password required"}
    if len(password) < 8:
        return {"ok": False, "error": "password must be >= 8 chars"}
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    # unique username
    c.execute("SELECT id FROM players WHERE username = ?", (username,))
    if c.fetchone():
        conn.close()
        return {"ok": False, "error": "username taken"}
    salt_hex, hash_hex = _hash_password(password)
    c.execute(
        "INSERT INTO players (peer_id, username, password_hash, email, position_x, position_y, inventory, equipment, active_quests, completed_quests) "
        "VALUES (?, ?, ?, ?, 300.0, 360.0, '[]', '{}', '[]', '[]')",
        (int(time.time() * 1000) % (2 ** 31), username, f"{salt_hex}:{hash_hex}", email),
    )
    peer_id = c.lastrowid
    token = secrets.token_hex(32)
    expires = datetime.utcnow() + timedelta(seconds=SESSION_TTL_SECONDS)
    c.execute(
        "INSERT INTO sessions (session_token, peer_id, expires_at) VALUES (?, ?, ?)",
        (token, peer_id, expires.isoformat()),
    )
    conn.commit()
    conn.close()
    return {"ok": True, "session_token": token, "peer_id": peer_id}


def login(db_path: str, username: str, password: str) -> dict:
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("SELECT id, password_hash FROM players WHERE username = ?", (username,))
    row = c.fetchone()
    if not row:
        conn.close()
        return {"ok": False, "error": "invalid credentials"}
    pid, stored = row
    if ":" not in stored:
        conn.close()
        return {"ok": False, "error": "invalid credentials"}
    salt_hex, hash_hex = stored.split(":", 1)
    if not _verify_password(password, salt_hex, hash_hex):
        conn.close()
        return {"ok": False, "error": "invalid credentials"}
    token = secrets.token_hex(32)
    expires = datetime.utcnow() + timedelta(seconds=SESSION_TTL_SECONDS)
    c.execute(
        "INSERT INTO sessions (session_token, peer_id, expires_at) VALUES (?, ?, ?)",
        (token, pid, expires.isoformat()),
    )
    conn.commit()
    conn.close()
    return {"ok": True, "session_token": token, "peer_id": pid}


def logout(db_path: str, session_token: str) -> dict:
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("DELETE FROM sessions WHERE session_token = ?", (session_token,))
    conn.commit()
    conn.close()
    return {"ok": True, "status": "logged out"}


def get_peer_for_session(db_path: str, session_token: str) -> int | None:
    if not session_token:
        return None
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("SELECT peer_id, expires_at FROM sessions WHERE session_token = ?", (session_token,))
    row = c.fetchone()
    conn.close()
    if not row:
        return None
    peer_id, expires = row
    try:
        if datetime.fromisoformat(expires) < datetime.utcnow():
            return None
    except Exception:
        pass
    return peer_id
