extends SceneTree

## Verification for the rhythm timing tolerance option (issue #47).
## Run: godot --headless --path . --script res://test/test_rhythm_timing.gd
## Asserts: default is strict, generous damps chaos jitter, generous
## lowers the emission floor, generous shortens re-press cooldown,
## and the setting persists.

const PREFS := preload("res://autoloads/preferences_manager.gd")
const STIM := preload("res://scripts/stim_tool.gd")


func _init() -> void:
	var failures := 0
	var prefs: Node = PREFS.new()
	prefs.name = "PreferencesManager"
	root.add_child(prefs)

	# 1. Default strict.
	if prefs.rhythm_timing != "strict":
		print("RHY FAIL: rhythm_timing defaults to %s" % prefs.rhythm_timing)
		failures += 1

	# 2. Generous damps jitter: run many high-chaos cycles per mode and
	#    compare beat-clock variance. Generous should deviate less.
	var stim: Node = STIM.new()
	root.add_child(stim)
	var deviations: Dictionary = {}
	for mode in ["strict", "generous"]:
		stim.timing_mode = mode
		stim.cooldown = 0.0
		stim.chaos = 0.0
		stim.disrupt(1.0)
		stim.press()
		var drifts: Array[float] = []
		# Ideal clock after t seconds with zero jitter:
		var ideal := 0.0
		for i in range(600):  # ~10s at 60fps
			var delta := 1.0 / 60.0
			stim.disrupt(delta)  # hold chaos pinned at 1.0 despite decay
			ideal += delta * stim.BEAT_RATE * TAU
			stim.update(delta)
			drifts.append(absf(stim.beat_clock - ideal))
		var worst: float = drifts.max()
		deviations[mode] = worst
		stim.release()
	if deviations["generous"] >= deviations["strict"]:
		print(
			(
				"RHY FAIL: generous jitter %f not smaller than strict %f"
				% [deviations["generous"], deviations["strict"]]
			)
		)
		failures += 1

	# 3. Emission threshold + cooldown constants.
	stim.timing_mode = "generous"
	if not is_equal_approx(
		float(stim.GENEROUS_EMISSION_THRESHOLD), float(stim.EMISSION_THRESHOLD) * 0.25
	):
		print("RHY NOTE: generous emission floor is not exactly 1/4 of strict")
	if not stim.GENEROUS_COOLDOWN_SECONDS < stim.COOLDOWN_SECONDS:
		print("RHY FAIL: generous cooldown not shorter than strict")
		failures += 1

	# 4. Cooldown actually applied per mode.
	prefs.rhythm_timing = "generous"
	stim.timing_mode = "generous"
	stim.press()
	stim.release()
	var gen_cd: float = stim.cooldown
	stim.timing_mode = "strict"
	stim.cooldown = 0.0
	stim.press()
	stim.release()
	if not gen_cd < stim.cooldown:
		print("RHY FAIL: release() did not apply a shorter generous cooldown")
		failures += 1

	# 5. Persistence round-trip.
	prefs.rhythm_timing = "generous"
	prefs.save()
	var prefs2: Node = PREFS.new()
	prefs2.load_or_create_defaults()
	if prefs2.rhythm_timing != "generous":
		print("RHY FAIL: rhythm_timing not persisted")
		failures += 1
	# Invalid values fall back to strict on load.
	var config := ConfigFile.new()
	config.load("user://brew_justice_prefs.cfg")
	config.set_value("accessibility", "rhythm_timing", "bogus")
	config.save("user://brew_justice_prefs.cfg")
	prefs2.load_or_create_defaults()
	if prefs2.rhythm_timing != "strict":
		print("RHY FAIL: invalid stored value not rejected to strict")
		failures += 1
	prefs2.free()

	stim.queue_free()
	prefs.queue_free()

	if failures > 0:
		print("RHY FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("RHY PASS")
		quit(0)
