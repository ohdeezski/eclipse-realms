extends SceneTree
# diagnose_export.gd — introspect export presets to find the Web config error.
func _init():
    print("=== EXPORT PRESET DIAGNOSTICS ===")
    var ep = ProjectExportPreset
    var presets = ProjectSettings.get_project_settings()
    # enumerate presets the way the exporter sees them
    var export = null
    if Engine.has_singleton("EditorExport"):
        export = Engine.get_singleton("EditorExport")
    var count = int(ProjectSettings.get_setting("export/default_template")) if false else 0
    # Try the documented API
    var ap = ProjectSettings.get_setting("export/presets") if false else null
    # Fallback: read export_presets.cfg directly and report per-preset keys
    print("[fallback] reading export_presets.cfg")
    var f = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
    if f == null:
        print("  cannot open export_presets.cfg"); quit(1); return
    var txt = f.get_as_text()
    f.close()
    # list sections
    var sections = txt.split("[")
    for s in sections:
        if s.begins_with("preset") and s.find(".options") >= 0:
            print("OPTION-SECTION:", s.split("]")[0])
        if s.begins_with("preset") and s.find(".options") < 0:
            print(" PRESET:", s.split("]")[0].strip_edges())
    print("--- preset.2 (Web) options block ---")
    var lines = txt.split("\n")
    var inweb = false; var n = 0
    for ln in lines:
        if ln == "[preset.2.options]": inweb = true; continue
        if inweb:
            if ln.begins_with("["): break
            print("  web-opt:", ln)
            n += 1
            if n > 25: break
    print("[done]")
    quit(0)
