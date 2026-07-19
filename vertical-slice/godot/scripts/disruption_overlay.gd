extends Control
class_name DisruptionOverlay

@export var neon_color: Color = Color(0.0, 0.94, 1.0, 0.28)
@export var line_thickness := 2.0
@export var max_jitter_pixels := 8.0
@export var flicker_rate := 18.0

var chaos := 0.0:
	set(value):
		chaos = clamp(value, 0.0, 1.0)
		_update_sleep_state()

var _flicker_time := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_update_sleep_state()


func _process(delta: float) -> void:
	if is_zero_approx(chaos):
		return

	_flicker_time += delta * (flicker_rate + chaos * 32.0)
	queue_redraw()


func _draw() -> void:
	if is_zero_approx(chaos):
		return

	var size := get_rect().size
	var flicker := sin(_flicker_time * 1.7) * cos(_flicker_time * 0.73)
	var y_offset := flicker * max_jitter_pixels * chaos
	var edge_alpha := neon_color.a * (0.35 + abs(flicker) * 0.65) * chaos
	var edge_color := neon_color
	edge_color.a = clamp(edge_alpha, 0.03, neon_color.a)

	# Offset the line geometry by the flicker value so the disruption feels
	# physically unstable instead of reading as static-y alpha blinking.
	draw_line(Vector2(0.0, y_offset), Vector2(size.x, y_offset), edge_color, line_thickness)

	if chaos > 0.55:
		var core_color := Color.WHITE
		core_color.a = (chaos - 0.55) * 0.32
		draw_line(Vector2(0.0, y_offset * 0.45), Vector2(size.x, y_offset * 0.45), core_color, max(line_thickness * 0.5, 1.0))


func _update_sleep_state() -> void:
	var active := not is_zero_approx(chaos)
	set_process(active)
	visible = active
	if not active:
		_flicker_time = 0.0
		queue_redraw()
