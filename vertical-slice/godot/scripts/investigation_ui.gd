extends CanvasLayer
class_name InvestigationUI

@export var fade_in_duration: float = 1.0
@export var hold_duration: float = 4.0
@export var fade_out_duration: float = 1.0
@export var default_text: String = ""

var label: Label
var tween: Tween
var _current_text: String = ""


func _ready() -> void:
	label = Label.new()
	label.anchors_preset = Control.PRESET_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.85, 0.0))
	label.text = default_text
	label.visible = false
	add_child(label)


func show_insight(text: String) -> void:
	_current_text = text
	label.text = text
	label.visible = true
	label.modulate.a = 0.0
	label.scale = Vector2(0.005, 0.005)
	_restart_fade_sequence()


func hide_insight() -> void:
	if is_instance_valid(tween) and tween.is_valid():
		tween.kill()
	label.modulate.a = 0.0
	label.visible = false


func _restart_fade_sequence() -> void:
	if is_instance_valid(tween) and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), fade_in_duration)
	tween.parallel().tween_property(label, "modulate:a", 1.0, fade_in_duration)
	tween.tween_interval(hold_duration)
	tween.tween_property(label, "modulate:a", 0.0, fade_out_duration)
	tween.tween_callback(func() -> void:
		label.visible = label.modulate.a > 0.01
		return
	)
