extends Node
# SensoryMeter owns load state and tier thresholds.
# Signals keep changes decoupled from rendering/logic.

signal load_changed(value: float)
signal mode_changed(mode: String)

var sensory := 18.0
# Baseline: 0-40, Hyperfocus: 41-75, Overload: 76-100
const MODE_BASELINE := "Baseline"
const MODE_HYPERFOCUS := "Hyperfocus"
const MODE_OVERLOAD := "Overload"


func set_load(value: float) -> void:
	var new_val := float(clamp(value, 0.0, 100.0))
	if sensory == new_val:
		return
	sensory = new_val
	var new_mode := _compute_mode()
	load_changed.emit(sensory)
	mode_changed.emit(new_mode)


func add_load(amount: float) -> void:
	set_load(sensory + amount)


func reduce_load(amount: float) -> void:
	set_load(sensory - amount)


func reset() -> void:
	set_load(18.0)


func _compute_mode() -> String:
	if sensory < 40.0:
		return MODE_BASELINE
	elif sensory < 75.0:
		return MODE_HYPERFOCUS
	return MODE_OVERLOAD


func mode_name() -> String:
	return _compute_mode()


func current_sensory() -> float:
	return sensory
