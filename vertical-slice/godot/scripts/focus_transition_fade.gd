extends CanvasLayer
class_name FocusTransitionFade

## Brief cinematic dim when entering/exiting focus mode (issue #54).
## Opacity-only fade — no zoom/scale — so it stays sensitivity-safe.
## With reduced_motion enabled the transition is an instant cut instead
## of an animated fade.

@export var fade_duration := 0.4
## How dark the world dims while focused.
@export var focused_dim := 0.35

var rect: ColorRect
var tween: Tween
var reduced_motion: bool = false


func _ready() -> void:
	layer = 50
	rect = ColorRect.new()
	rect.color = Color(0.0, 0.0, 0.05, 0.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(rect)


## Animate the dim toward the state's target. Instant cut under reduced motion.
func set_focus(active: bool) -> void:
	var target_alpha := focused_dim if active else 0.0
	if is_instance_valid(tween) and tween.is_valid():
		tween.kill()
	if reduced_motion:
		rect.color.a = target_alpha
		return
	tween = create_tween()
	tween.tween_property(rect, "color:a", target_alpha, fade_duration)
