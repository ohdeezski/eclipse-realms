# Repository Guidelines

## Project Structure & Module Organization
- **./client**: Godot 4.x game client. Logic is primarily in GDScript within `res://scripts/`. Singletons (Autoloads) like `GameManager`, `NetworkManager`, and `InputManager` handle core systems.
- **./server**: Python-based backend using `websockets` and `aiohttp`. Entry point is `./server/server.py`.
- **./shared**: Contains data schemas and game data intended for both client and server.
- **./docs**: Centralized documentation hub. Start with `./docs/00_MASTER_INDEX.md`.
- **./tools**: Utility scripts for asset generation (e.g., `./create_sprites.py`, `./generate_tileset.py`).

## Build, Test, and Development Commands
### Client
- **Run Client**: `godot --path client/`
- **Run Headless Test**: `godot --headless --path client/ --script res://tests/test_websocket_connection.gd --test`
- **Run Test Script**: `./run_test.sh`
- **Export (Windows)**: `godot --export-release windows --path client/ ../builds/windows/EclipseRealms.exe`

### Server
- **Run Server**: `python3 server/server.py`
- **Install Dependencies**: `pip install -r server/requirements.txt`

## Coding Style & Naming Conventions
- **GDScript**: Follow Godot 4.x idioms. Use `match` for branching, `is` for type checks, and `@onready` for node references.
- **Python**: Standard PEP 8 conventions.
- **Naming**: 
  - Scripts/Scenes: `snake_case.gd` / `snake_case.tscn`
  - Node names: `PascalCase`
  - Variables/Functions: `snake_case`

## Testing Guidelines
- **Client Tests**: Located in `./client/tests/`. Run via Godot CLI with the `--script` flag.
- **Integration**: Use `./run_test.sh` to verify WebSocket connectivity between client and server.

## Commit Guidelines
- Use descriptive prefixes: `fix:`, `feat:`, `chore:`, `docs:`, `art:`.
- Some historical commits use short capital prefixes (e.g., `F:`, `E:`, `D:`) or sprint identifiers (e.g., `WS-1:`), but `feat:`/`fix:` is preferred for standard changes.
- Example: `fix: inventory icon path (unblock 9 of 18 item icons)`
