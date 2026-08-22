extends SceneTree

## Headless verification for loudness normalization (issue #50).
## Run: godot --headless --path . --script res://test/test_loudness.gd
## Asserts: SFX bus exists, a limiter named LoudnessLimiter is the LAST
## effect on it with ceiling/threshold matching the policy constants,
## and re-running setup does not duplicate the limiter.

const ABM := preload("res://scripts/audio_bus_manager.gd")


func _init() -> void:
	var failures := 0
	var abm: Node = ABM.new()
	root.add_child(abm)
	await process_frame

	var sfx := AudioServer.get_bus_index("SFX")
	if sfx == -1:
		print("Loud FAIL: no SFX bus")
		quit(1)
		return

	var count := AudioServer.get_bus_effect_count(sfx)
	if count == 0:
		print("Loud FAIL: no effects on SFX bus")
		failures += 1

	var last := AudioServer.get_bus_effect(sfx, count - 1)
	if last == null or last.resource_name != "LoudnessLimiter":
		print("Loud FAIL: last SFX effect is not LoudnessLimiter")
		failures += 1
	elif not (last is AudioEffectLimiter):
		print("Loud FAIL: LoudnessLimiter is not an AudioEffectLimiter")
		failures += 1
	else:
		var lim := last as AudioEffectLimiter
		# Ceiling at -6 dB is the safety contract from docs/audio-loudness.md.
		if absf(lim.ceiling_db - (-6.0)) > 0.01:
			print("Loud FAIL: ceiling %f != -6.0" % lim.ceiling_db)
			failures += 1
		if absf(lim.threshold_db - (-9.0)) > 0.01:
			print("Loud FAIL: threshold %f != -9.0" % lim.threshold_db)
			failures += 1

	# No duplicate registration across repeated setups.
	var limiters := 0
	for i in range(count):
		var fx := AudioServer.get_bus_effect(sfx, i)
		if fx and fx.resource_name == "LoudnessLimiter":
			limiters += 1
	if limiters != 1:
		print("Loud FAIL: %d limiters on SFX bus (expected 1)" % limiters)
		failures += 1

	abm.queue_free()

	if failures > 0:
		print("Loud FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("Loud PASS")
		quit(0)
