# Eclipse Realms — LIVE TEAM STATUS BOARD

**Single source of truth.** Read this first. Update it when your status changes.
Last refresh: 2026-08-03 23:25 EDT by Agent Zero (live-verified).

---

## 1. VERIFIED LIVE STATE (evidence-backed)

| Area | Status | Evidence |
|------|--------|----------|
| Branch being worked | `feat/ci-workflows` | `git branch --show-current` |
| Uncommitted (3 files) | `client/project.godot`, `client/scenes/main_menu/main_menu.tscn`, `client/tests/test_ws_connection.gd` | `git status --short` |
| Protocol | ✅ WebSocketMultiplayerPeer port 9051 | `grep` on network_manager.gd |
| Godot engine | ✅ v4.4.stable | `~/bin/godot`, headless load exit 0 |
| Export templates | ✅ 4.2.2 / 4.3 / 4.4 | `~/.local/share/godot/export_templates/` |
| GitHub remote | ✅ ohdeezski/eclipse-realms | `git remote -v` |
| CI workflows | ⚠️ on feat/ci-workflows, godot-export pins **4.2.2** (game is 4.4) | `.github/workflows/` |
| Server | ✅ boots; WS 9051 + REST 9052 + SQLite; `/api/hello` ok | `server/server.py`, live curl |
| Server venv | ✅ `server/venv` (Python 3.13 host) | file tree |
| Assets | ⚠️ Audio real OGG; slime/villager/UI icons real; **player_idle.png now added**; walk/attack frames still TODO | file tree |
| Web build | ⚠️ exists; may be stale vs audio/protocol changes | `client/build/web/` |

## 2. ROLE STATUS BOARD

| Role | Status | Current work | Next action |
|------|--------|--------------|-------------|
| Aeris (PM) | 🟢 | Tracking milestone; owner of checklists | Keep TEAM_STATUS.md current; enforce daily 10:00 EST check-in |
| Tomoe (Exec OS) | 🟢 | Oversight/reality audits | Review this board each sync; flag stale claims |
| Shiki (Lead Dev) | 🟢 | Finished WebSocket migration (ENet→WS) + tests on branch | Commit 3 dirty files; verify WS test passes vs live server |
| Mio (Assets/QA) | 🟢 | player_idle.png done; audio real | Add walk/attack frames; test inventory/character UI; confirm sprites in-game |
| Sentinel (Backend) | 🟢 | server.py + Docker + SQLite done | Add auth routes (`/api/register`, `/api/login`, sessions, CORS, rate limit); run WS handshake with Shiki |
| Root (DevOps) | 🟢 | Workflows added on feat/ci-workflows | Merge `feat/ci-workflows`→`main`; bump CI Godot 4.2.2→4.4; deploy host + monitoring |
| Agent Zero (me) | 🟢 | Auditing + team sync docs | Execute tasks the team assigns; keep this board updated on every verified change |

## 3. REAL OPEN BLOCKERS (ordered)

| # | Blocker | Owner | Est. |
|---|--------|-------|------|
| B1 | 3 dirty files uncommitted | Shiki | 5m |
| B2 | CI only on feat/ci-workflows, not main | Root | 1h |
| B3 | CI workflow pins Godot 4.2.2; game on 4.4 | Root | 30m |
| B4 | Web build possible stale | Shiki | 1h |
| B5 | No server auth/sessions/CORS/rate-limit | Sentinel | 4h |
| B6 | DEFAULT_HOST="127.0.0.1" hardcoded | Shiki+Sentinel | 1h |
| B7 | Player animations (walk/attack) + in-game verify | Mio | 4h |
| B8 | No staging host/monitoring/alerting | Root | ongoing |
| B9 | Monetization (IAP/analytics/shop) = 0 | Business | — |

## 4. NEXT 3 DAYS (sync plan)

- **Day 1:** B1 commit (Shiki); B2+B3 merge branch + bump CI (Root); WS handshake test (Shiki+Sentinel).
- **Day 2:** B7 player anims (Mio); B5 auth (Sentinel); B4 web re-export (Shiki).
- **Day 3:** Sync/verify — CI green, web loads in browser, WS confirmed, host configurable.

## 5. UPDATE PROTOCOL (how we stay in sync)

1. **Before starting work:** read this board.
2. **After finishing a task:** update your row + blockers, commit if code touched.
3. **Daily 10:00 EST check-in:** post your row's status (status channel or this file).
4. **Anyone sees a stale claim:** fix it in this file immediately with evidence.
5. **Agent Zero:** refreshes this board from live `git/status/runtime` probes whenever asked to audit.

---
*Docs feeding this board: TEAM_SYNC_STEP_1.md, REALIGNMENT_CHECKPOINT.md, WEB_EXPORT_PROCESS.md.*
