extends SceneTree

## Headless smoke runner: instantiates the real focus-mode scene, steps a few
## frames, pokes core signals, and reports PASS/FAIL on stdout (issue #36).


func _init() -> void:
	var failures: Array[String] = []
	var scene_res := load("res://scenes/focus_mode.tscn")
	if scene_res == null:
		print("SMOKE FAIL: cannot load scenes/focus_mode.tscn")
		quit(1)
		return
	var scene: Node = (scene_res as PackedScene).instantiate()
	get_root().add_child(scene)
	for i in range(12):
		await process_frame
	# Structural checks mirroring test_focus_mode_smoke.gd's before_each.
	for node_path in [
		"Disruptor", "DisruptionOverlay", "ObserverLight", "NpcRegular", "AmbientAudio"
	]:
		if scene.find_child(node_path, true, false) == null:
			failures.append("missing node: " + node_path)
	for sig in [
		"reset_requested", "investigation_passed", "world_listeners_updated", "calm_changed"
	]:
		if not scene.has_signal(sig):
			failures.append("missing signal: " + sig)
	var ambient := scene.find_child("AmbientAudio", true, false) as AudioStreamPlayer2D
	if ambient and ambient.stream == null:
		failures.append("AmbientAudio has no runtime stream")
	# Signal-reaction check: chaos pulse must move overlay chaos.
	var overlay := scene.find_child("DisruptionOverlay", true, false)
	var disruptor := scene.find_child("Disruptor", true, false)
	if overlay and disruptor:
		var before: float = overlay.get("chaos")
		disruptor.chaos_pulse.emit(0.5)
		for i in range(3):
			await process_frame
		var after: float = overlay.get("chaos")
		if not (after > before):
			failures.append("chaos_pulse did not raise overlay.chaos")
	# Simulated frames for stability (no errors tolerated; parse already proven).
	for i in range(30):
		await process_frame
	if failures.is_empty():
		print("SMOKE PASS: all checks green")
		quit(0)
	else:
		for f in failures:
			print("SMOKE FAIL: " + f)
		quit(1)
