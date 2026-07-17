extends Node
class_name SensoryMeter

var sensory := 18.0


# Reduce sensory load.
func reduce_load(amount: float) -> void:
	sensory = float(clamp(sensory - amount, 0.0, 100.0))


# Set sensory load directly.
func set_load(value: float) -> void:
	sensory = float(clamp(value, 0.0, 100.0))


# Current mode computed from sensory value.
func mode_name() -> String:
	if sensory < 40.0:
		return "Baseline"
	elif sensory < 75.0:
		return "Hyperfocus"
	return "Overload"


# Reset to a calm starting value.
func reset() -> void:
	set_load(18.0)
