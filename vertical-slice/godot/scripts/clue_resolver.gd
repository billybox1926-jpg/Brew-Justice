extends Node
class_name ClueResolver

signal clarity_changed(clue_id: String, clarity: float)

@export var clue_data: ClueData

var _presence: float = 0.0
var _clarity: float = 0.0   # 0.0 = invisible/illegible, 1.0 = fully resolved
var _clarity_target: float = 0.0
var _smoothing: float = 0.02


func apply_presence(value: float) -> void:
	_presence = clamp(value, 0.0, 1.0)
	if clue_data:
		var edge := 0.2
		_clarity_target = smoothstep(clue_data.presence_threshold - edge, clue_data.presence_threshold + 0.1, _presence)
	else:
		_clarity_target = _presence
	_clarity = move_toward(_clarity, _clarity_target, _smoothing)
	_update_visuals()
	clarity_changed.emit(clue_data.clue_id if clue_data else "", _clarity)


func _update_visuals() -> void:
	# Override in child scripts for specific sensory outputs.
	pass
