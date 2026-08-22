extends SceneTree

## Verification for the visual beat pulsar (issue #49).
## Run: godot --headless --path . --script res://test/test_beat_pulsar.gd
## Asserts: opt-in default off, hidden while disabled, fires on
## rhythm_pulse when enabled, intensity scales opacity, fades back out,
## reduced_motion uses fade-only (no scale animation), and the
## preference persists.

const PREFS := preload("res://autoloads/preferences_manager.gd")
const PULSAR := preload("res://scripts/beat_pulsar.gd")


func _init() -> void:
	var failures := 0
	var prefs: Node = PREFS.new()
	prefs.name = "PreferencesManager"
	root.add_child(prefs)

	# 1. Default OFF.
	if prefs.beat_pulsar_enabled != false:
		print("PUL FAIL: beat_pulsar_enabled not default false")
		failures += 1

	var p: Control = PULSAR.new()
	root.add_child(p)
	await process_frame

	# 2. Disabled: on_beat is a no-op (stays invisible).
	p.on_beat(1.0)
	await process_frame
	if p.visible or p.ring.modulate.a > 0.0:
		print("PUL FAIL: pulsed while disabled")
		failures += 1

	# 3. Enabled: pulse shows at intensity-scaled alpha and signals.
	p.fade_out_seconds = 5.0  # slow the fade so the alpha check isn't racing it
	p.enabled = true
	if not p.visible:
		print("PUL FAIL: still hidden after enable")
		failures += 1
	var fired := [0]
	p.shown.connect(func() -> void: fired[0] += 1)
	p.on_beat(0.8)
	await process_frame
	if fired[0] != 1:
		print("PUL FAIL: shown signal count %d != 1" % fired[0])
		failures += 1
	if absf(p.ring.modulate.a - clampf(0.8, 0.25, 1.0)) > 0.05:
		print("PUL FAIL: alpha %f != intensity-scaled target" % p.ring.modulate.a)
		failures += 1

	# 4. Fades back to invisible after the fade window.
	await create_timer(p.fade_out_seconds * 2.5).timeout
	if p.ring.modulate.a > 0.01:
		print("PUL FAIL: did not fade out (alpha %f)" % p.ring.modulate.a)
		failures += 1

	# 5. Reduced motion: no scale animation — scale stays ONE throughout.
	prefs.reduced_motion = true
	p.on_beat(0.5)
	await process_frame
	if p.ring.scale != Vector2.ONE:
		print("PUL FAIL: scaled under reduced motion")
		failures += 1
	prefs.reduced_motion = false

	# 6. Persistence round-trip.
	prefs.beat_pulsar_enabled = true
	prefs.save()
	var prefs2: Node = PREFS.new()
	prefs2.load_or_create_defaults()
	if prefs2.beat_pulsar_enabled != true:
		print("PUL FAIL: beat_pulsar_enabled not persisted")
		failures += 1
	prefs2.free()

	p.queue_free()
	prefs.queue_free()

	if failures > 0:
		print("PUL FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("PUL PASS")
		quit(0)
