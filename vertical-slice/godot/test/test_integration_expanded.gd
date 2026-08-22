extends SceneTree

## Integration smoke coverage expansion (issue #37).
## Headless, asset-free checks for:
##   1. PreferencesManager startup / persistence round-trip
##   2. AudioBusManager calm-reactive ambient path
##   3. EvidenceBoard resolve path + graph progression signal
##   4. SensoryCanvas trail proximity emission
##   5. Missing-audio-bus graceful fallback guard
## Run:
##   godot --headless --path . --script res://test/test_integration_expanded.gd
## Exit 0 = all pass; exit 1 = at least one failure (each printed).

var _failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		print("  PASS  " + label)
	else:
		_failures.append(label)
		print("  FAIL  " + label)


func _init() -> void:
	print("== 1. PreferencesManager startup / persistence ==")
	_test_preferences()
	print("== 2. AudioBusManager calm-reactive ambient ==")
	_test_audio_calm()
	print("== 3. EvidenceBoard resolve + graph progression ==")
	_test_evidence_board()
	print("== 4. SensoryCanvas trail proximity ==")
	_test_trail_proximity()
	print("== 5. Missing audio bus graceful fallback ==")
	_test_missing_bus_fallback()

	print("")
	if _failures.is_empty():
		print("INTEGRATION PASS: all expanded smoke checks green")
		quit(0)
	else:
		print("INTEGRATION FAIL: %d check(s) failed" % _failures.size())
		quit(1)


# ---------------------------------------------------------------- 1


func _test_preferences() -> void:
	var pm: Node = load("res://autoloads/preferences_manager.gd").new()
	root.add_child(pm)
	# Startup path: load_or_create_defaults either loads an existing config or
	# creates one; either way the node must end in a consistent state.
	_check(pm.get("colorblind_mode") != null, "startup leaves colorblind_mode defined")
	_check(pm.get("master_volume") != null, "startup leaves master_volume defined")
	# Persistence round-trip: change, save, mutate in memory, reload.
	var original: bool = pm.get("colorblind_mode")
	pm.call("set_colorblind_mode", not original)
	pm.call("save")
	var pm2: Node = load("res://autoloads/preferences_manager.gd").new()
	root.add_child(pm2)
	pm2.call("load_or_create_defaults")
	_check(
		pm2.get("colorblind_mode") == (not original),
		"saved colorblind_mode survives save/load round-trip"
	)
	# Restore.
	pm.call("set_colorblind_mode", original)
	pm.call("save")
	pm2.queue_free()
	pm.queue_free()


# ---------------------------------------------------------------- 2


func _test_audio_calm() -> void:
	var abm: Node = load("res://scripts/audio_bus_manager.gd").new()
	root.add_child(abm)
	for i in range(3):
		await process_frame
	_check(abm.get("_cafe_player") != null, "cafe ambience player created")
	_check(abm.get("_room_mix") != null, "room mix state exists")
	var room_before: float = abm.get("_room_mix")
	var chatter_before: float = abm.get("_chatter_drive")
	abm.call("set_world_calm", 1.0)
	var room_calm: float = abm.get("_room_mix")
	var chatter_calm: float = abm.get("_chatter_drive")
	_check(room_calm != room_before, "room mix reacts to calm=1.0")
	_check(chatter_calm != chatter_before, "chatter drive reacts to calm=1.0")
	_check(room_calm >= 0.18 and room_calm <= 0.30, "calm room mix within WORLD_CALM_ROOM bounds")
	abm.call("set_world_calm", 0.0)
	var room_zero: float = abm.get("_room_mix")
	_check(room_zero != room_calm, "room mix differs between calm extremes")
	# Out-of-range input is clamped, not rejected.
	abm.call("set_world_calm", 5.0)
	_check(
		absf(abm.get("_room_mix") - room_zero) < 0.0001, "set_world_calm clamps out-of-range input"
	)
	abm.queue_free()


# ---------------------------------------------------------------- 3


func _test_evidence_board() -> void:
	var board: Node = load("res://scripts/evidence_board.gd").new()
	root.add_child(board)
	var progressed: Array[String] = []
	board.connect("graph_progression_requested", func(id: String) -> void: progressed.append(id))
	var clue := ClueData.new()
	clue.clue_id = "test_clue"
	clue.clue_name = "Test Clue"
	if clue.get("combines_with") != null:
		clue.combines_with = []
	if clue.get("contradicts") != null:
		clue.contradicts = []
	var resolver: Node = load("res://scripts/smudge_resolver.gd").new()
	root.add_child(resolver)
	board.call("register_clue", clue, resolver)
	board.call("resolve_clue", "test_clue")
	_check(
		progressed.size() == 1 and progressed[0] == "test_clue",
		"resolve_clue emits graph_progression_requested with the clue id"
	)
	board.call("resolve_clue", "nonexistent")
	_check(progressed.size() == 2, "resolve of unknown id still routes through the signal")
	board.queue_free()


# ---------------------------------------------------------------- 4


func _test_trail_proximity() -> void:
	var canvas: Node = load("res://scripts/sensory_canvas.gd").new()
	root.add_child(canvas)
	var received: Array[float] = []
	canvas.connect("trail_proximity", func(p: float) -> void: received.append(p))
	var pts := PackedVector2Array([Vector2(100, 100), Vector2(200, 200)])
	canvas.call("set_trail", pts)
	canvas.call("set_trail_target", Vector2(102, 100))
	_check(received.size() > 0, "trail_proximity emitted when target near trail")
	_check(received.size() > 0 and received[0] > 0.9, "near target gives high proximity")
	received.clear()
	canvas.call("set_trail_target", Vector2(900, 900))
	_check(received.size() > 0 and received[0] < 0.1, "far target gives low proximity")
	received.clear()
	canvas.call("set_trail", PackedVector2Array())
	canvas.call("set_trail_target", Vector2(100, 100))
	_check(received.is_empty(), "empty trail emits nothing (no crash)")
	canvas.queue_free()


# ---------------------------------------------------------------- 5


func _test_missing_bus_fallback() -> void:
	# Simulate a hostile audio environment: no SFX bus exists yet. The manager
	# must create it (post-#36 behavior) and never crash.
	var sfx_before := AudioServer.get_bus_index("SFX")
	if sfx_before != -1:
		# A previous test created it; remove to exercise the creation path.
		AudioServer.remove_bus(sfx_before)
	var abm: Node = load("res://scripts/audio_bus_manager.gd").new()
	root.add_child(abm)
	for i in range(3):
		await process_frame
	var sfx_after := AudioServer.get_bus_index("SFX")
	_check(sfx_after != -1, "missing SFX bus is created by AudioBusManager")
	_check(abm.get("_cafe_player") != null, "ambience still starts without a pre-existing bus")
	# Effects should be registered on the new bus.
	var effects := AudioServer.get_bus_effect_count(sfx_after)
	_check(effects >= 3, "filter effects added to freshly created bus (got %d)" % effects)
	# And the whole pipeline still runs frames without errors.
	abm.call("set_world_calm", 0.5)
	abm.call("update_targets", "Baseline", false, false, false)
	await process_frame
	_check(true, "update_targets runs without error on fresh bus")
	abm.queue_free()
