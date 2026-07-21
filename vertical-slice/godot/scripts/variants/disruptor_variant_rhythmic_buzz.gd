extends DisruptorVariant

## "Rhythmic interference pulse" — a periodic, mid-frequency buzz that
## pulls the player's rhythm off the baseline when it peaks.
func _init() -> void:
	variant_name = "rhythmic_buzz"
	intensity = 0.6
	duration = 0.4
	interval = 2.5
	auditory_band = "mid"
	lore_fragment = "A rhythmic buzz bleeds through the ceiling tiles."

