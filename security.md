# Eclipse Realms — Server Security (G-S1)

Status: **v0.1.0-alpha**. These controls close the server-side audit gaps G-S1
(AUDIT_COMPLETE_2026-08-15 §9 / §15). The server is **NOT** production-hardened.
See "Known Limitations" before any real deployment.

## Components
- **HTTP REST API** on port `9052` (aiohttp) — auth, account management, persistence.
- **WebSocket** on port `9051` — game-client fallback transport.
- **ENet** on port `9050` — real-time state sync (not yet implemented in `server.py`).

## Authentication scheme
1. `POST /api/register` `{username, password, email?}`
   - Passwords hashed with **PBKDF2-HMAC-SHA256**, 100k iterations, a 16-byte
     per-account random salt. Stored as `salt_hex:hash_hex` in `players.password_hash`.
   - Minimum password length: **8 chars**. Usernames must be non-empty and unique.
   - Returns a session token + peer_id and creates a `sessions` row with TTL.
2. `POST /api/login` `{username, password}`
   - Verifies the stored hash via constant-time comparison (`hmac.compare_digest`).
   - On success issues a new **32-byte random hex** session token (stored in
     `sessions` with an expiry).
3. `GET /api/me` `?session_token=...`
   - Resolves the token to a `peer_id` via the `sessions` table (rejects
     expired/unknown tokens). Returns the player record **without** `password_hash`.
4. `POST /api/logout` `{session_token}` — deletes the session row.

Auth is stateless per-request: the client passes `session_token` for `/api/me`.
Tokens are 256-bit random; session expiry defaults to **24h** (`ECLIPSE_SESSION_TTL` seconds).

## CORS (G-S1 fix)
- Default allowed origins: `https://streetsmartnyc.online`, `http://localhost`,
  `http://127.0.0.1:9052`.
- Override with `ECLIPSE_CORS_ORIGINS` (comma-separated). Set `*` **only** for local dev.
- Only `GET,POST,OPTIONS` and `Content-Type` are allowed. No Cookies/credentials are used.

## Rate limiting (G-S1 fix)
- Per client-IP, **100 requests / minute** (hardcoded `RATE_LIMIT_PER_MIN` for alpha).
- Exceeding the limit returns **HTTP 429**. The counter is in-memory and per-process
  (resets on restart and is not shared between instances).

## Secrets management
- The production Postgres password is supplied to docker-compose via a Docker secret.
  `server/docker/docker-compose.yml` references `./secrets/db_password.txt`.
- A placeholder exists at `./secrets/db_password.txt` (and `server/secrets/db_password.txt`
  so docker-compose resolves it from its project directory).
- **Replace it with a strong, randomized value before any real deployment and never
  commit the real secret.** Ensure `secrets/` is in `.gitignore`.

## Known limitations (track for beta / prod)
1. **No TLS.** REST + WebSocket are plaintext. Terminate TLS at a reverse proxy before
   production and move clients to HTTPS/WSS.
2. **No OPTIONS preflight handler.** CORS headers are attached to normal responses, but
   there is no explicit `OPTIONS` route, so browser preflight on cross-origin POSTs may
   return 405. Add an `OPTIONS` handler (or rely on the reverse proxy) before depending on
   cross-origin web clients.
3. **Naive rate limiting.** In-memory, per-process, single-instance only; uses
   `request.remote` (which is the proxy IP behind a load balancer). Move to a shared
   limiter (e.g. Redis) + `X-Forwarded-For` parsing for multi-instance deployments.
4. **No email verification / password reset.** Out of scope for v0.1.0.
5. **No brute-force protection beyond rate limiting.** Add per-account lockout / CAPTCHA
   on login.
6. **Sessions persist until expiry; logout is client-driven.** Tokens are not rotated and
   there is no server-enforced single-session policy.
7. **WebSocket (9051) and ENet (9050) have no auth handshake yet** for game traffic.
   This is the next hardening pass.
8. **No audit logging of auth events.** Add structured logging for register/login/logout
   failures and token reuse.
