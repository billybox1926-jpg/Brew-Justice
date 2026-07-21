extends Node
# SensoryMeter owns load state and tier thresholds.
# Signals keep changes decoupled from rendering/logic.

signal load_changed(value: float)
signal mode_changed(mode: String)

## Initial sensory load and tier breakpoints used by FocusModeMain.
const BASELINE_SENSORY := 18.0
const BASELINE_MAX := 40.0
const HYPERFOCUS_MAX := 75.0
const OVERLOAD_MIN := BASELINE_MAX + 1.0  # explicit boundary

var sensory := BASELINE_SENSORY
## Focus mode labels used by UI and canvas state.
const FOCUS_LABEL_ACTIVE := "Focus"
const FOCUS_LABEL_INACTIVE := "Baseline"
## Sensory meter mode names emitted by mode_changed.
const MODE_BASELINE := "Baseline"
const MODE_HYPERFOCUS := "Hyperfocus"
const MODE_OVERLOAD := "Overload"

## Noise floor / maximum load for sanity validation.
const MIN_SENSORY := 0.0
const MAX_SENSORY := 100.0


func set_load(value: float) -> void:
	var new_val := float(clamp(value, MIN_SENSORY, MAX_SENSORY))
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
	set_load(BASELINE_SENSORY)


func _compute_mode() -> String:
	if sensory < BASELINE_MAX:
		return MODE_BASELINE
	elif sensory < HYPERFOCUS_MAX:
		return MODE_HYPERFOCUS
	return MODE_OVERLOAD


func mode_name() -> String:
	return _compute_mode()


func current_sensory() -> float:
	return sensory
