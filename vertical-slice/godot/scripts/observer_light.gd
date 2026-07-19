extends Control
class_name ObserverLight

signal tuned_in(calm: float)

var lamp: PointLight2D
var occluder: LightOccluder2D
var base_color := Color(0.851, 0.71, 0.51)
var warm_color := Color(1.0, 0.85, 0.62)
var base_energy := 0.6
var warm_energy := 1.15
var base_range := 160.0
var warm_range := 220.0
var guarded := false

func _enter_tree() -> void:
	lamp = _find_direct(PointLight2D)
	occluder = _find_direct(LightOccluder2D)
	if lamp:
		lamp.color = base_color
		lamp.energy = base_energy
		lamp.texture_scale = 1.0
		lamp.range_item_cull_mask = 0
		lamp.shadow_enabled = false


func _exit_tree() -> void:
	if lamp and is_instance_valid(lamp):
		lamp.shadow_enabled = false


func _find_direct(type: int):
	for child in get_children():
		if is_instance_valid(child) and child.get_class() == class_string(type):
			return child
	return null


func class_string(t: int) -> String:
	match t:
		18:
			return "PointLight2D"
		19:
			return "LightOccluder2D"
	return ""


func apply_calm(calm: float, delta: float) -> void:
	if guarded != bool(calm > 0.05):
		guarded = !guarded
		tuned_in.emit(calm)
	if lamp:
		var alpha := smoothstep(0.0, 1.0, clamp(calm, 0.0, 1.0))
		var target_color := base_color.lerp(warm_color, alpha * 0.75)
		var target_energy := lerp(base_energy, warm_energy, alpha)
		var target_range := lerp(base_range, warm_range, alpha)
		lamp.color = lamp.color.lerp(target_color, min(delta * 3.5, 1.0))
		lamp.energy = lerp(lamp.energy, target_energy, min(delta * 3.5, 1.0))
		lamp.texture_scale = lerp(lamp.texture_scale, 1.0 + alpha * 0.35, min(delta * 3.0, 1.0))
		lamp.shadow_enabled = alpha > 0.55
	if occluder:
		occluder.occluder_light_mask = 1 if calm > 0.1 else 0
