extends Sprite2D
class_name NeonClue

signal stability_changed(stability: float)

var _presence: float = 0.0
var _material: Material

func _ready() -> void:
	_resolve_material()


func apply_presence(value: float) -> void:
	_presence = clamp(value, 0.0, 1.0)
	var stability := smoothstep(0.5, 0.85, _presence)

	if not _material:
		_resolve_material()
		if not _material:
			return

	if _material is ShaderMaterial:
		_material.set_shader_parameter("flicker_intensity", 1.0 - stability)
		_material.set_shader_parameter("text_alpha", stability)

	modulate.a = 0.18 + 0.82 * stability
	stability_changed.emit(stability)


func _resolve_material() -> void:
	if get("material") != null:
		_material = material
	else:
		_material = null
