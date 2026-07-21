extends Control
class_name SensoryCanvas

## Renders sensory feedback: vignette, trail, bind highlights.

const VIGNETTE_BASE_FRAC: float = 0.55
const VIGNETTE_RADIUS_SPAN: float = 0.3
const VIGNETTE_ALPHA_BASE: float = 0.10
const VIGNETTE_ALPHA_SPAN: float = 0.56
const VIGNETTE_ALPHA_MIN: float = 0.06
const VIGNETTE_ALPHA_MAX: float = 0.66
const VIGNETTE_WARMTH_BLEND: float = 0.55
const VIGNETTE_CALM_WARMTH: float = 0.2
const VIGNETTE_CHAOS_TINT: Color = Color(0.18, 0.08, 0.04)
const VIGNETTE_CHAOS_DRIVER: float = 0.35
const VIGNETTE_CALM_DRIVER: float = 0.04
const VIGNETTE_EASE: float = 0.55

@export var vignette_color: Color = Color(0.05, 0.03, 0.02)
@export var trail_color: Color = Color(0.82, 0.62, 0.18)
@export var highlight_color: Color = Color(1.0, 0.9, 0.6)

var presence: float = 0.5
var chaos: float = 0.0
var calm: float = 0.5

var trail_points: PackedVector2Array = PackedVector2Array()
var bind_points: PackedVector2Array = PackedVector2Array()
var tune_progress: float = 0.0

func queue_redraw_if_needed() -> void:
	if not is_inside_tree():
		return
	queue_redraw()


func _draw() -> void:
	_draw_vignette()
	_draw_trail(trail_points, trail_color, 2.0 + presence * 3.0)
	_draw_bind_highlights()
	_draw_clue_glow()


func _get_vignette_strength(presence: float, chaos: float, calm: float) -> float:
	var strength := (1.0 - presence) + chaos * VIGNETTE_CHAOS_DRIVER
	strength += calm * VIGNETTE_CALM_DRIVER
	return clampf(strength, 0.0, 1.0)


func _get_vignette_color(strength: float, calm: float) -> Color:
	var col := vignette_color
	col.a = clampf(VIGNETTE_ALPHA_BASE + strength * VIGNETTE_ALPHA_SPAN, VIGNETTE_ALPHA_MIN, VIGNETTE_ALPHA_MAX)
	col = col.lerp(VIGNETTE_CHAOS_TINT, strength * VIGNETTE_WARMTH_BLEND + calm * VIGNETTE_CALM_WARMTH)
	return col


func _draw_vignette() -> void:
	var size := get_viewport_rect().size
	var strength := _get_vignette_strength(presence, chaos, calm)
	var eased := ease(strength, VIGNETTE_EASE)
	var radius := min(size.x, size.y) * (VIGNETTE_BASE_FRAC + eased * VIGNETTE_RADIUS_SPAN)
	var col := _get_vignette_color(eased, calm)

	draw_rect(Rect2(0, 0, size.x, size.y - radius), col)
	draw_rect(Rect2(0, 0, size.x - radius, size.y), col)
	draw_rect(Rect2(radius, 0, size.x - radius, size.y), col)
	draw_rect(Rect2(0, radius, size.x, size.y - radius), col)


func _draw_trail(points: PackedVector2Array, col: Color, width: float) -> void:
	if points.size() < 2:
		return
	var c := col
	c.a = 0.45 + presence * 0.55
	draw_polyline(points, c, width, true)


func _draw_bind_highlights() -> void:
	if bind_points.is_empty():
		return
	var pulse := sin(Time.get_ticks_msec() / 1000.0 * (1.0 + presence * 2.0)) * 0.5 + 0.5
	var base_size := 6.0 + presence * 4.0
	for i in range(bind_points.size()):
		var p := bind_points[i]
		var size := base_size * (0.8 + 0.4 * pulse)
		var c := highlight_color
		c.a = 0.6 + presence * 0.4
		match i % 3:
			0:
				draw_circle(p, size, c)
			1:
				var pts := PackedVector2Array([
					p + Vector2(0, -size),
					p + Vector2(size, 0),
					p + Vector2(0, size),
					p + Vector2(-size, 0),
				])
				draw_colored_polygon(pts, c)
			2:
				var half := size * 0.707
				draw_rect(Rect2(p - Vector2(half, half), Vector2(size * 1.414, size * 1.414)), c)


func _draw_clue_glow() -> void:
	if tune_progress <= 0.0:
		return
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 3.0)
	var alpha := 0.04 + tune_progress * 0.08 + pulse * 0.04
	var col := Color(1.0, 0.85, 0.55)
	col.a = alpha
	var size := get_viewport_rect().size
	draw_rect(Rect2(0, 0, size.x, size.y), col)


func set_state(new_presence: float, new_chaos: float, new_tune_progress: float, new_calm: float) -> void:
	presence = clampf(new_presence, 0.0, 1.0)
	chaos = clampf(new_chaos, 0.0, 1.0)
	tune_progress = clampf(new_tune_progress, 0.0, 1.0)
	calm = clampf(new_calm, 0.0, 1.0)
	queue_redraw_if_needed()


func set_trail(new_points: PackedVector2Array) -> void:
	trail_points = new_points
	queue_redraw_if_needed()


func set_bind_points(new_points: PackedVector2Array) -> void:
	bind_points = new_points
	queue_redraw_if_needed()
