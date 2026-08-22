extends Control
class_name BeatPulsar

## Subtle visual beat indicator for deaf/hard-of-hearing players (issue #49).
## Listens to the SAME signal as the audio rhythm: StimTool.rhythm_pulse.
## On each pulse it eases a soft ring glow in at intensity-scaled opacity,
## then fades back out. Preference-gated (PreferencesManager
## .beat_pulsar_enabled, off by default) and motion-safe: under
## reduced_motion it fades opacity only, with no scale animation.

signal shown

@export var pulse_color: Color = Color(1.0, 0.9, 0.5, 0.55)
## Seconds for the glow to fade back down after each beat.
@export var fade_out_seconds: float = 0.35

var ring: Panel
var tween: Tween
var enabled: bool = false:
	set(value):
		enabled = value
		visible = value
		if not value and is_instance_valid(tween) and tween.is_valid():
			tween.kill()
		if not value and ring:
			ring.modulate.a = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring = Panel.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	ring.custom_minimum_size = Vector2(120, 8)
	ring.offset_top = 24.0
	ring.offset_left = -60.0
	ring.offset_right = 60.0
	var style := StyleBoxFlat.new()
	style.bg_color = pulse_color
	style.set_corner_radius_all(4)
	ring.add_theme_stylebox_override("panel", style)
	ring.modulate.a = 0.0
	add_child(ring)


## Called on every rhythm_pulse — the exact same emission that drives the
## stim rhythm audio, so visual and audio beats can never desync.
func on_beat(intensity: float) -> void:
	if not enabled or intensity <= 0.0:
		return
	visible = true
	if is_instance_valid(tween) and tween.is_valid():
		tween.kill()
	ring.modulate.a = clampf(intensity, 0.25, 1.0)
	if _reduced_motion():
		# Motion-safe fallback: fade opacity only, no size/scale change.
		tween = create_tween()
		tween.tween_property(ring, "modulate:a", 0.0, fade_out_seconds)
	else:
		ring.scale = Vector2(1.15, 1.15)
		tween = create_tween()
		tween.tween_property(ring, "scale", Vector2.ONE, fade_out_seconds)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, fade_out_seconds)
	shown.emit()


func _reduced_motion() -> bool:
	var prefs := get_node_or_null("/root/PreferencesManager")
	return prefs != null and bool(prefs.reduced_motion)
