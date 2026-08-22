extends SceneTree

## Wiring-doc drift guard (issue #35, stretch goal).
## Asserts that WIRING.md's documented actions, signals, and connections
## still match what focus_mode_main.gd actually wires. Run headless:
##   godot --headless --path . --script res://test/test_wiring_doc.gd
## Exit 0 = doc matches code; exit 1 = drift (or missing wiring).

var _failures: Array[String] = []


func _init() -> void:
	var doc := _read_doc()
	if doc == "":
		print("WIRING FAIL: cannot read WIRING.md")
		quit(1)
		return

	var script_src := _read_file("res://scripts/focus_mode_main.gd")
	var audio_src := _read_file("res://scripts/audio_bus_manager.gd")
	var main_script: GDScript = load("res://scripts/focus_mode_main.gd")

	# 1. Every InputMap registration in the code appears in the doc's action table.
	for action in _registered_actions(script_src):
		if not doc.contains("`%s`" % action):
			_failures.append("action `%s` is wired in code but missing from WIRING.md" % action)

	# 2. Every documented source->target connection exists as a connect() in code.
	for conn in _documented_connections(doc):
		var pattern := "%s.connect(%s)" % [conn[0], conn[1]]
		if not script_src.contains(pattern):
			_failures.append("doc claims %s -> but code has no '%s'" % [conn[0], pattern])

	# 3. Every connect() target in focus_mode_main.gd appears in the doc.
	for handler in _connected_handlers(script_src):
		if not doc.contains(handler):
			_failures.append("code connects to `%s` but WIRING.md omits it" % handler)

	# 4. AudioBusManager creates SFX bus + three filters, as documented.
	for needle in ["add_bus()", "AudioEffectLowPassFilter", "AudioEffectHighPassFilter", "AudioEffectBandPassFilter"]:
		if not audio_src.contains(needle):
			_failures.append("audio_bus_manager.gd lost expected wiring: %s" % needle)

	# 5. Live scene check: instantiate the real scene and verify documented
	#    nodes exist (only possible if scene loads).
	var scene_res := load("res://scenes/focus_mode.tscn")
	if scene_res:
		var scene: Node = (scene_res as PackedScene).instantiate()
		get_root().add_child(scene)
		for i in range(5):
			await process_frame
		for node_name in ["AudioBusManager", "SensoryCanvas", "Disruptor", "DisruptionOverlay", "ObserverLight", "NpcRegular", "SceneView", "AmbientAudio"]:
			if scene.find_child(node_name, true, false) == null:
				_failures.append("scene node documented in WIRING.md missing: %s" % node_name)
		for sig in ["reset_requested", "investigation_passed", "investigation_blocked", "world_listeners_updated", "calm_changed"]:
			if not scene.has_signal(sig):
				_failures.append("outbound signal documented in WIRING.md missing: %s" % sig)
		scene.queue_free()
	else:
		_failures.append("focus_mode.tscn failed to load")

	if _failures.is_empty():
		print("WIRING PASS: WIRING.md matches the code")
		quit(0)
	else:
		for f in _failures:
			print("WIRING FAIL: " + f)
		quit(1)


func _read_doc() -> String:
	return _read_file("res://../../WIRING.md")


func _read_file(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()


func _registered_actions(src: String) -> Array[String]:
	var out: Array[String] = []
	var re := RegEx.new()
	re.compile("_input_map_add_or_replace\\(\"([a-z_]+)\"")
	for m in re.search_all(src):
		out.append(m.get_string(1))
	return out


func _documented_connections(doc: String) -> Array:
	# Parse rows like: | `StimTool.stim_released` | `_on_stim_released` |
	var out := []
	var re := RegEx.new()
	re.compile("\\|\\s*`([A-Za-z_]+\\.[a-z_]+)`\\s*\\|\\s*`(_[a-z_]+)`\\s*\\|")
	for m in re.search_all(doc):
		var sig := m.get_string(1).split(".")
		out.append([sig[1], m.get_string(2)])
	return out


func _connected_handlers(src: String) -> Array[String]:
	var out: Array[String] = []
	var re := RegEx.new()
	re.compile("connect\\(([A-Za-z_]+)")
	for m in re.search_all(src):
		out.append(m.get_string(1))
	return out
