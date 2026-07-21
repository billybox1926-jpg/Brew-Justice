extends DisruptorVariant

## "Patterned broadcast" — a repeating 1-2-1 cadence that reads as
## intentional, as if someone is transmitting on purpose.
func _init() -> void:
	variant_name = "patterned_broadcast"
	intensity = 0.75
	duration = 0.35
	interval = 3.0
	auditory_band = "mid"
	lore_fragment = "A repeating pulse ticks from the stairwell."

