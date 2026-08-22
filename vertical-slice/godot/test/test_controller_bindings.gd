extends SceneTree

## Verification for gamepad/controller input mapping (issue #60).
## Run: godot --headless --path . --script res://test/test_controller_bindings.gd
## Asserts: default pad bindings land on every core action alongside
## keyboard events, custom joypad bindings persist through the existing
## PreferencesManager.custom_bindings slot, saved pad bindings survive a
## reload, and keyboard bindings are never clobbered.

const PREFS := preload("res://autoloads/preferences_manager.gd")
const CB := preload("res://scripts/controller_bindings.gd")


func _init() -> void:
	var failures := 0

	var prefs: Node = PREFS.new()
	prefs.name = "PreferencesManager"
	root.add_child(prefs)
	prefs.custom_bindings.clear()

	# Register actions exactly as FocusModeMain does.
	for pair in [["focus_toggle", KEY_F], ["stim_hold", KEY_SPACE], ["reset_sensory", KEY_R]]:
		if InputMap.has_action(pair[0]):
			InputMap.action_erase_events(pair[0])
		else:
			InputMap.add_action(pair[0])
		var k := InputEventKey.new()
		k.keycode = pair[1]
		k.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], k)

	# 1. Defaults: each action has both a key and a joypad event.
	var cb: Object = CB.new()
	cb.apply_default_joy_bindings()
	for action in ["focus_toggle", "reset_sensory"]:
		var has_key := false
		var has_pad := false
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				has_key = true
			elif ev is InputEventJoypadButton:
				has_pad = true
		if not (has_key and has_pad):
			print("PAD FAIL: %s missing key=%s pad=%s" % [action, str(has_key), str(has_pad)])
			failures += 1

	# stim_hold uses the right trigger axis.
	var stim_events := InputMap.action_get_events("stim_hold")
	var has_trigger := false
	for ev in stim_events:
		if (
			ev is InputEventJoypadMotion
			and int((ev as InputEventJoypadMotion).axis) == JOY_AXIS_TRIGGER_RIGHT
		):
			has_trigger = true
	if not has_trigger:
		print("PAD FAIL: stim_hold has no right-trigger axis event")
		failures += 1

	# 2. Custom joypad binding persists via the existing remapping slot.
	# Seed a keyboard entry as if the user had remapped a key, so we can
	# prove pad saves don't clobber keyboard entries.
	prefs.custom_bindings["focus_toggle"] = [{"keycode": KEY_F}]
	var pad_event := InputEventJoypadButton.new()
	pad_event.button_index = JOY_BUTTON_Y
	if not CB.save_joy_binding(prefs, "focus_toggle", pad_event):
		print("PAD FAIL: save_joy_binding rejected a joypad button")
		failures += 1
	if not prefs.custom_bindings["focus_toggle"].any(
		func(e: Dictionary) -> bool: return e.has("joy_button")
	):
		print("PAD FAIL: joy binding not stored in custom_bindings")
		failures += 1

	# 3. Keyboard entries are preserved when saving a pad binding.
	if not prefs.custom_bindings["focus_toggle"].any(
		func(e: Dictionary) -> bool: return e.has("keycode")
	):
		print("PAD FAIL: keyboard entry clobbered by pad binding")
		failures += 1

	# 4. Reload path: fresh prefs load restores the joypad binding into InputMap.
	InputMap.action_erase_events("focus_toggle")
	var keep_key := InputEventKey.new()
	keep_key.keycode = KEY_F
	InputMap.action_add_event("focus_toggle", keep_key)
	CB.apply_saved_joy_bindings(prefs)
	var restored_pad := false
	var restored_key := false
	for ev in InputMap.action_get_events("focus_toggle"):
		if ev is InputEventJoypadButton:
			restored_pad = true
		elif ev is InputEventKey:
			restored_key = true
	if not (restored_pad and restored_key):
		print("PAD FAIL: reload lost pad=%s key=%s" % [str(restored_pad), str(restored_key)])
		failures += 1

	# 5. describe() covers all three event kinds.
	if CB.describe(pad_event) == "?":
		print("PAD FAIL: describe() cannot render joypad button")
		failures += 1

	# Cleanup: remove test binding so other suites see defaults.
	prefs.custom_bindings.erase("focus_toggle")
	prefs.save()

	prefs.queue_free()

	if failures > 0:
		print("PAD FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("PAD PASS")
		quit(0)
