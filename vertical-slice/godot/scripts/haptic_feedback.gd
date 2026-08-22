extends Node
class_name HapticFeedback

## Gamepad vibration for rhythm regulation feedback (issue #55).
## - Gentle hum on each steady rhythm beat (low-frequency motor)
## - Sharp buzz on chaos spikes (high-frequency motor)
## Intensity is sensitivity-aware: scaled by
## PreferencesManager.haptics_intensity (0.0 = off, 1.0 = full) and every
## command is a no-op without connected joypads or when disabled.

const HUM_WEAK := 0.25
const HUM_STRONG := 0.45
const BUZZ_WEAK := 0.5
const BUZZ_STRONG := 1.0

var enabled: bool = false:
	set(value):
		enabled = value
		if not value:
			stop_all()


func _ready() -> void:
	var prefs := get_node_or_null("/root/PreferencesManager")
	if prefs:
		enabled = bool(prefs.haptics_enabled)


static func _intensity_scale() -> float:
	var prefs: Node = null
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		prefs = (loop as SceneTree).root.get_node_or_null("/root/PreferencesManager")
	return clampf(float(prefs.haptics_intensity), 0.0, 1.0) if prefs else 0.0


## Gentle sustained hum while the stim beat is steady. Call once per beat.
func hum(duration: float = 0.2) -> void:
	if not enabled:
		return
	var scale := HapticFeedback._intensity_scale()
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, HUM_WEAK * scale, HUM_STRONG * scale, duration)


## Sharp short buzz on a chaos spike.
func buzz(duration: float = 0.12) -> void:
	if not enabled:
		return
	var scale := HapticFeedback._intensity_scale()
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, BUZZ_WEAK * scale, BUZZ_STRONG * scale, duration)


func stop_all() -> void:
	for device in Input.get_connected_joypads():
		Input.stop_joy_vibration(device)
