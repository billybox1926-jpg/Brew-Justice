extends Node
class_name StimTool

signal stim_released(strength: float)

var holding := false
var charge := 0.0
var cooldown := 0.0


func press() -> void:
	if cooldown > 0.0:
		return
	holding = true
	charge = 0.0


func release() -> void:
	if not holding:
		return
	holding = false
	var strength = clamp(charge, 0.0, 1.0)
	stim_released.emit(strength)
	charge = 0.0
	cooldown = 0.5


func update(delta: float) -> void:
	if cooldown > 0.0:
		cooldown = max(cooldown - delta, 0.0)


func accumulate(delta: float) -> float:
	if holding and cooldown <= 0.0:
		charge = clamp(charge + delta * 0.6, 0.0, 1.0)
	return charge
