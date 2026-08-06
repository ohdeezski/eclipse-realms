# Eclipse Realms — Team Continuation Plan (2-Day Sprint)

**Date:** 2026-08-04
**Status:** Phase 0.5 → Phase 1 (first playable) near completion; ready for polish & deployment.
**Lead:** Aeris (Project Manager)

---

## 1. CURRENT STATE (Verified Live)

| Area | Status | Key Points |
|------|--------|------------|
| **Protocol** | ✅ WebSocket 9051, ENet removed | Client ↔ server aligned |
| **Godot Engine** | ✅ 4.4.stable + templates | Headless load success |
| **Core Gameplay** | ✅ Menu → Character → World → Combat → Save | Functional loop |
| **Audio** | ✅ Imported (music, sfx, ambient) | Real OGG files |
| **Assets** | ⚠️ Mostly real | Player idle sprite present; walk/attack frames incomplete |
| **Quests** | ✅ `quests.json` and `quest_log.gd` ready | NPCs give quests |
| **Inventory** | ✅ `inventory.gd` functional | Drag‑drop, equip/unequip, stack handling |
| **HUD** | ✅ `hud.gd` active | Health, mana, gold, level bars |
| **Server** | ❌ Auth missing (`/api/register`, `/api/login`) | Only hello/player/save endpoints |
| **CI/CD** | ⚠️ `feat/ci-workflows` on `GitHub Actions`, Godot 4.2.2 | Needs bump to 4.4 and merge to `main` |
| **Web Build** | ⚠️ Stale (built 20:28) | Should be regenerated after audio/protocol changes |
| **Monetization** | ❌ No shop/analytics/IAP | Pipeline scaffolding missing |

---

## 2. REMAINING CRITICAL BLOCKERS (P0/P1)

| # | Blocker | Owner | Effort |
|---|--------|-------|--------|
| B1 | CI/CD workflow only on `feat/ci-workflows` and pins 4.2.2 | Root | 30m |
| B2 | Missing server auth (`/api/register`, `/api/login`, sessions) | Sentinel | 4h |
| B3 | Stale web build (`client/build/web/` last 20:28) | Shiki | 1h |
| B4 | Player walk/attack animation frames | Mio | 4h |
| B5 | Missing monetization hooks (IAP, analytics, store) | Business | Ongoing |
| B6 | No staged changes committed (`client/project.godot`, etc.) | Shiki | 5m |
| B7 | Web host setup, monitoring, backups | Root | Ongoing |

---

## 3. ROLE ASSIGNMENTS (48‑hour sprint)

### Day 1 (24 hours)

#### Shiki (Lead Dev) – Priority 1
- **Task:** Commit staged changes (`client/project.godot`, `client/scenes/main_menu/main_menu.tscn`, `client/tests/test_ws_connection.gd`).
- **Action:** `git add . && git commit -m "feat: finalize WebSocket migration & protocol alignment"`.
- **Deliverable:** Clean feature branch with all core changes.

#### Root (DevOps) – Priority 2
- **Task:** Merge `feat/ci-workflows` → `main`; update `Godot_VERSION = 4.4` in `.github/workflows/godot-export.yml`.
- **Action:** Git operations and CI configuration update.
- **Deliverable:** `main` branch with working CI that references correct Godot version.

#### Sentinel (Backend) – Priority 3
- **Task:** Implement `/api/register` and `/api/login` (simple token/session); add CORS, rate limiting; verify existing endpoints (`/api/hello`, `/api/save`) work.
- **Action:** Add routes in `server/server.py`; run local tests.
- **Deliverable:** Functional auth layer on `server.py`.

#### Mio (Assets/QA) – Priority 4
- **Task:** Add player walk/attack animation frames; integrate into `player.gd` (AnimationPlayer).
- **Action:** Create new PNGs (or import existing), wire up states; test visually.
- **Deliverable:** Player sprite cycles for idle, walk, attack.

#### Shiki (parallel) – Priority 5
- **Task:** Regenerate web build (`godot --headless --export-release "Web" build/web/index.html`).
- **Action:** Run from `client/` using Godot 4.4.
- **Deliverable:** Fresh `client/build/web/` reflecting latest audio and protocol changes.

#### Root (parallel) – Priority 6
- **Task:** Deploy web build to hosting (Vercel or Netlify) – choose one.
- **Action:** Create repo, configure static site, push build.
- **Deliverable:** Public-facing web build URL.

#### Sentinel (parallel) – Priority 7
- **Task:** Add server health check (`/api/health`) and logging.
- **Action:** Simple `/api/health` endpoint returning `{ status: "ok", service: "Eclipse Realms Server", version: "0.1.0" }`.

### Day 2 (24 hours)

