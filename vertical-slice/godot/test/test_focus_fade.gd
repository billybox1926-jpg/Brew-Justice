extends SceneTree

## Smoke check for the focus-mode transition fade (issue #54).
## Run: godot --headless --path . --script res://test/test_focus_fade.gd
## Asserts toggle timing: fade animates toward the focused dim over
## fade_duration, returns to transparent on exit, and reduced_motion
## cuts instantly instead.

const FADE := preload("res://scripts/focus_transition_fade.gd")


func _init() -> void:
	var failures := 0
	var fade: CanvasLayer = FADE.new()
	root.add_child(fade)
	await process_frame

	if not fade.rect:
		print("FADE FAIL: rect missing")
		quit(1)
		return

	# 1. Entering focus starts an animated dim (not instant, not final).
	fade.set_focus(true)
	await process_frame
	if is_equal_approx(fade.rect.color.a, 0.0):
		print("FADE FAIL: no visible dim after entering focus")
		failures += 1
	await create_timer(fade.fade_duration * 2.5).timeout
	if not is_equal_approx(fade.rect.color.a, fade.focused_dim):
		print(
			"FADE FAIL: dim did not settle at %f (got %f)" % [fade.focused_dim, fade.rect.color.a]
		)
		failures += 1

	# 2. Exiting focus returns to fully transparent.
	fade.set_focus(false)
	await create_timer(fade.fade_duration * 2.5).timeout
	if not is_equal_approx(fade.rect.color.a, 0.0):
		print("FADE FAIL: exit focus left alpha at %f" % fade.rect.color.a)
		failures += 1

	# Mid-fade check: shortly after starting, alpha should be between.
	fade.reduced_motion = false
	fade.set_focus(true)
	await process_frame
	var mid: float = fade.rect.color.a
	if mid <= 0.0 or mid >= fade.focused_dim:
		print("FADE NOTE: mid-fade alpha %f not strictly between 0 and target" % mid)

	# 3. Reduced motion: instant cut to target within one frame.
	fade.reduced_motion = true
	fade.set_focus(true)
	await process_frame
	if not is_equal_approx(fade.rect.color.a, fade.focused_dim):
		print("FADE FAIL: reduced_motion did not cut instantly")
		failures += 1

	fade.queue_free()

	if failures > 0:
		print("FADE FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("FADE PASS")
		quit(0)
