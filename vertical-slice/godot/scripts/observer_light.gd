extends Control
class_name ObserverLight

signal tuned_in(calm: float)

const LIGHT_TYPE := "PointLight2D"
const OCCLUDER_TYPE := "LightOccluder2D"

@export var lamp_color_base := Color(0.851, 0.71, 0.51)
@export var lamp_color_warm := Color(1.0, 0.85, 0.62)
@export var lamp_energy_base := 0.6
@export var lamp_energy_warm := 1.15
@export var lamp_range_base := 160.0
@export var lamp_range_warm := 220.0

var lamp: PointLight2D
var occluder: LightOccluder2D
var prev_guarded := false

func _enter_tree() -> void:
	_find_nodes()
	if lamp:
		_apply_state(0.0, 0.0)


func _find_nodes() -> void:
	for child in get_children():
		if not is_instance_valid(child):
			continue
		if child.get_class() == LIGHT_TYPE:
			lamp = child
		elif child.get_class() == OCCLUDER_TYPE:
			occluder = child


func apply_calm(calm: float, delta: float) -> void:
	var guarded := calm > 0.05
	if guarded != prev_guarded:
		prev_guarded = guarded
		tuned_in.emit(calm)
	_apply_state(calm, delta)


func _apply_state(calm: float, delta: float) -> void:
	if not lamp:
		return
	var t := smoothstep(0.005, 1.0, clamp(calm, 0.0, 1.0))
	lamp.color = lamp.color.lerp(lamp_color_base.lerp(lamp_color_warm, t * 0.75), min(delta * 3.5, 1.0))
	lamp.energy = lerp(lamp.energy, lerp(lamp_energy_base, lamp_energy_warm, t), min(delta * 3.5, 1.0))
	lamp.texture_scale = lerp(lamp.texture_scale, 1.0 + t * 0.35, min(delta * 2.8, 1.0))
	lamp.shadow_enabled = t > 0.55
	if occluder:
		occluder.occluder_light_mask = 1 if calm > 0.1 else 0
