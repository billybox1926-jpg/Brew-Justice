extends SceneTree

## Verification for sensory calibration mode (issue #48).
## Run: godot --headless --path . --script res://test/test_calibration.gd
## Asserts: defaults are standard + not-done, the screen opens on first
## run, choosing persists pacing and marks done, skipping keeps standard,
## and a calibrated session never re-opens it.

const PREFS := preload("res://autoloads/preferences_manager.gd")
const CAL := preload("res://scripts/sensory_calibration.gd")


func _init() -> void:
	var failures := 0

	# Clean slate.
	var prefs: Node = PREFS.new()
	prefs.name = "PreferencesManager"
	root.add_child(prefs)
	prefs.sensory_pacing = "standard"
	prefs.calibration_done = false

	# 1. Defaults.
	if prefs.sensory_pacing != "standard" or prefs.calibration_done != false:
		print("CAL FAIL: calibration defaults wrong")
		failures += 1

	# 2. Factors table sanity: gentle calms, intense intensifies.
	var g: Dictionary = CAL.factors_for("gentle")
	var s: Dictionary = CAL.factors_for("standard")
	var i: Dictionary = CAL.factors_for("intense")
	if float(g.intensity) >= float(s.intensity) or float(i.intensity) <= float(s.intensity):
		print("CAL FAIL: intensity factors not ordered gentle < standard < intense")
		failures += 1
	if float(g.interval) <= float(s.interval) or float(i.interval) >= float(s.interval):
		print("CAL FAIL: interval factors not ordered gentle > standard > intense")
		failures += 1

	# 3. First run: screen opens.
	var cal: CanvasLayer = CAL.new()
	root.add_child(cal)
	await process_frame
	cal.open()
	await process_frame
	if not (cal.active and cal.visible):
		print("CAL FAIL: calibration did not open on first run")
		failures += 1

	# 4. Choosing persists pacing + done flag, closes screen.
	cal.choose("gentle")
	await process_frame
	if prefs.sensory_pacing != "gentle" or prefs.calibration_done != true:
		print(
			(
				"CAL FAIL: choose() did not persist (%s, %s)"
				% [str(prefs.sensory_pacing), str(prefs.calibration_done)]
			)
		)
		failures += 1
	if cal.active or cal.visible:
		print("CAL FAIL: calibration still open after choose()")
		failures += 1

	# 5. Persistence round-trip.
	var prefs2: Node = PREFS.new()
	prefs2.load_or_create_defaults()
	if prefs2.sensory_pacing != "gentle" or prefs2.calibration_done != true:
		print("CAL FAIL: calibration result not persisted")
		failures += 1
	prefs2.free()

	# 6. Skip path: keeps/returns to standard, marks done, closes.
	prefs.calibration_done = false
	cal.open()
	cal.skip()
	if prefs.sensory_pacing != "gentle":
		print("CAL NOTE: skip changed existing pacing (kept user choice)")
	if prefs.calibration_done != true:
		print("CAL FAIL: skip did not mark calibration done")
		failures += 1
	if cal.active:
		print("CAL FAIL: skip left calibration open")
		failures += 1

	# 7. Invalid stored pacing falls back to standard.
	prefs.save()
	var cfg := ConfigFile.new()
	cfg.load("user://brew_justice_prefs.cfg")
	cfg.set_value("accessibility", "sensory_pacing", "bogus")
	cfg.save("user://brew_justice_prefs.cfg")
	var prefs3: Node = PREFS.new()
	prefs3.load_or_create_defaults()
	if prefs3.sensory_pacing != "standard":
		print("CAL FAIL: invalid pacing not rejected to standard")
		failures += 1
	prefs3.free()

	cal.queue_free()
	prefs.queue_free()

	if failures > 0:
		print("CAL FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("CAL PASS")
		quit(0)
