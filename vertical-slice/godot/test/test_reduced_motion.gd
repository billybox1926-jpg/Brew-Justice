extends SceneTree

## Headless verification for the vestibular safety toggle (issue #44).
## Run: godot --headless --path . --script res://test/test_reduced_motion.gd
## Asserts: reduced_motion defaults OFF, persists, and each animated effect
## owner exposes a static fallback that suppresses motion when enabled.

const PREFS := preload("res://autoloads/preferences_manager.gd")
const OVERLAY := preload("res://scripts/disruption_overlay.gd")
const INV_UI := preload("res://scripts/investigation_ui.gd")


func _init() -> void:
	var failures := 0

	# 1. Default OFF (opt-in).
	var prefs: Node = PREFS.new()
	root.add_child(prefs)
	if prefs.reduced_motion != false:
		print("RM FAIL: reduced_motion defaults to true; must be opt-in")
		failures += 1

	# 2. Persistence round-trip.
	prefs.reduced_motion = true
	prefs.save()
	var prefs2: Node = PREFS.new()
	prefs2.load_or_create_defaults()
	if prefs2.reduced_motion != true:
		print("RM FAIL: reduced_motion not persisted")
		failures += 1
	prefs2.free()

	# 3. Overlay: reduced mode draws a static line and freezes _flicker_time.
	var overlay: Control = OVERLAY.new()
	root.add_child(overlay)
	overlay.chaos = 0.8
	var t_before: float = overlay._flicker_time
	overlay.reduced_motion = true
	for i in range(6):
		await process_frame
	if not is_equal_approx(overlay._flicker_time, t_before):
		print("RM FAIL: overlay flicker time still advances in reduced mode")
		failures += 1
	overlay.reduced_motion = false
	for i in range(6):
		await process_frame
	if is_equal_approx(overlay._flicker_time, t_before):
		print("RM FAIL: overlay flicker frozen even with reduced_motion off")
		failures += 1

	# 4. InvestigationUI: reduced mode starts at full scale (no zoom).
	var inv: CanvasLayer = INV_UI.new()
	root.add_child(inv)
	inv.reduced_motion = true
	inv.show_insight("static insight")
	if inv.label.scale != Vector2.ONE:
		print("RM FAIL: insight label zoomed in reduced mode")
		failures += 1
	inv.hide_insight()
	inv.reduced_motion = false
	inv.show_insight("zoom insight")
	if inv.label.scale == Vector2.ONE:
		print("RM FAIL: insight label never zooms with reduced_motion off")
		failures += 1
	inv.queue_free()

	overlay.queue_free()
	prefs.queue_free()

	if failures > 0:
		print("RM FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("RM PASS")
		quit(0)
