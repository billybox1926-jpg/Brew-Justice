extends Sprite2D
class_name SmudgeResolver

signal clarity_changed(clarity: float)

var _presence: float = 0.0
var _material: Material
var _initial_modulate: Color
@export var clue_data: ClueData

func _ready() -> void:
	_initial_modulate = modulate
	_resolve_material()


func apply_presence(value: float) -> void:
	_presence = clamp(value, 0.0, 1.0)
	var clarity := smoothstep(0.55, 0.9, _presence)

	if not _material:
		_resolve_material()
		if not _material:
			clarity_changed.emit(clarity)
			return

	if _material is ShaderMaterial:
		_material.set_shader_parameter("clarity", clarity)

	modulate.a = _initial_modulate.a * (0.35 + 0.65 * clarity)
	clarity_changed.emit(clarity)


func _resolve_material() -> void:
	if get("material") != null:
		_material = material
	else:
		_material = null
