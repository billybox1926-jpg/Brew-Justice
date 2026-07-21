extends Sprite2D
class_name NeonClue

signal clarity_changed(clarity: float)

var _presence: float = 0.0
var _material: Material
@export var clue_data: ClueData

func _ready() -> void:
	_resolve_material()


func apply_presence(value: float) -> void:
	_presence = clamp(value, 0.0, 1.0)
	var clarity := smoothstep(0.5, 0.85, _presence)

	if not _material:
		_resolve_material()
		if not _material:
			clarity_changed.emit(clarity)
			return

	if _material is ShaderMaterial:
		_material.set_shader_parameter("flicker_intensity", 1.0 - clarity)
		_material.set_shader_parameter("text_alpha", clarity)

	modulate.a = 0.18 + 0.82 * clarity
	clarity_changed.emit(clarity)


func _resolve_material() -> void:
	if get("material") != null:
		_material = material
	else:
		_material = null
