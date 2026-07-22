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
const VIGNETTE_EASE: float = 0.65
const VIGNETTE_EDGE_TINT: Color = Color(0.55, 0.7, 0.95)
const VIGNETTE_EDGE_TINT_STRENGTH: float = 0.35
const TRAIL_BASE_WIDTH: float = 5.0
const TRAIL_COLOR_NORMAL: Color = Color(0.82, 0.62, 0.18, 0.9)
const TRAIL_COLOR_COLORBLIND: Color = Color(1.0, 0.95, 0.45, 0.95)
const TRAIL_COLOR_DIM: Color = Color(0.55, 0.55, 0.55, 0.35)
const TRAIL_FADE_NEAR_CLUE: float = 0.35
const TRAIL_FADE_RESOLVED: float = 0.12

@export var vignette_color: Color = Color(0.05, 0.03, 0.02)
@export var trail_color: Color = Color(0.82, 0.62, 0.18)
@export var highlight_color: Color = Color(1.0, 0.9, 0.6)
var _palette: ColorPalette

var presence: float = 0.5
var chaos: float = 0.0
var calm: float = 0.5

signal trail_proximity(proximity: float)

var trail_points: PackedVector2Array = PackedVector2Array()
var bind_points: PackedVector2Array = PackedVector2Array()
var tune_progress: float = 0.0
var trail_help_visible: bool = true
var _trail_proximity_threshold: float = 45.0

const TRAIL_DRAW_WIDTH_MIN: float = 4.0
const TRAIL_DRAW_WIDTH_PRESENCE_SCALE: float = 3.0


func _ready() -> void:
	var pm := get_node_or_null("/root/PreferencesManager") as PreferencesManager
	if pm and pm.has_signal("preferences_updated"):
		pm.preferences_updated.connect(_on_preferences_updated)
	_setup_palette()
	if pm:
		_apply_trail_prefs(pm)


func _on_preferences_updated() -> void:
	var pm := get_node_or_null("/root/PreferencesManager") as PreferencesManager
	_apply_palette(pm)
	_apply_trail_prefs(pm)


func _setup_palette() -> void:
	_apply_palette(get_node_or_null("/root/PreferencesManager"))


func _apply_palette(pm: PreferencesManager) -> void:
	var cb := false
	if pm and pm.has_method("is_colorblind_mode"):
		cb = pm.is_colorblind_mode()
	var base := ColorPalette.new()
	_palette = base
	highlight_color = base.color_for("bind_highlight", cb)
	queue_redraw_if_needed()


func queue_redraw_if_needed() -> void:
	if not is_inside_tree():
		return
	queue_redraw()


func _is_colorblind() -> bool:
	var pm := get_node_or_null("/root/PreferencesManager") as PreferencesManager
	if pm and pm.has_method("is_colorblind_mode"):
		return pm.is_colorblind_mode()
	return false


func _apply_trail_prefs(pm: PreferencesManager) -> void:
	if pm:
		trail_help_visible = bool(pm.trail_enabled)
	queue_redraw_if_needed()


func _computed_trail_color() -> Color:
	var cb := _is_colorblind()
	var base := TRAIL_COLOR_COLORBLIND if cb else TRAIL_COLOR_NORMAL
	if tune_progress >= TRAIL_FADE_NEAR_CLUE or calm >= 0.72:
		base = base.lerp(TRAIL_COLOR_DIM, clamp(calm * 1.2, 0.0, 1.0))
	if tune_progress > 0.85:
		base.a = min(base.a, TRAIL_FADE_RESOLVED)
	return base


func _draw() -> void:
	_draw_vignette()
	if trail_help_visible:
		var width := maxf(TRAIL_BASE_WIDTH, 2.0 + presence * 3.0)
		_draw_trail(trail_points, _computed_trail_color(), width)
	_draw_bind_highlights()
	_draw_clue_glow()


func _get_vignette_strength(presence: float, chaos: float, calm: float) -> float:
	var strength := (1.0 - presence) + chaos * VIGNETTE_CHAOS_DRIVER
	strength += calm * VIGNETTE_CALM_DRIVER
	return clampf(strength, 0.0, 1.0)


func _get_vignette_color(strength: float, calm: float) -> Color:
	var col := vignette_color
	if _palette:
		col = _palette.color_for("vignette_tint", _is_colorblind())
	col.a = clampf(VIGNETTE_ALPHA_BASE + strength * VIGNETTE_ALPHA_SPAN, VIGNETTE_ALPHA_MIN, VIGNETTE_ALPHA_MAX)
	col = col.lerp(VIGNETTE_CHAOS_TINT, strength * VIGNETTE_WARMTH_BLEND + calm * VIGNETTE_CALM_WARMTH)
	return col


func _draw_vignette() -> void:
	var size := get_viewport_rect().size
	var strength := _get_vignette_strength(presence, chaos, calm)
	var eased := ease(strength, VIGNETTE_EASE)
	var radius := min(size.x, size.y) * (VIGNETTE_BASE_FRAC + eased * VIGNETTE_RADIUS_SPAN)
	var col := _get_vignette_color(eased, calm)

	var band := max(24.0, min(size.x, size.y) * (0.08 + eased * 0.12))
	var inner := Rect2(band, band, size.x - band * 2.0, size.y - band * 2.0)
	var outer_alpha := col.a * (1.0 - eased * 0.55)
	draw_rect(Rect2(0, 0, size.x, band), Color(col.r, col.g, col.b, outer_alpha))
	draw_rect(Rect2(0, size.y - band, size.x, band), Color(col.r, col.g, col.b, outer_alpha))
	draw_rect(Rect2(0, 0, band, size.y), Color(col.r, col.g, col.b, outer_alpha))
	draw_rect(Rect2(size.x - band, 0, band, size.y), Color(col.r, col.g, col.b, outer_alpha))
	if inner.size.x > 0 and inner.size.y > 0:
		draw_rect(inner, Color(0, 0, 0, 0))


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


func set_trail_enabled_test_only(enabled: bool) -> void:
	trail_help_visible = enabled
	queue_redraw_if_needed()


func set_trail(new_points: PackedVector2Array) -> void:
	trail_points = new_points
	queue_redraw_if_needed()


func set_bind_points(new_points: PackedVector2Array) -> void:
	bind_points = new_points
	queue_redraw_if_needed()


func set_trail_target(target: Vector2) -> void:
	if trail_points.is_empty():
		return
	var best: float = INF
	for pt in trail_points:
		best = minf(best, pt.distance_to(target))
	var proximity := 1.0 - smoothstep(_trail_proximity_threshold, _trail_proximity_threshold + 30.0, best)
	trail_proximity.emit(clampf(proximity, 0.0, 1.0))
