# Eclipse Realms - Web Export Process Documentation

## Overview
This document describes the process for exporting Eclipse Realms to Web platform using Godot 4.4.stable.

## Prerequisites
- Godot 4.4.stable installed and in PATH
- Export templates for 4.4.stable installed at `~/.local/share/godot/export_templates/4.4.stable/`

## Export Templates Setup

### Current Status
Export templates for 4.4.stable were not available from official downloads (corrupted archives). As a workaround, web export templates from 4.3.stable were copied:

```bash
mkdir -p ~/.local/share/godot/export_templates/4.4.stable/
cp ~/.local/share/godot/export_templates/4.3.stable/web_nothreads_debug.zip ~/.local/share/godot/export_templates/4.4.stable/
cp ~/.local/share/godot/export_templates/4.3.stable/web_nothreads_release.zip ~/.local/share/godot/export_templates/4.4.stable/
```

**Note:** These templates are from 4.3.stable and may have compatibility issues. Official 4.4.stable templates should be installed when available.

### Required Template Files
For Web export, the following templates are required:
- `web_nothreads_debug.zip` - Debug build template
- `web_nothreads_release.zip` - Release build template

## Export Configuration

### Export Preset (export_presets.cfg)
The project includes a "Web" export preset (preset.2) configured as:
- Platform: Web
- Export path: `build/web/index.html`
- Export filter: all_resources
- Script export mode: 2 (compiled)
- Canvas resize policy: 2 (viewport)
- Focus canvas on start: true
- Progressive Web App: disabled

### Web Export Options
Key web export options:
```ini
variant/extensions_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
```

## Build Command

### From Client Directory
```bash
cd "/home/ssmartnycbase/Desktop/StreetSmartNYC-BusinessBase/Obsidian-Vault/game-projects-(to monetize)/project-eclipse-realms/client"
godot --headless --export-release "Web" build/web/index.html
```

### Expected Output
Successful export produces these files in `build/web/`:
- `index.html` - Main HTML entry point
- `index.js` - JavaScript loader
- `index.wasm` - WebAssembly binary (~34 MB)
- `index.pck` - Packed game data (~3.8 MB)
- `index.png` - Application icon
- `index.icon.png` - Favicon
- `index.apple-touch-icon.png` - iOS home screen icon
- `index.audio.worklet.js` - Audio worklet
- `index.worker.js` - Web worker

## Known Issues & Workarounds

### 1. Missing Export Templates
**Issue:** Official 4.4.stable export templates download as corrupted archives.
**Workaround:** Copy templates from 4.3.stable installation.

### 2. Missing Font Resource
**Issue:** `res://assets/ui/fonts/default.tres` referenced in character_creation.tscn but missing.
**Fix:** Created placeholder font resource at `assets/ui/fonts/default.tres`

### 3. Test Scene Parse Errors
**Issue:** `test_runner.tscn` has parse error on line 1.
**Impact:** Non-blocking for export (scenes are included but show warnings)

### 4. TileSetPhysicsLayer Errors
**Issue:** Cannot get class 'TileSetPhysicsLayer' during export.
**Impact:** Non-blocking, appears to be a Godot 4.4 issue with tilemap export.

### 5. WebSocket API Changes
**Issue:** Godot 4.4 changed WebSocketMultiplayerPeer API signatures.
**Fixes Applied:**
- `create_client(url: String)` - takes WebSocket URL string
- `create_server(port: int, bind_address: String = "*")` - port first, then bind address

### 6. Export Preset "runnable" Warnings
**Issue:** "Couldn't find the given section preset.X and key runnable"
**Impact:** Non-blocking warnings, export still succeeds.

## Verification Steps

1. **Run Export Command**
   ```bash
   cd client && godot --headless --export-release "Web" build/web/index.html
   ```

2. **Check Output Files**
   ```bash
   ls -la build/web/
   ```

3. **Verify Key Files Exist**
   - index.html (entry point)
   - index.wasm (WebAssembly binary)
   - index.pck (game data)
   - index.js (loader)

4. **Test in Browser** (optional)
   Serve the build directory with a local HTTP server:
   ```bash
   cd build/web && python3 -m http.server 8080
   ```
   Then open http://localhost:8080

## Network Configuration for Web Export

The Web export uses WebSocketMultiplayerPeer for networking:
- Client connects to: `ws://localhost:9051` (or configured host/port)
- Server runs on: `0.0.0.0:9051` (WebSocket)
- Message format: JSON (matching server.py protocol)

## CI/CD Considerations

For automated builds:
1. Ensure Godot 4.4.stable is installed in CI environment
2. Install export templates (or copy from cache)
3. Run export command from client directory
4. Archive build/web/ directory as artifact

## Next Steps

1. **Official Templates:** Replace 4.3.stable templates with official 4.4.stable when available
2. **Font Resource:** Create proper font resource or use system font
3. **Test Scenes:** Fix test_runner.tscn parse error
4. **TileMap Export:** Investigate TileSetPhysicsLayer issue
5. **HTTPS/WSS:** Configure secure WebSocket for production deployment