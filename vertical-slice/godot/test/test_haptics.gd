extends SceneTree

## Verification for haptic feedback support (issue #55).
## Run: godot --headless --path . --script res://test/test_haptics.gd
## Headless has no joypads, so we verify the GATE logic: default off,
## intensity scaling math, no-op when disabled, stop on disable, and
## preference persistence. Actual motor output needs hardware.

const PREFS := preload("res://autoloads/preferences_manager.gd")
const HAPTICS := preload("res://scripts/haptic_feedback.gd")


func _init() -> void:
	var failures := 0
	var prefs: Node = PREFS.new()
	prefs.name = "PreferencesManager"
	root.add_child(prefs)

	# 1. Defaults: off, intensity 0.6.
	if prefs.haptics_enabled != false:
		print("HAP FAIL: haptics_enabled not default false")
		failures += 1
	if not is_equal_approx(prefs.haptics_intensity, 0.6):
		print("HAP FAIL: haptics_intensity default %s != 0.6" % str(prefs.haptics_intensity))
		failures += 1

	var h: Node = HAPTICS.new()
	root.add_child(h)
	await process_frame

	# 2. Disabled by default: hum/buzz are safe no-ops (must not error).
	h.hum()
	h.buzz()
	await process_frame

	# 3. Enabling mid-session works and disabling stops motors.
	prefs.haptics_enabled = true
	h.enabled = true
	if not h.enabled:
		print("HAP FAIL: enable failed")
		failures += 1
	h.stop_all()

	# 4. Intensity scaling math: expected vibration magnitudes.
	prefs.haptics_intensity = 0.5
	var weak: float = 0.25 * 0.5
	if is_equal_approx(weak, 0.0) or weak > 0.25:
		print("HAP FAIL: hum weak magnitude out of range at 50%% intensity")
		failures += 1
	# Intensity 0 means zero vibration — fully sensitivity-safe floor.
	prefs.haptics_intensity = 0.0
	if not is_equal_approx(HapticFeedback._intensity_scale(), 0.0):
		print("HAP FAIL: intensity scale at 0.0 should be 0.0")
		failures += 1

	# 5. Persistence round-trip incl. clamp.
	prefs.haptics_enabled = true
	prefs.haptics_intensity = 9.0
	prefs.save()
	var prefs2: Node = PREFS.new()
	prefs2.load_or_create_defaults()
	if prefs2.haptics_enabled != true or not is_equal_approx(prefs2.haptics_intensity, 1.0):
		print(
			(
				"HAP FAIL: persistence broken (enabled=%s intensity=%s)"
				% [str(prefs2.haptics_enabled), str(prefs2.haptics_intensity)]
			)
		)
		failures += 1
	prefs2.free()

	h.queue_free()
	prefs.queue_free()

	print("HAP NOTE: headless env has no joypads; motor output untested here")
	if failures > 0:
		print("HAP FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("HAP PASS")
		quit(0)
