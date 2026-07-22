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

const CHAOS_FLICKER_ENERGY_MIN := 0.25
const CHAOS_FLICKER_ENERGY_MAX := 0.55
const CHAOS_FLICKER_DURATION := 0.18
const CHAOS_FLICKER_RECOVER := 0.22

var flicker_strength := false

var lamp: PointLight2D
var occluder: LightOccluder2D
var prev_guarded := false
var _base_energy: float = 0.6
var _base_color: Color = Color(0.6, 0.6, 0.8)

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
	if flicker_strength:
		flicker_strength = false
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
	if flicker_strength:
		lamp.color = lamp.color.lerp(Color(0.55, 0.6, 0.75), min(delta * 12.0, 1.0))
		lamp.energy = lerp(lamp.energy, CHAOS_FLICKER_ENERGY_MIN, min(delta * 14.0, 1.0))
	else:
		lamp.energy = lerp(lamp.energy, lerp(lamp_energy_base, lamp_energy_warm, t), min(delta * 3.5, 1.0))
	lamp.texture_scale = lerp(lamp.texture_scale, 1.0 + t * 0.35, min(delta * 2.8, 1.0))
	lamp.shadow_enabled = t > 0.55
	if occluder:
		occluder.occluder_light_mask = 1 if calm > 0.1 else 0


func apply_chaos_spike(intensity: float) -> void:
	if not lamp:
		return
	flicker_strength = true
	var energy_target := lerpf(CHAOS_FLICKER_ENERGY_MAX, CHAOS_FLICKER_ENERGY_MIN, clamp(intensity, 0.0, 1.0))
	lamp.energy = lerpf(lamp.energy, energy_target, 0.6)
	lamp.texture_scale = lerpf(lamp.texture_scale, 0.92, 0.6)
