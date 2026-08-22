extends RefCounted
class_name ControllerBindings

## Gamepad/controller input mapping (issue #60).
## Establishes a platform-appropriate default control scheme for every
## game action and integrates with PreferencesManager.custom_bindings:
## custom joypad events saved through save_joy_binding() override the
## defaults, exactly as key bindings do via save_binding().
##
## Default scheme (Xbox/PlayStation/Switch layouts all resolve through
## Godot's joy button axis-agnostic constants):
##   focus_toggle  = A / Cross            (JOY_BUTTON_A)
##   stim_hold     = Right trigger        (axis 5, hold)
##   reset_sensory = B / Circle           (JOY_BUTTON_B)
##   demo_overload = X / Square           (JOY_BUTTON_X)

const DEFAULT_ACTIONS := {
	"focus_toggle": {"button": JOY_BUTTON_A},
	"reset_sensory": {"button": JOY_BUTTON_B},
	"demo_overload": {"button": JOY_BUTTON_X},
	"stim_hold": {"axis": JOY_AXIS_TRIGGER_RIGHT, "threshold": 0.5},
}


## Add the default controller event(s) for `action` alongside any existing
## keyboard binding (additive: keyboard keeps working when a pad is plugged in).
func apply_default_joy_bindings() -> void:
	for action: String in DEFAULT_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var spec: Dictionary = DEFAULT_ACTIONS[action]
		if spec.has("button"):
			InputMap.action_add_event(action, _button_event(int(spec.button)))
		elif spec.has("axis"):
			InputMap.action_add_event(
				action, _axis_event(int(spec.axis), float(spec.get("threshold", 0.5)))
			)


func _button_event(button_index: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button_index as JoyButton
	return e


func _axis_event(axis_index: int, threshold: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis_index as JoyAxis
	e.axis_value = threshold
	return e


## Persist a custom controller binding for `action`, mirroring the keyboard
## save_binding() path. Stored under the same custom_bindings dict with a
## "joy_button" or "joy_axis" tag so apply_bindings() can tell them apart.
static func save_joy_binding(prefs: Node, action: String, event: InputEvent) -> bool:
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return false
	var entry := {}
	if event is InputEventJoypadButton:
		entry = {"joy_button": int((event as InputEventJoypadButton).button_index)}
	else:
		var motion := event as InputEventJoypadMotion
		entry = {"joy_axis": int(motion.axis), "value": motion.axis_value}
	var existing: Array = prefs.custom_bindings.get(action, [])
	# Replace prior controller entries but keep keyboard ones.
	var kept := []
	for prev: Dictionary in existing:
		if not (prev.has("joy_button") or prev.has("joy_axis")):
			kept.append(prev)
	kept.append(entry)
	prefs.custom_bindings[action] = kept
	prefs.save()
	return true


## Rebuild InputMap entries from stored custom bindings, including joypad ones.
## Call after apply_default_joy_bindings(); additive with keyboard defaults.
static func apply_saved_joy_bindings(prefs: Node) -> void:
	for action: String in prefs.custom_bindings:
		if not InputMap.has_action(action):
			continue
		for entry: Dictionary in prefs.custom_bindings[action]:
			if entry.has("joy_button"):
				var e := InputEventJoypadButton.new()
				e.button_index = int(entry.joy_button) as JoyButton
				InputMap.action_add_event(action, e)
			elif entry.has("joy_axis"):
				var m := InputEventJoypadMotion.new()
				m.axis = int(entry.joy_axis) as JoyAxis
				m.axis_value = float(entry.value)
				InputMap.action_add_event(action, m)


## Human-readable label for a bound event, for prompts/UI.
static func describe(event: InputEvent) -> String:
	if event is InputEventJoypadButton:
		return "Pad btn %d" % int((event as InputEventJoypadButton).button_index)
	if event is InputEventJoypadMotion:
		return "Pad axis %d" % int((event as InputEventJoypadMotion).axis)
	if event is InputEventKey:
		return OS.get_keycode_string((event as InputEventKey).keycode)
	return "?"