#### All Hands – Cross‑team verification
- **Shiki:** Run end‑to‑end test (menu → character → village → combat → save/load) on local Godot.
- **Mio:** UI polish – adjust HUD layout, inventory drag‑and‑drop, quest log formatting.
- **Sentinel:** Verify WebSocket connection from Python client; simulate player movement in server.
- **Root:** CI integration – trigger build on `main` push; ensure Windows, Linux, Web artifacts generated.
- **Aeris (PM):** Update `docs/TEAM_STATUS.md` with daily progress; risk log; flag any blockers.
- **Tomoe (Exec):** Review final status; authorize `Phase 1` sign‑off.

#### Final Verification Checklist
- [ ] `git status --short` shows no uncommitted changes (except docs updates).
- [ ] CI passes on `main` (Linux/Windows/Web).
- [ ] Web build loads in browser, no missing resources.
- [ ] Player animations visible (idle, walk, attack).
- [ ] Auth endpoints (`/api/register`, `/api/login`, `/api/save`) functional.
- [ ] Save/load persistence tested.
- [ ] Server health endpoint present.
- [ ] Deployment target (hosting) accessible.

---

## 4. PUBLICATION & MONETIZATION PIPELINE (Week 2+)

**Platform:** Itch.io + Steam + Mobile (Android/iOS) – start with Itch.io as fastest launch.

**Immediate Actions (Week 2):**
1. Create Itch.io developer account; upload Linux/Windows builds (desktop).
2. Draft store description, screenshots, video trailer (record gameplay).
3. Set up analytics (Google Analytics, Mixpanel) – minimal tracking for funnel.
4. Plan cosmetic shop (skins, mounts, emotes) – using external service (Gumroad, Ko-fi) for simplicity.
5. Launch early‑access campaign; collect emails for beta wait‑list.

**Month 1 Goals:**
- 10,000+ downloads on Itch.io (early adopters).
- 50+ player feedback loops.
- First cosmetic skin sale (pre‑order).

**Month 2 Goals:**
- Steam submission (verify DRM, requirements).
- Mobile (Android) build (WebView wrapper).
- Expand server capacity (SQLite → PostgreSQL if needed).

---

## 5. COORDINATION PROTOCOL

- **Primary communication:** Updates to `docs/TEAM_STATUS.md` and `docs/TEAM_SYNC_STEP_1.md`.
- **Daily stand‑up:** 10:00 EST via chat (summary of yesterday’s work and today’s plan).
- **Blocker handling:** If any blocker extends beyond 8 hours, flag in `docs/TEAM_STATUS.md` under “Open Blockers” with owner and ETA.
- **Decision‑making:** Aeris (PM) resolves conflicts; Tomoe (Exec) approves scope changes.
- **Tooling:** Use `git` for version control; `github.com` for CI; `godotengine.org` for game builds.

---

## 6. IMMEDIATE ACTION (Next 2 Hours)

**Schedule:**
1. **0‑30 min:** Shiki commits staged changes.
2. **30‑60 min:** Root merges CI workflow and updates Godot version.
3. **60‑120 min:** Sentinel adds auth endpoints.
4. **120‑180 min:** Mio adds player animation frames.
5. **180‑240 min:** Shiki regenerates web build; Root deploys to host.

**Command line examples (execute in order):**
```bash
# 1. Commit staged changes
cd /home/ssmartnycbase/Desktop/StreetSmartNYC-BusinessBase/Obsidian-Vault/game-projects-(to monetize)/project-eclipse-realms
git add client/project.godot client/scenes/main_menu/main_menu.tscn client/tests/test_ws_connection.gd
git commit -m "feat: finalize WebSocket migration & protocol alignment" --author="Agent Zero <agent.zero@example.com>"

# 2. Merge feature into main
git checkout main
git merge feat/ci-workflows
# Update CI workflow
git diff HEAD~1 -- .github/workflows/godot-export.yml | less
git checkout main
# Apply changes
sed -i 's/GODOT_VERSION: 4.2.2/GODOT_VERSION: 4.4/' .github/workflows/godot-export.yml
# Also update the container image line
sed -i 's/barichello\/godot-ci:4.2.2/barichello\/godot-ci:4.4/' .github/workflows/godot-export.yml
git add .github/workflows/godot-export.yml
git commit -m "chore: bump Godot version to 4.4"
git push origin main

# 3. Add auth endpoints (Sentinel)
# Edit server/server.py, add /api/register and /api/login (simplified)
# Use a simple in‑memory token store for demo

# 4. Regenerate web build (Shiki)
godot --headless --export-release "Web" client/build/web/index.html

# 5. Deploy to host (Root) – placeholder, use Vercel CLI
vercel deploy client/build/web --prod

# 6. Update team status docs
echo "$(date '+%Y-%m-%d %H:%M:%S') – Sprint Day 1 completed" >> docs/TEAM_STATUS.md
```

---

## 7. FINAL REMARKS

The team is in an advanced state; the remaining work is largely CI, auth, assets, and publishing. By following this plan, we can ship a functional first‑playable build within **48 hours** and begin monetizing in **Week 2**.

Let’s start with committing the staged changes (Step 1) and proceed sequentially.

**Next command:** Would you like me to execute the staged commit for Shiki?

---

*Document generated by Agent Zero for Eclipse Realms R‑Team coordination.*
