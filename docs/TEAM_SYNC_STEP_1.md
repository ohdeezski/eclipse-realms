# Eclipse Realms — Team Sync (Agent Zero — CORRECTED, live-verified)

**Date:** 2026-08-03 22:40 EDT

> The prior audit tables (R_TEAM_DEPLOYMENT / REALIGNMENT_AUDIT / pasted summary) list blockers that are already DONE. This doc is the single source of truth for the next 72h.

## ✅ VERIFIED RESOLVED (were called blockers)

| Blocker | Old | Verified now |
|---------|-----|--------------|
| Protocol mismatch (ENet vs WS) | ❌ | ✅ `network_manager.gd` = `WebSocketMultiplayerPeer`, port 9051; zero ENet refs |
| Export templates | ❌ | ✅ 4.2.2 / 4.3 / 4.4 in `~/.local/share/godot/export_templates/` |
| GitHub repo | ❌ | ✅ `origin = https://github.com/ohdeezski/eclipse-realms.git` |
| Godot engine | ⚠️ | ✅ v4.4.stable at `~/bin/godot`; project loads headless exit 0 |

## ⚠️ REAL REMAINING BLOCKERS

| # | Item | Owner | Effort |
|---|------|-------|--------|
| B1 | `client/tests/test_websocket_connection.gd` modified, uncommitted | Shiki | 5m |
| B2 | CI/CD workflows only on `feat/ci-workflows`, not on `main` | Root | 1h |
| B3 | `godot-export.yml` pins **Godot 4.2.2**; game is built on **4.4** → CI exports stale | Root | 30m |
| B4 | Web build `client/build/web/` is 20:28, predates WS + audio changes | Shiki | 1h |
| B5 | No server auth (/api/hello, /api/player, /api/save only) | Sentinel | 4h |
| B6 | `DEFAULT_HOST="127.0.0.1"` hardcoded in NetworkManager | Shiki+Sentinel | 1h |
| B7 | Player sprite still placeholder (slime/villager/ui icons real) | Mio | 4h |
| B8 | No monitoring/alerting/staging host | Root | ongoing |
| B9 | Monetization = 0 (no IAP/analytics/shop) | Business | — |

## ✅ DONE (verified feature set)

- Main menu → character creation → oakrest_village flow loads
- Player movement/camera/combat (directional, crits, combos, damage numbers)
- Oakrest Village: tilemap, NPC dialogue/shops/quests/services, monsters, zone transitions
- Save/load full serialization + pending data API
- Server.py WebSocket(9051) + REST(9052) + SQLite; Dockerfile + compose (server+postgres)
- Godot 4.4 headless loads; 7 JSON data files + en.json load

## 🎯 THE REAL 3-DAY PLAN (so everyone is in sync)

**Day 1 — Unify CI/CD + verify stack (Root/Shiki):**
1. Shiki: commit or revert `test_websocket_connection.gd` change
2. Root: merge `feat/ci-workflows` → `main` (so CI runs on push)
3. Root: bump `godot-export.yml` `GODOT_VERSION` 4.2.2 → 4.4 (template URL + container `barichello/godot-ci:4.4`)
4. Shiki+Sentinel: run WS test vs live server; confirm handshake + PONG

**Day 2 — Parallel content/infra:**
- Mio: player sprite (idle/walk 32x32)
- Sentinel: add `/api/register`, `/api/login`, session token, CORS, rate limit
- Shiki: re-export web `godot --headless --export-release "Web" build/web/index.html`

**Day 3 — Verify + sync point:**
- CI green (Linux/Windows/Web artifacts)
- Web build loads in browser; no missing resources
- WS handshake confirmed
- `DEFAULT_HOST` configurable for prod

## ⛔ Deploy/monetize GATE
- [ ] Player art not rectangles
- [ ] Real audio hooked (not silent) + import cache clean
- [ ] Auth + sessions + rate limits
- [ ] Monetization hook (IAP/shop + analytics)
- [ ] CI auto-export green on `main`

*Authoritative current-state: git status/branch/remote/ignore + godot headless + template dir + network_manager grep. Update as items flip.*
